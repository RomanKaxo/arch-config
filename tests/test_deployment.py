"""Behavioral tests use a tiny fixture; never touch the running desktop."""
import argparse
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('arch_config', Path(__file__).resolve().parents[1] / 'tools/arch_config.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='arch-config-tests-')
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.repo = self.base / 'repo'
        self.home = self.base / 'other-user'
        self.repo.mkdir(); self.home.mkdir()
        self.original_root = module.ROOT
        module.ROOT = self.repo
        self.addCleanup(setattr, module, 'ROOT', self.original_root)
        (self.repo / 'profiles').mkdir()
        for name, monitor in [('generic',''),('current-pc','DP-2')]:
            (self.repo/'profiles'/f'{name}.json').write_text(json.dumps(dict(primary_monitor=monitor,dock_output='')))
        self.entries = []
        self.add('settings/config', 'home=@HOME@\n', mode=0o600)
        self.add('bin/tool', '#!/bin/sh\necho @PRIMARY_MONITOR@\n', mode=0o755)
        self.entries.append(dict(source='',target='settings/current',component='user',profile='all',mode=0o777,link='config'))
        self.save_manifest()
        self.args = argparse.Namespace(home=str(self.home),profile='generic',component='user',dry_run=False,system_root=str(self.base/'system'))

    def add(self, target, text, mode=0o644, component='user'):
        source = 'payload/'+target
        p=self.repo/source;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
        self.entries.append(dict(source=source,target=target,component=component,profile='all',mode=mode,text=True,capture=target))

    def save_manifest(self):
        (self.repo/'manifest.json').write_text(json.dumps(dict(version=1,entries=self.entries)))

    def run_silently(self, action):
        with contextlib.redirect_stdout(io.StringIO()):action(self.args)

    def backup(self):
        return next((self.home/'.local/state/arch-config/backups').iterdir())

    def test_render_idempotence_permissions_and_restore(self):
        old=self.home/'settings/config';old.parent.mkdir();old.write_text('original');old.chmod(0o640)
        self.run_silently(module.install)
        self.assertEqual(old.read_text(),f'home={self.home}\n')
        self.assertEqual(old.stat().st_mode&0o777,0o600)
        self.assertEqual((self.home/'bin/tool').stat().st_mode&0o777,0o755)
        self.assertEqual((self.home/'settings/current').resolve(),old)
        before=list((self.home/'.local/state/arch-config/backups').iterdir())
        self.run_silently(module.install)
        self.assertEqual(before,list((self.home/'.local/state/arch-config/backups').iterdir()))
        self.args.backup=str(self.backup());self.run_silently(module.restore)
        self.assertEqual(old.read_text(),'original')
        self.assertEqual(old.stat().st_mode&0o777,0o640)
        self.assertFalse((self.home/'bin/tool').exists())
        self.assertFalse((self.home/'settings/current').is_symlink())
        self.run_silently(module.restore)

    def test_dry_run_has_no_writes(self):
        self.args.dry_run=True;self.run_silently(module.install)
        self.assertEqual(list(self.home.iterdir()),[])

    def test_restore_conflict_is_detected_before_any_write(self):
        self.run_silently(module.install)
        target=self.home/'bin/tool';target.write_text('new edit')
        self.args.backup=str(self.backup())
        with self.assertRaises(ValueError):self.run_silently(module.restore)
        self.assertTrue((self.home/'settings/config').exists())
        self.assertEqual(target.read_text(),'new edit')

    def test_file_symlink_is_replaced_without_writing_referent(self):
        outside=self.base/'outside';outside.write_text('untouched')
        (self.home/'settings').mkdir();(self.home/'settings/config').symlink_to(outside)
        self.run_silently(module.install)
        self.assertEqual(outside.read_text(),'untouched')
        self.args.backup=str(self.backup());self.run_silently(module.restore)
        self.assertEqual((self.home/'settings/config').resolve(),outside)

    def test_parent_symlink_rejected_before_any_write(self):
        outside=self.base/'outside';outside.mkdir();(self.home/'settings').symlink_to(outside)
        with self.assertRaises(ValueError):self.run_silently(module.install)
        self.assertEqual(list(outside.iterdir()),[])
        self.assertFalse((self.home/'bin').exists())

    def test_traversal_rejected(self):
        self.entries[0]['target']='../escape';self.save_manifest()
        with self.assertRaises(ValueError):self.run_silently(module.install)

    def test_profiles_and_allowlisted_sync(self):
        self.args.profile='current-pc';self.run_silently(module.install)
        self.assertIn('DP-2',(self.home/'bin/tool').read_text())
        (self.home/'private-passwords.json').write_text('must not be read')
        p=self.home/'settings/config';p.write_text(f'home={self.home}\nchanged=yes\n')
        self.run_silently(module.sync)
        self.assertEqual((self.repo/'payload/settings/config').read_text(),'home=@HOME@\nchanged=yes\n')
        self.assertFalse((self.repo/'payload/private-passwords.json').exists())

    def test_system_staging_and_restore(self):
        self.add('etc/example.conf','safe\n',component='system');self.save_manifest()
        self.args.component='system';self.run_silently(module.install)
        root=Path(self.args.system_root)
        self.assertEqual((root/'etc/example.conf').read_text(),'safe\n')
        self.args.backup=str(next((root/'var/lib/arch-config/backups').iterdir()))
        self.run_silently(module.restore)
        self.assertFalse((root/'etc/example.conf').exists())

    def test_interrupted_install_can_be_restored(self):
        original_put=module.put
        calls=0
        def interrupted(path,value):
            nonlocal calls
            calls+=1
            if calls==2:raise OSError('injected interruption')
            return original_put(path,value)
        module.put=interrupted
        try:
            with self.assertRaises(OSError):self.run_silently(module.install)
        finally:module.put=original_put
        self.assertTrue((self.home/'settings/config').exists())
        self.assertFalse((self.home/'bin/tool').exists())
        self.args.backup=str(self.backup());self.run_silently(module.restore)
        self.assertFalse((self.home/'settings/config').exists())

    def test_sync_updates_link_metadata(self):
        self.entries[-1]['capture']='settings/current';self.save_manifest()
        self.run_silently(module.install)
        p=self.home/'settings/current';p.unlink();p.symlink_to('new-choice')
        self.run_silently(module.sync)
        self.assertEqual(json.loads((self.repo/'manifest.json').read_text())['entries'][-1]['link'],'new-choice')

    def test_corrupt_backup_is_rejected(self):
        old=self.home/'settings/config';old.parent.mkdir();old.write_text('old')
        self.run_silently(module.install)
        backup=self.backup();(backup/'files/settings/config').write_text('corrupt')
        self.args.backup=str(backup)
        with self.assertRaises(ValueError):self.run_silently(module.restore)
        self.assertIn('home=',old.read_text())


if __name__=='__main__':unittest.main()

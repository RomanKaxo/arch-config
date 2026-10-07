"""Exercise manual preference and transient overlay state without signaling a live dock."""
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

SCRIPT=Path(__file__).resolve().parents[1]/'payload/user/all/.local/bin/desktop-dock'

class DockTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(prefix='dock-state-test-');self.addCleanup(self.tmp.cleanup)
        self.env=dict(os.environ,HOME=self.tmp.name,XDG_RUNTIME_DIR=self.tmp.name+'/run')

    def call(self,action,*args):
        return json.loads(subprocess.check_output([sys.executable,str(SCRIPT),action,*args,'--no-signal'],env=self.env,text=True))

    def test_fresh_install_defaults_to_visible(self):
        state=self.call('sync');self.assertTrue(state['enabled']);self.assertTrue(state['visible'])

    def test_new_login_restores_visible_default(self):
        self.call('hide');self.call('overlay','launcher');state=self.call('session')
        self.assertTrue(state['enabled']);self.assertTrue(state['visible']);self.assertEqual(state['panel'],'')

    def test_closing_panel_preserves_manual_hide(self):
        self.call('hide');self.call('overlay','launcher');state=self.call('overlay','')
        self.assertFalse(state['enabled']);self.assertFalse(state['visible'])

    def test_closing_panel_restores_manual_show(self):
        self.call('show');state=self.call('overlay','launcher');self.assertTrue(state['enabled']);self.assertFalse(state['visible'])
        state=self.call('overlay','');self.assertTrue(state['visible'])

    def test_toggle_during_overlay_takes_effect_when_closed(self):
        self.call('hide');self.call('overlay','launcher');state=self.call('toggle');self.assertTrue(state['enabled']);self.assertFalse(state['visible'])
        state=self.call('overlay','');self.assertTrue(state['visible'])

    def test_restart_sync_preserves_hidden_preference(self):
        self.call('show');self.call('toggle');state=self.call('sync');self.assertFalse(state['visible'])
        persisted=json.loads((Path(self.tmp.name)/'.local/state/desktop/dock.json').read_text());self.assertFalse(persisted['enabled'])

    def test_show_and_hide_signal_only_the_taskbar_main_process(self):
        signal_dock = runpy.run_path(str(SCRIPT))['signal_dock']
        manager = subprocess.CompletedProcess([], 0, stdout='123\n', stderr='')
        for visible, signal in ((True, 'USR1'), (False, 'USR2')):
            with self.subTest(visible=visible), mock.patch('subprocess.run', return_value=manager) as run:
                signal_dock(visible)
                self.assertEqual(run.call_args_list[1].args[0], [
                    'systemctl', '--user', 'kill', '--kill-whom=main',
                    '--signal=' + signal, 'desktop-dock.service',
                ])

if __name__=='__main__':unittest.main()

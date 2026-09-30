#!/usr/bin/env python3
"""Explicit-file Arch configuration deployment. No third-party Python dependency."""
from __future__ import annotations
import argparse
import ast
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]


def json_read(path):
    return json.loads(Path(path).read_text())


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + '\n')
    path.chmod(0o600)


def relative(value):
    p = Path(value)
    if p.is_absolute() or '..' in p.parts or not p.parts:
        raise ValueError(f'Unsafe relative path: {value}')
    return p


def exists(path):
    return path.exists() or path.is_symlink()


def safe_destination(base, value):
    """Never follow an existing directory symlink during deployment/restore."""
    base = base.resolve()
    dest = base / relative(value)
    for p in dest.parents:
        if p == base:
            break
        if p.is_symlink():
            raise ValueError(f'Directory symlink would redirect write: {p}')
        if p.exists() and not p.is_dir():
            raise ValueError(f'Parent is not a directory: {p}')
    if dest.exists() and dest.is_dir() and not dest.is_symlink():
        raise ValueError(f'Refusing to replace directory with file: {dest}')
    return dest


def home_path(value):
    path = Path(value).expanduser().absolute()
    # Paths appear inside shell/Lua/QML/desktop-file strings; reject unsafe literals.
    if not re.fullmatch(r'/[A-Za-z0-9_./-]+', str(path)) or path == Path('/'):
        raise ValueError('HOME must be an absolute path using letters, digits, /, _, ., -')
    return path.resolve()


def selected(args):
    manifest = json_read(ROOT / 'manifest.json')
    if manifest['version'] != 1:
        raise ValueError('Unsupported manifest version')
    entries = [e for e in manifest['entries']
               if e['component'] == args.component and e['profile'] in ('all', args.profile)]
    seen = set()
    for e in entries:
        relative(e['target'])
        if e['target'] in seen:
            raise ValueError(f'Duplicate destination: {e["target"]}')
        seen.add(e['target'])
        if 'link' not in e:
            src = ROOT / relative(e['source'])
            if not src.is_file() or src.is_symlink() or not src.resolve().is_relative_to(ROOT):
                raise ValueError(f'Invalid payload: {src}')
    return entries


def variables(args):
    if not hasattr(args, '_variables'):
        profile = json_read(ROOT / 'profiles' / (args.profile + '.json'))
        args._variables = {'@HOME@': str(home_path(args.home)),
                           '@PRIMARY_MONITOR@': profile['primary_monitor'],
                           '@DOCK_OUTPUT@': profile['dock_output']}
    return args._variables


def render(value, args):
    for token, replacement in variables(args).items():
        value = value.replace(token, replacement)
    return value


def desired(e, args):
    if 'link' in e:
        return {'link': render(e['link'], args)}
    raw = (ROOT / e['source']).read_bytes()
    if e.get('text'):
        raw = render(raw.decode(), args).encode()
    return {'data': raw, 'mode': e['mode']}


def signature(path):
    if path.is_symlink():
        return {'link': os.readlink(path)}
    if path.is_file():
        return {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                'mode': stat.S_IMODE(path.stat().st_mode)}
    if not exists(path):
        return None
    raise ValueError(f'Unsupported file type: {path}')


def desired_signature(value):
    if 'link' in value:
        return value
    return {'sha256': hashlib.sha256(value['data']).hexdigest(), 'mode': value['mode']}


def put(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    # Write to a sibling and rename: don't follow a pre-existing file symlink.
    fd, name = tempfile.mkstemp(prefix='.arch-config-', dir=path.parent)
    os.close(fd)
    temporary = Path(name)
    try:
        if 'link' in value:
            temporary.unlink()
            temporary.symlink_to(value['link'])
        else:
            temporary.write_bytes(value['data'])
            temporary.chmod(value['mode'])
        os.replace(temporary, path)
    finally:
        if exists(temporary):
            temporary.unlink()


def install(args):
    home = home_path(args.home)
    base = home if args.component in ('user', 'workspace') else Path(args.system_root).resolve()
    if args.component == 'system' and base == Path('/') and os.geteuid() != 0 and not args.dry_run:
        raise ValueError('System deployment requires sudo; use --system-root for isolated staging')
    if args.component == 'workspace' and not (home / 'Desktop/Elaris-Harness/server.mjs').is_file():
        raise ValueError('Restore the separate Elaris-Harness repository first; see docs/APPLICATIONS.md')
    changes = []
    for e in selected(args):
        path = safe_destination(base, e['target'])
        value = desired(e, args)
        if signature(path) != desired_signature(value):
            changes.append((e, path, value))
    print(f'{args.component}/{args.profile}: {len(changes)} changed files/links')
    if args.dry_run:
        for _, path, _ in changes[:30]:
            print(f'  would write {path}')
        if len(changes) > 30:
            print(f'  ... and {len(changes) - 30} more')
        return
    if not changes:
        return
    if args.component == 'system':
        backup_root = base / 'var/lib/arch-config/backups'
    else:
        backup_root = home / '.local/state/arch-config/backups'
    safe_destination(base, str(backup_root.relative_to(base) / 'placeholder'))
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    backup = backup_root / stamp
    backup.mkdir(parents=True, mode=0o700)
    journal = {'version': 1, 'base': str(base), 'component': args.component,
               'profile': args.profile, 'entries': []}
    for e, path, value in changes:
        old = signature(path)
        saved = backup / 'files' / e['target']
        if old is not None:
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, saved, follow_symlinks=False)
        journal['entries'].append({'target': e['target'], 'before': old,
                                   'installed': desired_signature(value)})
    # Back up every previous file and write the full journal once before mutations.
    # Unwritten entries are recognizable because they still match their before state.
    write_json(backup / 'journal.json', journal)
    for e, path, value in changes:
        put(path, value)
    print(f'Backup: {backup}')
    print('Services were not restarted. Sign out/in after completing all restore steps.')


def restore(args):
    backup = Path(args.backup).expanduser().resolve()
    journal = json_read(backup / 'journal.json')
    base = Path(journal['base']).resolve()
    if args.component != journal['component']:
        raise ValueError('Choose the component recorded in this backup')
    expected = home_path(args.home) if args.component in ('user', 'workspace') else Path(args.system_root).resolve()
    if base != expected:
        raise ValueError('Backup destination does not match --home/--system-root')
    actions = []
    for e in journal['entries']:
        path = safe_destination(base, e['target'])
        current = signature(path)
        # Already restored, or a journal entry was saved before its write completed.
        if current == e['before']:
            continue
        if current != e['installed']:
            raise ValueError(f'Modified since installation; restore stopped without changes: {path}')
        saved = backup / 'files' / relative(e['target'])
        if e['before'] is not None and signature(saved) != e['before']:
            raise ValueError(f'Backup integrity failure: {saved}')
        actions.append((e, path, saved))
    print(f'Restore: {len(actions)} files/links')
    if args.dry_run:
        return
    for e, path, saved in reversed(actions):
        if e['before'] is None:
            path.unlink()
        elif 'link' in e['before']:
            put(path, {'link': os.readlink(saved)})
        else:
            put(path, {'data': saved.read_bytes(), 'mode': e['before']['mode']})
    print('Restored. Empty directories and audit journals are retained.')


def normalize(text, target, args):
    text = text.replace(str(home_path(args.home)), '@HOME@')
    if target == '.config/hypr/hyprland.lua' and 'dofile(os.getenv("HOME") .. "/.config/hypr/hardware.lua")' not in text:
        start, end = text.index('hl.monitor('), text.index('hl.env(')
        hardware = 'desktopPrimaryMonitor = "DP-2"\n' + text[start:end]
        if args.profile != 'current-pc':
            raise ValueError('Legacy fixed-monitor config must be captured using current-pc')
        if not args.dry_run:
            (ROOT / 'payload/user/current-pc/.config/hypr/hardware.lua').write_text(hardware)
        text = text[:start] + 'dofile(os.getenv("HOME") .. "/.config/hypr/hardware.lua")\n\n' + text[end:]
        text = text.replace('    hl.dsp.focus({monitor = "DP-2"})()\n    hl.exec_cmd("xrandr --output DP-2 --primary")',
                            '    if desktopPrimaryMonitor then\n        hl.dsp.focus({monitor = desktopPrimaryMonitor})()\n        hl.exec_cmd("xrandr --output " .. desktopPrimaryMonitor .. " --primary")\n    end')
    if 'quickshell' in target or target.endswith('waypaper-sync'):
        monitor = variables(args)['@PRIMARY_MONITOR@']
        if monitor:
            text = text.replace('"' + monitor + '"', '"@PRIMARY_MONITOR@"')
        elif target.endswith('waypaper-sync'):
            text = text.replace('if "" and', 'if "@PRIMARY_MONITOR@" and')
        else:
            text = text.replace('s.name === ""', 's.name === "@PRIMARY_MONITOR@"')
    if target.endswith('waypaper-sync'):
        text = text.replace('("All", "")', '("All", "@PRIMARY_MONITOR@")')
    if target.endswith('waypaper-sync') and 'if "@PRIMARY_MONITOR@" and' not in text:
        text = text.replace('if len(sys.argv) > 2 and', 'if "@PRIMARY_MONITOR@" and len(sys.argv) > 2 and')
    if target.endswith('desktop-dock.service'):
        output = variables(args)['@DOCK_OUTPUT@']
        if output:
            text = text.replace(output, '@DOCK_OUTPUT@')
        else:
            text = text.replace(' -mb 10 -s ', ' -mb 10@DOCK_OUTPUT@ -s ')
    if target.endswith('desktop-session.target') and 'DefaultDependencies=no' not in text:
        text = text.replace('[Unit]\n', '[Unit]\nDefaultDependencies=no\n')
    return text


def sync(args):
    # Only paths already explicitly in the manifest are read. Never discover app databases.
    home = home_path(args.home)
    changes = 0
    for e in selected(args):
        capture = e.get('capture')
        if not capture:
            if e['target'] == '.config/hypr/hardware.lua':
                capture = e['target']
            else:
                continue
        source = Path(args.system_root).resolve() / relative(capture.lstrip('/')) if args.component == 'system' else home / relative(capture)
        if not exists(source):
            print(f'Missing; retained in repository: {e["target"]}')
            continue
        if source.is_symlink():
            link = os.readlink(source).replace(str(home), '@HOME@')
            if link != e.get('link'):
                changes += 1
                print(f'link {e["target"]}')
                if not args.dry_run:
                    # Conversion between file/link needs explicit manifest edit.
                    if 'link' not in e:
                        raise ValueError(f'File became symlink; review manifest: {source}')
                    e['link'] = link
        else:
            if 'link' in e:
                raise ValueError(f'Symlink became file; review manifest: {source}')
            raw = source.read_bytes()
            if e.get('text'):
                raw = normalize(raw.decode(), e['target'], args).encode()
            dest = ROOT / e['source']
            if raw != dest.read_bytes():
                changes += 1
                print(f'file {e["target"]}')
                if not args.dry_run:
                    put(dest, {'data': raw, 'mode': e['mode']})
    # selected() returns references to a separate manifest; persist changed link targets.
    if not args.dry_run:
        manifest = json_read(ROOT / 'manifest.json')
        updates = {(e['component'], e['profile'], e['target']): e for e in selected(args)}
        # Link capture pass supplies only link changes, without losing other profiles.
        for e in manifest['entries']:
            if (e['component'],e['profile'],e['target']) not in updates or 'link' not in e or not e.get('capture'):
                continue
            src = Path(args.system_root).resolve() / relative(e['capture'].lstrip('/')) if args.component == 'system' else home / relative(e['capture'])
            if src.is_symlink():
                e['link'] = os.readlink(src).replace(str(home), '@HOME@')
        (ROOT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'{changes} changes; inspect git diff before committing. New files require manifest entries.')


def command(argv, dry_run=False, **kwargs):
    print('+ ' + ' '.join(str(x) for x in argv))
    if not dry_run:
        subprocess.run([str(x) for x in argv], check=True, **kwargs)


def packages(args):
    package_files = ['arch.txt', 'build.txt']
    if args.profile == 'current-pc':
        package_files.append('current-pc.txt')
    names = sorted({line.strip() for f in package_files
                    for line in (ROOT / 'packages' / f).read_text().splitlines()
                    if line.strip() and not line.startswith('#')})
    command(['sudo', 'pacman', '-Syu', '--needed', *names], args.dry_run)
    command(['flatpak', 'remote-add', '--user', '--if-not-exists', 'flathub',
             'https://dl.flathub.org/repo/flathub.flatpakrepo'], args.dry_run)
    for line in (ROOT / 'packages/flatpak.tsv').read_text().splitlines():
        if line.strip():
            app, origin = line.split('\t')
            command(['flatpak', 'install', '--user', origin, app], args.dry_run)


def extras(args):
    home = home_path(args.home)
    env = dict(os.environ, HOME=str(home))
    venv = home / '.local/share/waypaper-venv'
    command(['python', '-m', 'venv', '--system-site-packages', venv], args.dry_run)
    command([venv / 'bin/python', '-m', 'pip', 'install', '-r', ROOT / 'packages/waypaper.txt'], args.dry_run)
    if args.dry_run:
        print('Would install the preserved Waypaper app.py patch into that environment.')
    else:
        result = subprocess.check_output([str(venv / 'bin/python'), '-c',
                 'import waypaper; print(waypaper.__path__[0])'], text=True).strip()
        app = Path(result) / 'app.py'
        if not app.resolve().is_relative_to(venv.resolve()):
            raise ValueError('Refusing to patch a system Waypaper installation')
        # Keep original installed upstream file for inspection.
        original = app.with_suffix('.py.upstream')
        if not original.exists():
            shutil.copy2(app, original)
        put(app, {'data': render((ROOT / 'vendor/waypaper/app.py').read_text(), args).encode(), 'mode': 0o644})
    command([sys.executable, ROOT / 'tools/build_hyprbars.py', '--home', home,
             *(['--dry-run'] if args.dry_run else [])], args.dry_run, env=env)
    command(['fc-cache', '-f', home / '.local/share/fonts'], args.dry_run)
    command(['update-desktop-database', home / '.local/share/applications'], args.dry_run)


def activate(args):
    if args.component == 'system':
        # Enable for next boot; do not start display manager in an existing session.
        command(['sudo', 'systemctl', 'enable', 'NetworkManager.service', 'bluetooth.service',
                 'sddm.service', 'systemd-timesyncd.service', 'fstrim.timer'], args.dry_run)
        command(['sudo', 'timedatectl', 'set-timezone', 'Europe/Prague'], args.dry_run)
        print('Ensure en_US.UTF-8 and cs_CZ.UTF-8 are enabled in /etc/locale.gen, then sudo locale-gen.')
        if args.profile == 'current-pc':
            command(['sudo', 'mkinitcpio', '-P'], args.dry_run)
    else:
        if home_path(args.home) != Path.home().resolve():
            raise ValueError('User activation must run as the target user with its real HOME')
        command(['systemctl', '--user', 'daemon-reload'], args.dry_run)
        print('Captured enable links take effect on the next login. No restart requested.')


def check(args):
    entries = selected(args)
    count = 0
    for e in entries:
        value = desired(e, args)
        if 'data' not in value or not e.get('text'):
            continue
        text = value['data'].decode()
        if any(t in text for t in ('@HOME@', '@PRIMARY_MONITOR@', '@DOCK_OUTPUT@')):
            raise ValueError(f'Unrendered token: {e["target"]}')
        first = text.splitlines()[0] if text.splitlines() else ''
        if first.startswith('#!') and 'python' in first:
            ast.parse(text, filename=e['target'])
            count += 1
        elif first.startswith('#!') and ('bash' in first or first.endswith('/sh')) or e['target'] in ('.bashrc','.bash_profile','.bash_logout'):
            subprocess.run(['bash', '-n'], input=text, text=True, check=True)
            count += 1
        if e['target'].endswith('.json'):
            json.loads(text)
            count += 1
    print(f'Manifest and {count} script/JSON syntax checks passed ({len(entries)} entries).')
    if args.live:
        for argv in [['hyprctl','configerrors'], ['systemctl','--user','--failed','--no-pager']]:
            command(argv)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['install','sync','restore','check','packages','extras','activate'])
    parser.add_argument('--profile', choices=['generic','current-pc'], default='generic')
    parser.add_argument('--component', choices=['user','system','workspace'], default='user')
    parser.add_argument('--home', default=str(Path.home()))
    parser.add_argument('--system-root', default='/')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--backup', help='Exact backup directory used by restore')
    parser.add_argument('--live', action='store_true', help='check: read running session status')
    args = parser.parse_args()
    if args.action == 'restore' and not args.backup:
        parser.error('restore requires --backup')
    try:
        globals()[args.action](args)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())

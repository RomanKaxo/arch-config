#!/usr/bin/env python3
"""Build preserved hyprbars against current installed headers, with an ABI guard."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--home', default=str(Path.home()))
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    home = Path(args.home).resolve()
    if args.dry_run:
        print('Would build vendor/hyprbars with cmake using installed Hyprland headers; save matching ABI.')
        return
    # Obtain build ABI from headers, never from an old running compositor after an upgrade.
    flags = shlex.split(subprocess.check_output(['pkg-config','--cflags','hyprland'], text=True))
    candidates = [Path(flag[2:]) / suffix for flag in flags if flag.startswith('-I')
                  for suffix in ('hyprland/src/version.h','src/version.h','version.h')]
    header = next((p for p in candidates if p.is_file()), None)
    if header is None:
        raise SystemExit('Missing installed Hyprland version header; install Hyprland development headers.')
    text = header.read_text()
    defines = dict(re.findall(r'#define\s+(\w+)\s+"([^"]+)"', text))
    try:
        abi = defines['GIT_COMMIT_HASH']
        for suffix, key in [('aq','AQUAMARINE'),('hu','HYPRUTILS'),('hg','HYPRGRAPHICS'),('hc','HYPRCURSOR'),('hlg','HYPRLANG')]:
            version = defines[key + '_VERSION']
            abi += '_' + suffix + '_' + (version.rsplit('.',1)[0] if '.' in version else version)
    except KeyError:
        raise SystemExit('Cannot determine installed Hyprland ABI. Plugin was not changed.')
    with tempfile.TemporaryDirectory(prefix='arch-config-hyprbars-') as temporary:
        work = Path(temporary)
        shutil.copytree(ROOT / 'vendor/hyprbars', work / 'source')
        subprocess.run(['cmake','-S',str(work/'source'),'-B',str(work/'build'),'-DCMAKE_BUILD_TYPE=Release'],check=True)
        subprocess.run(['cmake','--build',str(work/'build'),'-j',str(min(os.cpu_count() or 2,4))],check=True)
        built = work / 'build/libhyprbars.so'
        if not built.is_file():
            raise SystemExit('Expected plugin build output missing')
        target = home / '.local/lib/hyprland'
        target.mkdir(parents=True,exist_ok=True)
        meta = dict(abi=abi,source='https://github.com/hyprwm/hyprland-plugins',
                    commit='7644cecdb947060682891a0db2a0cdc5c0b9e704',
                    sha256=hashlib.sha256(built.read_bytes()).hexdigest())
        for name in ['hyprbars.so','hyprbars.json']:
            p=target/name
            if p.exists():
                shutil.copy2(p,p.with_name(name+'.previous'))
        shutil.copy2(built,target/'hyprbars.so')
        (target/'hyprbars.json').write_text(json.dumps(meta,indent=2)+'\n')
        print('Plugin rebuilt. Loader checks ABI and checksum before loading; no session reload performed.')


if __name__=='__main__':
    main()

#!/usr/bin/env python3
"""Install the pinned, checksum-verified upstream DeepFilterNet LADSPA binary."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    if args.dry_run:
        print('Would build vendor/deepfilter with makepkg (upstream SHA-256 verified) and install using pacman -U.')
        return
    if os.geteuid() == 0:
        raise SystemExit('Run as a normal user; pacman requests sudo only for installation.')
    installed = subprocess.run(['pacman', '-Q', 'libdeep_filter_ladspa-bin'], capture_output=True, text=True)
    if installed.returncode == 0 and installed.stdout.split()[1] == '0.5.6-1':
        print('DeepFilterNet 0.5.6-1 is already installed.')
        return
    with tempfile.TemporaryDirectory(prefix='arch-config-deepfilter-') as temporary:
        work = Path(temporary)
        for name in ('PKGBUILD', 'libdeep_filter_ladspa.install'):
            shutil.copy2(ROOT / 'vendor/deepfilter' / name, work / name)
        subprocess.run(['makepkg', '--noconfirm'], cwd=work, check=True)
        package = work / 'libdeep_filter_ladspa-bin-0.5.6-1-x86_64.pkg.tar.zst'
        if not package.is_file():
            raise SystemExit('Expected DeepFilterNet package was not built.')
        subprocess.run(['sudo', 'pacman', '-U', '--needed', str(package)], check=True)


if __name__ == '__main__':
    main()

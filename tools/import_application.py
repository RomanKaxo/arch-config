#!/usr/bin/env python3
"""Import an already unpacked trusted vendor distribution, never its account data."""
import argparse
from pathlib import Path
import os
import shutil
import sys
import tempfile


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app',choices=['vscode','chatgpt','codex'])
    parser.add_argument('--source',required=True,help='Unpacked application root, or standalone Codex executable')
    parser.add_argument('--home',default=str(Path.home()))
    parser.add_argument('--dry-run',action='store_true')
    args=parser.parse_args()
    source=Path(args.source).expanduser().resolve(strict=True)
    home=Path(args.home).expanduser().resolve()
    required={'vscode':'bin/code','chatgpt':'usr/lib/chatgpt/codex-launcher'}
    if args.app=='codex':
        if not source.is_file() or not os.access(source,os.X_OK):raise ValueError('Source must be an executable')
    elif not source.is_dir() or not (source/required[args.app]).is_file():
        raise ValueError('Source is not the expected unpacked vendor distribution')
    target=home/'.local/opt'/args.app
    link=home/'.local/bin'/('code' if args.app=='vscode' else args.app)
    for dest in [target,link]:
        if dest.exists() or dest.is_symlink():raise ValueError(f'Existing installation retained; choose a fresh HOME or migrate manually: {dest}')
        for parent in dest.parents:
            if parent==home:break
            if parent.is_symlink():raise ValueError(f'Directory symlink would redirect write: {parent}')
    print(f'Import {source} -> {target}; launcher {link}')
    if args.dry_run:return
    target.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.arch-config-app-',dir=target.parent) as temporary:
        staging=Path(temporary)/'payload'
        if args.app=='codex':
            staging.mkdir();shutil.copy2(source,staging/'codex')
        else:
            shutil.copytree(source,staging,symlinks=True)
        os.replace(staging,target)
    link.parent.mkdir(parents=True,exist_ok=True)
    link.symlink_to(target/('codex' if args.app=='codex' else required[args.app]))
    print('Imported. Account/profile directories were not copied.')


if __name__=='__main__':
    try:main()
    except (ValueError,OSError) as error:
        print(f'ERROR: {error}',file=sys.stderr);sys.exit(1)

#!/usr/bin/env python3
"""Scan only repository content; report paths, never matching secret values."""
import json
from pathlib import Path
import re
import sys
import subprocess

ROOT=Path(__file__).resolve().parents[1]
BAD_NAMES={'.bash_history','.zsh_history','auth.json','hosts.yml','credentials','credentials.json','cookies','Cookies','Login Data','id_rsa','id_ed25519'}
PATTERNS=[re.compile(r'-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----'),
          re.compile(r'\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{50,})\b'),
          re.compile(r'\bAKIA[A-Z0-9]{16}\b'),
          re.compile(r'\bsk-(?:proj-)?[A-Za-z0-9_-]{35,}\b')]
manifest=json.loads((ROOT/'manifest.json').read_text())
errors=[];seen=set();files=0
for e in manifest['entries']:
    key=(e['component'],e['profile'],e['target'])
    if key in seen:errors.append(('manifest.json','duplicate destination'))
    seen.add(key)
    p=Path(e['target'])
    if p.is_absolute() or '..' in p.parts:errors.append(('manifest.json','unsafe destination'))
    if any(part in BAD_NAMES for part in p.parts):errors.append((e['target'],'credential/history filename'))
for p in ROOT.rglob('*'):
    rel=p.relative_to(ROOT)
    if any(part in ('.git','__pycache__','.cache') for part in rel.parts) or not p.is_file():continue
    files+=1
    if p.name in BAD_NAMES:errors.append((str(rel),'credential filename'))
    if p.stat().st_size>95*1024*1024:errors.append((str(rel),'exceeds repository file size policy'))
    try:text=p.read_text()
    except UnicodeDecodeError:continue
    if any(pattern.search(text) for pattern in PATTERNS):errors.append((str(rel),'secret-like value'))
    if rel.parts and rel.parts[0]=='payload' and '/home/roman' in text:errors.append((str(rel),'fixed home'))
if (ROOT/'.git').exists():
    tracked=set(subprocess.check_output(['git','-C',str(ROOT),'ls-files','--cached'],text=True).splitlines())
    for e in manifest['entries']:
        if 'link' not in e and e['source'] not in tracked:
            errors.append((e['source'],'payload absent from Git index'))
for rel,reason in errors:print(f'{reason}: {rel}')
print(f'Audit: {files} files, {len(manifest["entries"])} manifest entries, {len(errors)} findings.')
sys.exit(bool(errors))

"""A forking clipboard helper must not block subsequent PrintScreen invocations."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT=Path(__file__).resolve().parents[1]/'payload/user/all/.local/bin/desktop-screenshot'

class ScreenshotTests(unittest.TestCase):
    def test_region_and_full_repeat_immediately_despite_forking_clipboard(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); bin=root/'bin';bin.mkdir();runtime=root/'run';runtime.mkdir()
            scripts={
                'xdg-user-dir':'#!/bin/sh\nprintf "%s\\n" "$TEST_PICTURES"\n',
                'slurp':'#!/bin/sh\nprintf "0,0 10x10\\n"\n',
                'grim':'#!/bin/sh\nfor file do :; done\nprintf image > "$file"\n',
                'wl-copy':'#!/bin/sh\ncat > /dev/null\nsleep 0.8 >/dev/null 2>&1 &\n',
                'notify-send':'#!/bin/sh\nexit 0\n',
            }
            for name,body in scripts.items():
                p=bin/name;p.write_text(body);p.chmod(0o755)
            env=dict(os.environ,PATH=str(bin)+':'+os.environ['PATH'],XDG_RUNTIME_DIR=str(runtime),TEST_PICTURES=str(root/'pictures'))
            for mode in ['region','region','full','region']:
                subprocess.run(['bash',str(SCRIPT),mode],env=env,check=True,timeout=1)
            self.assertEqual(len(list((root/'pictures/Screenshots').glob('*.png'))),4)
            # The child still runs; its inherited descriptors must not retain the selector lock.
            lock=runtime/'desktop-screenshot-selection.lock'
            subprocess.run(['flock','-n',str(lock),'true'],check=True,timeout=1)

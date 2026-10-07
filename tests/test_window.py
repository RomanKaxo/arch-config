"""Minimization isolates a window without hiding other windows or monitors."""
import contextlib
import io
import json
import os
from pathlib import Path
import re
import runpy
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'payload/user/all/.local/bin/desktop-window'


def client(address='0xabc', pid=10, workspace='1', pinned=False):
    return dict(address=address, pid=pid, workspace={'name': workspace},
                pinned=pinned, title='Title', **{'class': 'kitty'})


class WindowTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.state = Path(self.temp.name) / 'midnight-minimized.json'
        self.commands = []
        self.clients = [client(), client('0xdef', pid=20)]
        self.monitors = [
            {'name': 'DP-1', 'focused': True, 'specialWorkspace': {'name': ''}},
            {'name': 'HDMI-1', 'focused': False, 'specialWorkspace': {'name': 'special:minimized'}},
        ]

    def run_action(self, action, address='0xabc'):
        def output(args, **kwargs):
            if args[:2] == ['hyprctl', '-j']:
                return json.dumps({'clients': self.clients, 'monitors': self.monitors,
                                   'activewindow': self.clients[0],
                                   'activeworkspace': {'name': '1'}}[args[2]])
            self.assertEqual(args[:2], ['hyprctl', 'dispatch'])
            expression = args[2]
            self.commands.append(expression)
            if expression.startswith('hl.dsp.window.move('):
                target = re.search(r'window="address:([^"]+)"', expression).group(1)
                workspace = re.search(r'workspace=("(?:[^"\\]|\\.)*")', expression).group(1)
                next(w for w in self.clients if w['address'] == target)['workspace']['name'] = json.loads(workspace)
            return 'ok\n'

        stdout = io.StringIO()
        args = [str(SCRIPT), action] + ([address] if address else [])
        with patch.dict(os.environ, {'XDG_RUNTIME_DIR': self.temp.name}), \
                patch('sys.argv', args), patch('subprocess.check_output', side_effect=output), \
                contextlib.redirect_stdout(stdout):
            try:
                runpy.run_path(str(SCRIPT), run_name='__main__')
            except SystemExit as error:
                if error.code not in (0, None):
                    raise
        return stdout.getvalue()

    def assert_only_selected_window_moved(self, original_monitors, other_workspace):
        self.assertEqual(self.monitors, original_monitors)
        self.assertEqual(self.clients[1]['workspace']['name'], other_workspace)
        moves = [cmd for cmd in self.commands if cmd.startswith('hl.dsp.window.move(')]
        self.assertEqual(len(moves), 1)
        self.assertIn('follow=false,window="address:0xabc"', moves[0])
        self.assertFalse(any('toggle_special' in cmd or 'monitor=' in cmd for cmd in self.commands))

    def test_normal_minimize_preserves_other_window_and_monitor(self):
        before = json.loads(json.dumps(self.monitors))
        self.run_action('minimize')
        self.assert_only_selected_window_moved(before, '1')
        self.assertEqual(self.clients[0]['workspace']['name'], 'special:minimized-0xabc')

    def test_reminimize_from_shared_dock_workspace_hides_only_chosen_window(self):
        for w in self.clients:
            w['workspace']['name'] = 'special:minimized'
        self.monitors[0]['specialWorkspace']['name'] = 'special:minimized'
        origin = {'workspace': '3', 'pid': 10, 'pinned': True}
        self.state.write_text(json.dumps({'0xabc': origin}))
        before = json.loads(json.dumps(self.monitors))
        self.run_action('minimize')
        self.assert_only_selected_window_moved(before, 'special:minimized')
        self.assertEqual(json.loads(self.state.read_text())['0xabc'], origin)
        self.run_action('restore')
        self.assertEqual(self.clients[0]['workspace']['name'], '3')
        self.assertIn('action="enable"', self.commands[-1])

    def test_reminimize_avoids_visible_and_occupied_individual_workspaces(self):
        self.clients[0]['workspace']['name'] = 'special:minimized-0xabc'
        self.clients[1]['workspace']['name'] = 'special:minimized-0xabc-1'
        self.monitors[0]['specialWorkspace']['name'] = 'special:minimized-0xabc'
        self.monitors[1]['specialWorkspace']['name'] = 'special:minimized-0xabc-2'
        before = json.loads(json.dumps(self.monitors))
        self.run_action('minimize')
        self.assert_only_selected_window_moved(before, 'special:minimized-0xabc-1')
        self.assertEqual(self.clients[0]['workspace']['name'], 'special:minimized-0xabc-3')

    def test_status_and_restore_accept_old_and_individual_minimized_windows(self):
        self.clients[0]['workspace']['name'] = 'special:minimized-0xabc'
        self.clients[1]['workspace']['name'] = 'special:minimized'
        self.assertEqual(json.loads(self.run_action('status', address=None))['text'], '󰖰 2')
        self.run_action('restore')
        self.assertEqual(self.clients[0]['workspace']['name'], '1')
        self.assertEqual(self.clients[1]['workspace']['name'], 'special:minimized')

    def test_scratchpad_is_left_untouched(self):
        self.clients[0]['workspace']['name'] = 'special:scratchpad'
        self.run_action('minimize')
        self.assertEqual(self.commands, [])
        self.assertFalse(self.state.exists())

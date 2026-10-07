"""Verify restored panels wait for the correct mapped surface without a live session."""
import json
from pathlib import Path
import runpy
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]


def layer(pid=123, width=1920):
    return {'levels': {'1': [{'namespace': 'waybar', 'pid': pid, 'w': width, 'h': 40}]}}


class TaskbarReadyTests(unittest.TestCase):
    def run_ready(self, profile, snapshots):
        reads = []
        for snapshot in snapshots:
            reads.extend(['123\n', json.dumps(snapshot)])
        script = ROOT / f'payload/user/{profile}/.local/bin/desktop-taskbar-ready'
        with mock.patch('subprocess.check_output', side_effect=reads) as read, \
                mock.patch('time.monotonic', return_value=0), mock.patch('time.sleep') as sleep:
            with self.assertRaises(SystemExit) as result:
                runpy.run_path(str(script))
        self.assertEqual(result.exception.code, 0)
        return read.call_count, sleep.call_count

    def test_current_pc_waits_for_dp2_and_the_current_top_bar_pid(self):
        reads, waits = self.run_ready('current-pc', [
            {'HDMI-A-1': layer()},
            {'DP-2': layer(pid=456)},
            {'DP-2': layer(width=0)},
            {'DP-2': layer()},
        ])
        self.assertEqual((reads, waits), (8, 3))

    def test_generic_waits_for_all_outputs_without_connector_assumptions(self):
        reads, waits = self.run_ready('generic', [
            {},
            {'eDP-1': layer(), 'USB-C-1': {'levels': {}}},
            {'eDP-1': layer(), 'USB-C-1': layer()},
        ])
        self.assertEqual((reads, waits), (6, 2))

    def test_missing_top_bar_times_out_instead_of_starting_disconnected(self):
        script = ROOT / 'payload/user/generic/.local/bin/desktop-taskbar-ready'
        with mock.patch('time.monotonic', side_effect=[0, 6]), \
                mock.patch('subprocess.check_output') as read:
            with self.assertRaisesRegex(SystemExit, 'did not map'):
                runpy.run_path(str(script))
        read.assert_not_called()


if __name__ == '__main__':
    unittest.main()

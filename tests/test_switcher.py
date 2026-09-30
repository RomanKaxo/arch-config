"""MRU filtering and activation protect against stale compositor handles."""
import importlib.machinery
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'payload/user/all/.local/bin/desktop-switcher'
loader = importlib.machinery.SourceFileLoader('switcher', str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
switcher = importlib.util.module_from_spec(spec)
loader.exec_module(switcher)


def client(address='0xabc', pid=10, history=0, workspace='1', mapped=True):
    return dict(address=address, pid=pid, focusHistoryID=history,
                workspace={'name':workspace}, mapped=mapped, title='Title', **{'class':'kitty'})


class SwitcherTests(unittest.TestCase):
    def test_mru_includes_minimized_and_other_desktops_but_excludes_internal_windows(self):
        data = [client(history=3), client('0xdef', history=0, workspace='2'),
                client('0xaaa', history=1, workspace='special:minimized'),
                client('0xbbb', history=2, workspace='special:scratchpad'),
                client('0xccc', history=4, mapped=False), client('0xddd', history=-1)]
        result = switcher.snapshot(data)
        self.assertEqual([w['address'] for w in result], ['0xdef', '0xaaa', '0xabc', '0xddd'])
        self.assertTrue(result[1]['minimized'])

    @patch.object(switcher.subprocess, 'check_output', return_value='{}')
    @patch.object(switcher, 'clients', return_value=[client(pid=20)])
    def test_recycled_address_does_not_activate_another_process(self, clients, command):
        self.assertFalse(switcher.activate('0xabc', 10))
        self.assertEqual(command.call_args.args[0], ['hyprctl','-j','layers'])

    @patch.object(switcher, 'clients', return_value=[])
    @patch.object(switcher.subprocess, 'check_output', return_value='{}')
    def test_closed_window_is_ignored(self, command, clients):
        self.assertFalse(switcher.activate('0xabc', 10))

    @patch.object(switcher, 'clients')
    def test_invalid_address_is_rejected_before_accessing_compositor(self, clients):
        with self.assertRaises(ValueError):
            switcher.activate('bad Lua injection', 10)
        clients.assert_not_called()

    @patch.object(switcher.subprocess, 'check_output', side_effect=['{}','ok\n'])
    @patch.object(switcher.subprocess, 'run')
    @patch.object(switcher, 'clients', return_value=[client(workspace='special:minimized')])
    def test_restore_precedes_atomic_focus_and_explicit_maximization(self, clients, restore, command):
        self.assertTrue(switcher.activate('0xabc', 10))
        self.assertEqual(restore.call_args.args[0][-2:], ['restore','0xabc'])
        args=command.call_args.args[0]
        self.assertEqual(args[:2], ['hyprctl','eval'])
        self.assertLess(args[2].index('hl.dsp.focus'), args[2].index('fullscreen_state'))
        self.assertIn('internal=1,client=1,action="set"', args[2])
        self.assertNotIn('toggle', args[2])

    @patch.object(switcher.subprocess, 'check_output')
    @patch.object(switcher, 'clients', return_value=[client(pid=20)])
    def test_recycled_address_is_not_closed(self, clients, command):
        self.assertFalse(switcher.close('0xabc', 10))
        command.assert_not_called()

    @patch.object(switcher, 'clients')
    def test_invalid_close_address_is_rejected_before_accessing_compositor(self, clients):
        with self.assertRaises(ValueError):
            switcher.close('bad Lua injection', 10)
        clients.assert_not_called()

    @patch.object(switcher.subprocess, 'check_output', return_value='ok\n')
    @patch.object(switcher, 'clients', return_value=[client()])
    def test_close_targets_only_the_verified_window(self, clients, command):
        self.assertTrue(switcher.close('0xabc', 10))
        self.assertEqual(command.call_args.args[0], ['hyprctl', 'eval', 'hl.dispatch(hl.dsp.window.close({window="address:0xabc"}))'])

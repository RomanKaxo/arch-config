"""Window activation restores individual parked windows and reveals tiled peers."""
import json
from pathlib import Path
import shutil
import subprocess
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'payload/user/all/.config/hypr/tiling.lua'

FIXTURE = r'''
local handlers, windows, commands = {}, {}, {}
local desktop = {name = "1", special = false}
local monitor = {active_workspace = desktop}
local function window(address, workspace, fullscreen, floating)
    local w = {address = address, workspace = workspace or desktop, monitor = monitor,
        mapped = true, hidden = false, floating = floating or false,
        fullscreen = fullscreen or 0, fullscreen_client = fullscreen or 0}
    table.insert(windows, w)
    return w
end
local function dispatcher(kind)
    return function(options) return {kind = kind, options = options} end
end
hl = {
    window_rule = function(_) end,
    on = function(event, callback) handlers[event] = callback end,
    get_workspace_windows = function(name)
        local result = {}
        for _, w in ipairs(windows) do
            if w.workspace.name == name then table.insert(result, w) end
        end
        return result
    end,
    dsp = {window = {fullscreen_state = dispatcher("fullscreen"), move = dispatcher("move")},
        workspace = {toggle_special = dispatcher("special")}, focus = dispatcher("focus")},
    dispatch = function(command)
        table.insert(commands, command)
        local opts = command.options
        if command.kind == "fullscreen" then
            opts.window.fullscreen, opts.window.fullscreen_client = opts.internal, opts.client
        elseif command.kind == "move" then
            assert(opts.workspace == desktop.name and opts.follow)
            opts.window.workspace = desktop
            handlers["window.active"](opts.window)
        elseif command.kind == "special" then
            assert(opts == monitor.active_special_workspace.name:sub(9))
            monitor.active_special_workspace = nil
        elseif command.kind == "focus" then
            handlers["window.active"](opts.window)
        end
    end,
}
'''


@unittest.skipUnless(shutil.which('lua'), 'Lua is required to exercise Hyprland callbacks')
class TilingTests(unittest.TestCase):
    def scenario(self, script):
        source = FIXTURE + '\ndofile(' + json.dumps(str(SCRIPT)) + ')\n' + script
        result = subprocess.run(['lua', '-'], input=source, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_new_window_reveals_maximized_peer(self):
        self.scenario('''
local old, new = window("old", nil, 1), window("new")
handlers["window.open"](new)
assert(old.fullscreen == 0 and old.fullscreen_client == 0)
assert(new.fullscreen == 0 and #commands == 1)
''')

    def test_dock_focus_unmaximizes_existing_window(self):
        self.scenario('''
local old, selected = window("old"), window("selected", nil, 1)
handlers["window.active"](selected)
assert(selected.fullscreen == 0 and old.workspace == selected.workspace)
''')

    def test_shared_parking_restores_only_selected_window(self):
        self.scenario('''
local parked = {name = "special:minimized", special = true}
monitor.active_special_workspace = parked
local old = window("old", nil, 1)
local selected, other = window("selected", parked, 1), window("other", parked)
handlers["window.active"](selected)
assert(selected.workspace == desktop and other.workspace == parked)
assert(old.fullscreen == 0 and selected.fullscreen == 0)
assert(monitor.active_special_workspace == nil)
assert(#commands == 5)
''')

    def test_individual_parking_clears_saved_fullscreen(self):
        self.scenario('''
local parked = {name = "special:minimized-0xabc", special = true}
monitor.active_special_workspace = parked
local selected = window("selected", parked, 2)
handlers["window.active"](selected)
assert(selected.workspace == desktop and selected.fullscreen == 0)
''')

    def test_explicit_fullscreen_and_floating_dialog_are_preserved(self):
        self.scenario('''
local video = window("video", nil, 2)
local dialog = window("dialog", nil, 0, true)
handlers["window.open"](dialog)
handlers["window.active"](video)
assert(video.fullscreen == 2 and #commands == 0)
''')

    def test_other_special_workspace_is_untouched(self):
        self.scenario('''
local scratch = {name = "special:scratchpad", special = true}
local selected = window("selected", scratch, 1)
handlers["window.active"](selected)
assert(selected.workspace == scratch and selected.fullscreen == 1 and #commands == 0)
''')

    def test_alt_tab_can_explicitly_maximize_after_focus(self):
        self.scenario('''
local old, selected = window("old", nil, 1), window("selected")
handlers["window.active"](selected)
hl.dispatch(hl.dsp.window.fullscreen_state({window = selected, internal = 1, client = 1}))
assert(old.fullscreen == 0 and selected.fullscreen == 1)
''')

    def test_single_window_keeps_manual_maximization(self):
        self.scenario('''
local selected = window("selected", nil, 1)
handlers["window.active"](selected)
assert(selected.fullscreen == 1 and #commands == 0)
''')

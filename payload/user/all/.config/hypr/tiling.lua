-- Deliberate activation restores parked windows into the visible desktop, then tiles.
-- Alt-Tab can still explicitly maximize its selection after focusing it.
hl.window_rule({
    name = "desktop-window-behavior", match = {class = ".*"},
    suppress_event = "maximize", focus_on_activate = false,
})
local arranging = false

-- Hyprland 0.56.2: src/desktop/state/FocusState.hpp (eFocusReason).
-- Forced foreign-toplevel activation from the taskbar uses desktop-state-change;
-- app activation requests are kept from taking focus by the rule above.
local deliberateFocus = {
    [2] = true, -- keybind
    [3] = true, -- focus-window dispatcher, including Alt-Tab / explicit restore
    [5] = true, -- click
    [7] = true, -- taskbar activation
    [9] = true, -- hard switch-to-window
}
local specialWorkspaceFocus = 12

local function isMinimized(workspace)
    return workspace and (workspace.name == "special:minimized"
        or workspace.name:match("^special:minimized%-"))
end

local function unmaximize(window)
    if window.fullscreen ~= 0 or window.fullscreen_client ~= 0 then
        hl.dispatch(hl.dsp.window.fullscreen_state({
            window = window, internal = 0, client = 0,
            action = "set", layout_aware = false,
        }))
    end
end

local function arrange(window)
    if arranging or not window or not window.mapped then return end
    arranging = true
    local ok, err = pcall(function()
        local workspace = window.workspace
        if isMinimized(workspace) then
            local parkedName = workspace.name
            local monitor = window.monitor
            local destination = monitor and monitor.active_workspace
            if not destination or destination.special then return end
            unmaximize(window)
            hl.dispatch(hl.dsp.window.move({
                window = window, workspace = destination.name, follow = true,
            }))
            -- Older parked workspaces may contain more than the selected window.
            local overlay = monitor.active_special_workspace
            if overlay and overlay.name == parkedName then
                hl.dispatch(hl.dsp.workspace.toggle_special(parkedName:sub(9)))
            end
            hl.dispatch(hl.dsp.focus({window = window}))
            workspace = destination
        end
        if not workspace or workspace.special or window.floating then return end
        local tiled = {}
        for _, candidate in ipairs(hl.get_workspace_windows(workspace.name)) do
            if candidate.mapped and not candidate.hidden and not candidate.floating then
                table.insert(tiled, candidate)
            end
        end
        if #tiled < 2 then return end
        for _, candidate in ipairs(tiled) do
            -- Explicit fullscreen videos/games retain their requested mode.
            if candidate.fullscreen == 1 then unmaximize(candidate) end
        end
    end)
    arranging = false
    if not ok then error(err) end
end

hl.on("window.active", function(window, reason)
    if not window or not window.mapped then return end
    if isMinimized(window.workspace) then
        -- Activating a hidden parked window first opens its special workspace.
        -- Only recover the selected window while that exact overlay is open.
        local monitor = window.monitor
        local overlay = monitor and monitor.active_special_workspace
        if not overlay or overlay.name ~= window.workspace.name then return end
        if reason ~= specialWorkspaceFocus and not deliberateFocus[reason] then return end
    elseif not deliberateFocus[reason] then
        -- Hover, workspace changes, layer dismissal and close fallback keep layout.
        return
    end
    arrange(window)
end)

hl.on("window.open", function(window)
    -- Background windows and children of parked apps must not reveal their peers.
    if not window or not window.mapped or isMinimized(window.workspace) then return end
    local active = hl.get_active_window()
    if active and active.address == window.address then arrange(window) end
end)

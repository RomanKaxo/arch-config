-- Dock activation restores parked windows into the visible desktop, then tiles.
-- Alt-Tab can still explicitly maximize its selection after focusing it.
hl.window_rule({name = "desktop-ignore-app-maximize", match = {class = ".*"}, suppress_event = "maximize"})
local arranging = false

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

hl.on("window.active", arrange)
hl.on("window.open", arrange)

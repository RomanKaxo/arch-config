-- Hyprland 0.56: graphite / blue desktop. Original configuration is backed up.
-- Modes read from hyprctl monitors all on 2026-09-28. Preserve existing positions.
dofile(os.getenv("HOME") .. "/.config/hypr/hardware.lua")

hl.env("XDG_DATA_DIRS", os.getenv("HOME") .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct:qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")

hl.config({
    input = {kb_layout = "cz,us", kb_variant = ",", kb_options = "grp:alt_shift_toggle", numlock_by_default = true},
    general = {
        gaps_in = 5, gaps_out = 10, border_size = 2, resize_on_border = true,
    },
    decoration = {
        rounding = 16, active_opacity = 1.0, inactive_opacity = 0.98, fullscreen_opacity = 1.0,
        blur = {enabled = true, size = 5, passes = 2, noise = 0.01, vibrancy = 0.06},
        shadow = {enabled = true, range = 20, render_power = 3, color = "rgba(00000044)"},
    },
    animations = {enabled = true},
    dwindle = {preserve_split = true},
    misc = {disable_hyprland_logo = true, disable_splash_rendering = true},
})
-- Motion uses deciseconds: 1.6 = 160 ms. No overshoot or springs.
hl.curve("desktop", {type = "bezier", points = {{0.22, 1}, {0.36, 1}}})
hl.curve("desktopExit", {type = "bezier", points = {{0.4, 0}, {1, 1}}})
hl.animation({leaf = "global", enabled = true, speed = 2.2, bezier = "desktop"})
hl.animation({leaf = "windowsIn", enabled = true, speed = 2.2, bezier = "desktop", style = "popin 97%"})
hl.animation({leaf = "windowsOut", enabled = true, speed = 1.6, bezier = "desktopExit", style = "popin 97%"})
hl.animation({leaf = "windowsMove", enabled = true, speed = 2.2, bezier = "desktop"})
hl.animation({leaf = "fade", enabled = true, speed = 1.8, bezier = "desktop"})
hl.animation({leaf = "border", enabled = true, speed = 1.6, bezier = "desktop"})
hl.animation({leaf = "workspaces", enabled = true, speed = 2.6, bezier = "desktop", style = "slidefade 12%"})
hl.animation({leaf = "layers", enabled = true, speed = 2.2, bezier = "desktop", style = "fade"})
hl.layer_rule({name = "desktop-panel-blur", match = {namespace = "^(waybar|nwg-drawer|launcher|desktop-launcher|desktop-dashboard|desktop-control|desktop-wallpapers|nwg-dock|swaync-control-center|swaync-notification-window)$"}, blur = true, ignore_alpha = 0.2})
-- Custom panels animate their own geometry; avoid applying two fades at once.
hl.layer_rule({name = "desktop-native-motion", match = {namespace = "^desktop-(launcher|dashboard|control|wallpapers)$"}, no_anim = true})
hl.layer_rule({name = "notification-motion", match = {namespace = "^swaync-notification-window$"}, animation = "slide top"})
hl.layer_rule({name = "history-motion", match = {namespace = "^swaync-control-center$"}, animation = "slide right"})

hl.on("hyprland.start", function()
    if desktopPrimaryMonitor then
        hl.dsp.focus({monitor = desktopPrimaryMonitor})()
        hl.exec_cmd("xrandr --output " .. desktopPrimaryMonitor .. " --primary")
    end
    hl.exec_cmd("$HOME/.local/bin/desktop-session start")
    hl.exec_cmd("kitty")
    hl.exec_cmd("$HOME/.local/bin/desktop-titlebars")
end)
hl.on("hyprland.shutdown", function()
    hl.exec_cmd("systemctl --user stop desktop-session.target graphical-session.target")
end)

local function launch(key, command, options)
    hl.bind(key, hl.dsp.exec_cmd(command), options)
end
launch("SUPER + Return", "kitty")
launch("SUPER + B", "firefox")
launch("SUPER + space", "@HOME@/.local/bin/desktop-panel toggleLauncher")
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("@HOME@/.local/bin/desktop-panel toggleLauncher"), {release = true, description = "Open Midnight app hub"})
launch("SUPER + E", "thunar")
launch("SUPER + L", "$HOME/.local/bin/desktop-lock")
launch("SUPER + N", "@HOME@/.local/bin/desktop-panel toggleControl")
launch("SUPER + D", "@HOME@/.local/bin/desktop-panel toggleDashboard")
launch("SUPER + CTRL + D", "$HOME/.local/bin/desktop-dock toggle")
launch("SUPER + SHIFT + V", "$HOME/.local/bin/desktop-clipboard")
launch("SUPER + SHIFT + W", "@HOME@/.local/bin/waypaper")
launch("SUPER + SHIFT + E", "$HOME/.local/bin/desktop-power")
launch("SUPER + SHIFT + T", "$HOME/.local/bin/desktop-theme")
launch("Print", "$HOME/.local/bin/desktop-screenshot region")
launch("SHIFT + Print", "$HOME/.local/bin/desktop-screenshot full")
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + V", hl.dsp.window.float({action = "toggle"}))
hl.bind("SUPER + F", hl.dsp.window.fullscreen())

-- Native window cycling also raises overlapping floating windows.
local function cycleWindow(forward)
    hl.dispatch(hl.dsp.window.cycle_next({next = forward, tiled = true, floating = true}))
    hl.dispatch(hl.dsp.window.bring_to_top())
end
hl.bind("ALT + Tab", function() cycleWindow(true) end, {repeating = true, description = "Next window"})
hl.bind("ALT + SHIFT + Tab", function() cycleWindow(false) end, {repeating = true, description = "Previous window"})

for _, direction in ipairs({"left", "right", "up", "down"}) do
    hl.bind("SUPER + " .. direction, hl.dsp.focus({direction = direction}))
end
-- Physical number-row keys work without Shift on both Czech and US layouts.
for workspace = 1, 9 do
    hl.bind("SUPER + code:" .. (workspace + 9), hl.dsp.focus({workspace = workspace}))
    hl.bind("SUPER + SHIFT + code:" .. (workspace + 9), hl.dsp.window.move({workspace = workspace}))
end
hl.bind("SUPER + mouse_down", hl.dsp.focus({workspace = "e+1"}))
hl.bind("SUPER + mouse_up", hl.dsp.focus({workspace = "e-1"}))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), {mouse = true})
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), {mouse = true})
launch("XF86AudioRaiseVolume", "$HOME/.local/bin/desktop-audio up", {locked = true, repeating = true})
launch("XF86AudioLowerVolume", "$HOME/.local/bin/desktop-audio down", {locked = true, repeating = true})
launch("XF86AudioMute", "$HOME/.local/bin/desktop-audio mute", {locked = true})
launch("XF86AudioMicMute", "$HOME/.local/bin/desktop-audio mic-mute", {locked = true})
launch("XF86AudioPlay", "playerctl play-pause", {locked = true})
launch("XF86AudioNext", "playerctl next", {locked = true})
launch("XF86AudioPrev", "playerctl previous", {locked = true})


-- Mouse window controls and recovery of minimized windows.
launch("SUPER + M", "$HOME/.local/bin/desktop-window minimize")
launch("SUPER + SHIFT + M", "$HOME/.local/bin/desktop-window restore")
dofile(os.getenv("HOME") .. "/.config/hypr/titlebars.lua")

dofile(os.getenv("HOME") .. "/.config/desktop/current/hypr.lua")

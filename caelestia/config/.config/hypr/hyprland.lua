-- Caelestia 2.5.0 on Roman's Arch Linux desktop.
hl.monitor({output = "DP-2", mode = "2560x1440@180", position = "0x0", scale = 1})
hl.monitor({output = "HDMI-A-1", mode = "1920x1080@180", position = "2560x0", scale = 1})
hl.monitor({output = "", mode = "preferred", position = "auto", scale = "auto"})
hl.workspace_rule({workspace = "1", monitor = "DP-2", default = true})
hl.workspace_rule({workspace = "2", monitor = "HDMI-A-1", default = true})

hl.env("XDG_DATA_DIRS", os.getenv("HOME") .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct:qt6ct")
hl.env("QT_STYLE_OVERRIDE", "Fusion")

hl.config({
    input = {kb_layout = "cz,us", kb_variant = ",", kb_options = "grp:alt_shift_toggle", numlock_by_default = true},
    general = {gaps_in = 4, gaps_out = 8, border_size = 2, resize_on_border = true},
    decoration = {
        rounding = 12, active_opacity = 1, inactive_opacity = 1,
        blur = {enabled = true, size = 10, passes = 2},
        shadow = {enabled = true, range = 20, render_power = 3, color = "rgba(00000044)"},
    },
    animations = {enabled = true},
    dwindle = {preserve_split = true, use_active_for_splits = true},
    misc = {disable_hyprland_logo = true, disable_splash_rendering = true, on_focus_under_fullscreen = 2},
})
local schemeFile = os.getenv("HOME") .. "/.config/hypr/scheme/current.lua"
local ok, colours = pcall(dofile, schemeFile)
if ok and colours.primary then
    hl.config({general = {col = {active_border = "rgb(" .. colours.primary .. ")", inactive_border = "rgb(" .. colours.outlineVariant .. ")"}}})
end
hl.curve("caelestia", {type = "bezier", points = {{0.22, 1}, {0.36, 1}}})
hl.animation({leaf = "global", enabled = true, speed = 3, bezier = "caelestia"})
hl.layer_rule({name = "caelestia-blur", match = {namespace = "^caelestia-.*$"}, blur = true, ignore_alpha = 0.2})
hl.layer_rule({name = "caelestia-motion", match = {namespace = "^caelestia-.*$"}, no_anim = true})

hl.on("hyprland.start", function()
    hl.dsp.focus({monitor = "DP-2"})()
    hl.exec_cmd("xrandr --output DP-2 --primary")
    hl.exec_cmd("$HOME/.local/bin/caelestia-session")
end)
hl.on("hyprland.shutdown", function()
    hl.exec_cmd("systemctl --user stop caelestia-shell.service caelestia-clipboard-text.service caelestia-clipboard-image.service caelestia-session.target")
end)

local function launch(key, command, options)
    hl.bind(key, hl.dsp.exec_cmd(command), options)
end
local cli = os.getenv("HOME") .. "/.local/bin/caelestia "
launch("SUPER + Return", "kitty")
launch("SUPER + B", "firefox")
launch("SUPER + E", "thunar")
launch("SUPER + space", cli .. "shell drawers toggle launcher")
launch("SUPER + SUPER_L", cli .. "shell drawers toggle launcher", {release = true})
launch("SUPER + N", cli .. "shell drawers toggle sidebar")
launch("SUPER + D", cli .. "shell drawers toggle dashboard")
launch("SUPER + L", cli .. "shell lock lock")
launch("SUPER + SHIFT + E", cli .. "shell drawers toggle session")
launch("SUPER + SHIFT + V", cli .. "clipboard")
launch("SUPER + SHIFT + W", cli .. "shell drawers toggle launcher")
launch("SUPER + CTRL + D", cli .. "shell drawers toggle utilities")
launch("Print", cli .. "screenshot -r")
launch("SHIFT + Print", cli .. "screenshot")
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + V", hl.dsp.window.float({action = "toggle"}))
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({previous = true}))
for _, direction in ipairs({"left", "right", "up", "down"}) do
    hl.bind("SUPER + " .. direction, hl.dsp.focus({direction = direction}))
end
for workspace = 1, 9 do
    hl.bind("SUPER + code:" .. (workspace + 9), hl.dsp.focus({workspace = workspace}))
    hl.bind("SUPER + SHIFT + code:" .. (workspace + 9), hl.dsp.window.move({workspace = workspace}))
end
hl.bind("SUPER + mouse_down", hl.dsp.focus({workspace = "e+1"}))
hl.bind("SUPER + mouse_up", hl.dsp.focus({workspace = "e-1"}))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), {mouse = true})
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), {mouse = true})
launch("XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", {locked = true, repeating = true})
launch("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", {locked = true, repeating = true})
launch("XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", {locked = true})
launch("XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", {locked = true})
launch("XF86MonBrightnessUp", "brightnessctl set +5%", {locked = true, repeating = true})
launch("XF86MonBrightnessDown", "brightnessctl set 5%-", {locked = true, repeating = true})
launch("XF86AudioPlay", "playerctl play-pause", {locked = true})
launch("XF86AudioNext", "playerctl next", {locked = true})
launch("XF86AudioPrev", "playerctl previous", {locked = true})

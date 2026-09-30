desktopPrimaryMonitor = "DP-2"
hl.monitor({output = "DP-2", mode = "2560x1440@180", position = "0x0", scale = 1})
hl.monitor({output = "HDMI-A-1", mode = "1920x1080@180", position = "2560x0", scale = 1})
hl.monitor({output = "", mode = "preferred", position = "auto", scale = "auto"})

-- AOC 1440p is the main display; MSI retains its own default workspace.
hl.workspace_rule({workspace = "1", monitor = "DP-2", default = true})
hl.workspace_rule({workspace = "2", monitor = "HDMI-A-1", default = true})


# Desktop setup — 28 September 2026

The desktop uses the installed Hyprland 0.56 Lua API. Main configuration:
`~/.config/hypr/hyprland.lua`.

For the seven palettes, added daily/gaming apps and current validation, see
`~/.config/desktop/README.md`.

## Controls

| Shortcut | Action |
| --- | --- |
| Super+Enter | Kitty |
| Super+B | Firefox |
| Super+Q | Close window |
| Super alone or Super+Space | Dark icon-grid application launcher |
| Super+E | Thunar |
| Super+L | Hyprlock |
| Super+1–9 | Workspaces, using physical number-row keys on both layouts |
| Super+Shift+1–9 | Move window to workspace |
| Super+mouse wheel | Previous/next existing workspace |
| Super+left/right drag | Move/resize window |
| Print | Select screenshot region; Escape cancels |
| Shift+Print | Capture entire desktop, including both monitors |
| Alt+Shift | Switch Czech / US layout |
| Super+N | Notification center |
| Super+Shift+V | Clipboard history |
| Super+Shift+W | Wallpaper picker |
| Super+Shift+T | Seven-palette theme selector |
| Super+V | Toggle floating, preserved from original configuration |
| Super+F | Toggle fullscreen |
| Super+arrows | Focus adjacent window |
| Super+Shift+E | Session/power menu with confirmation |

Screenshots are saved privately in `~/Pictures/Screenshots` and copied as PNGs.
Clipboard history stores up to 300 items locally in `~/.cache/cliphist`.
To clear history: `cliphist wipe`; to clear the current clipboard: `wl-copy --clear`.

Fuzzel remains in use for compact pickers, including themes, clipboard and session
actions; the application grid opens with Super or Super+Space.

Click the panel volume to open Pavucontrol; right-click to mute; scroll to adjust.
Bluetooth opens Blueman. Network opens the connection editor; right-click opens
`nmtui` for network selection. The tray network applet also offers connection controls.
Click CZ/US to switch layouts. The cup icon temporarily inhibits idle locking.
Click notifications to open history; right-click to toggle Do Not Disturb.

## Appearance and wallpaper

Graphite surfaces, neutral gray accents, 12px window corners, 2px borders, 5/10px gaps,
lightweight animations, two-pass blur and subtle terminal transparency.
GTK uses adw-gtk3-dark / the dark preference; Qt 5/6 uses the palette-generated Kvantum Desktop theme.
Icons: Graphite-Dark (neutral folder variants over Colloid). Text: Inter Variable. Terminal: JetBrainsMono Nerd Font.

Tapety spravuje **Waypaper**: otevři jej přes **Super+Shift+W** nebo spouštěč aplikací. Soubory zůstávají v `~/.local/share/wallpapers`; výběr se obnoví při přihlášení. Tapeta hlavního monitoru se synchronizuje také pro Hyprlock.

Waybar používá černou a šedou, dlouhé tečkované audio vlny a indikátor aktualizací balíčků **↑**. Klik na indikátor otevře seznam, pravé tlačítko spustí kontrolu.

Podrobná mapa souborů, ovládání a zálohy: [WAYBAR-WAYPAPER.md](../../.local/state/desktop-setup/WAYBAR-WAYPAPER.md).

## Displays

Detected using live Hyprland output and DRM modes, not guessed:

| Connector | Display | Native mode selected | Position / scale |
| --- | --- | --- | --- |
| DP-2 | AOC Q27G42XE | 2560×1440, 180 Hz | 0×0 / 1 |
| HDMI-A-1 | MSI MAG 256F | 1920×1080, 180 Hz | 2560×0 / 1 |

Both initially ran at 60 Hz. Their original left/right arrangement is preserved.
Unmatched future monitors use the preferred mode automatically.

## Session, lock and services

Hyprland calls `~/.local/bin/desktop-session` on startup. It imports display and
theme variables into the D-Bus/systemd user environment, then starts the desktop
session target and its services. Do not separately enable a second copy of the
applets in another autostart system. Normal compositor shutdown stops the desktop
and graphical session targets.

Hypridle locks after 10 minutes and turns displays off after 15 minutes. It respects
idle inhibitors and does not suspend automatically. Before manual suspend it
requests locking and uses the compositor lock notification to delay sleep until
the lock has engaged. Hyprlock authenticates with Arch's installed PAM login stack.

NetworkManager and Bluetooth are enabled system services. UDisks2, GVfs and
thumbnail helpers activate on demand. PipeWire sockets and WirePlumber are enabled.
Hyprpolkitagent starts with the graphical session. Thunar mounts removable media
and generates local thumbnails; autorun and automatic file execution are disabled.
Archives use File Roller and the Thunar archive plugin.

The existing portal routing is preserved: Hyprland for screen capture/sharing,
GTK fallback for file selection and other interfaces. These portals are activated
by D-Bus; they do not need `systemctl enable`.

## Emoji

Noto Color Emoji is the temporary open-source font from official Arch repositories.
Fontconfig also maps requests for Apple Color Emoji and Segoe UI Emoji to Noto.
This does not reproduce Apple's artwork. Actual Apple Color Emoji is proprietary,
is not in the official repositories, and was not downloaded or installed.
AUR repackaging or extraction from Apple software requires a separate source and
licensing review and your explicit approval before proceeding. The AUR package
web pages were access-blocked during research, so no particular repackager was verified.

## Backup and recovery

Before editing, the original Hyprland directory and other existing settings were
copied into:

`~/.local/state/desktop-setup/20260928-230819/config/`

The package list and prior GNOME interface settings are in that same backup.
To restore the original Hyprland entry point:

```sh
cp ~/.local/state/desktop-setup/20260928-230819/config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua
hyprctl reload
```

Then log out and back in to return to its original startup behaviour. Other new
configuration files and installed packages remain available; this does not remove
them or undo GTK/Qt settings.

## Validation and restart

See `~/.local/state/desktop-setup/VALIDATION.md` for actual test results and limits.
Useful checks: `hyprctl configerrors`, `hyprctl monitors`,
`systemctl --user --failed`, `wpctl status`, and `nmcli general status`.

Log out and back in once to give every application the new environment and exercise
the startup path. Existing Kitty/Firefox windows may need restarting for fonts and
themes. No kernel or NVIDIA package was upgraded, so this desktop setup does not
require a reboot. No automatic reboot was performed.

The official-package transaction unexpectedly ran the existing mkinitcpio hook,
which regenerated `/boot/EFI/Linux/arch-linux.efi`. This touched an EFI file despite
the requested restriction. The kernel version, EFI configuration, systemd-boot
configuration, fstab and partitions were not edited. See `/var/log/pacman.log`
at 23:08–23:09 on 28 September 2026 for the hook output.

## Documentation consulted

- https://wiki.hypr.land/configuring/core/monitors/
- https://wiki.hypr.land/configuring/core/binds/
- https://wiki.hypr.land/configuring/core/config-options/
- https://wiki.hypr.land/Nvidia/
- https://wiki.hypr.land/Hypr-Ecosystem/xdg-desktop-portal-hyprland/
- https://wiki.hypr.land/hypr-ecosystem/user/hypridle/
- https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/
- https://wiki.archlinux.org/title/Hyprland
- https://wiki.archlinux.org/title/Qt
- https://wiki.archlinux.org/title/Fonts
- https://archlinux.org/packages/extra/any/noto-fonts-emoji/
- Installed version-specific examples, Lua API stubs and package man pages.

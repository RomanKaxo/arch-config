# Roman's desktop

Completed configuration work on 28 September 2026. This is a custom Hyprland
configuration using official Arch components, not a downloaded dotfiles framework.

## Aktuální vzhled: Graphite

Černá a neutrální šedá jsou společnou paletou pro Waybar, dock, Hyprland rámy a titulky, Quickshell panely, nabídky, notifikace, Kitty, GTK a Qt/Kvantum. Systém preferuje tmavý režim a šedý akcent. Tlačítka oken zůstávají barevná: červená zavře, žlutá minimalizuje a zelená maximalizuje. `Graphite-Dark` mění barvy složek; rozpoznatelné ikony aplikací přebírá z původního Colloidu.

Dock je kompaktní antracitový panel s ikonami 38 px a jemným označením aktivní aplikace. Běží ve vrstvě **top**, takže jej celoobrazovkové okno (`Super+F`) překryje. Po opuštění fullscreenu je znovu vidět. Při otevření nabídky aplikací přes samotný Super nebo ostatních Quickshell panelů dostane dock signál pro skrytí; zavření panelu jej vrátí. Není ve vrstvě overlay, která zůstává nad fullscreenem.

Původní nastavení je zálohované; cesta je v `~/.local/state/desktop-setup/latest-graphite-backup`. Motiv přepneš přes **Super+Shift+T**, aktuální volba je **Graphite**. Některé už otevřené aplikace načtou celý nový motiv až po svém restartu. Vlastní motivy webových stránek a jednotlivých aplikací se řídí jejich nastavením.

## Themes

Press **Super+Shift+T**, launch **Desktop Themes**, or choose **Themes** in the
control center (**Super+N**).

Available palettes: **Graphite** (current), **Midnight**, **Obsidian**, **Deep Ocean**,
**Nord Night**, **Forest Night**, **Purple Night**, **Warm Night**.

Edit `~/.config/desktop/palettes.json` for colors and `templates/` for layouts.
`desktop-theme "Deep Ocean"` renders a generation and atomically changes `current`.
Do not edit generated files reached through `current` or the linked application
styles; the next theme change replaces them. `desktop-theme --check-all` validates
all palettes. Existing GTK/Qt applications may need reopening to adopt every color.
Flatpak applications retain their supported dark appearance; their private themes
are not forcibly replaced with host CSS. Wallpapers are selected independently.

The custom Kvantum theme adapts the installed KvGnomeDark assets by Tsu Jan,
from https://github.com/tsujan/Kvantum, licensed GPL-3.0-or-later. Its layout is
preserved and colors are supplied by the shared palette.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| Super+Enter / B / E | Kitty / Firefox / Thunar |
| Super alone or Super+Space | Application grid launcher |
| Super+Q / L | Close window / lock |
| Super+1–9 | Workspace, physical number row on either keyboard layout |
| Super+Shift+1–9 | Move window to workspace |
| Super+mouse wheel | Previous/next existing workspace |
| Super+left/right drag | Move/resize |
| Super+F / V | Fullscreen / floating |
| Alt+Shift | Czech **QWERTZ** / US **QWERTY**; panel shows CZ/US |
| Print / Shift+Print | Region / entire desktop screenshot |
| Super+N | Control center and notification history |
| Super+Shift+V / W / T | Clipboard / wallpaper / palette selector |
| Super+Shift+E | Session/power menu, with confirmation for disruptive actions |
| Volume/mute/mic/media keys | Audio OSD and MPRIS media control |

Screenshots save to `~/Pictures/Screenshots` and copy to the clipboard. Clipboard
history stays local, up to 300 items. Clear it with `cliphist wipe`.
Locking occurs after 10 minutes; displays turn off after 15. Applications can
inhibit idle; no automatic suspend is configured. The panel's cup toggles inhibition.

## Applications and sources

Official Arch packages provide Waybar, nwg-drawer/Fuzzel, SwayNC, Hyprlock/Hypridle/Hyprpaper,
Kitty, Firefox, Thunar and its archive/media plugins, GVfs (including SMB/MTP),
Tumbler, File Roller, Grim/Slurp, wl-clipboard/Cliphist, Blueman, Pavucontrol,
NetworkManager applet/editor, Hyprpolkitagent, Hyprland/GTK portals, Discord,
Steam, Flatpak, Fastfetch, Loupe, mpv, Mousepad, Galculator and Evince.
Fonts include JetBrains Mono Nerd Font, Noto, CJK and Noto Color Emoji. Icons are
Papirus-Dark; GTK uses adw-gtk3-dark and Qt uses Kvantum.

The primary launcher is `nwg-drawer`: a dark, full-screen application grid with
large Papirus icons, category filters, search and pinned apps. Super alone opens
it when released, and Super+Space is an alternate shortcut. Its GTK stylesheet is
generated from the active desktop palette. Fuzzel remains for compact pickers
such as clipboard, wallpaper, themes, and session actions.

**Sober 1.7.1** is the only installed application from Flathub. It is installed
per-user as `org.vinegarhq.Sober`, using the method recommended by its maintainers:
https://vinegarhq.org/Sober/Installation.html . Its matching NVIDIA extension is
`org.freedesktop.Platform.GL.nvidia-615-71-09`. Keep Flatpaks current with
`flatpak --user update`, especially after NVIDIA updates. Do not pin an old NVIDIA
extension. The launcher entry, icon and Roblox URL handlers are exported normally.

Sober is an unofficial proprietary compatibility application, not an official
Roblox Linux client. Its first-run terms and Automatic Roblox installation await
your interaction. No external APK, patched client or Wine workaround was installed.
Native Wayland launch, NVIDIA libraries, and Vulkan rendering inside the Sober
sandbox are verified; Roblox gameplay/audio
remain to be tested after sign-in. Some experiences may restrict unsupported
clients; see https://vinegarhq.org/Sober/Troubleshooting.html .

Steam's official multilib package, matching `lib32-nvidia-utils`, Vulkan loader,
and PulseAudio compatibility libraries are installed. Steam downloaded its official
Valve client and reaches sign-in under XWayland. Its compatibility log maps AppID 0
to `proton_experimental` with priority 75: normal Proton support is already active
by default. No custom Proton, driver, kernel, or optimization script was installed.
Steam will download game-specific Proton/runtime files as needed after login.
Actual Windows-game execution has not been tested without an account/game.

Discord's official Arch package downloaded its client through Discord's own
updater and opens natively on Wayland. Voice/call sharing requires account testing.
The underlying browser/portal capture path has passed an end-to-end Firefox test.

**Spotify is pending source approval.** It has no official Arch package. The
community Flathub package is not Spotify-supported; the web player is an alternative.
No Spotify application or unapproved AUR package was installed.

Noto Color Emoji remains the safe open-source fallback. It is not Apple's artwork.
Apple Color Emoji is proprietary and not in official Arch repositories. AUR
repackaging, third-party distribution, or extraction from Apple software needs
your explicit approval and a source/licensing review. No Apple font was downloaded.

## Design references only

ML4W informed the workspace/clock/status bar arrangement; HyDE the restrained
window styling; klpod0s the icon/search launcher; Noctalia the control center;
agusdoricich.dev the minimal terminal. None of their installers or complete
configurations was installed.

- https://ml4w.com/os/getting-started/overview
- https://dev.to/da4ndo/hyde-2025-update-the-most-aesthetic-dynamic-and-minimal-hyprland-experience-57lm
- https://github.com/klpod221/klpod0s
- https://noctalia.dev/
- https://www.agusdoricich.dev/

## Backups, validation and remaining checks

Original backup: `~/.local/state/desktop-setup/20260928-230819/`.
Backup before the master README changes:
`~/.local/state/desktop-setup/master-20260928-234325/`.
Multilib backup: `/etc/pacman.conf.before-gaming-20260928`.
All are retained. Restore individual files from these copies only after saving
any newer work. When restoring a generated application config, remove its symlink
before copying the backup so you do not overwrite a palette generation by accident.

See `~/.local/state/desktop-setup/MASTER-VALIDATION.md` for current results and
`VALIDATION.md` there for the initial desktop tests. The main Hyprland guide is
`~/.config/hypr/DESKTOP.md`.

Your monitors use their detected native modes: DP-2 2560×1440 at 180 Hz, HDMI-A-1
1920×1080 at 180 Hz, both scale 1. NVIDIA and the kernel were not upgraded.
User desktop services are healthy. Three pre-existing system TPM/NvPCR units
remain failed; boot/TPM integration was left unchanged.

Log out/in once to test full session startup and refresh the environment in all
existing applications. New apps already receive Flatpak launcher paths and themes.
No reboot is required by the installed packages. No reboot or shutdown was run.
Pair your own Bluetooth device in Blueman for a real headset/reconnection test;
physical USB insertion/ejection, suspend/resume, Discord calls, and game playback
still need real-world testing.

The initial desktop package transaction unexpectedly ran Arch's existing mkinitcpio
hook and regenerated `/boot/EFI/Linux/arch-linux.efi` at 23:09, contrary to the EFI
restriction. This was disclosed and recorded in `VALIDATION.md`. The later gaming
transaction guarded boot-sensitive package contents and suppressed only that
unnecessary rebuild hook for the single transaction. No boot configuration, fstab,
partition, or kernel version was changed.

## Aktualizace 29. 9. 2026: panel a tapety

Waybar má samostatný černý/šedý vzhled, dlouhé symetrické tečkované vlny a upozornění na aktualizace balíčků Arch/Flatpak. Tapety spravuje Waypaper přes **Super+Shift+W**; původní vlastní galerie byla odstraněna. Ovládání, soubory a ověření popisuje `~/.local/state/desktop-setup/WAYBAR-WAYPAPER.md`.

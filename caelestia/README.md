# Aktuální desktop: Caelestia

Od 12. 10. 2026 používá tento počítač Caelestia Shell 2.5.0 místo původního vlastního Quickshellu a Waybaru.
Konfigurace v `config/` je relativní k HOME. Zdroj shellu: https://github.com/caelestia-dots/shell,
stabilní tag `v2.5.0`, commit `d999d4878ee4cec134168e60d913714566a8cfa6`.

Původní desktop je archivovaný v Git historii a v `backups/pre-caelestia-2026-10-12`.
Přesná původní konfigurace byla pushnutá a ověřená na `main` v commitu
`cab804907e7f15c2ecc308ad208b640906340a08` před odstraněním aktivních souborů.
Kořenový `payload`, manifest a obnovovací nástroje popisují archivovaný desktop;
nespouštěj jejich `install`/`activate`, pokud chceš ponechat Caelestia.

## Ovládání

| Zkratka | Akce |
| --- | --- |
| Super / Super + Space | Launcher |
| Super + Enter | Kitty |
| Super + E / Super + B | Thunar / Firefox |
| Super + N | Boční panel |
| Super + D | Dashboard |
| Super + L | Zámek |
| Super + Shift + E | Nabídka napájení |
| Super + Shift + V | Historie schránky |
| Super + M / Super + Shift + M | Minimalizace / obnovení okna |
| Alt + Tab / Alt + Shift + Tab | Nativní přepínání oken |
| Print / Shift + Print | Výřez / screenshot |

Tapety: `~/Pictures/Wallpapers`. V launcheru napiš `>wallpaper`.
Monitory DP-2 (2560×1440) a HDMI-A-1 (1920×1080) zůstávají na 180 Hz.
Klávesnice: CZ/US, přepnutí Alt + Shift.
Automatické zamknutí po 10 minutách a vypnutí monitorů po 15 minutách; bez automatického uspávání.
Neaktivní okna mají 10% průhlednost. Kitty má trvale 15% průhlednost;
pravidlo s `override` zabraňuje dalšímu zesílení efektu při ztrátě fokusu.
Aktivní ostatní okna jsou neprůhledná. Rozmazání pozadí zůstává na původním nastavení.

## Instalované umístění

- Shell: `~/.config/quickshell/caelestia` (oficiální zdroje, bez místních úprav).
- Nastavení: `~/.config/caelestia/shell.json`.
- C++ a QML moduly: `~/.local/lib`, `~/.local/lib/qt6/qml`.
- CLI: `~/.local/share/caelestia/venv`, wrapper `~/.local/bin/caelestia`.
- Start relace: `~/.local/bin/caelestia-session`, `caelestia-session.target` a `caelestia-shell.service`.
- Schránka: `caelestia-clipboard-text.service` a `caelestia-clipboard-image.service`.
- Traffic light tlačítka: oficiální plugin hyprbars v `~/.local/lib/caelestia/hyprbars.so`,
  nastavení `~/.config/hypr/caelestia-titlebars.lua` a samostatné skripty
  `caelestia-titlebars` / `caelestia-window`. Červené zavírá, žluté minimalizuje jednotlivé
  okno a zelené přepíná maximalizaci. Obnovení minimalizovaných oken: Super + Shift + M.

Systémové závislosti jsou nainstalované přes pacman. Rubik je v `~/.local/share/fonts`.
Knihovny libcava a M3Shapes jsou sestavené z oficiálních zdrojů v `~/.local/src`.
Quickshell 0.3.2 byl ověřen živým načtením Caelestia 2.5.0.

## Obnova a aktualizace

Po instalaci závislostí a shellu zkopíruj obsah `config/` do HOME,
nastav spustitelnost `.local/bin/caelestia*` a proveď:

```bash
systemctl --user daemon-reload
systemctl --user enable caelestia-shell.service caelestia-clipboard-text.service caelestia-clipboard-image.service
hyprctl reload
~/.local/bin/caelestia-session
```

Pro opakované sestavení současného shellu:

```bash
PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig" cmake -S "$HOME/.local/src/caelestia-shell" -B "$HOME/.local/src/caelestia-shell/build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local" -DINSTALL_QSCONFDIR="$HOME/.config/quickshell/caelestia" -DVERSION=2.5.0 -DDISTRIBUTOR=Roman-local
CPATH="$HOME/.local/include" cmake --build "$HOME/.local/src/caelestia-shell/build" -j 4
cmake --install "$HOME/.local/src/caelestia-shell/build"
systemctl --user restart caelestia-shell.service
```

`caelestia update` se zde nepoužívá: instalace celých Caelestia dotfiles nebyla provedena.
Při aktualizaci vol stabilní tag shellu a jeho odpovídající závislosti.

## Ověření

Sestavení shellu, libcava a M3Shapes prošlo. `hyprctl configerrors` je prázdný.
Caelestia je aktivní a povolená; clipboard služby jsou aktivní a povolené.
Launcher a dashboard odpovídají přes IPC; vlastníkem `org.freedesktop.Notifications`
je proces Caelestia. Staré panely a služby neběží, konfigurace a lokální zálohy jsou odstraněné,
Původní plugin hyprbars byl při migraci odpojený; na následný požadavek jsou traffic light
tlačítka připojená samostatně s nastavením Caelestia. Akce zavření, maximalizace a jejího
zrušení, minimalizace a obnovení byly ověřené na dočasném okně Kitty.
Loader kontroluje checksum a ABI; po aktualizaci Hyprlandu je nutné plugin znovu sestavit
ze zdrojů v `vendor/hyprbars`, jinak jej bezpečně přeskočí.
Přihlášení po rebootu nebylo testované.

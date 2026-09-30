# Arch config — Roman

Kompletní konfigurace současného Arch Linux desktopu: Hyprland, Quickshell,
Waybar, dock, témata, tapety, audio, schránka, zamykání, vlastní skripty,
systemd služby, SDDM a seznam aplikací. Soukromý repozitář pro obnovu a správu změn.

**Začíná se na funkčním Archu s vytvořeným uživatelem, přístupem k internetu,
`sudo`, Git a Pythonem.** Instalace disků a bootloaderu je mimo rozsah.
Nejde o image disku ani zálohu osobních dat. Arch je rolling release; seznam
pozorovaných verzí zachycuje původní stav, nevynucuje nebezpečný downgrade.

## Obnova

```bash
git clone https://github.com/RomanKaxo/arch-config.git
cd arch-config
./arch-config check --profile current-pc
./arch-config install --component system --profile current-pc --dry-run
sudo ./arch-config install --component system --profile current-pc --home "$HOME"
./arch-config packages --profile current-pc
./arch-config install --profile current-pc
./arch-config extras --profile current-pc
./arch-config activate --component system --profile current-pc
./arch-config activate --profile current-pc
```

Před příkazem `packages` musí být funkční pacman mirrorlist a klíčenka.
Příkaz zachovává úplnou aktualizaci systému pomocí `pacman -Syu --needed`.
Po dokončení doplň locale podle [obnovovacího návodu](docs/RESTORE.md),
obnov aplikace distribuované mimo pacman/Flatpak podle
[aplikačního návodu](docs/APPLICATIONS.md) a znovu se přihlas.
Při změně ovladačů nebo kernelu restartuj počítač sám.

**Na jiném počítači použij všude `--profile generic`.** Tento profil neinstaluje
NVIDIA, kernel ani mikrokód a nevynucuje konkrétní monitory. Ovladač, kernel
a mikrokód musí být správně nainstalované v základním Archu.
Klávesnice zůstává česká/US, motiv a zkratky stejné.

`install` bez přepínačů kopíruje pouze uživatelské nastavení; neinstaluje balíčky,
nestartuje služby a nepoužívá sudo. Profil je výchozí `generic`, proto na původním
stroji výslovně uváděj `--profile current-pc`.

## Běžné změny

Upravuj konfiguraci jako dosud v `~/.config` nebo vlastní skripty v `~/.local/bin`.
Pak vybrané změny přenes do Gitu:

```bash
cd ~/Projects/arch-config
./arch-config sync --profile current-pc --dry-run
./arch-config sync --profile current-pc
./arch-config check --profile current-pc
git diff --stat
git diff -- payload/user/all/.config/hypr/hyprland.lua
git add -p
# Nové soubory přidej výslovně po kontrole jejich obsahu.
git commit -m "Update desktop configuration"
git push
```

`sync` čte pouze existující položky `manifest.json`; nic automaticky necommituje,
nepushuje a nemaže chybějící konfigurace. Nové soubory vyžadují výslovné rozšíření
manifestu. Změny balíčků aktualizuj zvlášť podle [správy repozitáře](docs/MAINTENANCE.md).

## Zálohy a ověření

Každá instalace mění pouze odlišné soubory a před přepsáním vytvoří zálohu.
`restore` vrací přesně jednu instalaci; ochrání soubory změněné později.
Příklady jsou v [RESTORE.md](docs/RESTORE.md).

```bash
python -m unittest discover -s tests -v
./arch-config check --profile generic
./arch-config check --profile current-pc
./arch-config check --profile current-pc --live
```

Rozsah a výjimky: [INVENTORY.md](docs/INVENTORY.md).
Výsledky skutečných testů: [VALIDATION.md](docs/VALIDATION.md).
Ovládání: [DESKTOP.md](docs/DESKTOP.md).

## Struktura

| Umístění | Obsah |
| --- | --- |
| `payload/user/all` | Společné nastavení a grafické prostředky |
| `payload/user/{generic,current-pc}` | Konfigurace monitorů |
| `payload/system` | Vybrané systémové soubory a SDDM |
| `payload/workspace` | Volitelné služby Elaris/OmniRoute |
| `profiles` | Parametry hardwarových profilů |
| `packages` | Arch/Flatpak seznamy, verze a původ zdrojů |
| `vendor` | Zdroj hyprbars, místní Waypaper úprava, licence |
| `tools`, `tests` | Obnovovací nástroje a jejich testy |

Původní symlinky jsou uložené jako metadata manifestu a vytvářejí se až při
instalaci; soubory zůstávají na běžných místech, nepřesměrovávají se do repozitáře.
Textové cesty se při instalaci vykreslí pro cílové HOME. Podporované cesty HOME
obsahují písmena, číslice, `/`, `_`, `.` a `-`; ostatní znaky nástroj odmítne před zápisem.

Vlastní kód a konfigurace jsou osobní projekt. Převzaté prostředky a zdroje
zachovávají upstream licence; viz [SOURCES.md](docs/SOURCES.md).

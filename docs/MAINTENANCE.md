# Správa repozitáře

## Konfigurace

Používej `sync --profile current-pc` na původním stroji; na přenosném profilu
`sync --profile generic`. Kontroluj `git diff` před každým commitem.
Symlinky se synchronizují do manifestu. Aktivní paleta se zachytí přes
`~/.config/desktop/current` do stabilního `palette-current`, bez historie dočasných palet.
Lokální stará konfigurace Hyprlandu se při sync rozdělí na společnou část a monitorový
profil. Po nasazení už se monitorový profil upravuje v `~/.config/hypr/hardware.lua`.

Nový soubor: přidej payload a položku v `manifest.json` s cílovou cestou, komponentou,
profilem, oprávněním a případně relativní cestou `capture`. Textové cesty používají
`@HOME@`; rozlišuj textové soubory od binárních. Synchronizace nové soubory nehledá
sama a odstraněné soubory nemaže z repozitáře.

Změny oprávnění nebo přechod soubor ↔ symlink vyžadují výslovnou revizi manifestu.
Systémový sync: `./arch-config sync --component system --profile current-pc` čte
jen schválené systémové cesty. `--system-root` umožňuje místo `/` číst staging.
Konfigurace se závislostí na zařízení patří do hostitelského profilu.

## Balíčky

`packages/observed-arch-versions.txt` je evidence původního systému. Instalátor
používá názvy v `arch.txt` a `build.txt`, navíc `current-pc.txt` pro původní hardware.
Po přidání aplikace doplň odpovídající seznam; nerozšiřuj hardware do společného seznamu.
Aktuální balíčky můžeš porovnat pomocí `pacman -Qqen` a `pacman -Qqm`.
Seznam `foreign.txt` byl při zachycení prázdný; AUR helper se nezavádí.
Flatpak aplikace eviduje `flatpak.tsv`, původní scope i případné rozdíly popisuje INVENTORY.md.

## Plugin a externí zdroje

Při aktualizaci Hyprlandu znovu spusť `python tools/build_hyprbars.py`.
Zdroj musí odpovídat novému API; úspěšný build vytvoří metadata podle hlaviček,
ne podle dříve spuštěného compositoru. Loader nepřijme neodpovídající ABI/checksum.
Skript zachovává předchozí binárku a nepřenačítá živou relaci.

Při aktualizaci Waypaper zkontroluj zachované úpravy ve `vendor/waypaper/app.py`.
`packages/waypaper.txt` obsahuje jen požadované závislosti venv, ne celý freeze
systémového Pythonu nebo cesty z build serverů.

## Kontroly před publikováním

Prezentace `README.md` a `read.md` mají shodný obsah; při úpravě udržuj oba soubory
sladěné. Banner je vlastní SVG v `docs/assets/arch-desktop.svg`.

```bash
python -m unittest discover -s tests -v
./arch-config check --profile current-pc
./arch-config check --profile generic
python tools/audit.py
```

Audit zkontroluje manifest, známé přihlašovací soubory a běžné formáty klíčů/tokenů.
Nenahrazuje kontrolu rozdílů; Git neobsahuje aplikační databáze, účty nebo zálohy.
Privátní repo není místo pro hesla. `.gitignore` je druhá ochrana, základem je explicitní manifest.

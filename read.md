<p align="center">
  <img src="docs/assets/arch-desktop.svg" alt="Arch. Po svém. — černý a grafitový desktop s levým taskbarem" width="1200">
</p>

<h1 align="center">Můj Arch. Můj pracovní prostor.</h1>

<p align="center">
  Černá tapeta, průhledné panely a okna, která mají svoje místo.<br>
  <strong>Arch Linux · Hyprland · Quickshell · Waybar</strong>
</p>

<p align="center">
  <a href="#plocha-po-mém">Plocha</a> ·
  <a href="#každý-den">Ovládání</a> ·
  <a href="#obnova">Obnova</a> ·
  <a href="docs/MAINTENANCE.md">Správa</a> ·
  <a href="docs/VALIDATION.md">Ověření</a>
</p>

---

Osobní konfigurace desktopu, kterou používám každý den. Vlastní launcher,
dashboard a ovládací centrum, společná grafitová paleta a soubory pro obnovu
na současném i jiném počítači. Vzhled i ovládání žijí v jednom repozitáři.

## Plocha po mém

| | Jak se chová |
| --- | --- |
| **Panely do L** | Horní Waybar navazuje na levý taskbar. Stejný styl, jemný rámeček a vyhrazené místo pro okna. |
| **Černá a grafit** | Tapeta Black Waves, neutrální šedá, průhlednost panelů 0,62 a blur o velikosti 10. |
| **Všechno po ruce** | Vlevo launcher, plochy a otevřená okna. Dole bdělý režim, oznámení, zámek a napájení. |
| **Klid při videu** | Fullscreen video i hra překryjí oba panely. Ruční skrytí taskbaru má vlastní zkratku. |
| **Místo pro práci** | Vnitřní odsazení oken 4 px, vnější 8 px, zaoblené titulky a náhledy Alt-Tab. |
| **Jeden vzhled** | Sladěné GTK, Qt, Kitty, Fuzzel, Waybar a Hyprlock. Sedm volitelných palet. |

Horní panel drží čas, audiovlny, RAM/GPU, aktualizace, síť, zvuk a jas monitorů.
Launcher, dashboard a ovládací centrum používají Quickshell.
Banner nahoře je schematický náhled; osobní obsah oken se do repozitáře neukládá.

## Každý den

| Zkratka | Akce |
| --- | --- |
| `Super` / `Super + Space` | Otevřít launcher |
| `Super + Enter` | Terminál Kitty |
| `Super + N` / `Super + D` | Ovládací centrum / dashboard |
| `Super + Ctrl + D` | Zobrazit nebo skrýt levý taskbar |
| `Alt + Tab` | Náhledy a přepínání oken |
| `Super + 1–9` | Přepnout pracovní plochu |
| `Super + M` / `Super + Shift + M` | Minimalizovat / obnovit okno |
| `Super + Shift + W` / `Super + Shift + T` | Tapeta / paleta |
| `Super + L` | Zamknout desktop |
| `Print` / `Shift + Print` | Výřez / screenshot celé plochy |

[Všechny zkratky, chování oken a ovládání monitorů →](docs/DESKTOP.md)

## Dva profily

| Profil | Pro koho |
| --- | --- |
| **`current-pc`** | Moje sestava: RTX 4060 Ti, AOC 1440p a MSI 1080p při 180 Hz. Taskbar na DP-2. |
| **`generic`** | Jiný počítač: automatická konfigurace monitorů, taskbar na každém výstupu, společné ovládání a vzhled. |

Profil `generic` neinstaluje kernel, mikrokód ani ovladač NVIDIA. Ty patří do
základního Archu podle konkrétního hardwaru. Klávesnice zůstává česká/US.

## Obnova

Začni na funkčním Arch Linuxu s uživatelem, internetem, `sudo`, Gitem a Pythonem.
Repozitář obnovuje prostředí a aplikace; rozdělení disku, bootloader a osobní data
řešíš samostatně. Arch je rolling release — zaznamenané verze slouží jako evidence.

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

**Na jiném počítači nahraď všude `current-pc` za `generic`.** Před instalací
balíčků musí fungovat pacman mirrorlist a klíčenka. `packages` zachovává úplnou
aktualizaci přes `pacman -Syu --needed`.

Po dokončení doplň locale, obnov aplikace distribuované mimo pacman/Flatpak
a znovu se přihlas. Při změně kernelu nebo ovladačů restartuj počítač.
`install` bez přepínačů kopíruje pouze uživatelské nastavení a používá profil
`generic`; neinstaluje balíčky ani nespouští služby.

[Podrobná obnova a návrat ze zálohy →](docs/RESTORE.md)

## Změna, kterou si chci nechat

Konfiguraci upravuju na obvyklých místech v `~/.config` a `~/.local/bin`.
Do repozitáře se přenáší výslovně vybrané soubory z manifestu:

```bash
cd ~/Projects/arch-config
./arch-config sync --profile current-pc --dry-run
./arch-config sync --profile current-pc
./arch-config check --profile current-pc
git diff --stat
git diff
git add -p
# Nové soubory přidej výslovně po kontrole.
git commit -m "feat(desktop): update desktop configuration"
git push
```

`sync` automaticky necommituje, nepushuje ani nemaže chybějící konfigurace.
Nové soubory potřebují položku v `manifest.json`; balíčky se evidují zvlášť.
Každá instalace zálohuje měněné soubory. `restore` umí vrátit jednu konkrétní
instalaci a ochrání pozdější úpravy.

## Co drží celek pohromadě

| Umístění | Obsah |
| --- | --- |
| `payload/user/all` | Společné nastavení, skripty, motivy a tapety |
| `payload/user/{generic,current-pc}` | Monitory, umístění taskbaru a navázané nastavení |
| `payload/system` | Systémové soubory a přihlašovací obrazovka SDDM |
| `payload/workspace` | Volitelné služby Elaris/OmniRoute |
| `profiles`, `packages` | Hardwarové profily, balíčky a evidence zdrojů |
| `tools`, `tests`, `vendor` | Obnova, testy a převzaté zdroje s licencemi |

Soubory se při instalaci kopírují na běžná místa. Symlinky se obnovují z manifestu;
textové cesty se vykreslí pro cílové HOME. Podporovaná cesta HOME používá písmena,
číslice, `/`, `_`, `.` a `-`.

<details>
<summary><strong>Kontroly před publikováním</strong></summary>

```bash
python -m unittest discover -s tests -v
./arch-config check --profile generic
./arch-config check --profile current-pc
python tools/audit.py
```

Živou relaci lze navíc ověřit přes `./arch-config check --profile current-pc --live`.
Výsledky a rozsah ověření jsou v [VALIDATION.md](docs/VALIDATION.md).

</details>

## Dokumentace

| Chci… | Otevřít |
| --- | --- |
| Znát všechny zkratky a chování panelů | [Ovládání desktopu](docs/DESKTOP.md) |
| Obnovit prostředí nebo vrátit instalaci | [Obnova](docs/RESTORE.md) |
| Nastavit aplikace a přihlášení | [Aplikace](docs/APPLICATIONS.md) |
| Zjistit, co se ukládá | [Inventář](docs/INVENTORY.md) |
| Spravovat konfiguraci a balíčky | [Správa repozitáře](docs/MAINTENANCE.md) |
| Projít výsledky kontrol | [Ověření](docs/VALIDATION.md) |
| Dohledat původ prostředků a licence | [Zdroje](docs/SOURCES.md) |

---

<p align="center"><sub>Roman · Arch po svém · Vlastní prostředí, ke kterému se dá vrátit.</sub></p>

# Zachycený rozsah

Snapshot byl pořízen 29.–30. září 2026 ze současného systému uživatele roman.
Základem je aktivní konfigurace, nikoli starší instalační skript nebo historické zálohy.
Manifest obsahuje přes 42 tisíc položek, převážně ikon a jejich symlinků.

## Zahrnuto

- Hyprland Lua, pravidla oken, klávesové zkratky, idle, lock, tapety a titlebars.
- Quickshell panely, dock, Waybar včetně audiovln a aktualizací, Cava, SwayNC,
  Fuzzel, Nwg Drawer, Kitty, GTK, Kvantum, Qt, Fontconfig a Fastfetch.
- Paletové šablony, definice všech palet a aktuálně aktivní vygenerovaná paleta.
  Historie starších náhodně pojmenovaných palet se nepřenáší.
- Vlastní `desktop-*`, Waypaper integrace, uživatelské služby, timer a aktivní
  enable symlinky. Bash, MIME asociace, uživatelské adresáře, Thunar, XFCE,
  Galculator a drobné nastavení Pavucontrol.
- Lokální tapety, Inter Variable, font DesktopWaves včetně generátoru, ikony
  Graphite a instalované Colloid varianty, desktopové launchery včetně War Thunder.
- pacman konfigurace včetně multilib, LANG, česká konzole, zram, SDDM a jeho motiv.
  NVIDIA blacklist/modules jsou pouze v profilu `current-pc`.
- Explicitně instalované Arch balíčky a pozorované verze, Flatpak Spotify/Sober,
  zdroje hyprbars a místní úprava Waypaper, evidence lokálních vývojářských aplikací.
- Volitelné jednotky Elaris a OmniRoute jako komponenta `workspace`, bez projektových dat.

## Záměrně odděleno

Osobní soubory, projekty, hry a savy; browser profily; Discord/Spotify/Steam účty;
FileZilla připojení; Wi-Fi hesla a Bluetooth párování; SSH/GPG/AWS/GitHub tokeny;
Codex/ChatGPT konverzace a účty; cache, historie, logy a instalační screenshoty.
Nekopíruje se `.config` nebo `.local` jako celek.

Lokální VS Code, ChatGPT, Codex a OmniRoute binárky nejsou config soubory a do
Gitu se nepřidávají. Jejich návrat popisuje APPLICATIONS.md. Projekt Elaris-Harness
musí mít vlastní zálohu/repozitář. Nastavení aplikací se zahrnuje jen tam, kde je
oddělené od účtů a historie. VS Code v době capture neměl samostatný settings.json
nebo keybindings.json; databáze workspace/globalStorage se neexportovaly.

Nevhodné pro přenos jsou fstab, partition UUID, EFI položky, TPM stav, bootloader,
hostname, machine-id, mirrorlist, klíčenky a aplikační databáze. `/boot` nebyl
čitelný a není zahrnut. Výchozí síťová konfigurace se obnoví přes NetworkManager;
připojení a párování se znovu nastavují po instalaci.

Některé původní upstream icon symlinky byly nefunkční; nefunkční zdrojové položky
se nezahrnuly. Ostatní relativní icon symlinky zůstávají zachované.

## Přenositelnost

`current-pc`: Intel mikrokód, nvidia-open / NVIDIA utils včetně 32bit části,
DP-2 AOC 2560×1440 @180 Hz vlevo a HDMI-A-1 MSI 1920×1080 @180 Hz vpravo.

`generic`: sdílené prostředí, preferované automatické monitory, bez vynuceného
GPU ovladače nebo původního kernelu/mikrokódu. Dock není svázán s názvem monitoru,
Quickshell používá první/fokusovaný monitor. Počasí/časové pásmo zůstávají původní
uživatelskou preferencí a lze je změnit.

Flatpak obnova sjednocuje aplikace na uživatelský scope. Instalátor nezachycuje
stažené runtimy ani přihlášení; Flatpak potřebné runtime stáhne sám.

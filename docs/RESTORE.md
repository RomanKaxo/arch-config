# Obnova na nainstalovaném Arch Linuxu

## Předpoklady

Funkční základní Arch, připojení k internetu, uživatel s HOME a sudo, Git a Python.
Správný kernel, bootloader, firmware a GPU ovladač jsou předpokladem obecného
profilu. Neprovádí se dělení disků, kopírování fstab, změna UUID nebo bootloaderu.
GitHub přístup pro privátní repo musíš přihlásit samostatně; token není v repozitáři.

1. Naklonuj repo a zvol `current-pc` pro RTX 4060 Ti a současné dva monitory,
   nebo `generic` pro ostatní stroje. Všechny další příkazy používají stejný profil.
2. Prohlédni `./arch-config install --component system --profile PROFILE --dry-run`.
   Systémový krok obnoví vybrané soubory v `/etc` a motiv SDDM. Proveď jej přes
   `sudo ./arch-config install --component system --profile PROFILE --home "$HOME"`.
   Nemění mirrorlist, síťová hesla, hostname nebo účty.
3. Spusť `./arch-config packages --profile PROFILE`. Arch balíčky se instalují
   s úplnou aktualizací systému. Flathub i aplikace se instalují v uživatelském scope.
   Aktuální snapshot obsahuje Spotify a Sober; přihlašuješ se následně sám.
4. Spusť `./arch-config install --profile PROFILE` a `./arch-config extras --profile PROFILE`.
   Druhý krok obnoví samostatné prostředí Waypaper včetně místní úpravy a sestaví
   hyprbars proti nainstalovaným hlavičkám. Žádný stažený binární plugin se nekopíruje.
5. V `/etc/locale.gen` povol `en_US.UTF-8 UTF-8` a `cs_CZ.UTF-8 UTF-8`, ponech ostatní
   používané jazyky a spusť `sudo locale-gen`. Původní LANG je `en_US.UTF-8`, konzole česká.
6. `./arch-config activate --component system --profile PROFILE` povolí NetworkManager,
   Bluetooth, SDDM, synchronizaci času a fstrim pro další boot a nastaví Europe/Prague.
   U `current-pc` znovu vytvoří initramfs přes mkinitcpio. Uživatel musí mít funkční
   stávající bootovací konfiguraci; nástroj ji nepřepisuje. Služby nejsou restartované.
7. Obnov ostatní aplikace podle APPLICATIONS.md. Spusť `./arch-config activate --profile PROFILE`,
   dokonči práci a odhlas/přihlas se. Pokud byl změněn kernel/GPU ovladač, restartuj sám.
8. Ověř `hyprctl configerrors`, `systemctl --user --failed`, `wpctl status`,
   aplikace, monitory a klávesové zkratky. NVIDIA profil navíc `nvidia-smi`.

`PROFILE` je zástupný text: nahraď jej `generic` nebo `current-pc`.
Balíčky v Arch rolling repozitářích se mohou od snapshotu změnit. Nesnaž se kombinovat
staré knihovny s novým Hyprlandem. Pokud vendored plugin přestane kompilovat, aktualizuj
jeho zdroj pro nový Hyprland; desktop má podmíněnou konfiguraci a funguje i bez pluginu.

## Zkušební obnova

Následující příkazy nepřepisují běžný HOME ani systémové soubory:

```bash
./arch-config install --profile generic --home /tmp/arch-preview/user --dry-run
./arch-config install --profile generic --home /tmp/arch-preview/user
./arch-config install --component system --profile generic --system-root /tmp/arch-preview/root --home /tmp/arch-preview/user
```

Nepouštěj v tomto režimu `packages` ani `activate`; tyto příkazy obsluhují skutečný
systém. `extras --home ...` vytvoří prostředí a plugin v uvedeném HOME, ale používá
skutečně nainstalované kompilátory a hlavičky.

## Návrat ze zálohy

Instalátor vypíše cestu nové zálohy. Uživatelské zálohy jsou pod
`~/.local/state/arch-config/backups`, systémové pod `/var/lib/arch-config/backups`.
Adresář obsahuje původní soubory a journal s kontrolními součty.

```bash
./arch-config restore --backup /ABSOLUTNI/CESTA/K/ZALOZE --dry-run
./arch-config restore --backup /ABSOLUTNI/CESTA/K/ZALOZE
sudo ./arch-config restore --component system --home "$HOME" --backup /var/lib/arch-config/backups/ID
```

Více instalací vracej v opačném pořadí. Obnova ověří celou zálohu před prvním zápisem.
Pokud je některý soubor od instalace změněný, zastaví se bez přepsání: uchovej novou
změnu a vyřeš konflikt ručně. Opakovaný restore už vrácené položky přeskočí.
Vrací se obsah, symlinky a oprávnění souborů; prázdné adresáře a journal zůstávají.
Balíčky, venv, sestavený plugin, časové pásmo a stav povolených systémových služeb
nejsou součástí souborového rollbacku. Před extras se předchozí plugin uloží jako
`.previous`; původní Waypaper app.py jako `.py.upstream`.

# Skutečně provedené ověření

Ověřeno 30. září 2026 na současném Arch Linuxu s Hyprlandem 0.56.2.
Všechny zápisové zkoušky konfigurací proběhly v `/tmp/arch-config-validation`;
aktivní konfigurace uživatele roman nebyla nasazovaná ani restartovaná.

## Prošlo

- 11 behaviorálních testů: render pro jiného uživatele, oprávnění, idempotence,
  návrat starého obsahu a symlinků, čistý dry-run, ochrana pozdějších změn,
  odmítnutí přesměrování přes symlink rodiče a cest s `..`, synchronizace pouze
  povolených souborů, aktualizace link metadat, systémový staging, integrita
  zálohy a zotavení po přerušené instalaci.
- Kompletní uživatelský payload nasazený do dvou odlišných testovacích HOME:
  `current-pc` a `generic`, každý s 42 741 konfiguracemi/ikonami/symlinky.
  Opakovaná instalace hlásila 0 změn.
- Úplný rollback obecného profilu přes všechny jeho zálohy v opačném pořadí:
  nezůstal žádný spravovaný soubor. Následná obnova a opakovaná instalace ověřené.
- Systémový profil `current-pc` nasazený do odděleného kořene: 11 souborů
  včetně SDDM a NVIDIA konfigurace, bez zásahu do běžného `/etc`.
- Oba vykreslené Hyprland profily prošly `hyprland --verify-config` s `config ok`;
  všechny nasazené Hyprland Lua soubory také `luac -p`.
- Kontrola systemd user jednotek pomocí `systemd-analyze --user verify` prošla.
  Nalezený původní cyklus mezi desktop-session.target, Hyprpaper a obnovou
  Waypaper se opravuje pomocí `DefaultDependencies=no` na vlastním session targetu.
- Synchronizace obecného profilu po nasazení má 0 změn. Synchronizace původní
  konfigurace normalizuje pevné cesty a odděluje monitorový profil.
- Všechny zachované symlinky mají existující cíle po nasazení payloadu.
- Waypaper venv vytvořený od nuly, PyPI závislosti instalované, lokální app.py úprava
  aplikovaná a launcher `waypaper --help` úspěšný. Test nevyžadoval živý compositor;
  očekávané hlášení o nedostupné monitorové IPC skončilo fallbackem `All`.
- Hyprbars skutečně sestavený přes CMake proti nainstalovaným hlavičkám a Lua 5.5.
  Vytvořená ABI metadata souhlasí s původním kompatibilním pluginem; SHA-256 souhlasí
  s novým výsledkem. Plugin nebyl načítaný do živé relace.
- Arch názvy v build seznamu existují v lokálních synchronizačních databázích pacmanu.
- Importní recepty VS Code, ChatGPT a Codex prošly zkušebním během proti skutečným
  lokálním distribučním souborům. Jejich velké binárky se do Gitu nekopírovaly.
- Audit payloadu a manifestu nenašel běžné tokeny, privátní klíče ani známé
  přihlašovací soubory. Shell/Python/JSON kontroly obou profilů prošly.

## Omezení ověření

Neproběhla instalace na čistý fyzický Arch ani VM, aktualizace balíčků současného
stroje, přepsání jeho systémových souborů, restart, nové přihlášení nebo spuštění
celé druhé grafické relace. Zkušební HOME používá knihovny hostitelského Archu.

Skutečná funkce audio zařízení, Bluetooth párování, sdílení obrazovky a hry vyžadují
ověření po přihlášení na cílovém stroji. Externí aplikace vyžadují originální
distribuci podle APPLICATIONS.md; soukromé účty a projekty nejsou součástí config repa.

C++ kompilátor vypsal upstream varování o narrowing a deprecated API; build skončil
úspěšně. Budoucí rolling aktualizace mohou vyžadovat úpravu pluginového zdroje.

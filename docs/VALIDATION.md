# Skutečně provedené ověření

## Levý taskbar a grafitová prezentace — 7. října 2026

- Prošlo všech 46 testů správy oken, minimalizace, přepínače, screenshotů,
  obnovy a viditelnosti taskbaru. Nové testy ověřují odlišné signály show/hide
  pouze hlavnímu procesu služby, čekání na správný PID horního panelu,
  nehotové povrchy a časový limit. Obecný profil čeká na všechny výstupy.
- `check` prošel pro `generic` i `current-pc`: každý má 42 757 uživatelských
  položek a 36 kontrol syntaxe skriptů/JSON.
- Na živé relaci původního stroje ověřeno opakované show/hide, překrytí
  launcherem a návrat bez restartu procesů. Horní panel začíná x=8, y=8;
  levý x=8, y=48. Vyhrazené místo je 68 px vlevo a 48 px nahoře.
- Fullscreen video na HDMI-A-1 překrylo horní panel; screenshot zkontrolovaný.
  Hyprland nehlásil chyby konfigurace. Po opravě `interval: "once"` zmizelo
  trvalé vytížení způsobené opakovaným načítáním SVG launcheru.
- Banner README skutečně vyrenderovaný pomocí `rsvg-convert` a vizuálně
  zkontrolovaný. Používá vlastní schematický náhled bez osobního obsahu oken.
- Audit celého payloadu a manifestu skončil bez nálezů. Ověřené také místní
  odkazy README a vykreslení konfigurace taskbaru pro jiné HOME v obou profilech.
- Nový obecný profil ověřený v testech a kontrolách konfigurace; na jiném
  fyzickém počítači se tento profil zatím nespouštěl.

## Původní ověření obnovy

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

## Nativní launcher a skleněný dock — 30. září 2026

- Oba konfigurační profily prošly kontrolou; sada má nově 18 behaviorálních testů.
- Na skutečném DP-2 2560×1440 / scale 1 ověřeno ruční show/hide/toggle přes dock
  layer v Hyprlandu, dočasné skrytí pod launcherem a návrat původního ručního stavu.
- Nový loginový stav je viditelný; testy ověřují reset skryté volby při nové relaci,
  její zachování při restartu a přepnutí během otevřeného panelu.
- Quickshell konfigurace načtená bez chyby; launcher nemá UI scale transform,
  ikony používají sourceSize podle pixelového poměru obrazovky. Náhledy launcheru
  a docku vizuálně zkontrolované na skutečném monitoru; osobní screenshoty nejsou v Gitu.
- Hyprland hlásí prázdný configerrors; binding Super + Ctrl + D registrovaný.
- Systemd jednotka docku používá KillMode=process pro zachování spuštěných aplikací
  a po startu synchronizuje ruční volbu. Případné hlášení o zbylých procesech v její
  skupině odpovídá těmto zachovaným aplikacím, nikoli novému procesu docku.

- Alt-Tab nyní používá vlastní Quickshell přehled s živými náhledy, zmrazeným MRU
  pořadím a potvrzením při puštění Altu. Alt + Shift + Tab vybírá opačně, Esc ruší.
  Potvrzení obnoví případně minimalizované okno, aktivuje jej a nastaví explicitní
  maximalizaci (opakování maximalizaci nevypne). Kontrola PID chrání před aktivací
  jiného okna po zavření/recyklaci adresy.
- Nových 24 testů prošlo včetně MRU pořadí, odložených oken, zaniklého/recyklovaného
  handle a opakovaného PrintScreenu s procesem schránky běžícím na pozadí.
- Virtuální Wayland klávesnice se skutečnými kódy Alt/Tab ověřila náhledy na
  aktivním monitoru, nezměněný focus při držení Altu, potvrzení a maximalizaci,
  opačný výběr, zrušení a rychlý Alt-Tab bez čekání na načtení panelu.
  Test používal dočasná okna a obnovil původní focus i nastavení myši.
- Opravený screenshot helper uvolňuje zámek před spuštěním wl-copy. Dřívější
  zdánlivý cooldown způsoboval zděděný descriptor zámku v procesu schránky.
- Více fyzických Tabů v jednom držení Altu ověřeno samostatně: výběr postupoval
  1 → 2 → 3 bez přepnutí zaměření. Události nesou session, revision a konečný
  offset; pozdě doručené starší zprávy nezmění novější nebo potvrzený výběr.
  Aktivace čeká na skutečné odmapování layeru, aby compositor nevrátil starý focus.

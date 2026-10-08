# Ovládání desktopu

| Zkratka | Akce |
| --- | --- |
| Super + Enter | Kitty |
| Super + B | Firefox |
| Super + E | Thunar |
| Super + Space / samotný Super | Launcher |
| Super + N | Ovládací centrum |
| Super + D | Dashboard |
| Super + Ctrl + D | Zobrazit / skrýt levý taskbar |
| Alt + Tab / Alt + Shift + Tab | Náhledy oken podle posledního použití; puštění Altu potvrdí a maximalizuje výběr |
| Super + L | Zamknutí |
| Super + Q | Zavření okna |
| Super + V | Plovoucí okno |
| Super + F | Fullscreen |
| Super + M / Super + Shift + M | Minimalizovat / obnovit |
| Super + 1–9 | Plocha; fyzické klávesy fungují i v češtině |
| Super + Shift + 1–9 | Přesun okna na plochu |
| Super + šipky | Přepnutí zaměření |
| Super + levé / pravé tažení myší | Přesun / změna velikosti |
| Super + Shift + V | Schránka |
| Super + Shift + W | Waypaper |
| Super + Shift + T | Výběr palety |
| Super + Shift + E | Napájení / ukončení relace |
| Print / Shift + Print | Výřez / celý screenshot |
| Alt + Shift | Čeština / US klávesnice |

Aktivní paleta se přepíná přes `desktop-theme`; vytváří konzistentní GTK, Qt,
Kitty, Fuzzel, Waybar a Hyprlock nastavení. Tapety spravuje Waypaper, hlavní tapeta
se přes `waypaper-sync` použije i pro zámek.

Hyprbars doplňuje barevná tlačítka zavřít, minimalizovat a maximalizovat.
Nekompatibilní plugin se nenačte; ostatní klávesové ovládání zůstává funkční.

Počasí používá Brno a časové pásmo Europe/Prague; noční filtr má původní souřadnice
Prahy. Tyto osobní výchozí hodnoty lze upravit v `desktop-weather` a
`desktop-nightlight.service`. Noční filtr se pouze zachovává jako volitelná služba.

Klik na hlasitost ve Waybaru otevře panel `desktop-sound-control`: výstupy,
mikrofon, hlasitost a směrování jednotlivých aplikací a profily zařízení.
Panel používá PipeWire/WirePlumber přes `pactl`; Pavucontrol zůstává dostupný
jako samostatná aplikace. Párování Bluetooth,
Wi-Fi hesla, účty Spotify/Discord/Steam/Sober a reálné herní testy se řeší po přihlášení.

EasyEffects obsahuje i všechny volitelné pluginy z Arch repozitáře: Calf, LSP,
MDA, x42 a ZAM; Yelp poskytuje nápovědu. DeepFilterNet LADSPA se instaluje přes
`tools/install_deepfilter.py` ze zachovaného AUR předpisu a binárky autora,
ověřené připnutým SHA-256. Krok `packages` ho zahrnuje automaticky.
Nastavení efektů a mikrofonu si uživatel volí sám; jeho presety nejsou v Gitu.

## Launcher, Waybar a levý taskbar

Launcher a dashboard se vykreslují v nativní velikosti bez dodatečného 125% zvětšení
na 1440p monitoru. Animace používá průhlednost a malý posun, nikoli škálování textu.
Ikony se rasterizují pro skutečné pixelové měřítko cílového monitoru.

Levý taskbar je druhý Waybar se společným černošedým stylem. Na původním stroji
je široký 60 px a navazuje na horní panel na DP-2: horní začíná na x=8, y=8,
levý na x=8, y=48. Profil `generic` zobrazuje taskbar na každém monitoru bez
pevného názvu výstupu. Horní panel se musí vykreslit první; hlídá to
`desktop-taskbar-ready` v příslušném hardwarovém profilu.

Nahoře jsou launcher, pracovní plochy, počítadlo minimalizovaných oken a aplikace
s ikonami 28 px. Dole bdělý režim, oznámení, zámek a napájení. Horní panel drží
čas, audiovlny a systémové ukazatele. SVG launcheru se načítá jednou přes
`interval: "once"`, aby se obrázek neobnovoval každou milisekundu.

Oba panely mají průhlednost 0,62 a compositorový blur velikosti 10 se dvěma průchody.
Používají vrstvu `bottom`: běžná dlaždicová okna respektují vyhrazené místo,
fullscreen video nebo hra panely překryje. Vnitřní odsazení (`gaps_in`) je 4 px,
vnější (`gaps_out`) 8 px. Tapeta Black Waves je uložená jako SVG i PNG a přes
`current.png` se použije také při přihlášení a zamykání.

Taskbar po novém přihlášení zůstává viditelný. `Super + Ctrl + D` ho přepne;
`desktop-dock show` a `desktop-dock hide` nastaví stav přímo.

Při otevření launcheru, dashboardu nebo ovládacího centra se taskbar dočasně skryje.
Po jejich zavření se vrátí pouze tehdy, pokud nebyl ručně skrytý. Změna motivu nebo
restart taskbaru zachová ruční volbu v aktuální relaci. Nové přihlášení ji vrátí na
viditelný taskbar. Stav se uchovává v `~/.local/state/desktop/dock.json`, informace
o otevřeném panelu v XDG_RUNTIME_DIR; tato data nejsou v Gitu.

Názvy `desktop-dock.service` a `desktop-dock` zůstávají kvůli návaznosti na relaci
a přepínání motivů. Služba spouští Waybar s `taskbar.jsonc` a `taskbar.css`;
USR1 panel zobrazí, USR2 skryje. Signál míří pouze na hlavní proces této služby,
nikoli na horní Waybar. Restart horní služby obnoví oba panely v tomto pořadí.
`KillMode=process` zachová dříve spuštěné aplikace.

Nová okna otevřená do popředí a záměrně obnovená okna se skládají vedle ostatních.
Klik v taskbaru nebo výslovné přepnutí okna může zrušit maximalizaci pracovních
oken. Pouhý pohyb myši, přepnutí plochy a návrat fokusu po zavření okna nebo
panelu zachovávají rozložení i maximalizaci. Okna otevíraná na pozadí a děti
minimalizovaných aplikací nepřerovnávají ostatní okna. Plovoucí dialogy a výslovný
fullscreen videa nebo hry si zachovají svůj režim. Aplikace mohou upozornit na
novou událost, ale samy si nepřebírají fokus.

Alt-Tab drží pořadí oken po celou dobu výběru. První Tab vybere poslední použité
okno, další Taby pokračují seznamem, Shift + Tab jde opačně. Výběr zahrnuje okna
z ostatních ploch a minimalizovaná okna; odložené okno se při potvrzení obnoví.
Esc zavře přepínač bez změny zaměření. Maximalizace zachovává horní panel
a není fullscreen. Náhledy se snímají jen při otevřeném přepínači.
Křížek v pravém horním rohu karty nebo Delete požádá aplikaci o zavření okna.
Před zavřením se kontroluje adresa i PID; zbývající karty lze dál přepínat.
Dialog pro neuložené změny případně zobrazí samotná aplikace.

Žluté tlačítko v titulku minimalizuje pouze dané okno. Každé okno se odkládá
samostatně, takže opakovaná minimalizace neskryje další okna
ani celou plochu. Obnovení funguje přes Alt-Tab, počítadlo v levém panelu
nebo Super + Shift + M; obnovit lze i okna odložená starší konfigurací.

## Jas monitorů a noční režim

Dvě ikonky slunce ve Waybaru ovládají hardwarový jas AOC a MSI přes DDC/CI.
Klik otevře okno se slidery, kolečko mění jas po 5 %. Noční režim pod slidery
přepíná teplotu obou monitorů na přibližně 4000 K; vypnutí obnoví běžné barvy.
Filtr se zapíná ručně, funguje i přes den a při spuštění desktopu je vypnutý.

`ddcutil` a modul `i2c-dev` jsou součástí instalace. V menu monitoru musí být
povolené DDC/CI. Skript při změnách používá zapamatovanou sběrnici, slučuje
požadavky ze slideru a po dokončení posunu ověřuje skutečný jas. Průběžné
hodnoty a přiřazení sběrnic jsou jen v XDG_RUNTIME_DIR, nejsou součástí Gitu.

Sériová čísla jsou v `~/.config/desktop/brightness-monitors.json`, například
`{"aoc": "SERIAL_PRVNIHO_MONITORU", "msi": "SERIAL_DRUHEHO_MONITORU"}`.
Profil `current-pc` obsahuje původní AOC a MSI. Profil `generic` je prázdný;
po doplnění sériových čísel z `ddcutil detect --terse` restartuj Waybar.
Ikonky nenakonfigurovaných monitorů jsou skryté.

PrintScreen nemá čekací dobu mezi hotovými snímky. Zámek existuje pouze během
interaktivního výběru oblasti, aby se nepřekrývalo více výběrových kurzorů.
Shift + PrintScreen fotí okamžitě celou plochu. Proces schránky tento zámek nedědí.

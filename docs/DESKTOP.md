# Ovládání desktopu

| Zkratka | Akce |
| --- | --- |
| Super + Enter | Kitty |
| Super + B | Firefox |
| Super + E | Thunar |
| Super + Space / samotný Super | Launcher |
| Super + N | Ovládací centrum |
| Super + D | Dashboard |
| Super + Ctrl + D | Zobrazit / skrýt dock |
| Alt + Tab / Alt + Shift + Tab | Další / předchozí okno na aktuální ploše |
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

Hlasitost a zařízení spravuje PipeWire/WirePlumber a Pavucontrol. Párování Bluetooth,
Wi-Fi hesla, účty Spotify/Discord/Steam/Sober a reálné herní testy se řeší po přihlášení.

## Launcher a skleněný dock

Launcher a dashboard se vykreslují v nativní velikosti bez dodatečného 125% zvětšení
na 1440p monitoru. Animace používá průhlednost a malý posun, nikoli škálování textu.
Ikony se rasterizují pro skutečné pixelové měřítko cílového monitoru.

Dock má průhledné skleněné pozadí s compositorovým blur a ikony 32 px bez zvětšení
při hoveru. Po novém přihlášení je viditelný. `Super + Ctrl + D` ho přepne;
`desktop-dock show` a `desktop-dock hide` nastaví stav přímo.

Při otevření launcheru, dashboardu nebo ovládacího centra se dock dočasně skryje.
Po jejich zavření se vrátí pouze tehdy, pokud nebyl ručně skrytý. Změna motivu nebo
restart docku zachová ruční volbu v aktuální relaci. Nové přihlášení ji vrátí na
viditelný dock. Stav se uchovává v `~/.local/state/desktop/dock.json`, informace
o otevřeném panelu v XDG_RUNTIME_DIR; tato data nejsou v Gitu.

Dock zůstává ve vrstvě top bez vyhrazeného místa, takže nepřesouvá pracovní okna
a fullscreen je nad ním. Restart jeho služby zachová aplikace spuštěné z docku.

# Ovládání desktopu

| Zkratka | Akce |
| --- | --- |
| Super + Enter | Kitty |
| Super + B | Firefox |
| Super + E | Thunar |
| Super + Space / samotný Super | Launcher |
| Super + N | Ovládací centrum |
| Super + D | Dashboard |
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

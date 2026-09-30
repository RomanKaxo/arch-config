# Původ zdrojů a licence

| Komponenta | Původ a verze | Uložení |
| --- | --- | --- |
| hyprbars | github.com/hyprwm/hyprland-plugins, commit `7644cecdb947060682891a0db2a0cdc5c0b9e704`, pro Hyprland 0.56.2 | `vendor/hyprbars`; upstream BSD licence |
| Colloid ikony | github.com/vinceliuice/Colloid-icon-theme, commit `ceac6608ecd0e40025cbc2ebbd32bf0e0f4ebc6a` | Instalované assets; GPL licence v `vendor/licenses` |
| Waypaper | PyPI Waypaper 2.8, anufrievroman/waypaper | GPL licence a lokálně upravené `app.py` v `vendor/waypaper` |
| Inter | rsms/Inter, nainstalované variabilní fonty | SIL Open Font License v `vendor/licenses` |
| DesktopWaves | Lokální FontTools generátor | `tools/build-wave-font.py` a vygenerovaný font |
| Tapety, Graphite úpravy, SDDM | Současné lokální desktopové prostředky | Payload |

Zdroj hyprbars má pro reprodukovatelný build přidanou explicitní CMake závislost
na Lua 5.5, používanou nainstalovaným Hyprlandem. Waypaper app.py zachovává místní
styling a integraci restartu Hyprpaper přes systemd; cesta k launcheru se vykresluje
pro cílový HOME. Po změně upstream verze musí být tato úprava znovu zkontrolována.

Přesná evidence je v `packages/sources.json`; pozorované Arch verze nejsou lockfile.
Licence převzatých prostředků zůstávají jejich původním autorům. Proprietární
aplikace a jejich instalační balíky nejsou redistribuované v tomto Git repozitáři.

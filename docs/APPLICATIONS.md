# Aplikace a účty

## Automaticky obnovené seznamy

`arch-config packages` instaluje současné explicitní Arch balíčky, včetně Firefoxu,
Discordu, Steamu, FileZilly, Thunaru, Loupe, mpv, Mousepadu, Evince a dalších nástrojů.
Spotify (`com.spotify.Client`) a Sober (`org.vinegarhq.Sober`) se instalují z Flathubu
v uživatelském scope. Steam znovu stáhne svůj runtime a hry, Flatpak potřebné runtime.
Žádné účty, databáze nebo uložená hesla se nepřenášejí.

`arch-config extras` obnoví Waypaper 2.8 a hyprbars. Pro prázdné venv jsou vyžadované
systémové PyGObject/Cairo/Pillow knihovny a balíčky z `packages/build.txt`.
Balíček GTK 3 přinese desktop; úprava Waypaper se přidává až po úspěšné instalaci.

## Lokálně distribuované programy

Původní PC má VS Code 1.139.1 a ChatGPT 26.928.20755 rozbalené v `~/.local/opt`,
Codex standalone pod spravovaným adresářem `.codex/packages`. Jejich binárky nejsou
v Gitu. Na jiném PC musí být dostupný originální instalátor nebo samostatná záloha
pouze distribučních souborů. Aktuální tarball VS Code je v
`~/Downloads/vscode-1.139.1-linux-x64.tar.gz`; neobsahuje uživatelský profil.
Nevytváří se náhradní neověřený instalační URL pro aplikaci, jejíž původní balík není dostupný.

Nástroj `tools/import_application.py` umí importovat rozbalené distribuce bez účtů.
Přijímá výslovně uvedenou lokální distribuci a odmítá přepsat existující instalaci.
Příklad na novém HOME:

```bash
# VS Code: rozbal oficiální Linux x64 tarball do pracovní složky.
mkdir -p /tmp/vscode-import
tar -xf /CESTA/vscode-linux-x64.tar.gz -C /tmp/vscode-import
python tools/import_application.py vscode --source /tmp/vscode-import/VSCode-linux-x64

# ChatGPT: kořen originální rozbalené distribuce musí obsahovat usr/lib/chatgpt.
python tools/import_application.py chatgpt --source /CESTA/rozbaleny-chatgpt

# Standalone Codex: originální spustitelný soubor bez uživatelského .codex profilu.
python tools/import_application.py codex --source /CESTA/codex
update-desktop-database ~/.local/share/applications
```

Launcher a ikony VS Code/ChatGPT jsou součástí config payloadu a odkazují na tyto
standardní cílové cesty. Dokud distribuci neobnovíš, launchery nebudou funkční.
Původní distribuční adresáře lze do samostatné zálohy uložit celé; uživatelské
`.config/Code`, `.config/Codex` a `.codex` se tím nezálohují.

## Volitelné vývojářské prostředí

Elaris-Harness je samostatný projekt v `~/Desktop/Elaris-Harness`, nikoliv desktopová
konfigurace. Obnov jeho vlastní Git repozitář a závislosti podle jeho README.
OmniRoute byl instalovaný jako npm balíček `omniroute@3.8.50`; přesný původ eviduje
`packages/omniroute.json`. Na novém stroji:

```bash
npm install --global --prefix "$HOME/.local" omniroute@3.8.50
./arch-config install --component workspace --profile current-pc
systemctl --user daemon-reload
systemctl --user enable elaris.service omniroute.service
```

Workspace komponenta neinstaluje aplikace ani neaktivuje služby sama a odmítne
instalaci bez existujícího Elaris serveru. Zálohu konfigurace/účtů OmniRoute udržuj
odděleně od Gitu. Na jiném stroji nahraď profil `generic`.

## Co zůstává po instalaci ruční

Přihlášení do GitHubu, prohlížeče, ChatGPT/Codex, Discordu, Steamu, Spotify a Sober;
stahování her a vlastní projekty. Při skutečné obnově ověř mikrofon, sdílení obrazovky,
Proton hru, Roblox a Bluetooth zařízení. Samotná přítomnost balíčků tyto workflow neověřuje.
War Thunder launcher obsahuje Steam AppID 236390; hra samotná ani save data se nepřenášejí.

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.components.misc
import "Logic.js" as Logic

Scope {
    id: root

    property bool opened: false
    property var entries: []
    property int selected: -1
    property var history: []
    property ShellScreen activeScreen
    property var settings: ({})
    readonly property var config: ({
        enabled: settings.enabled !== false,
        allWorkspaces: settings.allWorkspaces !== false,
        includeMinimized: settings.includeMinimized !== false,
        previews: settings.previews !== false,
        cardWidth: Math.max(180, Math.min(400, Number(settings.cardWidth) || 260)),
        maxVisible: Math.max(1, Math.min(7, Math.floor(Number(settings.maxVisible) || 5)))
    })

    function client(entry) {
        return entry ? Hypr.toplevels.values.find(t => Logic.matches(t.lastIpcObject, entry)) ?? null : null;
    }

    function remember() {
        const address = Hypr.activeToplevel?.lastIpcObject.address;
        if (address && !root.opened)
            root.history = [address, ...root.history.filter(a => a !== address)].slice(0, 100);
    }

    function step(direction: int): void {
        if (!root.config.enabled) {
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.cycle_next({previous=${direction < 0}})` : `cyclenext ${direction < 0 ? "prev" : ""}`);
            return;
        }
        if (!root.opened) {
            const active = Hypr.activeToplevel?.lastIpcObject.address ?? "";
            root.entries = Logic.snapshot(Hypr.toplevels.values.map(t => t.lastIpcObject), active,
                Hypr.focusedWorkspace?.name ?? "", root.config, root.history);
            if (!root.entries.length)
                return;
            root.activeScreen = Quickshell.screens.find(s => Hypr.monitorFor(s)?.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0];
            root.selected = active && root.entries[0].address === active ? 0 : (direction > 0 ? -1 : 0);
            root.opened = true;
            Hyprland.refreshToplevels();
        }
        root.selected = Logic.next(root.selected, direction, root.entries.length);
    }

    function cancel(): void {
        root.opened = false;
        root.remember();
    }

    function accept(): void {
        if (!root.opened)
            return;
        const entry = root.entries[root.selected];
        root.opened = false;
        // Drop the layer's keyboard focus before focusing the chosen window.
        Qt.callLater(() => {
            const t = root.client(entry);
            if (!t)
                return;
            if (Logic.minimized(t.workspace?.name ?? "")) {
                Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/caelestia-window", "restore", entry.address]);
            } else if (/^0x[0-9a-fA-F]+$/.test(entry.address)) {
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({window="address:${entry.address}"})` : `focuswindow address:${entry.address}`);
            }
        });
    }

    Component.onCompleted: remember()

    Connections {
        target: Hypr
        function onActiveToplevelChanged(): void { root.remember(); }
    }

    Connections {
        target: Hypr.toplevels
        function onValuesChanged(): void {
            if (!root.opened)
                return;
            const chosen = root.entries[root.selected]?.address;
            root.entries = root.entries.filter(e => root.client(e));
            if (!root.entries.length) {
                root.cancel();
                return;
            }
            const index = root.entries.findIndex(e => e.address === chosen);
            root.selected = index < 0 ? Math.min(root.selected, root.entries.length - 1) : index;
        }
    }

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/caelestia/switcher.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.settings = JSON.parse(text());
            } catch (error) {
                console.warn("Caelestia switcher: invalid settings", error);
            }
        }
    }

    CustomShortcut {
        name: "switcherNext"
        description: "Next window in Alt-Tab"
        onPressed: root.step(1)
    }
    CustomShortcut {
        name: "switcherPrevious"
        description: "Previous window in Alt-Tab"
        onPressed: root.step(-1)
    }
    CustomShortcut {
        name: "switcherAccept"
        description: "Activate selected window on Alt release"
        onPressed: root.accept()
        onReleased: root.accept()
    }

    IpcHandler {
        target: "switcher"
        function next(): void { root.step(1); }
        function previous(): void { root.step(-1); }
        function accept(): void { root.accept(); }
        function cancel(): void { root.cancel(); }
        function status(): string {
            return JSON.stringify({opened: root.opened, selected: root.selected, entries: root.entries,
                screen: root.activeScreen?.name ?? "", config: root.config});
        }
    }

    SwitcherWindow {
        controller: root
    }
}

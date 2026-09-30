import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "."

PanelWindow {
    id: win
    required property var shell
    property var windows: []
    property int selected: 0
    property int pendingSteps: 0
    property string epoch: ''
    property int revision: -1
    property int session: -1
    property int completedSession: -1
    property bool loading: false
    property bool commitPending: false
    property string closingAddress: ''
    property int closingSession: -1
    property bool opened: shell.view === 'switcher'
    visible: opened && windows.length > 0
    screen: shell.targetScreen
    anchors { top: true; bottom: true; left: true; right: true }
    color: 'transparent'
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: 'desktop-switcher'
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onOpenedChanged: if (opened) Qt.callLater(() => keyboard.forceActiveFocus())

    function updateSession(serial, offset, generation, version, commit) {
        if (epoch !== generation) {
            cancel(); epoch = generation; session = -1; completedSession = -1; revision = -1
        }
        if (serial <= completedSession || serial < session || version < revision || commitPending) return
        revision = version
        if (serial > session) {
            cancel(); session = serial
            step(offset)
        } else if (loading) pendingSteps = offset
        else if (opened && windows.length) selected = ((offset % windows.length) + windows.length) % windows.length
        if (commit) finish()
    }
    function step(direction) {
        if (loading) { pendingSteps += direction; return }
        if (opened && windows.length) {
            selected = (selected + direction + windows.length) % windows.length
            return
        }
        shell.targetScreen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
        windows = []; pendingSteps = direction; commitPending = false; loading = true
        listing.running = true
    }
    function finish() {
        if (closing.running) { commitPending = true; return }
        if (loading) { commitPending = true; return }
        if (!opened) return
        completedSession = Math.max(completedSession, session)
        const chosen = windows[selected]
        shell.view = ''
        windows = []
        if (chosen) Quickshell.execDetached([Quickshell.env('HOME') + '/.local/bin/desktop-switcher', 'activate', chosen.address, String(chosen.pid)])
    }
    function cancel() {
        completedSession = Math.max(completedSession, session)
        commitPending = false; pendingSteps = 0; loading = false
        listing.running = false
        if (opened) shell.view = ''
        windows = []
    }
    function status() { return JSON.stringify({loading: loading, opened: opened, selected: selected, session: session, revision: revision, completed: completedSession, pending: pendingSteps, windows: windows}) }
    function closeWindow(index) {
        if (closing.running || !windows[index]) return
        const chosen = windows[index]
        closingAddress = chosen.address
        closingSession = session
        closing.command = [Quickshell.env('HOME') + '/.local/bin/desktop-switcher', 'close', chosen.address, String(chosen.pid)]
        closing.running = true
    }
    Process {
        id: closing
        onExited: (code, status) => {
            if (code === 0 && win.session === win.closingSession && win.opened) {
                const selectedAddress = win.windows[win.selected]?.address
                win.windows = win.windows.filter(w => w.address !== win.closingAddress)
                const retained = win.windows.findIndex(w => w.address === selectedAddress)
                win.selected = retained >= 0 ? retained : Math.min(win.selected, Math.max(0, win.windows.length - 1))
            }
            win.closingAddress = ''
            if (!win.windows.length && win.opened) win.cancel()
            else if (win.commitPending) { win.commitPending = false; win.finish() }
            else Qt.callLater(() => keyboard.forceActiveFocus())
        }
    }
    function toplevel(address) {
        return Hyprland.toplevels.values.find(t => t.address.replace(/^0x/, '') === address.replace(/^0x/, ''))?.wayland || null
    }
    Process {
        id: listing
        command: [Quickshell.env('HOME') + '/.local/bin/desktop-switcher', 'list']
        stdout: StdioCollector {
            onStreamFinished: {
                if (!win.loading) return
                try { win.windows = JSON.parse(text) } catch(e) { win.windows = [] }
                win.loading = false
                if (!win.windows.length) { win.commitPending = false; return }
                win.selected = ((win.pendingSteps % win.windows.length) + win.windows.length) % win.windows.length
                win.shell.view = 'switcher'
                if (win.commitPending) win.finish()
                else Qt.callLater(() => keyboard.forceActiveFocus())
            }
        }
    }
    Rectangle { anchors.fill: parent; color: '#40000000'; MouseArea { anchors.fill: parent; onClicked: win.cancel() } }
    FocusScope {
        id: keyboard
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                win.step((event.modifiers & Qt.ShiftModifier) || event.key === Qt.Key_Backtab ? -1 : 1); event.accepted = true
            } else if (event.key === Qt.Key_Escape) { win.cancel(); event.accepted = true }
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { win.finish(); event.accepted = true }
            else if (event.key === Qt.Key_Right) { win.step(1); event.accepted = true }
            else if (event.key === Qt.Key_Left) { win.step(-1); event.accepted = true }
            else if (event.key === Qt.Key_Delete) { win.closeWindow(win.selected); event.accepted = true }
        }
        Keys.onReleased: event => {
            if (event.key === Qt.Key_Alt && !event.isAutoRepeat) { win.finish(); event.accepted = true }
        }
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 96, 1240)
            height: Math.min(parent.height - 96, grid.implicitHeight + 92)
            radius: Design.radiusLarge
            color: Design.alpha(Design.bg, 0.94)
            border.width: 1; border.color: Design.alpha(Design.accent, 0.35)
            Text {
                x: 24; y: 18; text: 'Přepnout okno'; color: Design.text
                font.family: Design.font; font.pixelSize: 16; renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right; anchors.rightMargin: 24; y: 20
                text: 'Tab: další   ·   Delete / ×: zavřít   ·   pusť Alt pro výběr'
                color: Design.muted; font.family: Design.font; font.pixelSize: 12; renderType: Text.NativeRendering
            }
            Flickable {
                id: scroll
                x: 20; y: 54; width: parent.width - 40; height: parent.height - 74
                contentHeight: grid.implicitHeight; clip: true
                function reveal() {
                    const row = Math.floor(win.selected / grid.columns)
                    const top = row * 194
                    if (top < contentY) contentY = top
                    else if (top + 184 > contentY + height) contentY = top + 184 - height
                }
                Connections { target: win; function onSelectedChanged() { Qt.callLater(() => scroll.reveal()) } }
                Grid {
                    id: grid
                    width: parent.width; columns: Math.max(1, Math.floor(width / 240)); spacing: 10
                    Repeater {
                        model: win.windows
                        delegate: Rectangle {
                            id: card
                            required property var modelData
                            required property int index
                            width: (grid.width - (grid.columns - 1) * grid.spacing) / grid.columns
                            height: 184; radius: 12
                            color: win.selected === index ? Design.alpha(Design.selection, 0.95) : Design.alpha(Design.surface, 0.7)
                            border.width: win.selected === index ? 2 : 1
                            border.color: win.selected === index ? Design.accent : Design.alpha(Design.border, 0.6)
                            Text {
                                x: 12; y: 10; width: parent.width - 52; elide: Text.ElideRight
                                text: card.modelData.title || card.modelData.app
                                color: Design.text; font.family: Design.font; font.pixelSize: 12; renderType: Text.NativeRendering
                            }
                            ScreencopyView {
                                id: preview
                                x: 10; y: 36; width: parent.width - 20; height: 116
                                captureSource: win.visible ? win.toplevel(card.modelData.address) : null
                                live: win.visible
                            }
                            Text {
                                anchors.centerIn: preview; visible: !preview.hasContent
                                text: card.modelData.app; color: Design.muted; width: preview.width - 16; elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter; font.family: Design.font; font.pixelSize: 16
                            }
                            Text {
                                x: 12; y: 160; width: parent.width - 24; elide: Text.ElideRight
                                text: card.modelData.app + (card.modelData.minimized ? ' · minimalizované' : '')
                                color: Design.muted; font.family: Design.font; font.pixelSize: 10; renderType: Text.NativeRendering
                            }
                            MouseArea { anchors.fill: parent; onClicked: { win.selected = card.index; win.finish() } }
                            Rectangle {
                                anchors.right: parent.right; anchors.rightMargin: 7; y: 6
                                width: 26; height: 26; radius: 8; z: 10
                                color: closeMouse.containsMouse ? '#a93838' : Design.alpha(Design.selection, 0.85)
                                opacity: win.closingAddress === card.modelData.address ? 0.45 : 1
                                Text { anchors.centerIn: parent; text: '×'; color: Design.text; font.pixelSize: 19 }
                                MouseArea {
                                    id: closeMouse; anchors.fill: parent; hoverEnabled: true
                                    enabled: !closing.running; cursorShape: Qt.PointingHandCursor
                                    onClicked: win.closeWindow(card.index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    property var colors: ({bg:'#0d0d0d', surface:'#181818', selection:'#303030', border:'#3b3b3b', text:'#dedede', muted:'#999999', accent:'#bcbcbc', cyan:'#b7b7b7'})
    readonly property color bg: colors.bg
    readonly property color surface: colors.surface
    readonly property color selection: colors.selection
    readonly property color border: colors.border
    readonly property color text: colors.text
    readonly property color muted: colors.muted
    readonly property color accent: colors.accent
    readonly property color blue: colors.cyan
    readonly property string font: 'Inter Variable'
    readonly property string mono: 'JetBrainsMono Nerd Font'
    readonly property int small: 8
    readonly property int medium: 16
    readonly property int large: 24
    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 16
    readonly property int radiusLarge: 24
    readonly property int fast: 160
    readonly property int normal: 220
    readonly property int slow: 280
    function alpha(c: color, a: real): color { return Qt.rgba(c.r,c.g,c.b,a) }
    FileView {
        path: '@HOME@/.config/desktop/active-tokens.json'
        watchChanges: true
        onFileChanged: reload()
        onLoaded: colors = JSON.parse(text())
    }
}

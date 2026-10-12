pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import "Logic.js" as Logic

StyledRect {
    id: root
    required property var client
    required property bool selected
    required property bool previews
    signal chosen

    readonly property string appClass: client?.lastIpcObject.class ?? ""
    readonly property string appName: DesktopEntries.heuristicLookup(appClass)?.name || appClass
    readonly property bool minimized: Logic.minimized(client?.workspace?.name ?? "")

    radius: Tokens.rounding.large
    color: selected ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh
    border.width: selected ? 2 : 1
    border.color: selected ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.small

        StyledClippingRect {
            id: preview
            visible: root.previews
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.small
            color: Colours.palette.m3surfaceContainerLowest

            MaterialIcon {
                anchors.centerIn: parent
                text: root.minimized ? "minimize" : Icons.getAppCategoryIcon(root.appClass, "desktop_windows")
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.extraLarge
            }
            ScreencopyView {
                anchors.centerIn: parent
                captureSource: root.client?.wayland ?? null
                live: root.selected
                constraintSize: Qt.size(preview.width, preview.height)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small
            Image {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                sourceSize: Qt.size(32, 32)
                source: Icons.getAppIcon(root.appClass, "application-x-executable")
                fillMode: Image.PreserveAspectFit
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall
                StyledText {
                    Layout.fillWidth: true
                    text: root.appName
                    font: Tokens.font.title.small
                    color: root.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.client?.title || root.appClass
                    font: Tokens.font.body.small
                    color: root.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.minimized ? "Minimalizované" : "Plocha " + Hypr.trimWsName(root.client?.workspace?.name ?? "")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                    elide: Text.ElideRight
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.chosen()
    }
}

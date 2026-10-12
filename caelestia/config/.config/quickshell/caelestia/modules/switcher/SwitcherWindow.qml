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

PanelWindow {
    id: root
    required property var controller

    screen: controller.activeScreen ?? Quickshell.screens[0]
    Tokens.screen: screen?.name ?? ""
    contentItem.Config.screen: screen?.name ?? ""
    contentItem.Tokens.screen: screen?.name ?? ""
    visible: controller.opened
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.namespace: "caelestia-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: controller.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    implicitWidth: Math.min((screen?.width ?? 1920) - 100,
        Math.min(controller.entries.length, controller.config.maxVisible) * (controller.config.cardWidth + Tokens.spacing.medium) - Tokens.spacing.medium + Tokens.padding.extraLarge * 2)
    implicitHeight: layout.implicitHeight + Tokens.padding.extraLarge * 2

    StyledRect {
        id: surface
        anchors.fill: parent
        radius: Tokens.rounding.extraLarge
        color: Colours.layer(Colours.palette.m3surfaceContainer, 0)
        border.width: 1
        border.color: Colours.palette.m3outlineVariant
        opacity: root.controller.opened ? 1 : 0

        Behavior on opacity { Anim { type: Anim.FastEffects } }

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: Tokens.padding.extraLarge
            spacing: Tokens.spacing.large

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small
                MaterialIcon { text: "switch_window" }
                StyledText {
                    text: "Přepnout okno"
                    font: Tokens.font.title.medium
                    Layout.fillWidth: true
                }
                StyledText {
                    text: (root.controller.selected + 1) + " / " + root.controller.entries.length
                    font: Tokens.font.label.large
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            ListView {
                id: cards
                Layout.fillWidth: true
                Layout.preferredHeight: root.controller.config.previews ? 244 : 116
                orientation: ListView.Horizontal
                spacing: Tokens.spacing.medium
                clip: true
                model: root.controller.entries
                currentIndex: root.controller.selected
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: width
                highlightMoveDuration: Tokens.anim.durations.expressiveFastEffects
                snapMode: ListView.SnapToItem
                boundsBehavior: Flickable.StopAtBounds

                delegate: WindowCard {
                    required property var modelData
                    required property int index
                    width: Math.min(root.controller.config.cardWidth, cards.width)
                    height: cards.height
                    client: root.controller.client(modelData)
                    selected: index === root.controller.selected
                    previews: root.controller.config.previews
                    onChosen: {
                        root.controller.selected = index;
                        root.controller.accept();
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: "Pusť Alt pro výběr   ·   Shift + Tab zpět   ·   Esc zavřít"
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }

    contentItem {
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.controller.cancel();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.controller.accept();
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Left) {
                root.controller.step(event.key === Qt.Key_Right ? 1 : -1);
            } else {
                return;
            }
            event.accepted = true;
        }
        Keys.onReleased: event => {
            if (event.key === Qt.Key_Alt && !event.isAutoRepeat) {
                root.controller.accept();
                event.accepted = true;
            }
        }
    }
}

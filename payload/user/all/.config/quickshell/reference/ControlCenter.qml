pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "."

Item {
    id: panel
    property var status: ({})
    property var player: null
    property var notifications: []
    property var weather: ({available:false})
    property date now: new Date()
    property bool opened: false
    property bool outputsExpanded: false
    property string actionError: ''
    property bool actionResponded: false
    readonly property bool busy: actionProcess.running
    readonly property bool hasTrack: !!player && !!player.trackTitle
    implicitHeight: body.implicitHeight + 32
    signal command(string command, bool closePanel)
    signal closeRequested()
    signal refreshRequested()
    onOpenedChanged: if (opened) { actionError=''; volumeSlider.forceActiveFocus() }
    Keys.onEscapePressed: closeRequested()

    function action(args) {
        if (busy) return
        actionError=''; actionResponded=false
        actionProcess.command=['@HOME@/.local/bin/desktop-control-action'].concat(args)
        actionProcess.running=true
    }
    function duration(seconds) { return Math.floor(Math.max(0,seconds)/60)+':'+String(Math.floor(Math.max(0,seconds)%60)).padStart(2,'0') }
    function age(timestamp) {
        const minutes=Math.max(0,Math.floor((now.getTime()/1000-timestamp)/60))
        return minutes<1?'teď':minutes<60?minutes+' min':minutes<1440?Math.floor(minutes/60)+' h':Math.floor(minutes/1440)+' d'
    }
    function notificationIcon(n) {
        const name=(n.desktop+' '+n.app).toLowerCase()
        for (const icon of ['discord','spotify','firefox','steam','kitty','thunar'])
            if(name.includes(icon)) return 'file://@HOME@/.local/share/icons/Colloid-Purple-Nord-Dark/apps/scalable/'+icon+'.svg'
        if(n.icon && (n.icon.startsWith('/') || n.icon.startsWith('file://'))) return n.icon.startsWith('/')?'file://'+n.icon:n.icon
        return Quickshell.iconPath(n.icon || n.desktop, 'preferences-system')
    }
    Process {
        id:actionProcess
        stdout:StdioCollector { onStreamFinished: {
            try { const result=JSON.parse(text); panel.actionResponded=true; if(!result.ok) panel.actionError=result.error || 'Změna se nezdařila.' }
            catch(e) { panel.actionError='Ovládání nevrátilo platnou odpověď.' }
        } }
        onExited: { if (!panel.actionResponded && !panel.actionError) panel.actionError='Akci se nepodařilo dokončit.'; panel.refreshRequested() }
    }
    Timer { interval:1000; repeat:true; running:panel.opened && !!panel.player?.isPlaying; onTriggered:panel.player.positionChanged() }
    component Caption: Text {
        color:Design.text; font.family:Design.font; font.pixelSize:13; font.weight:Font.Normal
        elide:Text.ElideRight; textFormat:Text.PlainText
    }
    component Icon: Image {
        property string name:''
        source:name?Qt.resolvedUrl('assets/'+name+'.svg'):''; sourceSize:Qt.size(48,48)
        width:20; height:20; fillMode:Image.PreserveAspectFit
    }
    component Surface: Rectangle {
        radius:Design.radiusMedium; color:Design.alpha(Design.surface,.94)
        border.width:1; border.color:Design.alpha(Design.border,.75)
    }
    component ActionButton: Controls.Button {
        id:button
        property string symbol:''
        property string description:text
        property bool selected:false
        implicitWidth:text ? content.implicitWidth+24 : 36; implicitHeight:36
        padding:8; hoverEnabled:true; focusPolicy:Qt.StrongFocus
        Accessible.name:description
        Controls.ToolTip.visible:hovered && description!==text
        Controls.ToolTip.text:description; Controls.ToolTip.delay:500
        background:Rectangle {
            radius:Design.radiusSmall
            color:button.down?Design.selection:button.selected?Design.alpha(Design.accent,.14):button.hovered?Design.alpha(Design.selection,.75):'transparent'
            border.width:1; border.color:button.activeFocus?Design.accent:button.selected?Design.alpha(Design.accent,.55):'transparent'
            Behavior on color { ColorAnimation { duration:Design.fast } }
        }
        contentItem:Item {
            implicitWidth:content.implicitWidth; implicitHeight:20; opacity:button.enabled?1:.35
            Row { id:content; anchors.centerIn:parent; spacing:8
                Icon { name:button.symbol; visible:button.symbol!==''; anchors.verticalCenter:parent.verticalCenter }
                Caption { text:button.text; visible:text!==''; anchors.verticalCenter:parent.verticalCenter; font.pixelSize:12 }
            }
        }
    }
    component Setting: Surface {
        id:setting
        property string title:''
        property string subtitle:''
        property string symbol:''
        property bool active:false
        property bool available:true
        property bool showDetails:false
        signal toggled()
        signal details()
        implicitHeight:76
        color:active?Design.alpha(Design.selection,.75):Design.alpha(Design.surface,.94)
        border.color:active?Design.alpha(Design.accent,.5):Design.alpha(Design.border,.75)
        Controls.Button {
            id:toggle; anchors.fill:parent; anchors.rightMargin:setting.showDetails?36:0
            enabled:setting.available && !panel.busy; hoverEnabled:true; focusPolicy:Qt.StrongFocus
            Accessible.name:setting.title+', '+setting.subtitle
            onClicked:setting.toggled()
            background:Rectangle { radius:Design.radiusMedium; color:toggle.hovered?Design.alpha(Design.accent,.08):'transparent'; border.width:toggle.activeFocus?1:0; border.color:Design.accent }
            contentItem:Item {
                opacity:toggle.enabled?1:.45
                Icon { x:10; anchors.verticalCenter:parent.verticalCenter; name:setting.symbol; width:22; height:22 }
                Column { x:42; anchors.verticalCenter:parent.verticalCenter; width:parent.width-48; spacing:5
                    Caption { width:parent.width; text:setting.title; font.pixelSize:12; font.weight:Font.Medium }
                    Caption { width:parent.width; text:setting.subtitle; font.pixelSize:10; color:setting.active?Design.blue:Design.muted }
                }
            }
        }
        ActionButton { anchors.right:parent.right; anchors.rightMargin:2; anchors.verticalCenter:parent.verticalCenter; width:32; symbol:'chevron'; visible:setting.showDetails; description:'Podrobnosti: '+setting.title; onClicked:setting.details() }
    }
    MouseArea { anchors.fill:parent }
    Rectangle {
        anchors.fill:parent; radius:Design.radiusLarge; color:Design.alpha(Design.bg,.94)
        border.width:1; border.color:Design.alpha(Design.accent,.32)
        Rectangle { anchors.fill:parent; anchors.margins:1; radius:Design.radiusLarge-1; color:'transparent'; border.width:1; border.color:Design.alpha(Design.blue,.05) }
    }
    Flickable {
        id:scroll; anchors.fill:parent; anchors.margins:16; contentWidth:width; contentHeight:body.implicitHeight
        clip:true; boundsBehavior:Flickable.StopAtBounds
        Controls.ScrollBar.vertical:Controls.ScrollBar { policy:Controls.ScrollBar.AsNeeded }
        Column {
            id:body; width:scroll.width; spacing:16
            RowLayout {
                width:parent.width; height:44; spacing:4
                Column { Layout.fillWidth:true; spacing:4
                    Caption { text:'Ovládací centrum'; font.pixelSize:16; font.weight:Font.Medium }
                    Caption { text:'roman'; font.pixelSize:11; color:Design.muted }
                }
                ActionButton { symbol:'lock'; description:'Zamknout'; onClicked:panel.command('@HOME@/.local/bin/desktop-lock',true) }
                ActionButton { symbol:'power'; description:'Napájení a relace'; onClicked:panel.command('@HOME@/.local/bin/desktop-power',true) }
                ActionButton { symbol:'close'; description:'Zavřít'; onClicked:panel.closeRequested() }
            }
            Surface {
                width:parent.width; height:errorLabel.implicitHeight+24; visible:panel.actionError!==''
                border.color:Design.alpha(Design.accent,.6)
                Caption { id:errorLabel; x:12; y:12; width:parent.width-24; text:panel.actionError; wrapMode:Text.Wrap; elide:Text.ElideNone; font.pixelSize:12 }
            }
            Surface {
                width:parent.width; height:audioColumn.implicitHeight+32
                Column {
                    id:audioColumn; x:16; y:16; width:parent.width-32; spacing:8
                    RowLayout { width:parent.width; height:28
                        Caption { text:'Zvuk'; font.weight:Font.Medium; Layout.fillWidth:true }
                        Caption { text:panel.status.audioAvailable?(panel.status.muted?'Ztlumeno':String(panel.status.volume)+' %'):'Nedostupný'; color:Design.muted; font.pixelSize:12 }
                    }
                    RowLayout { width:parent.width; spacing:8
                        ActionButton { symbol:panel.status.muted?'volume-off':'volume'; selected:!!panel.status.muted; description:'Ztlumit / zapnout zvuk'; enabled:!!panel.status.audioAvailable && !panel.busy; onClicked:panel.action(['mute']) }
                        Controls.Slider {
                            id:volumeSlider; Layout.fillWidth:true; implicitHeight:36; from:0; to:100; stepSize:1; focusPolicy:Qt.StrongFocus
                            enabled:!!panel.status.audioAvailable && !panel.busy
                            Accessible.name:'Hlasitost'; Accessible.description:'Hlasitost výstupu od 0 do 100 procent'
                            onMoved:if(!pressed)panel.action(['volume',String(Math.round(value))])
                            onPressedChanged:if(!pressed && enabled)panel.action(['volume',String(Math.round(value))])
                            Binding { target:volumeSlider; property:'value'; value:Math.min(100,panel.status.volume || 0); when:!volumeSlider.pressed && !panel.busy }
                            background:Rectangle {
                                x:volumeSlider.leftPadding; y:volumeSlider.topPadding+(volumeSlider.availableHeight-height)/2
                                width:volumeSlider.availableWidth; height:6; radius:3; color:Design.border
                                Rectangle { width:volumeSlider.visualPosition*parent.width; height:parent.height; radius:3; color:volumeSlider.enabled?Design.accent:Design.muted }
                            }
                            handle:Rectangle {
                                x:volumeSlider.leftPadding+volumeSlider.visualPosition*(volumeSlider.availableWidth-width)
                                y:volumeSlider.topPadding+(volumeSlider.availableHeight-height)/2
                                width:16; height:16; radius:8; color:Design.text
                                border.width:volumeSlider.activeFocus?3:1; border.color:Design.accent
                            }
                        }
                    }
                    Controls.Button {
                        id:outputToggle; width:parent.width; height:36; hoverEnabled:true; focusPolicy:Qt.StrongFocus
                        enabled:!!panel.status.outputs?.length
                        Accessible.name:'Vybrat zvukový výstup: '+(panel.status.outputName || 'Nedostupný')
                        onClicked:panel.outputsExpanded=!panel.outputsExpanded
                        background:Rectangle { radius:8; color:outputToggle.hovered?Design.selection:'transparent'; border.width:outputToggle.activeFocus?1:0; border.color:Design.accent }
                        contentItem:Item {
                            Caption { anchors.left:parent.left; anchors.leftMargin:8; anchors.verticalCenter:parent.verticalCenter; width:parent.width-40; text:panel.status.outputName || 'Žádný zvukový výstup'; font.pixelSize:12; color:Design.muted }
                            Icon { anchors.right:parent.right; anchors.rightMargin:8; anchors.verticalCenter:parent.verticalCenter; name:'chevron'; rotation:panel.outputsExpanded?90:0; width:16; height:16 }
                        }
                    }
                    Column {
                        width:parent.width; spacing:4; visible:panel.outputsExpanded
                        Repeater {
                            model:panel.status.outputs || []
                            delegate:Controls.Button {
                                id:deviceButton; required property var modelData
                                width:audioColumn.width; height:40; enabled:!panel.busy; hoverEnabled:true; focusPolicy:Qt.StrongFocus
                                Accessible.name:modelData.description+(modelData.active?', výchozí':'')
                                onClicked:panel.action(['output',String(modelData.id),String(modelData.serial)])
                                background:Rectangle { radius:8; color:deviceButton.modelData.active || deviceButton.hovered?Design.selection:'transparent'; border.width:1; border.color:deviceButton.activeFocus?Design.accent:deviceButton.modelData.active?Design.alpha(Design.accent,.5):'transparent' }
                                contentItem:Caption { text:(deviceButton.modelData.active?'✓  ':'')+deviceButton.modelData.description; font.pixelSize:12; verticalAlignment:Text.AlignVCenter; leftPadding:8 }
                            }
                        }
                    }
                    RowLayout { width:parent.width; spacing:4
                        ActionButton { symbol:panel.status.micMuted?'mic-off':'mic'; text:panel.status.micMuted?'Mikrofon vypnutý':'Mikrofon'; description:'Ztlumit / zapnout mikrofon'; selected:!!panel.status.micMuted; enabled:!!panel.status.micAvailable && !panel.busy; onClicked:panel.action(['mic-mute']) }
                        Item { Layout.fillWidth:true }
                        ActionButton { text:'Mixér'; symbol:'gear'; onClicked:panel.command('pavucontrol',true) }
                    }
                }
            }
            GridLayout {
                width:parent.width; columns:2; columnSpacing:8; rowSpacing:8
                Setting {
                    Layout.fillWidth:true; title:'Wi-Fi'; symbol:'wifi'; active:!!panel.status.wifi; available:!!panel.status.wifiAvailable; showDetails:true
                    subtitle:!available?'Bez adaptéru':panel.status.wifiConnected?panel.status.wifiName:active?'Nepřipojeno':'Vypnuto'
                    onToggled:panel.action(['wifi',active?'off':'on']); onDetails:panel.command('nm-connection-editor',true)
                }
                Setting {
                    Layout.fillWidth:true; title:'Bluetooth'; symbol:'bluetooth'; active:!!panel.status.bluetooth; available:!!panel.status.bluetoothAvailable; showDetails:true
                    subtitle:!available?'Bez adaptéru':active?'Zapnuto':'Vypnuto'
                    onToggled:panel.action(['bluetooth',active?'off':'on']); onDetails:panel.command('blueman-manager',true)
                }
                Setting {
                    Layout.fillWidth:true; title:'Noční světlo'; symbol:'moon'; active:!!panel.status.night; subtitle:active?'Zapnuto':'Vypnuto'
                    onToggled:panel.action(['night',active?'off':'on'])
                }
                Setting {
                    Layout.fillWidth:true; title:'Nerušit'; symbol:'bell'; active:!!panel.status.dnd; subtitle:active?'Zapnuto':'Vypnuto'
                    onToggled:panel.action(['dnd'])
                }
            }
            Surface {
                width:parent.width; height:panel.hasTrack?136:52
                RowLayout { anchors.fill:parent; anchors.margins:8; visible:!panel.hasTrack
                    Icon { name:'music'; Layout.leftMargin:8 }
                    Caption { text:'Nic se nepřehrává'; color:Design.muted; font.pixelSize:12; Layout.fillWidth:true }
                    ActionButton { text:'Spotify'; description:'Otevřít Spotify'; onClicked:panel.command('gtk-launch com.spotify.Client',true) }
                }
                Column {
                    x:16; y:16; width:parent.width-32; spacing:8; visible:panel.hasTrack
                    RowLayout { width:parent.width; spacing:12
                        ClippingRectangle {
                            Layout.preferredWidth:48; Layout.preferredHeight:48; radius:8; color:Design.selection
                            Icon { anchors.centerIn:parent; name:'music'; visible:art.status!==Image.Ready }
                            Image { id:art; anchors.fill:parent; source:panel.player?.trackArtUrl || ''; asynchronous:true; fillMode:Image.PreserveAspectCrop }
                        }
                        Column { Layout.fillWidth:true; spacing:5
                            Caption { width:parent.width; text:panel.player?.trackTitle || ''; font.weight:Font.Medium }
                            Caption { width:parent.width; text:panel.player?.trackArtist || panel.player?.identity || ''; font.pixelSize:11; color:Design.muted }
                        }
                    }
                    RowLayout { width:parent.width; spacing:4
                        Caption { text:panel.duration(panel.player?.position || 0)+' / '+panel.duration(panel.player?.length || 0); color:Design.muted; font.pixelSize:10; Layout.fillWidth:true }
                        ActionButton { symbol:'previous'; description:'Předchozí skladba'; enabled:!!panel.player?.canGoPrevious; onClicked:panel.player.previous() }
                        ActionButton { symbol:panel.player?.isPlaying?'pause':'play'; description:'Přehrát / pozastavit'; selected:true; enabled:!!panel.player?.canTogglePlaying; onClicked:panel.player.togglePlaying() }
                        ActionButton { symbol:'next'; description:'Další skladba'; enabled:!!panel.player?.canGoNext; onClicked:panel.player.next() }
                    }
                    Rectangle {
                        width:parent.width; height:3; radius:2; color:Design.border
                        Rectangle { width:parent.width*(panel.player?.length>0?Math.max(0,Math.min(1,panel.player.position/panel.player.length)):0); height:3; radius:2; color:Design.accent }
                    }
                }
            }
            Surface {
                width:parent.width; height:notificationColumn.implicitHeight+24
                Column {
                    id:notificationColumn; x:12; y:12; width:parent.width-24; spacing:8
                    RowLayout { width:parent.width; height:36
                        Caption { text:'Oznámení'; font.weight:Font.Medium; Layout.fillWidth:true }
                        Caption { text:String(panel.status.notifications || 0); color:Design.muted; font.pixelSize:12 }
                        ActionButton { text:'Vymazat vše'; enabled:!!panel.status.notifications && !panel.busy; onClicked:panel.action(['clear']) }
                    }
                    ListView {
                        id:notificationList; width:parent.width; height:count?Math.min(contentHeight,296):100; spacing:8; clip:true
                        boundsBehavior:Flickable.StopAtBounds; model:panel.notifications
                        Controls.ScrollBar.vertical:Controls.ScrollBar { policy:Controls.ScrollBar.AsNeeded }
                        delegate:Surface {
                            id:notice; required property var modelData; width:notificationList.width; height:84; radius:12
                            Controls.Button {
                                id:openNotice; anchors.fill:parent; anchors.rightMargin:34; hoverEnabled:true; focusPolicy:Qt.StrongFocus
                                Accessible.name:notice.modelData.app+': '+notice.modelData.summary+'. Otevřít historii a akce.'
                                onClicked:panel.command('swaync-client --open-panel -sw',true)
                                background:Rectangle { radius:12; color:openNotice.hovered?Design.alpha(Design.selection,.6):'transparent'; border.width:openNotice.activeFocus?1:0; border.color:Design.accent }
                                contentItem:Item {
                                    Image { x:6; y:10; width:28; height:28; source:panel.notificationIcon(notice.modelData); sourceSize:Qt.size(56,56); fillMode:Image.PreserveAspectFit }
                                    Column { x:44; y:7; width:parent.width-50; spacing:5
                                        RowLayout { width:parent.width
                                            Caption { text:notice.modelData.app; color:Design.muted; font.pixelSize:10; Layout.fillWidth:true }
                                            Caption { text:panel.age(notice.modelData.timestamp); color:Design.muted; font.pixelSize:10 }
                                        }
                                        Caption { width:parent.width; text:notice.modelData.summary; font.pixelSize:12; font.weight:Font.Medium }
                                        Caption { width:parent.width; text:notice.modelData.body || ''; font.pixelSize:11; color:Design.muted }
                                    }
                                }
                            }
                            ActionButton { anchors.right:parent.right; anchors.rightMargin:2; anchors.top:parent.top; anchors.topMargin:4; width:30; symbol:'close'; description:'Zavřít oznámení'; enabled:!panel.busy; onClicked:panel.action(['dismiss',String(notice.modelData.id)]) }
                        }
                        Column { anchors.centerIn:parent; width:parent.width; spacing:10; visible:notificationList.count===0
                            Icon { anchors.horizontalCenter:parent.horizontalCenter; name:'bell'; opacity:.5 }
                            Caption { width:parent.width; horizontalAlignment:Text.AlignHCenter; text:panel.status.notifications?'Starší oznámení najdeš v historii.':'Všechno vyřízeno'; color:Design.muted; font.pixelSize:12 }
                        }
                    }
                    ActionButton { width:parent.width; text:'Úplná historie'; symbol:'chevron'; onClicked:panel.command('swaync-client --open-panel -sw',true) }
                }
            }
            Controls.Button {
                id:weatherButton; width:parent.width; height:28; hoverEnabled:true; focusPolicy:Qt.StrongFocus
                Accessible.name:'Počasí Brno'; onClicked:panel.command('xdg-open https://www.meteoblue.com/en/weather/week/brno_czechia_3078610',true)
                background:Rectangle { radius:8; color:weatherButton.hovered?Design.selection:'transparent'; border.width:weatherButton.activeFocus?1:0; border.color:Design.accent }
                contentItem:RowLayout { spacing:8
                    Icon { name:panel.weather.icon==='moon'?'weather-night':panel.weather.icon || 'weather'; Layout.preferredWidth:18; Layout.preferredHeight:18; opacity:.75 }
                    Caption { text:panel.weather.available?'Brno · '+panel.weather.temperature+' °C'+(panel.weather.stale?' · starší údaj':''):'Brno · počasí nedostupné'; color:Design.muted; font.pixelSize:10; Layout.fillWidth:true }
                    Caption { text:'Open-Meteo'; color:Design.muted; font.pixelSize:9; opacity:.7 }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "."

ShellRoot {
    id: root
    property string view: ""
    // Nabídka přes Super i ostatní překryvné panely mají před dockem přednost.
    onViewChanged: dockVisibilitySync.restart()
    Component.onCompleted: dockVisibilitySync.restart()
    Timer {
        id: dockVisibilitySync
        interval: 30
        onTriggered: Quickshell.execDetached([
            Quickshell.env('HOME') + '/.local/bin/desktop-dock', 'overlay', root.view
        ])
    }
    property var targetScreen: Quickshell.screens.find(s => s.name === "@PRIMARY_MONITOR@") || Quickshell.screens[0]
    property string query: ""
    property string category: "All Apps"
    property date now: new Date()
    property var status: ({wifi:false,bluetooth:false,caffeine:false,night:false,dnd:false,uptime:"",notifications:0})
    property var notificationItems: []
    property var weather: ({available:false})
    property var player: Mpris.players.values.find(p => p.isPlaying) || Mpris.players.values.find(p => !!p.trackTitle) || Mpris.players.values[0] || null
    property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay && (a.name + ' ' + a.genericName + ' ' + a.comment).toLowerCase().includes(query.toLowerCase()) && (category === 'All Apps' || (category === 'Favorites' ? /firefox|kitty|steam|discord|spotify|thunar|sober|code/i.test(a.id) : appCategory(a) === category))).sort((a,b)=>appRank(a)-appRank(b) || a.name.localeCompare(b.name))
    function appRank(a) {
        const order=['code','firefox','com.spotify.Client','kitty','thunar','discord','steam','org.vinegarhq.Sober']
        const i=order.findIndex(id=>a.id.toLowerCase().replace(/\.desktop$/,'')===id.toLowerCase())
        return i<0 ? 100 : i
    }
    function appCategory(a) {
        const cats = a.categories || []
        if (cats.includes('Development')) return 'Development'
        if (cats.includes('Network')) return 'Internet'
        if (cats.includes('AudioVideo') || cats.includes('Audio') || cats.includes('Video')) return 'Multimedia'
        if (cats.includes('Office')) return 'Office'
        if (cats.includes('Settings')) return 'Settings'
        return 'System'
    }
    function appIcon(a) {
        const id = a.id.toLowerCase()
        const names = [['firefox','firefox'],['discord','discord'],['spotify','spotify'],['steam','steam'],['kitty','kitty'],['thunar','thunar'],['code','code']]
        for (const n of names) if (id.includes(n[0])) return Quickshell.iconPath(n[1], 'application-x-executable')
        return Quickshell.iconPath(a.icon, 'application-x-executable')
    }
    function toggle(name) {
        switcher.cancel()
        // Tapety spravuje samostatný Waypaper; panel už nevytváří vlastní galerii.
        if (name === "wallpapers") {
            view = ''
            Quickshell.execDetached(['@HOME@/.local/bin/waypaper'])
            return
        }
        targetScreen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens.find(s => s.name === "@PRIMARY_MONITOR@") || Quickshell.screens[0]
        view = view === name ? '' : name
        if (view) stateProcess.running = true
        if (view === "control") weatherProcess.running = true
    }
    function run(cmd, close = true) { Quickshell.execDetached(['bash','-lc',cmd]); if (close) view = ''; else refresh.restart() }
    Timer { interval:1000; running:true; repeat:true; onTriggered:root.now=new Date() }
    Timer { interval:root.view==='control'?2000:5000; running:root.view!==''; repeat:true; onTriggered:stateProcess.running=true }
    Timer { id:refresh; interval:350; onTriggered:stateProcess.running=true }
    Process { id:stateProcess; command:['@HOME@/.local/bin/desktop-panel-state']; stdout:StdioCollector { onStreamFinished: { try { root.status=JSON.parse(text) } catch(e) {} } } }
    Process {
        id:notificationFeed; command:['@HOME@/.local/bin/desktop-notification-feed']; running:true
        stdout:SplitParser { onRead:data=> { try { root.notificationItems=JSON.parse(data).items } catch(e) {} } }
        onExited:notificationReconnect.restart()
    }
    Timer { id:notificationReconnect; interval:3000; onTriggered:notificationFeed.running=true }
    Process { id:weatherProcess; command:['@HOME@/.local/bin/desktop-weather']; stdout:StdioCollector { onStreamFinished: { try { root.weather=JSON.parse(text) } catch(e) {} } } }
    Timer { interval:900000; running:root.view==='control'; repeat:true; onTriggered:weatherProcess.running=true }
    IpcHandler { target:'desktop'
        function updateSwitch(session: int, offset: int, epoch: string, revision: int, commit: bool) { switcher.updateSession(session, offset, epoch, revision, commit) }
        function switchNext() { switcher.step(1) }
        function switchPrevious() { switcher.step(-1) }
        function finishSwitch() { switcher.finish() }
        function cancelSwitch() { switcher.cancel() }
        function closeSwitchSelected() { switcher.closeWindow(switcher.selected) }
        function switchStatus(): string { return switcher.status() }
        function toggleLauncher() { root.toggle('launcher') }
        function toggleDashboard() { root.toggle('dashboard') }
        function toggleControl() { root.toggle('control') }
        function toggleWallpapers() { root.toggle('wallpapers') }
        function closeAll() { switcher.cancel(); root.view='' }
        function toggleDock() { Quickshell.execDetached([Quickshell.env('HOME') + '/.local/bin/desktop-dock', 'toggle']) }
    }
    WindowSwitcher {
        id: switcher
        shell: root
    }
    component Label: Text {
        color:Design.text; font.family:Design.font; font.pixelSize:14; font.weight:Font.Normal
        renderType:Text.NativeRendering; elide:Text.ElideRight
    }
    component Glass: ClippingRectangle {
        radius:Design.radiusLarge; color:Design.alpha(Design.bg,0.92)
        border.width:1; border.color:Design.alpha(Design.accent,0.27)
    }
    component Card: ClippingRectangle {
        radius:Design.radiusMedium; color:Design.alpha(Design.surface,0.9)
        border.width:1; border.color:Design.alpha(Design.border,0.75)
    }
    component Button: Rectangle {
        id:btn
        property string text:''
        property bool selected:false
        property bool flat:false
        property string glyph:''
        signal clicked()
        implicitWidth:Math.max(36,buttonLabel.implicitWidth+32); implicitHeight:36; Layout.fillWidth:false; Layout.fillHeight:false
        radius:Design.radiusSmall
        color:selected ? Design.selection : buttonMouse.containsMouse ? Design.alpha(Design.selection,0.7) : flat ? 'transparent' : Design.alpha(Design.surface,0.6)
        border.width:1; border.color:selected ? Design.alpha(Design.accent,0.8) : flat ? 'transparent' : Design.alpha(Design.border,0.7)
        Behavior on color { ColorAnimation { duration:Design.fast } }
        Label { id:buttonLabel; anchors.centerIn:parent; text:btn.text; font.pixelSize:12; font.family:btn.text.length<3 ? Design.mono : Design.font; color:btn.enabled ? Design.text : Design.muted }
        MouseArea { id:buttonMouse; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:btn.clicked() }
    }
    component Avatar: Rectangle {
        implicitWidth:64; implicitHeight:64; width:64; height:64; Layout.fillWidth:false; Layout.fillHeight:false; radius:width/2; color:Design.selection
        border.width:1; border.color:Design.alpha(Design.accent,0.8)
        Label { anchors.centerIn:parent; text:'R'; font.pixelSize:parent.width*.36; font.weight:Font.Light }
    }
    component Media: Card {
        id:media
        Image { id:cover; x:16; y:16; width:Math.min(media.height-32,112); height:width; source:root.player?.trackArtUrl || ''; fillMode:Image.PreserveAspectCrop; visible:source!='' }
        Card { x:cover.x; y:cover.y; width:cover.width; height:cover.height; visible:!cover.visible; Label { anchors.centerIn:parent; text:'♫'; color:Design.muted; font.pixelSize:32 } }
        Column {
            x:cover.x+cover.width+16; y:20; width:parent.width-x-16; spacing:8
            Label { width:parent.width; text:root.player?.trackTitle || 'Nothing playing'; font.weight:Font.Medium; font.pixelSize:15 }
            Label { width:parent.width; text:root.player?.trackArtist || 'Your music, when you are ready'; color:Design.muted; font.pixelSize:12 }
            Rectangle { width:parent.width; height:3; radius:2; color:Design.border
                Rectangle { height:3; radius:2; color:Design.accent; width:parent.width*(root.player?.length>0 ? Math.min(1,root.player.position/root.player.length) : 0) }
            }
            Row { spacing:8
                Button { text:'‹'; onClicked:root.player?.previous() }
                Button { text:root.player?.isPlaying ? 'Ⅱ' : '▷'; selected:root.player?.isPlaying || false; onClicked:root.player?.togglePlaying() }
                Button { text:'›'; onClicked:root.player?.next() }
            }
        }
    }
    component Toggle: Card {
        id:tile
        property string title:''
        property string symbol:''
        property bool active:false
        property string subtitle:''
        signal clicked()
        color:active ? Design.alpha(Design.selection,0.88) : tileMouse.containsMouse ? Design.alpha(Design.selection,0.45) : Design.alpha(Design.surface,0.88)
        border.color:active ? Design.alpha(Design.accent,0.65) : Design.border
        Behavior on color { ColorAnimation { duration:Design.fast } }
        Label { x:16; anchors.verticalCenter:parent.verticalCenter; text:tile.symbol; color:tile.active ? Design.accent : Design.muted; font.family:Design.mono; font.pixelSize:21 }
        Column { x:52; anchors.verticalCenter:parent.verticalCenter; width:parent.width-x-8; spacing:4
            Label { text:tile.title; width:parent.width; font.pixelSize:12; font.weight:Font.Medium }
            Label { text:tile.subtitle; width:parent.width; visible:text!=''; font.pixelSize:10; color:Design.muted }
        }
        MouseArea { id:tileMouse; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:tile.clicked() }
    }
    component Overlay: PanelWindow {
        id:overlay
        property string name:''
        property bool opened:root.view===name
        property real progress:opened ? 1 : 0
        Behavior on progress { NumberAnimation { duration:Design.normal; easing.type:Easing.OutCubic } }
        visible:opened || progress>0.001
        screen:root.targetScreen
        anchors { top:true; bottom:true; left:true; right:true }
        color:'transparent'; focusable:true; exclusionMode:ExclusionMode.Ignore
        WlrLayershell.namespace:'desktop-'+name
        WlrLayershell.keyboardFocus:opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        Rectangle { anchors.fill:parent; color:'#10000000'; opacity:overlay.progress; MouseArea { anchors.fill:parent; onClicked:root.view='' } }
        Item { focus:true; Keys.onEscapePressed:root.view='' }
    }

    Overlay {
        id:launcher; name:'launcher'
        onOpenedChanged: if (opened) { search.text=''; root.query=''; search.forceActiveFocus(); appList.currentIndex=0 }
        Glass {
            width:Math.min(parent.width-96,1280); height:Math.min(parent.height-120,820)
            anchors.centerIn:parent; anchors.verticalCenterOffset:Math.round(10*(1-launcher.progress)); opacity:launcher.progress
            ColumnLayout {
                anchors.fill:parent; anchors.margins:Design.large; spacing:Design.medium
                Card {
                    Layout.fillWidth:true; Layout.preferredHeight:60
                    Label { x:20; anchors.verticalCenter:parent.verticalCenter; text:'⌕'; font.pixelSize:26; color:Design.muted }
                    TextInput {
                        id:search; anchors.fill:parent; anchors.leftMargin:62; anchors.rightMargin:96
                        verticalAlignment:TextInput.AlignVCenter; renderType:Text.NativeRendering; font.family:Design.font; font.pixelSize:16; color:Design.text
                        selectByMouse:true; clip:true; onTextChanged: { root.query=text; appList.currentIndex=0 }
                        Keys.onEscapePressed:root.view=''
                        Keys.onDownPressed:appList.incrementCurrentIndex()
                        Keys.onUpPressed:appList.decrementCurrentIndex()
                        Keys.onReturnPressed: if (root.apps[appList.currentIndex]) { root.apps[appList.currentIndex].execute(); root.view='' }
                        Label { anchors.verticalCenter:parent.verticalCenter; visible:search.text===''; text:'Search applications…'; color:Design.muted; font.pixelSize:16 }
                    }
                    Label { anchors.right:parent.right; anchors.rightMargin:20; anchors.verticalCenter:parent.verticalCenter; text:'Ctrl  K'; font.pixelSize:11; color:Design.muted }
                }
                RowLayout {
                    Layout.fillWidth:true; Layout.fillHeight:true; spacing:Design.large
                    ColumnLayout {
                        Layout.preferredWidth:240; Layout.maximumWidth:240; Layout.minimumWidth:240; Layout.fillHeight:true; spacing:Design.small
                        Card {
                            Layout.fillWidth:true; Layout.fillHeight:true
                            Column {
                                anchors.fill:parent; anchors.margins:Design.small; spacing:4
                                Repeater {
                                    model:['All Apps','Favorites','Development','Internet','Multimedia','Office','System','Settings']
                                    delegate:Button {
                                        flat:true
                                        required property string modelData; required property int index
                                        width:parent.width; height:48; text:''; selected:root.category===modelData
                                        Label { x:14; anchors.verticalCenter:parent.verticalCenter; text:['󰀻','♡','⌘','◎','♫','▤','⚙','☷'][index]; font.family:Design.mono; font.pixelSize:19; color:parent.selected ? Design.accent : Design.muted }
                                        Label { x:50; anchors.verticalCenter:parent.verticalCenter; text:modelData; font.pixelSize:13 }
                                        onClicked: { root.category=modelData; appList.currentIndex=0 }
                                    }
                                }
                            }
                        }
                        RowLayout { Layout.fillWidth:true; Layout.preferredHeight:56; spacing:12
                            Avatar { Layout.preferredWidth:48; Layout.preferredHeight:48 }
                            Column { spacing:5; Label { text:'roman'; font.weight:Font.Medium } Label { text:'Good evening'; color:Design.muted; font.pixelSize:12 } }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth:true; Layout.fillHeight:true; spacing:Design.small
                        ListView {
                            id:appList; Layout.fillWidth:true; Layout.fillHeight:true
                            model:root.apps; clip:true; spacing:4; currentIndex:0; boundsBehavior:Flickable.StopAtBounds
                            delegate:Rectangle {
                                id:appRow; required property var modelData; required property int index
                                width:ListView.view.width; height:68; radius:Design.radiusMedium
                                color:appRow.ListView.isCurrentItem ? Design.alpha(Design.selection,.65) : appHit.containsMouse ? Design.alpha(Design.surface,.9) : 'transparent'
                                border.width:1; border.color:appRow.ListView.isCurrentItem ? Design.alpha(Design.blue,.9) : 'transparent'
                                Behavior on color { ColorAnimation { duration:Design.fast } }
                                Image { x:16; anchors.verticalCenter:parent.verticalCenter; width:38; height:38; source:root.appIcon(modelData); sourceSize:Qt.size(Math.round(38*(root.targetScreen?.devicePixelRatio || 1)),Math.round(38*(root.targetScreen?.devicePixelRatio || 1))); fillMode:Image.PreserveAspectFit }
                                Column { x:72; anchors.verticalCenter:parent.verticalCenter; width:parent.width-230; spacing:6
                                    Label { text:modelData.name; width:parent.width; font.weight:Font.Medium }
                                    Label { text:modelData.comment || modelData.genericName || 'Application'; width:parent.width; color:Design.muted; font.pixelSize:11 }
                                }
                                Rectangle { anchors.right:parent.right; anchors.rightMargin:52; anchors.verticalCenter:parent.verticalCenter; width:96; height:26; radius:13; color:Design.alpha(Design.selection,.8)
                                    Label { anchors.centerIn:parent; text:root.appCategory(modelData); font.pixelSize:10; color:Design.muted }
                                }
                                Label { anchors.right:parent.right; anchors.rightMargin:16; anchors.verticalCenter:parent.verticalCenter; text:'#'+(index+1); color:Design.muted; font.pixelSize:11 }
                                MouseArea { id:appHit; anchors.fill:parent; hoverEnabled:true; onPositionChanged:appList.currentIndex=index; onClicked: { modelData.execute(); root.view='' } }
                            }
                            Label { anchors.centerIn:parent; visible:appList.count===0; text:'No matching applications'; color:Design.muted }
                        }
                        RowLayout { Layout.fillWidth:true; Layout.preferredHeight:42
                            Label { text:'↑ ↓ Navigate   ↵ Open   Esc Close'; font.pixelSize:11; color:Design.muted }
                            Item { Layout.fillWidth:true }
                            Button { text:'⚙'; onClicked:root.toggle('control') }
                        }
                    }
                }
            }
        }
    }

    Overlay {
        id:dashboard; name:'dashboard'
        Glass {
            width:Math.min(parent.width-96,1040); height:Math.min(parent.height-130,600)
            anchors.centerIn:parent; anchors.verticalCenterOffset:Math.round(10*(1-dashboard.progress)); opacity:dashboard.progress
            ColumnLayout {
                anchors.fill:parent; anchors.margins:Design.large; spacing:Design.medium
                RowLayout { Layout.fillWidth:true; Layout.preferredHeight:28
                    Repeater { model:['#ff6058','#febc2e','#28c840']; delegate:Rectangle { required property string modelData; width:11; height:11; radius:6; color:modelData } }
                    Label { text:'Home'; font.pixelSize:13; color:Design.muted; leftPadding:16 }
                    Item { Layout.fillWidth:true }
                    Button { text:'⌕'; onClicked:root.toggle('launcher') }
                    Button { text:'−'; onClicked:root.view='' }
                    Button { text:'×'; onClicked:root.view='' }
                }
                RowLayout {
                    Layout.fillWidth:true; Layout.fillHeight:true; spacing:Design.medium
                    ColumnLayout { Layout.preferredWidth:52; Layout.maximumWidth:52; Layout.minimumWidth:52; Layout.fillHeight:true; spacing:Design.medium
                        Repeater { model:[['⌂','home'],['▦','wallpapers'],['󰍹','control'],['󰊴','gaming'],['󰉋','files'],['♫','music'],['⚙','settings']]
                            delegate:Button { flat:true; required property var modelData; Layout.fillWidth:true; implicitHeight:44; text:modelData[0]; selected:modelData[1]==='home'; onClicked: { const a=modelData[1]; if(a==='wallpapers'||a==='control') root.toggle(a); else if(a==='gaming') root.run('steam'); else if(a==='files') root.run('thunar'); else if(a==='music') root.run('gtk-launch com.spotify.Client'); else if(a==='settings') root.run('desktop-theme') } }
                        }
                        Item { Layout.fillHeight:true }
                    }
                    ColumnLayout {
                        Layout.fillWidth:true; Layout.fillHeight:true; spacing:Design.medium
                        Card {
                            Layout.fillWidth:true; Layout.preferredHeight:190; Layout.minimumHeight:190; Layout.maximumHeight:190
                            Image { anchors.fill:parent; anchors.margins:1; source:'file://@HOME@/.local/share/wallpapers/moonlit-lake.png'; fillMode:Image.PreserveAspectCrop; opacity:.16 }
                            Row { anchors.fill:parent; anchors.margins:Design.large; spacing:Design.large
                                Avatar { width:112; height:112; anchors.verticalCenter:parent.verticalCenter }
                                Column { anchors.verticalCenter:parent.verticalCenter; spacing:8
                                    Label { text:'roman'; font.pixelSize:24; font.weight:Font.Medium }
                                    Label { text:'@roman'; color:Design.accent; font.pixelSize:13 }
                                    Label { text:'Uptime  '+(root.status.uptime || '…'); color:Design.muted; font.family:Design.mono; font.pixelSize:12 }
                                    Label { text:'Arch Linux  ·  Hyprland'; color:Design.muted; font.family:Design.mono; font.pixelSize:12 }
                                    Label { text:'NVIDIA RTX 4060 Ti'; color:Design.muted; font.family:Design.mono; font.pixelSize:11 }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth:true; Layout.fillHeight:true; spacing:Design.medium
                            Media { Layout.fillWidth:true; Layout.fillHeight:true; Layout.minimumWidth:400; Layout.minimumHeight:170 }
                            GridLayout { columns:2; rowSpacing:Design.small; columnSpacing:Design.small; Layout.preferredWidth:300; Layout.minimumWidth:300; Layout.maximumWidth:300; Layout.fillHeight:true
                                Toggle { Layout.fillWidth:true; Layout.fillHeight:true; title:'Wi-Fi'; symbol:'󰤨'; active:root.status.wifi; subtitle:root.status.wifi ? 'Enabled' : 'Off'; onClicked:root.run('nm-connection-editor') }
                                Toggle { Layout.fillWidth:true; Layout.fillHeight:true; title:'Bluetooth'; symbol:''; active:root.status.bluetooth; subtitle:active ? 'On' : 'Off'; onClicked:root.run('blueman-manager') }
                                Toggle { Layout.fillWidth:true; Layout.fillHeight:true; title:'Caffeine'; symbol:'󰅶'; active:root.status.caffeine; onClicked:root.run('if systemctl --user is-active --quiet hypridle; then systemctl --user stop hypridle; else systemctl --user start hypridle; fi',false) }
                                Toggle { Layout.fillWidth:true; Layout.fillHeight:true; title:'Night light'; symbol:'󰖔'; active:root.status.night; onClicked:root.run('if systemctl --user is-active --quiet desktop-nightlight; then systemctl --user stop desktop-nightlight; else systemctl --user start desktop-nightlight; fi',false) }
                            }
                        }
                        RowLayout { Layout.fillWidth:true; Layout.preferredHeight:94; Layout.minimumHeight:94; Layout.maximumHeight:94; spacing:Design.medium
                            Card { Layout.fillWidth:true; Layout.fillHeight:true
                                RowLayout { anchors.fill:parent; anchors.margins:Design.medium; spacing:Design.large
                                    Label { text:Qt.formatTime(root.now,'HH:mm'); font.pixelSize:36; font.weight:Font.Light; color:Design.accent }
                                    Column { spacing:8; Label { text:Qt.formatDate(root.now,'dddd, d MMMM yyyy'); font.pixelSize:12 } Label { text:'Your quiet corner of the night'; color:Design.muted; font.pixelSize:11 } }
                                }
                            }
                            Card { Layout.preferredWidth:300; Layout.minimumWidth:300; Layout.maximumWidth:300; Layout.fillHeight:true
                                RowLayout { anchors.centerIn:parent; spacing:16
                                    Button { text:'Palettes'; onClicked:root.run('desktop-theme') }
                                    Button { text:'⏻  Power'; onClicked:root.run('desktop-power') }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Overlay {
        id:control; name:'control'
        ControlCenter {
            width:Math.min(420,parent.width-32); height:Math.min(implicitHeight,parent.height-80)
            anchors.right:parent.right; anchors.rightMargin:16; anchors.top:parent.top; anchors.topMargin:64
            opacity:control.progress; transform:Translate { x:(1-control.progress)*120 }
            status:root.status; player:root.player; now:root.now; opened:control.opened
            notifications:root.notificationItems; weather:root.weather
            onRefreshRequested:refresh.restart()
            onCommand:(command, closePanel)=>root.run(command,closePanel)
            onCloseRequested:root.view=''
        }
    }

}

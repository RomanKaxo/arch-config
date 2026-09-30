import QtQuick 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id:root
    width:1920; height:1080; color:'#090a10'
    property int sessionIndex:Math.max(0,sessionModel.lastIndex)
    property real uiScale:Math.min(width/1920,height/1080)
    Repeater { id:sessionEntries; model:sessionModel; delegate:Item { property string sessionName:model.name } }
    property color primary:'#e6e7ef'
    property color secondary:'#959bae'
    property color accent:'#9283bd'
    property bool ready:false
    property string selectedLayout:keyboard.layouts.length ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : 'CZ'
    component Caption: Text { color:root.primary; font.family:'Inter Variable'; font.pixelSize:14; renderType:Text.NativeRendering }
    Background { anchors.fill:parent; source:config.background; fillMode:Image.PreserveAspectCrop }
    Rectangle { anchors.fill:parent; color:'#30070910' }
    Timer { id:clock; property date date:new Date(); interval:1000; running:true; repeat:true; onTriggered:date=new Date() }
    TextConstants { id:tc }
    Connections { target:sddm; function onLoginFailed() { password.text=''; error.text=tc.loginFailed; password.forceActiveFocus() } }
    Caption { x:48; y:38; text:'H Y P R L A N D'; font.pixelSize:14; font.letterSpacing:2 }
    Caption { x:48; y:66; text:'T I L E   Y O U R   W O R L D'; color:root.secondary; font.pixelSize:9 }
    Caption { anchors.right:parent.right; anchors.rightMargin:48; y:42; text:'A calmer system. A clearer mind.'; color:root.secondary; font.pixelSize:11 }
    Column { anchors.horizontalCenter:parent.horizontalCenter; y:parent.height*.10; spacing:8; opacity:root.ready?1:0
        Behavior on opacity { NumberAnimation { duration:280 } }
        Caption { anchors.horizontalCenter:parent.horizontalCenter; text:Qt.formatTime(clock.date,'HH:mm'); font.pixelSize:96*root.uiScale; font.weight:Font.Light; font.letterSpacing:2 }
        Caption { anchors.horizontalCenter:parent.horizontalCenter; text:Qt.formatDate(clock.date,'ddd, d MMMM yyyy').toUpperCase(); color:root.secondary; font.pixelSize:13; font.letterSpacing:2 }
    }
    Rectangle {
        id:card; width:540; height:472; anchors.centerIn:parent; anchors.verticalCenterOffset:50
        radius:24; color:'#dc0c0d16'; border.width:1; border.color:'#48303245'
        opacity:root.ready?1:0; scale:(root.ready?1:.98)*root.uiScale
        Behavior on opacity { NumberAnimation { duration:240; easing.type:Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration:240; easing.type:Easing.OutCubic } }
        Rectangle { y:36; anchors.horizontalCenter:parent.horizontalCenter; width:112; height:112; radius:56; color:'#202239'; border.width:1; border.color:root.accent
            Caption { anchors.centerIn:parent; text:'R'; font.pixelSize:42; font.weight:Font.Light }
        }
        Caption { y:168; anchors.horizontalCenter:parent.horizontalCenter; text:'roman'; font.pixelSize:25; font.letterSpacing:3 }
        Caption { y:210; anchors.horizontalCenter:parent.horizontalCenter; text:'good things take time.'; color:root.secondary; font.pixelSize:11; font.letterSpacing:1 }
        Rectangle { y:254; width:card.width-96; height:60; anchors.horizontalCenter:parent.horizontalCenter; radius:30; color:'#aa10121c'; border.width:1; border.color:password.activeFocus?'#706b6388':'#303245'
            TextInput { id:password; anchors.fill:parent; anchors.leftMargin:24; anchors.rightMargin:68; verticalAlignment:TextInput.AlignVCenter; font.family:'Inter Variable'; font.pixelSize:15; color:root.primary; echoMode:TextInput.Password; selectByMouse:true; clip:true
                Keys.onReturnPressed:sddm.login('roman',text,root.sessionIndex)
                Keys.onEnterPressed:sddm.login('roman',text,root.sessionIndex)
            }
            Caption { x:24; anchors.verticalCenter:parent.verticalCenter; visible:password.text===''; text:'Enter your password…'; color:root.secondary }
            Rectangle { anchors.right:parent.right; anchors.rightMargin:8; anchors.verticalCenter:parent.verticalCenter; width:44; height:44; radius:22; color:submit.containsMouse?'#303048':'#202239'; border.width:1; border.color:'#706b6388'; Behavior on color { ColorAnimation { duration:160 } }
                Caption { anchors.centerIn:parent; text:'→'; font.pixelSize:24 }
                MouseArea { id:submit; anchors.fill:parent; hoverEnabled:true; onClicked:sddm.login('roman',password.text,root.sessionIndex) }
            }
        }
        Caption { id:error; y:322; anchors.horizontalCenter:parent.horizontalCenter; color:'#d183a2'; font.pixelSize:11 }
        Row { y:358; anchors.horizontalCenter:parent.horizontalCenter; spacing:24
            Repeater { model:[['☾','Sleep'],['↻','Restart'],['⏻','Power']]
                delegate:Rectangle { required property var modelData; required property int index; width:56; height:56; radius:28; color:powerHover.containsMouse?'#202239':'#10121c'; border.width:1; border.color:'#303245'; Behavior on color { ColorAnimation { duration:160 } }
                    Caption { anchors.centerIn:parent; text:modelData[0]; font.pixelSize:24 }
                    MouseArea { id:powerHover; anchors.fill:parent; hoverEnabled:true; onClicked:index===0?sddm.suspend():index===1?sddm.reboot():sddm.powerOff() }
                }
            }
        }
    }
    Caption { x:48; anchors.bottom:parent.bottom; anchors.bottomMargin:40; text:'LINUX   /   MIDNIGHT'; color:root.secondary; font.pixelSize:10; font.letterSpacing:1 }
    Row { anchors.right:parent.right; anchors.rightMargin:48; anchors.bottom:parent.bottom; anchors.bottomMargin:36; spacing:12
        Rectangle { width:64; height:36; radius:8; color:'#9910121c'; border.width:1; border.color:'#303245'
            Caption { anchors.centerIn:parent; text:root.selectedLayout; font.pixelSize:11 }
            MouseArea { anchors.fill:parent; onClicked:keyboard.currentLayout=(keyboard.currentLayout+1)%keyboard.layouts.length }
        }
        Rectangle { width:180; height:36; radius:8; color:'#9910121c'; border.width:1; border.color:'#303245'
            Caption { anchors.centerIn:parent; text:sessionEntries.itemAt(root.sessionIndex) ? sessionEntries.itemAt(root.sessionIndex).sessionName : 'Hyprland'; font.pixelSize:11 }
            MouseArea { anchors.fill:parent; onClicked:root.sessionIndex=(root.sessionIndex+1)%sessionEntries.count }
        }
    }
    Component.onCompleted: { root.ready=true; password.forceActiveFocus() }
}

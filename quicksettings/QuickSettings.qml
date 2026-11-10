import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import "../theme"
import "../bar"
import "../applets"

PanelWindow {
    id: root
    property var screen

    property string currentPowerProfile: "balanced"

    Component.onCompleted: {
        getProfileProcess.running = true;
    }

    IpcHandler {
        target: "quicksettings"
        function toggle() {
            QuickSettingsState.toggle();
        }
    }

    IpcHandler {
        target: "quicksettings"
        function toggle() {
            QuickSettingsState.toggle();
        }
        function toggleBluetooth() {
            if (!QuickSettingsState.settingsVisible) {
                QuickSettingsState.show();
            }
            QuickSettingsState.toggleBluetoothMenu();
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: QuickSettingsState.settingsVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-quicksettings"

    Connections {
        target: QuickSettingsState
        function onSettingsVisibleChanged() {
            if (QuickSettingsState.settingsVisible) {
                panel.forceActiveFocus();
                getProfileProcess.running = true;
            }
        }
    }

    anchors { top: true; bottom: true; left: true; right: true }

    mask: Region {
        item: QuickSettingsState.settingsVisible ? maskCover : null
    }
    Item {
        id: maskCover
        anchors.fill: parent
    }

    color: "transparent"

    MouseArea {
        anchors.fill: parent
        enabled: QuickSettingsState.settingsVisible
        onClicked: QuickSettingsState.hide()
    }

    Rectangle {
        id: panel
        width: 360
        height: 440

        focus: true
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (QuickSettingsState.networkMenuVisible) {
                    QuickSettingsState.networkMenuVisible = false;
                } else if (QuickSettingsState.bluetoothMenuVisible) {
                    QuickSettingsState.bluetoothMenuVisible = false;
                } else {
                    QuickSettingsState.hide();
                }
                event.accepted = true;
            }
        }

        anchors {
            right: parent.right
            top: parent.top
            rightMargin: 16
            topMargin: 38
        }

        color: Qt.rgba(Colors.colBg.r, Colors.colBg.g, Colors.colBg.b, 0.88)
        radius: 18
        border.color: Qt.alpha(Colors.colFg, 0.10)
        border.width: 1

        opacity: QuickSettingsState.settingsVisible ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        transform: Translate {
            y: QuickSettingsState.settingsVisible ? 0 : -10
            Behavior on y {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            // VIEW 1: Hoofd QuickSettings Grid & Sliders (verborgen als netwerk- of bluetoothmenu open is)
            Column {
                width: parent.width
                spacing: 16
                visible: !QuickSettingsState.networkMenuVisible && !QuickSettingsState.bluetoothMenuVisible

                Text {
                    text: "Quick Settings"
                    color: Colors.colFg
                    font {
                        pixelSize: 15
                        family: "JetBrainsMono Nerd Font"
                        weight: Font.Bold
                    }
                }

                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 10

                    Network{showBorder: true}
                    Bluetooth{}
                    PowerProfile{}
                    MicMute{}
                    ClipBoard{showBorder: true}
                }

                Column {
                    width: parent.width
                    spacing: 12
                    VolumeSlider{}
                    BrightnessSlider{}
                }
            }

            // VIEW 2: Netwerk Submenu
            NetworkSelector {
                width: parent.width
                height: parent.height - 32
                visible: QuickSettingsState.networkMenuVisible
                onCloseRequested: QuickSettingsState.networkMenuVisible = false
            }

            // VIEW 3: Bluetooth Submenu
            BluetoothSelector {
                width: parent.width
                height: parent.height - 32
                visible: QuickSettingsState.bluetoothMenuVisible
                onCloseRequested: QuickSettingsState.bluetoothMenuVisible = false
            }
        }
    }
}

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

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: QuickSettingsState.settingsVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-quicksettings"

    Connections {
        target: QuickSettingsState
        function onSettingsVisibleChanged() {
            if (QuickSettingsState.settingsVisible) {
                panel.forceActiveFocus();
            }
        }
    }

    anchors { top: true; bottom: true; left: true; right: true }

    // ── Slide offset (binnen de clip-container onder de balk) ────────────────
    property real slideOffset: QuickSettingsState.settingsVisible ? 0 : -(panel.height + 16)
    Behavior on slideOffset {
        NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
    }

    visible: QuickSettingsState.settingsVisible || slideOffset > -(panel.height + 15)

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

    // ── Clip-container onder de rechter pill van je balk ─────────────────────
    Item {
        id: settingsClipBox
        anchors.right: parent.right
        anchors.rightMargin: 4
        y: 52
        width: panel.width
        height: panel.height + 16
        clip: true

        Rectangle {
            id: panel
            width: 360
            height: contentCol.implicitHeight + 32
            x: 0
            y: root.slideOffset

            Behavior on height {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

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

            color: MatuColors.md3.surface
            radius: 16
            border.color: Qt.alpha(MatuColors.md3.on_surface, 0.10)
            border.width: 1

            // Voorkom sluiten bij klikken binnen het paneel zelf
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            Column {
                id: contentCol
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 16
                }
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

                        Network { showBorder: true }
                        Bluetooth {}
                        PowerProfile {}
                        MicMute {}
                        ClipBoard { showBorder: true }
                        NightLight {}
                    }

                    Column {
                        width: parent.width
                        spacing: 12
                        AudioOutput {}
                        VolumeSlider {}
                        BrightnessSlider {}
                    }
                }

                // VIEW 2: Netwerk Submenu
                NetworkSelector {
                    width: parent.width
                    height: 408
                    visible: QuickSettingsState.networkMenuVisible
                    onCloseRequested: QuickSettingsState.networkMenuVisible = false
                }

                // VIEW 3: Bluetooth Submenu
                BluetoothSelector {
                    width: parent.width
                    height: 408
                    visible: QuickSettingsState.bluetoothMenuVisible
                    onCloseRequested: QuickSettingsState.bluetoothMenuVisible = false
                }
            }
        }
    }
}

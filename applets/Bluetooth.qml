import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Io
import "../quicksettings"
import "../theme"

Rectangle {
    id: root
    width: 157
    height: 44
    radius: 10
    clip: true

    property var adapter: Bluetooth.defaultAdapter
    property bool isEnabled: adapter ? adapter.enabled : false

    property var connectedDevice: {
        if (!adapter || !adapter.devices) return null;
        return adapter.devices.values.find(d => d.connected);
    }

    color: isEnabled
        ? Qt.alpha(MatuColors.md3.primary, 0.25)
        : Qt.rgba(1, 1, 1, 0.07)

    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: {
                if (!isEnabled) return "󰂲"
                if (!connectedDevice) return "󰂯"
                return "󰂱"
            }
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            font.bold: true
            readonly property color baseColor: isEnabled ? MatuColors.md3.primary : MatuColors.md3.on_background
            color: mouseArea.containsMouse ? Qt.lighter(baseColor, 1.3) : baseColor

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: -2

            Text {
                Layout.fillWidth: true
                text: {
                    if (!isEnabled) return "Off"
                    if (!connectedDevice) return "Bluetooth"
                    return connectedDevice.name;
                }
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: connectedDevice ? 13 : 15
                font.bold: true
                color: mouseArea.containsMouse ? MatuColors.md3.primary : MatuColors.md3.on_background
                elide: Text.ElideRight

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // Compacte batterij-indicator onder de apparaatnaam (alleen zichtbaar indien beschikbaar)
            Text {
                Layout.fillWidth: true
                visible: isEnabled && connectedDevice && connectedDevice.batteryAvailable
                text: connectedDevice && connectedDevice.batteryAvailable
                      ? Math.round(connectedDevice.battery * 100) + "%"
                      : ""
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.bold: true
                color: mouseArea.containsMouse ? MatuColors.md3.primary : MatuColors.md3.on_background
                opacity: 0.75
                elide: Text.ElideRight

                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!QuickSettingsState.settingsVisible) {
                QuickSettingsState.show();
            }
            QuickSettingsState.toggleBluetoothMenu();
        }
    }
}

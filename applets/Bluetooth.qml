import Quickshell
import QtQuick
import Quickshell.Bluetooth
import Quickshell.Io
import "../quicksettings" // <-- Belangrijk voor QuickSettingsState
import "../theme"

Rectangle {
    id: root
    width: 157
    height: 44
    radius: 10

    property var adapter: Bluetooth.defaultAdapter
    property bool isEnabled: adapter ? adapter.enabled : false

    property var connectedDevice: {
        if (!adapter || !adapter.devices) return null;
        return adapter.devices.values.find(d => d.connected);
    }

    color: isEnabled
        ? Qt.rgba(0.2, 0.6, 1.0, 0.25)
        : Qt.rgba(1, 1, 1, 0.07)

    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: {
                if (!isEnabled) return "󰂲"
                if (!connectedDevice) return "󰂯"
                return "󰂱"
            }
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            font.bold: true
            color: isEnabled ? Qt.rgba(0.5, 0.8, 1.0, 1) : Colors.colFg
        }

        Text {
            text: {
                if (!isEnabled) return "Off"
                if (!connectedDevice) return "Bluetooth"

                var devName = connectedDevice.name;
                if (connectedDevice.batteryAvailable) {
                    var batteryPct = Math.round(connectedDevice.battery * 100);
                    return devName + " (" + batteryPct + "%)";
                }
                return devName;
            }
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            font.bold: true
            color: Colors.colFg
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!QuickSettingsState.settingsVisible) {
                QuickSettingsState.show();
            }
            QuickSettingsState.toggleBluetoothMenu();
        }
    }
}

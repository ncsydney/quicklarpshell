import Quickshell
import QtQuick
import Quickshell.Networking
import "../quicksettings"
import "../theme"

Rectangle {
    id: root
    width: 157
    height: 44
    radius: 10

    property bool showBorder: false

    property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    property var active: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null
    readonly property real signal: active ? active.signalStrength : 0

    readonly property string icon: {
        if (!Networking.wifiEnabled) return String.fromCodePoint(0xF05AA)
        if (!active) return String.fromCodePoint(0xF092D)

        let tier = signal >= 0.75 ? 4
            : signal >= 0.5 ? 3
            : signal >= 0.25 ? 2
            : 1

        return String.fromCodePoint(0xF091F + (tier - 1) * 3)
    }

    color: showBorder ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
    border.color: showBorder ? Qt.alpha(Colors.colFg, 0.15) : "transparent"
    border.width: showBorder ? 1 : 0

    Row {
        anchors.centerIn: parent
        spacing: 8

    Text {
            text: root.icon
            font {
                family: "JetBrainsMono Nerd Font"
                pixelSize: 16
                bold: true
            }
            color: MatuColors.md3.secondary
        }

        Text {
            text: {
                if (!Networking.wifiEnabled) return "WiFi Off"
                if (!root.active) return "WiFi"
                return root.active.name
            }
            font {
                family: "JetBrainsMono Nerd Font"
                pixelSize: 16
            }
            color: Colors.colFg
            elide: Text.ElideRight
            width: 95
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!QuickSettingsState.settingsVisible) {
                QuickSettingsState.show();
            }
            QuickSettingsState.toggleNetworkMenu();
        }
    }
}

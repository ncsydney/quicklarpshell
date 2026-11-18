import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import "../quicksettings"
import "../settings"
import "../theme"

Rectangle {
    id: root
    readonly property bool showLabel: root.showBorder || SettingsState.showNetworkName
    implicitWidth: root.showBorder ? 157 : (contentRow.implicitWidth + 8)
    implicitHeight: 44
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
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

    // Achtergrond blijft stabiel (geen rare kleurverandering van het hele blok bij hover)
    color: showBorder ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
    border.color: showBorder ? Qt.alpha(Colors.colFg, 0.15) : "transparent"
    border.width: showBorder ? 1 : 0

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: root.showLabel ? 8 : 0

        Text {
            text: root.icon
            font {
                family: "JetBrainsMono Nerd Font"
                pixelSize: 16
                bold: true
            }
            // Kleur verandert op basis van hover over de gehele component
            color: mouseArea.containsMouse ? MatuColors.md3.primary : Colors.colFg

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        Text {
            visible: root.showLabel
            text: {
                if (!Networking.wifiEnabled) return "WiFi Off"
                if (!root.active) return "WiFi"
                return root.active.name
            }
            font {
                family: "JetBrainsMono Nerd Font"
                pixelSize: 16
                bold: true
            }
            // Zelfde hover-kleur voor de netwerknaam
            color: mouseArea.containsMouse ? MatuColors.md3.primary : Colors.colFg
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 95)

            Behavior on color {
                ColorAnimation { duration: 150 }
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
            QuickSettingsState.toggleNetworkMenu();
        }
    }
}

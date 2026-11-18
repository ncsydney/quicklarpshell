import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Io
import "../theme"

ColumnLayout {
    id: root
    spacing: 10

    signal closeRequested()

    property var adapter: Bluetooth.defaultAdapter
    property bool isEnabled: adapter ? adapter.enabled : false
    property bool isScanning: scanProcess.running

    // Proces voor verbinden en ontkoppelen
    Process {
        id: btActionProcess
    }

    // Aparte proces voor scannen met automatische timeout (15 seconden)
    Process {
        id: scanProcess
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: "Bluetooth"
            color: MatuColors.md3.on_background
            font {
                pixelSize: 14
                family: "JetBrainsMono Nerd Font"
                weight: Font.Bold
            }
        }

        Item { Layout.fillWidth: true }

        // Bluetooth Aan/Uit Schakelaar
        Rectangle {
            width: 36; height: 22; radius: 11
            color: root.isEnabled ? MatuColors.md3.primary : Qt.rgba(1, 1, 1, 0.15)
            border.color: root.isEnabled ? Qt.alpha(MatuColors.md3.primary, 0.5) : Qt.alpha(MatuColors.md3.on_background, 0.2)
            border.width: 1

            Rectangle {
                width: 16; height: 16; radius: 8
                y: 2
                x: root.isEnabled ? parent.width - width - 3 : 3
                color: MatuColors.md3.on_background

                Behavior on x {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.adapter) {
                        btActionProcess.command = root.isEnabled
                            ? ["bluetoothctl", "power", "off"]
                            : ["bluetoothctl", "power", "on"]
                        btActionProcess.running = true;
                    }
                }
            }
        }

        // Scan knop (verbreed zodat de tekst "Scan" / "Bezig..." past)
        Rectangle {
            width: 56; height: 28; radius: 14
            color: root.isScanning ? Qt.rgba(MatuColors.md3.primary.r, MatuColors.md3.primary.g, MatuColors.md3.primary.b, 0.35) : Qt.rgba(1, 1, 1, 0.15)
            border.color: root.isScanning ? Qt.alpha(MatuColors.md3.primary, 0.5) : "transparent"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: root.isScanning ? "Scanning." : "Scan"
                color: MatuColors.md3.on_background
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.adapter && root.isEnabled && !root.isScanning) {
                        // Houd de verbinding open met een pipe zodat bluetoothctl effectief scant gedurende 15 seconden
                        scanProcess.command = ["sh", "-c", "{ echo \"scan on\"; sleep 15; echo \"scan off\"; } | bluetoothctl"];
                        scanProcess.running = true;
                    }
                }
            }
        }

        // Sluitknop
        Rectangle {
            width: 28; height: 28; radius: 14
            color: Qt.rgba(1, 1, 1, 0.15)
            Text {
                anchors.centerIn: parent
                text: "󰅖"
                color: MatuColors.md3.on_background
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 340
        clip: true
        model: root.adapter && root.isEnabled ? root.adapter.devices.values : []
        spacing: 6

        Text {
            anchors.centerIn: parent
            visible: !root.isEnabled || (root.adapter && root.adapter.devices.values.length === 0)
            text: !root.isEnabled ? "Bluetooth Off" : (root.isScanning ? "Searching..." : "No Devices Found")
            color: MatuColors.md3.on_background
            opacity: 0.5
            font {
                pixelSize: 12
                family: "JetBrainsMono Nerd Font"
            }
        }

        delegate: Rectangle {
            width: ListView.view.width
            height: 38
            radius: 12
            color: modelData.connected ? Qt.rgba(MatuColors.md3.primary.r, MatuColors.md3.primary.g, MatuColors.md3.primary.b, 0.25) : Qt.rgba(1, 1, 1, 0.07)
            border.color: modelData.connected ? Qt.alpha(MatuColors.md3.primary, 0.5) : Qt.alpha(MatuColors.md3.on_background, 0.1)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                Text {
                    text: modelData.connected ? "󰂱" : "󰂯"
                    color: modelData.connected ? MatuColors.md3.primary : MatuColors.md3.on_background
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                }

                Text {
                    Layout.fillWidth: true
                    text: {
                        var devName = modelData.name || modelData.address;
                        if (modelData.batteryAvailable) {
                            return devName + " (" + Math.round(modelData.battery * 100) + "%)";
                        }
                        return devName;
                    }
                    color: MatuColors.md3.on_background
                    elide: Text.ElideRight
                    font {
                        pixelSize: 12
                        family: "JetBrainsMono Nerd Font"
                        weight: modelData.connected ? Font.Bold : Font.Normal
                    }
                }

                Text {
                    visible: modelData.connected
                    text: "󰄬"
                    color: MatuColors.md3.primary
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (modelData.connected) {
                        btActionProcess.command = ["bluetoothctl", "disconnect", modelData.address];
                        btActionProcess.running = true;
                    } else {
                        btActionProcess.command = ["bluetoothctl", "connect", modelData.address];
                        btActionProcess.running = true;
                    }
                }
            }
        }
    }
}

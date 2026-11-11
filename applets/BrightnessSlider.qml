import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Slider {
    id: root
    width: parent ? parent.width : 200
    height: 44
    from: 0
    to: 100
    value: 80

    // Proces om helderheid in te stellen
    Process {
        id: setBrightProcess
    }

    onMoved: {
        setBrightProcess.command = ["brightnessctl", "set", Math.round(value) + "%"]
        setBrightProcess.running = true
    }

    // Proces om de werkelijke helderheid op te vragen via brightnessctl
    Process {
        id: getBrightProcess
        running: true
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(",");
                if (parts.length >= 4) {
                    var brightVal = parseInt(parts[3].replace("%", ""));
                    if (!isNaN(brightVal) && !root.pressed) {
                        root.value = brightVal;
                    }
                }
            }
        }
    }

    // Timer om de helderheid te pollen
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            if (!root.pressed) {
                getBrightProcess.running = true;
            }
        }
    }

    handle: Item {}

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 44
        radius: 12
        color: Qt.rgba(1, 1, 1, 0.07)
        border.color: Qt.alpha(Colors.colFg, 0.15)
        border.width: 1
        clip: true

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            color: Qt.alpha(MatuColors.md3.primary, 0.25)
            radius: parent.radius
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14

            Row {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter
                Text {
                    text: "󰃞"
                    font {
                        family: "JetBrainsMono Nerd Font"
                        pixelSize: 16
                        bold: true
                    }
                    color: Colors.colFg
                }
                Text {
                    text: "Brightness"
                    font {
                        family: "JetBrainsMono Nerd Font"
                        pixelSize: 16
                        bold: true
                    }
                    color: Colors.colFg
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Math.round(root.value) + "%"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                color: Colors.colFg
                opacity: 0.7
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}

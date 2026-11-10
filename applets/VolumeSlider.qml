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
    value: 50

    // Proces om het volume in te stellen via de slider
    Process {
        id: setVolProcess
    }

    onMoved: {
        setVolProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(value) + "%"]
        setVolProcess.running = true
    }

    // Proces om periodiek het werkelijke systeemvolume op te halen
    Process {
        id: getVolProcess
        running: true
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                var match = data.match(/([0-9]*\.?[0-9]+)/);
                if (match) {
                    var vol = parseFloat(match[1]) * 100;
                    if (!root.pressed) {
                        root.value = vol;
                    }
                }
            }
        }
    }

    // Timer om te controleren of het volume elders is gewijzigd
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (!root.pressed) {
                getVolProcess.running = true;
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
            color: MatuColors.md3.secondary
            radius: parent.radius
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14

            Row {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter // Gecorrigeerd naar Qt.AlignVCenter
                Text {
                    text: ""
                    font {
                        family: "JetBrainsMono Nerd Font"
                        pixelSize: 16
                        bold: true
                    }
                    color: Colors.colFg
                }
                Text {
                    text: "Volume"
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
                Layout.alignment: Qt.AlignVCenter // Gecorrigeerd naar Qt.AlignVCenter
            }
        }
    }
}

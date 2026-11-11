import Quickshell
import QtQuick
import Quickshell.Io
import "../theme"

Rectangle {
    id: root
    width: 157
    height: 44
    radius: 10

    property bool showBorder: false

    Process {
        id: clipboardProcess
        command: ["sh", "-c", "cliphist list | rofi -dmenu -p 'Clipboard' | cliphist decode | wl-copy"]
    }

    color: showBorder ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
    border.color: showBorder ? Qt.alpha(Colors.colFg, 0.15) : "transparent"
    border.width: showBorder ? 1 : 0

    Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: ""
            font {
                family: "JetBrainsMono Nerd Font"
                pixelSize: 16
                bold: true
            }
            color: Colors.colFg
        }

        Text {
            text: "Cliphist"
            font {
                family: "JetBrainsMono Nerd Font"
                pixelSize: 16
                bold: true
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
            clipboardProcess.running = true
        }
    }
}

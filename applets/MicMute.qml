import Quickshell
import Quickshell.Io
import QtQuick
import "../theme"

Rectangle {
    id: root
    width: 157
    height: 44
    radius: 10

    property bool isMuted: false

    Component.onCompleted: {
        checkMuteProcess.running = true
    }

    color: isMuted
        ? Qt.alpha(MatuColors.md3.primary, 0.25)
        : Qt.rgba(1, 1, 1, 0.07)

    border.color: Qt.alpha(Colors.colFg, 0.15)
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }

    // Proces om de huidige mute-status te controleren
    Process {
        id: checkMuteProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: SplitParser {
            onRead: data => {
                isMuted = data.includes("[MUTED]")
            }
        }
    }

    // Proces om te toggelen en direct de status te verversen
    Process {
        id: toggleProcess
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
        onExited: {
            checkMuteProcess.running = true
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: "󰍭"
            font{
                family: "JetBrainsMono Nerd Font"
                pixelSize: 16
                bold: true
            }
            color: isMuted ? MatuColors.md3.error : Colors.colFg
        }

        Text {
            text: isMuted ? "Muted" : "Mic Mute"
            font{
                family: "JetBrainsMono Nerd Font"
                pixelSize: 16
                bold: true
            }
            color: Colors.colFg
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            toggleProcess.running = true
        }
    }
}

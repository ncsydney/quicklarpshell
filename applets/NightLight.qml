
import QtQuick
import Quickshell.Io
import "../theme"
import "../settings"

Rectangle {
    id: root
    property bool active: false
    readonly property int temperature: SettingsState.nightLightTemp

    width: 159
    height: 52
    radius: 14
    color: active ? Qt.alpha(MatuColors.md3.primary, 0.25) : Qt.alpha(Colors.colFg, 0.05)
    border.color: Qt.alpha(Colors.colFg, 0.10)
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }

    Component.onCompleted: checkProc.running = true

    Process {
        id: checkProc
        command: ["pgrep", "-x", "hyprsunset"]
        onExited: (code) => { root.active = (code === 0); }
    }

    Process {
        id: startProc
    }

    Process {
        id: stopProc
        command: ["pkill", "-x", "hyprsunset"]
    }

    Row {
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 14
        }
        spacing: 10

        Text {
            text: root.active ? "󰌵" : "󰌶"
            color: mouseArea.containsMouse ? MatuColors.md3.primary : Colors.colFg
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            text: "Night Light"
            color: mouseArea.containsMouse ? MatuColors.md3.primary : Colors.colFg
            font.family: "JetBrainsMono Nerd Font"
            font {
                pixelSize: 16
                bold: true
            }
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.active) {
                stopProc.running = false;
                stopProc.running = true;
                root.active = false;
            } else {
                startProc.command = ["bash", "-c", "setsid -f hyprsunset -t " + root.temperature + " >/dev/null 2>&1"];
                startProc.running = false;
                startProc.running = true;
                root.active = true;
            }
        }
    }
}

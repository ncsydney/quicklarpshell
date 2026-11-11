import Quickshell
import Quickshell.Io
import QtQuick
import "../theme"

Rectangle {
    id: root
    width: 157
    height: 44
    radius: 10

    // Houdt het actieve energieprofiel bij
    property string currentPowerProfile: "balanced"

    // Haal de status op zodra het component geladen is
    Component.onCompleted: {
        getProfileProcess.running = true
    }

    color: currentPowerProfile === "performance"
        ? Qt.alpha(MatuColors.md3.primary, 0.25)
        : Qt.rgba(1, 1, 1, 0.07)

    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: currentPowerProfile === "performance" ? "" : (currentPowerProfile === "power-saver" ? "" : "")
            font{
                family: "JetBrainsMono Nerd Font"
                pixelSize: 16
                bold:true
            }
            color: currentPowerProfile === "performance" ? Qt.rgba(1, 0.5, 0.5, 1) : Colors.colFg
        }

        Text {
            text: currentPowerProfile.charAt(0).toUpperCase() + currentPowerProfile.slice(1)
            font{
                family: "JetBrainsMono Nerd Font"
                pixelSize: 16
                bold:true
            }
            color: Colors.colFg
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            var profiles = ["balanced", "performance", "power-saver"]
            var nextIndex = (profiles.indexOf(currentPowerProfile) + 1) % profiles.length
            var target = profiles[nextIndex]

            setProfileProcess.command = ["powerprofilesctl", "set", target]
            setProfileProcess.running = true
        }
    }

    // Processen om de powerprofilesctl status te beheren
    Process {
        id: getProfileProcess
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: data => {
                var res = data.trim()
                if (res !== "") currentPowerProfile = res
            }
        }
    }

    Process {
        id: setProfileProcess
        onExited: {
            getProfileProcess.running = true
        }
    }
}

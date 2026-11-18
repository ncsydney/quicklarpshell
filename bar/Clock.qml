import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../settings"

Text {
    id: root

    Process {
        id: mediaPlayerProcess
        command: ["qs", "ipc", "call", "mediaplayer", "toggle"]
    }

    readonly property string timeFmt: (SettingsState.use12HourClock ? "hh:mm" : "HH:mm")
                                    + (SettingsState.showSeconds ? ":ss" : "")
                                    + (SettingsState.use12HourClock ? " AP" : "")
    readonly property string fullFmt: SettingsState.showDate ? ("ddd dd MMM  " + timeFmt) : timeFmt

    text: Qt.formatDateTime(clock.date, fullFmt)

    // Kleur verandert subtiel bij hover naar je accentkleur met een animatie
    color: mouseArea.containsMouse ? MatuColors.md3.primary : Colors.colFg

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    font {
        family: "SF Mono"
        letterSpacing: -1
        pixelSize: 15
        weight: 600
    }

    SystemClock {
        id: clock
        precision: SettingsState.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            mediaPlayerProcess.running = false;
            mediaPlayerProcess.running = true;
        }
    }
}

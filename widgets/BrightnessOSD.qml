import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root
    property var modelData
    screen: modelData

    property int  _lastBrightness: -1
    property bool osdVisible:      false
    property int  brightness:      0

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.namespace:     "qs-brightness-osd-noanim"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true
    implicitHeight: 100

    mask: Region {
        item: osdCard
    }

    color: "transparent"

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root.osdVisible = false
    }

    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: {
            if (!brightnessQuery.running)
                brightnessQuery.running = true
        }
    }

    // ── Brightness query process ────────────────────────────────────────────
    Process {
        id: brightnessQuery
        command: ["sh", "-c", "echo $(( $(brightnessctl get) * 100 / $(brightnessctl max) ))"]
        stdout: SplitParser {
            onRead: data => {
                const newBrightness = parseInt(data.trim())
                if (isNaN(newBrightness)) return

                const changed = newBrightness !== root._lastBrightness
                root._lastBrightness = newBrightness
                root.brightness = newBrightness

                if (changed) {
                    root.osdVisible = true
                    hideTimer.restart()
                }
            }
        }
    }

    // ── Slide-up animation ─────────────────────────────────────────────────
    property real slideOffset: osdVisible ? 0 : 80
    Behavior on slideOffset {
        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: osdCard
        width:  240
        height: 56
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     22

        transform: Translate { y: root.slideOffset }
        opacity:   root.osdVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 220 } }

        radius: 18
        color:  Qt.rgba(Colors.colBg.r, Colors.colBg.g, Colors.colBg.b, 0.85)

        Rectangle {
            anchors.fill: parent; z: 1; radius: parent.radius
            color: "transparent"
            border.color: Qt.alpha(Colors.colFg, 0.10)
            border.width: 1
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
            spacing: 12

	            Text {
	                text: root.brightness > 60 ? "󰃠"
	                    : root.brightness > 20 ? "󰃟"
	                    :                        "󰃞"
	                font.pixelSize: 18
	                font.family:    "JetBrainsMono Nerd Font"
	                color: MatuColors.md3.secondary
	                Behavior on color { ColorAnimation { duration: 150 } }
	            }

            Rectangle {
                Layout.fillWidth: true
                height: 5; radius: 3
                color: Qt.alpha(Colors.colFg, 0.12)
                Rectangle {
                    width:  parent.width * Math.min(root.brightness / 100.0, 1.0)
                    height: parent.height; radius: parent.radius
                    color:  MatuColors.md3.secondary
                    Behavior on width { NumberAnimation { duration: 80  } }
                }
            }

            Text {
                text:                root.brightness + "%"
                font.pixelSize:      12
                font.weight:         Font.Medium
                color:                 MatuColors.md3.on_surface
                Layout.preferredWidth: 44
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}

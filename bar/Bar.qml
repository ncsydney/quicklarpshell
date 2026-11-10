import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"
import "../mediaplayer"

PanelWindow {
    id: root

    Process {
        id: quickSettingsProcess
        command: ["qs", "ipc", "call", "quicksettings", "toggle"]
    }

    Process {
        id: mediaPlayerProcess
        command: ["qs", "ipc", "call", "mediaplayer", "toggle"]
    }

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 45
    color: "transparent"

    // Config options
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 14
    readonly property real pillRadius: 12
    readonly property color pillBg: Qt.alpha(Colors.colBg, 0.85)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 8

        // Left Section: Logo, Workspaces
        Rectangle {
            Layout.fillHeight: true
            color: root.pillBg
            radius: root.pillRadius
            implicitWidth: leftRow.implicitWidth + 16

            RowLayout {
                id: leftRow
                anchors.centerIn: parent
                spacing: 8

                // Logo
		Rectangle {
		    Layout.preferredWidth: 20
		    Layout.preferredHeight: 20
		    color: "transparent"

		    Text {
			anchors.centerIn: parent
			text: "\udb82\udcc7"
			font.family: "JetBrainsMono Nerd Font"
			font.pixelSize: 22
			color: MatuColors.md3.primary
		    }

		}

                Separator {}

                Workspaces {
                    fontFamily: root.fontFamily
                    fontSize: root.fontSize
                }
                Separator{}
            }
	}

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillHeight: true
            color: root.pillBg
            radius: root.pillRadius
            implicitWidth: mediaRow.implicitWidth

            RowLayout {
                id: mediaRow
                anchors.centerIn: parent
                Separator {}
                Clock {
                    MouseArea {
             			anchors.fill: parent
             			cursorShape: Qt.PointingHandCursor
        			onClicked: {
        			    mediaPlayerProcess.running = true;
			    }
		    }
                }

                Separator{}
            }
        }

            Item {
                Layout.fillWidth: true
            }

        Rectangle {
            Layout.fillHeight: true
            implicitWidth: statusRow.implicitWidth + 24
            color: root.pillBg
            radius: root.pillRadius

            RowLayout {
                id: statusRow
                anchors.centerIn: parent
                spacing: 8

                Network {}
                Separator {}
                Battery {}


            }
                    MouseArea {
             			anchors.fill: parent
             			cursorShape: Qt.PointingHandCursor
        			onClicked: {
        			    quickSettingsProcess.running = true;
			    }
		    }
        }
    }
}

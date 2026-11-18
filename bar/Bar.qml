import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"
import "../mediaplayer"
import "../settings"

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

    Process {
        id: powerMenuProcess
        command: ["qs", "ipc", "call", "powermenu", "toggle"]
    }

    anchors {
        top: SettingsState.barPosition === "top"
        bottom: SettingsState.barPosition === "bottom"
        left: true
        right: true
    }
    implicitHeight: SettingsState.barHeight
    color: "transparent"

    // Config options (live gekoppeld aan SettingsState)
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 14
    readonly property real pillRadius: SettingsState.cornerRadius
    readonly property color pillBg: Qt.alpha(MatuColors.md3.surface, 0.86)

    Item {
        anchors.fill: parent
        anchors.margins: SettingsState.barMargin

        RowLayout {
            anchors.fill: parent
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
                        id: logoContainer
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        color: "transparent" // Geen achtergrondvierkant dat kleurt!

                        Text {
                            anchors.centerIn: parent
                            text: "󰣇" // Of je logo-teken/glyph
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 20

                            color: mouseArea.containsMouse ? MatuColors.md3.primary : MatuColors.md3.on_surface

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                powerMenuProcess.running = true;
                            }
                        }
                    }

                    Separator { visible: SettingsState.showSeparators }

                    Workspaces {
                        fontFamily: root.fontFamily
                        fontSize: root.fontSize
                    }

                    Separator { visible: SettingsState.showSeparators }
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
                    Separator { visible: SettingsState.showSeparators }
                    Battery {}
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        quickSettingsProcess.running = false;
                        quickSettingsProcess.running = true;
                    }
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            height: parent.height
            color: root.pillBg
            radius: root.pillRadius
            implicitWidth: mediaRow.implicitWidth + (SettingsState.showSeparators ? 0 : 24)

            RowLayout {
                id: mediaRow
                anchors.centerIn: parent

                Separator { visible: SettingsState.showSeparators }

                Clock {
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            mediaPlayerProcess.running = false;
                            mediaPlayerProcess.running = true;
                        }
                    }
                }

                Separator { visible: SettingsState.showSeparators }
            }
        }
    }
}

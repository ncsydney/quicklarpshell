import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../theme"

Item {
    property string fontFamily
    property int fontSize

    // Aangepast naar 10 elementen (9 workspaces + 1 scratchpad)
    implicitWidth: 10 * 20
    implicitHeight: 30
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: 9
            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: parent.height
                color: "transparent"

                property var workspace: Hyprland.workspaces.values.find(ws => ws.id === index + 1) ?? null
                property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                property bool hasWindows: (workspace?.toplevels?.values?.length ?? 0) > 0

                Text {
                    text: index + 1
                    color: (parent.isActive || parent.hasWindows) ? Colors.colFg : Colors.colBrightBlack
                    font.pixelSize: fontSize
                    font.family: fontFamily
                    font.bold: true
                    anchors.centerIn: parent
                }

                Rectangle {
                    width: 20
                    height: 3
                    color: parent.isActive ? MatuColors.md3.error : Colors.colBg
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (index + 1) + " })")
                }
            }
        }

        // Extra element voor de Scratchpad (Special Workspace)
        Rectangle {
            Layout.preferredWidth: 20
            Layout.preferredHeight: parent.height
            color: "transparent"

            property var scratchpadWs: Hyprland.workspaces.values.find(ws => ws.name.startsWith("special")) ?? null
            property bool isScratchpadActive: Hyprland.focusedWorkspace?.name?.startsWith("special") ?? false
            property bool scratchpadHasWindows: (scratchpadWs?.toplevels?.values?.length ?? 0) > 0

            Text {
                text: "S" // Je kunt hier ook een icoon neerzetten
                color: (parent.isScratchpadActive || parent.scratchpadHasWindows) ? MatuColors.md3.secondary : Colors.colBrightBlack
                font.pixelSize: fontSize
                font.family: fontFamily
                font.bold: true
                anchors.centerIn: parent
            }

            Rectangle {
                width: 20
                height: 3
                color: parent.isScratchpadActive ? Colors.colPurple : Colors.colBg
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
            }

            MouseArea {
                anchors.fill: parent
                // Pas de dispatch-opdracht aan op basis van hoe jouw config special workspaces toggled
                onClicked: Hyprland.dispatch("dispatch togglespecialworkspace kitty-scratchpad")
            }
        }
    }
}

import QtQuick
import Quickshell.Io
import "../theme"

Rectangle {
    id: root
    width: parent ? parent.width : 328
    height: expanded ? Math.min(180, 48 + sinksModel.count * 34) : 44
    radius: 12
    clip: true
    color: Qt.rgba(1, 1, 1, 0.07)
    border.color: Qt.alpha(MatuColors.md3.on_background, 0.25)
    border.width: 1

    property bool expanded: false
    property string activeSinkName: "Audio Output"

    Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    ListModel { id: sinksModel }

    function refreshSinks() {
        listProc.running = false;
        listProc.running = true;
    }

    Component.onCompleted: refreshSinks()

    // Leest alle PipeWire Sinks uit via wpctl status
    Process {
        id: listProc
        command: ["bash", "-c", "wpctl status | awk '/Sinks:/,/Sources:/'"]
        stdout: StdioCollector {
            onStreamFinished: {
                sinksModel.clear();
                const lines = text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const m = lines[i].match(/(\*)?\s*(\d+)\.\s+(.+?)\s*(?:\[vol:|$)/);
                    if (m) {
                        const isDefault = (m[1] === "*");
                        const id = m[2];
                        const name = m[3].trim();
                        sinksModel.append({ sinkId: id, sinkName: name, isActive: isDefault });
                        if (isDefault) root.activeSinkName = name;
                    }
                }
            }
        }
    }

    Process {
        id: setSinkProc
        property string targetId: ""
        command: ["wpctl", "set-default", targetId]
        onExited: root.refreshSinks()
    }

    Column {
        anchors.fill: parent

        // Kopregel (klik om lijst uit te klappen)
        Item {
            width: parent.width
            height: 44

            Row {
                anchors {
                    left: parent.left
                    right: expandIcon.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 14
                    rightMargin: 8
                }
                spacing: 10

                Text {
                    text: root.activeSinkName.toLowerCase().includes("head") ? "󰋋" : "󰓃"
                    color: MatuColors.md3.primary
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    width: parent.width - 26
                    text: root.activeSinkName
                    color: MatuColors.md3.on_background
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                id: expandIcon
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin: 14
                }
                text: root.expanded ? "󰅃" : "󰅀"
                color: MatuColors.md3.on_background
                opacity: 0.7
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.refreshSinks();
                    root.expanded = !root.expanded;
                }
            }
        }

        // Subtiele scheidingslijn wanneer uitgeklapt
        Rectangle {
            width: parent.width - 28
            height: 1
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.alpha(MatuColors.md3.on_background, 0.12)
            visible: root.expanded
        }

        // Uitklapbare lijst met audio-apparaten
        ListView {
            width: parent.width
            height: parent.height - 45
            clip: true
            model: sinksModel

            delegate: Rectangle {
                width: ListView.view.width
                height: 34
                color: isActive
                       ? Qt.alpha(MatuColors.md3.primary, 0.25)
                       : (rowMa.containsMouse ? Qt.alpha(MatuColors.md3.on_background, 0.08) : "transparent")

                Row {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 16
                        rightMargin: 14
                    }
                    spacing: 8

                    Text {
                        text: isActive ? "󰄬" : " "
                        color: MatuColors.md3.primary
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        width: parent.width - 20
                        text: sinkName
                        color: MatuColors.md3.on_background
                        opacity: isActive ? 1.0 : 0.8
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: isActive
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        setSinkProc.targetId = sinkId;
                        setSinkProc.running = true;
                        root.expanded = false;
                    }
                }
            }
        }
    }
}

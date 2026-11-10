import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../theme"

ColumnLayout {
    id: root
    spacing: 10

    signal closeRequested()

    ListModel {
        id: audioSinksModel
    }

    Process {
        id: sinksProcess
        // Parst wpctl status feilloos en levert schone regels op in het formaat: ID|NAAM|ACTIEF
        command: ["sh", "-c", "wpctl status | sed 's/\\x1b\\[[0-9;]*m//g' | awk 'BEGIN { in_sinks=0 } /Sinks:/ { in_sinks=1; next } /Sources:/ || /Filters:/ || /Clients:/ || /Streams:/ { in_sinks=0 } in_sinks { if ($0 ~ /[0-9]+\\./) { active = ($0 ~ /\\*/) ? 1 : 0; line = $0; sub(/^[ \\t│├└─*]+/, \"\", line); split(line, parts, \".\"); id = parts[1]; sub(/^[0-9]+[ \\t]*\\.[ \\t]*/, \"\", line); sub(/[ \\t]*\\[vol:.*$/, \"\", line); print id \"|\" line \"|\" active; } }'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim();
                if (line === "") return;

                var parts = line.split("|");
                if (parts.length === 3) {
                    var id = parts[0].trim();
                    var name = parts[1].trim();
                    var isActive = (parts[2].trim() === "1");

                    var exists = false;
                    for (var i = 0; i < audioSinksModel.count; i++) {
                        if (audioSinksModel.get(i).sinkId === id) {
                            exists = true;
                            audioSinksModel.setProperty(i, "isActive", isActive);
                            audioSinksModel.setProperty(i, "sinkName", name);
                            break;
                        }
                    }
                    if (!exists && name.length > 0) {
                        audioSinksModel.append({
                            "sinkId": id,
                            "sinkName": name,
                            "isActive": isActive
                        });
                    }
                }
            }
        }
    }

    Process {
        id: setSinkProcess
    }

    function refresh() {
        audioSinksModel.clear();
        sinksProcess.running = true;
    }

    Component.onCompleted: {
        refresh();
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "Select media output"
            color: Colors.colFg
            font {
                pixelSize: 14
                family: "JetBrainsMono Nerd Font"
                weight: Font.Bold
            }
        }
        Item { Layout.fillWidth: true }

        Rectangle {
            width: 28; height: 28; radius: 14
            color: Qt.rgba(1, 1, 1, 0.15)
            Text {
                anchors.centerIn: parent
                text: "󰅖"
                color: Colors.colFg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.closeRequested()
            }
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 130
        clip: true
        model: audioSinksModel
        spacing: 6

        Text {
            anchors.centerIn: parent
            visible: audioSinksModel.count === 0
            text: "Geen audio-uitgangen gevonden"
            color: Colors.colFg
            opacity: 0.5
            font {
                pixelSize: 12
                family: "JetBrainsMono Nerd Font"
            }
        }

        delegate: Rectangle {
            width: ListView.view.width
            height: 38
            radius: 12
            color: model.isActive ? Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.25) : Qt.rgba(1, 1, 1, 0.07)
            border.color: model.isActive ? Qt.alpha(Colors.colBlue, 0.5) : Qt.alpha(Colors.colFg, 0.1)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                Text {
                    text: model.isActive ? "󰓃" : "󰋋"
                    color: model.isActive ? Colors.colBlue : Colors.colFg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                }

                Text {
                    Layout.fillWidth: true
                    text: model.sinkName
                    color: Colors.colFg
                    elide: Text.ElideRight
                    font {
                        pixelSize: 12
                        family: "JetBrainsMono Nerd Font"
                        weight: model.isActive ? Font.Bold : Font.Normal
                    }
                }

                Text {
                    visible: model.isActive
                    text: "󰄬"
                    color: Colors.colBlue
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    // Schakel direct over via wpctl set-default met de juiste sink ID
                    setSinkProcess.command = ["wpctl", "set-default", model.sinkId];
                    setSinkProcess.running = true;
                    refreshTimer.restart();
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 250
        repeat: false
        onTriggered: root.refresh()
    }
}

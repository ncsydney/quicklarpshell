import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import "../theme"

ColumnLayout {
    id: root
    spacing: 10

    signal closeRequested()

    property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    property var selectedNetwork: null

    Component.onCompleted: {
        if (wifiDevice) {
            wifiDevice.scannerEnabled = true;
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: root.selectedNetwork ? "Verbind met " + root.selectedNetwork.name : "Netwerkcentrum"
            color: Colors.colFg
            font {
                pixelSize: 14
                family: "JetBrainsMono Nerd Font"
                weight: Font.Bold
            }
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        // Sluit- of terugknop
        Rectangle {
            width: 28; height: 28; radius: 14
            color: Qt.rgba(1, 1, 1, 0.15)
            Text {
                anchors.centerIn: parent
                text: root.selectedNetwork ? "󰁍" : "󰅖"
                color: Colors.colFg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.selectedNetwork) {
                        root.selectedNetwork = null;
                    } else {
                        root.closeRequested();
                    }
                }
            }
        }
    }

    // ── LIJST MET NETWERKEN ──
    ListView {
        id: netList
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 340
        clip: true
        visible: !root.selectedNetwork
        model: root.wifiDevice ? root.wifiDevice.networks.values : []
        spacing: 6

        Text {
            anchors.centerIn: parent
            visible: !root.wifiDevice || root.wifiDevice.networks.values.length === 0
            text: "Geen netwerken gevonden"
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
            color: modelData.connected ? Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.25) : Qt.rgba(1, 1, 1, 0.07)
            border.color: modelData.connected ? Qt.alpha(Colors.colBlue, 0.5) : Qt.alpha(Colors.colFg, 0.1)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                Text {
                    text: modelData.connected ? "󰤨" : "󰤯"
                    color: modelData.connected ? Colors.colBlue : Colors.colFg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                }

                Text {
                    Layout.fillWidth: true
                    text: modelData.name || "Onbekend netwerk"
                    color: Colors.colFg
                    elide: Text.ElideRight
                    font {
                        pixelSize: 12
                        family: "JetBrainsMono Nerd Font"
                        weight: modelData.connected ? Font.Bold : Font.Normal
                    }
                }

                Text {
                    visible: modelData.connected
                    text: "󰄬"
                    color: Colors.colBlue
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!modelData.connected) {
                        if (modelData.known) {
                            modelData.connect();
                        } else {
                            root.selectedNetwork = modelData;
                        }
                    }
                }
            }
        }
    }

    // ── WACHTWOORD INVOER SCHERM (Strak gestyled in QML-thema) ──
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12
        visible: root.selectedNetwork !== null

        Text {
            text: "Wachtwoord vereist voor:\n" + (root.selectedNetwork ? root.selectedNetwork.name : "")
            color: Colors.colFg
            opacity: 0.8
            font {
                pixelSize: 12
                family: "JetBrainsMono Nerd Font"
            }
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // Aangepast invoerveld in dezelfde stijl als de lijstitems
        Rectangle {
            Layout.fillWidth: true
            height: 38
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.07)
            border.color: Qt.alpha(Colors.colFg, 0.2)
            border.width: 1

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 36
                verticalAlignment: TextInput.AlignVCenter
                color: Colors.colFg
                font {
                    pixelSize: 13
                    family: "JetBrainsMono Nerd Font"
                }
                echoMode: TextInput.Password
                focus: root.selectedNetwork !== null

                onAccepted: {
                    if (root.selectedNetwork && text.length > 0) {
                        root.selectedNetwork.connectWithPsk(text);
                        text = "";
                        root.selectedNetwork = null;
                    }
                }
            }

            // Klein slot-icoontje aan de rechterkant
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "󰌾"
                color: Colors.colFg
                opacity: 0.4
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
            }
        }

        // Gekleurde verbindknop in dezelfde stijl als actieve items
        Rectangle {
            Layout.fillWidth: true
            height: 38
            radius: 12
            color: btnMouse.containsMouse ? Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.35) : Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.25)
            border.color: Qt.alpha(Colors.colBlue, 0.5)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Verbinden"
                color: Colors.colBlue
                font {
                    pixelSize: 13
                    family: "JetBrainsMono Nerd Font"
                    weight: Font.Bold
                }
            }

            MouseArea {
                id: btnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.selectedNetwork && passwordInput.text.length > 0) {
                        root.selectedNetwork.connectWithPsk(passwordInput.text);
                        passwordInput.text = "";
                        root.selectedNetwork = null;
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}

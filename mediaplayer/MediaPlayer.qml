import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects // Nodig voor FastBlur en OpacityMask
import "../theme"

PanelWindow {
    id: root
    property var screen

    property bool showOutputMenu: false

    // ── IPC Handler voor het openen/sluiten via shortcuts of de balk ──
    IpcHandler {
        target: "mediaplayer"
        function toggle() {
            MediaPlayerState.toggle();
            if (!MediaPlayerState.playerVisible) {
                root.showOutputMenu = false;
            }
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: MediaPlayerState.playerVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-mediaplayer"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: MediaPlayerState.playerVisible ? maskCover : null
    }

    Item {
        id: maskCover
        anchors.fill: parent
    }

    color: "transparent"

    // ── Actieve MPRIS Speler ────────────────────────────────────────────────
    readonly property MprisPlayer activePlayer: {
        var players = Mpris.players.values;
        if (players.length === 0) return null;
        for (var i = 0; i < players.length; i++) {
            if (players[i].identity.toLowerCase().indexOf("spotify") !== -1)
                return players[i];
        }
        return players[0];
    }

    // ── Live positie bijhouden via een Timer ────────────────────────────────
    property real livePosition: 0

    onActivePlayerChanged: {
        if (root.activePlayer) {
            root.livePosition = root.activePlayer.position;
        }
    }

    Timer {
        interval: 200
        running: root.activePlayer && root.activePlayer.isPlaying && MediaPlayerState.playerVisible
        repeat: true
        onTriggered: {
            if (root.activePlayer) {
                root.livePosition = root.activePlayer.position;
            }
        }
    }

    function formatTime(seconds) {
        if (isNaN(seconds) || seconds < 0) return "0:00";
        var m = Math.floor(seconds / 60);
        var s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // Sluiten bij klikken buiten het paneel
    MouseArea {
        anchors.fill: parent
        enabled: MediaPlayerState.playerVisible
        onClicked: {
            MediaPlayerState.hide();
            root.showOutputMenu = false;
        }
    }

    // ── Panel Geometry & Styling ──────────────────────────────────────────
    readonly property int panelW: 390
    readonly property int panelH: 210

    Rectangle {
        id: panel
        width: root.panelW
        height: root.panelH
        clip: true

        focus: true // Nodig om toetsaanslagen te ontvangen
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (root.showOutputMenu) {
                    root.showOutputMenu = false;
                } else {
                    MediaPlayerState.hide();
                }
                event.accepted = true;
            }
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 12

        color: Qt.rgba(Colors.colBg.r, Colors.colBg.g, Colors.colBg.b, 0.85)
        radius: 32 // Ronde hoeken gelijk aan OneUI 8
        border.color: Qt.alpha(Colors.colFg, 0.12)
        border.width: 1

        transform: Translate {
            y: MediaPlayerState.playerVisible ? 0 : -root.panelH - 20
            Behavior on y {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }
        }
        opacity: MediaPlayerState.playerVisible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }

        // ── OneUI 8 Album Art Achtergrond (Netjes afgerond via OpacityMask) ──
        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: panel.width
                    height: panel.height
                    radius: panel.radius
                }
            }

            Image {
                id: bgArtSource
                anchors.fill: parent
                source: root.activePlayer ? root.activePlayer.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: false
                smooth: true
            }

            FastBlur {
                anchors.fill: parent
                source: bgArtSource
                radius: 40
                visible: root.activePlayer !== null && bgArtSource.status === Image.Ready
                opacity: 0.65
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)
                visible: root.activePlayer !== null && bgArtSource.status === Image.Ready
            }
        }

        Item {
            anchors.fill: parent
            anchors.margins: 16

            Text {
                anchors.centerIn: parent
                visible: !root.activePlayer && !root.showOutputMenu
                text: "No media"
                color: Colors.colFg
                opacity: 0.4
                font {
                    pixelSize: 13
                    family: "JetBrainsMono Nerd Font"
                }
            }

            // ────────────────────────────────────────────────────────
            // VIEW 1: STANDAARD MEDIA PLAYER VIEW
            // ────────────────────────────────────────────────────────
            ColumnLayout {
                anchors.fill: parent
                spacing: 12
                visible: !root.showOutputMenu && root.activePlayer !== null

                // ── Bovenste rij: App/Bron + Media output knop ──
                RowLayout {
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 8
                        Text {
                            text: "󰓇"
                            color: Colors.colFg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                        Text {
                            text: root.activePlayer ? (root.activePlayer.identity || "Media") : ""
                            color: Colors.colFg
                            opacity: 0.8
                            font {
                                pixelSize: 12
                                family: "JetBrainsMono Nerd Font"
                                weight: Font.Medium
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Media Output Pill Button
                    Rectangle {
                        height: 28
                        width: outputText.implicitWidth + 24
                        radius: 14
                        color: Qt.rgba(1, 1, 1, 0.15)
                        border.color: Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1

                        Text {
                            id: outputText
                            anchors.centerIn: parent
                            text: "Media output"
                            color: Colors.colFg
                            font {
                                pixelSize: 11
                                family: "JetBrainsMono Nerd Font"
                                weight: Font.Medium
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.showOutputMenu = true;
                            }
                        }
                    }
                }

                // ── Middelste sectie: Titel & Artiest ──
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: root.activePlayer ? (root.activePlayer.trackTitle || "Onbekend nummer") : ""
                        elide: Text.ElideRight
                        color: Colors.colFg
                        font {
                            pixelSize: 15
                            family: "JetBrainsMono Nerd Font"
                            weight: Font.Bold
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.activePlayer ? (root.activePlayer.trackArtist || "Onbekende artiest") : ""
                        elide: Text.ElideRight
                        color: Colors.colFg
                        opacity: 0.75
                        font {
                            pixelSize: 12
                            family: "JetBrainsMono Nerd Font"
                        }
                    }
                }

                // ── Voortgangsbalk & Tijdweergave ──
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.2)

                        Rectangle {
                            height: parent.height
                            radius: 2
                            color: Colors.colBlue
                            width: {
                                if (!root.activePlayer || root.activePlayer.length === 0) return 0;
                                return parent.width * Math.min(1.0, root.livePosition / root.activePlayer.length);
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.formatTime(root.livePosition)
                            color: Colors.colFg
                            opacity: 0.6
                            font {
                                pixelSize: 10
                                family: "JetBrainsMono Nerd Font"
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.formatTime(root.activePlayer ? root.activePlayer.length : 0)
                            color: Colors.colFg
                            opacity: 0.6
                            font {
                                pixelSize: 10
                                family: "JetBrainsMono Nerd Font"
                            }
                        }
                    }
                }

                // ── Onderste rij: Volledige set Mediacontrols ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    // Shuffle Knop
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: (root.activePlayer && root.activePlayer.shuffle) ? Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.25) : "transparent"
                        border.color: (root.activePlayer && root.activePlayer.shuffle) ? Qt.alpha(Colors.colBlue, 0.5) : "transparent"
                        border.width: (root.activePlayer && root.activePlayer.shuffle) ? 1 : 0

                        Text {
                            anchors.centerIn: parent
                            text: "󰒟"
                            color: (root.activePlayer && root.activePlayer.shuffle) ? Colors.colBlue : Colors.colFg
                            opacity: (root.activePlayer && root.activePlayer.shuffle) ? 1.0 : 0.7
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                MediaPlayerState.toggleShuffle(root.activePlayer);
                            }
                        }
                    }

                    // Vorige Knop
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            color: Colors.colFg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (root.activePlayer) root.activePlayer.previous()
                        }
                    }

                    // Play / Pause Knop
                    Rectangle {
                        width: 42; height: 42; radius: 21
                        color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.3)
                        border.color: Qt.alpha(Colors.colBlue, 0.5)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: (root.activePlayer && root.activePlayer.isPlaying) ? "󰏤" : "󰐊"
                            color: Colors.colBlue
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
                        }
                    }

                    // Volgende Knop
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            color: Colors.colFg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (root.activePlayer) root.activePlayer.next()
                        }
                    }

                    // Repeat Knop
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        readonly property bool isRepeating: root.activePlayer && root.activePlayer.loopStatus && root.activePlayer.loopStatus !== "None"

                        color: isRepeating ? Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.25) : "transparent"
                        border.color: isRepeating ? Qt.alpha(Colors.colBlue, 0.5) : "transparent"
                        border.width: isRepeating ? 1 : 0

                        Text {
                            anchors.centerIn: parent
                            text: (root.activePlayer && root.activePlayer.loopStatus === "Track") ? "󰑘" : "󰑖"
                            color: parent.isRepeating ? Colors.colBlue : Colors.colFg
                            opacity: parent.isRepeating ? 1.0 : 0.7
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                MediaPlayerState.toggleRepeat(root.activePlayer);
                            }
                        }
                    }
                }
            }

            // ────────────────────────────────────────────────────────
            // VIEW 2: MEDIA OUTPUT SELECTION MENU (Aparte Component)
            // ────────────────────────────────────────────────────────
            MediaOutputSelector {
                anchors.fill: parent
                visible: root.showOutputMenu
                onCloseRequested: root.showOutputMenu = false
            }
        }
    }
}

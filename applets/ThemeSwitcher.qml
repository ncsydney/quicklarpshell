import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: root

    property var screen
    property bool pickerVisible: false

    // ── Variabelen uit jouw bash-script ──────────────────────────────────────
    readonly property string wallpaperBaseDir: Quickshell.env("HOME") + "/Pictures/backgrounds"
    readonly property string curwallConfPath: Quickshell.env("HOME") + "/.config/hypr/curwall.conf"
    readonly property string matugenConfigPath: Quickshell.env("HOME") + "/.config/matugen/config.toml"

    // ── Huidige actieve wallpaper uit curwall.conf ───────────────────────────
    property string activeWallpaperPath: ""

    FileView {
        id: curwallFile
        path: root.curwallConfPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const match = text().match(/\$FULL_PATH=(.+)/);
            if (match && match[1]) {
                root.activeWallpaperPath = match[1].trim();
            }
        }
    }

    // ── Live kleuren-preview state ───────────────────────────────────────────
    property string previewPath: ""
    property var previewColors: [
        MatuColors.md3.primary,
        MatuColors.md3.secondary,
        MatuColors.md3.tertiary,
        MatuColors.md3.primary_container,
        MatuColors.md3.surface_container_highest
    ]

    // ── IPC-koppeling ────────────────────────────────────────────────────────
    IpcHandler {
        target: "themeswitcher"
        function toggle(): void {
            root.pickerVisible = !root.pickerVisible;
        }
    }

    // ── Layer / scherm-overlay ───────────────────────────────────────────────
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: root.pickerVisible || animProgress > 0.01

    mask: Region {
        item: root.pickerVisible ? maskCover : null
    }

    Item {
        id: maskCover
        anchors.fill: parent
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.pickerVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-themeswitcher"

    // ── Animatie-progress (0 = gesloten, 1 = open) ───────────────────────────
    property real animProgress: root.pickerVisible ? 1.0 : 0.0
    Behavior on animProgress {
        NumberAnimation {
            duration: root.pickerVisible ? 320 : 200
            easing.type: root.pickerVisible ? Easing.OutBack : Easing.InCubic
            easing.overshoot: 1.15
        }
    }

    // ── Debounce timer voor snelle live kleuren-preview ──────────────────────
    Timer {
        id: previewDebounce
        interval: 120
        repeat: false
        onTriggered: {
            if (root.previewPath !== "") {
                previewProc.running = false;
                previewProc.running = true;
            }
        }
    }

    function extractHex(colorsRoot, key) {
        if (!colorsRoot) return null;
        if (colorsRoot.dark && colorsRoot.dark[key]) {
            const val = colorsRoot.dark[key];
            if (typeof val === "string" && val.startsWith("#")) return val;
            if (val && typeof val.color === "string") return val.color;
        }
        if (colorsRoot[key]) {
            const entry = colorsRoot[key];
            if (typeof entry === "string" && entry.startsWith("#")) return entry;
            if (entry && typeof entry.dark === "string") return entry.dark;
            if (entry && entry.dark && typeof entry.dark.color === "string") return entry.dark.color;
            if (entry && typeof entry.color === "string") return entry.color;
        }
        return null;
    }

    // ── Matugen dry-run voor de 5 preview-kleurbolletjes ─────────────────────
    Process {
        id: previewProc
        command: [
            "matugen", "image", root.previewPath,
            "--source-color-index", "0",
            "--dry-run", "-j", "hex"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const c = data.colors || data;
                    const p1 = root.extractHex(c, "primary");
                    const p2 = root.extractHex(c, "secondary");
                    const p3 = root.extractHex(c, "tertiary");
                    const p4 = root.extractHex(c, "primary_container");
                    const p5 = root.extractHex(c, "surface_container_highest");

                    if (p1 && p2 && p3) {
                        root.previewColors = [
                            p1,
                            p2,
                            p3,
                            p4 || p1,
                            p5 || p2
                        ];
                    }
                } catch (e) {}
            }
        }
    }

    function requestPreview(fileUrlStr) {
        if (!fileUrlStr) return;
        const cleanPath = decodeURIComponent(fileUrlStr.replace("file://", ""));
        if (cleanPath !== root.previewPath) {
            root.previewPath = cleanPath;
            previewDebounce.restart();
        }
    }

    // Zoekt de actieve wallpaper in het grid en springt er direct naartoe
    function jumpToActiveWallpaper() {
        if (folderModel.count === 0) return;

        let targetIdx = 0;
        if (root.activeWallpaperPath !== "") {
            for (let i = 0; i < folderModel.count; i++) {
                const itemPath = decodeURIComponent(folderModel.get(i, "fileUrl").toString().replace("file://", ""));
                if (itemPath === root.activeWallpaperPath) {
                    targetIdx = i;
                    break;
                }
            }
        }

        grid.currentIndex = targetIdx;
        grid.positionViewAtIndex(targetIdx, GridView.Contain);
        const url = folderModel.get(targetIdx, "fileUrl");
        if (url) root.requestPreview(url.toString());
    }

    // ── Proces dat alle acties uit jouw script uitvoert ──────────────────────
    Process {
        id: applyThemeProc
        property string targetPath: ""
        property string targetName: ""

        command: [
            "bash", "-c",
            "echo \"\\$FULL_PATH=$1\" > \"$3\" && " +
            "waypaper --wallpaper \"$1\" && " +
            "matugen image \"$1\" --source-color-index 0 -c \"$4\" && " +
            "notify-send -i \"$1\" \"Wallpaper Changed\" \"New wallpaper: $2\"",
            "--",
            targetPath,
            targetName,
            root.curwallConfPath,
            root.matugenConfigPath
        ]
    }

    function applyWallpaper(fileUrlStr, fileName) {
        const cleanPath = decodeURIComponent(fileUrlStr.replace("file://", ""));
        root.activeWallpaperPath = cleanPath;
        applyThemeProc.targetPath = cleanPath;
        applyThemeProc.targetName = fileName;
        applyThemeProc.running = true;
        root.pickerVisible = false;
    }

    // Subtiele donkere achtergrond-dimmer die mee-animeert
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45 * root.animProgress)

        MouseArea {
            anchors.fill: parent
            enabled: root.pickerVisible
            onClicked: root.pickerVisible = false
        }
    }

    // ── Hoofdvenster ─────────────────────────────────────────────────────────
    Rectangle {
        id: mainCard
        anchors.centerIn: parent
        anchors.verticalCenterOffset: (1.0 - root.animProgress) * 24
        width: parent.width * 0.65
        height: parent.height * 0.70
        radius: 16
        clip: true

        opacity: Math.min(1.0, root.animProgress * 1.3)
        scale: 0.92 + (0.08 * root.animProgress)

        color: Qt.alpha(MatuColors.md3.surface, 0.94)
        border.color: MatuColors.md3.primary
        border.width: 2

        // ── Subtiele wazige gloed van de geselecteerde wallpaper ─────────────
        Image {
            id: ambientGlow
            anchors.fill: parent
            anchors.margins: 2
            source: root.previewPath !== "" ? "file://" + root.previewPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            // Lage resolutie op groot vlak geeft een natuurlijke, zachte blur
            sourceSize.width: 48
            sourceSize.height: 48
            opacity: status === Image.Ready ? 0.18 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16

            // ── Zoekbalk + Live Kleuren-preview ──────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 12
                color: Qt.alpha(MatuColors.md3.surface_container, 0.88)
                border.color: MatuColors.md3.primary
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    Text {
                        text: "Choose Wallpaper:"
                        color: MatuColors.md3.primary
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 13
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: MatuColors.md3.on_surface
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        clip: true

                        Keys.onEscapePressed: root.pickerVisible = false

                        Keys.onReturnPressed: {
                            if (grid.count > 0 && grid.currentIndex >= 0) {
                                const url = folderModel.get(grid.currentIndex, "fileUrl").toString();
                                const name = folderModel.get(grid.currentIndex, "fileName");
                                root.applyWallpaper(url, name);
                            }
                        }

                        Keys.onLeftPressed: grid.moveCurrentIndexLeft()
                        Keys.onRightPressed: grid.moveCurrentIndexRight()
                        Keys.onUpPressed: grid.moveCurrentIndexUp()
                        Keys.onDownPressed: grid.moveCurrentIndexDown()

                        onTextChanged: {
                            folderModel.nameFilters = text.length > 0
                                ? ["*" + text + "*.jpg", "*" + text + "*.jpeg", "*" + text + "*.png", "*" + text + "*.webp"]
                                : ["*.jpg", "*.jpeg", "*.png", "*.webp"];
                            grid.currentIndex = 0;
                        }

                        Text {
                            anchors.fill: parent
                            text: "Search."
                            color: MatuColors.md3.on_surface_variant
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            visible: !searchInput.text
                        }
                    }

                    // ── Live Matugen Palet-bolletjes rechts in de zoekbalk ───
                    Row {
                        spacing: 6

                        Text {
                            text: "Palet:"
                            color: MatuColors.md3.on_surface
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                            rightPadding: 4
                        }

                        Repeater {
                            model: root.previewColors
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: modelData
                                border.color: Qt.rgba(1, 1, 1, 0.25)
                                border.width: 1
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on color {
                                    ColorAnimation { duration: 180 }
                                }
                            }
                        }
                    }
                }
            }

            // ── Wallpaper Grid (4 kolommen) ──────────────────────────────────
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: width / 4
                cellHeight: 225
                currentIndex: 0

                onCurrentIndexChanged: {
                    if (count > 0 && currentIndex >= 0 && currentIndex < count) {
                        const url = folderModel.get(currentIndex, "fileUrl");
                        if (url) root.requestPreview(url.toString());
                    }
                }

                model: FolderListModel {
                    id: folderModel
                    folder: "file://" + root.wallpaperBaseDir
                    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
                    showDirs: false
                    sortField: FolderListModel.Name

                    onCountChanged: {
                        if (count > 0 && root.pickerVisible) {
                            root.jumpToActiveWallpaper();
                        }
                    }
                }

                delegate: Item {
                    width: grid.cellWidth
                    height: grid.cellHeight

                    readonly property string itemCleanPath: decodeURIComponent(fileUrl.toString().replace("file://", ""))
                    readonly property bool isActiveWallpaper: itemCleanPath === root.activeWallpaperPath
                    readonly property bool isHighlighted: grid.currentIndex === index || tileMouse.containsMouse

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 8
                        radius: 12
                        color: isHighlighted
                               ? MatuColors.md3.primary
                               : Qt.alpha(MatuColors.md3.surface_container, 0.88)

                        border.color: isActiveWallpaper && !isHighlighted
                                      ? MatuColors.md3.primary
                                      : "transparent"
                        border.width: isActiveWallpaper && !isHighlighted ? 2 : 0

                        scale: isHighlighted ? 1.03 : 1.0

                        Behavior on scale {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            // Thumbnail van de wallpaper
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: MatuColors.md3.surface_container_lowest
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: fileUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.width: 320
                                }

                                // ── "Actief" badge rechtsboven op de huidige wallpaper ──
                                Rectangle {
                                    visible: isActiveWallpaper
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 6
                                    height: 22
                                    width: activeBadgeRow.implicitWidth + 12
                                    radius: 6
                                    color: Qt.alpha(MatuColors.md3.surface, 0.88)
                                    border.color: MatuColors.md3.primary
                                    border.width: 1

                                    Row {
                                        id: activeBadgeRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: "󰄬"
                                            color: MatuColors.md3.primary
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.bold: true
                                            font.pixelSize: 11
                                        }

                                        Text {
                                            text: "Actief"
                                            color: MatuColors.md3.on_surface
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.bold: true
                                            font.pixelSize: 10
                                        }
                                    }
                                }
                            }

                            // Bestandsnaam
                            Text {
                                Layout.fillWidth: true
                                text: fileName
                                color: isHighlighted
                                       ? MatuColors.md3.on_primary
                                       : MatuColors.md3.on_surface
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: isHighlighted || isActiveWallpaper
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: grid.currentIndex = index
                            onClicked: root.applyWallpaper(fileUrl.toString(), fileName)
                        }
                    }
                }
            }
        }
    }

    onPickerVisibleChanged: {
        if (pickerVisible) {
            curwallFile.reload();
            searchInput.text = "";
            searchInput.forceActiveFocus();
            root.jumpToActiveWallpaper();
        }
    }
}

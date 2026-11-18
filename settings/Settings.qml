import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root
    property var screen
    property int currentTab: 0
    property string searchQuery: ""

    readonly property string uiFont: "JetBrainsMono Nerd Font"
    readonly property var tabs: [
        { icon: "󰕮", label: "Bar & Layout" },
        { icon: "󰚥", label: "Modules" },
        { icon: "󰏘", label: "Theme & Colors" },
        { icon: "", label: "Hyprland" },
        { icon: "󰌌", label: "Keybinds" },
        { icon: "󰋼", label: "System" }
    ]

    // Central metadata with unique keys (single source of truth)[cite: 5, 6]
    readonly property var settingCatalog: [
        { key: "preset", tab: 0, cat: "Bar & Layout", title: "Quick Preset (Profile)", subtitle: "Apply a complete desktop layout immediately" },
        { key: "barPosition", tab: 0, cat: "Bar & Layout", title: "Bar Position", subtitle: "Place the bar at the top or bottom of the screen" },
        { key: "barHeight", tab: 0, cat: "Bar & Layout", title: "Bar Height", subtitle: "Height of the bar in pixels" },
        { key: "barMargin", tab: 0, cat: "Bar & Layout", title: "Outer Margin (Gaps)", subtitle: "Distance between the screen edge and the pills" },
        { key: "cornerRadius", tab: 0, cat: "Bar & Layout", title: "Corner Radius", subtitle: "Border radius of pills, popups and panels" },
        { key: "showSeparators", tab: 0, cat: "Bar & Layout", title: "Show Separators", subtitle: "Subtle vertical lines between bar modules" },
        { key: "animationDuration", tab: 0, cat: "Bar & Layout", title: "Animation Speed", subtitle: "Duration of menu and popup animations" },
        { key: "showSeconds", tab: 1, cat: "Modules", title: "Show Seconds in Clock", subtitle: "Expand display to HH:MM:SS" },
        { key: "use12HourClock", tab: 1, cat: "Modules", title: "12-Hour Time Format (AM/PM)", subtitle: "Use 12-hour format instead of 24-hour" },
        { key: "showDate", tab: 1, cat: "Modules", title: "Show Date Next to Time", subtitle: "Show day and month next to the clock in the center" },
        { key: "showNetworkName", tab: 1, cat: "Modules", title: "Show Wi-Fi Network Name", subtitle: "Show SSID next to the icon in the bar" },
        { key: "showBatteryPercentage", tab: 1, cat: "Modules", title: "Show Battery Percentage", subtitle: "Show percentage next to the battery icon" },
        { key: "activeWorkspacesCount", tab: 1, cat: "Modules", title: "Workspace Count", subtitle: "Maximum number of workspace buttons in the bar" },
        { key: "matugenPalette", tab: 2, cat: "Theme & Colors", title: "Matugen Color Palette", subtitle: "Live preview of primary and secondary colors" },
        { key: "matugenMode", tab: 2, cat: "Theme & Colors", title: "Matugen Color Mode", subtitle: "Switch between dark and light Material You theme" },
        { key: "matugenScheme", tab: 2, cat: "Theme & Colors", title: "Matugen Palette Style", subtitle: "Color saturation and contrast of generated colors" },
        { key: "nightLightTemp", tab: 2, cat: "Theme & Colors", title: "Night Light Temperature", subtitle: "Color warmth when Night Light is active" },
        { key: "panelOpacity", tab: 2, cat: "Theme & Colors", title: "Panel Transparency", subtitle: "Opacity of bar pills and Quick Settings" },
        { key: "wallpaperMatugen", tab: 2, cat: "Theme & Colors", title: "Wallpaper & Matugen Colors", subtitle: "Open the wallpaper picker to switch the color scheme" },
        { key: "hyprGapsOut", tab: 3, cat: "Hyprland", title: "Hyprland Gaps Out", subtitle: "Space between windows and the screen edge (live)" },
        { key: "hyprBorderSize", tab: 3, cat: "Hyprland", title: "Window Border Size", subtitle: "Thickness of active and inactive Hyprland borders (live)" },
        { key: "hyprRounding", tab: 3, cat: "Hyprland", title: "Hyprland Window Rounding", subtitle: "Corner rounding of application windows (live)" },
        { key: "hyprBlurSize", tab: 3, cat: "Hyprland", title: "Hyprland Blur Size", subtitle: "Strength of background blur behind transparent windows" },
        { key: "hyprBlurPasses", tab: 3, cat: "Hyprland", title: "Hyprland Blur Passes", subtitle: "Number of blur passes (higher = softer, more GPU)" },
        { key: "hyprInactiveOpacity", tab: 3, cat: "Hyprland", title: "Inactive Window Opacity", subtitle: "Opacity of unfocused windows" },
        { key: "hyprAnimations", tab: 3, cat: "Hyprland", title: "Hyprland Animations", subtitle: "Enable or disable window and workspace animations" },
        { key: "hyprReload", tab: 3, cat: "Hyprland", title: "Reload Hyprland Lua Config", subtitle: "Reloads hyprland.lua & luaconfs and reapplies live tweaks" },
        { key: "hyprOpenConfig", tab: 3, cat: "Hyprland", title: "Open Main Config (hyprland.lua)", subtitle: "Open /home/syd/.config/hypr/hyprland.lua in your editor" },
        { key: "keybindsEdit", tab: 4, cat: "Keybinds", title: "Edit Keybinds File (keybinds.lua)", subtitle: "Open /home/syd/.config/hypr/luaconfs/keybinds.lua" },
        { key: "sysInfo", tab: 5, cat: "System", title: "Quickshell Desktop Shell System Info", subtitle: "View CPU, Kernel, RAM and Uptime" },
        { key: "copySettings", tab: 5, cat: "System", title: "Copy Settings to Clipboard", subtitle: "Copy full settings.json backup with wl-copy" },
        { key: "restartQuickshell", tab: 5, cat: "System", title: "Restart Quickshell", subtitle: "Restart the full shell if a component freezes" },
        { key: "openSettingsFile", tab: 5, cat: "System", title: "Open Settings File", subtitle: "View ~/.local/state/quickshell/settings.json" }
    ]

    function item(key) {
        for (let i = 0; i < settingCatalog.length; i++) {
            if (settingCatalog[i].key === key) return settingCatalog[i];
        }
        return { title: key, subtitle: "" };
    }

    // System info & keybinds[cite: 5]
    property string sysKernel: "Loading..."
    property string sysUptime: "Loading..."
    property string sysCpu: "Loading..."
    property string sysRam: "Loading..."
    property var parsedKeybinds: []

    IpcHandler {
        target: "settings"
        function toggle(): void { SettingsState.toggle(); }
    }

    anchors { top: true; bottom: true; left: true; right: true }

    property real animProgress: SettingsState.settingsVisible ? 1.0 : 0.0
    Behavior on animProgress {
        NumberAnimation {
            duration: SettingsState.settingsVisible ? 280 : 180
            easing.type: SettingsState.settingsVisible ? Easing.OutBack : Easing.InCubic
            easing.overshoot: 1.08
        }
    }

    visible: SettingsState.settingsVisible || animProgress > 0.01
    mask: Region { item: SettingsState.settingsVisible ? maskCover : null }
    Item { id: maskCover; anchors.fill: parent }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: SettingsState.settingsVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-settings"

    function restartProcess(proc) {
        proc.running = false;
        proc.running = true;
    }

    function clearSearch() {
        searchInput.text = "";
        root.searchQuery = "";
    }

    function matchesSearch(titleText, subtitleText) {
        if (root.searchQuery === "") return true;
        const q = root.searchQuery.toLowerCase();
        return titleText.toLowerCase().includes(q) || subtitleText.toLowerCase().includes(q);
    }

    Connections {
        target: SettingsState
        function onSettingsVisibleChanged() {
            if (SettingsState.settingsVisible) {
                root.restartProcess(sysInfoProc);
                root.restartProcess(keybindsProc);
            }
        }
    }

    Process { id: matugenProc }

    function applyMatugen() {
        const cmd =
            "WP=$(grep -oE '\"[^\"]+\\.(png|jpg|jpeg|webp)\"' /home/syd/.config/hypr/luaconfs/curwall.lua 2>/dev/null | tr -d '\"' | head -n1); " +
            "[ -z \"$WP\" ] && WP=$(swww query 2>/dev/null | grep -oP 'image: \\K.*' | head -n1); " +
            "[ -z \"$WP\" ] && WP=$(hyprctl hyprpaper listactive 2>/dev/null | awk '{print $NF}' | head -n1); " +
            "if [ -n \"$WP\" ]; then matugen image \"$WP\" -m " + SettingsState.matugenMode + " -t " + SettingsState.matugenScheme + "; fi";
        matugenProc.command = ["bash", "-c", cmd];
        root.restartProcess(matugenProc);
    }

    Process {
        id: sysInfoProc
        running: true
        command: ["bash", "-c",
            "echo \"KERNEL=$(uname -r)\"; " +
            "echo \"UPTIME=$(uptime -p | sed 's/^up //')\"; " +
            "echo \"CPU=$(grep -m1 'model name' /proc/cpuinfo | cut -d':' -f2 | xargs)\"; " +
            "echo \"RAM=$(free -h | awk '/^Mem:/ {print $3 \" / \" $2}')\""
        ]
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("KERNEL=")) root.sysKernel = line.substring(7);
                else if (line.startsWith("UPTIME=")) root.sysUptime = line.substring(7);
                else if (line.startsWith("CPU=")) root.sysCpu = line.substring(4);
                else if (line.startsWith("RAM=")) root.sysRam = line.substring(4);
            }
        }
    }

    Process {
        id: keybindsProc
        running: true
        property string rawBuffer: ""
        onStarted: rawBuffer = ""
        command: ["python3", "-c",
            "import os, re, json\n" +
            "path = '/home/syd/.config/hypr/luaconfs/keybinds.lua'\n" +
            "res = []\n" +
            "if os.path.isfile(path):\n" +
            "    with open(path, 'r', encoding='utf-8', errors='ignore') as f:\n" +
            "        content = f.read()\n" +
            "    m_mod = re.search(r'local\\s+mainMod\\s*=\\s*[\"\\']([^\"\\']+)[\"\\']', content)\n" +
            "    main_mod = m_mod.group(1) if m_mod else 'SUPER'\n" +
            "    for line in content.splitlines():\n" +
            "        s = line.strip()\n" +
            "        if not s or s.startswith('--'): continue\n" +
            "        m = re.match(r'^hl\\.bind[a-z]*\\s*\\((.+)\\)\\s*$', s)\n" +
            "        if m:\n" +
            "            parts = m.group(1).split(',', 1)\n" +
            "            if len(parts) == 2:\n" +
            "                raw_combo, raw_act = parts[0].strip(), parts[1].strip()\n" +
            "                combo = raw_combo.replace('mainMod', main_mod).replace('..', '').replace('\"', '').replace(\"'\", '')\n" +
            "                combo = re.sub(r'\\s+', ' ', combo).strip()\n" +
            "                m_cmd = re.search(r'exec_cmd\\s*\\(\\s*([\"\\']?)(.*?)\\1\\s*\\)', raw_act)\n" +
            "                action = m_cmd.group(2) if m_cmd else re.sub(r'^hl\\.dsp\\.', '', raw_act).rstrip(')')\n" +
            "                res.append({'combo': combo, 'action': action})\n" +
            "print(json.dumps(res))"
        ]
        stdout: SplitParser { onRead: line => keybindsProc.rawBuffer += line }
        onExited: {
            try { root.parsedKeybinds = JSON.parse(keybindsProc.rawBuffer); }
            catch (e) { root.parsedKeybinds = []; }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.40 * root.animProgress)
        MouseArea {
            anchors.fill: parent
            enabled: SettingsState.settingsVisible
            onClicked: SettingsState.hide()
        }
    }

    Rectangle {
        id: windowCard
        anchors.centerIn: parent
        anchors.verticalCenterOffset: (1.0 - root.animProgress) * 20
        width: 860
        height: 590
        radius: 16
        opacity: Math.min(1.0, root.animProgress * 1.3)
        scale: 0.94 + (0.06 * root.animProgress)
        color: Qt.alpha(MatuColors.md3.surface, 0.96)
        border.color: MatuColors.md3.primary
        border.width: 2

        focus: true
        Keys.onEscapePressed: root.searchQuery !== "" ? root.clearSearch() : SettingsState.hide()

        MouseArea { anchors.fill: parent; onClicked: {} }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Left Sidebar ───────────────────────────────────────────────
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 240
                color: Qt.alpha(MatuColors.md3.surface_container, 0.7)
                radius: 14

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        text: "Settings"
                        color: MatuColors.md3.on_surface
                        font { family: root.uiFont; pixelSize: 16; bold: true }
                        Layout.leftMargin: 6
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        Layout.bottomMargin: 6
                        radius: 10
                        color: Qt.alpha(MatuColors.md3.on_surface, 0.06)
                        border.color: searchInput.activeFocus ? MatuColors.md3.primary : Qt.alpha(MatuColors.md3.on_surface, 0.14)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                text: "󰍉"
                                color: searchInput.activeFocus ? MatuColors.md3.primary : MatuColors.md3.on_surface_variant
                                font { family: root.uiFont; pixelSize: 14 }
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                color: MatuColors.md3.on_surface
                                font { family: root.uiFont; pixelSize: 12 }
                                clip: true
                                selectByMouse: true
                                onTextChanged: root.searchQuery = text

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Search..."
                                    color: MatuColors.md3.on_surface_variant
                                    opacity: 0.65
                                    font { family: root.uiFont; pixelSize: 12 }
                                    visible: searchInput.text === ""
                                }
                            }
                        }
                    }

                    Repeater {
                        model: root.tabs

                        Rectangle {
                            id: navItem
                            readonly property bool isActive: root.searchQuery === "" && root.currentTab === index

                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 10
                            opacity: root.searchQuery === "" ? 1.0 : 0.45
                            color: isActive
                                   ? Qt.alpha(MatuColors.md3.primary, 0.25)
                                   : (navMa.containsMouse ? Qt.alpha(MatuColors.md3.on_surface, 0.06) : "transparent")
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                visible: navItem.isActive
                                width: 3
                                height: 18
                                radius: 2
                                color: MatuColors.md3.primary
                                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                            }

                            Row {
                                anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 14 }
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    color: navItem.isActive ? MatuColors.md3.primary : MatuColors.md3.on_surface_variant
                                    font { family: root.uiFont; pixelSize: 15 }
                                }
                                Text {
                                    text: modelData.label
                                    color: MatuColors.md3.on_surface
                                    font { family: root.uiFont; pixelSize: 13; bold: navItem.isActive }
                                }
                            }

                            MouseArea {
                                id: navMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.clearSearch();
                                    root.currentTab = index;
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 10
                        color: resetMa.containsMouse ? Qt.alpha(MatuColors.md3.error, 0.20) : Qt.alpha(MatuColors.md3.on_surface, 0.05)

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰑓"; color: MatuColors.md3.error; font { family: root.uiFont; pixelSize: 14 } }
                            Text { text: "Reset To Defaults"; color: MatuColors.md3.on_surface; font { family: root.uiFont; pixelSize: 12 } }
                        }

                        MouseArea {
                            id: resetMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SettingsState.resetDefaults()
                        }
                    }
                }
            }

            // ── Right Content Area ─────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 24
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.searchQuery !== ""
                              ? ("Search results for \"" + root.searchQuery + "\"")
                              : root.tabs[root.currentTab].label
                        color: MatuColors.md3.on_surface
                        font { family: root.uiFont; pixelSize: 18; bold: true }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 30; height: 30; radius: 8
                        color: closeMa.containsMouse ? Qt.alpha(MatuColors.md3.error, 0.25) : Qt.alpha(MatuColors.md3.on_surface, 0.08)
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: MatuColors.md3.on_surface
                            font { family: root.uiFont; pixelSize: 14 }
                        }
                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SettingsState.hide()
                        }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: allTabsColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: allTabsColumn
                        width: parent.width
                        spacing: 10

                        // ── TAB 0: Bar & Layout ────────────────────────────
                        ColumnLayout {
                            visible: root.searchQuery === "" && root.currentTab === 0
                            Layout.fillWidth: true
                            spacing: 10

                            SettingChoiceRow {
                                readonly property var meta: root.item("preset")
                                title: meta.title
                                subtitle: meta.subtitle
                                options: [
                                    { label: "Default", value: "default" },
                                    { label: "Minimal", value: "minimal" },
                                    { label: "Glass", value: "glass" },
                                    { label: "Dock", value: "dock" }
                                ]
                                currentValue: SettingsState.activePreset
                                onSelected: v => SettingsState.applyPreset(v)
                            }
                            SettingChoiceRow {
                                readonly property var meta: root.item("barPosition")
                                title: meta.title
                                subtitle: meta.subtitle
                                options: [
                                    { label: "Top", value: "top" },
                                    { label: "Bottom", value: "bottom" }
                                ]
                                currentValue: SettingsState.barPosition
                                onSelected: v => { SettingsState.barPosition = v; SettingsState.save(); }
                            }

                            SettingSliderRow {
                                readonly property var meta: root.item("barHeight")
                                title: meta.title
                                subtitle: meta.subtitle
                                from: 34; to: 60; stepSize: 1
                                value: SettingsState.barHeight
                                unit: "px"
                                onValueEdited: v => { SettingsState.barHeight = v; SettingsState.save(); }
                            }

                            SettingSliderRow {
                                readonly property var meta: root.item("barMargin")
                                title: meta.title
                                subtitle: meta.subtitle
                                from: 0; to: 16; stepSize: 1
                                value: SettingsState.barMargin
                                unit: "px"
                                onValueEdited: v => { SettingsState.barMargin = v; SettingsState.save(); }
                            }

                            SettingSliderRow {
                                readonly property var meta: root.item("cornerRadius")
                                title: meta.title
                                subtitle: meta.subtitle
                                from: 0; to: 24; stepSize: 1
                                value: SettingsState.cornerRadius
                                unit: "px"
                                onValueEdited: v => { SettingsState.cornerRadius = v; SettingsState.save(); }
                            }

                            SettingToggleRow {
                                readonly property var meta: root.item("showSeparators")
                                title: meta.title
                                subtitle: meta.subtitle
                                checked: SettingsState.showSeparators
                                onToggled: v => { SettingsState.showSeparators = v; SettingsState.save(); }
                            }

                            SettingSliderRow {
                                readonly property var meta: root.item("animationDuration")
                                title: meta.title
                                subtitle: meta.subtitle
                                from: 80; to: 450; stepSize: 20
                                value: SettingsState.animationDuration
                                unit: "ms"
                                onValueEdited: v => { SettingsState.animationDuration = v; SettingsState.save(); }
                            }
                        }

                        // ── TAB 1: Modules ───────────────────────────────────
                        ColumnLayout {
                            visible: root.searchQuery === "" && root.currentTab === 1
                            Layout.fillWidth: true
                            spacing: 10

                            SettingToggleRow {
                                readonly property var meta: root.item("showSeconds")
                                title: meta.title
                                subtitle: meta.subtitle
                                checked: SettingsState.showSeconds
                                onToggled: v => { SettingsState.showSeconds = v; SettingsState.save(); }
                            }

                            SettingToggleRow {
                                readonly property var meta: root.item("use12HourClock")
                                title: meta.title
                                subtitle: meta.subtitle
                                checked: SettingsState.use12HourClock
                                onToggled: v => { SettingsState.use12HourClock = v; SettingsState.save(); }
                            }

                            SettingToggleRow {
                                readonly property var meta: root.item("showDate")
                                title: meta.title
                                subtitle: meta.subtitle
                                checked: SettingsState.showDate
                                onToggled: v => { SettingsState.showDate = v; SettingsState.save(); }
                            }

                            SettingToggleRow {
                                readonly property var meta: root.item("showNetworkName")
                                title: meta.title
                                subtitle: meta.subtitle
                                checked: SettingsState.showNetworkName
                                onToggled: v => { SettingsState.showNetworkName = v; SettingsState.save(); }
                            }

                            SettingToggleRow {
                                readonly property var meta: root.item("showBatteryPercentage")
                                title: meta.title
                                subtitle: meta.subtitle
                                checked: SettingsState.showBatteryPercentage
                                onToggled: v => { SettingsState.showBatteryPercentage = v; SettingsState.save(); }
                            }

                            SettingSliderRow {
                                readonly property var meta: root.item("activeWorkspacesCount")
                                title: meta.title
                                subtitle: meta.subtitle
                                from: 4; to: 10; stepSize: 1
                                value: SettingsState.activeWorkspacesCount
                                unit: ""
                                onValueEdited: v => { SettingsState.activeWorkspacesCount = v; SettingsState.save(); }
                            }
                        }

                        // ── TAB 2: Theme & Colors ────────────────────────────
                        ColumnLayout {
                            visible: root.searchQuery === "" && root.currentTab === 2
                            Layout.fillWidth: true
                            spacing: 10

                            SettingCard {
                                Layout.preferredHeight: 68
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 12

                                    readonly property var meta: root.item("matugenPalette")
                                    SettingLabels {
                                        title: parent.meta.title
                                        subtitle: parent.meta.subtitle
                                    }

                                    Row {
                                        spacing: 8
                                        Repeater {
                                            model: [
                                                { c: MatuColors.md3.primary, lbl: "P" },
                                                { c: MatuColors.md3.secondary, lbl: "S" },
                                                { c: MatuColors.md3.tertiary, lbl: "T" },
                                                { c: MatuColors.md3.error, lbl: "E" }
                                            ]
                                            Rectangle {
                                                width: 28; height: 28; radius: 14
                                                color: modelData.c
                                                border.color: Qt.alpha(MatuColors.md3.on_surface, 0.25)
                                                border.width: 1
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.lbl
                                                    color: MatuColors.md3.on_primary
                                                    font { family: root.uiFont; pixelSize: 11; bold: true }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            SettingChoiceRow {
                                readonly property var meta: root.item("matugenMode")
                                title: meta.title
                                subtitle: meta.subtitle
                                options: [
                                    { label: "Dark", value: "dark" },
                                    { label: "Light", value: "light" }
                                ]
                                currentValue: SettingsState.matugenMode
                                onSelected: v => {
                                    SettingsState.matugenMode = v;
                                    SettingsState.save();
                                    root.applyMatugen();
                                }
                            }

                            SettingChoiceRow {
                                readonly property var meta: root.item("matugenScheme")
                                title: meta.title
                                subtitle: meta.subtitle
                                options: [
                                    { label: "Tonal", value: "scheme-tonal-spot" },
                                    { label: "Vibrant", value: "scheme-vibrant" },
                                    { label: "Mono", value: "scheme-monochrome" }
                                ]
                                currentValue: SettingsState.matugenScheme
                                onSelected: v => {
                                    SettingsState.matugenScheme = v;
                                    SettingsState.save();
                                    root.applyMatugen();
                                }
                            }

                            SettingSliderRow {
                                readonly property var meta: root.item("nightLightTemp")
                                title: meta.title
                                subtitle: meta.subtitle
                                from: 2500; to: 6000; stepSize: 100
                                value: SettingsState.nightLightTemp
                                unit: "K"
                                onValueEdited: v => {
                                    SettingsState.nightLightTemp = Math.round(v);
                                    SettingsState.save();
                                    SettingsState.applyNightLight();
                                }
                            }

                            SettingSliderRow {
                                readonly property var meta: root.item("panelOpacity")
                                title: meta.title
                                subtitle: meta.subtitle
                                from: 50; to: 100; stepSize: 2
                                value: Math.round(SettingsState.panelOpacity * 100)
                                unit: "%"
                                onValueEdited: v => { SettingsState.panelOpacity = v / 100.0; SettingsState.save(); }
                            }

                            SettingActionRow {
                                readonly property var meta: root.item("wallpaperMatugen")
                                title: meta.title
                                subtitle: meta.subtitle
                                buttonText: "Open"
                                onTriggered: {
                                    SettingsState.hide();
                                    Quickshell.execDetached(["qs", "ipc", "call", "themeswitcher", "toggle"]);
                                }
                            }
                        }

                        // ── TAB 3: Hyprland ──────────────────────────────────
                        ColumnLayout {
                            visible: root.searchQuery === "" && root.currentTab === 3
                            Layout.fillWidth: true
                            spacing: 10

                            SettingSliderRow {
                                readonly property var meta: root.item("hyprGapsOut")
                                title: meta.title
                                subtitle: meta.subtitle
                                from: 0; to: 32; stepSize: 2
                                value: SettingsState.hyprGapsOut
                                unit: "px"
                                onValueEdited: v => {
                                    SettingsState.hyprGapsOut = Math.round(v);
                                    SettingsState.save();
                                    SettingsState.syncHyprland();
                                }
                            }

                            SettingSliderRow {
                                readonly property var meta: root.item("hyprBorderSize")
                                title: meta.title
                                subtitle: meta.subtitle
                                from: 0; to: 6; stepSize: 1
                                value: SettingsState.hyprBorderSize
                                unit: "px"
                                onValueEdited: v => {
                                    SettingsState.hyprBorderSize = Math.round(v);
                                    SettingsState.save();
                                    SettingsState.syncHyprland();
                                }
                            }

                            SettingSliderRow {
                                readonly property var meta: root.item("hyprRounding")
                                title: meta.title
                                subtitle: meta.subtitle
                                from: 0; to: 24; stepSize: 1
                                value: SettingsState.hyprRounding
                                unit: "px"
                                onValueEdited: v => {
                                    SettingsState.hyprRounding = Math.round(v);
                                    SettingsState.save();
                                    SettingsState.syncHyprland();
                                }
                            }

                            SettingSliderRow {
                                readonly property var meta: root.item("hyprBlurSize")
                                title: meta.title
                                subtitle: meta.subtitle
                                from: 1; to: 16; stepSize: 1
                                value: SettingsState.hyprBlurSize
                                unit: "px"
                                onValueEdited: v => {
                                    SettingsState.hyprBlurSize = Math.round(v);
                                    SettingsState.save();
                                    SettingsState.syncHyprland();
                                }
                            }

                            SettingSliderRow {
                                readonly property var meta: root.item("hyprBlurPasses")
                                title: meta.title
                                subtitle: meta.subtitle
                                from: 1; to: 5; stepSize: 1
                                value: SettingsState.hyprBlurPasses
                                unit: "x"
                                onValueEdited: v => {
                                    SettingsState.hyprBlurPasses = Math.round(v);
                                    SettingsState.save();
                                    SettingsState.syncHyprland();
                                }
                            }

                            SettingSliderRow {
                                readonly property var meta: root.item("hyprInactiveOpacity")
                                title: meta.title
                                subtitle: meta.subtitle
                                from: 60; to: 100; stepSize: 2
                                value: Math.round(SettingsState.hyprInactiveOpacity * 100)
                                unit: "%"
                                onValueEdited: v => {
                                    SettingsState.hyprInactiveOpacity = v / 100.0;
                                    SettingsState.save();
                                    SettingsState.syncHyprland();
                                }
                            }

                            SettingToggleRow {
                                readonly property var meta: root.item("hyprAnimations")
                                title: meta.title
                                subtitle: meta.subtitle
                                checked: SettingsState.hyprAnimations
                                onToggled: v => {
                                    SettingsState.hyprAnimations = v;
                                    SettingsState.save();
                                    SettingsState.syncHyprland();
                                }
                            }

                            SettingActionRow {
                                readonly property var meta: root.item("hyprReload")
                                title: meta.title
                                subtitle: meta.subtitle
                                buttonText: "Reload"
                                onTriggered: {
                                    Quickshell.execDetached(["bash", "-c", "export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t \"$XDG_RUNTIME_DIR/hypr\" 2>/dev/null | head -n1); hyprctl reload"]);
                                    SettingsState.syncHyprland();
                                }
                            }

                            SettingActionRow {
                                readonly property var meta: root.item("hyprOpenConfig")
                                title: meta.title
                                subtitle: meta.subtitle
                                buttonText: "Open Lua"
                                onTriggered: Quickshell.execDetached(["xdg-open", "/home/syd/.config/hypr/hyprland.lua"])
                            }
                        }

                        // ── TAB 4: Keybinds ──────────────────────────────────
                        ColumnLayout {
                            visible: root.searchQuery === "" && root.currentTab === 4
                            Layout.fillWidth: true
                            spacing: 8

                            SettingActionRow {
                                readonly property var meta: root.item("keybindsEdit")
                                title: meta.title
                                subtitle: meta.subtitle
                                buttonText: "Open Lua"
                                onTriggered: Quickshell.execDetached(["xdg-open", "/home/syd/.config/hypr/luaconfs/keybinds.lua"])
                            }

                            Text {
                                visible: root.parsedKeybinds.length === 0
                                text: "No keybinds found in /home/syd/.config/hypr/luaconfs/keybinds.lua"
                                color: MatuColors.md3.on_surface_variant
                                font { family: root.uiFont; pixelSize: 12 }
                            }

                            Repeater {
                                model: root.parsedKeybinds

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                    radius: 10
                                    color: MatuColors.md3.surface_container

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                                        spacing: 12

                                        Rectangle {
                                            Layout.preferredWidth: comboLbl.implicitWidth + 18
                                            Layout.preferredHeight: 28
                                            radius: 7
                                            color: Qt.alpha(MatuColors.md3.primary, 0.20)
                                            border.color: Qt.alpha(MatuColors.md3.primary, 0.45)
                                            border.width: 1

                                            Text {
                                                id: comboLbl
                                                anchors.centerIn: parent
                                                text: modelData.combo
                                                color: MatuColors.md3.primary
                                                font { family: root.uiFont; pixelSize: 11; bold: true }
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.action
                                            color: MatuColors.md3.on_surface
                                            font { family: root.uiFont; pixelSize: 12 }
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }

                        // ── TAB 5: System ────────────────────────────────────
                        ColumnLayout {
                            visible: root.searchQuery === "" && root.currentTab === 5
                            Layout.fillWidth: true
                            spacing: 10

                            SettingCard {
                                Layout.preferredHeight: 118
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 6

                                    Text {
                                        text: root.item("sysInfo").title
                                        color: MatuColors.md3.primary
                                        font { family: root.uiFont; pixelSize: 14; bold: true }
                                    }
                                    Text {
                                        text: "CPU: " + root.sysCpu
                                        color: MatuColors.md3.on_surface
                                        font { family: root.uiFont; pixelSize: 11 }
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: "Kernel: " + root.sysKernel + "  •  RAM: " + root.sysRam
                                        color: MatuColors.md3.on_surface_variant
                                        font { family: root.uiFont; pixelSize: 11 }
                                    }
                                    Text {
                                        text: "Uptime: " + root.sysUptime
                                        color: MatuColors.md3.on_surface_variant
                                        font { family: root.uiFont; pixelSize: 11 }
                                    }
                                }
                            }

                            SettingActionRow {
                                readonly property var meta: root.item("copySettings")
                                title: meta.title
                                subtitle: meta.subtitle
                                buttonText: "Copy"
                                onTriggered: Quickshell.execDetached(["bash", "-c", "wl-copy < \"" + SettingsState.statePath + "\""])
                            }

                            SettingActionRow {
                                readonly property var meta: root.item("restartQuickshell")
                                title: meta.title
                                subtitle: meta.subtitle
                                buttonText: "Restart"
                                onTriggered: Quickshell.execDetached(["bash", "-c", "qs kill; sleep 0.2; quickshell &"])
                            }

                            SettingActionRow {
                                readonly property var meta: root.item("openSettingsFile")
                                title: meta.title
                                subtitle: meta.subtitle
                                buttonText: "Open JSON"
                                onTriggered: Quickshell.execDetached(["zeditor", SettingsState.statePath])
                            }
                        }

                        // ── MASTER SEARCH RESULTS LIST (CLICKABLE) ───────────
                        ColumnLayout {
                            visible: root.searchQuery !== ""
                            Layout.fillWidth: true
                            spacing: 10

                            Repeater {
                                model: root.settingCatalog

                                delegate: Rectangle {
                                    visible: root.matchesSearch(modelData.title, modelData.subtitle)
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 58
                                    radius: 12
                                    color: resMa.containsMouse
                                           ? Qt.alpha(MatuColors.md3.primary, 0.16)
                                           : MatuColors.md3.surface_container
                                    border.color: resMa.containsMouse
                                                  ? MatuColors.md3.primary
                                                  : Qt.alpha(MatuColors.md3.on_surface, 0.10)
                                    border.width: 1

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                                        spacing: 12

                                        SettingLabels {
                                            title: modelData.title
                                            subtitle: modelData.subtitle
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: catTxt.implicitWidth + 18
                                            Layout.preferredHeight: 26
                                            radius: 7
                                            color: Qt.alpha(MatuColors.md3.primary, 0.20)

                                            Text {
                                                id: catTxt
                                                anchors.centerIn: parent
                                                text: modelData.cat + " 󰁔"
                                                color: MatuColors.md3.primary
                                                font { family: root.uiFont; pixelSize: 11; bold: true }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: resMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.currentTab = modelData.tab;
                                            root.clearSearch();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Reusable components (at root level)[cite: 5] ───────────────────────
    component SettingCard: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 58
        radius: 12
        color: MatuColors.md3.surface_container
    }

    component SettingLabels: Column {
        property string title: ""
        property string subtitle: ""

        Layout.fillWidth: true
        spacing: 2

        Text {
            text: parent.title
            color: MatuColors.md3.on_surface
            font { family: root.uiFont; pixelSize: 13; bold: true }
        }
        Text {
            text: parent.subtitle
            color: MatuColors.md3.on_surface_variant
            font { family: root.uiFont; pixelSize: 11 }
            elide: Text.ElideRight
            width: parent.width
        }
    }

    component SettingToggleRow: SettingCard {
        id: toggleRow
        property string title: ""
        property string subtitle: ""
        property bool checked: false
        signal toggled(bool value)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            SettingLabels { title: toggleRow.title; subtitle: toggleRow.subtitle }
            Rectangle {
                width: 44; height: 24; radius: 12
                color: toggleRow.checked ? MatuColors.md3.primary : Qt.alpha(MatuColors.md3.on_surface, 0.2)
                Behavior on color { ColorAnimation { duration: 150 } }
                Rectangle {
                    width: 18; height: 18; radius: 9; y: 3
                    x: toggleRow.checked ? 23 : 3
                    color: toggleRow.checked ? MatuColors.md3.on_primary : MatuColors.md3.on_surface
                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toggleRow.toggled(!toggleRow.checked)
                }
            }
        }
    }

    component SettingSliderRow: Slider {
        id: sliderRoot
        property string title: ""
        property string subtitle: ""
        property string unit: ""
        signal valueEdited(real newValue)

        Layout.fillWidth: true
        Layout.preferredHeight: 62
        hoverEnabled: true

        HoverHandler { cursorShape: Qt.PointingHandCursor }
        onMoved: valueEdited(value)
        handle: Item {}

        background: Rectangle {
            radius: 12
            color: MatuColors.md3.surface_container
            border.color: sliderRoot.pressed
                          ? MatuColors.md3.primary
                          : (sliderRoot.hovered ? Qt.alpha(MatuColors.md3.on_surface, 0.25) : Qt.alpha(MatuColors.md3.on_surface, 0.12))
            border.width: 1
            clip: true
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Rectangle {
                width: sliderRoot.visualPosition * parent.width
                height: parent.height
                radius: parent.radius
                color: Qt.alpha(MatuColors.md3.primary, sliderRoot.pressed ? 0.32 : 0.22)
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                spacing: 12

                SettingLabels { title: sliderRoot.title; subtitle: sliderRoot.subtitle }

                Rectangle {
                    Layout.preferredWidth: valTxt.implicitWidth + 18
                    Layout.preferredHeight: 28
                    radius: 8
                    color: Qt.alpha(MatuColors.md3.primary, 0.20)
                    border.color: Qt.alpha(MatuColors.md3.primary, 0.45)
                    border.width: 1

                    Text {
                        id: valTxt
                        anchors.centerIn: parent
                        text: Math.round(sliderRoot.value) + sliderRoot.unit
                        color: MatuColors.md3.primary
                        font { family: root.uiFont; pixelSize: 12; bold: true }
                    }
                }
            }
        }
    }

    component SettingChoiceRow: SettingCard {
        id: choiceRow
        property string title: ""
        property string subtitle: ""
        property var options: []
        property string currentValue: ""
        signal selected(string value)

        Layout.preferredHeight: 62

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            SettingLabels { title: choiceRow.title; subtitle: choiceRow.subtitle }
            Row {
                spacing: 6
                Repeater {
                    model: choiceRow.options
                    delegate: Rectangle {
                        id: choiceBtn
                        readonly property bool isChosen: choiceRow.currentValue === modelData.value
                        height: 30
                        width: choiceTxt.implicitWidth + 20
                        radius: 8
                        color: choiceBtn.isChosen ? MatuColors.md3.primary : Qt.alpha(MatuColors.md3.on_surface, 0.08)
                        Text {
                            id: choiceTxt
                            anchors.centerIn: parent
                            text: modelData.label
                            color: choiceBtn.isChosen ? MatuColors.md3.on_primary : MatuColors.md3.on_surface
                            font { family: root.uiFont; pixelSize: 11; bold: choiceBtn.isChosen }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: choiceRow.selected(modelData.value)
                        }
                    }
                }
            }
        }
    }

    component SettingActionRow: SettingCard {
        id: actionRow
        property string title: ""
        property string subtitle: ""
        property string buttonText: "Run"
        signal triggered()

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            SettingLabels { title: actionRow.title; subtitle: actionRow.subtitle }
            Rectangle {
                width: btnLbl.implicitWidth + 24
                height: 32
                radius: 8
                color: actionMa.containsMouse ? Qt.lighter(MatuColors.md3.primary, 1.1) : MatuColors.md3.primary
                Text {
                    id: btnLbl
                    anchors.centerIn: parent
                    text: actionRow.buttonText
                    color: MatuColors.md3.on_primary
                    font { family: root.uiFont; pixelSize: 12; bold: true }
                }
                MouseArea {
                    id: actionMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: actionRow.triggered()
                }
            }
        }
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool settingsVisible: false
    function toggle() { settingsVisible = !settingsVisible; }
    function show() { settingsVisible = true; }
    function hide() { settingsVisible = false; }

    // ── Balk & Layout instellingen ───────────────────────────────────────────
    property int barHeight: 45
    property int barMargin: 4
    property int cornerRadius: 16
    property real panelOpacity: 0.88
    property string barPosition: "top" // "top" of "bottom"
    property bool showSeparators: true
    property int animationDuration: 220

    // ── Module instellingen ──────────────────────────────────────────────────
    property bool showSeconds: false
    property bool use12HourClock: false
    property bool showDate: false
    property bool showNetworkName: true
    property bool showBatteryPercentage: true
    property int activeWorkspacesCount: 9

    // ── Thema & Night Light ──────────────────────────────────────────────────
    property int nightLightTemp: 4000
    property string matugenMode: "dark" // "dark" of "light"
    property string matugenScheme: "scheme-tonal-spot"

    // ── Hyprland Live Tweaks ─────────────────────────────────────────────────
    property int hyprGapsOut: 8
    property int hyprBorderSize: 2
    property int hyprRounding: 12
    property int hyprBlurSize: 6
    property int hyprBlurPasses: 2
    property real hyprInactiveOpacity: 0.92
    property bool hyprAnimations: true

    // ── Presets toepassen ────────────────────────────────────────────────────
    function applyPreset(name) {
        if (name === "minimal") {
            barPosition = "top";
            barHeight = 36;
            barMargin = 2;
            cornerRadius = 10;
            panelOpacity = 0.92;
            showSeparators = false;
            showNetworkName = false;
            showBatteryPercentage = false;
            hyprGapsOut = 4;
            hyprRounding = 8;
        } else if (name === "glass") {
            barPosition = "top";
            barHeight = 46;
            barMargin = 10;
            cornerRadius = 20;
            panelOpacity = 0.72;
            showSeparators = true;
            showNetworkName = true;
            showBatteryPercentage = true;
            hyprGapsOut = 14;
            hyprRounding = 16;
        } else if (name === "dock") {
            barPosition = "bottom";
            barHeight = 44;
            barMargin = 6;
            cornerRadius = 14;
            panelOpacity = 0.88;
            showSeparators = true;
            showNetworkName = true;
            showBatteryPercentage = true;
            hyprGapsOut = 8;
            hyprRounding = 12;
        } else {
            resetDefaults();
            return;
        }
        save();
        syncHyprland();
    }

    function applyNightLight() {
        const temp = Math.round(root.nightLightTemp);
        const cmd =
            "if pgrep -x hyprsunset >/dev/null 2>&1; then " +
            "  if [ -z \"$HYPRLAND_INSTANCE_SIGNATURE\" ]; then " +
            "    export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t \"$XDG_RUNTIME_DIR/hypr\" 2>/dev/null | head -n1); " +
            "  fi; " +
            "  hyprctl hyprsunset temperature " + temp + "; " +
            "fi";
        Quickshell.execDetached(["bash", "-c", cmd]);
    }

    function syncHyprland() {
        const luaContent = "-- Automatisch gegenereerd door Quickshell Settings\n" +
            "hl.config({\n" +
            "    general = {\n" +
            "        gaps_out = " + hyprGapsOut + ",\n" +
            "        border_size = " + hyprBorderSize + ",\n" +
            "    },\n" +
            "    decoration = {\n" +
            "        rounding = " + hyprRounding + ",\n" +
            "        inactive_opacity = " + hyprInactiveOpacity.toFixed(2) + ",\n" +
            "        blur = {\n" +
            "            size = " + hyprBlurSize + ",\n" +
            "            passes = " + hyprBlurPasses + ",\n" +
            "        },\n" +
            "    },\n" +
            "    animations = {\n" +
            "        enabled = " + (hyprAnimations ? "true" : "false") + ",\n" +
            "    },\n" +
            "})\n";

        const luaPath = Quickshell.env("HOME") + "/.config/hypr/luaconfs/quickshell_overrides.lua";

        const cmd = "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"; " +
                    "if [ -z \"$HYPRLAND_INSTANCE_SIGNATURE\" ]; then " +
                    "  export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t \"$XDG_RUNTIME_DIR/hypr\" 2>/dev/null | head -n1); " +
                    "fi; " +
                    "hyprctl --batch \"" +
                    "keyword general:gaps_out " + hyprGapsOut + " ; " +
                    "keyword general:border_size " + hyprBorderSize + " ; " +
                    "keyword decoration:rounding " + hyprRounding + " ; " +
                    "keyword decoration:blur:size " + hyprBlurSize + " ; " +
                    "keyword decoration:blur:passes " + hyprBlurPasses + " ; " +
                    "keyword decoration:inactive_opacity " + hyprInactiveOpacity.toFixed(2) + " ; " +
                    "keyword animations:enabled " + (hyprAnimations ? 1 : 0) + "\"";

        Quickshell.execDetached(["bash", "-c", cmd, "--", luaPath, luaContent]);
    }

    // ── Reset naar standaardwaarden ──────────────────────────────────────────
    function resetDefaults() {
        barHeight = 45;
        barMargin = 4;
        cornerRadius = 16;
        panelOpacity = 0.88;
        barPosition = "top";
        showSeparators = true;
        animationDuration = 220;
        showSeconds = false;
        use12HourClock = false;
        showDate = false;
        showNetworkName = true;
        showBatteryPercentage = true;
        activeWorkspacesCount = 9;
        nightLightTemp = 4000;
        matugenMode = "dark";
        matugenScheme = "scheme-tonal-spot";
        hyprGapsOut = 8;
        hyprBorderSize = 2;
        hyprRounding = 12;
        hyprBlurSize = 6;
        hyprBlurPasses = 2;
        hyprInactiveOpacity = 0.92;
        hyprAnimations = true;
        save();
        syncHyprland();
        applyNightLight();
    }

    // ── Automatisch opslaan & laden in JSON ──────────────────────────────────
    readonly property string statePath: Quickshell.env("HOME") + "/.local/state/quickshell/settings.json"

    property FileView stateFile: FileView {
        path: root.statePath
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data.barHeight !== undefined) root.barHeight = data.barHeight;
                if (data.barMargin !== undefined) root.barMargin = data.barMargin;
                if (data.cornerRadius !== undefined) root.cornerRadius = data.cornerRadius;
                if (data.panelOpacity !== undefined) root.panelOpacity = data.panelOpacity;
                if (data.barPosition !== undefined) root.barPosition = data.barPosition;
                if (data.showSeparators !== undefined) root.showSeparators = data.showSeparators;
                if (data.animationDuration !== undefined) root.animationDuration = data.animationDuration;
                if (data.showSeconds !== undefined) root.showSeconds = data.showSeconds;
                if (data.use12HourClock !== undefined) root.use12HourClock = data.use12HourClock;
                if (data.showDate !== undefined) root.showDate = data.showDate;
                if (data.showNetworkName !== undefined) root.showNetworkName = data.showNetworkName;
                if (data.showBatteryPercentage !== undefined) root.showBatteryPercentage = data.showBatteryPercentage;
                if (data.activeWorkspacesCount !== undefined) root.activeWorkspacesCount = data.activeWorkspacesCount;
                if (data.nightLightTemp !== undefined) root.nightLightTemp = data.nightLightTemp;
                if (data.matugenMode !== undefined) root.matugenMode = data.matugenMode;
                if (data.matugenScheme !== undefined) root.matugenScheme = data.matugenScheme;
                if (data.hyprGapsOut !== undefined) root.hyprGapsOut = data.hyprGapsOut;
                if (data.hyprBorderSize !== undefined) root.hyprBorderSize = data.hyprBorderSize;
                if (data.hyprRounding !== undefined) root.hyprRounding = data.hyprRounding;
                if (data.hyprBlurSize !== undefined) root.hyprBlurSize = data.hyprBlurSize;
                if (data.hyprBlurPasses !== undefined) root.hyprBlurPasses = data.hyprBlurPasses;
                if (data.hyprInactiveOpacity !== undefined) root.hyprInactiveOpacity = data.hyprInactiveOpacity;
                if (data.hyprAnimations !== undefined) root.hyprAnimations = data.hyprAnimations;
                root.syncHyprland();
            } catch (e) {}
        }
    }

    property Process saveProc: Process {
        id: saveProc
    }

    function save() {
        const payload = JSON.stringify({
            barHeight: root.barHeight,
            barMargin: root.barMargin,
            cornerRadius: root.cornerRadius,
            panelOpacity: root.panelOpacity,
            barPosition: root.barPosition,
            showSeparators: root.showSeparators,
            animationDuration: root.animationDuration,
            showSeconds: root.showSeconds,
            use12HourClock: root.use12HourClock,
            showDate: root.showDate,
            showNetworkName: root.showNetworkName,
            showBatteryPercentage: root.showBatteryPercentage,
            activeWorkspacesCount: root.activeWorkspacesCount,
            nightLightTemp: root.nightLightTemp,
            matugenMode: root.matugenMode,
            matugenScheme: root.matugenScheme,
            hyprGapsOut: root.hyprGapsOut,
            hyprBorderSize: root.hyprBorderSize,
            hyprRounding: root.hyprRounding,
            hyprBlurSize: root.hyprBlurSize,
            hyprBlurPasses: root.hyprBlurPasses,
            hyprInactiveOpacity: root.hyprInactiveOpacity,
            hyprAnimations: root.hyprAnimations
        }, null, 2);

        saveProc.command = ["bash", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "--", root.statePath, payload];
        saveProc.running = false;
        saveProc.running = true;
    }
}

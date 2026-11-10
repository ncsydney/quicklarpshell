import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "./bar"
import Quickshell.Io
import "./widgets"
import "./power_menu"
import "./quicksettings"
import "./mediaplayer"
ShellRoot {
    // ── Bar ────────────────────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens
        Bar {
            property var modelData
            screen: modelData
        }
    }

    // ── Media Panel Overlay ────────────────────────────────────────────────
        Variants {
            model: Quickshell.screens
            MediaPlayer {
                property var modelData
                screen: modelData
            }
        }
    // ── Volume OSD (auto-shows on PipeWire sink events) ────────────────────
    Variants {
        model: Quickshell.screens
        VolumeOSD {
            property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens
        BrightnessOSD {
            property var modelData
            screen: modelData
        }
    }
    // ── Power menu overlay ─────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens
        PowerMenu {
            property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens
        QuickSettings {
            property var modelData
            screen: modelData
        }
    }
}

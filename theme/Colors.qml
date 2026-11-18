pragma Singleton
import QtQuick

QtObject {
    readonly property color colBg: MatuColors.md3.surface !== "transparent" ? MatuColors.md3.surface : "#201514"
    readonly property color colFg: MatuColors.md3.on_surface !== "transparent" ? MatuColors.md3.on_surface : "#F3E7BF"

    readonly property color colBlack: MatuColors.md3.surface_container !== "transparent" ? MatuColors.md3.surface_container : "#483B3B"
    readonly property color colRed: MatuColors.md3.error !== "transparent" ? MatuColors.md3.error : "#262A22"
    readonly property color colGreen: MatuColors.md3.tertiary !== "transparent" ? MatuColors.md3.tertiary : "#714372"
    readonly property color colYellow: MatuColors.md3.primary !== "transparent" ? MatuColors.md3.primary : "#546B27"
    readonly property color colBlue: MatuColors.md3.primary !== "transparent" ? MatuColors.md3.primary : "#9F7355"
    readonly property color colPurple: MatuColors.md3.tertiary !== "transparent" ? MatuColors.md3.tertiary : "#98A4A0"
    readonly property color colCyan: MatuColors.md3.primary !== "transparent" ? MatuColors.md3.primary : "#DEBB48"
    readonly property color colWhite: MatuColors.md3.on_surface !== "transparent" ? MatuColors.md3.on_surface : "#E6D59B"

    readonly property color colBrightBlack: MatuColors.md3.outline !== "transparent" ? MatuColors.md3.outline : "#A1956C"
    readonly property color colBrightRed: MatuColors.md3.error !== "transparent" ? MatuColors.md3.error : "#262A22"
    readonly property color colBrightGreen: MatuColors.md3.tertiary !== "transparent" ? MatuColors.md3.tertiary : "#714372"
    readonly property color colBrightYellow: MatuColors.md3.primary !== "transparent" ? MatuColors.md3.primary : "#546B27"
    readonly property color colBrightBlue: MatuColors.md3.primary !== "transparent" ? MatuColors.md3.primary : "#9F7355"
    readonly property color colBrightPurple: MatuColors.md3.tertiary !== "transparent" ? MatuColors.md3.tertiary : "#98A4A0"
    readonly property color colBrightCyan: MatuColors.md3.primary !== "transparent" ? MatuColors.md3.primary : "#DEBB48"
    readonly property color colBrightWhite: MatuColors.md3.on_surface !== "transparent" ? MatuColors.md3.on_surface : "#E6D59B"
}

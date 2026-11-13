import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

NIconButton {
    id: root

    property ShellScreen screen

    baseSize: Style.capsuleHeight
    applyUiScale: false
    density: Settings.data.bar.density
    icon: "wallpaper-selector"
    tooltipText: I18n.tr("tooltips.open-wallpaper-selector")
    tooltipDirection: BarService.getTooltipDirection()
    colorBg: (Settings.data.bar.showCapsule ? Colors.mSurfaceVariant : Colors.transparent)
    colorFg: Colors.mOnSurface
    colorBorder: Colors.transparent
    colorBorderHover: Colors.transparent
    onClicked: PanelService.getPanel("wallpaperPanel")?.toggle(this)
}

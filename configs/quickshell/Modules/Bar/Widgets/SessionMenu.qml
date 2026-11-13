import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

NIconButton {
    id: root

    property ShellScreen screen

    density: Settings.data.bar.density
    baseSize: Style.capsuleHeight
    applyUiScale: false
    icon: "power"
    tooltipText: I18n.tr("tooltips.session-menu")
    tooltipDirection: BarService.getTooltipDirection()
    colorBg: (Settings.data.bar.showCapsule ? Colors.mSurfaceVariant : Colors.transparent)
    colorFg: Colors.mError
    colorBorder: Colors.transparent
    colorBorderHover: Colors.transparent
    onClicked: PanelService.getPanel("sessionMenuPanel")?.toggle()
}

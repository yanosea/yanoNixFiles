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
    icon: IdleInhibitorService.isInhibited ? "keep-awake-on" : "keep-awake-off"
    tooltipText: IdleInhibitorService.isInhibited ? I18n.tr("tooltips.disable-keep-awake") : I18n.tr("tooltips.enable-keep-awake")
    tooltipDirection: BarService.getTooltipDirection()
    colorBg: IdleInhibitorService.isInhibited ? Colors.mPrimary : (Settings.data.bar.showCapsule ? Colors.mSurfaceVariant : Colors.transparent)
    colorFg: IdleInhibitorService.isInhibited ? Colors.mOnPrimary : Colors.mOnSurface
    colorBorder: Colors.transparent
    colorBorderHover: Colors.transparent
    onClicked: IdleInhibitorService.manualToggle()
}

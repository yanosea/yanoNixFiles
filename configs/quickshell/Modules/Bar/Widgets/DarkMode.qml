import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services

NIconButton {
    id: root

    property ShellScreen screen

    icon: "dark-mode"
    tooltipText: Settings.data.colorSchemes.darkMode ? I18n.tr("tooltips.switch-to-light-mode") : I18n.tr("tooltips.switch-to-dark-mode")
    tooltipDirection: BarService.getTooltipDirection()
    density: Settings.data.bar.density
    baseSize: Style.capsuleHeight
    applyUiScale: false
    colorBg: Settings.data.colorSchemes.darkMode ? (Settings.data.bar.showCapsule ? Colors.mSurfaceVariant : Colors.transparent) : Colors.mPrimary
    colorFg: Settings.data.colorSchemes.darkMode ? Colors.mOnSurface : Colors.mOnPrimary
    colorBorder: Colors.transparent
    colorBorderHover: Colors.transparent
    onClicked: Settings.data.colorSchemes.darkMode = !Settings.data.colorSchemes.darkMode
}

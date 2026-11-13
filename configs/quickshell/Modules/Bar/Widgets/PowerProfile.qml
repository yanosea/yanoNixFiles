import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.Commons
import qs.Services
import qs.Widgets

NIconButton {
    id: root

    property ShellScreen screen

    baseSize: Style.capsuleHeight
    applyUiScale: false
    density: Settings.data.bar.density
    visible: PowerProfileService.available
    icon: PowerProfileService.getIcon()
    tooltipText: I18n.tr("tooltips.power-profile", {
        "profile": PowerProfileService.getName()
    })
    tooltipDirection: BarService.getTooltipDirection()
    colorBg: (PowerProfileService.profile === PowerProfile.Balanced) ? (Settings.data.bar.showCapsule ? Colors.mSurfaceVariant : Colors.transparent) : Colors.mPrimary
    colorFg: (PowerProfileService.profile === PowerProfile.Balanced) ? Colors.mOnSurface : Colors.mOnPrimary
    colorBorder: Colors.transparent
    colorBorderHover: Colors.transparent
    onClicked: PowerProfileService.cycleProfile()
}

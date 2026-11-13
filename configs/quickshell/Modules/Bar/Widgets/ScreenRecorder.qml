import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// Screen Recording Indicator
NIconButton {
    id: root

    property ShellScreen screen

    property bool isThisMonitorRecording: ScreenRecorderService.isRecording && screen.name === ScreenRecorderService.recordingMonitor

    icon: "camera-video"
    tooltipText: isThisMonitorRecording ? I18n.tr("tooltips.click-to-stop-recording") : I18n.tr("tooltips.click-to-start-recording")
    tooltipDirection: BarService.getTooltipDirection()
    density: Settings.data.bar.density
    baseSize: Style.capsuleHeight
    applyUiScale: false
    colorBg: isThisMonitorRecording ? Colors.mPrimary : (Settings.data.bar.showCapsule ? Colors.mSurfaceVariant : Colors.transparent)
    colorFg: isThisMonitorRecording ? Colors.mOnPrimary : Colors.mOnSurface
    colorBorder: Colors.transparent
    colorBorderHover: Colors.transparent

    function handleClick() {
        if (!ScreenRecorderService.isAvailable) {
            ToastService.showError(I18n.tr("toast.recording.not-installed"), I18n.tr("toast.recording.not-installed-desc"), 7000);
            return;
        }
        ScreenRecorderService.toggleRecording(screen.name);
    }

    onClicked: handleClick()
}

import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen

  icon: "camera-video"
  hot: ScreenRecorderService.isRecording && screen.name === ScreenRecorderService.recordingMonitor
  tooltipText: hot ? I18n.tr("tooltips.click-to-stop-recording") : I18n.tr("tooltips.click-to-start-recording")

  function handleClick() {
    if (!ScreenRecorderService.isAvailable) {
      ToastService.showError(I18n.tr("toast.recording.not-installed"), I18n.tr("toast.recording.not-installed-desc"), 7000)
      return
    }
    ScreenRecorderService.toggleRecording(screen.name)
    if (!ScreenRecorderService.isRecording) {
      var panel = PanelService.getPanel("controlCenterPanel")
      panel?.close()
    }
  }

  onClicked: handleClick()
}

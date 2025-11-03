import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen

  icon: "dark-mode"
  hot: !Settings.data.colorSchemes.darkMode
  tooltipText: Settings.data.colorSchemes.darkMode ? I18n.tr("tooltips.switch-to-light-mode") : I18n.tr("tooltips.switch-to-dark-mode")
  onClicked: Settings.data.colorSchemes.darkMode = !Settings.data.colorSchemes.darkMode

  onRightClicked: {
    var settingsPanel = PanelService.getPanel("settingsPanel")
    settingsPanel.requestedTab = SettingsPanel.Tab.ColorScheme
    settingsPanel.open()
  }
}

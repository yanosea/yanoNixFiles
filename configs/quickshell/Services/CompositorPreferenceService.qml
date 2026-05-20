pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services

Singleton {
  id: root

  readonly property string prefsFilePath: "/var/lib/greetd/preferred-compositor"

  // "niri-session" or "start-hyprland"
  property string preferredCompositor: "start-hyprland"

  readonly property string preferredName: preferredCompositor === "start-hyprland" ? "Hyprland" : "Niri"
  readonly property string currentName: CompositorService.isHyprland ? "Hyprland" : "Niri"

  function init() {
    Logger.i("CompositorPreference", "Service started")
    readProcess.running = true
  }

  // Read the preference file
  Process {
    id: readProcess
    command: ["cat", root.prefsFilePath]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        const raw = text.trim()
        if (raw === "niri-session" || raw === "start-hyprland") {
          root.preferredCompositor = raw
          Logger.i("CompositorPreference", "Loaded:", raw)
        } else {
          root.preferredCompositor = "start-hyprland"
          Logger.i("CompositorPreference", "File missing or invalid, defaulting to start-hyprland")
        }
      }
    }
  }

  // Write process
  Process {
    id: writeProcess
    running: false
    property string pendingValue: ""

    onExited: function (exitCode) {
      if (exitCode === 0) {
        root.preferredCompositor = pendingValue
        Logger.i("CompositorPreference", "Saved:", pendingValue)
      } else {
        Logger.e("CompositorPreference", "Write failed, exit:", exitCode)
      }
    }
  }

  // Set the preferred compositor for next login
  function setPreferred(compositor) {
    if (compositor !== "niri-session" && compositor !== "start-hyprland") {
      Logger.w("CompositorPreference", "Invalid value:", compositor)
      return
    }
    writeProcess.pendingValue = compositor
    writeProcess.command = ["sh", "-c", "printf '%s' '" + compositor + "' > '" + root.prefsFilePath + "'"]
    writeProcess.running = true
  }

  // Set preferred then log out to switch compositor
  function switchTo(compositor) {
    setPreferred(compositor)
    switchTimer.start()
  }

  Timer {
    id: switchTimer
    interval: 600
    repeat: false
    onTriggered: {
      Logger.i("CompositorPreference", "Logging out to switch compositor")
      CompositorService.logout()
    }
  }
}

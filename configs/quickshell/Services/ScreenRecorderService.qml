pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services

Singleton {
  id: root

  readonly property var settings: Settings.data.screenRecorder
  property bool isRecording: false
  property bool isPending: false
  // True only if the recorder actually started capturing at least once
  property bool hasActiveRecording: false
  property string outputPath: ""
  property string recordingMonitor: ""
  property bool isAvailable: ProgramCheckerService.wfRecorderAvailable

  // Update availability when ProgramCheckerService completes its checks
  Connections {
    target: ProgramCheckerService
    function onChecksCompleted() {// Availability is now automatically updated via property binding
    }
  }

  // Start or Stop recording
  function toggleRecording(monitorName) {
    (isRecording || isPending) ? stopRecording() : startRecording(monitorName)
  }

  // Start screen recording using wf-recorder
  function startRecording(monitorName) {
    if (!isAvailable) {
      return
    }
    if (isRecording || isPending) {
      return
    }
    isPending = true
    hasActiveRecording = false
    recordingMonitor = monitorName || ""

    // wf-recorder doesn't need portal check, launch directly
    launchRecorder()
  }

  function launchRecorder() {
    var filename = Time.getFormattedTimestamp() + ".mp4"
    var videoDir = Settings.preprocessPath(settings.directory)
    if (videoDir && !videoDir.endsWith("/")) {
      videoDir += "/"
    }

    // Add monitor name to filename if specified
    if (recordingMonitor) {
      outputPath = videoDir + filename.replace(".mp4", "-" + recordingMonitor + ".mp4")
    } else {
      outputPath = videoDir + filename
    }

    // Use wf-recorder like Hyprland
    var audioArg = `--audio="alsa_output.usb-Roland_Rubix24-00.analog-surround-40.monitor" --audio-volume=1.5`
    var monitorArg = recordingMonitor ? `-o ${recordingMonitor}` : ""
    var command = `wf-recorder -a ${monitorArg} -f "${outputPath}" ${audioArg}`

    // Use Process instead of execDetached so we can monitor it and read stderr
    recorderProcess.exec({
                           "command": ["sh", "-c", command]
                         })

    // Start monitoring - if process ends quickly, it was likely cancelled
    pendingTimer.running = true
  }

  // Stop recording using Quickshell.execDetached
  function stopRecording() {
    if (!isRecording && !isPending) {
      return
    }

    ToastService.showNotice(I18n.tr("toast.recording.stopping"), outputPath, 2000)

    Quickshell.execDetached(["sh", "-c", "pkill -SIGINT wf-recorder"])

    isRecording = false
    isPending = false
    pendingTimer.running = false
    monitorTimer.running = false
    hasActiveRecording = false
    recordingMonitor = ""

    // Just in case, force kill after 3 seconds
    killTimer.running = true
  }

  // Process to run and monitor gpu-screen-recorder
  Process {
    id: recorderProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: function (exitCode, exitStatus) {
      if (isPending) {
        // Process ended while we were pending - likely cancelled or error
        isPending = false
        pendingTimer.running = false

        // Check if gpu-screen-recorder is not installed
        const stdout = String(recorderProcess.stdout.text || "").trim()
        if (stdout === "GPU_SCREEN_RECORDER_NOT_INSTALLED") {
          ToastService.showError(I18n.tr("toast.recording.not-installed"), I18n.tr("toast.recording.not-installed-desc"), 7000)
          return
        }

        // If it failed to start, show a clear error toast with stderr
        if (exitCode !== 0) {
          const err = String(recorderProcess.stderr.text || "").trim()
          if (err.length > 0)
            ToastService.showError(I18n.tr("toast.recording.failed-start"), err, 7000)
          else
            ToastService.showError(I18n.tr("toast.recording.failed-start"), I18n.tr("toast.recording.failed-gpu"), 7000)
        }
      } else if (isRecording) {
        // Process ended normally while recording
        isRecording = false
        monitorTimer.running = false
        // Consider successful save if exitCode == 0
        if (exitCode === 0) {
          ToastService.showNotice(I18n.tr("toast.recording.saved"), outputPath, 5000)
        } else {
          const err2 = String(recorderProcess.stderr.text || "").trim()
          if (err2.length > 0)
            ToastService.showError(I18n.tr("toast.recording.failed-start"), err2, 7000)
          else
            ToastService.showError(I18n.tr("toast.recording.failed-start"), I18n.tr("toast.recording.failed-general"), 7000)
        }
      }
    }
  }

  Timer {
    id: pendingTimer
    interval: 2000 // Wait 2 seconds to see if process stays alive
    running: false
    repeat: false
    onTriggered: {
      if (isPending && recorderProcess.running) {
        // Process is still running after 2 seconds - assume recording started successfully
        isPending = false
        isRecording = true
        hasActiveRecording = true
        monitorTimer.running = true
        // Don't show a toast when recording starts to avoid having the toast in every video.
        //ToastService.showNotice("Recording started", outputPath, 4000)
      } else if (isPending) {
        // Process not running anymore - was cancelled or failed
        isPending = false
      }
    }
  }

  // Monitor timer to periodically check if we're still recording
  Timer {
    id: monitorTimer
    interval: 2000
    running: false
    repeat: true
    onTriggered: {
      if (!recorderProcess.running && isRecording) {
        isRecording = false
        running = false
      }
    }
  }

  Timer {
    id: killTimer
    interval: 3000
    running: false
    repeat: false
    onTriggered: {
      Quickshell.execDetached(["sh", "-c", "pkill -9 wf-recorder 2>/dev/null || true"])
    }
  }
}

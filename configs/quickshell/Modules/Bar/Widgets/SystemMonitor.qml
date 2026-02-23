import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Settings
import qs.Services
import qs.Widgets

Item {
  id: root

  property ShellScreen screen

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId]
  property var widgetSettings: {
    if (section && sectionWidgetIndex >= 0) {
      var widgets = Settings.data.bar.widgets[section]
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex]
      }
    }
    return {}
  }

  readonly property string barPosition: Settings.data.bar.position
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property bool density: Settings.data.bar.density
  readonly property bool oppositeDirection: BarService.getPillDirection(root)

  readonly property bool showCpuUsage: (widgetSettings.showCpuUsage !== undefined) ? widgetSettings.showCpuUsage : widgetMetadata.showCpuUsage
  readonly property bool showCpuTemp: (widgetSettings.showCpuTemp !== undefined) ? widgetSettings.showCpuTemp : widgetMetadata.showCpuTemp
  readonly property bool showGpuUsage: (widgetSettings.showGpuUsage !== undefined) ? widgetSettings.showGpuUsage : widgetMetadata.showGpuUsage
  readonly property bool showGpuTemp: (widgetSettings.showGpuTemp !== undefined) ? widgetSettings.showGpuTemp : widgetMetadata.showGpuTemp
  readonly property bool showMemoryUsage: (widgetSettings.showMemoryUsage !== undefined) ? widgetSettings.showMemoryUsage : widgetMetadata.showMemoryUsage
  readonly property bool showMemoryAsPercent: (widgetSettings.showMemoryAsPercent !== undefined) ? widgetSettings.showMemoryAsPercent : widgetMetadata.showMemoryAsPercent
  readonly property bool showNetworkStats: (widgetSettings.showNetworkStats !== undefined) ? widgetSettings.showNetworkStats : widgetMetadata.showNetworkStats
  readonly property bool showDiskUsage: (widgetSettings.showDiskUsage !== undefined) ? widgetSettings.showDiskUsage : widgetMetadata.showDiskUsage

  readonly property real iconSize: textSize * 1.4
  readonly property real textSize: {
    var base = isVertical ? Style.capsuleHeight * 0.82 : Style.capsuleHeight
    return Math.max(1, (density === "compact") ? base * 0.43 : base * 0.33)
  }

  readonly property int percentTextWidth: Math.ceil(percentMetrics.boundingRect.width + 3)
  readonly property int tempTextWidth: Math.ceil(tempMetrics.boundingRect.width + 3)
  readonly property int memTextWidth: Math.ceil(memMetrics.boundingRect.width + 3)

  TextMetrics {
    id: percentMetrics
    font.family: Settings.data.ui.fontFixed
    font.weight: Style.fontWeightMedium
    font.pointSize: textSize * Settings.data.ui.fontFixedScale
    text: "99%"
  }

  TextMetrics {
    id: tempMetrics
    font.family: Settings.data.ui.fontFixed
    font.weight: Style.fontWeightMedium
    font.pointSize: textSize * Settings.data.ui.fontFixedScale
    text: "99°"
  }

  TextMetrics {
    id: memMetrics
    font.family: Settings.data.ui.fontFixed
    font.weight: Style.fontWeightMedium
    font.pointSize: textSize * Settings.data.ui.fontFixedScale
    text: "99.9K"
  }

  // ── Pill state ──
  property bool showPill: false
  property bool hovered: false

  readonly property int pillHeight: Style.capsuleHeight
  readonly property int pillPaddingH: Math.round(pillHeight * 0.2)
  readonly property int pillOverlap: Math.round(pillHeight * 0.5)
  readonly property int pillMaxWidth: Math.max(1, Math.round(mainGrid.implicitWidth + pillPaddingH * 2 + pillOverlap))
  readonly property int pillMaxHeight: Math.max(1, Math.round(mainGrid.implicitHeight + pillPaddingH * 2 + pillOverlap))

  // ── Widget size (matches BarPillHorizontal/Vertical pattern) ──
  implicitWidth: isVertical ? pillHeight : (pillHeight + Math.max(0, pill.width - pillOverlap))
  implicitHeight: isVertical ? (pillHeight + Math.max(0, pill.height - pillOverlap)) : pillHeight

  // ── Pill (expanding content area) ──
  Rectangle {
    id: pill

    width: isVertical ? pillHeight : (showPill ? pillMaxWidth : 1)
    height: isVertical ? (showPill ? pillMaxHeight : 1) : pillHeight
    opacity: showPill ? Style.opacityFull : Style.opacityNone

    color: hovered ? Color.mTertiary : (Settings.data.bar.showCapsule ? Color.mSurfaceVariant : Color.transparent)
    clip: true

    readonly property int halfPill: Math.round(pillHeight * 0.5)

    // Horizontal: rounded on the far side from icon
    // Vertical: rounded on the far side from icon
    topLeftRadius: isVertical ? (!oppositeDirection ? halfPill : 0) : (!oppositeDirection ? halfPill : 0)
    topRightRadius: isVertical ? (!oppositeDirection ? halfPill : 0) : (oppositeDirection ? halfPill : 0)
    bottomLeftRadius: isVertical ? (oppositeDirection ? halfPill : 0) : (!oppositeDirection ? halfPill : 0)
    bottomRightRadius: isVertical ? (oppositeDirection ? halfPill : 0) : (oppositeDirection ? halfPill : 0)

    // Position: pill slides out from behind iconCircle
    x: isVertical ? 0 : (oppositeDirection ? (iconCircle.x + iconCircle.width / 2) : (iconCircle.x + iconCircle.width / 2) - width)
    y: isVertical ? (!oppositeDirection ? (iconCircle.y + iconCircle.height / 2 - height) : (iconCircle.y + iconCircle.height / 2)) : 0

    anchors.verticalCenter: isVertical ? undefined : parent.verticalCenter
    anchors.horizontalCenter: isVertical ? parent.horizontalCenter : undefined

    Behavior on color {
      ColorAnimation {
        duration: Style.animationNormal
        easing.type: Easing.InOutQuad
      }
    }

    Behavior on width {
      enabled: showAnim.running || hideAnim.running
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutCubic
      }
    }

    Behavior on height {
      enabled: showAnim.running || hideAnim.running
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutCubic
      }
    }

    Behavior on opacity {
      enabled: showAnim.running || hideAnim.running
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutCubic
      }
    }

    GridLayout {
      id: mainGrid
      anchors.centerIn: parent
      anchors.horizontalCenterOffset: isVertical ? 0 : (oppositeDirection ? pillOverlap / 2 : -pillOverlap / 2)
      anchors.verticalCenterOffset: isVertical ? (!oppositeDirection ? -pillOverlap / 2 : pillOverlap / 2) : 0
      flow: isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
      rows: isVertical ? -1 : 1
      columns: isVertical ? 1 : -1
      rowSpacing: isVertical ? (Style.marginM) : 0
      columnSpacing: isVertical ? 0 : (Style.marginM)
      visible: showPill

      // CPU Usage Component
      Item {
        Layout.preferredWidth: isVertical ? pillHeight : iconSize + percentTextWidth + (Style.marginXXS)
        Layout.preferredHeight: Style.capsuleHeight
        Layout.alignment: isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: showCpuUsage

        GridLayout {
          id: cpuUsageContent
          anchors.centerIn: parent
          flow: isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: isVertical ? 2 : 1
          columns: isVertical ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: Style.marginXXS

          NIcon {
            icon: "cpu-usage"
            pointSize: iconSize
            applyUiScale: false
            color: root.hovered ? Color.mOnTertiary : Color.mOnSurface
            Layout.alignment: Qt.AlignCenter
            Layout.row: isVertical ? 1 : 0
            Layout.column: 0
          }

          NText {
            text: `${Math.round(SystemStatService.cpuUsage)}%`
            family: Settings.data.ui.fontFixed
            pointSize: textSize
            applyUiScale: false
            font.weight: Style.fontWeightMedium
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: isVertical ? -1 : percentTextWidth
            horizontalAlignment: isVertical ? Text.AlignHCenter : Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            color: root.hovered ? Color.mOnTertiary : Color.mPrimary
            Layout.row: isVertical ? 0 : 0
            Layout.column: isVertical ? 0 : 1
            scale: isVertical ? Math.min(1.0, pillHeight / implicitWidth) : 1.0
          }
        }
      }

      // CPU Temperature Component
      Item {
        Layout.preferredWidth: isVertical ? pillHeight : (iconSize + tempTextWidth) + (Style.marginXXS)
        Layout.preferredHeight: Style.capsuleHeight
        Layout.alignment: isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: showCpuTemp

        GridLayout {
          id: cpuTempContent
          anchors.centerIn: parent
          flow: isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: isVertical ? 2 : 1
          columns: isVertical ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: Style.marginXXS

          NIcon {
            icon: "cpu-temperature"
            pointSize: iconSize
            applyUiScale: false
            color: root.hovered ? Color.mOnTertiary : Color.mOnSurface
            Layout.alignment: Qt.AlignCenter
            Layout.row: isVertical ? 1 : 0
            Layout.column: 0
          }

          NText {
            text: `${Math.round(SystemStatService.cpuTemp)}°`
            family: Settings.data.ui.fontFixed
            pointSize: textSize
            applyUiScale: false
            font.weight: Style.fontWeightMedium
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: isVertical ? -1 : tempTextWidth
            horizontalAlignment: isVertical ? Text.AlignHCenter : Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            color: root.hovered ? Color.mOnTertiary : Color.mPrimary
            Layout.row: isVertical ? 0 : 0
            Layout.column: isVertical ? 0 : 1
            scale: isVertical ? Math.min(1.0, pillHeight / implicitWidth) : 1.0
          }
        }
      }

      // GPU Usage Component
      Item {
        Layout.preferredWidth: isVertical ? pillHeight : iconSize + percentTextWidth + (Style.marginXXS)
        Layout.preferredHeight: Style.capsuleHeight
        Layout.alignment: isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: showGpuUsage

        GridLayout {
          id: gpuUsageContent
          anchors.centerIn: parent
          flow: isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: isVertical ? 2 : 1
          columns: isVertical ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: Style.marginXXS

          NIcon {
            icon: "device-desktop-analytics"
            pointSize: iconSize
            applyUiScale: false
            color: root.hovered ? Color.mOnTertiary : Color.mOnSurface
            Layout.alignment: Qt.AlignCenter
            Layout.row: isVertical ? 1 : 0
            Layout.column: 0
          }

          NText {
            text: `${Math.round(SystemStatService.gpuUsage)}%`
            family: Settings.data.ui.fontFixed
            pointSize: textSize
            applyUiScale: false
            font.weight: Style.fontWeightMedium
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: isVertical ? -1 : percentTextWidth
            horizontalAlignment: isVertical ? Text.AlignHCenter : Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            color: root.hovered ? Color.mOnTertiary : Color.mPrimary
            Layout.row: isVertical ? 0 : 0
            Layout.column: isVertical ? 0 : 1
            scale: isVertical ? Math.min(1.0, pillHeight / implicitWidth) : 1.0
          }
        }
      }

      // GPU Temperature Component
      Item {
        Layout.preferredWidth: isVertical ? pillHeight : (iconSize + tempTextWidth) + (Style.marginXXS)
        Layout.preferredHeight: Style.capsuleHeight
        Layout.alignment: isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: showGpuTemp

        GridLayout {
          id: gpuTempContent
          anchors.centerIn: parent
          flow: isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: isVertical ? 2 : 1
          columns: isVertical ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: Style.marginXXS

          NIcon {
            icon: "temperature"
            pointSize: iconSize
            applyUiScale: false
            color: root.hovered ? Color.mOnTertiary : Color.mOnSurface
            Layout.alignment: Qt.AlignCenter
            Layout.row: isVertical ? 1 : 0
            Layout.column: 0
          }

          NText {
            text: `${Math.round(SystemStatService.gpuTemp)}°`
            family: Settings.data.ui.fontFixed
            pointSize: textSize
            applyUiScale: false
            font.weight: Style.fontWeightMedium
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: isVertical ? -1 : tempTextWidth
            horizontalAlignment: isVertical ? Text.AlignHCenter : Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            color: root.hovered ? Color.mOnTertiary : Color.mPrimary
            Layout.row: isVertical ? 0 : 0
            Layout.column: isVertical ? 0 : 1
            scale: isVertical ? Math.min(1.0, pillHeight / implicitWidth) : 1.0
          }
        }
      }

      // Memory Usage Component
      Item {
        Layout.preferredWidth: isVertical ? pillHeight : iconSize + (showMemoryAsPercent ? percentTextWidth : memTextWidth) + (Style.marginXXS)
        Layout.preferredHeight: Style.capsuleHeight
        Layout.alignment: isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: showMemoryUsage

        GridLayout {
          id: memoryContent
          anchors.centerIn: parent
          flow: isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: isVertical ? 2 : 1
          columns: isVertical ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: Style.marginXXS

          NIcon {
            icon: "memory"
            pointSize: iconSize
            applyUiScale: false
            color: root.hovered ? Color.mOnTertiary : Color.mOnSurface
            Layout.alignment: Qt.AlignCenter
            Layout.row: isVertical ? 1 : 0
            Layout.column: 0
          }

          NText {
            text: showMemoryAsPercent ? `${Math.round(SystemStatService.memPercent)}%` : `${SystemStatService.memGb.toFixed(1)}G`
            family: Settings.data.ui.fontFixed
            pointSize: textSize
            applyUiScale: false
            font.weight: Style.fontWeightMedium
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: isVertical ? -1 : (showMemoryAsPercent ? percentTextWidth : memTextWidth)
            horizontalAlignment: isVertical ? Text.AlignHCenter : Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            color: root.hovered ? Color.mOnTertiary : Color.mPrimary
            Layout.row: isVertical ? 0 : 0
            Layout.column: isVertical ? 0 : 1
            scale: isVertical ? Math.min(1.0, pillHeight / implicitWidth) : 1.0
          }
        }
      }

      // Disk Usage Component (primary drive)
      Item {
        Layout.preferredWidth: isVertical ? pillHeight : iconSize + percentTextWidth + (Style.marginXXS)
        Layout.preferredHeight: Style.capsuleHeight
        Layout.alignment: isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: showDiskUsage

        GridLayout {
          id: diskContent
          anchors.centerIn: parent
          flow: isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: isVertical ? 2 : 1
          columns: isVertical ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: Style.marginXXS

          NIcon {
            icon: "storage"
            pointSize: iconSize
            applyUiScale: false
            color: root.hovered ? Color.mOnTertiary : Color.mOnSurface
            Layout.alignment: Qt.AlignCenter
            Layout.row: isVertical ? 1 : 0
            Layout.column: 0
          }

          NText {
            text: `${SystemStatService.diskPercents["/"]}%`
            family: Settings.data.ui.fontFixed
            pointSize: textSize
            applyUiScale: false
            font.weight: Style.fontWeightMedium
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: isVertical ? -1 : percentTextWidth
            horizontalAlignment: isVertical ? Text.AlignHCenter : Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            color: root.hovered ? Color.mOnTertiary : Color.mPrimary
            Layout.row: isVertical ? 0 : 0
            Layout.column: isVertical ? 0 : 1
            scale: isVertical ? Math.min(1.0, pillHeight / implicitWidth) : 1.0
          }
        }
      }

      // Network Download Speed Component
      Item {
        Layout.preferredWidth: isVertical ? pillHeight : iconSize + memTextWidth + (Style.marginXXS)
        Layout.preferredHeight: Style.capsuleHeight
        Layout.alignment: isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: showNetworkStats

        GridLayout {
          id: downloadContent
          anchors.centerIn: parent
          flow: isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: isVertical ? 2 : 1
          columns: isVertical ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: Style.marginXXS

          NIcon {
            icon: "download-speed"
            pointSize: iconSize
            applyUiScale: false
            color: root.hovered ? Color.mOnTertiary : Color.mOnSurface
            Layout.alignment: Qt.AlignCenter
            Layout.row: isVertical ? 1 : 0
            Layout.column: 0
          }

          NText {
            text: isVertical ? SystemStatService.formatCompactSpeed(SystemStatService.rxSpeed) : SystemStatService.formatSpeed(SystemStatService.rxSpeed)
            family: Settings.data.ui.fontFixed
            pointSize: textSize
            applyUiScale: false
            font.weight: Style.fontWeightMedium
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: isVertical ? -1 : memTextWidth
            horizontalAlignment: isVertical ? Text.AlignHCenter : Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            color: root.hovered ? Color.mOnTertiary : Color.mPrimary
            Layout.row: isVertical ? 0 : 0
            Layout.column: isVertical ? 0 : 1
            scale: isVertical ? Math.min(1.0, pillHeight / implicitWidth) : 1.0
          }
        }
      }

      // Network Upload Speed Component
      Item {
        Layout.preferredWidth: isVertical ? pillHeight : iconSize + memTextWidth + (Style.marginXXS)
        Layout.preferredHeight: Style.capsuleHeight
        Layout.alignment: isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
        visible: showNetworkStats

        GridLayout {
          id: uploadContent
          anchors.centerIn: parent
          flow: isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
          rows: isVertical ? 2 : 1
          columns: isVertical ? 1 : 2
          rowSpacing: Style.marginXXS
          columnSpacing: Style.marginXXS

          NIcon {
            icon: "upload-speed"
            pointSize: iconSize
            applyUiScale: false
            color: root.hovered ? Color.mOnTertiary : Color.mOnSurface
            Layout.alignment: Qt.AlignCenter
            Layout.row: isVertical ? 1 : 0
            Layout.column: 0
          }

          NText {
            text: isVertical ? SystemStatService.formatCompactSpeed(SystemStatService.txSpeed) : SystemStatService.formatSpeed(SystemStatService.txSpeed)
            family: Settings.data.ui.fontFixed
            pointSize: textSize
            applyUiScale: false
            font.weight: Style.fontWeightMedium
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: isVertical ? -1 : memTextWidth
            horizontalAlignment: isVertical ? Text.AlignHCenter : Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            color: root.hovered ? Color.mOnTertiary : Color.mPrimary
            Layout.row: isVertical ? 0 : 0
            Layout.column: isVertical ? 0 : 1
            scale: isVertical ? Math.min(1.0, pillHeight / implicitWidth) : 1.0
          }
        }
      }
    }
  }

  // ── Icon circle (always visible) ──
  Rectangle {
    id: iconCircle
    width: pillHeight
    height: pillHeight
    radius: width * 0.5
    color: hovered ? Color.mTertiary : (Settings.data.bar.showCapsule ? Color.mSurfaceVariant : Color.transparent)

    x: isVertical ? 0 : (oppositeDirection ? 0 : (parent.width - width))
    y: isVertical ? (!oppositeDirection ? (parent.height - height) : 0) : 0
    anchors.verticalCenter: isVertical ? undefined : parent.verticalCenter
    anchors.horizontalCenter: isVertical ? parent.horizontalCenter : undefined

    Behavior on color {
      ColorAnimation {
        duration: Style.animationNormal
        easing.type: Easing.InOutQuad
      }
    }

    NIcon {
      icon: "activity-heartbeat"
      pointSize: root.iconSize
      applyUiScale: false
      color: hovered ? Color.mOnTertiary : Color.mOnSurface
      x: (iconCircle.width - width) / 2
      y: (iconCircle.height - height) / 2 + (height - contentHeight) / 2
    }
  }

  // ── Animations (same pattern as BarPillHorizontal/Vertical) ──
  ParallelAnimation {
    id: showAnim
    running: false
    NumberAnimation {
      target: pill
      property: isVertical ? "height" : "width"
      from: 1
      to: isVertical ? pillMaxHeight : pillMaxWidth
      duration: Style.animationNormal
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: pill
      property: "opacity"
      from: 0
      to: 1
      duration: Style.animationNormal
      easing.type: Easing.OutCubic
    }
    onStarted: showPill = true
  }

  ParallelAnimation {
    id: hideAnim
    running: false
    NumberAnimation {
      target: pill
      property: isVertical ? "height" : "width"
      from: isVertical ? pillMaxHeight : pillMaxWidth
      to: 1
      duration: Style.animationNormal
      easing.type: Easing.InCubic
    }
    NumberAnimation {
      target: pill
      property: "opacity"
      from: 1
      to: 0
      duration: Style.animationNormal
      easing.type: Easing.InCubic
    }
    onStopped: showPill = false
  }

  Timer {
    id: showTimer
    interval: Style.pillDelay
    onTriggered: {
      if (!showPill) {
        showAnim.start()
      }
    }
  }

  // ── Mouse interaction ──
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: {
      hovered = true
      if (!showPill) {
        showTimer.start()
      }
    }
    onExited: {
      hovered = false
      if (showPill) {
        hideAnim.start()
      }
      showTimer.stop()
    }
  }
}

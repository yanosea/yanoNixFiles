import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

NBox {
    id: root

    RowLayout {
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginL

        // Left: current running compositor
        NIcon {
            icon: "device-desktop"
            pointSize: Style.fontSizeXXL
            color: Colors.mPrimary
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            spacing: 0
            Layout.alignment: Qt.AlignVCenter

            NText {
                text: CompositorPreferenceService.currentName
                font.weight: Style.fontWeightBold
            }
            NText {
                text: "running"
                pointSize: Style.fontSizeXS
                color: Colors.mOnSurfaceVariant
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // Right: login-default selector + optional logout button
        RowLayout {
            spacing: Style.marginXS
            Layout.alignment: Qt.AlignVCenter

            NText {
                text: "Default:"
                pointSize: Style.fontSizeXS
                color: Colors.mOnSurfaceVariant
            }

            // Niri pill
            Rectangle {
                implicitWidth: niriLabel.implicitWidth + Style.marginM * 2
                implicitHeight: Math.round(Style.baseWidgetSize * 0.6 * Style.uiScaleRatio)
                radius: Style.radiusS
                color: CompositorPreferenceService.preferredCompositor === "niri-session" ? Colors.mPrimary : Colors.mSurfaceVariant
                Behavior on color {
                    ColorAnimation {
                        duration: Style.animationFast
                    }
                }

                NText {
                    id: niriLabel
                    anchors.centerIn: parent
                    text: "Niri"
                    pointSize: Style.fontSizeXS
                    font.weight: Style.fontWeightMedium
                    color: CompositorPreferenceService.preferredCompositor === "niri-session" ? Colors.mOnPrimary : Colors.mOnSurfaceVariant
                    Behavior on color {
                        ColorAnimation {
                            duration: Style.animationFast
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: CompositorPreferenceService.setPreferred("niri-session")
                }
            }

            // Hyprland pill
            Rectangle {
                implicitWidth: hyprLabel.implicitWidth + Style.marginM * 2
                implicitHeight: Math.round(Style.baseWidgetSize * 0.6 * Style.uiScaleRatio)
                radius: Style.radiusS
                color: CompositorPreferenceService.preferredCompositor === "start-hyprland" ? Colors.mPrimary : Colors.mSurfaceVariant
                Behavior on color {
                    ColorAnimation {
                        duration: Style.animationFast
                    }
                }

                NText {
                    id: hyprLabel
                    anchors.centerIn: parent
                    text: "Hyprland"
                    pointSize: Style.fontSizeXS
                    font.weight: Style.fontWeightMedium
                    color: CompositorPreferenceService.preferredCompositor === "start-hyprland" ? Colors.mOnPrimary : Colors.mOnSurfaceVariant
                    Behavior on color {
                        ColorAnimation {
                            duration: Style.animationFast
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: CompositorPreferenceService.setPreferred("start-hyprland")
                }
            }

            // Logout button — only when current session differs from login default
            NIconButton {
                visible: CompositorPreferenceService.currentName !== CompositorPreferenceService.preferredName
                icon: "logout"
                tooltipText: "Switch to " + CompositorPreferenceService.preferredName + " (logout)"
                colorFg: Colors.mError
                colorBgHover: Colors.mError
                colorFgHover: Colors.mOnError
                onClicked: CompositorPreferenceService.switchTo(CompositorPreferenceService.preferredCompositor)
            }
        }
    }
}

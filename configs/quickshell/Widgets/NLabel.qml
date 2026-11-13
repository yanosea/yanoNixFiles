import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
    id: root

    property string label: ""
    property string description: ""
    property color labelColor: Colors.mOnSurface
    property color descriptionColor: Colors.mOnSurfaceVariant

    spacing: Style.marginXXS
    Layout.fillWidth: true

    NText {
        text: label
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: labelColor
        visible: label !== ""
        Layout.fillWidth: true
    }

    NText {
        text: description
        pointSize: Style.fontSizeS
        color: descriptionColor
        wrapMode: Text.WordWrap
        visible: description !== ""
        Layout.fillWidth: true
    }
}

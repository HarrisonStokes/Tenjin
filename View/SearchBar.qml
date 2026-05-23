import QtQuick
import QtQuick.Controls
import Layouts
import TenjinView

Rectangle {
    id: root
    height: Platform.touchTarget
    color: Platform.surface
    radius: Platform.radius
    border.color: Platform.border
    border.width: 1

    signal queryChanged(string q)

    Row {
        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "🔍"; font.pixelSize: Platform.iconSize; color: Platform.textMuted
        }

        TextField {
            width: root.width - 40
            anchors.verticalCenter: parent.verticalCenter
            placeholderText: "Search words…"
            placeholderTextColor: Platform.textMuted
            font.pixelSize: Platform.fontBase
            color: Platform.textPrimary
            background: Rectangle { color: "transparent" }
            onTextChanged: root.queryChanged(text)
        }
    }
}

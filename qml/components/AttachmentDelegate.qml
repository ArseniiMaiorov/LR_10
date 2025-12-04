import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: root
    required property string type
    required property string path
    width: ListView.view ? ListView.view.width : implicitWidth

    contentItem: RowLayout {
        spacing: 8
        Label {
            text: "[" + root.type + "]"
            font.bold: true
        }
        Label {
            text: root.path
            elide: Label.ElideRight
            Layout.fillWidth: true
        }
        ToolButton {
            icon.name: "document-open"
            onClicked: Qt.openUrlExternally(root.path)
            Accessible.name: "Открыть вложение"
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GroupBox {
    id: root
    property var subscription
    property var onSubscribe

    title: "Подписка"
    Layout.fillWidth: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Label {
            text: subscription && subscription.active ?
                      "Текущий план: " + subscription.plan + " (активна до " + subscription.expiration + ")" :
                      "Нет активной подписки"
            wrapMode: Text.Wrap
        }

        ComboBox {
            id: planSelector
            Layout.fillWidth: true
            model: ["Free", "Standard", "Pro"]
        }

        Button {
            text: "Оформить/обновить"
            Layout.fillWidth: true
            onClicked: {
                if (onSubscribe)
                    onSubscribe(planSelector.currentText)
            }
        }
    }
}
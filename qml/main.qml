import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: window
    width: 1200
    height: 720
    visible: true
    title: qsTr("Менеджер заметок")

    property var appData: ({ subscription: {}, notebooks: [] })
    property int selectedNotebookIndex: 0
    property int selectedNoteIndex: 0

    function syncEditors() {
        noteTitle.text = currentNote() ? currentNote().title : "";
        noteContent.text = currentNote() ? currentNote().content : "";
    }

    function currentNotebook() {
        return appData.notebooks && appData.notebooks.length > 0 ? appData.notebooks[selectedNotebookIndex] : null;
    }

    function currentNote() {
        const nb = currentNotebook();
        if (!nb || !nb.notes || nb.notes.length === 0)
            return null;
        return nb.notes[selectedNoteIndex];
    }

    function persist() {
        dataStore.saveData(appData);
    }

    function refreshFromStorage() {
        appData = dataStore.loadData();
        if (!appData.notebooks)
            appData.notebooks = [];
        if (selectedNotebookIndex >= appData.notebooks.length)
            selectedNotebookIndex = Math.max(0, appData.notebooks.length - 1);
        if (currentNotebook() && selectedNoteIndex >= currentNotebook().notes.length)
            selectedNoteIndex = Math.max(0, currentNotebook().notes.length - 1);
        syncEditors();
    }

    function createNotebook() {
        const id = "notebook-" + Date.now();
        const notebook = { id: id, title: "Новый блокнот", notes: [] };
        appData.notebooks.push(notebook);
        selectedNotebookIndex = appData.notebooks.length - 1;
        persist();
    }

    function removeNotebook(index) {
        if (index < 0 || index >= appData.notebooks.length)
            return;
        appData.notebooks.splice(index, 1);
        selectedNotebookIndex = Math.max(0, selectedNotebookIndex - 1);
        selectedNoteIndex = 0;
        persist();
    }

    function createNote() {
        const nb = currentNotebook();
        if (!nb)
            return;
        const note = {
            id: "note-" + Date.now(),
            title: "Новая заметка",
            content: "",
            attachments: [],
            lastModified: new Date().toISOString()
        };
        nb.notes.push(note);
        selectedNoteIndex = nb.notes.length - 1;
        persist();
    }

    function removeNote(index) {
        const nb = currentNotebook();
        if (!nb || index < 0 || index >= nb.notes.length)
            return;
        nb.notes.splice(index, 1);
        selectedNoteIndex = Math.max(0, selectedNoteIndex - 1);
        persist();
    }

    function updateCurrentNote(content, title) {
        const note = currentNote();
        const nb = currentNotebook();
        if (!note || !nb)
            return;
        note.content = content;
        note.title = title;
        note.lastModified = new Date().toISOString();
        nb.notes[selectedNoteIndex] = note;
        persist();
    }

    function addAttachment(filePath, type) {
        const note = currentNote();
        const nb = currentNotebook();
        if (!note || !nb)
            return;
        note.attachments.push({ type: type, path: filePath });
        note.lastModified = new Date().toISOString();
        nb.notes[selectedNoteIndex] = note;
        persist();
    }

    function toggleSubscription(plan) {
        const expiry = new Date();
        expiry.setMonth(expiry.getMonth() + 1);
        appData.subscription = {
            plan: plan,
            active: plan !== "Free",
            expiration: expiry.toISOString().split("T")[0]
        };
        persist();
    }

    Component.onCompleted: refreshFromStorage()

    onSelectedNotebookIndexChanged: syncEditors()
    onSelectedNoteIndexChanged: syncEditors()

    FileDialog {
        id: attachmentDialog
        title: "Выберите файл для вложения"
        fileMode: FileDialog.OpenFile
        onAccepted: {
            addAttachment(selectedFile, attachmentType.currentText)
        }
    }

    FileDialog {
        id: exportDialog
        title: "Экспортировать заметку"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Текстовый файл (*.txt)", "Все файлы (*)"]
        onAccepted: {
            const note = currentNote();
            if (note)
                dataStore.exportNote(note, selectedFile)
        }
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            spacing: 12
            Label {
                text: "Менеджер заметок"
                font.bold: true
                font.pointSize: 16
                Layout.alignment: Qt.AlignVCenter
            }
            Label {
                text: "Данные: " + dataStore.dataLocation()
                elide: Label.ElideRight
                Layout.fillWidth: true
            }
            Button {
                text: "Экспорт"
                enabled: currentNote() !== null
                onClicked: exportDialog.open()
            }
        }
    }

    SplitView {
        anchors.fill: parent

        Rectangle {
            color: "#f8f8f8"
            implicitWidth: 320

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Добавить блокнот"
                        Layout.fillWidth: true
                        onClicked: createNotebook()
                    }
                }

                ListView {
                    id: notebookList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: appData.notebooks
                    delegate: Frame {
                        width: ListView.view ? ListView.view.width : implicitWidth
                        padding: 6
                        background: Rectangle {
                            color: index === selectedNotebookIndex ? "#e0f7fa" : "transparent"
                            radius: 4
                        }
                        ColumnLayout {
                            width: parent.width
                            spacing: 4
                            TextField {
                                text: modelData.title
                                placeholderText: "Название блокнота"
                                onTextChanged: {
                                    modelData.title = text
                                    persist()
                                }
                                Layout.fillWidth: true
                            }
                            RowLayout {
                                spacing: 6
                                Button {
                                    text: "Открыть"
                                    onClicked: {
                                        selectedNotebookIndex = index
                                        selectedNoteIndex = 0
                                    }
                                }
                                Button {
                                    text: "Удалить"
                                    enabled: appData.notebooks.length > 1
                                    onClicked: removeNotebook(index)
                                }
                            }
                        }
                    }
                }

                SubscriptionPanel {
                    subscription: appData.subscription
                    onSubscribe: toggleSubscription
                }
            }
        }

        Rectangle {
            color: "white"
            anchors.margins: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Добавить заметку"
                        enabled: currentNotebook() !== null
                        onClicked: createNote()
                    }
                    Button {
                        text: "Удалить заметку"
                        enabled: currentNote() !== null
                        onClicked: removeNote(selectedNoteIndex)
                    }
                    ComboBox {
                        id: attachmentType
                        model: ["Изображение", "Аудио", "Видео", "Файл"]
                    }
                    Button {
                        text: "Добавить вложение"
                        enabled: currentNote() !== null
                        onClicked: attachmentDialog.open()
                    }
                }

                SplitView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        id: noteList
                        implicitWidth: 240
                        model: currentNotebook() ? currentNotebook().notes : []
                        delegate: ItemDelegate {
                            width: ListView.view ? ListView.view.width : implicitWidth
                            text: modelData.title
                            highlighted: index === selectedNoteIndex
                            onClicked: selectedNoteIndex = index
                        }
                    }

                    Frame {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            TextField {
                                id: noteTitle
                                text: currentNote() ? currentNote().title : ""
                                placeholderText: "Заголовок"
                                font.pointSize: 16
                                onTextEdited: updateCurrentNote(noteContent.text, text)
                                Layout.fillWidth: true
                            }

                            TextArea {
                                id: noteContent
                                text: currentNote() ? currentNote().content : ""
                                placeholderText: "Введите текст заметки"
                                wrapMode: TextArea.Wrap
                                onTextChanged: updateCurrentNote(text, noteTitle.text)
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }

                            Label {
                                text: currentNote() ? "Обновлено: " + currentNote().lastModified : ""
                                color: "gray"
                            }

                            GroupBox {
                                title: "Вложения"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 160

                                ListView {
                                    anchors.fill: parent
                                    model: currentNote() ? currentNote().attachments : []
                                    delegate: AttachmentDelegate {
                                        type: modelData.type
                                        path: modelData.path
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

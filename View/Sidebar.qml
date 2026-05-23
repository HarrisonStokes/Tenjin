import TenjinView
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle {
    id: sidebarRoot
    color: Platform.surface

    signal addWordRequested()
    signal addDeckRequested()

    function createSidebarTag() {
        const name = newSidebarTag.text.trim()
        if (name.length === 0) return
        if (appVM.wordVM.createTag(name)) {
            newSidebarTag.text = ""
            appVM.sidebarVM.reload()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Mode tabs: Words | Tags | Decks ──────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            color: Platform.surface
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1; color: Platform.border
            }
            Row {
                anchors.fill: parent
                Repeater {
                    model: ["Words", "Tags", "Decks"]
                    Rectangle {
                        width: parent.width / 3
                        height: 38
                        color: "transparent"
                        property bool active: sidebarMode === index
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 12
                            font.bold: parent.active
                            color: parent.active ? Platform.accent : Platform.textMuted
                        }
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 2
                            color: parent.active ? Platform.accent : "transparent"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                sidebarMode = index
                                // Drive the main page too (top nav removed):
                                // Words/Tags → Words page (0), Decks → Decks page (1).
                                appVM.currentPage = (index === 2) ? 1 : 0
                            }
                        }
                    }
                }
            }
        }

        // ── Filter input ──────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            color: Platform.bg
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1; color: Platform.border
            }
            TextField {
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                placeholderText: "Filter…"
                font.pixelSize: 12
                color: Platform.textPrimary
                background: Rectangle { color: "transparent" }
                onTextChanged: appVM.sidebarVM.filterText = text
            }
        }

        // ── Add button (context-sensitive: Word on Words tab, Deck on
        //    Decks tab; hidden on Tags) ──────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 40 : 0
            visible: sidebarMode === 0 || sidebarMode === 2
            color: Platform.surface
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1; color: Platform.border
            }
            Rectangle {
                id: addBtn
                anchors.centerIn: parent
                width: parent.width - 16
                height: 28
                radius: Platform.radius
                color: addBtnArea.containsMouse ? Platform.accentDark : Platform.accent
                Text {
                    anchors.centerIn: parent
                    text: sidebarMode === 0 ? "+ Word" : "+ Deck"
                    color: Platform.bg
                    font.pixelSize: 12
                    font.bold: true
                }
                MouseArea {
                    id: addBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (sidebarMode === 0) sidebarRoot.addWordRequested()
                        else if (sidebarMode === 2) sidebarRoot.addDeckRequested()
                    }
                }
            }
        }

        // ── Lists ─────────────────────────────────────────────
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: sidebarMode

            // Words
            ListView {
                id: wordListView
                clip: true
                model: appVM.wordVM.getAllWords()

                Connections {
                    target: appVM.wordVM
                    function onWordListChanged() {
                        wordListView.model = appVM.wordVM.getAllWords()
                    }
                }

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 38
                    color: appVM.wordVM.selectedWordId === modelData.wordId
                           ? Platform.surfaceAlt : "transparent"

                    Rectangle {
                        anchors { left: parent.left; bottom: parent.bottom }
                        width: 3; height: parent.height
                        color: Platform.accent
                        visible: appVM.wordVM.selectedWordId === modelData.wordId
                    }

                    Text {
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14
                        }
                        text: modelData.word
                        font.pixelSize: 13
                        color: Platform.textPrimary
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 1; color: Platform.border; opacity: 0.5
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            appVM.wordVM.selectWord(modelData.wordId)
                            appVM.currentPage = 0
                        }
                    }
                }

                // Empty state
                Text {
                    anchors.centerIn: parent
                    visible: wordListView.count === 0
                    text: "No words yet.\nClick + Word to add one."
                    color: Platform.textMuted
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Tags (tree: tag → words)
            ColumnLayout {
                spacing: 6

                // New-tag toolbar
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Platform.touchTarget * 0.85
                        color: Platform.bg
                        radius: Platform.radius - 2
                        border.color: newSidebarTag.activeFocus ? Platform.accent : Platform.border
                        border.width: 1

                        TextField {
                            id: newSidebarTag
                            anchors.fill: parent
                            anchors.margins: 5
                            placeholderText: "New tag\u2026"
                            placeholderTextColor: Platform.textMuted
                            color: Platform.textPrimary
                            font.pixelSize: Platform.fontBase - 1
                            background: null
                            onAccepted: createSidebarTag()
                        }
                    }

                    Rectangle {
                        implicitWidth: Platform.touchTarget * 0.85
                        implicitHeight: Platform.touchTarget * 0.85
                        radius: Platform.radius - 2
                        color: addSidebarTagArea.containsMouse ? Platform.accentDark : Platform.accent
                        Text {
                            anchors.centerIn: parent
                            text: "+"; color: Platform.bg
                            font.pixelSize: Platform.fontLarge; font.bold: true
                        }
                        MouseArea {
                            id: addSidebarTagArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: createSidebarTag()
                        }
                    }
                }

                ListView {
                    id: tagListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: appVM.sidebarVM.model

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 38
                        color: rowHover.hovered ? Platform.surfaceAlt : "transparent"

                        HoverHandler { id: rowHover }

                        RowLayout {
                            anchors { fill: parent; leftMargin: model.isTag ? 10 : 22; rightMargin: 8 }
                            spacing: 6
                            Text {
                                visible: model.isTag
                                text: model.expanded ? "▾" : "▸"
                                color: Platform.textMuted
                                font.pixelSize: 10
                            }
                            Text {
                                Layout.fillWidth: true
                                text: model.itemName
                                font.pixelSize: model.isTag ? 12 : 13
                                font.bold: model.isTag
                                color: model.isTag ? Platform.accent : Platform.textPrimary
                                elide: Text.ElideRight
                            }
                            // Delete tag (global) — only on tag rows, on hover.
                            Text {
                                visible: model.isTag && rowHover.hovered
                                text: "\u2715"
                                color: delTagArea.containsMouse ? Platform.danger : Platform.textMuted
                                font.pixelSize: Platform.fontBase
                                MouseArea {
                                    id: delTagArea
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: appVM.wordVM.deleteTag(model.itemId)
                                }
                            }
                        }
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 1; color: Platform.border; opacity: 0.4
                        }
                        MouseArea {
                            anchors.fill: parent
                            z: -1
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (model.isTag)
                                    appVM.sidebarVM.model.toggleExpanded(index)
                                else {
                                    appVM.wordVM.selectWord(model.itemId)
                                    appVM.currentPage = 0
                                }
                            }
                        }
                    }
                }

                function createSidebarTag() {
                    if (newSidebarTag.text.trim().length > 0) {
                        appVM.wordVM.createTag(newSidebarTag.text.trim())
                        newSidebarTag.text = ""
                        appVM.sidebarVM.reload()
                    }
                }
            }

            // Decks
            ListView {
                id: deckListView
                clip: true
                model: appVM.deckVM.deckModel

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 38
                    color: appVM.deckVM.selectedDeckId === model.deckId
                           ? Platform.surfaceAlt : "transparent"

                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: 3
                        color: Platform.accent
                        visible: appVM.deckVM.selectedDeckId === model.deckId
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 8 }
                        Text {
                            Layout.fillWidth: true
                            text: model.deckName
                            font.pixelSize: 13
                            color: Platform.textPrimary
                            elide: Text.ElideRight
                        }
                        Text {
                            text: "✦"
                            font.pixelSize: 9
                            color: Platform.textMuted
                            visible: model.isSmart
                        }
                    }
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 1; color: Platform.border; opacity: 0.5
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            appVM.deckVM.selectDeck(model.deckId)
                            appVM.currentPage = 1
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: deckListView.count === 0
                    text: "No decks yet.\nClick + Deck to add one."
                    color: Platform.textMuted
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // ── Import / Export footer ─────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: Platform.surface
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1; color: Platform.border
            }
            RowLayout {
                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                spacing: 8
                Repeater {
                    model: [{ label: "Import", act: 0 }, { label: "Export", act: 1 }]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: Platform.radius
                        color: ieArea.containsMouse ? Platform.surfaceAlt : Platform.bg
                        border.color: Platform.border
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: Platform.accentDark
                            font.pixelSize: 12
                            font.bold: true
                        }
                        MouseArea {
                            id: ieArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.act === 0 ? importDialog.open()
                                                                  : exportDialog.open()
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: exportDialog
        title: "Export collection"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "json"
        nameFilters: ["Tenjin export (*.json)"]
        onAccepted: appVM.exportData(selectedFile)
    }

    FileDialog {
        id: importDialog
        title: "Import collection"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Tenjin export (*.json)", "All files (*)"]
        onAccepted: appVM.importData(selectedFile)
    }

    // Mode state
    property int sidebarMode: 0
}

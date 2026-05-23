add_subdirectory(ViewModels)

# Files that must be tagged as QML singletons before being passed to
# qt_add_qml_module — set_source_files_properties() must execute in the same
# directory scope as the module declaration.
set_source_files_properties(Platform.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

# Media QML files are added only when their backing Qt module is enabled, so a
# lean build (MEDIA_SUPPORT=OFF / WEBVIEW_SUPPORT=OFF) doesn't try to compile
# QML that imports a module it wasn't linked against.
set(_TENJIN_MEDIA_QML "")
if(MEDIA_SUPPORT)
    list(APPEND _TENJIN_MEDIA_QML MediaPlayerView.qml)
endif()
if(WEBVIEW_SUPPORT)
    list(APPEND _TENJIN_MEDIA_QML WebEmbed.qml)
endif()

qt_add_qml_module(TenjinView
    URI            TenjinView
    VERSION        1.0
    STATIC
    OUTPUT_DIRECTORY  ${CMAKE_BINARY_DIR}/qml/TenjinView
    IMPORT_PATH       ${CMAKE_BINARY_DIR}/qml

    QML_FILES
        Main.qml
        ActionButton.qml
        Sidebar.qml
        Platform.qml
        WordPage.qml
        DeckListPage.qml
        DeckListPanel.qml
        DeckDetailPanel.qml
        ReviewPage.qml
        ContentBlock.qml
        GridContentView.qml
        TagChip.qml
        SearchBox.qml
        SearchBar.qml
        ConfirmDialog.qml
        AddWordDialog.qml
        AddDeckDialog.qml
        ${_TENJIN_MEDIA_QML}
)

target_link_libraries(TenjinView
    PRIVATE  TenjinViewModels
             Qt6::Quick
             Qt6::QuickControls2
             ${TENJIN_MEDIA_COMPONENTS}
             tenjin_warnings
             tenjin_sanitizers
)

# Feature macros (TENJIN_MEDIA / TENJIN_WEBVIEW). PUBLIC so the App target, which
# includes AppViewModel.h (it reads TENJIN_WEBVIEW), inherits them transitively.
target_compile_definitions(TenjinView
    PUBLIC   ${TENJIN_FEATURE_DEFINITIONS}
)

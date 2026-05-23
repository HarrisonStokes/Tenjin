qt_add_executable(Tenjin
    WIN32
    src/main.cpp
)

set_target_properties(Tenjin PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

target_link_libraries(Tenjin
    PRIVATE
        TenjinViewModels
        TenjinViewplugin
        Qt6::Quick
        Qt6::QuickControls2
        tenjin_warnings
        tenjin_sanitizers
)

target_include_directories(Tenjin PRIVATE src)

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    set_target_properties(Tenjin PROPERTIES
        MACOSX_BUNDLE                              TRUE
        MACOSX_BUNDLE_INFO_PLIST                   "${CMAKE_CURRENT_SOURCE_DIR}/ios/Info.plist"
        MACOSX_BUNDLE_BUNDLE_NAME                  "Tenjin"
        MACOSX_BUNDLE_BUNDLE_VERSION               "${PROJECT_VERSION}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING         "${PROJECT_VERSION}"
        MACOSX_BUNDLE_GUI_IDENTIFIER               "app.tenjin.Tenjin"
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER  "app.tenjin.Tenjin"
        XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "16.0"
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY     "1,2"
    )
    if(DEFINED APPLE_TEAM_ID)
        set_target_properties(Tenjin PROPERTIES
            XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${APPLE_TEAM_ID}"
        )
    endif()
endif()

# Windows: install + windeployqt handled entirely in cmake/Packaging.cmake
# (install(TARGETS) misresolves the .exe suffix for cross-compiled PE binaries,
# and Qt's generic deploy tool crashes on them). Linux/macOS use the standard
# install + Qt deploy script.
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    install(TARGETS Tenjin
        BUNDLE  DESTINATION .
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
    qt_generate_deploy_qml_app_script(
        TARGET               Tenjin
        OUTPUT_SCRIPT        deploy_script
        DEPLOY_TOOL_OPTIONS  --no-compiler-runtime --no-translations
    )
    install(SCRIPT ${deploy_script})
endif()

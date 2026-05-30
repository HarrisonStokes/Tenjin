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

# On a STATIC Qt build (iOS) the QSQLITE driver is a plugin that must be
# compiled into the binary; there is no runtime sqldrivers/ folder to load it
# from. Qt's automatic static-plugin import does NOT reliably pick up the SQL
# driver when Qt6::Sql reaches the executable only transitively (through the
# DatabaseManager static lib), so link the plugin target explicitly. Linking a
# Qt plugin target pulls in its *_init object, which emits Q_IMPORT_PLUGIN.
# Guarded by TARGET so it's a harmless no-op on dynamic desktop builds where the
# driver is loaded at runtime. Without this, addDatabase("QSQLITE") yields an
# invalid driver, db.open() fails, the DatabaseManager ctor throws, and the
# app terminates the instant it launches on iOS.
if(TARGET Qt6::QSQLiteDriverPlugin)
    target_link_libraries(Tenjin PRIVATE Qt6::QSQLiteDriverPlugin)
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    # CFBundleVersion must be a monotonically increasing build number (Apple +
    # AltStore reject re-installs whose build number didn't change). Default to
    # 1; CI/local can override with -DTENJIN_BUILD_NUMBER=<n> (e.g. the run
    # number) so each sideloaded build is distinct.
    if(NOT DEFINED TENJIN_BUILD_NUMBER)
        set(TENJIN_BUILD_NUMBER "1")
    endif()

    # The app icon asset catalog. Adding it to the target's sources lets Xcode
    # compile it into the bundle (producing the real icon files); the matching
    # name is set via XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME.
    target_sources(Tenjin PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/Assets.xcassets"
    )
    set_source_files_properties(
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/Assets.xcassets"
        PROPERTIES MACOSX_PACKAGE_LOCATION Resources
    )

    set_target_properties(Tenjin PROPERTIES
        MACOSX_BUNDLE                              TRUE
        MACOSX_BUNDLE_INFO_PLIST                   "${CMAKE_CURRENT_SOURCE_DIR}/ios/Info.plist"
        MACOSX_BUNDLE_BUNDLE_NAME                  "Tenjin"
        MACOSX_BUNDLE_BUNDLE_VERSION               "${TENJIN_BUILD_NUMBER}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING         "${PROJECT_VERSION}"
        MACOSX_BUNDLE_GUI_IDENTIFIER               "app.tenjin.Tenjin"
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER  "app.tenjin.Tenjin"
        XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "16.0"
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY     "1,2"
        XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
        # Default to "no team / sign later" so an unsigned device build succeeds
        # in CI; AltStore/Sideloadly/Xcode apply the real identity afterwards.
        XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED      "NO"
        XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED       "NO"
    )

    # If you build & sign locally in Xcode, pass -DAPPLE_TEAM_ID=XXXXXXXXXX to
    # flip on automatic signing with your Apple ID team.
    if(DEFINED APPLE_TEAM_ID)
        set_target_properties(Tenjin PROPERTIES
            XCODE_ATTRIBUTE_DEVELOPMENT_TEAM          "${APPLE_TEAM_ID}"
            XCODE_ATTRIBUTE_CODE_SIGN_STYLE           "Automatic"
            XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED     "YES"
            XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED      "YES"
        )
    endif()

    # Qt 6.8's QtMultimedia on iOS uses FFmpeg as its media backend, but the
    # Qt installer does NOT auto-link the FFmpeg frameworks. Without this call
    # the final link fails with hundreds of "Undefined symbols: _av_*, _avcodec_*,
    # _swr_*, _sws_*" errors. qt_add_ios_ffmpeg_libraries embeds the FFmpeg
    # frameworks (libavcodec, libavformat, libavutil, libswresample, libswscale)
    # from the Qt iOS kit into the .app bundle and configures rpath.
    # See: https://doc.qt.io/qt-6/qt-add-ios-ffmpeg-libraries.html
    if(MEDIA_SUPPORT)
        if(CMAKE_VERSION VERSION_LESS "3.28")
            message(FATAL_ERROR
                "iOS + MEDIA_SUPPORT=ON needs CMake >= 3.28 for qt_add_ios_ffmpeg_libraries. "
                "Either upgrade CMake, or configure with -DMEDIA_SUPPORT=OFF for iOS.")
        endif()
        if(COMMAND qt_add_ios_ffmpeg_libraries)
            # Unsigned CI builds: skip per-framework code-sign-on-copy. AltStore /
            # Sideloadly / Xcode re-sign the whole bundle (including embedded
            # frameworks) when they install. Skip is harmless for signed builds.
            set(QT_NO_FFMPEG_XCODE_EMBED_FRAMEWORKS_CODE_SIGN_ON_COPY ON)
            qt_add_ios_ffmpeg_libraries(Tenjin)
        else()
            message(FATAL_ERROR
                "qt_add_ios_ffmpeg_libraries is not available — Qt 6.8+ is required "
                "for iOS media support, or set -DMEDIA_SUPPORT=OFF.")
        endif()
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

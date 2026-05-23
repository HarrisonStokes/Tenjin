add_library(DatabaseManager STATIC
    src/DatabaseManager.cpp
    include/DatabaseManager/DatabaseManager.h
)

target_include_directories(DatabaseManager PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_link_libraries(DatabaseManager
    PUBLIC  Qt6::Core
            Qt6::Sql
    PRIVATE tenjin_warnings
            tenjin_sanitizers
)

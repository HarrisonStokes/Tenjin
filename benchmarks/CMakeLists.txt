function(tenjin_add_benchmark name)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs SOURCES LINK)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    add_executable(${name} ${ARG_SOURCES})

    set_target_properties(${name} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    )

    target_link_libraries(${name}
        PRIVATE
            benchmark::benchmark
            benchmark::benchmark_main
            tenjin_warnings
            ${ARG_LINK}
    )
endfunction()

add_subdirectory(Service)

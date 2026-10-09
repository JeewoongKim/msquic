# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

if(QUIC_BUILD_SHARED)
    message(FATAL_ERROR "Fuzz targets require a static MsQuic build")
endif()

if("$ENV{LIB_FUZZING_ENGINE}" STREQUAL "")
    message(FATAL_ERROR "LIB_FUZZING_ENGINE is required")
endif()

separate_arguments(
    FUZZING_ENGINE
    NATIVE_COMMAND
    "$ENV{LIB_FUZZING_ENGINE}"
)

function(add_oss_fuzzer target source)
    add_executable(${target} "${source}")

    target_compile_definitions(${target} PRIVATE
        CX_PLATFORM_LINUX
        QUIC_TEST_APIS
    )

    target_include_directories(${target} PRIVATE
        "${PROJECT_SOURCE_DIR}/src/test"
        "${PROJECT_SOURCE_DIR}/src/platform"
        "${PROJECT_SOURCE_DIR}/src/generated/common"
        "${PROJECT_SOURCE_DIR}/src/generated/linux"
        "${PROJECT_BINARY_DIR}/_deps/opensslquic-build/${QUIC_TLS_LIB}/include"
        "${PROJECT_SOURCE_DIR}/submodules/googletest/googletest/include"
        "${PROJECT_SOURCE_DIR}/submodules/googletest/googletest"
    )

    target_link_libraries(${target} PRIVATE
        inc
        msquic
        ${FUZZING_ENGINE}
    )

    set_target_properties(${target} PROPERTIES
        LINKER_LANGUAGE CXX
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/fuzzers"
        RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/fuzzers"
        RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/fuzzers"
    )
endfunction()

add_oss_fuzzer(datapath_raw_fuzz
    "${CMAKE_CURRENT_SOURCE_DIR}/datapath_raw_fuzz.c"
)

add_oss_fuzzer(fuzz
    "${CMAKE_CURRENT_SOURCE_DIR}/fuzz.cc"
)

add_oss_fuzzer(oss_fuzz_spinquic
    "${PROJECT_SOURCE_DIR}/src/tools/spin/spinquic.cpp"
)

target_compile_definitions(oss_fuzz_spinquic PRIVATE
    FUZZING
    QUIC_BUILD_STATIC
)

set_target_properties(oss_fuzz_spinquic PROPERTIES
    OUTPUT_NAME "spinquic"
)

add_custom_target(all_fuzzers
    DEPENDS
        datapath_raw_fuzz
        fuzz
        oss_fuzz_spinquic
)

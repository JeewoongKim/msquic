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

add_executable(datapath_raw_fuzz
    datapath_raw_fuzz.c
)

target_compile_definitions(datapath_raw_fuzz PRIVATE
    CX_PLATFORM_LINUX
    QUIC_TEST_APIS
)

target_include_directories(datapath_raw_fuzz PRIVATE
    "${PROJECT_SOURCE_DIR}/src/test"
    "${PROJECT_SOURCE_DIR}/src/platform"
    "${PROJECT_SOURCE_DIR}/src/generated/common"
    "${PROJECT_SOURCE_DIR}/src/generated/linux"
    "${PROJECT_BINARY_DIR}/_deps/opensslquic-build/${QUIC_TLS_LIB}/include"
    "${PROJECT_SOURCE_DIR}/submodules/googletest/googletest/include"
    "${PROJECT_SOURCE_DIR}/submodules/googletest/googletest"
)

target_link_libraries(datapath_raw_fuzz PRIVATE
    inc
    msquic
    ${FUZZING_ENGINE}
)

set_target_properties(datapath_raw_fuzz PROPERTIES
    LINKER_LANGUAGE CXX
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/fuzzers"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/fuzzers"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/fuzzers"
)

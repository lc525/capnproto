cmake_minimum_required(VERSION 2.8)
project(capnproto CXX C)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/stage)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/stage)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/stage)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ggdb3 -std=c++0x -fPIC")

include(fw)
fw_option(USE_SNAPPY OFF)
fw_option(BUILD_SAMPLES ON)
fw_option_summary()

include(ExternalProject)
include(CTest)
include(capnpc)
enable_testing()

add_subdirectory(compiler)
add_subdirectory(c++)

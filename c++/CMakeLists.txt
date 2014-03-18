cmake_minimum_required(VERSION 2.8)
project(capnproto CXX C)

option(USE_EXTERNAL_GTEST
    "Create external project for gtest, download and build it during `make`" OFF)
option(USE_SUBMODULE_GTEST
    "GTest exists in current build tree, use it as regular cmake target.
    All necessary include paths should be provided at the parent scope" OFF)
option(USE_EXTERNAL_CAPNP
    "Use capnp compiler and c++ plugin passed in $CAPNP and $CAPNPC_CXX
    environment variables respectively" OFF)

if("${CMAKE_BUILD_TYPE}" STREQUAL "")
    set(CMAKE_BUILD_TYPE Release CACHE STRING "")
endif()

if("${BUILD_SHARED_LIBS}" STREQUAL "")
    set(BUILD_SHARED_LIBS ON CACHE BOOL "")
endif()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../cmake)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(VERSION_MAJOR 0)
set(VERSION_MINOR 5)

execute_process(
    COMMAND git --git-dir ${CMAKE_CURRENT_SOURCE_DIR}/../.git rev-parse --short HEAD
    OUTPUT_VARIABLE GIT_REV
)
string(REPLACE "\n" "" GIT_REV ${GIT_REV})
set(SOVERSION "${VERSION_MAJOR}.${VERSION_MINOR}")
set(VERSION "${SOVERSION}-${GIT_REV}")
unset(GIT_REV)

find_package(Threads REQUIRED)
link_libraries(${CMAKE_THREAD_LIBS_INIT}) # -lpthread(s) for all targets

if(USE_EXTERNAL_GTEST)
    include(ExternalProject)
    ExternalProject_Add(gtest
        DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}/gtest
        SVN_REPOSITORY http://googletest.googlecode.com/svn/tags/release-1.7.0
        UPDATE_COMMAND ""
        CMAKE_ARGS -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        INSTALL_COMMAND ""
    )

    ExternalProject_Get_Property(gtest source_dir)
    ExternalProject_Get_Property(gtest binary_dir)
    set(GTEST_LIBRARY "${binary_dir}/libgtest.a")
    set(GTEST_MAIN_LIBRARY "${binary_dir}/libgtest_main.a")
    set(GTEST_INCLUDE_DIRECTORIES ${source_dir}/include)
elseif(USE_SUBMODULE_GTEST)
    set(GTEST_LIBRARY gtest)
    set(GTEST_MAIN_LIBRARY gtest_main)
else()
    find_package(GTest REQUIRED)
endif()

include_directories(${GTEST_INCLUDE_DIRECTORIES})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/src)

set(kj_sources
    src/kj/common.c++
    src/kj/units.c++
    src/kj/memory.c++
    src/kj/refcount.c++
    src/kj/array.c++
    src/kj/string.c++
    src/kj/string-tree.c++
    src/kj/exception.c++
    src/kj/debug.c++
    src/kj/arena.c++
    src/kj/io.c++
    src/kj/mutex.c++
    src/kj/thread.c++
    src/kj/main.c++
    src/kj/parse/char.c++
)

include(CMakeParseArguments)

macro(library)
    set(one_value_args NAME)
    set(multi_value_args SOURCES DEPENDS)
    cmake_parse_arguments(LIBRARY "" "${one_value_args}" "${multi_value_args}" ${ARGN})

    add_library(${LIBRARY_NAME} OBJECT ${LIBRARY_SOURCES})
    add_library(${LIBRARY_NAME}-shared SHARED $<TARGET_OBJECTS:${LIBRARY_NAME}>)
    add_library(${LIBRARY_NAME}-static STATIC $<TARGET_OBJECTS:${LIBRARY_NAME}>)

    set_target_properties(${LIBRARY_NAME}-shared PROPERTIES
        OUTPUT_NAME ${LIBRARY_NAME}
        VERSION ${VERSION}
        SOVERSION ${SOVERSION}
    )

    set_target_properties(${LIBRARY_NAME}-static PROPERTIES
        OUTPUT_NAME ${LIBRARY_NAME}
    )

    foreach(dep ${LIBRARY_DEPENDS})
        target_link_libraries(${LIBRARY_NAME}-static ${dep}-static)
        target_link_libraries(${LIBRARY_NAME}-shared ${dep}-shared)
    endforeach()

    install(TARGETS ${LIBRARY_NAME}-shared
        EXPORT capnproto
        COMPONENT SharedLibraries
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
    )

    install(TARGETS ${LIBRARY_NAME}-static
        EXPORT capnproto
        COMPONENT StaticLibraries
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
    )

endmacro()

library(
    NAME kj
    SOURCES ${kj_sources}
)

set(kj_async_sources
    src/kj/async.c++
    src/kj/async-unix.c++
    src/kj/async-io.c++
)

library(
    NAME kj-async
    SOURCES ${kj_async_sources}
    DEPENDS kj
)

set(capnp_sources
    src/capnp/c++.capnp.c++
    src/capnp/blob.c++
    src/capnp/arena.c++
    src/capnp/layout.c++
    src/capnp/list.c++
    src/capnp/any.c++
    src/capnp/message.c++
    src/capnp/schema.capnp.c++
    src/capnp/schema.c++
    src/capnp/schema-loader.c++
    src/capnp/dynamic.c++
    src/capnp/stringify.c++
    src/capnp/serialize.c++
    src/capnp/serialize-packed.c++
)

library(
    NAME capnp
    SOURCES ${capnp_sources}
    DEPENDS kj
)
set(capnp_rpc_sources
    src/capnp/serialize-async.c++
    src/capnp/capability.c++
    src/capnp/dynamic-capability.c++
    src/capnp/rpc.c++
    src/capnp/rpc.capnp.c++
    src/capnp/rpc-twoparty.c++
    src/capnp/rpc-twoparty.capnp.c++
    src/capnp/ez-rpc.c++
)

library(
    NAME capnp-rpc
    SOURCES ${capnp_rpc_sources}
    DEPENDS kj kj-async capnp
)

set(capnpc_sources
    src/capnp/compiler/md5.c++
    src/capnp/compiler/error-reporter.c++
    src/capnp/compiler/lexer.capnp.c++
    src/capnp/compiler/lexer.c++
    src/capnp/compiler/grammar.capnp.c++
    src/capnp/compiler/parser.c++
    src/capnp/compiler/node-translator.c++
    src/capnp/compiler/compiler.c++
    src/capnp/schema-parser.c++
)

library(
    NAME capnpc
    SOURCES ${capnpc_sources}
    DEPENDS kj capnp
)

set(capnp_binary_sources
    src/capnp/compiler/module-loader.c++
    src/capnp/compiler/capnp.c++
)

add_executable(capnp-exe ${capnp_binary_sources})
set_target_properties(capnp-exe PROPERTIES OUTPUT_NAME capnp)
target_link_libraries(capnp-exe kj-shared capnp-shared capnpc-shared)

add_executable(capnpc-capnp src/capnp/compiler/capnpc-capnp.c++)
target_link_libraries(capnpc-capnp kj-shared capnp-shared)

add_executable(capnpc-c++ src/capnp/compiler/capnpc-c++.c++)
target_link_libraries(capnpc-c++ kj-shared capnp-shared)

install(TARGETS
    capnp-exe
    capnpc-capnp
    capnpc-c++
    COMPONENT Compiler
    RUNTIME DESTINATION bin
)

install(CODE "execute_process(
    COMMAND \"${CMAKE_COMMAND}\" -E create_symlink capnp capnpc
    COMMAND \"ldconfig </dev/null > /dev/null 2>&1\"
    WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/bin
    )"
)

set(CPACK_COMPONENT_COMPILER_DEPENDS SharedLibraries)

install(FILES
    src/capnp/any.h
    src/capnp/blob.h
    src/capnp/capability.h
    src/capnp/c++.capnp
    src/capnp/c++.capnp.h
    src/capnp/common.h
    src/capnp/dynamic.h
    src/capnp/endian.h
    src/capnp/ez-rpc.h
    src/capnp/generated-header-support.h
    src/capnp/layout.h
    src/capnp/list.h
    src/capnp/message.h
    src/capnp/orphan.h
    src/capnp/pointer-helpers.h
    src/capnp/pretty-print.h
    src/capnp/rpc.capnp.h
    src/capnp/rpc.h
    src/capnp/rpc-prelude.h
    src/capnp/rpc-twoparty.capnp.h
    src/capnp/rpc-twoparty.h
    src/capnp/schema.capnp
    src/capnp/schema.capnp.h
    src/capnp/schema.h
    src/capnp/schema-loader.h
    src/capnp/schema-parser.h
    src/capnp/serialize-async.h
    src/capnp/serialize.h
    src/capnp/serialize-packed.h
    DESTINATION include/capnp
    COMPONENT Headers
)

install(FILES
    src/kj/arena.h
    src/kj/array.h
    src/kj/async.h
    src/kj/async-inl.h
    src/kj/async-io.h
    src/kj/async-prelude.h
    src/kj/async-unix.h
    src/kj/common.h
    src/kj/debug.h
    src/kj/exception.h
    src/kj/function.h
    src/kj/io.h
    src/kj/main.h
    src/kj/memory.h
    src/kj/mutex.h
    src/kj/one-of.h
    src/kj/refcount.h
    src/kj/string.h
    src/kj/string-tree.h
    src/kj/thread.h
    src/kj/threadlocal.h
    src/kj/tuple.h
    src/kj/units.h
    src/kj/vector.h
    DESTINATION include/kj
    COMPONENT Headers
)

install(FILES
    src/kj/parse/char.h
    src/kj/parse/common.h
    DESTINATION include/kj/parse
    COMPONENT Headers
)

install(EXPORT capnproto
    DESTINATION share/cmake
    COMPONENT CMakeModules
)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/../cmake/capnpc.cmake
    DESTINATION share/cmake
    COMPONENT CMakeModules
)

if(USE_EXTERNAL_CAPNP)
    set(CAPNPC_EXECUTABLE "$ENV{CAPNP}" CACHE STRING "")
    set(CAPNPC_CXX_EXECUTABLE "$ENV{CAPNPC_CXX}" CACHE STRING "")
else()
    get_target_property(CAPNPC_EXECUTABLE capnp-exe LOCATION)
    get_target_property(CAPNPC_CXX_EXECUTABLE capnpc-c++ LOCATION)
endif()

set(CAPNPC_IMPORT_PATH ${CMAKE_CURRENT_SOURCE_DIR}/src)

include(capnpc) # for capnp_generate_cpp()

set(test_capnpc_inputs
    src/capnp/test.capnp
    src/capnp/test-import.capnp
    src/capnp/test-import2.capnp
)

capnp_generate_cpp(test_capnpc_sources test_capnpc_headers ${test_capnpc_inputs})

set(capnp_test_sources
    ${test_capnpc_sources}
    src/kj/common-test.c++
    src/kj/memory-test.c++
    src/kj/refcount-test.c++
    src/kj/array-test.c++
    src/kj/string-test.c++
    src/kj/string-tree-test.c++
    src/kj/exception-test.c++
    src/kj/debug-test.c++
    src/kj/arena-test.c++
    src/kj/units-test.c++
    src/kj/tuple-test.c++
    src/kj/one-of-test.c++
    src/kj/function-test.c++
    src/kj/mutex-test.c++
    src/kj/async-test.c++
    src/kj/async-unix-test.c++
    src/kj/async-io-test.c++
    src/kj/parse/common-test.c++
    src/kj/parse/char-test.c++
    src/capnp/common-test.c++
    src/capnp/blob-test.c++
    src/capnp/endian-test.c++
    src/capnp/endian-fallback-test.c++
    src/capnp/endian-reverse-test.c++
    src/capnp/layout-test.c++
    src/capnp/any-test.c++
    src/capnp/message-test.c++
    src/capnp/capability-test.c++
    src/capnp/schema-test.c++
    src/capnp/schema-loader-test.c++
    src/capnp/dynamic-test.c++
    src/capnp/stringify-test.c++
    src/capnp/encoding-test.c++
    src/capnp/orphan-test.c++
    src/capnp/serialize-test.c++
    src/capnp/serialize-async-test.c++
    src/capnp/serialize-packed-test.c++
    src/capnp/rpc-test.c++
    src/capnp/rpc-twoparty-test.c++
    src/capnp/ez-rpc-test.c++
    src/capnp/test-util.c++
    src/capnp/compiler/lexer-test.c++
    src/capnp/compiler/md5-test.c++
)

add_executable(capnp-test ${capnp_test_sources})
target_link_libraries(capnp-test
    ${GTEST_LIBRARY}
    ${GTEST_MAIN_LIBRARY}
    kj-shared
    kj-async-shared
    capnp-shared
    capnp-rpc-shared
    capnpc-shared
)
add_test(capnp ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/capnp-test)
add_dependencies(capnp-test capnp-exe capnpc-c++)

add_executable(capnp-evolution-test src/capnp/compiler/evolution-test.c++)
target_link_libraries(capnp-evolution-test
    ${GTEST_LIBRARY}
    ${GTEST_MAIN_LIBRARY}
    kj-shared
    kj-async-shared
    capnp-shared
    capnp-rpc-shared
    capnpc-shared
)
add_test(capnp-evolution ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/capnp-evolution-test)

if(USE_EXTERNAL_GTEST)
    add_dependencies(capnp-test gtest)
    add_dependencies(capnp-evolution-test gtest)
endif()

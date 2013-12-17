cmake_minimum_required(VERSION 2.8.10)
project(samples)
set(NAME samples)

find_package(Threads REQUIRED)
link_libraries(${CMAKE_THREAD_LIBS_INIT})

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR})
list(APPEND CMAKE_CXX_FLAGS "-std=c++11")
include(external_capnp)
include_directories(${CAPNP_INCLUDE_DIRECTORIES})
include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_BINARY_DIR})

capnp_generate_cpp(addressbook_capnp_sources _ addressbook.capnp)

add_executable(addressbook ${addressbook_capnp_sources} addressbook.c++)
target_link_libraries(addressbook ${CAPNP_LIBRARIES})
add_dependencies(addressbook capnproto)

capnp_generate_cpp(calculator_capnp_sources __ calculator.capnp)

add_executable(calculator-client ${calculator_capnp_sources} calculator-client.c++)
target_link_libraries(calculator-client ${CAPNP_LIBRARIES})
add_dependencies(calculator-client capnproto)

add_executable(calculator-server ${calculator_capnp_sources} calculator-server.c++)
target_link_libraries(calculator-server ${CAPNP_LIBRARIES})
add_dependencies(calculator-server capnproto)

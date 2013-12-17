include(ExternalProject)

# gmock
ExternalProject_Add(gmock
    SVN_REPOSITORY http://googlemock.googlecode.com/svn/tags/release-1.7.0
    CMAKE_ARGS -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
    INSTALL_COMMAND ""
    UPDATE_COMMAND ""
)

ExternalProject_Get_Property(gmock source_dir)
ExternalProject_Get_Property(gmock binary_dir)

set(GTEST_LIBRARY "${binary_dir}/gtest/libgtest.a")
set(GTEST_MAIN_LIBRARY "${binary_dir}/gtest/libgtest_main.a")
list(APPEND GTEST_BOTH_LIBRARIES  ${GTEST_LIBRARY} ${GTEST_MAIN_LIBRARY})
set(GTEST_INCLUDE_DIRECTORIES ${source_dir}/gtest/include)

set(GMOCK_LIBRARY "${binary_dir}/libgmock.a")
set(GMOCK_MAIN_LIBRARY "${binary_dir}/libgmock_main.a")
list(APPEND GMOCK_BOTH_LIBRARIES  ${GMOCK_LIBRARY} ${GMOCK_MAIN_LIBRARY})
set(GMOCK_INCLUDE_DIRECTORIES ${source_dir}/include)

# capnproto
ExternalProject_Add(capnproto
    GIT_REPOSITORY https://github.com/isn-/capnproto.git
    GIT_TAG cmakeable
    DEPENDS gmock
    CMAKE_ARGS
        -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
        -DBUILD_SHARED_LIBS=ON
        -DUSE_EXTERNAL_GTEST=ON
        -DGTEST_INCLUDE_DIRECTORIES=${GTEST_INCLUDE_DIRECTORIES}
        -DGTEST_LIBRARY=${GTEST_LIBRARY}
        -DGTEST_MAIN_LIBRARY=${GTEST_MAIN_LIBRARY}
    INSTALL_COMMAND ""
    UPDATE_COMMAND ""
)

ExternalProject_Get_Property(capnproto source_dir)
ExternalProject_Get_Property(capnproto binary_dir)

set(CAPNP_LIBRARY "${binary_dir}/c++/libcapnp.so")
set(CAPNP_RPC_LIBRARY "${binary_dir}/c++/libcapnp-rpc.so")
set(CAPNPC_LIBRARY "${binary_dir}/c++/libcapnpc.so")
set(KJ_LIBRARY "${binary_dir}/c++/libkj.so")
set(KJ_ASYNC_LIBRARY "${binary_dir}/c++/libkj-async.so")
set(CAPNPC_EXECUTABLE "${binary_dir}/c++/capnp")
set(CAPNPC_CXX_EXECUTABLE "${binary_dir}/c++/capnpc-c++")
set(CAPNP_INCLUDE_DIRECTORIES "${source_dir}/c++/src")
list(APPEND CAPNP_LIBRARIES ${CAPNP_RPC_LIBRARY})
list(APPEND CAPNP_LIBRARIES ${CAPNP_LIBRARY})
list(APPEND CAPNP_LIBRARIES ${CAPNPC_LIBRARY})
list(APPEND CAPNP_LIBRARIES ${KJ_ASYNC_LIBRARY})
list(APPEND CAPNP_LIBRARIES ${KJ_LIBRARY})

function(CAPNP_GENERATE_CPP SRCS HDRS)
  if(NOT ARGN)
    message(SEND_ERROR "Error: CAPNP_GENERATE_CPP() called without any capnp files")
    return()
  endif(NOT ARGN)

  if(CAPNP_GENERATE_CPP_APPEND_PATH)
    foreach(FIL ${ARGN})
      get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
      get_filename_component(ABS_PATH ${ABS_FIL} PATH)
      list(FIND _capnp_include_path ${ABS_PATH} _contains_already)
      if(${_contains_already} EQUAL -1)
          list(APPEND _capnp_include_path --import-path=${ABS_PATH})
      endif()
    endforeach()
  else()
    set(_capnp_include_path --import-path=${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  set(${SRCS})
  set(${HDRS})
  foreach(FIL ${ARGN})
    get_filename_component(ABS_FIL ${FIL} ABSOLUTE)

    list(APPEND ${SRCS} "${CMAKE_CURRENT_BINARY_DIR}/${FIL}.c++")
    list(APPEND ${HDRS} "${CMAKE_CURRENT_BINARY_DIR}/${FIL}.h")

    add_custom_command(
      OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${FIL}.c++"
             "${CMAKE_CURRENT_BINARY_DIR}/${FIL}.h"
      COMMAND  ${CAPNPC_EXECUTABLE}
      ARGS compile --src-prefix=${CMAKE_CURRENT_SOURCE_DIR} --output=${CAPNPC_CXX_EXECUTABLE}:${CMAKE_CURRENT_BINARY_DIR} ${_capnp_include_path} -I${source_dir}/c++/src/ ${ABS_FIL}
      DEPENDS ${ABS_FIL}
      COMMENT "Running C++ capnp compiler on ${FIL}"
      VERBATIM )
  endforeach()

  set_source_files_properties(${${SRCS}} ${${HDRS}} PROPERTIES GENERATED TRUE)
  set(${SRCS} ${${SRCS}} PARENT_SCOPE)
  set(${HDRS} ${${HDRS}} PARENT_SCOPE)
endfunction()

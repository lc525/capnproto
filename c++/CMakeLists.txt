find_package(Threads REQUIRED)

ExternalProject_Add(gtest
     DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}/gtest
     SVN_REPOSITORY http://googletest.googlecode.com/svn/tags/release-1.6.0
     UPDATE_COMMAND ""
     PATCH_COMMAND patch -p0 < ${CMAKE_CURRENT_SOURCE_DIR}/gtest-1.6.0-c++11.patch
     CMAKE_ARGS -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
     INSTALL_COMMAND ""
)

ExternalProject_Get_Property(gtest source_dir)
include_directories(${source_dir}/include)
ExternalProject_Get_Property(gtest binary_dir)
set(gtest_library "${binary_dir}/libgtest.a")
set(gtest_main_library "${binary_dir}/libgtest_main.a")

if(USE_SNAPPY)
    ExternalProject_Add(snappy
         DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}/snappy
         SVN_REPOSITORY http://snappy.googlecode.com/svn/trunk
         SVN_REVISION -r 78
         CONFIGURE_COMMAND cd <SOURCE_DIR> && <SOURCE_DIR>/autogen.sh && cd - && <SOURCE_DIR>/configure
         BUILD_COMMAND ${MAKE}
         UPDATE_COMMAND ""
         INSTALL_COMMAND ""
    )

    ExternalProject_Get_Property(snappy source_dir)
    include_directories(${source_dir})
    ExternalProject_Get_Property(snappy binary_dir)
    set(SNAPPY_LIBRARIES "${binary_dir}/.libs/libsnappy.a")
endif()

include_directories(src)

add_subdirectory(src)

if(BUILD_SAMPLES)
    add_subdirectory(samples)
endif()

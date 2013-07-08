capnp_generate_cpp(schema_srcs schema_hdrs c++.capnp schema.capnp)

set(sources
    ${schema_srcs}
    arena.c++
    blob.c++
    dynamic.c++
    layout.c++
    list.c++
    message.c++
    schema.c++
    schema-loader.c++
    serialize.c++
    serialize-packed.c++
    stringify.c++
)

set(headers
    ${schema_hdrs}
    arena.h
    blob.h
    common.h
    dynamic.h
    endian.h
    generated-header-support.h
    layout.h
    list.h
    message.h
    orphan.h
    schema.h
    schema-loader.h
    serialize.h
    serialize-packed.h
    test-util.h
)

set(llibs kj)

if (USE_SNAPPY)
    list(APPEND sources serialize-snappy.c++)
    list(APPEND headers serialize-snappy.h)
    list(APPEND llibs ${snappy_library})
endif()

add_library(capnp STATIC ${sources} ${headers})
target_link_libraries(capnp kj ${llibs})

if(USE_SNAPPY)
    add_dependencies(capnp snappy)
endif()

set(tests
    test-util.h
    test-util.c++
    blob-test.c++
    dynamic-test.c++
    encoding-test.c++
    endian-fallback-test.c++
    endian-reverse-test.c++
    endian-test.c++
    layout-test.c++
    message-test.c++
    orphan-test.c++
    schema-loader-test.c++
    schema-test.c++
    serialize-packed-test.c++
    serialize-test.c++
    stringify-test.c++
)

if(USE_SNAPPY)
    list(APPEND tests serialize-snappy-test.c++)
endif()

capnp_generate_cpp(test_srcs test_hdrs test.capnp test-import.capnp)

add_executable(ut-capnp ${tests} ${test_srcs} ${test_hdrs})
target_link_libraries(ut-capnp capnp ${gtest_library} ${gtest_main_library})
add_dependencies(ut-capnp gtest)
add_test(ut-capnp "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/ut-capnp")

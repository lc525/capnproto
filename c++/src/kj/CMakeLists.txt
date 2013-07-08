set(sources
    array.c++
    common.c++
    debug.c++
    exception.c++
    io.c++
    memory.c++
    string.c++
    units.c++
)

set(headers
    array.h
    common.h
    debug.h
    exception.h
    io.h
    memory.h
    string.h
    tuple.h
    units.h
    vector.h
)

add_library(kj STATIC ${sources} ${headers})
target_link_libraries(kj ${CMAKE_THREAD_LIBS_INIT})

set(tests
    array-test.c++
    common-test.c++
    debug-test.c++
    exception-test.c++
    memory-test.c++
    string-test.c++
    tuple-test.c++
    units-test.c++
)

add_executable(ut-kj ${tests})
target_link_libraries(ut-kj kj ${gtest_library} ${gtest_main_library})
add_dependencies(ut-kj gtest)
add_test(ut-kj "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/ut-kj")

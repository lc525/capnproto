set(name sample-addressbook)

capnp_generate_cpp(srcs hdrs addressbook.capnp)
add_executable(${name}
    ${srcs}
    ${hdrs}
    addressbook.c++
)

target_link_libraries(${name} capnp)

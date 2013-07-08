#todo the entire file is a big piece of hack. rewrite it when c++ compiler will be released

set(target_binary
    ${CMAKE_CURRENT_SOURCE_DIR}/dist/build/capnpc/capnpc
)

add_custom_command(
    OUTPUT ${target_binary}
    COMMAND runhaskell Setup.hs configure --user
    COMMAND runhaskell Setup.hs build
    COMMAND runhaskell Setup.hs install
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Building capnpc"
    VERBATIM
)

add_custom_target(capnpc ALL DEPENDS ${target_binary})

macro(fw_option NAME DEFAULT_VALUE)
    if("${${NAME}}" STREQUAL "")
        set(${NAME} ${DEFAULT_VALUE})
    endif()
    list(APPEND __fw_options ${NAME})
endmacro()


macro(fw_option_summary)
    message(STATUS "Options summary:")
    foreach(__opt ${__fw_options})
        message(STATUS "  ${__opt} : ${${__opt}}")
    endforeach()
endmacro()

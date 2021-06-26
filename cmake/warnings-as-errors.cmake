function(_get_warnings_as_errors_flag out_flag)
    if (MSVC)
        set(${out_flag} "/WX" PARENT_SCOPE)
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(${out_flag} "-Werror" PARENT_SCOPE)
    else()
        message(WARNING "Warnings as error not supported for current compiler: ${CMAKE_CXX_COMPILER_ID}")
        set(${out_flag} "" PARENT_SCOPE)
    endif()
endfunction()

function(add_warnings_as_errors)
    _get_warnings_as_errors_flag(flag)
    add_compile_options("${flag}")
endfunction()

function(target_warnings_as_errors target private_public_interface)
    _get_warnings_as_errors_flag(flag)
    target_compile_options("${target}" "${private_public_interface}" "${flag}")
endfunction()

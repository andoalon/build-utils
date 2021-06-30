cmake_minimum_required(VERSION 3.15)
include_guard()

macro(set_old_msvc_runtime_policy)
    # Make cmake choose the visual studio runtime library the old way,
    # so that we can hack the flags, because that's the only way conan
    # currently detect the statically linked runtime.
    # If needs to be called before the 'project' call
    # (https://cmake.org/cmake/help/v3.15/prop_tgt/MSVC_RUNTIME_LIBRARY.html)
    
    if (PROJECT_NAME)
        message(FATAL_ERROR "set_old_msvc_runtime_policy() must be called BEFORE calling project()")
    endif()

    if (POLICY CMP0091)
        cmake_policy(SET CMP0091 OLD) # Modifies the policy of the caller
    endif()
endmacro()

function(set_static_msvc_runtime)
    if (NOT PROJECT_NAME)
        message(FATAL_ERROR "set_static_msvc_runtime() must be called AFTER calling project()")
    endif()

    if (NOT PROJECT_NAME STREQUAL CMAKE_PROJECT_NAME)
        message(WARNING "Setting MSVC runtime for project ${PROJECT_NAME} which is not the top-level one (${CMAKE_PROJECT_NAME})")
    endif()

    if (POLICY CMP0091)
        cmake_policy(POP) # We want to check the policies from the caller, not from this file

        cmake_policy(GET CMP0091 msvc_runtime_policy)
        if (NOT msvc_runtime_policy STREQUAL "OLD")
            message(FATAL_ERROR "CMP0091 not correctly set to \"OLD\"")
        endif()

        cmake_policy(PUSH) # Keep amount of PUSH/POP equal
    endif()

    if (MSVC)
        set(compiler_flags
                CMAKE_CXX_FLAGS
                CMAKE_CXX_FLAGS_DEBUG
                CMAKE_CXX_FLAGS_RELEASE
                CMAKE_CXX_FLAGS_RELWITHDEBINFO
                CMAKE_CXX_FLAGS_MINSIZEREL
                CMAKE_C_FLAGS
                CMAKE_C_FLAGS_DEBUG
                CMAKE_C_FLAGS_RELEASE
                CMAKE_C_FLAGS_RELWITHDEBINFO
                CMAKE_C_FLAGS_MINSIZEREL
                )
        foreach(compiler_flag ${compiler_flags})
            string(REPLACE "/MD" "/MT" ${compiler_flag} "${${compiler_flag}}")
            set(${compiler_flag} "${${compiler_flag}}" PARENT_SCOPE)

            # Not really necessary but otherwise the change won't show in
            # the cache which can be confusing
            set(${compiler_flag} "${${compiler_flag}}" CACHE STRING "" FORCE)
        endforeach()

        # The new way of doing it would be this: (cmake 3.15, and conan would need to start detecting this)
        #set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    endif()
endfunction()

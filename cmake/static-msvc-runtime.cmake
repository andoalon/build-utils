cmake_minimum_required(VERSION 3.15)
include_guard()

macro(set_old_msvc_runtime_policy)
    # Make cmake choose the visual studio runtime library the old way,
    # so that we can hack the flags, because that's the only way conan
    # currently detect the statically linked runtime.
    # If needs to be called before the 'project' call
    # (https://cmake.org/cmake/help/v3.15/prop_tgt/MSVC_RUNTIME_LIBRARY.html)
    cmake_policy(SET CMP0091 OLD)
endmacro()

macro(set_static_msvc_runtime)
    if (MSVC)
        set(CompilerFlags
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
        foreach(CompilerFlag ${CompilerFlags})
            string(REPLACE "/MD" "/MT" ${CompilerFlag} "${${CompilerFlag}}")
        endforeach()

        # The new way of doing it would be this: (cmake 3.15, and conan would need to start detecting this)
        #set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    endif()
endmacro()

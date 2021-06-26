function(_get_common_flags out_compiler_flags out_linker_flags)
    set(linker_flags)

    if (MSVC)
        set(compiler_flags
            "/W4"
            "/permissive-" # Disable most non-standard behavior
            "/utf-8"  # Both for source and execution. `/source-charset:utf-8` and `/execution-charset:utf-8` can be used instead for more granularity https://docs.microsoft.com/en-us/cpp/build/reference/utf-8-set-source-and-executable-character-sets-to-utf-8?view=msvc-160
            "/w14062" # -Wswitch https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-4-c4062?view=vs-2019
            "/w14165" # '`HRESULT`' is being converted to '`bool`'; are you sure this is what you want? https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-1-c4165?view=vs-2019
            "/w14191" # Cast between function pointers of different types https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-3-c4191?view=vs-2019
            "/w14242" # Lossy type conversion https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-3-c4191?view=vs-2019
            "/w14254" # Lossy type conversion but with operator
            "/w14263" # -Woverloaded-virtual https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-4-c4263?view=vs-2019
            "/w14265" # Polymorphic type without virtual destructor https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-3-c4265?view=vs-2019
            "/w14287" # Compare unsigned with negative literals https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-3-c4287?view=vs-2019
            "/w14296" # Expression is always false (-Wtautological-compare) https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-4-c4296?view=vs-2019
            "/w14355" # 'this' : used in base member initializer list https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-c4355?view=vs-2019
            "/w14471" # 'enumeration': a forward declaration of an unscoped enumeration must have an underlying type (int assumed) https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-4-c4471?view=vs-2019
            "/w14545" # expression before comma evaluates to a function which is missing an argument list https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-1-c4545?view=vs-2019
            "/w14546" # function call before comma missing argument list  https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-1-c4546?view=vs-2019
            "/w14547" # 'operator' : operator before comma has no effect; expected operator with side-effect https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-1-c4547?view=vs-2019
            "/w14548" # expression before comma has no effect; expected expression with side-effect https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-1-c4548?view=vs-2019
            "/w14549" # 'operator' : operator before comma has no effect; did you intend 'operator'?  https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-1-c4549?view=vs-2019
            "/w14555" # expression has no effect; expected expression with side-effect https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-1-c4555?view=vs-2019
            "/w14557" # '__assume' contains side-effect 'effect'
            "/w14574" # '_identifier_' is defined to be `0`: did you mean to use `#if` '_identifier_'? Checking ifdef something that's defined to 0
            "/w14643" # forward declaring 'identifier' in namespace std is not permitted by the C++ Standard
            "/w14640" # '_instance_' : construction of local static object is not thread-safe https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-3-c4640?view=vs-2019
        )

        set(linker_flags
            "/IGNORE:4099" # Missing .pdb file
        )
    # gcc or clang
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(compiler_flags
            "-Wall"
            "-Wextra"
            "-Wpedantic" # Non-standard C++ is used
            #"-Wcast-align" # Potential performance problem casts. Noisy, warns also when casting from char*
            "-Wswitch" # Switch on enum withou 'default' doesn't handle certain enumerator(s)
            "-Wconversion" # Type conversions that may lose data
            "-Wformat=2" # Security issues around functions that format output (e.g. printf)
            "-Wshadow" # Variable declaration shadows one from a parent context
            "-Woverloaded-virtual" # Overload (not override) a virtual function
            "-Wnon-virtual-dtor" # A class with virtual functions has a non-virtual destructor
            "-Wunused" # Anything being unused
            "-Wsign-conversion" # Sign conversions
            #"-Wdouble-promotion" # Float is implicit promoted to double
            "-Wold-style-cast" # C-style cast is used
            "-Wsuggest-override"
        )
    else()
        message(WARNING "Common warnings not supported for current compiler: ${CMAKE_CXX_COMPILER_ID}")
        set(compiler_flags)
    endif()

    # gcc only
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(compiler_flags
		    "-Wlogical-op" # Logical operations being used where bitwise were probably wanted
		    #"-Wuseless-cast" # Perform a cast to the same type
		    "-Wduplicated-cond" # if / else chain has duplicated conditions
		    "-Wmisleading-indentation" # Indentation implies blocks where blocks do not exist
		    "-Wnull-dereference" # Null dereference is detected
		    "-Wduplicated-branches" # if / else branches have duplicated code
            "-Wsuggest-attribute=noreturn"
            # Probably too noisy :(
            # -Wsuggest-attribute=pure
            # -Wsuggest-attribute=const
        )
    endif()
	
	# clang only
	if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
		set(compiler_flags
			"-Wparentheses" # Doing weird stuff in conditionals where precendence might not be clear or when there are side-effects
		)
	endif()

    set(${out_compiler_flags} "${compiler_flags}" PARENT_SCOPE)
    set(${out_linker_flags} "${linker_flags}" PARENT_SCOPE)
endfunction()

function(add_common_flags)
    _get_common_flags(compiler_flags linker_flags)
    
    add_compile_options("${compiler_flags}")
    add_link_options("${linker_flags}")
endfunction()

function(target_common_flags target private_public_interface)
    _get_common_flags(compiler_flags linker_flags)

    target_compile_options("${target}" "${private_public_interface}" "${compiler_flags}")
    target_link_options("${target}" "${private_public_interface}" "${linker_flags}")
endfunction()

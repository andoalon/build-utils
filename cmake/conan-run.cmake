include_guard()

include("${CMAKE_CURRENT_LIST_DIR}/conan.cmake")

function(_conan_get_profile_arg
	profile
	settings_keyword
	config
	out_profile_arg
)
	if (NOT EXISTS "${profile}")
		message(FATAL_ERROR "PROFILE ${profile} does not exist")
	endif()

	if (NOT IS_DIRECTORY "${profile}")
		set(${out_profile_arg} "${profile}" "${settings_keyword}" "build_type=${config}" PARENT_SCOPE)
		return()
	endif()

	if (NOT EXISTS "${profile}/${config}")
		message(FATAL_ERROR "Profile for configuration: ${config} does not exist in ${profile}/")
	endif()

	if (IS_DIRECTORY "${profile}/${config}")
		message(FATAL_ERROR "${profile}/${config} must be a file")
	endif()

	set(${out_profile_arg} "${profile}/${config}" PARENT_SCOPE)
endfunction()

function(_conan_get_profile_or_settings
	config
	profile
	profile_host
	profile_build
	out_profile_or_settings
)
	# Choose profile or settings
	if (profile AND (profile_host OR profile_build))
		message(FATAL_ERROR "Either PROFILE or PROFILE_HOST and PROFILE_BUILD can be provided, but not both")
	endif()

	if ((profile_host OR profile_build) AND NOT (profile_host AND profile_build))
		message(FATAL_ERROR "If PROFILE_HOST is provided then PROFILE_BUILD must be provided too and viceversa")
	endif()

	if (profile OR (profile_host AND profile_build))
		if (profile)
			_conan_get_profile_arg("${profile}" "SETTINGS" "${config}" profile_arg)
			set(profile_or_settings PROFILE ${profile_arg} PARENT_SCOPE)
		else()
			_conan_get_profile_arg("${profile_host}" "SETTINGS_HOST" "${config}" profile_host_arg)
			_conan_get_profile_arg("${profile_build}" "SETTINGS_BUILD" "${config}" profile_build_arg)

			set(profile_or_settings PROFILE_HOST ${profile_host_arg} PROFILE_BUILD ${profile_build_arg} PARENT_SCOPE)
		endif()
	else()
		conan_cmake_autodetect(conan_autodetected_settings BUILD_TYPE "${config}")
		set(profile_or_settings SETTINGS ${conan_autodetected_settings} PARENT_SCOPE)
	endif()
endfunction()

function(_conan_install name)
	set(options DYNAMIC_MSVC_RUNTIME)
	set(one_value_args DESTINATION RECIPE_FILE PROFILE PROFILE_HOST PROFILE_BUILD)
	set(multi_value_args EXTRA_SETTINGS OPTIONS OPTIONS_HOST OPTIONS_BUILD)
	cmake_parse_arguments(arg "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})
	if (arg_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "Unrecognized arguments: ${arg_UNPARSED_ARGUMENTS}")
	endif()
	
	# Don't process recipe if it has already been processed
	file(TIMESTAMP "${arg_RECIPE_FILE}" recipe_last_write_time)
	if (recipe_last_write_time STREQUAL "")
		message(WARNING "Cannot obtain last write time for file: \"${arg_RECIPE_FILE}\". Can't detect whether it was changed, so conan will be run")
	else()
		if(DEFINED CONAN_${name}_recipe_last_write_time
			AND recipe_last_write_time STREQUAL CONAN_${name}_recipe_last_write_time
			AND EXISTS "${arg_DESTINATION}"
		)
			message(STATUS "Skipping conan for ${arg_RECIPE_FILE} because it didn't change")
			return()
		endif()
	endif()
	unset(CONAN_${name}_recipe_last_write_time CACHE)

	message(STATUS "Running conan for: ${arg_RECIPE_FILE}")

	# Clean-up directories
	set(install_dir "${arg_DESTINATION}/modules")

	file(REMOVE_RECURSE "${arg_DESTINATION}")
	file(MAKE_DIRECTORY "${install_dir}")

	# Determine configurations to use
	get_cmake_property(generator_is_multi_config GENERATOR_IS_MULTI_CONFIG)
	if(generator_is_multi_config)
		if (NOT CMAKE_CONFIGURATION_TYPES)
			message(FATAL_ERROR "Please set a value for CMAKE_CONFIGURATION_TYPES (e.g. `set(CMAKE_CONFIGURATION_TYPES \"Debug\" \"Release\")`))")
		endif()

		set(configurations ${CMAKE_CONFIGURATION_TYPES})
		set(conan_generator "cmake_find_package_multi")
	else()
		if (NOT CMAKE_BUILD_TYPE)	
			message(FATAL_ERROR "Please set a value for CMAKE_BUILD_TYPE (e.g. `set(CMAKE_BUILD_TYPE \"Debug\")`)")
		endif()

		set(configurations ${CMAKE_BUILD_TYPE})
		set(conan_generator "cmake_find_package")
	endif()

	# Install dependencies for each configuration
	foreach(config ${configurations})
		_conan_get_profile_or_settings("${config}" "${arg_PROFILE}" "${arg_PROFILE_HOST}" "${arg_PROFILE_BUILD}" profile_or_settings)

		if (MSVC AND NOT "${arg_DYNAMIC_MSVC_RUNTIME}")
			set(msvc_runtime_value "compiler.runtime=MT")
			if (config STREQUAL "Debug")
				string(APPEND msvc_runtime_value "d")
			endif()
		else()
			set(msvc_runtime_value)
		endif()

		if (DEFINED arg_OPTIONS)
			set(arg_OPTIONS "OPTIONS" ${arg_OPTIONS})
		else()
			set(arg_OPTIONS)
		endif()

		if (DEFINED arg_OPTIONS_HOST)
			set(arg_OPTIONS_HOST "OPTIONS_HOST" ${arg_OPTIONS_HOST})
		else()
			set(arg_OPTIONS_HOST)
		endif()

		if (DEFINED arg_OPTIONS_BUILD)
			set(arg_OPTIONS_BUILD "OPTIONS_BUILD" ${arg_OPTIONS_BUILD})
		else()
			set(arg_OPTIONS_BUILD)
		endif()

		conan_cmake_install(
			PATH_OR_REFERENCE "${arg_RECIPE_FILE}"
			GENERATOR "${conan_generator}"
			BUILD "missing"
			INSTALL_FOLDER "${install_dir}"
			${arg_OPTIONS}
			${arg_OPTIONS_HOST}
			${arg_OPTIONS_BUILD}
			${profile_or_settings}
			SETTINGS ${arg_EXTRA_SETTINGS} ${msvc_runtime_value}
		)
	endforeach()

	# Write hash of the processed recipe to cache
	set(CONAN_${name}_recipe_last_write_time "${recipe_last_write_time}"
		CACHE STRING "Last write time of the ${name} conan recipe. Delete me to force re-run" FORCE)
endfunction()

function(conan_run)
	if(EXISTS "${PROJECT_SOURCE_DIR}/conanfile.py")
		if (EXISTS "${PROJECT_SOURCE_DIR}/conanfile.txt")
			message(FATAL_ERROR "Both conanfile.py and conanfile.txt exist in ${PROJECT_SOURCE_DIR}/. Please merge them into one")
			return()
		endif()
		
		set(recipe_file "${PROJECT_SOURCE_DIR}/conanfile.py")
	elseif(EXISTS "${PROJECT_SOURCE_DIR}/conanfile.txt")
		set(recipe_file "${PROJECT_SOURCE_DIR}/conanfile.txt")
	else()
		message(FATAL_ERROR "No conanfile.txt/conanfile.py found in ${PROJECT_SOURCE_DIR}")
		return()
	endif()

	# Trigger CMake re-run if the recipe changes
	set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${recipe_file}")

	set(project_conan_dir "${PROJECT_BINARY_DIR}/.conan")
	set(project_conan_module_dir "${project_conan_dir}/modules")

	# Process dependencies
	_conan_install(${PROJECT_NAME}
		RECIPE_FILE "${recipe_file}"
		DESTINATION "${project_conan_dir}"
		${ARGN}
	)

	# Configure CMake find_package() behavior for Conan's cmake_find_package generator
	set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${project_conan_module_dir}" PARENT_SCOPE)

	# Configure CMake find_package() behavior for Conan's cmake_find_package_multi generator
	set(CMAKE_FIND_PACKAGE_PREFER_CONFIG TRUE PARENT_SCOPE)
	set(CMAKE_FIND_ROOT_PATH ${CMAKE_FIND_ROOT_PATH} "${project_conan_module_dir}" PARENT_SCOPE)
	set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} "${project_conan_module_dir}" PARENT_SCOPE)
endfunction()

function(add_conan_bool_option_to_list out_options_list bool_option option_name)
	if (${bool_option})
		list(APPEND ${out_options_list} "${option_name}=True")
	else()
		list(APPEND ${out_options_list} "${option_name}=False")
	endif()
	set(${out_options_list} ${${out_options_list}} PARENT_SCOPE)
endfunction()

cmake_minimum_required(VERSION 3.17)

find_program(dot_program "dot" REQUIRED DOC "Tool required to convert graphviz graph files (.dot) to images")

if (NOT DEFINED graph_files_dir)
    message(FATAL_ERROR "'graph_files_dir' must be specified")
endif()

if (NOT EXISTS "${graph_files_dir}")
    message(FATAL_ERROR "The 'graph_files_dir' directory (\"${graph_files_dir}\") must exist")
endif()

if (NOT IS_DIRECTORY "${graph_files_dir}")
    message(FATAL_ERROR "'graph_files_dir' (\"${graph_files_dir}\") is not a directory")
endif()

set(output_dir "${graph_files_dir}/images")
# Don't remove the directory first since by this point it might contain conan_dependencies.html
file(MAKE_DIRECTORY ${output_dir})

file(GLOB graph_files "${graph_files_dir}/*.*")

list(LENGTH graph_files graph_file_count)
message(STATUS "Converting ${graph_file_count} graphviz files to images...")

foreach(graph_file IN LISTS graph_files)
    get_filename_component(graph_file_filename ${graph_file} NAME)
    execute_process(
        COMMAND "${dot_program}" "${graph_file}" -Tpng -o "${graph_file_filename}.png"
        WORKING_DIRECTORY ${output_dir}
    )
endforeach()

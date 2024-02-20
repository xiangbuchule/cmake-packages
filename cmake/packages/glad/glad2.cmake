include(ExternalProject)

# install python script
# script:   script file save path
# source:   source code path
# proxy:    build use proxy
# python:   python path dir
function(glad2_patch_script)
    # params
    cmake_parse_arguments(glad2 "" "script;source;proxy;python" "" ${ARGN})
    # set params
    set(script_content "\
# set glad info
set(glad_source         \"${glad2_source}\")
set(glad_proxy          \"${glad2_proxy}\")
# write CMakeLists.txt content
")
    # set other script
    set(cmake_build_content [[
cmake_minimum_required(VERSION 3.20)
# Silence warning about PROJECT_VERSION
cmake_policy(SET CMP0048 NEW)
# Enable MACOSX_RPATH by default
cmake_policy(SET CMP0042 NEW)
# Allow "IN_LIST" in "IF()"
cmake_policy(SET CMP0057 NEW)
# Silence warning about if()
cmake_policy(SET CMP0054 NEW)
if(CMAKE_VERSION VERSION_GREATER 3.8)
    # Enable IPO for CMake versions that support it
    cmake_policy(SET CMP0069 NEW)
endif()
]])
    if(NOT ("" STREQUAL "${glad2_python}"))
        if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
            string(REPLACE "/" "\\\\" glad2_python "${glad2_python}")
        else()
            string(REPLACE "\\" "/" glad2_python "${glad2_python}")
        endif()
        string(APPEND cmake_build_content "set(ENV{PATH} \"${glad2_python};\$ENV{PATH}\")\n")
    endif()

    string(APPEND cmake_build_content [[
project(GLAD LANGUAGES C)
# include function
include(cmake/CMakeLists.txt)
set(GLAD_SOURCE_PATH "${CMAKE_CURRENT_SOURCE_DIR}")
# Find the python interpreter, set the PYTHON_EXECUTABLE variable
if (CMAKE_VERSION VERSION_LESS 3.12)
    # this logic is deprecated in CMake after 3.12
    find_package(PythonInterp REQUIRED)
else()
    # the new hotness. This will preferentially find Python3 instead of Python2
    find_package(Python)
    set(PYTHON_EXECUTABLE ${Python_EXECUTABLE})
endif()

# Options
if(NOT DEFINED GLAD_OUT_PATH)
    set(GLAD_OUT_PATH "" CACHE STRING "Include directory")
else()
    file(MAKE_DIRECTORY "${GLAD_OUT_PATH}")
endif()
if(NOT DEFINED GLAD_API)
    set(GLAD_API "gl:compatibility=4.6" CACHE STRING "API name:profile/spec=version pairs, like gl:core=3.3,gles1/gl=2,gles2, no version means latest")
endif()
if(NOT DEFINED GLAD_LANGUAGE)
    set(GLAD_LANGUAGE "c" CACHE STRING "Glad language")
endif()
if(NOT DEFINED GLAD_EXTENSIONS)
    set(GLAD_EXTENSIONS "" CACHE STRING "Path to extensions file or comma separated list of extensions, if missing all extensions are included")
endif()
option(GLAD_QUIET "Build quiet" OFF)
option(GLAD_ALIAS "Enables function pointer aliasing" OFF)
option(GLAD_DEBUG "Enables generation of a debug build" OFF)
option(GLAD_MERGE "Merge multiple APIs of the same specification into one file" OFF)
option(GLAD_LOADER "Include internal loaders for APIs" OFF)
option(GLAD_EXCLUDE_FROM_ALL "Exclude building the library from the all target" OFF)
option(GLAD_MX "Enables support for multiple GL contexts" OFF)
option(GLAD_MXGLOBAL "Mimic global GL functions with context switching" OFF)
option(GLAD_ON_DEMAND "On-demand function pointer loading, initialize on use (experimental)" OFF)
option(GLAD_HEADERONLY "Generate a header only version of glad" OFF)
option(GLAD_REPRODUCIBLE "Makes the build reproducible by not fetching the latest specification from Khronos." OFF)
if(GLAD_MX AND GLAD_ON_DEMAND)
    message(FATAL_ERROR "option GLAD_MX can not be used together with GLAD_ON_DEMAND !!!")
endif()
if(BUILD_SHARED_LIBS)
    set(GLAD_BUILD_TYPE "SHARED")
else()
    set(GLAD_BUILD_TYPE "STATIC")
endif()
# add glad build option
set(GG_UNPARSED_ARGUMENTS_CACHE "" CACHE STRING "Glad build options")
if (NOT (IS_DIRECTORY "${GLAD_OUT_PATH}"))
    set(GLAD_OUT_PATH "${CMAKE_CURRENT_BINARY_DIR}/gladsources/glad")
endif()
if(${GLAD_QUIET})
    list(APPEND glad_build_option "QUIET")
endif()
if(${GLAD_ALIAS})
    list(APPEND glad_build_option "ALIAS")
endif()
if(${GLAD_DEBUG})
    list(APPEND glad_build_option "DEBUG")
endif()
if(${GLAD_MERGE})
    list(APPEND glad_build_option "MERGE")
endif()
if(${GLAD_LOADER})
    list(APPEND glad_build_option "LOADER")
endif()
if(${GLAD_EXCLUDE_FROM_ALL})
    list(APPEND glad_build_option "EXCLUDE_FROM_ALL")
endif()
if(${GLAD_MX})
    list(APPEND glad_build_option "MX")
endif()
if(${GLAD_MXGLOBAL})
    list(APPEND glad_build_option "MXGLOBAL")
endif()
if(${GLAD_ON_DEMAND})
    list(APPEND glad_build_option "ON_DEMAND")
endif()
if(${GLAD_HEADERONLY})
    list(APPEND glad_build_option "HEADERONLY")
endif()
if(${GLAD_REPRODUCIBLE})
    list(APPEND glad_build_option "REPRODUCIBLE")
endif()
# start build
if(${GLAD_EXTENSIONS})
    glad_add_library(
        glad ${GLAD_BUILD_TYPE} ${glad_build_option}
        LOCATION "${GLAD_OUT_PATH}"
        LANGUAGE ${GLAD_LANGUAGE}
        API ${GLAD_API}
        EXTENSIONS "${GLAD_EXTENSIONS}"
    )
else()
    glad_add_library(
        glad ${GLAD_BUILD_TYPE} ${glad_build_option}
        LOCATION "${GLAD_OUT_PATH}"
        LANGUAGE ${GLAD_LANGUAGE}
        API ${GLAD_API}
    )
endif()
# install library
install(
    TARGETS glad
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)
# install header
install(
    DIRECTORY ${GLAD_OUT_PATH}/include/glad ${GLAD_OUT_PATH}/include/KHR
    DESTINATION include
)
]])
    set(cmake_build_content "set(cmake_build_content [[\n${cmake_build_content}]])")
    set(script_content "${script_content}${cmake_build_content}")
    set(cmake_build_content [[
# write CMakeLists.txt
set(cmake_main_file "${glad_source}/CMakeLists.txt")
if(NOT EXISTS "${cmake_main_file}" OR IS_DIRECTORY "${cmake_main_file}")
    file(WRITE "${cmake_main_file}" "${cmake_build_content}")
endif()
# change file
set(cmake_config_file "${glad_source}/cmake/CMakeLists.txt")
file(READ "${cmake_config_file}" cmake_config)
string(REGEX REPLACE "-m glad" "glad/__main__.py" cmake_config "${cmake_config}")
file(WRITE "${cmake_config_file}" "${cmake_config}")
set(python_config_file "${glad_source}/glad/__main__.py")
file(READ "${python_config_file}" python_config)
string(REGEX REPLACE "import os" "import os\nimport sys\nsys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))\nimport glad" python_config "${python_config}")
set(ssl_replace_key "from glad.util import parse_apis")
set(ssl_replace_content "${ssl_replace_key}\nimport ssl\nssl._create_default_https_context = ssl._create_unverified_context")
if(NOT "${glad_proxy}" STREQUAL "")
    set(ssl_replace_content "${ssl_replace_content}\nos.environ['HTTPS_PROXY']='${glad_proxy}'")
endif()
string(REGEX REPLACE "${ssl_replace_key}" "${ssl_replace_content}" python_config "${python_config}")
file(WRITE "${python_config_file}" "${python_config}")
]])
    set(script_content "${script_content}\n\n${cmake_build_content}")
    if(NOT EXISTS "${glad2_script}" OR IS_DIRECTORY "${glad2_script}")
        file(WRITE "${glad2_script}" "${script_content}")
    endif()
endfunction()

# check and get cmake args params
# parameter:    check cmake parameter
# default:      default value
# result:       return value
function(get_cmake_args)
    # get other paramers
    cmake_parse_arguments(prefix "" "arg;default;result;args_list_name" "args_list" ${ARGN})
    # to toupper
    string(TOUPPER "${prefix_arg}" upper_arg)
    # get paramer length
    foreach(item IN LISTS prefix_args_list "${prefix_args_list_name}" prefix_UNPARSED_ARGUMENTS)
        list(APPEND cmake_args_list "${item}")
    endforeach()
    list(LENGTH cmake_args_list cmake_args_length)
    # get last index
    math(EXPR cmake_args_last_index "${cmake_args_length} - 1")
    # loop
    while(cmake_args_last_index GREATER -1)
        # get item
        list(GET cmake_args_list ${cmake_args_last_index} item)
        # to toupper
        string(TOUPPER "${item}" upper_item)
        # regex match
        string(REGEX MATCH "-D( *)?${upper_arg}( *)?=(.*)?" match_result "${upper_item}")
        if(match_result)
            # find = index
            string(FIND "${item}" "=" equal_index)
            # get length
            string(LENGTH "${item}" item_length)
            # start index
            math(EXPR equal_index "${equal_index} + 1")
            # substring length
            math(EXPR substring_length "${item_length} - ${equal_index}")
            # substring
            string(SUBSTRING "${item}" ${equal_index} ${substring_length} "${prefix_result}")
            string(STRIP "${${prefix_result}}" "${prefix_result}")
            # string(REPLACE "'"  "" "${prefix_result}" "${${prefix_result}}")
            # string(REPLACE "\"" "" "${prefix_result}" "${${prefix_result}}")
            set("${prefix_result}_FOUND" "YES" PARENT_SCOPE)
            set("${prefix_result}" "${${prefix_result}}" PARENT_SCOPE)
            return()
        endif()
        # index--
        math(EXPR cmake_args_last_index "${cmake_args_last_index} - 1")
    endwhile()
    set("${prefix_result}" "${prefix_default}" PARENT_SCOPE)
endfunction()

# replace repeat cmake args
# replace_list: need replace list name
# source_list:  need change list name
function(replace_cmake_args replace_list source_list)
    foreach(item IN LISTS "${replace_list}")
        string(STRIP "${item}" item)
        # to toupper
        string(TOUPPER "${item}" item)
        # regex match
        string(REGEX MATCH "-D(.*)?=(.*)?" match_result "${item}")
        if(match_result)
            # find = index
            string(FIND "${item}" "=" equal_index)
            # substring length
            math(EXPR substring_length "${equal_index} - 2")
            # substring
            string(SUBSTRING "${item}" 2 ${substring_length} cmake_args_tmp)
            string(STRIP "${cmake_args_tmp}" cmake_args_tmp)
            # is repeat
            foreach(source_item IN LISTS "${source_list}")
                string(TOUPPER "${source_item}" upper_source_item)
                # regex match
                string(REGEX MATCH "-D( *)?${cmake_args_tmp}( *)?=(.*)?" match_result "${upper_source_item}")
                if(match_result)
                    list(APPEND replace_list_tmp "${source_item}")
                endif()
            endforeach()
        endif()
    endforeach()
    # remove
    foreach(item IN LISTS replace_list_tmp)
        list(REMOVE_ITEM "${source_list}" "${item}")
    endforeach()
    # replace
    foreach(item IN LISTS "${replace_list}")
        list(APPEND "${source_list}" "${item}")
    endforeach()
    set("${source_list}" "${${source_list}}" PARENT_SCOPE)
endfunction()

# guess target file name
function(guess_binary_file)
    # params
    cmake_parse_arguments(file "" "name;prefix;remove_prefix;suffix;remove_suffix" "" ${ARGN})
    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        if(MSVC)
            set(lib_file_default_extension ".lib")
            set(lib_file_default_prefix "")
            set(lib_file_default_suffix "")
            set(bin_file_default_extension ".dll")
            set(bin_file_default_prefix "")
            set(bin_file_default_suffix "")
        elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(lib_file_default_extension ".a")
            set(lib_file_default_prefix "lib")
            set(lib_file_default_suffix ".dll")
            set(bin_file_default_extension ".dll")
            set(bin_file_default_prefix "lib")
            set(bin_file_default_suffix "")
        elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
            message(FATAL_ERROR "TODO Setting ...")
        else()
            message(FATAL_ERROR "TODO Setting ...")
        endif()
    elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
        if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(lib_file_default_extension ".a")
            set(lib_file_default_prefix "lib")
            set(lib_file_default_suffix "")
            set(bin_file_default_extension "so")
            set(bin_file_default_prefix "lib")
            set(bin_file_default_suffix "")
        endif()
    elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
        message(FATAL_ERROR "TODO Setting ...")
    else()
        message(FATAL_ERROR "TODO Setting ...")
    endif()
    set(lib_file_default_prefix "${file_prefix}")
    set(lib_file_default_suffix "${file_suffix}")
    set(bin_file_default_prefix "${file_prefix}")
    set(bin_file_default_suffix "${file_suffix}")
    if(file_remove_prefix)
        set(lib_file_default_prefix "")
        set(bin_file_default_prefix "")
    endif()
    if(file_remove_suffix)
        set(lib_file_default_suffix "")
        set(bin_file_default_suffix "")
    endif()
    set("${file_name}_lib" "${file_prefix}${file_name}${file_suffix}${lib_file_default_extension}" PARENT_SCOPE)
    set("${file_name}_bin" "${file_prefix}${file_name}${file_suffix}${bin_file_default_extension}" PARENT_SCOPE)
endfunction()

# name:     target name
# prefix:   prefix path
# version:  packages version
# proxy:    install glad proxy
# python:   python path dir
# deps:     deps target
# ARGN: this will add this to build cmake args
#   -DGLAD_OUT_PATH:            build out path
#   -DGLAD_API:                 API name:profile/spec=version pairs, like gl:core=3.3,gles1/gl=2,gles2, no version means latest
#   -DGLAD_LANGUAGE:            Glad language(c or rust)
#   -DGLAD_EXTENSIONS:          Path to extensions file or comma separated list of extensions, if missing all extensions are included
#   -DGLAD_QUIET:               Build quiet
#   -DGLAD_ALIAS:               Enables function pointer aliasing
#   -DGLAD_DEBUG:               Enables generation of a debug build
#   -DGLAD_MERGE:               Merge multiple APIs of the same specification into one file
#   -DGLAD_LOADER:              Include internal loaders for APIs
#   -DGLAD_EXCLUDE_FROM_ALL:    Exclude building the library from the all target
#   -DGLAD_MX:                  Enables support for multiple GL contexts
#   -DGLAD_MXGLOBAL:            imic global GL functions with context switching
#   -DGLAD_ON_DEMAND:           On-demand function pointer loading, initialize on use (experimental)
#   -DGLAD_HEADERONLY:          Generate a header only version of glad
#   -DGLAD_REPRODUCIBLE:        Makes the build reproducible by not fetching the latest specification from Khronos.
function(add_glad2)
    # params
    cmake_parse_arguments(glad "" "name;prefix;version;proxy;python" "deps" ${ARGN})
    # 如果已经存在就直接退出
    if((TARGET "${glad_name}") OR (DEFINED "${glad_name}-includes"))
        return()
    endif()
        # set pkg name
    set(pkg_name "pkg-${glad_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "glad_build_shared" args_list_name "glad_UNPARSED_ARGUMENTS")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "glad_build_type" args_list_name "glad_UNPARSED_ARGUMENTS")
    # check is out path
    get_cmake_args(arg "GLAD_OUT_PATH" default "" result "glad_binary" args_list_name "glad_UNPARSED_ARGUMENTS")
    # address
    set(glad_repository_url         "https://github.com/Dav1dde/glad")
    list(APPEND glad_version_list   "2.0.4")
    list(APPEND glad_hash_list      "A17876B0A8CA57086EF226CB3BB6DE3C62CEC1535A46F4FBE3FFC8158095B72A")
    # input version is in version list
    string(STRIP "${glad_version}" glad_version)
    if("${glad_version}" STREQUAL "")
        set(glad_version_index 0)
    else()
        list(FIND glad_version_list "${glad_version}" glad_version_index)
    endif()
    if(glad_version_index GREATER_EQUAL 0)
        set(glad_url   "https://codeload.github.com/Dav1dde/glad/zip/refs/tags/v${glad_version}")
        set(glad_file  "glad2-${glad_version}.zip")
        list(GET glad_hash_list ${glad_version_index} glad_hash)
    endif()
    # set build path
    set(glad_download   "${glad_prefix}/cache/download")
    set(glad_install    "${glad_prefix}/cache/install/${glad_name}/${glad_build_type}")
    set(glad_build      "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(glad_source     "${glad_prefix}/${glad_name}")
    set(glad_patch       "${glad_prefix}/cache/patch/${glad_name}")
    if("${glad_binary}" STREQUAL "")
        if(MSVC)
            set(glad_binary "${glad_prefix}/cache/bin/${glad_name}")
        else()
            set(glad_binary "${glad_prefix}/cache/bin/${glad_name}/${glad_build_type}")
        endif()
    endif()
    # set git config
    if(NOT ("" STREQUAL "${glad_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${glad_proxy} https.proxy=${glad_proxy})
    endif()
    # set url
    if(${glad_version_index} GREATER_EQUAL 0)
        set(glad_url_options    URL "${glad_url}" URL_HASH SHA256=${glad_hash} DOWNLOAD_NAME "${glad_file}")
    else()
        set(glad_url_options    GIT_REPOSITORY "${repository_url}" GIT_TAG "${glad_version}"
                                GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # build option
    set(glad_cmake_options  # default set shared/static
                            "-DBUILD_SHARED_LIBS=${glad_build_shared}"
                            # default set debug/release
                            "-DCMAKE_BUILD_TYPE=${glad_build_type}"
                            # default glad config
                            "-DGLAD_OUT_PATH='${glad_binary}'"
                            # "-DGLAD_API="
                            # "-DGLAD_LANGUAGE="
                            # "-DGLAD_EXTENSIONS="
                            # "-DGLAD_QUIET="
                            # "-DGLAD_ALIAS="
                            # "-DGLAD_DEBUG="
                            # "-DGLAD_MERGE="
                            # "-DGLAD_LOADER="
                            # "-DGLAD_EXCLUDE_FROM_ALL="
                            # "-DGLAD_MX="
                            # "-DGLAD_MXGLOBAL="
                            # "-DGLAD_ON_DEMAND="
                            # "-DGLAD_HEADERONLY="
                            # "-DGLAD_REPRODUCIBLE="
                            # default set lib/exe build path
                            "-DLIBRARY_OUTPUT_PATH='${glad_binary}'"
                            "-DEXECUTABLE_OUTPUT_PATH='${glad_binary}'"
                            "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${glad_binary}'"
                            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${glad_binary}'"
                            "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${glad_binary}'"
                            # default set lib install path
                            "-DCMAKE_INSTALL_PREFIX='${glad_install}'"
                            "-DCMAKE_INSTALL_LIBDIR='${glad_install}/lib'"
                            "-DCMAKE_INSTALL_BINDIR='${glad_install}/bin'"
                            "-DCMAKE_INSTALL_INCLUDEDIR='${glad_install}/include'"
                            # default set compile flags
                            "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                            "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                            "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                            "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                            "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                            "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("glad_UNPARSED_ARGUMENTS" "glad_cmake_options")
    # patch
    set(glad_patch_file "${glad_patch}/patch.cmake")
    glad2_patch_script(script "${glad_patch_file}" source "${glad_source}" proxy "${glad_proxy}" python "${glad_python}")
    set(glad_patch_option COMMAND "${CMAKE_COMMAND}" -P "${glad_patch_file}")
    # set step
    get_cmake_args(arg "GLAD_HEADERONLY" default "OFF" result "glad_header_only" args_list_name "glad_UNPARSED_ARGUMENTS")
    # msvc build command
    if(MSVC)
        set(glad_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${glad_build}" --config "${glad_build_type}")
        set(glad_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${glad_build}" --config "${glad_build_type}" --target INSTALL)
    endif()
    set(glad_terminal_options   USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${glad_download}" SOURCE_DIR "${glad_source}"
                                        ${glad_url_options} CMAKE_ARGS ${glad_cmake_options} EXCLUDE_FROM_ALL ON
                                        PATCH_COMMAND ${glad_patch_option} ${glad_build_cmd}
                                        ${glad_install_cmd} ${glad_terminal_options}
                                        DEPENDS ${glad_deps})
    # set target
    if(glad_header_only)
        set("${glad_name}-includes" "${glad_binary}/include" PARENT_SCOPE)
        add_library("${glad_name}" INTERFACE)
        target_include_directories("${glad_name}" INTERFACE "${glad_binary}/include")
        add_dependencies("${glad_name}" "${pkg_name}")
        return()
    endif()
    if(glad_build_shared)
        add_library("${glad_name}" SHARED IMPORTED GLOBAL)
        if(MSVC)
            set("${glad_name}-shared" ON PARENT_SCOPE)
        endif()
    else()
        add_library("${glad_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${glad_name}" "${pkg_name}")
    string(TOUPPER "${glad_build_type}" glad_build_type_upper)
    if("RELEASE" STREQUAL "${glad_build_type_upper}")
        set("${glad_name}-includes" "${glad_install}/include" PARENT_SCOPE)
        set(lib_path "${glad_install}/lib")
        set(bin_path "${glad_install}/bin")
    else()
        set("${glad_name}-includes" "${glad_binary}/include" PARENT_SCOPE)
        if(MSVC)
            set(lib_path "${glad_binary}/${glad_build_type}")
            set(bin_path "${glad_binary}/${glad_build_type}")
        else()
            set(lib_path "${glad_binary}")
            set(bin_path "${glad_binary}")
        endif()
    endif()
    guess_binary_file(name glad)
    set_target_properties("${glad_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${glad_lib}")
    if(glad_build_shared)
        set_target_properties("${glad_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${glad_bin}")
    endif()
endfunction()
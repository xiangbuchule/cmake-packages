include(ExternalProject)

# install zstd script
# script:   script file save path
# source:   source code path
# zlib:     zlib path dir
# bzip2:    bzip2 path dir
function(zstd_patch_script)
    # params
    cmake_parse_arguments(zstd "" "script;source" "" ${ARGN})
    # set params
    set(script_content "\
# set info
set(source  \"${zstd_source}\")
")
    string(APPEND script_content [[
# write CMakeLists.txt content
file(COPY "${source}/build/cmake/CMakeModules" DESTINATION "${source}")
file(GLOB files LIST_DIRECTORIES ON RELATIVE "${source}/build/cmake" "${source}/build/cmake/**")
list(REMOVE_ITEM files "CMakeModules" ".gitignore" "README.md" "CMakeLists.txt")
set(move_files "")
foreach(item IN LISTS files)
    if(IS_DIRECTORY "${source}/build/cmake/${item}")
        file(GLOB_RECURSE move_files_t "${source}/build/cmake/${item}" "${source}/build/cmake/${item}/*.cmake")
        file(GLOB_RECURSE move_files_tt "${source}/build/cmake/${item}" "${source}/build/cmake/${item}/*.txt")
        file(GLOB_RECURSE move_files_ttt "${source}/build/cmake/${item}" "${source}/build/cmake/${item}/*.cmake.in")
        list(APPEND move_files ${move_files_t} ${move_files_tt} ${move_files_ttt})
    else()
        file(COPY "${source}/build/cmake/${item}" DESTINATION "${source}")
    endif()
endforeach()
string(REGEX REPLACE "(^;)|(;$)" "" move_files "${move_files}")
string(REGEX REPLACE ";+" ";" move_files "${move_files}")
foreach(item IN LISTS move_files)
    file(RELATIVE_PATH move_path "${source}/build/cmake" "${item}")
    file(COPY_FILE "${item}" "${source}/${move_path}")
endforeach()
set(regex_string "set(ZSTD_SOURCE_DIR \"\${CMAKE_CURRENT_SOURCE_DIR}/../..\")")
file(READ "${source}/build/cmake/CMakeLists.txt" content)
string(REPLACE "${regex_string}" "set(ZSTD_SOURCE_DIR \"\${CMAKE_CURRENT_SOURCE_DIR}\")" content "${content}")
file(WRITE "${source}/CMakeLists.txt" "${content}")
]])
    file(WRITE "${zstd_script}" "${script_content}")
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
#   name:       binary name
#   lib_prefix: lib prefix name
#   lib_suffix: lib suffix name
#   bin_prefix: bin prefix name
#   bin_suffix: bin suffix name
function(guess_binary_file)
    # params
    cmake_parse_arguments(file "" "name;lib_prefix;lib_suffix;bin_prefix;bin_suffix" "" ${ARGN})
    # set default
    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        if(MSVC)
            set(lib_extension ".lib")
            set(bin_extension ".dll")
        elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(lib_extension ".a")
            set(lib_prefix "lib")
            set(lib_suffix ".dll")
            set(bin_extension ".dll")
            set(bin_prefix "lib")
        elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
            message(FATAL_ERROR "TODO Setting ...")
        else()
            message(FATAL_ERROR "TODO Setting ...")
        endif()
    elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
        if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(lib_extension ".a")
            set(lib_prefix "lib")
            set(bin_extension ".so")
            set(lib_prefix "lib")
        endif()
    elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
        message(FATAL_ERROR "TODO Setting ...")
    else()
        message(FATAL_ERROR "TODO Setting ...")
    endif()
    # set prefix/suffix
    if(NOT ("${lib_prefix}" STREQUAL "${file_lib_prefix}"))
        set(lib_prefix "${file_lib_prefix}")
    endif()
    if(NOT ("${lib_suffix}" STREQUAL "${file_lib_suffix}"))
        set(lib_suffix "${file_lib_suffix}")
    endif()
    if(NOT ("${bin_prefix}" STREQUAL "${file_bin_prefix}"))
        set(bin_prefix "${file_bin_prefix}")
    endif()
    if(NOT ("${bin_suffix}" STREQUAL "${file_bin_suffix}"))
        set(bin_suffix "${file_bin_suffix}")
    endif()
    set("${file_name}_lib" "${lib_prefix}${file_name}${lib_suffix}${lib_extension}" PARENT_SCOPE)
    set("${file_name}_bin" "${bin_prefix}${file_name}${bin_suffix}${bin_extension}" PARENT_SCOPE)
endfunction()

# name:     target name
# prefix:   prefix path
# version:  packages version
# deps:     deps target
# zlib:     zlib path dir
# bzip2:    bzip2 path dir
# ARGN: this will add this to build cmake args
#   ZSTD_BUILD_PROGRAMS:    OFF
#   ZSTD_BUILD_TESTS:       OFF
#   BUILD_TESTING:          OFF
function(add_zstd)
    # params
    cmake_parse_arguments(zstd "" "name;prefix;version;proxy" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${zstd_name}" OR (DEFINED "${zstd_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${zstd_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "zstd_build_shared" args_list_name "zstd_UNPARSED_ARGUMENTS")
    if(zstd_build_shared)
        set(zstd_build_static OFF)
    else()
        set(zstd_build_static ON)
    endif()
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "zstd_build_type" args_list_name "zstd_UNPARSED_ARGUMENTS")
    # address
    set(zstd_repository_url          "https://github.com/facebook/zstd")
    list(APPEND zstd_version_list    "1.5.5")
    list(APPEND zstd_hash_list       "9C4396CC829CFAE319A6E2615202E82AAD41372073482FCE286FAC78646D3EE4")
    # input version is in version list
    string(STRIP "${zstd_version}" zstd_version)
    if("${zstd_version}" STREQUAL "")
        set(zstd_version_index 0)
    else()
        list(FIND zstd_version_list "${zstd_version}" zstd_version_index)
    endif()
    if(zstd_version_index GREATER_EQUAL 0)
        set(zstd_url   "${zstd_repository_url}/releases/download/v${zstd_version}/zstd-${zstd_version}.tar.gz")
        set(zstd_file  "zstd-${zstd_version}.tar.gz")
        list(GET zstd_hash_list ${zstd_version_index} zstd_hash)
    endif()
    # set build path
    set(zstd_download  "${zstd_prefix}/cache/download")
    set(zstd_install   "${zstd_prefix}/cache/install/${zstd_name}/${zstd_build_type}")
    set(zstd_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(zstd_source    "${zstd_prefix}/${zstd_name}")
    set(zstd_patch     "${zstd_prefix}/cache/patch/${zstd_name}")
    if(MSVC)
        set(zstd_binary "${zstd_prefix}/cache/bin/${zstd_name}")
    else()
        set(zstd_binary "${zstd_prefix}/cache/bin/${zstd_name}/${zstd_build_type}")
    endif()
    # build option
    set(zstd_cmake_options   # default options
                            "-DZSTD_BUILD_PROGRAMS=OFF"
                            "-DZSTD_BUILD_TESTS=OFF"
                            "-DBUILD_TESTING=OFF"
                            "-DZSTD_BUILD_SHARED=${zstd_build_shared}"
                            "-DZSTD_BUILD_STATIC=${zstd_build_static}"
                            # default set shared/static
                            "-DBUILD_SHARED_LIBS=${zstd_build_shared}"
                            # default set debug/release
                            "-DCMAKE_BUILD_TYPE=${zstd_build_type}"
                            # default set lib/exe build path
                            "-DLIBRARY_OUTPUT_PATH='${zstd_binary}'"
                            "-DEXECUTABLE_OUTPUT_PATH='${zstd_binary}'"
                            "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${zstd_binary}'"
                            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${zstd_binary}'"
                            "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${zstd_binary}'"
                            # default set lib install path
                            "-DCMAKE_INSTALL_PREFIX='${zstd_install}'"
                            "-DCMAKE_INSTALL_LIBDIR='${zstd_install}/lib'"
                            "-DCMAKE_INSTALL_BINDIR='${zstd_install}/bin'"
                            "-DCMAKE_INSTALL_INCLUDEDIR='${zstd_install}/include'"
                            # default set compile flags
                            "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                            "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                            "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                            "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                            "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                            "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("zstd_UNPARSED_ARGUMENTS" "zstd_cmake_options")
    # is install
    if(MSVC)
        set(zstd_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${zstd_build}" --config "${zstd_build_type}")
        set(zstd_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${zstd_build}" --config "${zstd_build_type}" --target INSTALL)
    endif()
    # set git config
    if(NOT ("" STREQUAL "${zstd_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${zstd_proxy} https.proxy=${zstd_proxy})
    endif()
    # set url option
    if(${zstd_version_index} GREATER_EQUAL 0)
        set(zstd_url_option URL "${zstd_url}" URL_HASH SHA256=${zstd_hash} DOWNLOAD_NAME "${zstd_file}")
    else()
        set(zstd_url_option GIT_REPOSITORY "${zstd_repository_url}" GIT_TAG "${zstd_version}"
                            GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # patch
    set(zstd_patch_file "${zstd_patch}/patch.cmake")
    zstd_patch_script(script "${zstd_patch_file}" source "${zstd_source}")
    set(zstd_patch_cmd PATCH_COMMAND COMMAND "${CMAKE_COMMAND}" -P "${zstd_patch_file}")
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${zstd_download}" SOURCE_DIR "${zstd_source}"
                                        ${zstd_url_option} CMAKE_ARGS ${zstd_cmake_options} EXCLUDE_FROM_ALL ON
                                        ${zstd_patch_cmd} ${zstd_build_cmd} ${zstd_install_cmd} DEPENDS ${zstd_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # check is build shared/static
    if(zstd_build_shared)
        add_library("${zstd_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${zstd_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${zstd_name}" "${pkg_name}")
    # set lib path dir
    set(lib_path "${zstd_install}/lib")
    set(bin_path "${zstd_install}/bin")
    set("${zstd_name}-includes"     "${zstd_install}/include"   PARENT_SCOPE)
    set("${zstd_name}-cmake"        "${lib_path}/cmake/zstd"    PARENT_SCOPE)
    set("${zstd_name}-pkgconfig"    "${lib_path}/pkgconfig"     PARENT_SCOPE)
    set("${zstd_name}-root"         "${zstd_install}"           PARENT_SCOPE)
    set("${zstd_name}-source"       "${zstd_source}"            PARENT_SCOPE)
    guess_binary_file(name "zstd")
    set_target_properties("${zstd_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${zstd_lib}")
    if(zstd_build_shared)
        set_target_properties("${zstd_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${zstd_bin}")
    endif()
endfunction()

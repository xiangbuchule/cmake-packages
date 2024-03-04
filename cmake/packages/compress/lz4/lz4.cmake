include(ExternalProject)

# install lz4 script
# script:   script file save path
# source:   source code path
# zlib:     zlib path dir
# bzip2:    bzip2 path dir
function(lz4_patch_script)
    # params
    cmake_parse_arguments(lz4 "" "script;source" "" ${ARGN})
    # set params
    set(script_content "\
# set info
set(source  \"${lz4_source}\")
")
    string(APPEND script_content [[
# write CMakeLists.txt content
file(COPY "${source}/build/cmake/lz4Config.cmake.in" DESTINATION "${source}")
set(regex_string "set(LZ4_TOP_SOURCE_DIR \"\${CMAKE_CURRENT_SOURCE_DIR}/../..\")")
file(READ "${source}/build/cmake/CMakeLists.txt" content)
string(REPLACE "${regex_string}" "set(LZ4_TOP_SOURCE_DIR \"\${CMAKE_CURRENT_SOURCE_DIR}\")" content "${content}")
file(WRITE "${source}/CMakeLists.txt" "${content}")
]])
    file(WRITE "${lz4_script}" "${script_content}")
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
#   LZ4_BUILD_CLI:  OFF
#   LZ4_BUILD_LEGACY_LZ4C:  OFF
function(add_lz4)
    # params
    cmake_parse_arguments(lz4 "" "name;prefix;version;proxy" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${lz4_name}" OR (DEFINED "${lz4_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${lz4_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "lz4_build_shared" args_list_name "lz4_UNPARSED_ARGUMENTS")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "lz4_build_type" args_list_name "lz4_UNPARSED_ARGUMENTS")
    # address
    set(lz4_repository_url          "https://github.com/lz4/lz4")
    list(APPEND lz4_version_list    "1.9.4")
    list(APPEND lz4_hash_list       "0B0E3AA07C8C063DDF40B082BDF7E37A1562BDA40A0FF5272957F3E987E0E54B")
    # input version is in version list
    string(STRIP "${lz4_version}" lz4_version)
    if("${lz4_version}" STREQUAL "")
        set(lz4_version_index 0)
    else()
        list(FIND lz4_version_list "${lz4_version}" lz4_version_index)
    endif()
    if(lz4_version_index GREATER_EQUAL 0)
        set(lz4_url   "${lz4_repository_url}/releases/download/v${lz4_version}/lz4-${lz4_version}.tar.gz")
        set(lz4_file  "lz4-${lz4_version}.tar.gz")
        list(GET lz4_hash_list ${lz4_version_index} lz4_hash)
    endif()
    # set build path
    set(lz4_download  "${lz4_prefix}/cache/download")
    set(lz4_install   "${lz4_prefix}/cache/install/${lz4_name}/${lz4_build_type}")
    set(lz4_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(lz4_source    "${lz4_prefix}/${lz4_name}")
    set(lz4_patch     "${lz4_prefix}/cache/patch/${lz4_name}")
    if(MSVC)
        set(lz4_binary "${lz4_prefix}/cache/bin/${lz4_name}")
    else()
        set(lz4_binary "${lz4_prefix}/cache/bin/${lz4_name}/${lz4_build_type}")
    endif()
    # build option
    set(lz4_cmake_options   # default options
                            "-DLZ4_BUILD_CLI=OFF"
                            "-DLZ4_BUILD_LEGACY_LZ4C=OFF"
                            # default set shared/static
                            "-DBUILD_SHARED_LIBS=${lz4_build_shared}"
                            # default set debug/release
                            "-DCMAKE_BUILD_TYPE=${lz4_build_type}"
                            # default set lib/exe build path
                            "-DLIBRARY_OUTPUT_PATH='${lz4_binary}'"
                            "-DEXECUTABLE_OUTPUT_PATH='${lz4_binary}'"
                            "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${lz4_binary}'"
                            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${lz4_binary}'"
                            "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${lz4_binary}'"
                            # default set lib install path
                            "-DCMAKE_INSTALL_PREFIX='${lz4_install}'"
                            "-DCMAKE_INSTALL_LIBDIR='${lz4_install}/lib'"
                            "-DCMAKE_INSTALL_BINDIR='${lz4_install}/bin'"
                            "-DCMAKE_INSTALL_INCLUDEDIR='${lz4_install}/include'"
                            # default set compile flags
                            "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                            "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                            "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                            "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                            "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                            "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("lz4_UNPARSED_ARGUMENTS" "lz4_cmake_options")
    # is install
    if(MSVC)
        set(lz4_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${lz4_build}" --config "${lz4_build_type}")
        set(lz4_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${lz4_build}" --config "${lz4_build_type}" --target INSTALL)
    endif()
    # set git config
    if(NOT ("" STREQUAL "${lz4_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${lz4_proxy} https.proxy=${lz4_proxy})
    endif()
    # set url option
    if(${lz4_version_index} GREATER_EQUAL 0)
        set(lz4_url_option URL "${lz4_url}" URL_HASH SHA256=${lz4_hash} DOWNLOAD_NAME "${lz4_file}")
    else()
        set(lz4_url_option  GIT_REPOSITORY "${lz4_repository_url}" GIT_TAG "${lz4_version}"
                            GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # patch
    set(lz4_patch_file "${lz4_patch}/patch.cmake")
    lz4_patch_script(script "${lz4_patch_file}" source "${lz4_source}")
    set(lz4_patch_cmd PATCH_COMMAND COMMAND "${CMAKE_COMMAND}" -P "${lz4_patch_file}")
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${lz4_download}" SOURCE_DIR "${lz4_source}"
                                        ${lz4_url_option} CMAKE_ARGS ${lz4_cmake_options} EXCLUDE_FROM_ALL ON
                                        ${lz4_patch_cmd} ${lz4_build_cmd} ${lz4_install_cmd} DEPENDS ${lz4_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # check is build shared/static
    if(lz4_build_shared)
        add_library("${lz4_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${lz4_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${lz4_name}" "${pkg_name}")
    # set lib path dir
    set(lib_path "${lz4_install}/lib")
    set(bin_path "${lz4_install}/bin")
    set("${lz4_name}-includes"  "${lz4_install}/include"    PARENT_SCOPE)
    set("${lz4_name}-cmake"     "${lib_path}/cmake/lz4"     PARENT_SCOPE)
    set("${lz4_name}-pkgconfig" "${lib_path}/pkgconfig"     PARENT_SCOPE)
    set("${lz4_name}-root"      "${lz4_install}"            PARENT_SCOPE)
    set("${lz4_name}-source"    "${lz4_source}"             PARENT_SCOPE)
    guess_binary_file(name "lz4")
    set_target_properties("${lz4_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${lz4_lib}")
    if(lz4_build_shared)
        set_target_properties("${lz4_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${lz4_bin}")
    endif()
endfunction()

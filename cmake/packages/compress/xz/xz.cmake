include(ExternalProject)

# install xz script
# script:   script file save path
# source:   source code path
# zlib:     zlib path dir
# bzip2:    bzip2 path dir
function(xz_patch_script)
    # params
    cmake_parse_arguments(xz "" "script;source" "" ${ARGN})
    # set params
    set(script_content "\
# set info
set(source  \"${xz_source}\")
set(zlib    \"${xz_zlib}\")
set(bzip2   \"${xz_bzip2}\")
")
    string(APPEND script_content [[
# write CMakeLists.txt content
set(regex_string "include(CheckFunctionExists)")
string(APPEND replace_content "${regex_string}\n")
file(READ "${source}/CMakeLists.txt" old_content)
if(NOT ("" STREQUAL "${zlib}"))
    string(APPEND replace_content "set(ZLIB_ROOT \"${zlib}\")\n")
endif()
if(NOT ("" STREQUAL "${bzip2}"))
    string(APPEND replace_content "set(ENV{PATH} \"${bzip2};\$ENV{PATH}\")\n")
endif()
string(REPLACE "${regex_string}" "${replace_content}" new_content "${old_content}")
file(WRITE "${source}/CMakeLists.txt" "${new_content}")
]])
    file(WRITE "${xz_script}" "${script_content}")
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
#   BUILD_SHARED_LIBS:  OFF
function(add_xz)
    # params
    cmake_parse_arguments(xz "" "name;prefix;version;proxy" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${xz_name}" OR (DEFINED "${xz_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${xz_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "xz_build_shared" args_list_name "xz_UNPARSED_ARGUMENTS")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "xz_build_type" args_list_name "xz_UNPARSED_ARGUMENTS")
    # address
    set(xz_repository_url       "https://github.com/tukaani-project/xz")
    list(APPEND xz_version_list "5.6.0" "5.4.6")
    list(APPEND xz_hash_list    "0f5c81f14171b74fcc9777d302304d964e63ffc2d7b634ef023a7249d9b5d875"
                                "aeba3e03bf8140ddedf62a0a367158340520f6b384f75ca6045ccc6c0d43fd5c")
    # input version is in version list
    string(STRIP "${xz_version}" xz_version)
    if("${xz_version}" STREQUAL "")
        set(xz_version_index 0)
    else()
        list(FIND xz_version_list "${xz_version}" xz_version_index)
    endif()
    if(xz_version_index GREATER_EQUAL 0)
        set(xz_url   "${xz_repository_url}/releases/download/v${xz_version}/xz-${xz_version}.tar.gz")
        set(xz_file  "xz-${xz_version}.tar.gz")
        list(GET xz_hash_list ${xz_version_index} xz_hash)
    endif()
    # set build path
    set(xz_download  "${xz_prefix}/cache/download")
    set(xz_install   "${xz_prefix}/cache/install/${xz_name}/${xz_build_type}")
    set(xz_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(xz_source    "${xz_prefix}/${xz_name}")
    set(xz_patch     "${xz_prefix}/cache/patch/${xz_name}")
    if(MSVC)
        set(xz_binary "${xz_prefix}/cache/bin/${xz_name}")
    else()
        set(xz_binary "${xz_prefix}/cache/bin/${xz_name}/${xz_build_type}")
    endif()
    # build option
    set(xz_cmake_options    # default options
                            "-DBUILD_TESTING=OFF"
                            # default set shared/static
                            "-DBUILD_SHARED_LIBS=${xz_build_shared}"
                            # default set debug/release
                            "-DCMAKE_BUILD_TYPE=${xz_build_type}"
                            # default set lib/exe build path
                            "-DLIBRARY_OUTPUT_PATH='${xz_binary}'"
                            "-DEXECUTABLE_OUTPUT_PATH='${xz_binary}'"
                            "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${xz_binary}'"
                            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${xz_binary}'"
                            "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${xz_binary}'"
                            # default set lib install path
                            "-DCMAKE_INSTALL_PREFIX='${xz_install}'"
                            "-DCMAKE_INSTALL_LIBDIR='${xz_install}/lib'"
                            "-DCMAKE_INSTALL_BINDIR='${xz_install}/bin'"
                            "-DCMAKE_INSTALL_INCLUDEDIR='${xz_install}/include'"
                            # default set compile flags
                            "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                            "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                            "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                            "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                            "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                            "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("xz_UNPARSED_ARGUMENTS" "xz_cmake_options")
    # is install
    if(MSVC)
        set(xz_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${xz_build}" --config "${xz_build_type}")
        set(xz_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${xz_build}" --config "${xz_build_type}" --target INSTALL)
    endif()
    # set git config
    if(NOT ("" STREQUAL "${xz_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${xz_proxy} https.proxy=${xz_proxy})
    endif()
    # set url option
    if(${xz_version_index} GREATER_EQUAL 0)
        set(xz_url_option URL "${xz_url}" URL_HASH SHA256=${xz_hash} DOWNLOAD_NAME "${xz_file}")
    else()
        set(xz_url_option   GIT_REPOSITORY "${xz_repository_url}" GIT_TAG "${xz_version}"
                            GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # patch
    set(xz_patch_file "${xz_patch}/patch.cmake")
    xz_patch_script(script "${xz_patch_file}" source "${xz_source}" zlib "${xz_zlib}" bzip2 "${xz_bzip2}")
    set(xz_patch_cmd PATCH_COMMAND COMMAND "${CMAKE_COMMAND}" -P "${xz_patch_file}")
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${xz_download}" SOURCE_DIR "${xz_source}"
                                        ${xz_url_option} CMAKE_ARGS ${xz_cmake_options} EXCLUDE_FROM_ALL ON
                                        ${xz_patch_cmd} ${xz_build_cmd} ${xz_install_cmd} DEPENDS ${xz_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # check is build shared/static
    if(xz_build_shared)
        add_library("${xz_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${xz_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${xz_name}" "${pkg_name}")
    # set lib path dir
    set("${xz_name}-includes"   "${xz_install}/include"             PARENT_SCOPE)
    set("${xz_name}-cmake"      "${xz_install}/lib/cmake/liblzma"   PARENT_SCOPE)
    set("${xz_name}-root"       "${xz_install}"                     PARENT_SCOPE)
    set("${xz_name}-source"     "${xz_source}"                      PARENT_SCOPE)
    set(lib_path "${xz_install}/lib")
    set(bin_path "${xz_install}/bin")
    guess_binary_file(name "lzma" lib_prefix "lib" bin_prefix "lib")
    set_target_properties("${xz_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${lzma_lib}")
    if(xz_build_shared)
        set_target_properties("${xz_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${lzma_bin}")
    endif()
endfunction()

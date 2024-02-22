include(ExternalProject)

# install mysql8 script
# script:   script file save path
# source:   source code path
function(mysql8_patch_script)
    # params
    cmake_parse_arguments(mysql8 "" "script;source" "" ${ARGN})
    # set params
    set(script_content "\
# set info
set(source  \"${mysql8_source}\")
")
    string(APPEND script_content [[
# write CMakeLists.txt content
set(regex_string "MESSAGE(STATUS \"Running cmake version \${CMAKE_VERSION}\")")
string(APPEND replace_content "${regex_string}\n")
file(READ "${source}/CMakeLists.txt" old_content)
if(NOT ("" STREQUAL "${boost}"))
    string(APPEND replace_content "set(WITH_BOOST \"${boost}\")")
endif()
string(REPLACE "${regex_string}" "${replace_content}" new_content "${old_content}")
file(WRITE "${source}/CMakeLists.txt" "${new_content}")
]])
    if(NOT EXISTS "${mysql8_script}" OR IS_DIRECTORY "${mysql8_script}")
        file(WRITE "${mysql8_script}" "${script_content}")
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
# deps:     deps target
# ARGN: this will add this to build cmake args
#   ENABLE_LIB_ONLY:    ON
function(add_mysql8)
    # params
    cmake_parse_arguments(mysql8 "" "name;prefix;version;proxy" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${mysql8_name}" OR (DEFINED "${mysql8_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${mysql8_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "mysql8_build_shared" args_list_name "mysql8_UNPARSED_ARGUMENTS")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "mysql8_build_type" args_list_name "mysql8_UNPARSED_ARGUMENTS")
    # address
    set(mysql8_repository_url       "https://github.com/mysql/mysql-server")
    list(APPEND mysql8_version_list "8.0.36" "8.0.28")
    list(APPEND mysql8_hash_list    "cad607f67050fca7d0e50ee456c7b828574e67274c7bc624c65eb45d9f50f422"
                                    "7F59548FD6E5107F0A5DD7F495267E9B6053EC137B292BCEFBE419C3C21A3C3B")
    # input version is in version list
    string(STRIP "${mysql8_version}" mysql8_version)
    if("${mysql8_version}" STREQUAL "")
        set(mysql8_version_index 0)
    else()
        list(FIND mysql8_version_list "${mysql8_version}" mysql8_version_index)
    endif()
    if(mysql8_version_index GREATER_EQUAL 0)
        set(mysql8_url   "${mysql8_repository_url}/archive/refs/tags/mysql-${mysql8_version}.zip")
        set(mysql8_file  "mysql8-${mysql8_version}.zip")
        list(GET mysql8_hash_list ${mysql8_version_index} mysql8_hash)
    endif()
    # set build path
    set(mysql8_download  "${mysql8_prefix}/cache/download")
    set(mysql8_install   "${mysql8_prefix}/cache/install/${mysql8_name}/${mysql8_build_type}")
    set(mysql8_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(mysql8_source    "${mysql8_prefix}/${mysql8_name}")
    set(mysql8_patch     "${mysql8_prefix}/cache/patch/${mysql8_name}")
    if(MSVC)
        set(mysql8_binary "${mysql8_prefix}/cache/bin/${mysql8_name}")
    else()
        set(mysql8_binary "${mysql8_prefix}/cache/bin/${mysql8_name}/${mysql8_build_type}")
    endif()
    # build option
    set(mysql8_cmake_options # default set shared/static
                            "-DBUILD_SHARED_LIBS=${mysql8_build_shared}"
                            # default set debug/release
                            "-DCMAKE_BUILD_TYPE=${mysql8_build_type}"
                            # default set lib/exe build path
                            "-DLIBRARY_OUTPUT_PATH='${mysql8_binary}'"
                            "-DEXECUTABLE_OUTPUT_PATH='${mysql8_binary}'"
                            "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${mysql8_binary}'"
                            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${mysql8_binary}'"
                            "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${mysql8_binary}'"
                            # default set lib install path
                            "-DCMAKE_INSTALL_PREFIX='${mysql8_install}'"
                            "-DCMAKE_INSTALL_LIBDIR='${mysql8_install}/lib'"
                            "-DCMAKE_INSTALL_BINDIR='${mysql8_install}/bin'"
                            "-DCMAKE_INSTALL_INCLUDEDIR='${mysql8_install}/include'"
                            # default set compile flags
                            "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                            "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                            "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                            "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                            "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                            "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("mysql8_UNPARSED_ARGUMENTS" "mysql8_cmake_options")
    # is install
    if(MSVC)
        set(mysql8_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${mysql8_build}" --config "${mysql8_build_type}")
        set(mysql8_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${mysql8_build}" --config "${mysql8_build_type}" --target INSTALL)
    endif()
    # set git config
    if(NOT ("" STREQUAL "${mysql8_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${mysql8_proxy} https.proxy=${mysql8_proxy})
    endif()
    # set url option
    if(${mysql8_version_index} GREATER_EQUAL 0)
        set(mysql8_url_option URL "${mysql8_url}" URL_HASH SHA256=${mysql8_hash} DOWNLOAD_NAME "${mysql8_file}")
    else()
        set(mysql8_url_option   GIT_REPOSITORY "${mysql8_repository_url}" GIT_TAG "${mysql8_version}"
                                GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # patch
    # set(mysql8_patch_file "${mysql8_patch}/patch.cmake")
    # mysql8_patch_script(script "${mysql8_patch_file}" source "${mysql8_source}")
    # set(mysql8_patch_cmd PATCH_COMMAND COMMAND "${CMAKE_COMMAND}" -P "${mysql8_patch_file}")
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${mysql8_download}" SOURCE_DIR "${mysql8_source}"
                                        ${mysql8_url_option} CMAKE_ARGS ${mysql8_cmake_options} EXCLUDE_FROM_ALL ON
                                        ${mysql8_patch_cmd} ${mysql8_build_cmd} ${mysql8_install_cmd} DEPENDS ${mysql8_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # check is build shared/static
    if(mysql8_build_shared)
        add_library("${mysql8_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${mysql8_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${mysql8_name}" "${pkg_name}")
    # set lib path dir
    set("${mysql8_name}-includes"    "${mysql8_install}/include"          PARENT_SCOPE)
    set("${mysql8_name}-pkgconfig"   "${mysql8_install}/lib/pkgconfig"    PARENT_SCOPE)
    set("${mysql8_name}-root"        "${mysql8_install}"                  PARENT_SCOPE)
    set(lib_path "${mysql8_install}/lib")
    set(bin_path "${mysql8_install}/lib")
    guess_binary_file(name "bz2")
    set_target_properties("${mysql8_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${bz2_lib}")
    if(mysql8_build_shared)
        set_target_properties("${mysql8_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${bz2_bin}")
    endif()
endfunction()

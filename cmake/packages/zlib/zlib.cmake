include(ExternalProject)

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
# ARGN:     this will add this to build cmake args
#   ZLIB_BUILD_EXAMPLES:    ON
#   RENAME_ZCONF:           ON
function(add_zlib)
    # params
    cmake_parse_arguments(zlib "" "name;prefix;version;proxy" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${zlib_name}" OR (DEFINED "${zlib_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${zlib_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "zlib_build_shared" args_list_name "zlib_UNPARSED_ARGUMENTS")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "zlib_build_type" args_list_name "zlib_UNPARSED_ARGUMENTS")
    # address
    set(zlib_repository_url         "https://github.com/madler/zlib")
    list(APPEND zlib_version_list   "1.3.1" "1.3")
    list(APPEND zlib_hash_list      "50B24B47BF19E1F35D2A21FF36D2A366638CDF958219A66F30CE0861201760E6"
                                    "E6EE0C09DCCF864EC23F2DF075401CC7C68A67A8A633FF182E7ABCB7C673356E")
    # input version is in version list
    string(STRIP "${zlib_version}" zlib_version)
    if("${zlib_version}" STREQUAL "")
        set(zlib_version_index 0)
    else()
        list(FIND zlib_version_list "${zlib_version}" zlib_version_index)
    endif()
    if(zlib_version_index GREATER_EQUAL 0)
        set(zlib_url   "${zlib_repository_url}/archive/refs/tags/v${zlib_version}.zip")
        set(zlib_file  "zlib-${zlib_version}.zip")
        list(GET zlib_hash_list ${zlib_version_index} zlib_hash)
    endif()
    # set build path
    set(zlib_download  "${zlib_prefix}/cache/download")
    set(zlib_install   "${zlib_prefix}/cache/install/${zlib_name}/${zlib_build_type}")
    set(zlib_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(zlib_source    "${zlib_prefix}/${zlib_name}")
    if(MSVC)
        set(zlib_binary "${zlib_prefix}/cache/bin/${zlib_name}")
    else()
        set(zlib_binary "${zlib_prefix}/cache/bin/${zlib_name}/${zlib_build_type}")
    endif()
    # build option
    set(zlib_cmake_options # default set shared/static
                            "-DBUILD_SHARED_LIBS=${zlib_build_shared}"
                            # default set debug/release
                            "-DCMAKE_BUILD_TYPE=${zlib_build_type}"
                            # default set lib/exe build path
                            "-DLIBRARY_OUTPUT_PATH='${zlib_binary}'"
                            "-DEXECUTABLE_OUTPUT_PATH='${zlib_binary}'"
                            "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${zlib_binary}'"
                            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${zlib_binary}'"
                            "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${zlib_binary}'"
                            # default set lib install path
                            "-DCMAKE_INSTALL_PREFIX='${zlib_install}'"
                            "-DCMAKE_INSTALL_LIBDIR='${zlib_install}/lib'"
                            "-DCMAKE_INSTALL_BINDIR='${zlib_install}/bin'"
                            "-DCMAKE_INSTALL_INCLUDEDIR='${zlib_install}/include'"
                            # default set compile flags
                            "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                            "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                            "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                            "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                            "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                            "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("zlib_UNPARSED_ARGUMENTS" "zlib_cmake_options")
    # is install
    if(MSVC)
        set(zlib_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${zlib_build}" --config "${zlib_build_type}")
        set(zlib_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${zlib_build}" --config "${zlib_build_type}" --target INSTALL)
    endif()
    # set git config
    if(NOT ("" STREQUAL "${zlib_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${zlib_proxy} https.proxy=${zlib_proxy})
    endif()
    # set url option
    if(${zlib_version_index} GREATER_EQUAL 0)
        set(zlib_url_option URL "${zlib_url}" URL_HASH SHA256=${zlib_hash} DOWNLOAD_NAME "${zlib_file}")
    else()
        set(zlib_url_option GIT_REPOSITORY "${zlib_repository_url}" GIT_TAG "${zlib_version}"
                            GIT_SHALLOW ON GIT_PROGRESS OFF ${git_config})
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${zlib_download}" SOURCE_DIR "${zlib_source}"
                                        ${zlib_url_option} CMAKE_ARGS ${zlib_cmake_options}
                                        ${zlib_build_cmd} ${zlib_install_cmd} DEPENDS ${zlib_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # check is build shared/static
    if(zlib_build_shared)
        add_library("${zlib_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${zlib_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${zlib_name}" "${pkg_name}")
    # set lib path dir
    set("${zlib_name}-includes" "${zlib_install}/include" PARENT_SCOPE)
    set("${zlib_name}-root" "${zlib_install}" PARENT_SCOPE)
    set(lib_path "${zlib_install}/lib")
    set(bin_path "${zlib_install}/bin")
    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        if(MSVC)
            string(TOUPPER "${zlib_build_type}" zlib_build_type_upper)
            if("${zlib_build_type_upper}" STREQUAL "DEBUG")
                set(zlib_suffix "d")
            endif()
            if(zlib_build_shared)
                set(lib_name "zlib${zlib_suffix}.lib")
            else()
                set(lib_name "zlibstatic${zlib_suffix}.lib")
            endif()
            set(bin_name "zlib${zlib_suffix}1.dll")
        endif()
        if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
            if(zlib_build_shared)
                set(lib_name "libzlib.a")
            else()
                set(lib_name "libzlibstatic.a")
            endif()
            set(bin_name "zlib1.dll")
        endif()
        if(CMAKE_C_COMPILER_ID STREQUAL "Clang")
            message(FATAL_ERROR "#TODO Setting ...")
        endif()
    else()
        message(FATAL_ERROR "#TODO Setting ...")
    endif()
    set_target_properties("${zlib_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${lib_name}")
    if(zlib_build_shared)
        set_target_properties("${zlib_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${bin_name}")
    endif()
endfunction()

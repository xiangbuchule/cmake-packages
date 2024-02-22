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
# ARGN: this will add this to build cmake args
#   ENABLE_LIB_ONLY:    ON
function(add_mysql_connector_c)
    # params
    cmake_parse_arguments(mysql "" "name;prefix;version" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${mysql_name}" OR (DEFINED "${mysql_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${mysql_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "mysql_build_shared" args_list_name "mysql_UNPARSED_ARGUMENTS")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "mysql_build_type" args_list_name "mysql_UNPARSED_ARGUMENTS")
    # address
    set(mysql_repository_url        "https://downloads.mysql.com/archives/get/p/19/file")
    list(APPEND mysql_version_list  "6.1.11")
    list(APPEND mysql_hash_list     "C8664851487200162B38B6F3C8DB69850BD4F0E4C5FF5A6D161DBFB5CB76B6C4")
    # input version is in version list
    string(STRIP "${mysql_version}" mysql_version)
    if("${mysql_version}" STREQUAL "")
        set(mysql_version_index 0)
    else()
        list(FIND mysql_version_list "${mysql_version}" mysql_version_index)
    endif()
    if(mysql_version_index LESS 0)
        set(mysql_version_index 0)
    endif()
    list(GET mysql_version_list ${mysql_version_index} mysql_version)
    set(mysql_url   "${mysql_repository_url}/mysql-connector-c-${mysql_version}-src.tar.gz")
    set(mysql_file  "mysql-connector-c-${mysql_version}.zip")
    list(GET mysql_hash_list ${mysql_version_index} mysql_hash)
    # set build path
    set(mysql_download  "${mysql_prefix}/cache/download")
    set(mysql_install   "${mysql_prefix}/cache/install/${mysql_name}/${mysql_build_type}")
    set(mysql_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(mysql_source    "${mysql_prefix}/${mysql_name}")
    if(MSVC)
        set(mysql_binary "${mysql_prefix}/cache/bin/${mysql_name}")
    else()
        set(mysql_binary "${mysql_prefix}/cache/bin/${mysql_name}/${mysql_build_type}")
    endif()
    # build option
    set(mysql_cmake_options # default set shared/static
                            "-DBUILD_SHARED_LIBS=${mysql_build_shared}"
                            # default set debug/release
                            "-DCMAKE_BUILD_TYPE=${mysql_build_type}"
                            # default set lib/exe build path
                            "-DLIBRARY_OUTPUT_PATH='${mysql_binary}'"
                            "-DEXECUTABLE_OUTPUT_PATH='${mysql_binary}'"
                            "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${mysql_binary}'"
                            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${mysql_binary}'"
                            "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${mysql_binary}'"
                            # default set lib install path
                            "-DCMAKE_INSTALL_PREFIX='${mysql_install}'"
                            "-DCMAKE_INSTALL_LIBDIR='${mysql_install}/lib'"
                            "-DCMAKE_INSTALL_BINDIR='${mysql_install}/bin'"
                            "-DCMAKE_INSTALL_INCLUDEDIR='${mysql_install}/include'"
                            # default set compile flags
                            "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                            "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                            "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                            "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                            "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                            "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("mysql_UNPARSED_ARGUMENTS" "mysql_cmake_options")
    # is install
    if(MSVC)
        set(mysql_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${mysql_build}" --config "${mysql_build_type}")
        set(mysql_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${mysql_build}" --config "${mysql_build_type}" --target INSTALL)
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${mysql_download}" SOURCE_DIR "${mysql_source}"
                                        URL "${mysql_url}" URL_HASH SHA256=${mysql_hash} DOWNLOAD_NAME "${mysql_file}"
                                        CMAKE_ARGS ${mysql_cmake_options} EXCLUDE_FROM_ALL ON
                                        ${mysql_patch_cmd} ${mysql_build_cmd} ${mysql_install_cmd} DEPENDS ${mysql_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # check is build shared/static
    if(mysql_build_shared)
        add_library("${mysql_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${mysql_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${mysql_name}" "${pkg_name}")
    # set lib path dir
    set("${mysql_name}-includes"    "${mysql_install}/include"          PARENT_SCOPE)
    set("${mysql_name}-pkgconfig"   "${mysql_install}/lib/pkgconfig"    PARENT_SCOPE)
    set("${mysql_name}-root"        "${mysql_install}"                  PARENT_SCOPE)
    set(lib_path "${mysql_install}/lib")
    set(bin_path "${mysql_install}/lib")
    guess_binary_file(name "bz2")
    set_target_properties("${mysql_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${bz2_lib}")
    if(mysql_build_shared)
        set_target_properties("${mysql_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${bz2_bin}")
    endif()
endfunction()

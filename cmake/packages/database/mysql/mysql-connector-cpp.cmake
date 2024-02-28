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
# ARGN: this will add this to build cmake args
#   ENABLE_LIB_ONLY:    ON
function(add_mysql_connector_cpp)
    # params
    cmake_parse_arguments(mysql "" "name;prefix;version;proxy" "deps" ${ARGN})
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
    set(mysql_repository_url        "https://github.com/mysql/mysql-connector-cpp")
    list(APPEND mysql_version_list  "8.3.0" "8.2.0" "8.1.0" "8.0.33")
    list(APPEND mysql_hash_list     "8c47fd82ee179582280e6ee823eb58f8066b0fd8101e684c46dfb73010a39664"
                                    "46075784557c9e143aa412c10f0f8169596f88ac1c336f8b8b37fcef40f6501d"
                                    "ac2e90e21de9928ab9e9ead106f64fd4441c4aa9921104a2d5712f0f722a2c02"
                                    "b498d711ae0ea823f20e4fb8aabe98d0b4cadef07b01f67771fdc71d317146ca")
    # input version is in version list
    string(STRIP "${mysql_version}" mysql_version)
    if("${mysql_version}" STREQUAL "")
        set(mysql_version_index 0)
    else()
        list(FIND mysql_version_list "${mysql_version}" mysql_version_index)
    endif()
    if(mysql_version_index GREATER_EQUAL 0)
        set(mysql_url   "${mysql_repository_url}/archive/refs/tags/${mysql_version}.zip")
        set(mysql_file  "mysql-connector-cpp-${mysql_version}.zip")
        list(GET mysql_hash_list ${mysql_version_index} mysql_hash)
    endif()
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
                            "-DINSTALL_LIB_DIR_STATIC='${mysql_install}/lib'"
                            "-DINSTALL_LIB_DIR='${mysql_install}/lib'"
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
    # set git config
    if(NOT ("" STREQUAL "${mysql_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${mysql_proxy} https.proxy=${mysql_proxy})
    endif()
    # set url option
    if(${mysql_version_index} GREATER_EQUAL 0)
        set(mysql_url_option URL "${mysql_url}" URL_HASH SHA256=${mysql_hash} DOWNLOAD_NAME "${mysql_file}")
    else()
        set(mysql_url_option   GIT_REPOSITORY "${mysql_repository_url}" GIT_TAG "${mysql_version}"
                                GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${mysql_download}" SOURCE_DIR "${mysql_source}"
                                        ${mysql_url_option} CMAKE_ARGS ${mysql_cmake_options} EXCLUDE_FROM_ALL ON
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
    string(TOUPPER "${mysql_build_type}" mysql_build_type_upper)
    if("${mysql_build_type_upper}" STREQUAL "DEBUG")
        list(APPEND extra_path "/debug")
    endif()
    set(lib_path "${mysql_install}/lib${extra_path}")
    set(bin_path "${mysql_install}/lib${extra_path}")
    # set name
    get_cmake_args(arg "STATIC_MSVCRT" default "OFF" result "mysql_static_msvcrt" args_list_name "mysql_cmake_options")
    if(NOT mysql_build_shared)
        set(extra_suffix "-static")
        if(mysql_static_msvcrt)
            string(APPEND extra_suffix "-mt")
        endif()
    endif()
    # set file
    if(MSVC)
        string(REGEX REPLACE "[0-9]$" "" vs_version "${MSVC_TOOLSET_VERSION}")
        guess_binary_file(name "mysql" lib_suffix "cppconn8${extra_suffix}" bin_suffix "cppconn8-2-vs${vs_version}")
    else()
        guess_binary_file(name "mysql" lib_suffix "cppconn8${extra_suffix}" bin_suffix "cppconn8")
    endif()
    set_target_properties("${mysql_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${mysql_lib}")
    if(mysql_build_shared)
        set_target_properties("${mysql_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${mysql_bin}")
    endif()
endfunction()

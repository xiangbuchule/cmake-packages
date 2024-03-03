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
# python:   python path dir
# ARGN: this will add this to build cmake args
#   JSONCPP_WITH_TESTS:                 OFF
#   JSONCPP_WITH_POST_BUILD_UNITTEST:   OFF
#   JSONCPP_WITH_WARNING_AS_ERROR:      OFF
#   JSONCPP_WITH_STRICT_ISO:            ON
#   JSONCPP_WITH_PKGCONFIG_SUPPORT:     ON
#   JSONCPP_WITH_CMAKE_PACKAGE:         ON
#   JSONCPP_WITH_EXAMPLE:               OFF
#   JSONCPP_STATIC_WINDOWS_RUNTIME:     OFF
function(add_jsoncpp)
    # params
    cmake_parse_arguments(jsoncpp "" "name;prefix;version;proxy" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${jsoncpp_name}" OR (DEFINED "${jsoncpp_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${jsoncpp_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "jsoncpp_build_shared" args_list_name "jsoncpp_UNPARSED_ARGUMENTS")
    if(jsoncpp_build_shared)
        set(jsoncpp_build_static OFF)
    else()
        set(jsoncpp_build_static ON)
    endif()
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "jsoncpp_build_type" args_list_name "jsoncpp_UNPARSED_ARGUMENTS")
    # address
    set(jsoncpp_repository_url          "https://github.com/open-source-parsers/jsoncpp")
    list(APPEND jsoncpp_version_list    "1.9.5")
    list(APPEND jsoncpp_hash_list       "A074E1B38083484E8E07789FD683599D19DA8BB960959C83751CD0284BDF2043")
    # input version is in version list
    string(STRIP "${jsoncpp_version}" jsoncpp_version)
    if("${jsoncpp_version}" STREQUAL "")
        set(jsoncpp_version_index 0)
    else()
        list(FIND jsoncpp_version_list "${jsoncpp_version}" jsoncpp_version_index)
    endif()
    if(jsoncpp_version_index GREATER_EQUAL 0)
        set(jsoncpp_url   "${jsoncpp_repository_url}/archive/refs/tags/${jsoncpp_version}.zip")
        set(jsoncpp_file  "jsoncpp-${jsoncpp_version}.zip")
        list(GET jsoncpp_hash_list ${jsoncpp_version_index} jsoncpp_hash)
    endif()
    # set build path
    set(jsoncpp_download  "${jsoncpp_prefix}/cache/download")
    set(jsoncpp_install   "${jsoncpp_prefix}/cache/install/${jsoncpp_name}/${jsoncpp_build_type}")
    set(jsoncpp_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(jsoncpp_source    "${jsoncpp_prefix}/${jsoncpp_name}")
    if(MSVC)
        set(jsoncpp_binary "${jsoncpp_prefix}/cache/bin/${jsoncpp_name}")
    else()
        set(jsoncpp_binary "${jsoncpp_prefix}/cache/bin/${jsoncpp_name}/${jsoncpp_build_type}")
    endif()
    # build option
    set(jsoncpp_cmake_options   # default set options
                                "-DJSONCPP_WITH_TESTS=OFF"
                                "-DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF"
                                "-DJSONCPP_WITH_TESTS=OFF"
                                "-DBUILD_OBJECT_LIBS=OFF"
                                # default set shared/static
                                "-DBUILD_SHARED_LIBS=${jsoncpp_build_shared}"
                                "-DBUILD_STATIC_LIBS=${jsoncpp_build_static}"
                                # default set debug/release
                                "-DCMAKE_BUILD_TYPE=${jsoncpp_build_type}"
                                # default set lib/exe build path
                                "-DLIBRARY_OUTPUT_PATH='${jsoncpp_binary}'"
                                "-DEXECUTABLE_OUTPUT_PATH='${jsoncpp_binary}'"
                                "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${jsoncpp_binary}'"
                                "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${jsoncpp_binary}'"
                                "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${jsoncpp_binary}'"
                                # default set lib install path
                                "-DCMAKE_INSTALL_PREFIX='${jsoncpp_install}'"
                                "-DCMAKE_INSTALL_LIBDIR='${jsoncpp_install}/lib'"
                                "-DCMAKE_INSTALL_BINDIR='${jsoncpp_install}/bin'"
                                "-DCMAKE_INSTALL_INCLUDEDIR='${jsoncpp_install}/include'"
                                # default set compile flags
                                "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                                "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                                "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                                "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                                "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                                "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("jsoncpp_UNPARSED_ARGUMENTS" "jsoncpp_cmake_options")
    # is install
    if(MSVC)
        set(jsoncpp_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${jsoncpp_build}" --config "${jsoncpp_build_type}")
        set(jsoncpp_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${jsoncpp_build}" --config "${jsoncpp_build_type}" --target INSTALL)
    endif()
    # set git config
    if(NOT ("" STREQUAL "${jsoncpp_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${jsoncpp_proxy} https.proxy=${jsoncpp_proxy})
    endif()
    # set url option
    if(${jsoncpp_version_index} GREATER_EQUAL 0)
        set(jsoncpp_url_option URL "${jsoncpp_url}" URL_HASH SHA256=${jsoncpp_hash} DOWNLOAD_NAME "${jsoncpp_file}")
    else()
        set(jsoncpp_url_option  GIT_REPOSITORY "${jsoncpp_repository_url}" GIT_TAG "${jsoncpp_version}"
                                GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${jsoncpp_download}" SOURCE_DIR "${jsoncpp_source}"
                                        ${jsoncpp_url_option} CMAKE_ARGS ${jsoncpp_cmake_options} EXCLUDE_FROM_ALL ON
                                        ${jsoncpp_build_cmd} ${jsoncpp_install_cmd} DEPENDS ${jsoncpp_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # check is build shared/static
    if(jsoncpp_build_shared)
        add_library("${jsoncpp_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${jsoncpp_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${jsoncpp_name}" "${pkg_name}")
    # set lib path dir
    set("${jsoncpp_name}-includes"      "${jsoncpp_install}/include"        PARENT_SCOPE)
    set("${jsoncpp_name}-pkgconfig"     "${jsoncpp_install}/lib/pkgconfig"  PARENT_SCOPE)
    set("${jsoncpp_name}-cmake"         "${jsoncpp_install}/lib/cmake"      PARENT_SCOPE)
    set("${jsoncpp_name}-root"          "${jsoncpp_install}"                PARENT_SCOPE)
    set(lib_path "${jsoncpp_install}/lib")
    set(bin_path "${jsoncpp_install}/bin")
    guess_binary_file(name "jsoncpp")
    set_target_properties("${jsoncpp_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${jsoncpp_lib}")
    if(jsoncpp_build_shared)
        set_target_properties("${jsoncpp_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${jsoncpp_bin}")
    endif()
endfunction()

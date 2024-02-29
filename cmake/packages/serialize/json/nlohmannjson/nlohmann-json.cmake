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

# operate list some regex item
# names:    list var names
# regex:    regex rules
# replace:  replace contents
# remove:   remove not regex item
# option:   operate option (replace,remove,replace_regex,replace_not_regex)
#   FIND:               find regex item
#   FIND_NOT_REGEX:     find not regex item
#   REPLACE:            replace this item all content
#   REPLACE_REGEX:      just replace this item regex content
#   REPLACE_NOT_REGEX:  just replace this item not regex content
function(replace_list)
    # params
    cmake_parse_arguments(list "" "option;regex;replace;remove" "names" ${ARGN})
    set(default_option_list "FIND" "FIND_NOT_REGEX"
                            "REPLACE" "REPLACE_REGEX" "REPLACE_NOT_REGEX")
    # get option
    string(STRIP "${list_option}" list_option)
    string(TOUPPER "${list_option}" list_option)
    if("" STREQUAL "${list_option}")
        set(list_option "FIND")
    else()
        list(FIND default_option_list "${list_option}" option_index)
        if(${option_index} LESS 0)
            set(list_option "FIND")
        endif()
    endif()
    if("FIND_NOT_REGEX" STREQUAL "${list_option}")
        set(list_remove OFF)
    endif()
    # foreach
    foreach(list_name IN LISTS list_names list_UNPARSED_ARGUMENTS)
        foreach(item IN LISTS "${list_name}")
            # is match
            string(REGEX MATCHALL "${list_regex}" match_result "${item}")
            if((match_result AND ("FIND_NOT_REGEX" STREQUAL "${list_option}")) OR
                (NOT match_result AND ("FIND" STREQUAL "${list_option}" OR list_remove)))
                continue()
            endif()
            if(match_result AND "REPLACE" STREQUAL "${list_option}")
                set(item "${list_replace}")
            endif()
            if(match_result AND "REPLACE_REGEX" STREQUAL "${list_option}")
                string(REGEX REPLACE "${list_regex}" "${list_replace}" item "${item}")
            endif()
            if(match_result AND "REPLACE_NOT_REGEX" STREQUAL "${list_option}")
                string(REGEX REPLACE "${list_regex}" ";" item_list "${item}")
                if(POLICY CMP0007)
                    cmake_policy(SET CMP0007 NEW)
                endif()
                list(LENGTH item_list item_list_length)
                math(EXPR item_list_length "${item_list_length} - 1")
                set(item "")
                foreach(key RANGE ${item_list_length})
                    list(GET item_list ${key} value)
                    if(${key} EQUAL ${item_list_length})
                        set(match_value "")
                    else()
                        list(GET match_result ${key} match_value)
                    endif()
                    if("" STREQUAL "${value}")
                        string(APPEND item "${match_value}")
                    else()
                        string(APPEND item "${list_replace}${match_value}")
                    endif()
                endforeach()
            endif()
            list(APPEND "${list_name}_tmp" "${item}")
        endforeach()
        set("${list_name}" "${${list_name}_tmp}" PARENT_SCOPE)
    endforeach()
endfunction()

# name:     target name
# prefix:   prefix path
# version:  packages version
# deps:     deps target
# python:   python path dir
# ARGN: this will add this to build cmake args
#   ENABLE_LIB_ONLY:    ON
function(add_nlohmannjson)
    # params
    cmake_parse_arguments(nlohmannjson "" "name;prefix;version;proxy;python" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${nlohmannjson_name}" OR (DEFINED "${nlohmannjson_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${nlohmannjson_name}")
    replace_list(option "FIND_NOT_REGEX" regex "-D( *)?JSON_Install( *)?=(.*)?" replace "" remove OFF
                names nlohmannjson_options nlohmannjson_UNPARSED_ARGUMENTS)
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "nlohmannjson_build_type" args_list_name "nlohmannjson_UNPARSED_ARGUMENTS")
    # address
    set(nlohmannjson_repository_url          "https://github.com/nlohmann/json")
    list(APPEND nlohmannjson_version_list    "3.11.3")
    list(APPEND nlohmannjson_hash_list       "04022B05D806EB5FF73023C280B68697D12B93E1B7267A0B22A1A39EC7578069")
    # input version is in version list
    string(STRIP "${nlohmannjson_version}" nlohmannjson_version)
    if("${nlohmannjson_version}" STREQUAL "")
        set(nlohmannjson_version_index 0)
    else()
        list(FIND nlohmannjson_version_list "${nlohmannjson_version}" nlohmannjson_version_index)
    endif()
    if(nlohmannjson_version_index GREATER_EQUAL 0)
        set(nlohmannjson_url   "${nlohmannjson_repository_url}/archive/refs/tags/v${nlohmannjson_version}.zip")
        set(nlohmannjson_file  "nlohmannjson-${nlohmannjson_version}.zip")
        list(GET nlohmannjson_hash_list ${nlohmannjson_version_index} nlohmannjson_hash)
    endif()
    # set build path
    set(nlohmannjson_download   "${nlohmannjson_prefix}/cache/download")
    set(nlohmannjson_install    "${nlohmannjson_prefix}/cache/install/${nlohmannjson_name}/${nlohmannjson_build_type}")
    set(nlohmannjson_build      "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(nlohmannjson_source     "${nlohmannjson_prefix}/${nlohmannjson_name}")
    if(MSVC)
        set(nlohmannjson_binary "${nlohmannjson_prefix}/cache/bin/${nlohmannjson_name}")
    else()
        set(nlohmannjson_binary "${nlohmannjson_prefix}/cache/bin/${nlohmannjson_name}/${nlohmannjson_build_type}")
    endif()
    # build option
    set(nlohmannjson_cmake_options  # default set options
                                    "-DJSON_BuildTests=OFF"
                                    "-DJSON_Install=ON"
                                    # default set lib install path
                                    "-DCMAKE_INSTALL_PREFIX='${nlohmannjson_install}'"
                                    "-DCMAKE_INSTALL_LIBDIR='${nlohmannjson_install}/lib'"
                                    "-DCMAKE_INSTALL_BINDIR='${nlohmannjson_install}/bin'"
                                    "-DCMAKE_INSTALL_INCLUDEDIR='${nlohmannjson_install}/include'")
    # add other build args
    replace_cmake_args("nlohmannjson_UNPARSED_ARGUMENTS" "nlohmannjson_cmake_options")
    # is install
    if(MSVC)
        set(nlohmannjson_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${nlohmannjson_build}" --config "${nlohmannjson_build_type}")
        set(nlohmannjson_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${nlohmannjson_build}" --config "${nlohmannjson_build_type}" --target INSTALL)
    endif()
    # set git config
    if(NOT ("" STREQUAL "${nlohmannjson_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${nlohmannjson_proxy} https.proxy=${nlohmannjson_proxy})
    endif()
    # set url option
    if(${nlohmannjson_version_index} GREATER_EQUAL 0)
        set(nlohmannjson_url_option URL "${nlohmannjson_url}" URL_HASH SHA256=${nlohmannjson_hash} DOWNLOAD_NAME "${nlohmannjson_file}")
    else()
        set(nlohmannjson_url_option GIT_REPOSITORY "${nlohmannjson_repository_url}" GIT_TAG "${nlohmannjson_version}"
                                    GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${nlohmannjson_download}" SOURCE_DIR "${nlohmannjson_source}"
                                        ${nlohmannjson_url_option} CMAKE_ARGS ${nlohmannjson_cmake_options} EXCLUDE_FROM_ALL ON
                                        ${nlohmannjson_build_cmd} ${nlohmannjson_install_cmd} DEPENDS ${nlohmannjson_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # check is build shared/static
    add_library("${nlohmannjson_name}" INTERFACE)
    add_dependencies("${nlohmannjson_name}" "${pkg_name}")
    target_include_directories("${nlohmannjson_name}" INTERFACE "${nlohmannjson_install}/include")
    # set lib path dir
    set("${nlohmannjson_name}-includes"     "${nlohmannjson_install}/include"               PARENT_SCOPE)
    set("${nlohmannjson_name}-pkgconfig"    "${nlohmannjson_install}/share/pkgconfig"       PARENT_SCOPE)
    set("${nlohmannjson_name}-cmake"        "${nlohmannjson_install}/share/nlohmann_json"   PARENT_SCOPE)
    set("${nlohmannjson_name}-root"         "${nlohmannjson_install}"                       PARENT_SCOPE)
    set("${nlohmannjson_name}-source"       "${nlohmannjson_source}"                        PARENT_SCOPE)
endfunction()

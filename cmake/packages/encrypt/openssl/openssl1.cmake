include(ExternalProject)

# install openssl1 script
# script:   script file save path
# source:   source dir
# zlib:     zlib file path
function(openssl1_patch_script)
    # params
    cmake_parse_arguments(openssl1 "" "script;source;zlib" "" ${ARGN})
    # set params
    set(script_content "\
# set perl/nasm info
set(source  \"${openssl1_source}\")
set(zlib    \"${openssl1_zlib}\")
")
    # set other script
    string(APPEND script_content [[
# write Configure content
set(regex_string "# see INSTALL for instructions.")
string(APPEND replace_content "${regex_string}\n")
string(APPEND replace_content "no warnings 'all';")
file(READ "${source}/Configure" old_content)
string(REPLACE "${regex_string}" "${replace_content}" new_content "${old_content}")
file(WRITE "${source}/Configure" "${new_content}")
if(NOT ("${zlib}" STREQUAL ""))
    file(COPY "${zlib}" DESTINATION "${source}")
endif()
]])
    file(WRITE "${openssl1_script}" "${script_content}")
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

# append list item
# content:  item
# names:    lists names
function(append_list)
    # params
    cmake_parse_arguments(list "" "content;regex" "names" ${ARGN})
    # foreach
    foreach(list_name IN LISTS list_names list_UNPARSED_ARGUMENTS)
        set(is_append ON)
        foreach(item IN LISTS "${list_name}")
            string(REGEX MATCH "${list_regex}" match_result "${item}")
            if(match_result)
                set(is_append OFF)
                break()
            endif()
        endforeach()
        if(is_append)
            set("${list_name}" "${${list_name}};${list_content}" PARENT_SCOPE)
        endif()
    endforeach()
endfunction()


# name:     target name
# prefix:   prefix path
# version:  packages version
# deps:     deps target
# nasm:     nasm path dir
# perl:     perl path dir
function(add_openssl1)
    # params
    cmake_parse_arguments(openssl1 "" "name;prefix;version;proxy;nasm;perl;zlib_dir" "options;deps" ${ARGN})
    # if target exist, return
    if(TARGET "${openssl1_name}" OR (DEFINED "${openssl1_name}-includes"))
        return()
    endif()
    # get nasm/perl
    string(TOUPPER "${openssl1_nasm}" openssl1_nasm_upper)
    if("${openssl1_nasm_upper}" STREQUAL "" OR "${openssl1_nasm_upper}" STREQUAL "NASM")
        set(openssl1_nasm "nasm")
    endif()
    string(TOUPPER "${openssl1_perl}" openssl1_perl_upper)
    if("${openssl1_perl_upper}" STREQUAL "" OR "${openssl1_perl_upper}" STREQUAL "PERL")
        set(openssl1_perl "perl")
    endif()
    # set pkg name
    set(pkg_name "pkg-${openssl1_name}")
        # get config option
    replace_list(option "FIND_NOT_REGEX" regex "^--prefix=" replace "" remove OFF
                names openssl1_options openssl1_UNPARSED_ARGUMENTS)
    replace_list(option "FIND_NOT_REGEX" regex "^--openssldir=" replace "" remove OFF
                names openssl1_options openssl1_UNPARSED_ARGUMENTS)
    set(config_options_tmp "${openssl1_options};${openssl1_UNPARSED_ARGUMENTS}")
    string(REGEX REPLACE "(^;)|(;$)" "" config_options_tmp "${config_options_tmp}")
    # find zlib
    foreach(item IN LISTS config_options_tmp)
        string(REGEX MATCH "--with-zlib-lib" zlib_file "${item}")
        if(zlib_file)
            string(REGEX REPLACE "--with-zlib-lib.*=" "" zlib_file "${item}")
            string(STRIP "${zlib_file}" zlib_file)
            break()
        endif()
    endforeach()
    if(NOT ("${zlib_file}" STREQUAL ""))
        get_filename_component(zlib_file_name "${zlib_file}" NAME_WLE)
        replace_list(option "REPLACE" regex "--with-zlib-lib" replace "--with-zlib-lib=${zlib_file_name}"
                    remove OFF names config_options_tmp)
    endif()
    # find others
    if(BUILD_SHARED_LIBS)
        append_list(content "shared" regex "shared$" names config_options_tmp)
    else()
        append_list(content "no-shared" regex "shared$" names config_options_tmp)
    endif()
    list(FIND config_options_tmp "shared" shared_index)
    if(shared_index GREATER_EQUAL 0)
        set(openssl1_build_shared ON)
    endif()
    list(FIND config_options_tmp "no-shared" no_shared_index)
    if(no_shared_index GREATER_EQUAL 0)
        set(openssl1_build_shared OFF)
    endif()
    if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        append_list(content "--debug" regex "--debug" names config_options_tmp)
    else()
        append_list(content "--release" regex "--release" names config_options_tmp)
    endif()
    # address
    set(openssl1_repository_url         "https://github.com/openssl/openssl")
    list(APPEND openssl1_version_list   "1.1.1w")
    list(APPEND openssl1_hash_list      "CF3098950CB4D853AD95C0841F1F9C6D3DC102DCCFCACD521D93925208B76AC8")
    # input version is in version list
    string(STRIP "${openssl1_version}" openssl1_version)
    if("${openssl1_version}" STREQUAL "")
        set(openssl1_version_index 0)
    else()
        list(FIND openssl1_version_list "${openssl1_version}" openssl1_version_index)
    endif()
    if(openssl1_version_index GREATER_EQUAL 0)
        string(REPLACE "." "_" openssl1_version_tmp "${openssl1_version}")
        set(openssl1_url   "${openssl1_repository_url}/releases/download/OpenSSL_${openssl1_version_tmp}/openssl-${openssl1_version}.tar.gz")
        set(openssl1_file  "openssl1-${openssl1_version}.tar.gz")
        list(GET openssl1_hash_list ${openssl1_version_index} openssl1_hash)
    endif()
    # set build path
    set(openssl1_download  "${openssl1_prefix}/cache/download")
    list(FIND config_options_tmp "--debug" debug_index)
    if(debug_index GREATER_EQUAL 0)
        set(openssl1_install   "${openssl1_prefix}/cache/install/${openssl1_name}/Debug")
    else()
        set(openssl1_install   "${openssl1_prefix}/cache/install/${openssl1_name}/Release")
    endif()
    if(NOT EXISTS "${openssl1_install}" OR IS_DIRECTORY "${openssl1_install}")
        file(MAKE_DIRECTORY "${openssl1_install}")
    endif()
    set(openssl1_tmp  "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix")
    if(NOT EXISTS "${openssl1_tmp}" OR IS_DIRECTORY "${openssl1_tmp}")
        file(MAKE_DIRECTORY "${openssl1_tmp}")
    endif()
    set(openssl1_source "${openssl1_prefix}/${openssl1_name}")
    set(openssl1_patch  "${openssl1_prefix}/cache/patch/${openssl1_name}")
    # set git config
    if(NOT ("" STREQUAL "${openssl1_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${openssl1_proxy} https.proxy=${openssl1_proxy})
    endif()
    # set url option
    if(${openssl1_version_index} GREATER_EQUAL 0)
        set(openssl1_url_option URL "${openssl1_url}" URL_HASH SHA256=${openssl1_hash} DOWNLOAD_NAME "${openssl1_file}")
    else()
        set(openssl1_url_option GIT_REPOSITORY "${openssl1_repository_url}" GIT_TAG "${openssl1_version}"
                                GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # save config options
    set(config_info_file "${openssl1_tmp}/configs")
    if((NOT EXISTS "${config_info_file}") OR IS_DIRECTORY "${config_info_file}")
        if("" STREQUAL "${config_options_tmp}")
            file(TOUCH "${config_info_file}")
        else()
            file(WRITE "${config_info_file}" "${config_options_tmp}")
        endif()
    else()
        file(READ "${config_info_file}" config_options_info)
        if(NOT ("${config_options_tmp}" STREQUAL "${config_options_info}"))
            file(WRITE "${config_info_file}" "${config_options_tmp}")
        endif()
    endif()
    # patch
    set(openssl1_patch_file "${openssl1_patch}/patch.cmake")
    openssl1_patch_script(script "${openssl1_patch_file}" source "${openssl1_source}" zlib "${zlib_file}")
    set(openssl1_patch_cmd PATCH_COMMAND COMMAND "${CMAKE_COMMAND}" -P "${openssl1_patch_file}")
    if(MSVC)
        set(openssl1_configure_cmd CONFIGURE_COMMAND COMMAND "")
        set(openssl1_build_cmd BUILD_COMMAND COMMAND "")
        set(openssl1_install_cmd INSTALL_COMMAND COMMAND "")
    else()
        set(openssl1_configure_cmd CONFIGURE_COMMAND COMMAND perl Configure "${perl_toolset}" ${config_options_tmp}  --prefix=${openssl1_install} --openssldir=${openssl1_install}/SSL)
        set(openssl1_build_cmd BUILD_COMMAND COMMAND make)
        set(openssl1_install_cmd INSTALL_COMMAND COMMAND make install install_sw install_ssldirs)
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${openssl1_download}" SOURCE_DIR "${openssl1_source}"
                                        ${openssl1_url_option} EXCLUDE_FROM_ALL ON
                                        ${openssl1_patch_cmd} ${openssl1_configure_cmd}
                                        ${openssl1_build_cmd} ${openssl1_install_cmd} DEPENDS ${openssl1_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # compiler
    if(MSVC)
        if(${CMAKE_VS_PLATFORM_NAME} EQUAL win32)
            set(msvc_target x86)
        else()
            set(msvc_target x64)
        endif()
        string(REPLACE "host=" "" msvc_host "${CMAKE_GENERATOR_TOOLSET}")
        if("${msvc_target}" STREQUAL "${msvc_host}")
            set(msvc_host_target "${msvc_host}")
        else()
            set(msvc_host_target "${msvc_host}_${msvc_target}")
        endif()
        if("x86" STREQUAL "${msvc_target}")
            set(perl_toolset "VC-WIN32")
        else()
            set(perl_toolset "VC-WIN64A")
        endif()
        get_filename_component(msvc_bat "${CMAKE_LINKER}../../../../../../../../Auxiliary/Build/vcvarsall.bat" ABSOLUTE)
        # set cmd env
        if(NOT ("${openssl1_perl}" STREQUAL "perl"))
            list(APPEND openssl1_env_list "${openssl1_perl}/perl/bin")
        endif()
        if(NOT ("${openssl1_nasm}" STREQUAL "nasm"))
            list(APPEND openssl1_env_list "${openssl1_nasm}")
        endif()
        list(JOIN openssl1_env_list "\;" openssl1_env_list)
        if(openssl1_env_list)
            set(msvc_cmd_env call "${msvc_bat}" "${msvc_host_target}" && call set "PATH=${openssl1_env_list}\;%PATH%")
        else()
            set(msvc_cmd_env call "${msvc_bat}" "${msvc_host_target}")
        endif()
        ExternalProject_Add_StepTargets("${pkg_name}" patch)
        set_target_properties("${pkg_name}-patch" PROPERTIES EXCLUDE_FROM_ALL TRUE)
        add_custom_command(
            OUTPUT "${openssl1_tmp}/configed"
            COMMAND cmd /C ${msvc_cmd_env} && perl Configure "${perl_toolset}" ${config_options_tmp}  --prefix=${openssl1_install} --openssldir=${openssl1_install}/SSL
            COMMAND "${CMAKE_COMMAND}" -E touch "${openssl1_tmp}/configed"
            WORKING_DIRECTORY "${openssl1_source}"
            MAIN_DEPENDENCY "${config_info_file}"
            DEPENDS "${pkg_name}-patch"
            USES_TERMINAL
            COMMENT "Configure OpenSSL In '${openssl1_source}' ..."
        )
        add_custom_command(
            OUTPUT "${openssl1_tmp}/maked"
            COMMAND cmd /C ${msvc_cmd_env} && nmake
            COMMAND "${CMAKE_COMMAND}" -E touch "${openssl1_tmp}/maked"
            WORKING_DIRECTORY "${openssl1_source}"
            MAIN_DEPENDENCY "${openssl1_tmp}/configed"
            USES_TERMINAL
            COMMENT "Build OpenSSL In '${openssl1_source}' ..."
        )
        add_custom_command(
            OUTPUT "${openssl1_tmp}/installed"
            COMMAND cmd /C ${msvc_cmd_env} && nmake /f "${openssl1_source}/makefile" install_sw install_ssldirs
            COMMAND "${CMAKE_COMMAND}" -E touch "${openssl1_tmp}/installed"
            WORKING_DIRECTORY "${openssl1_source}"
            MAIN_DEPENDENCY "${openssl1_tmp}/maked"
            USES_TERMINAL
            COMMENT "Install OpenSSL In '${openssl1_install}' ..."
        )
        ExternalProject_Add_StepDependencies("${pkg_name}" install "${openssl1_tmp}/installed")
    endif()
    # set lib path dir
    set("${openssl1_name}-includes"    "${openssl1_install}/include"          PARENT_SCOPE)
    set("${openssl1_name}-pkgconfig"   "${openssl1_install}/lib/pkgconfig"    PARENT_SCOPE)
    set("${openssl1_name}-root"        "${openssl1_install}"                  PARENT_SCOPE)
    set(lib_path "${openssl1_install}/lib")
    set(bin_path "${openssl1_install}/bin")
    string(REPLACE "." ";" openssl1_version_list "${openssl1_version}")
    list(LENGTH openssl1_version_list openssl1_version_list_len)
    math(EXPR openssl1_version_list_len "${openssl1_version_list_len} - 1")
    list(REMOVE_AT openssl1_version_list ${openssl1_version_list_len})
    list(JOIN openssl1_version_list "_" openssl1_version)
    # set binary list
    set(binary_list "ssl" "crypto")
    foreach(item IN LISTS binary_list)
        # check is build shared/static
        if(openssl1_build_shared)
            add_library("${openssl1_name}::${item}" SHARED IMPORTED GLOBAL)
        else()
            add_library("${openssl1_name}::${item}" STATIC IMPORTED GLOBAL)
        endif()
        add_dependencies("${openssl1_name}::${item}" "${pkg_name}")
        # file
        guess_binary_file(name "${item}" lib_prefix "lib" bin_prefix "lib" bin_suffix "-${openssl1_version}-${msvc_target}")
        # set lib
        set_target_properties("${openssl1_name}::${item}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${${item}_lib}")
        if(openssl1_build_shared)
            set_target_properties("${openssl1_name}::${item}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${${item}_bin}")
        endif()
    endforeach()
endfunction()

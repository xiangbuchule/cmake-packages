include(ExternalProject)

# install libiconv script
# script:   script file save path
# source:   source dir
# zlib:     zlib file path
function(libiconv_patch_script)
    # params
    cmake_parse_arguments(libiconv "" "script;source;zlib" "" ${ARGN})
    # set params
    set(script_content "\
# set perl/nasm info
set(source  \"${libiconv_source}\")
set(zlib    \"${libiconv_zlib}\")
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
    file(WRITE "${libiconv_script}" "${script_content}")
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
function(add_libiconv)
    # params
    cmake_parse_arguments(libiconv "" "name;prefix;version;proxy;msys" "options;deps" ${ARGN})
    # if target exist, return
    if(DEFINED "${libiconv_name}-includes")
        return()
    endif()
    # get nasm/perl
    if(MSVC)
        string(TOUPPER "${libiconv_msys}" libiconv_msys_upper)
        if("${libiconv_msys_upper}" STREQUAL "" OR NOT IS_DIRECTORY "${libiconv_msys_upper}")
            message(FATAL_ERROR "When Use MSVC, You Need MSYS To Build")
        endif()
    endif()
    # set pkg name
    set(pkg_name "pkg-${libiconv_name}")
        # get config option
    replace_list(option "FIND_NOT_REGEX" regex "^--prefix=" replace "" remove OFF
                names libiconv_options libiconv_UNPARSED_ARGUMENTS)
    replace_list(option "FIND_NOT_REGEX" regex "^--openssldir=" replace "" remove OFF
                names libiconv_options libiconv_UNPARSED_ARGUMENTS)
    set(config_options_tmp "${libiconv_options};${libiconv_UNPARSED_ARGUMENTS}")
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
        set(libiconv_build_shared ON)
    endif()
    list(FIND config_options_tmp "no-shared" no_shared_index)
    if(no_shared_index GREATER_EQUAL 0)
        set(libiconv_build_shared OFF)
    endif()
    if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        append_list(content "--debug" regex "--debug" names config_options_tmp)
    else()
        append_list(content "--release" regex "--release" names config_options_tmp)
    endif()
    # address
    set(libiconv_repository_url         "https://ftp.gnu.org/pub/gnu/libiconv/")
    list(APPEND libiconv_version_list   "1.17")
    list(APPEND libiconv_hash_list      "8F74213B56238C85A50A5329F77E06198771E70DD9A739779F4C02F65D971313")
    # input version is in version list
    string(STRIP "${libiconv_version}" libiconv_version)
    if("${libiconv_version}" STREQUAL "")
        set(libiconv_version_index 0)
    else()
        list(FIND libiconv_version_list "${libiconv_version}" libiconv_version_index)
    endif()
    if(libiconv_version_index GREATER_EQUAL 0)
        string(REPLACE "." "_" libiconv_version_tmp "${libiconv_version}")
        set(libiconv_url   "${libiconv_repository_url}/releases/download/OpenSSL_${libiconv_version_tmp}/openssl-${libiconv_version}.tar.gz")
        set(libiconv_file  "libiconv-${libiconv_version}.tar.gz")
        list(GET libiconv_hash_list ${libiconv_version_index} libiconv_hash)
    endif()
    # set build path
    set(libiconv_download  "${libiconv_prefix}/cache/download")
    list(FIND config_options_tmp "--debug" debug_index)
    if(debug_index GREATER_EQUAL 0)
        set(libiconv_install   "${libiconv_prefix}/cache/install/${libiconv_name}/Debug")
    else()
        set(libiconv_install   "${libiconv_prefix}/cache/install/${libiconv_name}/Release")
    endif()
    if(NOT EXISTS "${libiconv_install}" OR IS_DIRECTORY "${libiconv_install}")
        file(MAKE_DIRECTORY "${libiconv_install}")
    endif()
    set(libiconv_tmp  "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix")
    if(NOT EXISTS "${libiconv_tmp}" OR IS_DIRECTORY "${libiconv_tmp}")
        file(MAKE_DIRECTORY "${libiconv_tmp}")
    endif()
    set(libiconv_source "${libiconv_prefix}/${libiconv_name}")
    set(libiconv_patch  "${libiconv_prefix}/cache/patch/${libiconv_name}")
    # set git config
    if(NOT ("" STREQUAL "${libiconv_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${libiconv_proxy} https.proxy=${libiconv_proxy})
    endif()
    # set url option
    if(${libiconv_version_index} GREATER_EQUAL 0)
        set(libiconv_url_option URL "${libiconv_url}" URL_HASH SHA256=${libiconv_hash} DOWNLOAD_NAME "${libiconv_file}")
    else()
        set(libiconv_url_option GIT_REPOSITORY "${libiconv_repository_url}" GIT_TAG "${libiconv_version}"
                                GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # save config options
    set(config_info_file "${libiconv_tmp}/configs")
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
    set(libiconv_patch_file "${libiconv_patch}/patch.cmake")
    libiconv_patch_script(script "${libiconv_patch_file}" source "${libiconv_source}" zlib "${zlib_file}")
    set(libiconv_patch_cmd PATCH_COMMAND COMMAND "${CMAKE_COMMAND}" -P "${libiconv_patch_file}")
    if(MSVC)
        set(libiconv_configure_cmd CONFIGURE_COMMAND COMMAND "")
        set(libiconv_build_cmd BUILD_COMMAND COMMAND "")
        set(libiconv_install_cmd INSTALL_COMMAND COMMAND "")
    else()
        set(libiconv_configure_cmd CONFIGURE_COMMAND COMMAND perl Configure "${perl_toolset}" ${config_options_tmp}  --prefix=${libiconv_install} --openssldir=${libiconv_install}/SSL)
        set(libiconv_build_cmd BUILD_COMMAND COMMAND make)
        set(libiconv_install_cmd INSTALL_COMMAND COMMAND make install install_sw install_ssldirs)
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${libiconv_download}" SOURCE_DIR "${libiconv_source}"
                                        ${libiconv_url_option} EXCLUDE_FROM_ALL ON
                                        ${libiconv_patch_cmd} ${libiconv_configure_cmd}
                                        ${libiconv_build_cmd} ${libiconv_install_cmd} DEPENDS ${libiconv_deps}
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
        if(NOT ("${libiconv_perl}" STREQUAL "perl"))
            list(APPEND libiconv_env_list "${libiconv_perl}/perl/bin")
        endif()
        if(NOT ("${libiconv_nasm}" STREQUAL "nasm"))
            list(APPEND libiconv_env_list "${libiconv_nasm}")
        endif()
        list(JOIN libiconv_env_list "\;" libiconv_env_list)
        if(libiconv_env_list)
            set(msvc_cmd_env call "${msvc_bat}" "${msvc_host_target}" && call set "PATH=${libiconv_env_list}\;%PATH%")
        else()
            set(msvc_cmd_env call "${msvc_bat}" "${msvc_host_target}")
        endif()
        ExternalProject_Add_StepTargets("${pkg_name}" patch)
        set_target_properties("${pkg_name}-patch" PROPERTIES EXCLUDE_FROM_ALL TRUE)
        add_custom_command(
            OUTPUT "${libiconv_tmp}/configed"
            COMMAND cmd /C ${msvc_cmd_env} && perl Configure "${perl_toolset}" ${config_options_tmp}  --prefix=${libiconv_install} --openssldir=${libiconv_install}/SSL
            COMMAND "${CMAKE_COMMAND}" -E touch "${libiconv_tmp}/configed"
            WORKING_DIRECTORY "${libiconv_source}"
            MAIN_DEPENDENCY "${config_info_file}"
            DEPENDS "${pkg_name}-patch"
            USES_TERMINAL
            COMMENT "Configure OpenSSL In '${libiconv_source}' ..."
        )
        add_custom_command(
            OUTPUT "${libiconv_tmp}/maked"
            COMMAND cmd /C ${msvc_cmd_env} && nmake
            COMMAND "${CMAKE_COMMAND}" -E touch "${libiconv_tmp}/maked"
            WORKING_DIRECTORY "${libiconv_source}"
            MAIN_DEPENDENCY "${libiconv_tmp}/configed"
            USES_TERMINAL
            COMMENT "Build OpenSSL In '${libiconv_source}' ..."
        )
        add_custom_command(
            OUTPUT "${libiconv_tmp}/installed"
            COMMAND cmd /C ${msvc_cmd_env} && nmake /f "${libiconv_source}/makefile" install_sw install_ssldirs
            COMMAND "${CMAKE_COMMAND}" -E touch "${libiconv_tmp}/installed"
            WORKING_DIRECTORY "${libiconv_source}"
            MAIN_DEPENDENCY "${libiconv_tmp}/maked"
            USES_TERMINAL
            COMMENT "Install OpenSSL In '${libiconv_install}' ..."
        )
        ExternalProject_Add_StepDependencies("${pkg_name}" install "${libiconv_tmp}/installed")
    endif()
    # set lib path dir
    set("${libiconv_name}-includes"    "${libiconv_install}/include"          PARENT_SCOPE)
    set("${libiconv_name}-pkgconfig"   "${libiconv_install}/lib/pkgconfig"    PARENT_SCOPE)
    set("${libiconv_name}-root"        "${libiconv_install}"                  PARENT_SCOPE)
    set(lib_path "${libiconv_install}/lib")
    set(bin_path "${libiconv_install}/bin")
    string(REPLACE "." ";" libiconv_version_list "${libiconv_version}")
    list(LENGTH libiconv_version_list libiconv_version_list_len)
    math(EXPR libiconv_version_list_len "${libiconv_version_list_len} - 1")
    list(REMOVE_AT libiconv_version_list ${libiconv_version_list_len})
    list(JOIN libiconv_version_list "_" libiconv_version)
    # set binary list
    set(binary_list "ssl" "crypto")
    foreach(item IN LISTS binary_list)
        # check is build shared/static
        if(libiconv_build_shared)
            add_library("${libiconv_name}::${item}" SHARED IMPORTED GLOBAL)
        else()
            add_library("${libiconv_name}::${item}" STATIC IMPORTED GLOBAL)
        endif()
        add_dependencies("${libiconv_name}::${item}" "${pkg_name}")
        # file
        guess_binary_file(name "${item}" lib_prefix "lib" bin_prefix "lib" bin_suffix "-${libiconv_version}-${msvc_target}")
        # set lib
        set_target_properties("${libiconv_name}::${item}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${${item}_lib}")
        if(libiconv_build_shared)
            set_target_properties("${libiconv_name}::${item}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${${item}_bin}")
        endif()
    endforeach()
endfunction()

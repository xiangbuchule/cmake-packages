include(ExternalProject)

# install openssl1 script
# script:       script file save path
# source:       source dir
# perl_path:    openssl1 name
# nasm_path:    openssl1 install url
# msvc_bat:     msvc bat file path
# msvc_host:    x64 x86 x86_x64 x64_x86
# config_cmd:   config command
# build_cmd:    build command
# install_cmd:  install command
function(openssl1_patch_script)
    # params
    cmake_parse_arguments(openssl1 "" "script;source;perl_path;nasm_path;msvc_bat;msvc_host" "config_cmd;build_cmd;install_cmd" ${ARGN})
    # set params
    set(script_content "\
# set perl/nasm info
set(source      \"${openssl1_source}\")
set(perl        \"${openssl1_perl_path}\")
set(nasm        \"${openssl1_nasm_path}\")
set(msvc_bat    \"${openssl1_msvc_bat}\")
set(msvc_host   \"${openssl1_msvc_host}\")
set(config_cmd  ${openssl1_config_cmd})
set(build_cmd   ${openssl1_build_cmd})
set(install_cmd ${openssl1_install_cmd})
")
    # set other script
    string(APPEND script_content [[
# write Configure content
set(regex_string "use OpenSSL::Glob\;")
string(APPEND replace_content "${regex_string}\n")
string(APPEND replace_content "no warnings 'all';")
file(READ "${source}/Configure" old_content)
string(REPLACE "${regex_string}" "${replace_content}" new_content "${old_content}")
file(WRITE "${source}/Configure" "${new_content}")
if(msvc_bat)
    # run env
    set(perl_nasm_env   "${perl}/perl/bin\;${nasm}\;!PATH!")
    set(msvc_cmd_env    call "${msvc_bat}" "${msvc_host}" && call set "PATH=${perl_nasm_env}")
    # config
    if(NOT EXISTS "${source}/configdata.pm" AND NOT IS_DIRECTORY "${source}/configdata.pm")
        execute_process(
            COMMAND cmd /V:ON /C ${msvc_cmd_env} && ${config_cmd}
            WORKING_DIRECTORY "${source}"
            ERROR_VARIABLE config_error
        )
        if(NOT ("${config_error}" STREQUAL ""))
            message(FATAL_ERROR "Config openssl1 Error:" ${config_error})
            # message("Config openssl1 Error:" ${config_error})
        endif()
    endif()
    # build
    execute_process(
        COMMAND cmd /V:ON /C ${msvc_cmd_env} && ${build_cmd}
        WORKING_DIRECTORY "${source}"
        ERROR_VARIABLE build_error
    )
    if(NOT ("${build_error}" STREQUAL ""))
        message(FATAL_ERROR "build openssl1 Error:" ${build_error})
        # message("build openssl1 Error:" ${build_error})
    endif()
    # install
    execute_process(
        COMMAND cmd /V:ON /C ${msvc_cmd_env} && ${install_cmd}
        WORKING_DIRECTORY "${source}"
        ERROR_VARIABLE install_error
    )
    if(NOT ("${install_error}" STREQUAL ""))
        message(FATAL_ERROR "Install openssl1 Error:" ${install_error})
        # message( "Install openssl1 Error:" ${install_error})
    endif()
endif()
]])
    file(WRITE "${openssl1_script}" "${script_content}")
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
# nasm:     nasm path dir
# perl:     perl path dir
function(add_openssl1)
    # params
    cmake_parse_arguments(openssl1 "" "name;prefix;version;nasm;perl" "options;deps" ${ARGN})
    # if target exist, return
    if(TARGET "${openssl1_name}" OR (DEFINED "${openssl1_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${openssl1_name}")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "openssl1_build_type" args_list_name "openssl1_UNPARSED_ARGUMENTS")
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
    set(openssl1_install   "${openssl1_prefix}/cache/install/${openssl1_name}/${openssl1_build_type}")
    if(NOT EXISTS "${openssl1_install}" OR IS_DIRECTORY "${openssl1_install}")
        file(MAKE_DIRECTORY "${openssl1_install}")
    endif()
    set(openssl1_build  "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(openssl1_source "${openssl1_prefix}/${openssl1_name}")
    set(openssl1_patch  "${openssl1_prefix}/cache/patch/${openssl1_name}")
    set(openssl1_binary "${openssl1_prefix}/cache/bin/${openssl1_name}/${openssl1_build_type}")
    if(NOT EXISTS "${openssl1_binary}" OR IS_DIRECTORY "${openssl1_binary}")
        file(MAKE_DIRECTORY "${openssl1_binary}")
    endif()
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
        set(openssl1_configure_cmd CONFIGURE_COMMAND COMMAND "")
        set(openssl1_build_cmd BUILD_COMMAND COMMAND "")
        set(openssl1_install_cmd INSTALL_COMMAND COMMAND "")
    elseif(MINGW)
        set(openssl1_configure_cmd CONFIGURE_COMMAND COMMAND perl -w Configure "${perl_toolset}" no-tests --prefix=${openssl1_install} --openssldir=${openssl1_install}/SSL)
        set(openssl1_build_cmd BUILD_COMMAND COMMAND "")
        set(openssl1_install_cmd INSTALL_COMMAND COMMAND "")
    else()
        set(openssl1_configure_cmd CONFIGURE_COMMAND COMMAND perl -w Configure "${perl_toolset}" no-tests --prefix=${openssl1_install} --openssldir=${openssl1_install}/SSL)
        set(openssl1_build_cmd BUILD_COMMAND COMMAND "")
        set(openssl1_install_cmd INSTALL_COMMAND COMMAND "")
    endif()
    # patch
    set(openssl1_patch_file "${openssl1_patch}/patch.cmake")
    openssl1_patch_script(
        script      "${openssl1_patch_file}"
        source      "${openssl1_source}"
        perl_path   "${openssl1_perl}"
        nasm_path   "${openssl1_nasm}"
        msvc_bat    "${msvc_bat}"
        msvc_host   "${msvc_host_target}"
        config_cmd  perl -w Configure "${perl_toolset}" no-tests --prefix=${openssl1_install} --openssldir=${openssl1_install}/SSL
        build_cmd   nmake
        install_cmd nmake install_sw
    )
    set(openssl1_patch_cmd PATCH_COMMAND "${CMAKE_COMMAND}" -P "${openssl1_patch_file}")
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${openssl1_download}" SOURCE_DIR "${openssl1_source}"
                                        ${openssl1_url_option} EXCLUDE_FROM_ALL ON ${openssl1_patch_cmd}
                                        ${openssl1_configure_cmd} ${openssl1_build_cmd} ${openssl1_install_cmd} DEPENDS ${openssl1_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # check is build shared/static
    if(openssl1_build_shared)
        add_library("${openssl1_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${openssl1_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${openssl1_name}" "${pkg_name}")
    # set lib path dir
    set("${openssl1_name}-includes"    "${openssl1_install}/include"          PARENT_SCOPE)
    set("${openssl1_name}-pkgconfig"   "${openssl1_install}/lib/pkgconfig"    PARENT_SCOPE)
    set("${openssl1_name}-root"        "${openssl1_install}"                  PARENT_SCOPE)
    set(lib_path "${openssl1_install}/lib")
    set(bin_path "${openssl1_install}/bin")
    guess_binary_file(prefix "lib" name "crypto" suffix "-3-${msvc_target}")
    guess_binary_file(prefix "lib" name "ssl" suffix "-3-${msvc_target}")
    set_target_properties("${openssl1_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${ssl_lib};${lib_path}/${crypto_lib}")
    if(openssl1_build_shared)
        set_target_properties("${openssl1_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${ssl_bin};${lib_path}/${crypto_bin}")
    endif()
endfunction()

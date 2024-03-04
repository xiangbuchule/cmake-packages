# install msys2 script
# script:   script file save path
# url:      msys2 install url
# file:     msys2 install file path
# sha256:   msys2 file sha256 check
# proxy:    proxy
function(msys2_download_script)
    # params
    cmake_parse_arguments(msys2 "" "script;url;file;sha256;proxy" "" ${ARGN})
    # set params
    set(script_content "\
# set msys2 info
set(msys2_url       \"${msys2_url}\")
set(msys2_file      \"${msys2_file}\")
set(msys2_sha256    \"${msys2_sha256}\")
set(proxy           \"${msys2_proxy}\")
")
    # set script content
    string(APPEND script_content [[
# set proxy
if(NOT ("" STREQUAL "${proxy}"))
    set(ENV{http_proxy}     "${proxy}")
    set(ENV{https_proxy}    "${proxy}")
endif()
# download
file(
    DOWNLOAD "${msys2_url}" "${msys2_file}"
    EXPECTED_HASH SHA256=${msys2_sha256}
    SHOW_PROGRESS
    STATUS msys2_download_statu
)
list(GET msys2_download_statu 0 msys2_download_statu_code)
list(REMOVE_AT msys2_download_statu 0)
if(NOT ("${msys2_download_statu_code}" STREQUAL "0"))
    message(FATAL_ERROR "Download '${msys2_url}' ===> '${msys2_file_path}' Error: ${msys2_download_statu}")
endif()
]])
    file(WRITE "${msys2_script}" "${script_content}")
endfunction()

# change msys2 source
# script:   script file save path
# source:   msys2 source dir
# url:      msys2 source url
function(msys2_extract_script)
    # params
    cmake_parse_arguments(msys2 "" "script;file;source" "" ${ARGN})
    # set params
    set(script_content "\
# set msys2 info
set(source  \"${msys2_source}\")
set(file    \"${msys2_file}\")
")
    # set script content
    string(APPEND script_content [[
# extract
file(REMOVE_RECURSE "${source}")
file(MAKE_DIRECTORY "${source}")
file(ARCHIVE_EXTRACT INPUT "${file}" DESTINATION ${source})
file(GLOB files LIST_DIRECTORIES ON "${source}/**")
foreach(item IN LISTS files)
    file(GLOB move_files LIST_DIRECTORIES ON "${item}/**")
    foreach(k IN LISTS move_files)
        file(RELATIVE_PATH move_path "${item}" "${k}")
        file(RENAME "${k}" "${source}/${move_path}")
    endforeach()
    file(REMOVE_RECURSE "${item}")
endforeach()
]])
    file(WRITE "${msys2_script}" "${script_content}")
endfunction()

# change msys2 source
# script:   script file save path
# source:   msys2 source dir
# url:      msys2 source url
function(msys2_patch_script)
    # params
    cmake_parse_arguments(msys2 "" "script;source" "source_url" ${ARGN})
    # set params
    set(script_content "\
# set msys2 info
set(source      \"${msys2_source}\")
set(source_url  \"${msys2_source_url};${msys2_UNPARSED_ARGUMENTS}\")
string(REGEX REPLACE \"(^;)|(;$)\" \"\" source_url \"\${source_url}\")
")
    # set script content
    string(APPEND script_content [[
# set content
if(NOT ("" STREQUAL "${source_url}"))
    foreach(item IN LISTS source_url)
        set(regex_string "# See https://www.msys2.org/dev/mirrors")
        set(file_name "${source}/etc/pacman.d/mirrorlist.msys")
        if(EXISTS "${file_name}" AND NOT IS_DIRECTORY "${file_name}")
            file(READ "${file_name}" content)
            set(add_content "${regex_string}\nServer = ${item}/msys2/msys/$arch/")
            string(REPLACE "${regex_string}" "${add_content}" content "${content}")
            file(WRITE "${file_name}" "${content}")
        endif()
        set(file_name "${source}/etc/pacman.d/mirrorlist.ucrt64")
        if(EXISTS "${file_name}" AND NOT IS_DIRECTORY "${file_name}")
            file(READ "${file_name}" content)
            set(add_content "${regex_string}\nServer = ${item}/msys2/mingw/ucrt64/")
            string(REPLACE "${regex_string}" "${add_content}" content "${content}")
            file(WRITE "${file_name}" "${content}")
        endif()
        set(file_name "${source}/etc/pacman.d/mirrorlist.mingw64")
        if(EXISTS "${file_name}" AND NOT IS_DIRECTORY "${file_name}")
            file(READ "${file_name}" content)
            set(add_content "${regex_string}\nServer = ${item}/msys2/mingw/x86_64/")
            string(REPLACE "${regex_string}" "${add_content}" content "${content}")
            file(WRITE "${file_name}" "${content}")
        endif()
        set(file_name "${source}/etc/pacman.d/mirrorlist.mingw32")
        if(EXISTS "${file_name}" AND NOT IS_DIRECTORY "${file_name}")
            file(READ "${file_name}" content)
            set(add_content "${regex_string}\nServer = ${item}/msys2/mingw/i686/")
            string(REPLACE "${regex_string}" "${add_content}" content "${content}")
            file(WRITE "${file_name}" "${content}")
        endif()
        set(file_name "${source}/etc/pacman.d/mirrorlist.mingw")
        if(EXISTS "${file_name}" AND NOT IS_DIRECTORY "${file_name}")
            file(READ "${file_name}" content)
            set(add_content "${regex_string}\nServer = ${item}/msys2/mingw/$repo/")
            string(REPLACE "${regex_string}" "${add_content}" content "${content}")
            file(WRITE "${file_name}" "${content}")
        endif()
        set(file_name "${source}/etc/pacman.d/mirrorlist.clang64")
        if(EXISTS "${file_name}" AND NOT IS_DIRECTORY "${file_name}")
            file(READ "${file_name}" content)
            set(add_content "${regex_string}\nServer = ${item}/msys2/mingw/clang64/")
            string(REPLACE "${regex_string}" "${add_content}" content "${content}")
            file(WRITE "${file_name}" "${content}")
        endif()
        set(file_name "${source}/etc/pacman.d/mirrorlist.clang32")
        if(EXISTS "${file_name}" AND NOT IS_DIRECTORY "${file_name}")
            file(READ "${file_name}" content)
            set(add_content "${regex_string}\nServer = ${item}/msys2/mingw/clang32/")
            string(REPLACE "${regex_string}" "${add_content}" content "${content}")
            file(WRITE "${file_name}" "${content}")
        endif()
    endforeach()
endif()
]])
    file(WRITE "${msys2_script}" "${script_content}")
endfunction()

# msys2 install packages
#   name:   pkg target name
#   prefix: prefix path
#   target: what target deps this pkgs
#   deps:   install pkg target deps what
#   msys2:  msys2 root path dir
#   pkgs:   install packages list
function(msys2_install_pkgs)
    # params
    cmake_parse_arguments(msys2 "" "name;prefix;target;msys2" "pkgs;deps" ${ARGN})
    # if exists target, return
    set(target_name "tool-${msys2_name}")
    if(TARGET "${target_name}")
        return()
    endif()
    # get dir
    if("${msys2_msys2}" STREQUAL "" OR NOT EXISTS "${msys2_msys2}")
        return()
    endif()
    # get pkgs
    set(pkgs_tmp "${msys2_pkgs};${msys2_UNPARSED_ARGUMENTS}")
    string(REGEX REPLACE "(^;)|(;$)" "" pkgs_tmp "${pkgs_tmp}")
    if("" STREQUAL "${pkgs_tmp}")
        return()
    endif()
    # set build path
    set(msys2_tmp   "${CMAKE_CURRENT_BINARY_DIR}/${target_name}-prefix")
    set(msys2_patch "${msys2_prefix}/cache/patch/${msys2_name}")
    if(NOT EXISTS "${msys2_patch}" OR NOT (IS_DIRECTORY "${msys2_patch}"))
        file(MAKE_DIRECTORY "${msys2_patch}")
    endif()
    # save pkgs info
    set(pkgs_info_file "${msys2_patch}/pkgs")
    if((NOT EXISTS "${pkgs_info_file}") OR IS_DIRECTORY "${pkgs_info_file}")
        file(WRITE "${pkgs_info_file}" "${pkgs_tmp}")
    else()
        file(READ "${pkgs_info_file}" pkgs_info)
        if(NOT ("${pkgs_tmp}" STREQUAL "${pkgs_info}"))
            file(WRITE "${pkgs_info_file}" "${pkgs_tmp}")
        endif()
    endif()
    # add build rule
    list(JOIN pkgs_tmp " " pkgs_tmp)
    add_custom_command(
        OUTPUT "${msys2_tmp}/pkgs_installed"
        COMMAND "${msys2_msys2}/usr/bin/bash" -lc "pacman -S ${pkgs_tmp} --noconfirm"
        COMMAND "${CMAKE_COMMAND}" -E touch "${msys2_tmp}/pkgs_installed"
        WORKING_DIRECTORY "${msys2_msys2}"
        MAIN_DEPENDENCY "${pkgs_info_file}"
        USES_TERMINAL
        COMMENT "Install msys2 pkgs ..."
    )
    # set target
    add_custom_target(
        "${target_name}"
        WORKING_DIRECTORY "${msys2_msys2}"
        DEPENDS "${msys2_tmp}/pkgs_installed"
        COMMENT "Build '${msys2_name}'."
    )
    # add deps
    if(NOT ("${msys2_deps}" STREQUAL ""))
        add_dependencies("${target_name}" ${msys2_deps})
    endif()
    if(NOT ("${msys2_target}" STREQUAL ""))
        add_dependencies("${msys2_target}" "${target_name}")
    endif()
endfunction()

# name:     target name
# prefix:   prefix path
# url:      download url
# file:     download file name
# sha256:   hash sha256 check
# deps:     deps target
function(add_msys2)
    # params
    cmake_parse_arguments(msys2   "" "name;prefix;url;file;sha256;proxy" "source_url;pkgs;deps" ${ARGN})
    # if exists target, return
    set(target_name "tool-${msys2_name}")
    if(TARGET "${target_name}")
        return()
    endif()
    # get pkgs
    set(pkgs "${msys2_pkgs};${msys2_UNPARSED_ARGUMENTS}")
    string(REGEX REPLACE "(^;)|(;$)" "" pkgs "${pkgs}")
    list(JOIN pkgs " " pkgs)
    # set build path
    set(msys2_tmp        "${CMAKE_CURRENT_BINARY_DIR}/${target_name}-prefix")
    set(msys2_download   "${msys2_prefix}/cache/download")
    set(msys2_source     "${msys2_prefix}/cache/tool/${msys2_name}")
    set(msys2_patch      "${msys2_prefix}/cache/patch/${msys2_name}")
    if(NOT EXISTS "${msys2_tmp}" OR NOT IS_DIRECTORY "${msys2_tmp}")
        file(MAKE_DIRECTORY "${msys2_tmp}")
    endif()
    if(NOT EXISTS "${msys2_download}" OR NOT IS_DIRECTORY "${msys2_download}")
        file(MAKE_DIRECTORY "${msys2_download}")
    endif()
    if(NOT EXISTS "${msys2_source}" OR NOT IS_DIRECTORY "${msys2_source}")
        file(MAKE_DIRECTORY "${msys2_source}")
    endif()
    if(NOT EXISTS "${msys2_patch}" OR NOT IS_DIRECTORY "${msys2_patch}")
        file(MAKE_DIRECTORY "${msys2_patch}")
    endif()
    # create patch scrips
    set(msys2_download_script_file "${msys2_patch}/download.cmake")
    msys2_download_script(
        script  "${msys2_download_script_file}"
        url     "${msys2_url}"
        file    "${msys2_download}/${msys2_file}"
        sha256  "${msys2_sha256}"
        proxy   "${msys2_proxy}"
    )
    set(msys2_extract_script_file "${msys2_patch}/extract.cmake")
    msys2_extract_script(
        script  "${msys2_extract_script_file}"
        file    "${msys2_download}/${msys2_file}"
        source  "${msys2_source}"
    )
    set(msys2_patch_script_file "${msys2_patch}/patch.cmake")
    msys2_patch_script(
        script      "${msys2_patch_script_file}"
        source      "${msys2_source}"
        source_url  ${msys2_source_url}
    )
    # add build rule
    add_custom_command(
        OUTPUT "${msys2_download}/${msys2_file}"
        COMMAND "${CMAKE_COMMAND}" -P "${msys2_download_script_file}"
        WORKING_DIRECTORY "${msys2_download}"
        USES_TERMINAL
        COMMENT "Download msys2 '${msys2_url}' ===> '${msys2_download}/${msys2_file}' ..."
    )
    add_custom_command(
        OUTPUT "${msys2_tmp}/extract"
        COMMAND "${CMAKE_COMMAND}" -P "${msys2_extract_script_file}"
        COMMAND "${CMAKE_COMMAND}" -E touch "${msys2_tmp}/extract"
        WORKING_DIRECTORY "${msys2_source}/.."
        MAIN_DEPENDENCY "${msys2_download}/${msys2_file}"
        USES_TERMINAL
        COMMENT "Extract msys2 '${msys2_download}/${msys2_file}' ===> '${msys2_source}' ..."
    )
    add_custom_command(
        OUTPUT "${msys2_tmp}/patch"
        COMMAND "${CMAKE_COMMAND}" -P "${msys2_patch_script_file}"
        COMMAND "${CMAKE_COMMAND}" -E touch "${msys2_tmp}/patch"
        WORKING_DIRECTORY "${msys2_source}"
        MAIN_DEPENDENCY "${msys2_tmp}/extract"
        USES_TERMINAL
        COMMENT "Extract msys2 '${msys2_download}/${msys2_file}' ===> '${msys2_source}' ..."
    )
    add_custom_command(
        OUTPUT "${msys2_tmp}/pkgs_installed"
        COMMAND "${msys2_source}/usr/bin/bash" -lc "pacman -Syyu --noconfirm"
        COMMAND "${msys2_source}/usr/bin/bash" -lc "pacman -S ${pkgs} --noconfirm"
        COMMAND "${CMAKE_COMMAND}" -E touch "${msys2_tmp}/pkgs_installed"
        WORKING_DIRECTORY "${msys2_source}"
        MAIN_DEPENDENCY "${msys2_tmp}/patch"
        USES_TERMINAL
        COMMENT "Install msys2 pkgs '${pkgs}' ..."
    )
    # set target
    add_custom_target(
        "${target_name}"
        DEPENDS "${msys2_tmp}/pkgs_installed"
        WORKING_DIRECTORY "${msys2_patch}"
        COMMENT "Build '${msys2_name}' In '${msys2_source}'."
    )
    # add deps
    if(NOT ("${msys2_deps}" STREQUAL ""))
        add_dependencies("${target_name}" ${msys2_deps})
    endif()
    # set python path
    set("${msys2_name}-path" "${msys2_source}" PARENT_SCOPE)
endfunction()

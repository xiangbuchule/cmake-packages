# install perl script
# script:   script file save path
# url:      perl install url
# file:     perl install file path
# sha256:   perl file sha256 check
# proxy:    proxy
function(perl_patch_script)
    # params
    cmake_parse_arguments(perl "" "script;url;file;sha256;proxy" "" ${ARGN})
    # set params
    set(script_content "\
# set perl info
set(perl_url    \"${perl_url}\")
set(perl_file   \"${perl_file}\")
set(perl_sha256 \"${perl_sha256}\")
set(proxy       \"${perl_proxy}\")
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
    DOWNLOAD "${perl_url}" "${perl_file}"
    EXPECTED_HASH SHA256=${perl_sha256}
    SHOW_PROGRESS
    STATUS perl_download_statu
)
list(GET perl_download_statu 0 perl_download_statu_code)
list(REMOVE_AT perl_download_statu 0)
if(NOT ("${perl_download_statu_code}" STREQUAL "0"))
    message(FATAL_ERROR "Download '${perl_url}' ===> '${perl_file_path}' Error: ${perl_download_statu}")
endif()
]])
    file(WRITE "${perl_script}" "${script_content}")
endfunction()

# name:     target name
# prefix:   prefix path
# url:      download url
# file:     download file name
# sha256:   hash sha256 check
# deps:     deps target
function(add_perl)
    # params
    cmake_parse_arguments(perl   "" "name;prefix;url;file;sha256;proxy" "deps" ${ARGN})
    # if exists target, return
    set(target_name "tool-${perl_name}")
    if(TARGET "${target_name}")
        return()
    endif()
    # set build path
    set(perl_tmp        "${CMAKE_CURRENT_BINARY_DIR}/${target_name}-prefix")
    set(perl_download   "${perl_prefix}/cache/download")
    set(perl_source     "${perl_prefix}/cache/tool/${perl_name}")
    set(perl_patch      "${perl_prefix}/cache/patch/${perl_name}")
    if(NOT EXISTS "${perl_tmp}" OR NOT IS_DIRECTORY "${perl_tmp}")
        file(MAKE_DIRECTORY "${perl_tmp}")
    endif()
    if(NOT EXISTS "${perl_download}" OR NOT IS_DIRECTORY "${perl_download}")
        file(MAKE_DIRECTORY "${perl_download}")
    endif()
    if(NOT EXISTS "${perl_source}" OR NOT IS_DIRECTORY "${perl_source}")
        file(MAKE_DIRECTORY "${perl_source}")
    endif()
    if(NOT EXISTS "${perl_patch}" OR NOT IS_DIRECTORY "${perl_patch}")
        file(MAKE_DIRECTORY "${perl_patch}")
    endif()
    # create patch scrips
    set(perl_patch_script_file "${perl_patch}/patch.cmake")
    perl_patch_script(
        script  "${perl_patch_script_file}"
        url     "${perl_url}"
        file    "${perl_download}/${perl_file}"
        sha256  "${perl_sha256}"
        proxy   "${perl_proxy}"
    )
    # add build rule
    add_custom_command(
        OUTPUT "${perl_download}/${perl_file}"
        COMMAND "${CMAKE_COMMAND}" -P "${perl_patch_script_file}"
        WORKING_DIRECTORY "${perl_download}"
        USES_TERMINAL
        COMMENT "Download Perl '${perl_url}' ===> '${perl_download}/${perl_file}' ..."
    )
    add_custom_command(
        OUTPUT "${perl_tmp}/touch"
        COMMAND "${CMAKE_COMMAND}" -E tar -xf "${perl_download}/${perl_file}"
        COMMAND "${CMAKE_COMMAND}" -E touch "${perl_tmp}/touch"
        WORKING_DIRECTORY "${perl_source}"
        MAIN_DEPENDENCY "${perl_download}/${perl_file}"
        USES_TERMINAL
        COMMENT "Extract Perl '${perl_download}/${perl_file}' ===> '${perl_source}' ..."
    )
    # set target
    add_custom_target(
        "${target_name}"
        DEPENDS "${perl_tmp}/touch"
        WORKING_DIRECTORY "${perl_patch}"
        COMMENT "Build '${perl_name}' In '${perl_source}'."
    )
    # add deps
    if(NOT ("${perl_deps}" STREQUAL ""))
        add_dependencies("${target_name}" ${perl_deps})
    endif()
    # set python path
    set("${perl_name}-path" "${perl_source}" PARENT_SCOPE)
endfunction()

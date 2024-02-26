# download nasm script
# script:   script file save path
# url:      nasm download url
# file:     nasm download file path
# sha256:   nasm file sha256 check
# proxy:    proxy
function(nasm_patch_download_script)
    # params
    cmake_parse_arguments(nasm "" "script;url;file;sha256;proxy" "" ${ARGN})
    # set params
    set(script_content "\
# set nasm info
set(nasm_url    \"${nasm_url}\")
set(nasm_file   \"${nasm_file}\")
set(nasm_sha256 \"${nasm_sha256}\")
set(proxy       \"${nasm_proxy}\")
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
    DOWNLOAD "${nasm_url}" "${nasm_file}"
    EXPECTED_HASH SHA256=${nasm_sha256}
    SHOW_PROGRESS
    STATUS nasm_download_statu
)
list(GET nasm_download_statu 0 nasm_download_statu_code)
list(REMOVE_AT nasm_download_statu 0)
if(NOT ("${nasm_download_statu_code}" STREQUAL "0"))
    message(FATAL_ERROR "Download '${nasm_url}' ===> '${nasm_file}' Error: ${nasm_download_statu}")
endif()
]])
    file(WRITE "${nasm_script}" "${script_content}")
endfunction()

# extract nasm script
# script:   script file save path
# file:     nasm file path
# target:   nasm extract dir
function(nasm_patch_extract_script)
    # params
    cmake_parse_arguments(nasm "" "script;file;target" "" ${ARGN})
    # set params
    set(script_content "\
# set nasm info
set(nasm_file   \"${nasm_file}\")
set(nasm_target \"${nasm_target}\")
")
    # set script content
    string(APPEND script_content [[
# extract
if(NOT EXISTS "${nasm_target}/LICENSE" OR IS_DIRECTORY "${nasm_target}/LICENSE")
    file(ARCHIVE_EXTRACT INPUT "${nasm_file}" DESTINATION ${nasm_target})
    file(GLOB_RECURSE files LIST_DIRECTORIES ON "${nasm_target}/**")
    foreach(item IN LISTS files)
        string(REGEX REPLACE "${nasm_target}/" "" file_name "${item}")
        string(REGEX MATCH "/" match_result "${file_name}")
        if(match_result)
            get_filename_component(file_name "${file_name}" NAME)
            file(RENAME "${item}" "${nasm_target}/${file_name}")
        else()
            list(APPEND remove_lists "${nasm_target}/${file_name}")
        endif()
    endforeach()
    foreach(item IN LISTS remove_lists)
        file(REMOVE_RECURSE "${item}")
    endforeach()
endif()
]])
    file(WRITE "${nasm_script}" "${script_content}")
endfunction()

# name:     target name
# prefix:   prefix path
# url:      download url
# file:     download file name
# sha256:   hash sha256 check
# proxy:    proxy
# deps:     deps target
function(add_nasm)
    # params
    cmake_parse_arguments(nasm   "" "name;prefix;url;file;sha256;proxy" "deps" ${ARGN})
    # if exists target, return
    set(target_name "tool-${nasm_name}")
    if(TARGET "${target_name}")
        return()
    endif()
    # set build path
    set(nasm_tmp        "${CMAKE_CURRENT_BINARY_DIR}/${target_name}-prefix")
    set(nasm_download   "${nasm_prefix}/cache/download")
    set(nasm_source     "${nasm_prefix}/cache/tool/${nasm_name}")
    set(nasm_patch      "${nasm_prefix}/cache/patch/${nasm_name}")
    if(NOT EXISTS "${nasm_tmp}" OR NOT (IS_DIRECTORY "${nasm_tmp}"))
        file(MAKE_DIRECTORY "${nasm_tmp}")
    endif()
    if(NOT EXISTS "${nasm_download}" OR NOT (IS_DIRECTORY "${nasm_download}"))
        file(MAKE_DIRECTORY "${nasm_download}")
    endif()
    if(NOT EXISTS "${nasm_source}" OR NOT (IS_DIRECTORY "${nasm_source}"))
        file(MAKE_DIRECTORY "${nasm_source}")
    endif()
    if(NOT EXISTS "${nasm_patch}" OR NOT (IS_DIRECTORY "${nasm_patch}"))
        file(MAKE_DIRECTORY "${nasm_patch}")
    endif()
    # create patch scrips
    set(nasm_patch_download_script_file "${nasm_patch}/download.cmake")
    nasm_patch_download_script(
        script  "${nasm_patch_download_script_file}"
        url     "${nasm_url}"
        file    "${nasm_download}/${nasm_file}"
        sha256  "${nasm_sha256}"
        proxy   "${nasm_proxy}"
    )
    set(nasm_patch_extract_script_file "${nasm_patch}/extract.cmake")
    nasm_patch_extract_script(
        script  "${nasm_patch_extract_script_file}"
        file    "${nasm_download}/${nasm_file}"
        target  "${nasm_source}"
    )
    # add build rule
    add_custom_command(
        OUTPUT "${nasm_download}/${nasm_file}"
        COMMAND "${CMAKE_COMMAND}" -P "${nasm_patch_download_script_file}"
        WORKING_DIRECTORY "${nasm_download}"
        USES_TERMINAL
        COMMENT "Download NASM '${nasm_url}' ===> '${nasm_download}/${nasm_file}' ..."
    )
    add_custom_command(
        OUTPUT "${nasm_tmp}/touch"
        COMMAND "${CMAKE_COMMAND}" -P "${nasm_patch_extract_script_file}"
        COMMAND "${CMAKE_COMMAND}" -E touch "${nasm_tmp}/touch"
        WORKING_DIRECTORY "${nasm_source}"
        MAIN_DEPENDENCY "${nasm_download}/${nasm_file}"
        USES_TERMINAL
        COMMENT "Extract NASM '${nasm_download}/${nasm_file}' ===> '${nasm_source}' ..."
    )
    # set target
    add_custom_target(
        "${target_name}"
        DEPENDS "${nasm_tmp}/touch"
        WORKING_DIRECTORY "${nasm_patch}"
        COMMENT "Build '${nasm_name}' In '${nasm_source}'."
    )
    # add deps
    if(NOT ("${nasm_deps}" STREQUAL ""))
        add_dependencies("${target_name}" ${nasm_deps})
    endif()
    # set python path
    set("${nasm_name}-path" "${nasm_source}" PARENT_SCOPE)
endfunction()

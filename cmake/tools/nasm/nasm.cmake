# install python script
# script:           script file save path
# name:             python name
# url:              python install url
# file:             python install file name
# proxy:            pip install use proxy
# pkgs:             pip install packages
# sha256:           python file sha256 check
# download:         python file save dir
# binary:           python file extract and install dir
function(nasm_patch_script)
    # params
    cmake_parse_arguments(nasm "" "script;name;url;file;sha256;download;binary;proxy" "" ${ARGN})
    # set params
    set(script_content "\
# set nasm info
set(nasm_url              \"${nasm_url}\")
set(nasm_name             \"${nasm_name}\")
set(nasm_file             \"${nasm_file}\")
set(nasm_proxy            \"${nasm_proxy}\")
set(nasm_sha256           \"${nasm_sha256}\")
set(nasm_download_path    \"${nasm_download}\")
set(nasm_binary_path      \"${nasm_binary}/\${nasm_name}\")
")
    # set other script
    string(APPEND script_content [[
# create dir
if(NOT EXISTS "${nasm_download_path}" OR IS_DIRECTORY "${nasm_download_path}")
    file(MAKE_DIRECTORY "${nasm_download_path}")
endif()
if(NOT EXISTS "${nasm_binary_path}" OR IS_DIRECTORY "${nasm_binary_path}")
    file(MAKE_DIRECTORY "${nasm_binary_path}")
endif()
# download
set(nasm_file_path "${nasm_download_path}/${nasm_file}")
file(DOWNLOAD "${nasm_url}" "${nasm_file_path}" SHOW_PROGRESS STATUS nasm_download_statu
    EXPECTED_HASH SHA256=${nasm_sha256}
)
list(GET nasm_download_statu 0 nasm_download_statu_code)
list(REMOVE_AT nasm_download_statu 0)
if(NOT ("${nasm_download_statu_code}" STREQUAL "0"))
    message(FATAL_ERROR "Download '${nasm_url} ===> ${nasm_file_path}' Error:" ${nasm_download_statu})
endif()
# extract
if(NOT EXISTS "${nasm_binary_path}/LICENSE" OR IS_DIRECTORY "${nasm_binary_path}/LICENSE")
    file(ARCHIVE_EXTRACT INPUT "${nasm_file_path}" DESTINATION "${nasm_binary_path}")
    file(GLOB_RECURSE files "${nasm_binary_path}/*.exe")
    file(GLOB_RECURSE files_license "${nasm_binary_path}/LICENSE")
    file(GLOB tmp_dirs LIST_DIRECTORIES true "${nasm_binary_path}/*")
    foreach(item IN LISTS files files_license)
        get_filename_component(tmp_name "${item}" NAME)
        get_filename_component(tmp_dir "${item}" DIRECTORY)
        get_filename_component(tmp_dir "${tmp_dir}" DIRECTORY)
        file(RENAME "${item}" "${nasm_binary_path}/${tmp_name}")
    endforeach()
    file(REMOVE_RECURSE "${tmp_dirs}")
endif()
]])
    file(WRITE "${nasm_script}" "${script_content}")
endfunction()

# name:             target name
# prefix:           prefix path
# url:              download url
# file:             download file name
# sha256:           hash sha256 check
# proxy:            proxy
# deps:             deps target
function(add_nasm)
    # params
    cmake_parse_arguments(nasm   "" "name;prefix;url;file;sha256;proxy" "deps" ${ARGN})
    # if exists target, return
    set(target_name "tool-${nasm_name}")
    if(TARGET "${target_name}")
        return()
    endif()
    # set build path
    set(nasm_download    "${nasm_prefix}/cache/download")
    set(nasm_source      "${nasm_prefix}/cache/tool")
    set(nasm_patch       "${nasm_prefix}/cache/patch/${nasm_name}")
    # create patch scrips
    if(NOT EXISTS "${nasm_patch}" OR NOT (IS_DIRECTORY "${nasm_patch}"))
        file(MAKE_DIRECTORY "${nasm_patch}")
    endif()
    set(nasm_patch_script_file "${nasm_patch}/patch.cmake")
    nasm_patch_script(
        script          "${nasm_patch_script_file}"
        name            "${nasm_name}"
        url             "${nasm_url}"
        file            "${nasm_file}"
        sha256          "${nasm_sha256}"
        download        "${nasm_download}"
        binary          "${nasm_source}"
        proxy           "${nasm_proxy}"
    )
    set(nasm_source "${nasm_source}/${nasm_name}")
    # set target
    add_custom_target(
        "${target_name}" WORKING_DIRECTORY "${nasm_patch}" USES_TERMINAL
        COMMAND "${CMAKE_COMMAND}" -P "${nasm_patch_script_file}"
    )
    # add deps
    if(NOT ("${nasm_deps}" STREQUAL ""))
        add_dependencies("${target_name}" ${nasm_deps})
    endif()
    # set python path
    set("${nasm_name}-path" "${nasm_source}" PARENT_SCOPE)
endfunction()

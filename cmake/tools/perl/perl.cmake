# install perl script
# script:   script file save path
# name:     perl name
# url:      perl install url
# file:     perl install file name
# pkgs:     pip install packages
# sha256:   perl file sha256 check
# download: perl file save dir
# binary:   perl file extract and install dir
function(perl_patch_script)
    # params
    cmake_parse_arguments(perl "" "script;name;url;file;sha256;download;binary" "pkgs;source_url" ${ARGN})
    # set params
    set(script_content "\
# set perl info
set(perl_url            \"${perl_url}\")
set(perl_name           \"${perl_name}\")
set(perl_file           \"${perl_file}\")
set(perl_pkgs           \"${perl_pkgs};${perl_UNPARSED_ARGUMENTS}\")
set(perl_sha256         \"${perl_sha256}\")
set(perl_source_url     \"${perl_source_url}\")
set(perl_download_path  \"${perl_download}\")
set(perl_binary_path    \"${perl_binary}/\${perl_name}\")
string(REGEX REPLACE    \"(^;)|(;$)\" \"\" perl_pkgs \"\${perl_pkgs}\")
")
    # set other script
    string(APPEND script_content [[
# create dir
if(NOT EXISTS "${perl_download_path}" OR IS_DIRECTORY "${perl_download_path}")
    file(MAKE_DIRECTORY "${perl_download_path}")
endif()
if(NOT EXISTS "${perl_binary_path}" OR IS_DIRECTORY "${perl_binary_path}")
    file(MAKE_DIRECTORY "${perl_binary_path}")
endif()
# download
set(perl_file_path "${perl_download_path}/${perl_file}")
file(DOWNLOAD "${perl_url}" "${perl_file_path}" SHOW_PROGRESS STATUS perl_download_statu
    EXPECTED_HASH SHA256=${perl_sha256}
)
list(GET perl_download_statu 0 perl_download_statu_code)
list(REMOVE_AT perl_download_statu 0)
if(NOT ("${perl_download_statu_code}" STREQUAL "0"))
    message(FATAL_ERROR "Download '${perl_url} ===> ${perl_file_path}' Error:" ${perl_download_statu})
endif()
# extract
if(NOT EXISTS "${perl_binary_path}/README.txt" OR IS_DIRECTORY "${perl_binary_path}/README.txt")
    file(ARCHIVE_EXTRACT INPUT "${perl_file_path}" DESTINATION "${perl_binary_path}")
endif()
]])
    file(WRITE "${perl_script}" "${script_content}")
endfunction()

# perl install packages
# name:     pkg target name
# target:   what target deps this pkgs
# deps:     install pkg target deps what
# perl:     perl executable path
# pkgs:     install packages list
# function(perl_install_pkgs)
#     # params
#     cmake_parse_arguments(perl "" "name;target;perl" "deps;pkgs" ${ARGN})
#     # set option
#     if(NOT ("${perl_perl}" STREQUAL ""))
#         set(perl_executable "${perl_perl}")
#         get_filename_component(work_directory "${perl_perl}" DIRECTORY)
#         set(work_directory_option WORKING_DIRECTORY "${work_directory}")
#     else()
#         set(perl_executable "prel")
#     endif()
#     if("${pip_proxy}")
#         set(pip_option "${pip_option};--proxy;${pip_proxy}")
#     endif()
#     # set target
#     add_custom_target(
#         "${perl_name}" WORKING_DIRECTORY "${perl}" USES_TERMINAL
#         COMMAND "${CMAKE_COMMAND}" -E chdir "${pip_python}" "${pip_python}/python" -m pip ${pip_option} install ${install_option} ${pip_pkgs} ${pip_UNPARSED_ARGUMENTS}
#     )
#     # add deps
#     if(NOT ("${perl_deps}" STREQUAL ""))
#         add_dependencies("${perl_name}" ${perl_deps})
#     endif()
#     if(NOT ("${perl_target}" STREQUAL ""))
#         add_dependencies("${perl_target}" "${perl_name}")
#     endif()
# endfunction()

# name:     target name
# prefix:   prefix path
# url:      download url
# file:     download file name
# sha256:   hash sha256 check
# deps:     deps target
# pkgs:     need python packages
function(add_perl)
    # params
    cmake_parse_arguments(perl   "" "name;prefix;url;file;sha256;proxy" "deps;pkgs" ${ARGN})
    # if exists target, return
    set(target_name "tool-${perl_name}")
    if(TARGET "${target_name}")
        return()
    endif()
    # set build path
    set(perl_download    "${perl_prefix}/cache/download")
    set(perl_source      "${perl_prefix}/cache/tool")
    set(perl_patch       "${perl_prefix}/cache/patch")
    # create patch scrips
    if(NOT EXISTS "${perl_patch}" OR NOT (IS_DIRECTORY "${perl_patch}"))
        file(MAKE_DIRECTORY "${perl_patch}")
    endif()
    set(perl_patch_script_file "${perl_patch}/${perl_name}/patch.cmake")
    perl_patch_script(
        script      "${perl_patch_script_file}"
        name        "${perl_name}"
        url         "${perl_url}"
        file        "${perl_file}"
        sha256      "${perl_sha256}"
        download    "${perl_download}"
        binary      "${perl_source}"
        proxy       "${perl_proxy}"
        pkgs        ${perl_pkgs}
        ${perl_UNPARSED_ARGUMENTS}
    )
    # set target
    add_custom_target(
        "${target_name}" ALL WORKING_DIRECTORY "${perl_patch}" USES_TERMINAL
        COMMAND "${CMAKE_COMMAND}" -P "${perl_patch_script_file}"
    )
    # add deps
    if(NOT ("${perl_deps}" STREQUAL ""))
        add_dependencies("${target_name}" ${perl_deps})
    endif()
    # set python path
    set("${perl_name}-path" "${perl_source}/${perl_name}" PARENT_SCOPE)
endfunction()

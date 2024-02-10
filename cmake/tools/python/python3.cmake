# install python script
# script:   script file save path
# name:     python name
# url:      python install url
# file:     python install file name
# proxy:    pip install use proxy
# pkgs:     pip install packages
# sha256:   python file sha256 check
# download: python file save dir
# binary:   python file extract and install dir
function(python3_patch_script)
    # params
    cmake_parse_arguments(python3 "" "script;name;url;file;sha256;download;binary;proxy;pip_url;pip_file" "pkgs" ${ARGN})
    # set params
    set(script_content "\
# set python info
set(python_url              \"${python3_url}\")
set(python_name             \"${python3_name}\")
set(python_file             \"${python3_file}\")
set(python_pkgs             \"${python3_pkgs}\" \"${python3_UNPARSED_ARGUMENTS}\")
set(python_proxy            \"${python3_proxy}\")
set(python_sha256           \"${python3_sha256}\")
set(python_download_path    \"${python3_download}\")
set(python_binary_path      \"${python3_binary}/\${python_name}\")
set(pip_url                 \"${python3_pip_url}\")
set(pip_file                \"\${python_name}-${python3_pip_file}\")
")
    # set other script
    string(APPEND script_content [[
# create dir
if(NOT EXISTS "${python_download_path}" OR IS_DIRECTORY "${python_download_path}")
    file(MAKE_DIRECTORY "${python_download_path}")
endif()
if(NOT EXISTS "${python_binary_path}" OR IS_DIRECTORY "${python_binary_path}")
    file(MAKE_DIRECTORY "${python_binary_path}")
endif()
# download
set(python_file_path "${python_download_path}/${python_file}")
file(DOWNLOAD "${python_url}" "${python_file_path}" SHOW_PROGRESS STATUS python_download_statu
    EXPECTED_HASH SHA256=${python_sha256}
)
list(GET python_download_statu 0 python_download_statu_code)
list(REMOVE_AT python_download_statu 0)
if(NOT ("${python_download_statu_code}" STREQUAL "0"))
    message(FATAL_ERROR "Download '${python_url} ===> ${python_file_path}' Error:" ${python_download_statu})
endif()
set(pip_file_path "${python_download_path}/${pip_file}")
if(NOT (EXISTS "${pip_file_path}") OR IS_DIRECTORY "${pip_file_path}")
    file(DOWNLOAD "${pip_url}" "${pip_file_path}" SHOW_PROGRESS STATUS pip_download_statu)
    list(GET pip_download_statu 0 pip_download_statu_code)
    list(REMOVE_AT pip_download_statu 0)
    if(NOT ("${pip_download_statu_code}" STREQUAL "0"))
        if(EXISTS "${pip_file_path}" AND NOT (IS_DIRECTORY "${pip_file_path}"))
            file(REMOVE "${pip_file_path}")
        endif()
        message(FATAL_ERROR "Download '${pip_url} ===> ${pip_file_path}' Error:" ${pip_download_statu})
    endif()
endif()
# extract
if(NOT EXISTS "${python_binary_path}/LICENSE.txt" OR IS_DIRECTORY "${python_binary_path}/LICENSE.txt")
    file(ARCHIVE_EXTRACT INPUT "${python_file_path}" DESTINATION "${python_binary_path}")
endif()
# install pip
if(NOT EXISTS "${python_binary_path}/Lib/site-packages" OR NOT (IS_DIRECTORY "${python_binary_path}"))
    execute_process(WORKING_DIRECTORY "${python_binary_path}" ERROR_VARIABLE python_install_pip_error
        COMMAND "${CMAKE_COMMAND}" -E chdir "${python_binary_path}" "${python_binary_path}/python" "${python_download_path}/${pip_file}" --no-warn-script-location
    )
    if(NOT ("${python_install_pip_error}" STREQUAL ""))
        file(REMOVE "${python_binary_path}")
        message(FATAL_ERROR "Install Pip Error:" ${python_install_pip_error})
    endif()
    # find python*._pth
    file(GLOB config_files "${python_binary_path}/python*._pth")
    list(GET config_files 0 config_file)
    # read/write change config
    file(READ "${config_file}" python_config)
    string(REGEX REPLACE "#import site" "import site" python_config "${python_config}")
    file(WRITE "${config_file}" "${python_config}")
endif()
# install pkgs
if(NOT ("${python_pkgs}" STREQUAL ";"))
    set(install_option "--no-warn-script-location;--no-warn-conflicts;--no-python-version-warning")
    set(pip_option "--cache-dir;${python_binary_path}/cache")
    if("${python_proxy}")
        set(pip_option "${pip_option};--proxy;${python_proxy}")
    endif()
    execute_process(WORKING_DIRECTORY "${python_binary_path}" ERROR_VARIABLE pkgs_install_error
        COMMAND "${CMAKE_COMMAND}" -E chdir "${python_binary_path}" "${python_binary_path}/python" -m pip ${pip_option} install ${install_option} ${python_pkgs}
    )
    if(NOT ("${pkgs_install_error}" STREQUAL ""))
        message(FATAL_ERROR "Install '${python_pkgs}' Error:" ${pkgs_install_error})
    endif()
endif()
]])
    if(NOT EXISTS "${python3_script}" OR IS_DIRECTORY "${python3_script}")
        file(WRITE "${python3_script}" "${script_content}")
    endif()
endfunction()

# pip install packages
#   name:   pkg target name
#   target: what target deps this pkgs
#   deps:   install pkg target deps what
#   python: python executable program path
#   pkgs:   install packages list
function(pip_install_pkgs)
    # params
    cmake_parse_arguments(pip "" "name;target;python;proxy" "deps;pkgs" ${ARGN})
    # set option
    string(TOUPPER "${pip_python}" pip_python_tmp)
    if(NOT ("${pip_python}" STREQUAL "") AND NOT ("${pip_python_tmp}" STREQUAL "PYTHON"))
        set(python_executable "${pip_python}")
        get_filename_component(work_directory "${pip_python}" DIRECTORY)
        set(work_directory_option WORKING_DIRECTORY "${work_directory}")
    else()
        set(python_executable "python")
    endif()
    set(install_option "--no-warn-script-location;--no-warn-conflicts;--no-python-version-warning")
    set(pip_option "--cache-dir;${pip_python}/cache")
    if("${pip_proxy}")
        set(pip_option "${pip_option};--proxy;${pip_proxy}")
    endif()
    # set target
    add_custom_target(
        "${pip_name}" ${work_directory_option} USES_TERMINAL
        COMMAND "${python_executable}" -m pip ${pip_option} install ${install_option} ${pip_pkgs} ${pip_UNPARSED_ARGUMENTS}
    )
    # add deps
    if(NOT ("${pip_deps}" STREQUAL ""))
        add_dependencies("${pip_name}" ${pip_deps})
    endif()
    if(NOT ("${pip_target}" STREQUAL ""))
        add_dependencies("${pip_target}" "${pip_name}")
    endif()
endfunction()

# name:     target name
# prefix:   prefix path
# url:      download url
# file:     download file name
# sha256:   hash sha256 check
# deps:     deps target
# pkgs:     need python packages
function(add_python3)
    # params
    cmake_parse_arguments(python3   "" "name;prefix;url;file;sha256;proxy;pip_url;pip_file" "deps;pkgs" ${ARGN})
    # if exists target, return
    set(target_name "tool-${python3_name}")
    if(TARGET "${target_name}")
        return()
    endif()
    # set build path
    set(python3_download    "${python3_prefix}/cache/download")
    set(python3_source      "${python3_prefix}/cache/tool")
    set(python3_patch       "${python3_prefix}/cache/patch/${python3_name}")
    # create patch scrips
    if(NOT EXISTS "${python3_patch}" OR NOT (IS_DIRECTORY "${python3_patch}"))
        file(MAKE_DIRECTORY "${python3_patch}")
    endif()
    set(python3_patch_script_file "${python3_patch}/patch.cmake")
    python3_patch_script(
        script      "${python3_patch_script_file}"
        name        "${python3_name}"
        url         "${python3_url}"
        file        "${python3_file}"
        sha256      "${python3_sha256}"
        download    "${python3_download}"
        binary      "${python3_source}"
        proxy       "${python3_proxy}"
        pip_url     "${python3_pip_url}"
        pip_file    "${python3_pip_file}"
        pkgs        ${python3_pkgs}
        ${python3_UNPARSED_ARGUMENTS}
    )
    set(python3_source "${python3_source}/${python3_name}")
    # set target
    add_custom_target(
        "${target_name}" WORKING_DIRECTORY "${python3_patch}" USES_TERMINAL
        COMMAND "${CMAKE_COMMAND}" -P "${python3_patch_script_file}"
    )
    # add deps
    if(NOT ("${python3_deps}" STREQUAL ""))
        add_dependencies("${target_name}" ${python3_deps})
    endif()
    # set python path
    set("${python3_name}-path" "${python3_source}" PARENT_SCOPE)
endfunction()

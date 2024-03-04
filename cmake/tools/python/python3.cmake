# download python script
#   script:     script file save path
#   url:        python download url
#   file:       python download file path
#   proxy:      use proxy
#   sha256:     python file sha256 check
#   pip_url:    pip url
#   pip_file:   pip file
function(python3_patch_download_script)
    # params
    cmake_parse_arguments(python3 "" "script;url;file;sha256;proxy;pip_url;pip_file" "" ${ARGN})
    # set params
    set(script_content "\
# set python/pip info
set(python_url      \"${python3_url}\")
set(python_file     \"${python3_file}\")
set(python_sha256   \"${python3_sha256}\")
set(pip_url         \"${python3_pip_url}\")
set(pip_file        \"${python3_pip_file}\")
set(proxy           \"${python3_proxy}\")
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
    DOWNLOAD "${python_url}" "${python_file}"
    EXPECTED_HASH SHA256=${python_sha256}
    SHOW_PROGRESS
    STATUS python_download_statu
)
list(GET python_download_statu 0 python_download_statu_code)
list(REMOVE_AT python_download_statu 0)
if(NOT ("${python_download_statu_code}" STREQUAL "0"))
    message(FATAL_ERROR "Download '${python_url}' ===> '${python_file}' Error: ${python_download_statu}")
endif()
file(
    DOWNLOAD "${pip_url}" "${pip_file}"
    SHOW_PROGRESS
    STATUS pip_download_statu
)
list(GET pip_download_statu 0 pip_download_statu_code)
list(REMOVE_AT pip_download_statu 0)
if(NOT ("${pip_download_statu_code}" STREQUAL "0"))
    message(FATAL_ERROR "Download '${pip_url}' ===> '${pip_file}' Error: ${pip_download_statu}")
endif()
]])
    file(WRITE "${python3_script}" "${script_content}")
endfunction()

# install python pip script
#   script:         script file save path
#   python:         python root dir
#   pip:            pip file path
#   pip_source_url  pip source url
function(python3_patch_install_pip_script)
    # params
    cmake_parse_arguments(python3 "" "script;python;pip;pip_source_url" "" ${ARGN})
    # set params
    set(script_content "\
# set python/pip info
set(python_path     \"${python3_python}\")
set(pip_file        \"${python3_pip}\")
set(pip_source_url  \"${python3_pip_source_url}\")
")
    # set script content
    string(APPEND script_content [[
# config pip
if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
    set(pip_config_file "${python_path}/pip.ini")
else()
    set(pip_config_file "${python_path}/pip.conf")
endif()
if(NOT ("" STREQUAL "${pip_source_url}"))
    string(APPEND pip_config_content "[global]\n")
    string(APPEND pip_config_content "index-url = ${pip_source_url}/simple\n")
    string(APPEND pip_config_content "[install]\n")
    string(APPEND pip_config_content "trusted-host = ${pip_source_url}\n")
    file(WRITE "${pip_config_file}" "${pip_config_content}")
else()
    file(TOUCH "${pip_config_file}")
endif()
# install pip
execute_process(
    COMMAND "${python_path}/python" "${pip_file}" --no-warn-script-location
    WORKING_DIRECTORY "${python_path}"
    ERROR_VARIABLE install_pip_error
)
if(NOT ("" STREQUAL "${install_pip_error}"))
    file(REMOVE "${pip_config_file}")
    message(FATAL_ERROR "Install Pip Error: ${install_pip_error}")
endif()
# find python*._pth
file(GLOB config_files "${python_path}/python*._pth")
list(GET config_files 0 config_file)
# read/write change python*._pth
file(READ "${config_file}" python_config)
string(REGEX REPLACE "#import site" "import site" python_config "${python_config}")
file(WRITE "${config_file}" "${python_config}")
]])
    file(WRITE "${python3_script}" "${script_content}")
endfunction()

# install python pkgs script
#   script: script file save path
#   python: python root dir
#   pkgs:   pkgs
#   proxy:  use proxy
function(python3_patch_install_pkgs_script)
    # params
    cmake_parse_arguments(python3 "" "script;python;proxy" "pkgs" ${ARGN})
    # set params
    set(script_content "\
# set python/pip info
set(python_path     \"${python3_python}\")
set(pkgs            \"${python3_pkgs};${python3_UNPARSED_ARGUMENTS}\")
set(proxy           \"${python3_proxy}\")
string(REGEX REPLACE \"(^;)|(;$)\" \"\" pkgs \"\${pkgs}\")
")
    # set script content
    string(APPEND script_content [[
# install config
set(install_option "--no-warn-script-location;--no-warn-conflicts;--no-python-version-warning")
set(pip_option "--cache-dir;${python_path}/cache")
if("${proxy}")
    list(APPEND pip_option "--proxy;${proxy}")
endif()
if(NOT ("" STREQUAL "${pkgs}"))
    execute_process(
        COMMAND "${python_path}/python" -m pip ${pip_option} install ${install_option} ${pkgs}
        WORKING_DIRECTORY "${python_path}"
        ERROR_VARIABLE pkgs_install_error
    )
    if(NOT ("" STREQUAL "${pkgs_install_error}"))
        message(FATAL_ERROR "Install '${python_pkgs}' Error: ${pkgs_install_error}")
    endif()
endif()
]])
    file(WRITE "${python3_script}" "${script_content}")
endfunction()

# pip install packages
#   name:   pkg target name
#   prefix: prefix path
#   target: what target deps this pkgs
#   deps:   install pkg target deps what
#   python: python executable program path
#   pkgs:   install packages list
function(pip_install_pkgs)
    # params
    cmake_parse_arguments(pip "" "name;prefix;target;python;proxy" "deps;pkgs" ${ARGN})
    # if exists target, return
    set(target_name "tool-${pip_name}")
    if(TARGET "${target_name}")
        return()
    endif()
    # get pkgs
    set(pkgs_tmp "${pip_pkgs};${pip_UNPARSED_ARGUMENTS}")
    string(REGEX REPLACE "(^;)|(;$)" "" pkgs_tmp "${pkgs_tmp}")
    if("" STREQUAL "${pkgs_tmp}")
        return()
    endif()
    # set build path
    set(pip_tmp   "${CMAKE_CURRENT_BINARY_DIR}/${target_name}-prefix")
    set(pip_patch "${pip_prefix}/cache/patch/${pip_name}")
    if(NOT EXISTS "${pip_patch}" OR NOT (IS_DIRECTORY "${pip_patch}"))
        file(MAKE_DIRECTORY "${pip_patch}")
    endif()
    # save pkgs info
    set(pkgs_info_file "${pip_patch}/pkgs")
    if((NOT EXISTS "${pkgs_info_file}") OR IS_DIRECTORY "${pkgs_info_file}")
        file(WRITE "${pkgs_info_file}" "${pkgs_tmp}")
    else()
        file(READ "${pkgs_info_file}" pkgs_info)
        if(NOT ("${pkgs_tmp}" STREQUAL "${pkgs_info}"))
            file(WRITE "${pkgs_info_file}" "${pkgs_tmp}")
        endif()
    endif()
    # set option
    string(TOUPPER "${pip_python}" pip_python_tmp)
    if(NOT ("${pip_python}" STREQUAL "") AND NOT ("${pip_python_tmp}" STREQUAL "PYTHON"))
        set(python_executable "${pip_python}")
        get_filename_component(work_directory "${pip_python}" DIRECTORY)
        set(work_directory_option WORKING_DIRECTORY "${work_directory}")
        set(pip_option "--cache-dir;${pip_python}/cache")
    else()
        set(python_executable "python")
    endif()
    set(install_option "--no-warn-script-location;--no-warn-conflicts;--no-python-version-warning")
    if("${pip_proxy}")
        list(APPEND pip_option "--proxy;${pip_proxy}")
    endif()
    # add build rule
    add_custom_command(
        OUTPUT "${pip_tmp}/pkgs_installed"
        COMMAND "${python_executable}" -m pip ${pip_option} install ${install_option} ${pkgs_tmp}
        COMMAND "${CMAKE_COMMAND}" -E touch "${pip_tmp}/pkgs_installed"
        ${work_directory_option}
        MAIN_DEPENDENCY "${pkgs_info_file}"
        USES_TERMINAL
        COMMENT "Install pip pkgs ..."
    )
    # set target
    add_custom_target(
        "${target_name}"
        ${work_directory_option}
        DEPENDS "${pip_tmp}/pkgs_installed"
        COMMENT "Build '${pip_name}'."
    )
    # add deps
    if(NOT ("${pip_deps}" STREQUAL ""))
        add_dependencies("${target_name}" ${pip_deps})
    endif()
    if(NOT ("${pip_target}" STREQUAL ""))
        add_dependencies("${pip_target}" "${target_name}")
    endif()
endfunction()

# add python3 tools
#   name:           target name
#   prefix:         prefix path
#   url:            download url
#   file:           download file name
#   sha256:         hash sha256 check
#   deps:           deps target
#   pkgs:           need python packages
#   pip_url:        pip url
#   pip_file:       pip file
#   pip_sha256      pip sha256 check
#   pip_source_url: pip source url
function(add_python3)
    # params
    cmake_parse_arguments(python3 "" "name;prefix;url;file;sha256;proxy;pip_url;pip_file;pip_source_url" "deps;pkgs" ${ARGN})
    # if exists target, return
    set(target_name "tool-${python3_name}")
    if(TARGET "${target_name}")
        return()
    endif()
    # set build path
    set(python3_tmp         "${CMAKE_CURRENT_BINARY_DIR}/${target_name}-prefix")
    set(python3_download    "${python3_prefix}/cache/download")
    set(python3_source      "${python3_prefix}/cache/tool/${python3_name}")
    set(python3_patch       "${python3_prefix}/cache/patch/${python3_name}")
    if(NOT EXISTS "${python3_tmp}" OR NOT IS_DIRECTORY "${python3_tmp}")
        file(MAKE_DIRECTORY "${python3_tmp}")
    endif()
    if(NOT EXISTS "${python3_download}" OR NOT IS_DIRECTORY "${python3_download}")
        file(MAKE_DIRECTORY "${python3_download}")
    endif()
    if(NOT EXISTS "${python3_source}" OR NOT IS_DIRECTORY "${python3_source}")
        file(MAKE_DIRECTORY "${python3_source}")
    endif()
    if(NOT EXISTS "${python3_patch}" OR NOT IS_DIRECTORY "${python3_patch}")
        file(MAKE_DIRECTORY "${python3_patch}")
    endif()
    # set pip file name
    get_filename_component(python_name_tmp "${python3_file}" NAME_WLE)
    set(python3_pip_file "${python_name_tmp}-${python3_pip_file}")
    # create patch scrips
    set(python3_patch_download_script_file "${python3_patch}/download.cmake")
    python3_patch_download_script(
        script      "${python3_patch_download_script_file}"
        url         "${python3_url}"
        file        "${python3_download}/${python3_file}"
        sha256      "${python3_sha256}"
        proxy       "${python3_proxy}"
        pip_url     "${python3_pip_url}"
        pip_file    "${python3_download}/${python3_pip_file}"
    )
    set(python3_patch_install_pip_script_file "${python3_patch}/pip.cmake")
    python3_patch_install_pip_script(
        script          "${python3_patch_install_pip_script_file}"
        python          "${python3_source}"
        pip             "${python3_download}/${python3_pip_file}"
        pip_source_url  "${python3_pip_source_url}"
    )
    set(python3_patch_install_pkgs_script "${python3_patch}/pkgs.cmake")
    if("" STREQUAL "${python3_pip_source_url}")
        set(proxy_tmp "${python3_proxy}")
    else()
        set(proxy_tmp "")
    endif()
    set(pkgs_tmp "${python3_pkgs};${python3_UNPARSED_ARGUMENTS}")
    string(REGEX REPLACE "(^;)|(;$)" "" pkgs_tmp "${pkgs_tmp}")
    python3_patch_install_pkgs_script(
        script  "${python3_patch_install_pkgs_script}"
        python  "${python3_source}"
        proxy   "${proxy_tmp}"
        pkgs    ${pkgs_tmp}
    )
    # add build rule
    add_custom_command(
        OUTPUT "${python3_download}/${python3_file}" "${python3_download}/${python3_pip_file}"
        COMMAND "${CMAKE_COMMAND}" -E echo "Download Python '${python3_url}' ===> '${python3_download}/${python3_file}' ..."
        COMMAND "${CMAKE_COMMAND}" -E echo "Download Python '${python3_pip_url}' ===> '${python3_download}/${python3_pip_file}' ..."
        COMMAND "${CMAKE_COMMAND}" -P "${python3_patch_download_script_file}"
        WORKING_DIRECTORY "${python3_download}"
        USES_TERMINAL
    )
    add_custom_command(
        OUTPUT "${python3_tmp}/extracted"
        COMMAND "${CMAKE_COMMAND}" -E tar -xf "${python3_download}/${python3_file}"
        COMMAND "${CMAKE_COMMAND}" -E touch "${python3_tmp}/extracted"
        WORKING_DIRECTORY "${python3_source}"
        DEPENDS "${python3_download}/${python3_file}" "${python3_download}/${python3_pip_file}"
        USES_TERMINAL
        COMMENT "Extract Python '${python3_download}/${python3_file}' ===> '${python3_source}' ..."
    )
    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        set(pip_config_file "${python3_source}/pip.ini")
    else()
        set(pip_config_file "${python3_source}/pip.conf")
    endif()
    add_custom_command(
        OUTPUT "${pip_config_file}"
        COMMAND "${CMAKE_COMMAND}" -P "${python3_patch_install_pip_script_file}"
        WORKING_DIRECTORY "${python3_source}"
        MAIN_DEPENDENCY "${python3_tmp}/extracted"
        USES_TERMINAL
        COMMENT "Install Pip '${python3_download}/${python3_pip_file}' ===> '${python3_source}' ..."
    )
    set(pkgs_info_file "${python3_tmp}/pkgs")
    if((NOT EXISTS "${pkgs_info_file}") OR IS_DIRECTORY "${pkgs_info_file}")
        if("" STREQUAL "${pkgs_tmp}")
            file(TOUCH "${pkgs_info_file}")
        else()
            file(WRITE "${pkgs_info_file}" "${pkgs_tmp}")
        endif()
    else()
        file(READ "${pkgs_info_file}" pkgs_info)
        if(NOT ("${pkgs_tmp}" STREQUAL "${pkgs_info}"))
            file(WRITE "${pkgs_info_file}" "${pkgs_tmp}")
        endif()
    endif()
    add_custom_command(
        OUTPUT "${python3_tmp}/pkgs_installed"
        COMMAND "${CMAKE_COMMAND}" -P "${python3_patch_install_pkgs_script}"
        COMMAND "${CMAKE_COMMAND}" -E touch "${python3_tmp}/pkgs_installed"
        WORKING_DIRECTORY "${python3_source}"
        DEPENDS "${pkgs_info_file}" "${pip_config_file}"
        USES_TERMINAL
        COMMENT "Install Python pkgs ..."
    )
    # set target
    add_custom_target(
        "${target_name}"
        WORKING_DIRECTORY "${python3_source}"
        DEPENDS "${python3_tmp}/pkgs_installed"
        COMMENT "Build '${python3_name}' In '${python3_source}'."
    )
    # add deps
    if(NOT ("${python3_deps}" STREQUAL ""))
        add_dependencies("${target_name}" ${python3_deps})
    endif()
    # set python path
    set("${python3_name}-path" "${python3_source}" PARENT_SCOPE)
endfunction()

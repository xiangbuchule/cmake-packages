# imgui project patch script
# script:   script file save path
# sources:  source files/dirs path
function(imgui_patch_script)
    # params
    cmake_parse_arguments(imgui "" "script;target;config_key;config_file;config_target_file" "sources" ${ARGN})
    # set content
    set(script_content "\
set(target              \"${imgui_target}\")
set(sources             \"${imgui_sources};${imgui_UNPARSED_ARGUMENTS}\")
set(config_key          \"${imgui_config_key}\")
set(config_file         \"${imgui_config_file}\")
set(config_target_file  \"${imgui_config_target_file}\")
")
    string(APPEND script_content [[
# read file to 16 hex string
function(read_file_hex)
    # params
    cmake_parse_arguments(read "" "file;result" "" ${ARGN})
    # read file to 16 hex string
    file(READ "${read_file}" tmp HEX)
    # let string to 16 hex list
    string(REGEX REPLACE "(..)" "'\\\\x\\1';" tmp "${tmp}")
    # remove last ;
    string(REGEX REPLACE ";$" "" tmp "${tmp}")
    # get length
    list(LENGTH tmp len)
    # list to string
    list(JOIN tmp ", " tmp)
    # return
    set("${read_result}"        "${tmp}" PARENT_SCOPE)
    set("${read_result}_len"    "${len}" PARENT_SCOPE)
endfunction()
# 压缩资源文件
set(is_diff OFF)
if(NOT EXISTS "${target}" OR IS_DIRECTORY "${target}")
    set(is_diff ON)
    message("start compress assets files ...")
    file(ARCHIVE_CREATE OUTPUT "${target}" PATHS ${sources} FORMAT zip)
endif()
# 设置 资源文件
if(is_diff)
    message("start config assets files ...")
    read_file_hex(file "${target}" result "${config_key}")
    configure_file("${config_file}" "${config_target_file}")
endif()
]])
    if(NOT EXISTS "${imgui_script}" OR IS_DIRECTORY "${imgui_script}")
        file(WRITE "${imgui_script}" "${script_content}")
    endif()
endfunction()
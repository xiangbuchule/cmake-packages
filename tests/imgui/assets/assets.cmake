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

# config 资源文件
set(assets_path     "${CMAKE_CURRENT_SOURCE_DIR}/assets")
set(icons_path      "${assets_path}/icons")
set(shaders_path    "${assets_path}/shaders")
# 设置 shader
read_file_hex(file "${shaders_path}/main.frag"  result "main_frag")
read_file_hex(file "${shaders_path}/main.vert"  result "main_vert")
# 设置 icon
read_file_hex(file "${icons_path}/16x16_icon.png"       result "16x16_icon")
read_file_hex(file "${icons_path}/32x32_icon.png"       result "32x32_icon")
read_file_hex(file "${icons_path}/48x48_icon.png"       result "48x48_icon")
read_file_hex(file "${icons_path}/64x64_icon.png"       result "64x64_icon")
read_file_hex(file "${icons_path}/128x128_icon.png"     result "128x128_icon")
read_file_hex(file "${icons_path}/256x256_icon.png"     result "256x256_icon")
# 创建文件
set(config_file_source_path "${CMAKE_CURRENT_LIST_DIR}/rc/rc.hpp.in")
set(config_file_target_path "${extra_source_path}/rc.hpp")
configure_file("${config_file_source_path}" "${config_file_target_path}" @ONLY)
set(config_file_source_path "${CMAKE_CURRENT_LIST_DIR}/rc/shaders.cpp.in")
set(config_file_target_path "${extra_source_path}/shaders.cpp")
configure_file("${config_file_source_path}" "${config_file_target_path}" @ONLY)
set(config_file_source_path "${CMAKE_CURRENT_LIST_DIR}/rc/icons.cpp.in")
set(config_file_target_path "${extra_source_path}/icons.cpp")
configure_file("${config_file_source_path}" "${config_file_target_path}" @ONLY)
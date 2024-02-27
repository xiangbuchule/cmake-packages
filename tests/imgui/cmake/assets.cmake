# imgui project patch script
# script:               script file save path
# sources:              source files/dirs path
# config_key:           config key name @var@ var
# config_files:         config file list
# config_target_files:  config target save file list
function(imgui_patch_script)
    # params
    cmake_parse_arguments(imgui "" "script;target;config_key;" "config_files;config_target_files;sources" ${ARGN})
    # set content
    set(script_content "\
set(target              \"${imgui_target}\")
set(sources             \"${imgui_sources};${imgui_UNPARSED_ARGUMENTS}\")
set(config_key          \"${imgui_config_key}\")
set(config_files        \"${imgui_config_files}\")
set(config_target_files \"${imgui_config_target_files}\")
string(REGEX REPLACE    \"(^;)|(;$)\" \"\" sources \"\${sources}\")
")
    string(APPEND script_content [[
# diff zip file content with source files
# file:     zip file path
# sources:  compress files(not dirs)
function(diff_zip)
    # params
    cmake_parse_arguments(diff "" "file" "sources" ${ARGN})
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E tar -tvf "${diff_file}"
        OUTPUT_VARIABLE tmp
    )
    # 去掉多余空格与换行符
    string(STRIP "${tmp}" tmp)
    # 转list
    string(REPLACE "\n" ";" lists "${tmp}")
    # 获取文件名、时间、大小
    foreach(item IN LISTS lists)
        # 将多余空格替换为1个空格
        string(REGEX REPLACE " +" " " item "${item}")
        # 转list
        string(REPLACE " " ";" item "${item}")
        # 获取文件名
        list(GET item 8 file_name)
        # 判断是否是文件
        string(LENGTH "${file_name}" string_length)
        math(EXPR last_index "${string_length} - 1")
        string(SUBSTRING "${file_name}" ${last_index} 1 last_character)
        if(NOT ("/" STREQUAL "${last_character}"))
            # 记录文件名
            list(APPEND file_name_list "${file_name}")
            # 记录文件时间
            list(GET item 5 6 7 file_time)
            list(JOIN file_time " " file_time)
            list(APPEND file_time_list "${file_time}")
            # 记录文件大小
            list(GET item 4 file_size)
            list(APPEND file_size_list "${file_size}")
        endif()
    endforeach()
    # 判断文件是否和压缩包中的文件存在差异
    foreach(item IN LISTS diff_sources)
        if(NOT EXISTS "${item}" AND IS_DIRECTORY "${item}")
            message(FATAL_ERROR "File '${item}' Can't Be Directory And Exists !!!")
        endif()
        # 查找zip是否包含文件
        list(FIND file_name_list "${item}" index)
        if(${index} GREATER_EQUAL 0)
            # 比较文件大小
            file(SIZE "${item}" file_source_size)
            list(GET file_size_list ${index} file_target_size)
            if("${file_source_size}" STREQUAL "${file_target_size}")
                # 比较文件时间
                list(GET file_time_list ${index} file_target_time)
                string(REPLACE " " ";" file_target_time_list "${file_target_time}")
                list(GET file_target_time_list 2 time_or_year)
                string(FIND "${time_or_year}" ":" time_index)
                if(${time_index} GREATER_EQUAL 0)
                    file(TIMESTAMP "${item}" file_source_time "%d %b %H:%M")
                else()
                    file(TIMESTAMP "${item}" file_source_time "%d %b %Y")
                endif()
                if(NOT ("${file_source_time}" STREQUAL "${file_target_time}"))
                    set(is_diff ON PARENT_SCOPE)
                    break()
                endif()
            else()
                set(is_diff ON PARENT_SCOPE)
                break()
            endif()
        else()
            set(is_diff ON PARENT_SCOPE)
            break()
        endif()
    endforeach()
endfunction()

# read file to 16 hex string
# file:     file path
# result:   return name
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
if(NOT EXISTS "${target}" OR IS_DIRECTORY "${target}")
    set(is_diff ON)
else()
    diff_zip(file "${target}" sources ${sources})
endif()
# 设置 资源文件
if(is_diff)
    message("start compress assets files ...")
    file(ARCHIVE_CREATE OUTPUT "${target}" PATHS ${sources} FORMAT zip)
    message("start config assets files ...")
    read_file_hex(file "${target}" result "${config_key}")
    list(LENGTH config_files list_length)
    math(EXPR list_length_index "${list_length} - 1")
    foreach(index RANGE ${list_length_index})
        list(GET config_files           ${index} current_config_file)
        list(GET config_target_files    ${index} current_config_target_file)
        configure_file("${current_config_file}" "${current_config_target_file}")
    endforeach()
endif()
]])
    file(WRITE "${imgui_script}" "${script_content}")
endfunction()
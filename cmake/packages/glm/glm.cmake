include(ExternalProject)

# 补丁脚本
set(glm_patch_powershell "\
Param(\n\
    [Parameter(Mandatory = $True, HelpMessage = 'File Path')][Alias('f')]\n\
    [String] $File\n\
)\n\
$File = $(Resolve-Path -Path $File)\n\
if(Test-Path -Path $File) {\n\
    [String[]] $content = $(Get-Content -Path $File)\n\
    [System.Collections.Generic.List[String]] $list = [System.Collections.Generic.List[String]]::New()\n\
    for($i=0; $i -lt $content.count; $i++) {\n\
        if($content[$i] -eq 'enable_testing()') {\n\
            $list.Add('option(BUILD_TESTS \"Butild Tests\" OFF)')\n\
            continue\n\
        }\n\
        if($content[$i].Contains('\${CMAKE_SOURCE_DIR} STREQUAL \${CMAKE_CURRENT_SOURCE_DIR}')) {\n\
            $list.Add($content[$i].Replace('\${CMAKE_SOURCE_DIR} STREQUAL \${CMAKE_CURRENT_SOURCE_DIR}', '(\${CMAKE_SOURCE_DIR} STREQUAL \${CMAKE_CURRENT_SOURCE_DIR}) AND \${BUILD_TESTS}'))\n\
            continue\n\
        }\n\
        if($content[$i] -eq 'add_subdirectory(test)') {\n\
            $list.Add('    enable_testing()')\n\
            $list.Add('    add_subdirectory(test)')\n\
            continue\n\
        }\n\
        $list.Add($content[$i])\n\
    }\n\
    Set-Content -Path $File -Value $list\n\
} else {\n\
    Write-Error \"File $File Not Exist !!!\"\n\
}\n\
")
set(glm_patch_bash "\
#!/usr/bin/env bash\n\
file_path=''
printHelp() {\n\
cat << EOF\n\
usage: $0 [-h --help] [-f --file].\n\
-h,--help   print help.\n\
-f,--file   File Path.\n\
EOF\n\
}\n\
getCommandParams() {\n\
    local command_params=$(getopt -a -o hf: -l help,file: -n $(basename \"$0\") -- \"$@\")\n\
    if [ $? != 0 ]; then printf \"Get Command Params Error !!!\\n\";exit 1;fi\n\
    eval set -- \"$command_params\"\n\
    while true;do\n\
        case \"$1\" in\n\
            -h|--help) printHelp; exit 0;;\n\
            -f|--file) file_path=$(echo $2 | sed -e 's/^[ ]*//g' | sed -e 's/[ ]*$//g'); shift 2;;\n\
            \"--\") shift; break;;\n\
            *) printf \"Params Error !!!\\n\";printHelp;exit 1;;\n\
        esac\n\
    done\n\
}\n\
getCommandParams \"$@\"\n\
if [[ '' == \"$file_path\" ]];then printf \"file '$file_path' error !!!\\n\";exit 1;fi\n\
if [ ! -f \"$file_path\" ];then printf \"file '$file_path' not exist !!!\\n\";exit 1;fi\n\
sed -i 's/enable_testing()/option(BUILD_TESTS \"Butild Tests\" OFF)/g' \"$file_path\"\n\
sed -i 's/\${CMAKE_SOURCE_DIR} STREQUAL \${CMAKE_CURRENT_SOURCE_DIR}/(\${CMAKE_SOURCE_DIR} STREQUAL \${CMAKE_CURRENT_SOURCE_DIR}) AND \${BUILD_TESTS}/g' \"$file_path\"\n\
sed -i '/add_subdirectory(test)/i\\    enable_testing()' \"$file_path\"\n\
sed -i 's/add_subdirectory(test)/    add_subdirectory(test)/g' \"$file_path\"\n\
")

# 参数
# header_only 表示只头文件
#   由于glm是仅头文件的库,所以构建不传递该参数
#   来构建共享库或静态库是无意义的
# shared 表示构建共享库而非静态库
# build_tests 表示构建测试
# git_shallow 表示使用git clone时添加--depth 1
#   如果设置该参数version就不能设置为git的hash提交
#   需要设置为分支或者tag名
# name: glm 目标名
# prefix: /path/dir 目录前缀
# version: 0.9.9.8 指定版本
function(add_glm)
    # 获取参数
    set(glm_options             "header_only" "shared" "build_tests" "git_shallow")
    set(glm_params              "name" "prefix" "version")
    set(glm_multi_params        "depends" "cmake_args")
    cmake_parse_arguments(glm   "${glm_options}" "${glm_params}" "${glm_multi_params}" ${ARGN})
    # 提示参数值
    message(STATUS "Build ${glm_name}...")
    foreach(item ${glm_options})
        message(STATUS "Option '${item}': ${glm_${item}}")
    endforeach()
    foreach(item ${glm_params})
        message(STATUS "Params '${item}': ${glm_${item}}")
    endforeach()
    foreach(item ${glm_multi_params})
        message(STATUS "Multi Params '${item}': ${glm_${item}}")
    endforeach()
    foreach(item ${glm_UNPARSED_ARGUMENTS})
        message(WARNING "No Used Params '${item}'")
    endforeach()
    # 如果已经存在就直接退出
    if((TARGET "${glm_name}") OR (DEFINED "${glm_name}_includes"))
        return()
    endif()
    # 仓库地址
    set(repository_url "https://github.com/g-truc/glm")
    # 记录版本及其校验值
    list(APPEND glm_url_list        "https://github.com/g-truc/glm/releases/download/0.9.9.8/glm-0.9.9.8.zip")
    list(APPEND glm_file_list       "glm-0.9.9.8.zip")
    list(APPEND glm_hash_list       "37E2A3D62EA3322E43593C34BAE29F57E3E251EA89F4067506C94043769ADE4C")
    list(APPEND glm_version_list    "0.9.9.8")
    # 查找是否存在列出的版本
    string(STRIP "${glm_version}" glm_version)
    if("${glm_version}" STREQUAL "")
        set(glm_version_index 0)
    else()
        list(FIND glm_version_list "${glm_version}" glm_version_index)
    endif()
    if(glm_version_index GREATER_EQUAL 0)
        list(GET glm_url_list   ${glm_version_index} glm_url)
        list(GET glm_file_list  ${glm_version_index} glm_file)
        list(GET glm_hash_list  ${glm_version_index} glm_hash)
    endif()
    # 设置文件路径
    # set(glm_tmp         "${CMAKE_CURRENT_BINARY_DIR}/ThirdCache/tmp/glm")
    set(glm_download    "${glm_prefix}/cache/download")
    set(glm_install     "${glm_prefix}/cache/install/${glm_name}")
    set(glm_source      "${glm_prefix}/${glm_name}")
    if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
        set(glm_binary  "${glm_prefix}/cache/bin/${glm_name}")
    else()
        set(glm_binary  "${glm_prefix}/cache/bin/${glm_name}/${CMAKE_BUILD_TYPE}")
    endif()
    # set(glm_stamp       "${CMAKE_CURRENT_BINARY_DIR}/ThirdCache/log/glm")
    # set(glm_log         "${CMAKE_CURRENT_BINARY_DIR}/ThirdCache/log/glm")
    # 构建参数
    set(glm_build_shared OFF)
    set(glm_build_static OFF)
    if(glm_shared)
        set(glm_build_shared ON)
    else()
        set(glm_build_static ON)
    endif()
    if(${glm_version_index} GREATER_EQUAL 0)
        set(glm_url_options URL "${glm_url}" URL_HASH SHA256=${glm_hash} DOWNLOAD_NAME "${glm_file}")
    else()
        set(glm_url_options GIT_REPOSITORY "${repository_url}" GIT_TAG "${glm_version}"
                            GIT_SHALLOW ${glm_git_shallow} GIT_PROGRESS ON)
    endif()
    set(glm_build_options   "-DBUILD_TESTS=${glm_build_tests}" "-DBUILD_SHARED_LIBS=${glm_build_shared}"
                            "-DBUILD_STATIC_LIBS=${glm_build_static}"

                            "-DEXECUTABLE_OUTPUT_PATH='${glm_binary}'" "-DLIBRARY_OUTPUT_PATH='${glm_binary}'"

                            "-DCMAKE_INSTALL_LIBDIR='${glm_install}/lib'" "-DCMAKE_INSTALL_BINDIR='${glm_install}/bin'"
                            "-DCMAKE_INSTALL_INCLUDEDIR='${glm_install}/include'")
    foreach(item ${glm_cmake_args})
        list(APPEND glm_build_options "${item}")
    endforeach()
    set(glm_terminal_options    USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    set(glm_steps update patch build)
    # 设置补丁脚本
    set(glm_patch_path "${glm_prefix}/cache/patch/${glm_name}")
    file(MAKE_DIRECTORY "${glm_patch_path}")
    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        set(glm_patch_powershell_file "${glm_patch_path}/patch.ps1")
        file(WRITE "${glm_patch_powershell_file}" "${glm_patch_powershell}")
        set(patch_shell     "PowerShell")
        set(patch_option    "-c")
        set(patch_cmd       "& '${glm_patch_powershell_file}' -f '${glm_source}/CMakeLists.txt'")
    else()
        set(glm_patch_bash_file "${glm_patch_path}/patch.sh")
        file(WRITE "${glm_patch_bash_file}" "${glm_patch_bash}")
        set(patch_shell     "bash")
        set(patch_option    "-c")
        set(patch_cmd       "chmod +x '${glm_patch_bash_file}' && '${glm_patch_bash_file}' -f '${glm_source}/CMakeLists.txt'")
    endif()
    set(glm_patchs COMMAND ${CMAKE_COMMAND} -E chdir "${glm_source}" ${patch_shell} ${patch_option} "${patch_cmd}")
    # 开始构建
    ExternalProject_Add("thrid-${glm_name}" DOWNLOAD_DIR "${glm_download}" SOURCE_DIR "${glm_source}"
                                            ${glm_url_options} CMAKE_ARGS ${glm_build_options}
                                            PATCH_COMMAND ${glm_patchs} INSTALL_COMMAND ""
                                            ${glm_terminal_options} STEP_TARGETS ${glm_steps})
    # 设置include
    set("${glm_name}_includes" "${glm_source}" PARENT_SCOPE)
    # 设置生成lib目标
    if(glm_header_only)
        add_library("${glm_name}" INTERFACE)
        target_include_directories("${glm_name}" INTERFACE "${glm_source}")
        add_dependencies("${glm_name}" "thrid-${glm_name}-update" ${glm_depends})
    else()
        if(glm_shared)
            add_library("${glm_name}" SHARED IMPORTED GLOBAL)
            set(lib_suffix "shared")
        else()
            add_library("${glm_name}" STATIC IMPORTED GLOBAL)
            set(lib_suffix "static")
        endif()
        add_dependencies("${glm_name}" "thrid-${glm_name}-build" ${glm_depends})
        if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
            set(lib_path "${glm_binary}/${CMAKE_BUILD_TYPE}")
            set(bin_path "${glm_binary}/${CMAKE_BUILD_TYPE}")
        else()
            set(lib_path "${glm_binary}")
            set(bin_path "${glm_binary}")
        endif()
        if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
            if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
                set(lib_name "glm_${lib_suffix}.lib")
                set(bin_name "glm_${lib_suffix}.dll")
            endif()
            if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
                set(lib_name "libglm_${lib_suffix}.dll.a")
                set(bin_name "libglm_${lib_suffix}.dll")
            endif()
            if(CMAKE_C_COMPILER_ID STREQUAL "Clang")
                message(FATAL_ERROR "TODO Setting ...")
            endif()
        else()
            message(FATAL_ERROR "TODO Setting ...")
        endif()
        set_target_properties("${glm_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${lib_name}")
        if(glm_shared)
            set_target_properties("${glm_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${bin_name}")
        endif()
    endif()
endfunction()
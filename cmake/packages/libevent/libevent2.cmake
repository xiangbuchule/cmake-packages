include(ExternalProject)

# 检查参数的宏
# name: 变量名
# default_value: 默认的值
# value_list: 值可能的列表
#   如果同时指定了默认值和值可能的列表
#   那么如果值不在列表中,就使用默认值.
#   如果仅指定了值可能的列表,那么如果
#   值不在列表中,就使用列表中第一个值.
macro(libevent2_check_params)
    cmake_parse_arguments(check "" "name;default_value" "value_list" ${ARGN})
    if("${check_value_list}" STREQUAL "")
        if("${${check_name}}" STREQUAL "")
            set("${check_name}" "${check_default_value}")
        endif()
    else()
        if(NOT ("${${check_name}}" STREQUAL "${check_default_value}"))
            list(FIND check_value_list "${${check_name}}" check_value_list_index)
            if(${check_value_list_index} LESS 0)
                if(NOT ("${check_default_value}" STREQUAL ""))
                    set("${check_name}" "${check_default_value}")
                else()
                    list(GET check_value_list 0 "${check_name}")
                endif()
            endif()
        endif()
    endif()
endmacro()


# 参数
# shared 表示构建共享库而非静态库
# git_shallow 表示使用git clone时添加--depth 1
#   如果设置该参数version就不能设置为git的hash提交
#   需要设置为分支或者tag名
# name: glm 目标名
# prefix: /path/dir 目录前缀
# version: 2.1.12 指定版本
# library_type: STATIC|SHARED|BOTH
function(add_libevent2)
    # 获取参数
    set(libevent_options        "disable_debug_mode" "enable_verbose_debug" "disable_mm_replacement" "disable_thread_support"
                                "disable_benchmark" "disable_tests" "disable_regress" "disable_samples" "disable_clock_gettime"
                                "force_kqueue_check" "disable_openssl" "coverage" "doxygen"

                                "disable_gcc_warnings" "enable_gcc_hardening" "enable_gcc_function_sections" "enable_gcc_warnings"

                                "git_shallow")
    set(libevent_params         "name" "prefix" "version" "library_type" "build_type")
    set(libevent_multi_params   "depends" "cmake_args")
    cmake_parse_arguments(libevent "${libevent_options}" "${libevent_params}" "${libevent_multi_params}" ${ARGN})
    message(STATUS "Build ${libevent_name}...")
    foreach(item ${libevent_options})
        message(STATUS "Option '${item}': ${libevent_${item}}")
    endforeach()
    foreach(item ${libevent_params})
        message(STATUS "Params '${item}': ${libevent_${item}}")
    endforeach()
    foreach(item ${libevent_multi_params})
        message(STATUS "Multi Params '${item}': ${libevent_${item}}")
    endforeach()
    foreach(item ${libevent_UNPARSED_ARGUMENTS})
        message(WARNING "No Used Params '${item}'")
    endforeach()
    # 如果已经存在就直接退出
    if((TARGET "${libevent_name}_core") OR (TARGET "${libevent_name}_core"))
        return()
    endif()
    # 检查参数
    string(STRIP "${libevent_library_type}" libevent_library_type)
    libevent2_check_params(name "libevent_library_type" default_value "SHARED" value_list "SHARED" "STATIC")
    string(STRIP "${libevent_build_type}" libevent_build_type)
    libevent2_check_params(name "libevent_build_type" default_value "${CMAKE_BUILD_TYPE}" value_list "Debug" "Release")
    # 仓库地址
    set(repository_url "https://github.com/libevent/libevent")
    # 记录版本及其校验值
    list(APPEND libevent_url_list       "https://github.com/libevent/libevent/archive/refs/tags/release-2.1.12-stable.zip")
    list(APPEND libevent_file_list      "libevent-release-2.1.12-stable.zip")
    list(APPEND libevent_hash_list      "8836AD722AB211DE41CB82FE098911986604F6286F67D10DFB2B6787BF418F49")
    list(APPEND libevent_version_list   "2.1.12")
    # 查找是否存在列出的版本
    string(STRIP "${libevent_version}" libevent_version)
    if("${libevent_version}" STREQUAL "")
        set(libevent_version_index 0)
    else()
        list(FIND libevent_version_list "${libevent_version}" libevent_version_index)
    endif()
    if(libevent_version_index GREATER_EQUAL 0)
        list(GET libevent_url_list  ${libevent_version_index} libevent_url)
        list(GET libevent_file_list ${libevent_version_index} libevent_file)
        list(GET libevent_hash_list ${libevent_version_index} libevent_hash)
    endif()
    # 设置文件路径
    # set(libevent_tmp      "${CMAKE_CURRENT_BINARY_DIR}/ThirdCache/tmp/libevent")
    set(libevent_download   "${libevent_prefix}/cache/download")
    set(libevent_install    "${libevent_prefix}/cache/install/${libevent_name}")
    set(libevent_source     "${libevent_prefix}/${libevent_name}")
    if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
        set(libevent_binary "${libevent_prefix}/cache/bin/${libevent_name}")
    else()
        set(libevent_binary "${libevent_prefix}/cache/bin/${libevent_name}/${CMAKE_BUILD_TYPE}")
    endif()
    # set(libevent_stamp      "${CMAKE_CURRENT_BINARY_DIR}/ThirdCache/log/libevent")
    # set(libevent_log        "${CMAKE_CURRENT_BINARY_DIR}/ThirdCache/log/libevent")
    # 构建参数
    if(${libevent_version_index} GREATER_EQUAL 0)
        set(libevent_url_options URL "${libevent_url}" URL_HASH SHA256=${libevent_hash} DOWNLOAD_NAME "${libevent_file}")
    else()
        set(libevent_url_options    GIT_REPOSITORY "${repository_url}" GIT_TAG "${libevent_version}"
                                    GIT_SHALLOW ${libevent_gitshallow} GIT_PROGRESS ON)
    endif()
    set(libevent_build_options  "-DEVENT__LIBRARY_TYPE='${libevent_library_type}'"
                                "-DEVENT__DISABLE_DEBUG_MODE=${libevent_disable_debug_mode}"
                                "-DEVENT__ENABLE_VERBOSE_DEBUG=${libevent_enable_verbose_debug}"
                                "-DEVENT__DISABLE_MM_REPLACEMENT=${libevent_disable_mm_replacement}"
                                "-DEVENT__DISABLE_THREAD_SUPPORT=${libevent_disable_thread_support}"
                                "-DEVENT__DISABLE_BENCHMARK=${libevent_disable_benchmark}"
                                "-DEVENT__DISABLE_TESTS=${libevent_disable_tests}"
                                "-DEVENT__DISABLE_REGRESS=${libevent_disable_regress}"
                                "-DEVENT__DISABLE_SAMPLES=${libevent_disable_samples}"
                                "-DEVENT__DISABLE_CLOCK_GETTIME=${disable_clock_gettime}"
                                "-DEVENT__FORCE_KQUEUE_CHECK=${libevent_force_kqueue_check}"
                                "-DEVENT__DISABLE_OPENSSL=${libevent_disable_openssl}"
                                "-DEVENT__COVERAGE=${libevent_coverage}" "-DEVENT__DOXYGEN=${libevent_doxygen}"

                                "-DEVENT__DISABLE_GCC_WARNINGS=${libevent_disable_gcc_warnings}"
                                "-DEVENT__ENABLE_GCC_HARDENING=${libevent_enable_gcc_hardening}"
                                "-DEVENT__ENABLE_GCC_FUNCTION_SECTIONS=${libevent_enable_gcc_function_sections}"
                                "-DEVENT__ENABLE_GCC_WARNINGS=${libevent_enable_gcc_warnings}"

                                "-DCMAKE_BUILD_TYPE='${libevent_build_type}'" "-DCMAKE_DEBUG_POSTFIX=''"
                                # "-DEXECUTABLE_OUTPUT_PATH='${libevent_binary}'"
                                # "-DLIBRARY_OUTPUT_PATH='${libevent_binary}'"
                                "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${libevent_binary}'"
                                "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${libevent_binary}'"
                                "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${libevent_binary}'"
                                "-DCMAKE_INSTALL_PREFIX='${libevent_install}'")
    foreach(item ${libevent_cmake_args})
        list(APPEND libevent_build_options "${item}")
    endforeach()
    set(libevent_terminal_options   USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                    USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    set(libevent_steps install)
    # 开始构建
    ExternalProject_Add("thrid-${libevent_name}"    DOWNLOAD_DIR "${libevent_download}" SOURCE_DIR "${libevent_source}"
                                                    ${libevent_url_options} CMAKE_ARGS ${libevent_build_options}
                                                    ${libevent_terminal_options} STEP_TARGETS ${libevent_steps})
    # 设置include
    set("${libevent_name}_includes" "${libevent_install}/include" PARENT_SCOPE)
    # 设置文件
    if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
            set(lib_path "${libevent_binary}/${CMAKE_BUILD_TYPE}")
        else()
            set(lib_path "${libevent_binary}")
        endif()
    else()
        set(lib_path "${libevent_install}/lib")
    endif()
    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
            set(lib_suffix "lib")
            set(bin_suffix "dll")
        endif()
        if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(lib_prefix "lib")
            set(lib_suffix "dll.a")
            set(bin_suffix "dll")
        endif()
        if(CMAKE_C_COMPILER_ID STREQUAL "Clang")
            message(FATAL_ERROR "TODO Setting ...")
        endif()
    else()
        message(FATAL_ERROR "TODO Setting ...")
    endif()
    set(event_lib_file          "${lib_path}/${lib_prefix}event.${lib_suffix}")
    set(event_core_lib_file     "${lib_path}/${lib_prefix}event_core.${lib_suffix}")
    set(event_extra_lib_file    "${lib_path}/${lib_prefix}event_extra.${lib_suffix}")
    set(event_openssl_lib_file  "${lib_path}/${lib_prefix}event_openssl.${lib_suffix}")
    set(event_pthreads_lib_file "${lib_path}/${lib_prefix}event_pthreads.${lib_suffix}")
    set(event_bin_file          "${lib_path}/${lib_prefix}event.${bin_suffix}")
    set(event_core_bin_file     "${lib_path}/${lib_prefix}event_core.${bin_suffix}")
    set(event_extra_bin_file    "${lib_path}/${lib_prefix}event_extra.${bin_suffix}")
    set(event_openssl_bin_file  "${lib_path}/${lib_prefix}event_openssl.${bin_suffix}")
    set(event_pthreads_bin_file "${lib_path}/${lib_prefix}event_pthreads.${bin_suffix}")
    # 设置目标
    add_library("${libevent_name}"                  "${libevent_library_type}" IMPORTED GLOBAL)
    add_library("${libevent_name}_core"             "${libevent_library_type}" IMPORTED GLOBAL)
    add_library("${libevent_name}_extra"            "${libevent_library_type}" IMPORTED GLOBAL)
    add_dependencies("${libevent_name}"             "thrid-${libevent_name}-install" ${libevent_depends})
    add_dependencies("${libevent_name}_core"        "thrid-${libevent_name}-install" ${libevent_depends})
    add_dependencies("${libevent_name}_extra"       "${libevent_name}_core")
    set_target_properties("${libevent_name}"        PROPERTIES IMPORTED_IMPLIB "${event_lib_file}")
    set_target_properties("${libevent_name}_core"   PROPERTIES IMPORTED_IMPLIB "${event_core_lib_file}")
    set_target_properties("${libevent_name}_extra"  PROPERTIES IMPORTED_IMPLIB "${event_extra_lib_file}")
    if(NOT ${libevent_disable_openssl})
        add_library("${libevent_name}_openssl"              "${libevent_library_type}" IMPORTED GLOBAL)
        add_dependencies("${libevent_name}_openssl"         "${libevent_name}_core")
        set_target_properties("${libevent_name}_openssl"    PROPERTIES IMPORTED_IMPLIB "${event_openssl_lib_file}")
    endif()
    if((NOT ${libevent_disable_thread_support}) AND (NOT WIN32))
        add_library("${libevent_name}_pthreads"             "${libevent_library_type}" IMPORTED GLOBAL)
        add_dependencies("${libevent_name}_pthreads"        "${libevent_name}_core")
        set_target_properties("${libevent_name}_pthreads"   PROPERTIES IMPORTED_IMPLIB "${event_pthreads_lib_file}")
    endif()
    if("${libevent_library_type}" STREQUAL "SHARED")
        set_target_properties("${libevent_name}"        PROPERTIES IMPORTED_LOCATION "${event_bin_file}")
        set_target_properties("${libevent_name}_core"   PROPERTIES IMPORTED_LOCATION "${event_core_bin_file}")
        set_target_properties("${libevent_name}_extra"  PROPERTIES IMPORTED_LOCATION "${event_extra_bin_file}")
        if(NOT ${libevent_disable_openssl})
            set_target_properties("${libevent_name}_openssl" PROPERTIES IMPORTED_LOCATION "${event_openssl_bin_file}")
        endif()
        if((NOT ${libevent_disable_thread_support}) AND (NOT WIN32))
            set_target_properties("${libevent_name}_pthreads" PROPERTIES IMPORTED_LOCATION "${event_pthreads_bin_file}")
        endif()
    endif()
endfunction()
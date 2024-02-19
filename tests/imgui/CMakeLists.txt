# cmake需要的最低版本
cmake_minimum_required (VERSION 3.12)
# 主项目名
project(test_imgui)

# not link console
if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -mwindows")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mwindows")
endif()

# set includes
set(include_paths "${CMAKE_CURRENT_SOURCE_DIR}/include")
# set extra source path
set(extra_source_path "${CMAKE_CURRENT_BINARY_DIR}/extra")

# config assets
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/assets.cmake")
imgui_patch_script(
    script              "${CMAKE_CURRENT_BINARY_DIR}/patch.cmake"
    target              "${CMAKE_CURRENT_BINARY_DIR}/rc.zip"
    config_key          "rc_data"
    config_file         "${include_paths}/rc.h.in"
    config_target_file  "${extra_source_path}/rc.h"
    sources             "icons" "shaders"
                        "fonts/Nerd-Font-Hack/HackNerdFont-Regular.ttf"
                        "fonts/Source-Han-Serif/SimplifiedChinese-VF.ttf"
)

# config file
configure_file("${include_paths}/config.h.in" "${extra_source_path}/config.h" @ONLY)

# 查找源文件
list(APPEND source_file "${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp")

# 构建目标
add_executable(${PROJECT_NAME} ${source_file})
# 目标依赖项
add_custom_target(
    ${PROJECT_NAME}-rc
    COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/patch.cmake"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/assets"
    USES_TERMINAL
)
add_dependencies(
    ${PROJECT_NAME} ${PROJECT_NAME}-rc
                    libzip-1.10.1 glad2-2.0.4 glfw3-3.3.9 stb-master
                    freetype2-2.13.2 imgui-1.90.3-docking
                    bzip2-master
)
# 目标include
target_include_directories(
    ${PROJECT_NAME} PRIVATE
    "${include_paths}"
    "${extra_source_path}"
)
target_include_directories(
    ${PROJECT_NAME} PRIVATE
    "${glad2-2.0.4-includes}"
    "${glfw3-3.3.9-includes}"
    "${freetype2-2.13.2-includes}"
    "${libzip-1.10.1-includes}"
)
# 声明一下imgui-1.90.3-docking中的源文件是被生成的
# 防止generate阶段报错找不到源文件
add_custom_command(
    OUTPUT ${imgui-1.90.3-docking-sources}
    COMMAND echo imgui source files will be created
    USES_TERMINAL ON
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    # COMMAND "${CMAKE_COMMAND}" -E touch ${imgui-1.90.3-docking-sources}
)
# 目标链接项
target_link_libraries(
    ${PROJECT_NAME} libzip-1.10.1 glad2-2.0.4 glfw3-3.3.9 stb-master
                    freetype2-2.13.2 imgui-1.90.3-docking
)
if(MSVC)
    # set(new_link_flags "/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup")
    # get_target_property(old_link_flags ${PROJECT_NAME} LINK_FLAGS)
    # if(NOT "${old_link_flags}" STREQUAL "old_link_flags-NOTFOUND")
    #     set(new_link_flags "${old_link_flags} ${new_link_flags}")
    # endif()
    # set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "${new_link_flags}")
endif()
# 构建后复制文件
if(WIN32)
    set(bzip2_bin bz2-1.dll)
else()
    set(bzip2_bin bz2-1.so)
endif()
add_custom_command(
    TARGET ${PROJECT_NAME}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:zlib-1.3.1>"        "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:bzip2-master>"      "$<TARGET_FILE_DIR:${PROJECT_NAME}>/${bzip2_bin}"
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:libzip-1.10.1>"     "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:freetype2-2.13.2>"  "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:glad2-2.0.4>"       "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:glfw3-3.3.9>"       "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
)
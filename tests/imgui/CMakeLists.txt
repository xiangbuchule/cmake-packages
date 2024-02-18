# cmake需要的最低版本
cmake_minimum_required (VERSION 3.12)
# 主项目名
project(test_imgui)

if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -mwindows")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mwindows")
endif()

# set extra source path
set(extra_source_path "${CMAKE_CURRENT_BINARY_DIR}/extra")

# set assets
include("${CMAKE_CURRENT_SOURCE_DIR}/assets/assets.cmake")

# config file
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/include/config.h.in" "${extra_source_path}/config.h" @ONLY)

# 查找源文件
list(APPEND source_file         "${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp")
list(APPEND extra_source_file   "${extra_source_path}/icons.c"
                                "${extra_source_path}/shaders.c")

# 构建目标
add_executable(${PROJECT_NAME} ${source_file} ${extra_source_file})
# 目标依赖项
add_dependencies(${PROJECT_NAME} glad2-2.0.4 glfw3-3.3.9 stb-master freetype2-2.13.2 imgui-1.90.3-docking)
# 目标include
target_include_directories(
    ${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    "${extra_source_path}"
    "${glad2-2.0.4-includes}"
    "${glfw3-3.3.9-includes}"
    "${freetype2-2.13.2-includes}"
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
target_link_libraries(${PROJECT_NAME} glad2-2.0.4 glfw3-3.3.9 stb-master freetype2-2.13.2 imgui-1.90.3-docking)
if(MSVC)
    set(new_link_flags "/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup")
    get_target_property(old_link_flags ${PROJECT_NAME} LINK_FLAGS)
    if(NOT "${old_link_flags}" STREQUAL "old_link_flags-NOTFOUND")
        set(new_link_flags "${old_link_flags} ${new_link_flags}")
    endif()
    set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "${new_link_flags}")
endif()
# 构建后复制文件
add_custom_command(
    TARGET ${PROJECT_NAME}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:glad2-2.0.4>"       "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:glfw3-3.3.9>"       "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:freetype2-2.13.2>"  "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
)
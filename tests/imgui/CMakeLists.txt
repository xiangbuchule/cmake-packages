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

# 查找源文件
list(APPEND source_file "${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp")
list(APPEND extra_source_file   "${extra_source_path}/icons.cpp"
                                "${extra_source_path}/shaders.cpp")

# 构建目标
add_executable(${PROJECT_NAME} ${source_file} ${extra_source_file})
# 目标依赖项
# glad 需要 --mx --loader 构建
add_dependencies(${PROJECT_NAME} glad2-2.0.4 glfw3-3.3.9 stb-master imgui-1.90.1-docking)
# 目标include
target_include_directories(
    ${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    "${extra_source_path}"
    "${glad-2.0.4-includes}"
    "${glfw3-3.3.9-includes}"
)
# 目标链接项
target_link_libraries(${PROJECT_NAME} glad-2.0.4 glfw3-3.3.9 stb-master)
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
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:glad2-2.0.4>" "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:glfw3-3.3.9>" "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
)
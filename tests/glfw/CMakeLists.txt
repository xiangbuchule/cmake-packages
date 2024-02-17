# cmake需要的最低版本
cmake_minimum_required (VERSION 3.12)
# 主项目名
project(test_glfw)

if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -mwindows")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mwindows")
endif()

# 构建目标
add_executable(${PROJECT_NAME} main.cpp)
# 目标依赖项
add_dependencies(${PROJECT_NAME} glfw3-3.3.9)
# 目标include
target_include_directories(${PROJECT_NAME} PRIVATE ${glfw3-3.3.9-includes})
# 目标链接项
target_link_libraries(${PROJECT_NAME} "glfw3-3.3.9")
add_custom_command(
    TARGET ${PROJECT_NAME}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:glfw3-3.3.9>" "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
)
# 移除控制台窗口
if(MSVC)
    set_target_properties(
        ${PROJECT_NAME}
        PROPERTIES
        LINK_FLAGS "/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup"
    )
endif()
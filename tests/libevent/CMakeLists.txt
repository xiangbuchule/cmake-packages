# cmake需要的最低版本
cmake_minimum_required (VERSION 3.12)
# 主项目名
project(test_libevent)

# 构建目标
add_executable(${PROJECT_NAME} main.c)
# 目标依赖项
add_dependencies(${PROJECT_NAME} libevent_2.1.12_core libevent_2.1.12_extra)
# 目标include
target_include_directories(${PROJECT_NAME} PRIVATE ${libevent_2.1.12_includes})
# 目标链接项
target_link_libraries(${PROJECT_NAME} "libevent_2.1.12_core" "libevent_2.1.12_extra" ws2_32)
add_custom_command(
    TARGET ${PROJECT_NAME}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:libevent_2.1.12_core>" "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:libevent_2.1.12_extra>" "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
)
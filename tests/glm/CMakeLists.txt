# cmake需要的最低版本
cmake_minimum_required (VERSION 3.12)
# 主项目名
project(test_glm)

# 构建目标
add_executable(${PROJECT_NAME} main.cpp)
# 目标依赖项
add_dependencies(${PROJECT_NAME} glm_0.9.9.8)
# 目标include
target_include_directories(${PROJECT_NAME} PRIVATE "${glm_0.9.9.8_includes}")
# 目标链接项
target_link_libraries(${PROJECT_NAME} glm_0.9.9.8)
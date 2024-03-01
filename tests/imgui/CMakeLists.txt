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
set(project_include_path "${CMAKE_CURRENT_SOURCE_DIR}/include")
# set includes
set(project_source_path "${CMAKE_CURRENT_SOURCE_DIR}/src")
# set config
set(project_config_path "${CMAKE_CURRENT_SOURCE_DIR}/config")
# set cmake module source path
set(project_cmake_module_path "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
# set extra source path
set(project_extra_source_path "${CMAKE_CURRENT_BINARY_DIR}/extra")
# set assets source path
set(project_assets_path "${CMAKE_CURRENT_SOURCE_DIR}/assets")


# config assets
include("${project_cmake_module_path}/assets.cmake")
imgui_patch_script(
    script              "${CMAKE_CURRENT_BINARY_DIR}/patch.cmake"
    target              "${CMAKE_CURRENT_BINARY_DIR}/rc.zip"
    config_key          "rc_data"
    config_files        "${project_config_path}/rc.h.in"   "${project_config_path}/rc.c.in"
    config_target_files "${project_extra_source_path}/rc.h" "${project_extra_source_path}/rc.c"
    sources             "icons/16x16_icon.png"      "icons/16x16_icon.png"
                        "icons/32x32_icon.png"      "icons/48x48_icon.png"
                        "icons/64x64_icon.png"      "icons/128x128_icon.png"
                        "icons/256x256_icon.png"    "icons/512x512_icon.png"
                        "shaders/main.vert"         "shaders/main.frag"
                        "fonts/Nerd-Font-Hack/HackNerdFont-Regular.ttf"
                        "fonts/Source-Han-Sans/SimplifiedChinese-VF.ttf"
)

# config file
configure_file("${project_config_path}/config.h.in" "${project_extra_source_path}/config.h" @ONLY)
add_custom_command(
    OUTPUT "${project_extra_source_path}/rc.c"
    COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/patch.cmake"
    WORKING_DIRECTORY "${project_assets_path}"
    USES_TERMINAL
    COMMENT "Check Assets ..."
)

# 查找源文件
file(GLOB_RECURSE files CONFIGURE_DEPENDS "${project_source_path}/*.cpp")
list(APPEND source_file "${project_extra_source_path}/rc.c"
                        "${files}")

# 构建目标
add_executable(${PROJECT_NAME} ${source_file})
# 目标依赖项
add_dependencies(
    ${PROJECT_NAME} libzip-1.10.1 glad2-2.0.4 glfw3-3.3.9 stb-master
                    freetype2-2.13.2 imgui-1.90.4-docking-glfw-opengl3
                    mysql-connector-cpp-8.3.0::jdbc mysql-connector-cpp-8.3.0::xdev
                    rapidjson-1.1.0
)
# 目标include
target_include_directories(
    ${PROJECT_NAME} PRIVATE
    "${project_include_path}"
    "${project_extra_source_path}"
)
target_include_directories(
    ${PROJECT_NAME} PRIVATE
    "${openssl1-1.1.1w-includes}"
    "${glad2-2.0.4-includes}"
    "${glfw3-3.3.9-includes}"
    "${freetype2-2.13.2-includes}"
    "${libzip-1.10.1-includes}"
    "${mysql-connector-cpp-8.3.0-includes}"
)
# 声明一下源文件是被生成的
# 防止generate阶段报错找不到源文件
add_custom_command(
    OUTPUT  ${imgui-1.90.4-docking-glfw-opengl3-sources}
    COMMAND echo some source files will be created
    USES_TERMINAL ON
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    # COMMAND "${CMAKE_COMMAND}" -E touch ${imgui-1.90.4-docking-glfw-opengl3-sources}
)
# 目标链接项
target_link_libraries(
    ${PROJECT_NAME} libzip-1.10.1 glad2-2.0.4 glfw3-3.3.9 stb-master
                    freetype2-2.13.2 imgui-1.90.4-docking-glfw-opengl3
                    mysql-connector-cpp-8.3.0::jdbc mysql-connector-cpp-8.3.0::xdev
                    rapidjson-1.1.0
)
target_compile_definitions(
    ${PROJECT_NAME} PRIVATE
    GLFW_INCLUDE_NONE
    IMGUI_ENABLE_FREETYPE
    STB_IMAGE_IMPLEMENTATION
    _SILENCE_CXX17_ITERATOR_BASE_CLASS_DEPRECATION_WARNING
    _SILENCE_ALL_CXX17_DEPRECATION_WARNINGS
)
# 由于glad构建为了动态库,需要添加GLAD_API_CALL_EXPORT
# 保证能正确找到动态库的函数地址,当然也可以在.h文件中添加
# #define GLAD_API_CALL_EXPORT
if(MSVC AND glad2-2.0.4-shared)
    target_compile_definitions(
        ${PROJECT_NAME} PRIVATE
        GLAD_API_CALL_EXPORT
    )
endif()
if(MSVC)
    set(new_link_flags "/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup")
    get_target_property(old_link_flags ${PROJECT_NAME} LINK_FLAGS)
    if(NOT "${old_link_flags}" STREQUAL "old_link_flags-NOTFOUND")
        set(new_link_flags "${old_link_flags} ${new_link_flags}")
    endif()
    set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "${new_link_flags}")
endif()
# 构建后复制文件
if(WIN32)
    set(bzip2_bin bz2-1.dll)
else()
    set(bzip2_bin bz2-1.so)
endif()
# set file list
set(file_lists  "$<TARGET_FILE:zlib-1.3.1>" "$<TARGET_FILE:libzip-1.10.1>" "$<TARGET_FILE:freetype2-2.13.2>"
                "$<TARGET_FILE:glad2-2.0.4>" "$<TARGET_FILE:glfw3-3.3.9>" "$<TARGET_FILE:openssl1-1.1.1w::ssl>"
                "$<TARGET_FILE:openssl1-1.1.1w::crypto>" "$<TARGET_FILE:mysql-connector-cpp-8.3.0::jdbc>"
                "$<TARGET_FILE:mysql-connector-cpp-8.3.0::xdev>" "$<TARGET_FILE:mysql8-8.3.0>")
add_custom_command(
    TARGET ${PROJECT_NAME}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${file_lists}                  "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:bzip2-master>"  "$<TARGET_FILE_DIR:${PROJECT_NAME}>/${bzip2_bin}"
)
# cmake需要的最低版本
cmake_minimum_required (VERSION 3.12)
# 项目名
project(Tests)

# 设置代理
set(ENV{http_proxy}     "socks5://127.0.0.1:10808")
set(ENV{https_proxy}    "socks5://127.0.0.1:10808")

# # tools
# include("${custom_module}/tools/perl/perl.cmake")
# add_perl(name "perl_win32_x64_5.38.0.1" prefix "${third_path}" version "5.38.0.1" platform "win32" arch "x64")

include("${custom_module}/tools/python/python3.cmake")
add_python3(
    name        "python-3.13.0a1"
    prefix      "${third_path}"
    url         "https://www.python.org/ftp/python/3.13.0/python-3.13.0a1-embed-amd64.zip"
    file        "python-3.13.0a1.zip"
    # proxy       "http://127.0.0.1:10809"
    sha256      "fb8733603b48722e6cdfcdee2b8b4d4f5c8f6723ef8a9478ab211d6469226df6"
    pkgs        "jinja2"
    pip_url     "https://bootstrap.pypa.io/get-pip.py"
    pip_file    "get-pip.py"
)

# # 查找python
# if (CMAKE_VERSION VERSION_LESS 3.12)
#     find_package(PythonInterp REQUIRED)
# else()
#     find_package(Python)
#     set(PYTHON_EXECUTABLE ${Python_EXECUTABLE})
# endif()
# if("" STREQUAL "${Python_FOUND}")
#     set(Python_FOUND FALSE)
# endif()
# if("" STREQUAL "${PYTHONINTERP_FOUND}")
#     set(PYTHONINTERP_FOUND FALSE)
# endif()
# # 如果没找到就下载
# if((NOT ${Python_FOUND}) AND (NOT ${PYTHONINTERP_FOUND}))
#     include("${custom_module}/tools/python/python3.cmake")
#     add_python3(name "python3_win32_x64_3.11.6" prefix "${third_path}" version "3.11.6" platform "win32" arch "x64"
#             proxy "http://127.0.0.1:10809" packages "jinja2")
#     set(PYTHON_EXECUTABLE "${python3_win32_x64_3.11.6_path}/python.exe")
#     set(depends_python_option depends "python3_win32_x64_3.11.6")
# endif()

# # glm
# include("${custom_module}/packages/glm/glm.cmake")
# add_glm(name "glm_0.9.9.8" version "0.9.9.8" prefix "${third_path}" header_only cmake_args ${common_cmake_args})

# # cglm
# include("${custom_module}/packages/cglm/cglm.cmake")
# add_cglm(name "cglm_0.9.1" version "0.9.1" prefix "${third_path}" header_only cmake_args ${common_cmake_args})

# # libevent2
# include("${custom_module}/packages/libevent/libevent2.cmake")
# add_libevent2(name "libevent_2.1.12" version "2.1.12" prefix "${third_path}" library_type "SHARED"
#                 disable_benchmark disable_tests disable_samples build_type "${CMAKE_BUILD_TYPE}" cmake_args ${common_cmake_args})

# glfw3
include("${custom_module}/packages/glfw/glfw3.cmake")
add_glfw3(
    name    "glfw3-3.3.9"
    prefix  "${third_path}"
    version "3.3.9"
    "-DBUILD_SHARED_LIBS=ON"    "-DCMAKE_BUILD_TYPE=Release"    "-DGLFW_BUILD_EXAMPLES=OFF"
    "-DGLFW_BUILD_TESTS=OFF"    "-DGLFW_BUILD_DOCS=OFF"         "-DGLFW_INSTALL=ON"
)

# glad2
include("${custom_module}/packages/glad/glad2.cmake")
add_glad2(
    name "glad-2.0.4-mx"
    version "2.0.4"
    prefix "${third_path}"
    proxy "http://127.0.0.1:10809"
    deps "tool-python-3.13.0a1"
    env_k "PATH"
    env_v "${python-3.13.0a1_path}"
    "-DGLAD_API=gl:compatibility=4.6,egl,gles1,gles2,glsc2,glx,vulkan,wgl"
    "-DGLAD_MX=ON"
)
add_glad2(
    name "glad-2.0.4"
    version "2.0.4"
    prefix "${third_path}"
    proxy "http://127.0.0.1:10809"
    deps "tool-python-3.13.0a1"
    env_k "PATH"
    env_v "${python-3.13.0a1_path}"
    "-DGLAD_API=gl:compatibility=4.6,egl,gles1,gles2,glsc2,glx,vulkan,wgl"
)

# stb_image
include("${custom_module}/packages/stb/stb.cmake")
add_stb(name "stb-master" version "master" prefix "${third_path}")

# imgui
include("${custom_module}/packages/imgui/imgui.cmake")
add_imgui("freetype" name "imgui-1.90.1-docking" version "v1.90.1-docking" prefix "${third_path}")

# ==================================================
# =================== 添加子项目 ===================
# ==================================================
# 子项目
# add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/glm")
# add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/cglm")
# add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/libevent")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/glfw")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/glad")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/imgui")

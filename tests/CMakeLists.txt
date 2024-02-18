# cmake需要的最低版本
cmake_minimum_required (VERSION 3.12)
# 项目名
project(Tests)

# 设置代理
set(http_proxy          "http://127.0.0.1:10809")
set(socks5_proxy        "socks5://127.0.0.1:10808")
set(ENV{http_proxy}     "${socks5_proxy}")
set(ENV{https_proxy}    "${socks5_proxy}")

# python3
include("${custom_module}/tools/python/python3.cmake")
add_python3(
    name            "python3-3.13.0a1"
    prefix          "${third_path}"
    url             "https://www.python.org/ftp/python/3.13.0/python-3.13.0a1-embed-amd64.zip"
    file            "python3-3.13.0a1.zip"
    # proxy           "${socks5_proxy}"
    sha256          "fb8733603b48722e6cdfcdee2b8b4d4f5c8f6723ef8a9478ab211d6469226df6"
    pkgs            "jinja2"
    pip_url         "https://bootstrap.pypa.io/get-pip.py"
    pip_file        "get-pip.py"
    pip_source_url  "https://pypi.tuna.tsinghua.edu.cn"
)

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
    name    "glad2-2.0.4-mx"
    version "2.0.4"
    prefix  "${third_path}"
    proxy   "${http_proxy}"
    deps    "tool-python3-3.13.0a1"
    python  "${python3-3.13.0a1-path}"
    "-DGLAD_API=gl:compatibility=4.6,egl,gles1,gles2,glsc2,glx,vulkan,wgl"
    "-DGLAD_MX=ON"
)
add_glad2(
    name    "glad2-2.0.4"
    version "2.0.4"
    prefix  "${third_path}"
    proxy   "${http_proxy}"
    deps    "tool-python3-3.13.0a1"
    python  "${python3-3.13.0a1-path}"
    "-DGLAD_API=gl:compatibility=4.6,egl,gles1,gles2,glsc2,glx,vulkan,wgl"
)

# stb_image
include("${custom_module}/packages/stb/stb.cmake")
add_stb(name "stb-master" version "master" prefix "${third_path}" proxy "${socks5_proxy}")

# freetype2
include("${custom_module}/packages/freetype/freetype2.cmake")
add_freetype2(
    name    "freetype2-2.13.2"
    version "2.13.2"
    prefix  "${third_path}"
    proxy   "${socks5_proxy}"
)

# imgui
include("${custom_module}/packages/imgui/imgui.cmake")
add_imgui(
    name    "imgui-1.90.3-docking"
    version "1.90.3-docking"
    prefix  "${third_path}"
    # proxy   "${socks5_proxy}"
    deps    "pkg-glad2-2.0.4" "pkg-glfw3-3.3.9" "pkg-freetype2-2.13.2"
    freetype ON
)

# ==================================================
# =================== 添加子项目 ===================
# ==================================================
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/glfw")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/glad")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/imgui")

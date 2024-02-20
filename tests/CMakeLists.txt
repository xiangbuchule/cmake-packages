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

# boost
include("${custom_module}/packages/boost/boost.cmake")
add_boost(
    name        "boost-1.84.0"
    version     "1.84.0"
    prefix      "${third_path}"
    # proxy       "${socks5_proxy}"
)

# zlib
include("${custom_module}/packages/zlib/zlib.cmake")
add_zlib(
    name    "zlib-1.3.1"
    version "1.3.1"
    prefix  "${third_path}"
    # proxy   "${socks5_proxy}"
    "-DZLIB_BUILD_EXAMPLES=OFF"
)

# bzip2
include("${custom_module}/packages/bzip/bzip2.cmake")
add_bzip2(
    name    "bzip2-master"
    version "master"
    prefix  "${third_path}"
    # proxy   "${socks5_proxy}"
    python  "${python3-3.13.0a1-path}"
    deps    "tool-python3-3.13.0a1"
)

# libzip
include("${custom_module}/packages/libzip/libzip.cmake")
add_libzip(
    name    "libzip-1.10.1"
    version "1.10.1"
    prefix  "${third_path}"
    # proxy   "${socks5_proxy}"
    deps    "pkg-zlib-1.3.1" "pkg-bzip2-master"
    zlib    "${zlib-1.3.1-root}"
    bzip2   "${bzip2-master-root}"
    "-DENABLE_BZIP2=ON"
)

# freetype2
include("${custom_module}/packages/freetype/freetype2.cmake")
add_freetype2(
    name    "freetype2-2.13.2"
    version "2.13.2"
    prefix  "${third_path}"
    proxy   "${socks5_proxy}"
    deps    "pkg-zlib-1.3.1" "pkg-bzip2-master"
    zlib    "${zlib-1.3.1-root}"
    bzip2   "${bzip2-master-root}"
)

# glfw3
include("${custom_module}/packages/glfw/glfw3.cmake")
add_glfw3(
    name    "glfw3-3.3.9"
    prefix  "${third_path}"
    version "3.3.9"
    "-DBUILD_SHARED_LIBS=ON"    "-DGLFW_BUILD_EXAMPLES=OFF"     "-DGLFW_INSTALL=ON"
    "-DGLFW_BUILD_TESTS=OFF"    "-DGLFW_BUILD_DOCS=OFF"
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

# imgui
include("${custom_module}/packages/imgui/imgui.cmake")
add_imgui(
    name        "imgui-1.90.3-docking-glfw-opengl3"
    version     "1.90.3-docking"
    prefix      "${third_path}"
    # proxy       "${socks5_proxy}"
    deps        "pkg-glad2-2.0.4" "pkg-glfw3-3.3.9" "pkg-freetype2-2.13.2"
    freetype    ON
    backends    "glfw" "opengl3"
)

# mysql-connecter-c
include("${custom_module}/packages/mysql/mysql8.cmake")
add_mysql8(
    name        "mysql8-8.3.0"
    version     "8.3.0"
    prefix      "${third_path}"
    # proxy       "${socks5_proxy}"
    # deps        "boost-1.84.0"
    # boost       "${boost-1.84.0-includes}"
)

# mysql-connecter-c
include("${custom_module}/packages/mysql/mysql-connector-c.cmake")
add_mysql_connector_c(
    name        "mysql-connector-c-6.1.11"
    version     "6.1.11"
    prefix      "${third_path}"
    # proxy       "${socks5_proxy}"
)

# ==================================================
# =================== 添加子项目 ===================
# ==================================================
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/glfw")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/glad")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/imgui")

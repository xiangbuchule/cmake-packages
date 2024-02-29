# cmake需要的最低版本
cmake_minimum_required (VERSION 3.12)
# 项目名
project(Tests)

if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

# 设置代理
set(http_proxy          "http://127.0.0.1:10809")
set(socks5_proxy        "socks5://127.0.0.1:10808")
set(ENV{http_proxy}     "${socks5_proxy}")
set(ENV{https_proxy}    "${socks5_proxy}")

# nasm
include("${custom_module}/tools/nasm/nasm.cmake")
add_nasm(
    name    "nasm-2.16.01"
    prefix  "${third_path}"
    url     "https://www.nasm.us/pub/nasm/releasebuilds/2.16.01/win64/nasm-2.16.01-win64.zip"
    file    "nasm-2.16.01.zip"
    # proxy   "${socks5_proxy}"
    sha256  "029EED31FAF0D2C5F95783294432CBEA6C15BF633430F254BB3C1F195C67CA3A"
)

# python3
include("${custom_module}/tools/python/python3.cmake")
add_python3(
    name            "python3-3.13.0a1"
    prefix          "${third_path}"
    url             "https://www.python.org/ftp/python/3.13.0/python-3.13.0a1-embed-amd64.zip"
    file            "python3-3.13.0a1.zip"
    proxy           "${socks5_proxy}"
    sha256          "fb8733603b48722e6cdfcdee2b8b4d4f5c8f6723ef8a9478ab211d6469226df6"
    pkgs            "jinja2"
    pip_url         "https://bootstrap.pypa.io/pip/get-pip.py"
    pip_file        "get-pip.py"
    pip_source_url  "https://pypi.tuna.tsinghua.edu.cn"
)

# perl
include("${custom_module}/tools/perl/perl.cmake")
add_perl(
    name    "perl-5.36.1.1"
    prefix  "${third_path}"
    url     "https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_5380_5361/strawberry-perl-5.36.1.1-64bit-portable.zip"
    file    "perl-5.36.1.1.zip"
    proxy   "${socks5_proxy}"
    sha256  "96dc0fc440e3123dd8d58df3498e41caba20610f33ed67af937a61b296c4786c"
)

# stdexec
include("${custom_module}/packages/base/stdexec/stdexec.cmake")
add_stdexec(name "stdexec-main" version "main" prefix "${third_path}" proxy "${socks5_proxy}")

# zlib
include("${custom_module}/packages/compress/zlib/zlib.cmake")
add_zlib(
    name    "zlib-1.3.1"
    version "1.3.1"
    prefix  "${third_path}"
    # proxy   "${socks5_proxy}"
    "-DZLIB_BUILD_EXAMPLES=OFF"
)

# openssl1
include("${custom_module}/packages/encrypt/openssl/openssl1.cmake")
get_target_property(zlib-lib zlib-1.3.1 IMPORTED_IMPLIB)
add_openssl1(
    name        "openssl1-1.1.1w"
    prefix      "${third_path}"
    version     "1.1.1w"
    nasm        "${nasm-2.16.01-path}"
    perl        "${perl-5.36.1.1-path}"
    proxy       "${socks5_proxy}"
    deps        "tool-nasm-2.16.01" "tool-perl-5.36.1.1" "pkg-zlib-1.3.1"
    options     "no-tests" "zlib" "zlib-dynamic"
                "--with-zlib-lib=${zlib-lib}"
                "--with-zlib-include=${zlib-1.3.1-root}/include"
)
# openssl3
include("${custom_module}/packages/encrypt/openssl/openssl3.cmake")
add_openssl3(
    name    "openssl3-3.2.1"
    prefix  "${third_path}"
    version "3.2.1"
    nasm    "${nasm-2.16.01-path}"
    perl    "${perl-5.36.1.1-path}"
    # proxy   "${socks5_proxy}"
    deps    "tool-nasm-2.16.01" "tool-perl-5.36.1.1"
)

# boost
include("${custom_module}/packages/base/boost/boost.cmake")
add_boost(
    name        "boost-1.84.0"
    version     "1.84.0"
    prefix      "${third_path}"
    proxy       "${socks5_proxy}"
)

# bzip2
include("${custom_module}/packages/compress/bzip/bzip2.cmake")
add_bzip2(
    name    "bzip2-master"
    version "master"
    prefix  "${third_path}"
    # proxy   "${socks5_proxy}"
    python  "${python3-3.13.0a1-path}"
    deps    "tool-python3-3.13.0a1"
)

# libzip
include("${custom_module}/packages/compress/libzip/libzip.cmake")
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
include("${custom_module}/packages/asset/freetype/freetype2.cmake")
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
include("${custom_module}/packages/ui/glfw/glfw3.cmake")
add_glfw3(
    name    "glfw3-3.3.9"
    prefix  "${third_path}"
    version "3.3.9"
    "-DBUILD_SHARED_LIBS=ON"    "-DGLFW_BUILD_EXAMPLES=OFF"     "-DGLFW_INSTALL=ON"
    "-DGLFW_BUILD_TESTS=OFF"    "-DGLFW_BUILD_DOCS=OFF"
)

# glad2
include("${custom_module}/packages/render/glad/glad2.cmake")
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
include("${custom_module}/packages/asset/stb/stb.cmake")
add_stb(name "stb-master" version "master" prefix "${third_path}" proxy "${socks5_proxy}")

# imgui
include("${custom_module}/packages/ui/imgui/imgui.cmake")
add_imgui(
    name        "imgui-1.90.4-docking-glfw-opengl3"
    version     "1.90.4-docking"
    prefix      "${third_path}"
    # proxy       "${socks5_proxy}"
    deps        "pkg-glad2-2.0.4" "pkg-glfw3-3.3.9" "pkg-freetype2-2.13.2"
    freetype    ON
    backends    "glfw" "opengl3"
)

# mysql-connecter-c
include("${custom_module}/packages/database/mysql/mysql-connector-c.cmake")
add_mysql_connector_c(
    name    "mysql-connector-c-6.1.11"
    version "6.1.11"
    prefix  "${third_path}"
)

# mysql-connecter-cpp
include("${custom_module}/packages/database/mysql/mysql-connector-cpp.cmake")
add_mysql_connector_cpp(
    name    "mysql-connector-cpp-8.0.33"
    version "8.0.33"
    deps    "pkg-openssl1-1.1.1w"
    prefix  "${third_path}"
    proxy   "${socks5_proxy}"
    "-DWITH_SSL=${openssl1-1.1.1w-root}"
)

# rapidjson
include("${custom_module}/packages/serialize/json/rapidjson/rapidjson.cmake")
add_rapidjson(name "rapidjson-1.1.0" version "1.1.0" prefix "${third_path}" proxy "${socks5_proxy}")

include("${custom_module}/packages/serialize/json/jsoncpp/jsoncpp.cmake")
add_jsoncpp(name "jsoncpp-1.9.5" version "1.9.5" prefix "${third_path}" proxy "${socks5_proxy}")

include("${custom_module}/packages/serialize/json/nlohmannjson/nlohmann-json.cmake")
add_nlohmannjson(name "nlohmannjson-3.11.3" version "3.11.3" prefix "${third_path}" proxy "${socks5_proxy}")

# ==================================================
# =================== 添加子项目 ===================
# ==================================================
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/glfw")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/glad")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/imgui")

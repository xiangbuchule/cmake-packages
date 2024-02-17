# cmake需要的最低版本
cmake_minimum_required(VERSION 3.12)
# 主项目名
project(Main)

# =====================================
# ============= 设置库类型 =============
# =====================================
if(POLICY CMP0077)
    cmake_policy(SET CMP0077 NEW)
endif()
# 设置默认构建动态库
option(BUILD_SHARED_LIBS "Build shared libraries" ON)

# =====================================
# ========= 设置c/cpp编译选项 ==========
# =====================================
# 设置c编译版本
set(CMAKE_C_STANDARD 23)
# 设置c++编译版本
set(CMAKE_CXX_STANDARD 23)
# 设置c编译器
# set(CMAKE_C_COMPILER "gcc")
# message(${CMAKE_C_COMPILER})
# 设置cpp编译器
# set(CMAKE_CXX_COMPILER "g++")
# message(${CMAKE_CXX_COMPILER})
# 设置c/cpp编译Debug与Release的编译参数
# Clang编译选项与MSVC相似
if(CMAKE_C_COMPILER_ID STREQUAL "Clang")
    # using Clang
    message("-- using Clang compile")
elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    # using GCC
    message("-- using GCC compile")
    set(flags_debug "-O0 -g3 -ggdb3")
    set(flags_release "-O3")
elseif(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    # using Visual Studio
    message("-- using MSVC compile")
    set(flags_debug "/Od /Zi /Ob0 /MDd /RTC1")
    set(flags_release "/Ox -fp:fast /Ob2 /MD")
endif()
set(CMAKE_C_FLAGS_DEBUG     "${CMAKE_C_FLAGS_DEBUG} ${flags_debug}")
set(CMAKE_C_FLAGS_RELEASE   "${CMAKE_C_FLAGS_RELEASE} ${flags_release}")
set(CMAKE_CXX_FLAGS_DEBUG   "${CMAKE_CXX_FLAGS_DEBUG} ${flags_debug}")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${flags_release}")
if(WIN32 AND (CMAKE_C_COMPILER_ID STREQUAL "GNU"))
    set(mingw_flags             "-static-libgcc -static-libstdc++ -Wl,-Bstatic -lstdc++ -lpthread -lwinpthread -Wl,-Bdynamic")
    set(CMAKE_C_FLAGS           "${CMAKE_C_FLAGS} ${mingw_flags}")
    set(CMAKE_CXX_FLAGS         "${CMAKE_CXX_FLAGS} ${mingw_flags}")
endif()

# =====================================
# ========= 设置额外编译选项 ===========
# =====================================
# 设置编码
set(code_encode UTF-8)
set(binary_ncode ${code_encode})
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    add_compile_options(/source-charset:${code_encode} /execution-charset:${binary_ncode})
endif()
if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    add_compile_options(-finput-charset=${code_encode} -fexec-charset=${binary_ncode} -fwide-exec-charset=${binary_ncode})
endif()

# =====================================
# === 设置编译版本是Debug还是Release ===
# =====================================
# 判断命令传入的是否为空，如果为空，默认Debug
if("${CMAKE_BUILD_TYPE}" STREQUAL "")
    set(CMAKE_BUILD_TYPE "Debug")
endif()

# =====================================
# ========== 包含的三方项目 ============
# =====================================
set(custom_module "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
set(third_path "${CMAKE_CURRENT_SOURCE_DIR}/third")

# =====================================
# ============ 添加子项目 ==============
# =====================================
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/tests")

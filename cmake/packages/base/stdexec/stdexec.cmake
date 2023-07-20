include(ExternalProject)

# name: target name
# prefix: prefix path
# version: packages version
# deps: deps target
function(add_stdexec)
    # params
    cmake_parse_arguments(stdexec "" "name;prefix;version;proxy" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${stdexec_name}" OR (DEFINED "${stdexec_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${stdexec_name}")
    # set source path
    set(stdexec_source "${stdexec_prefix}/${stdexec_name}")
    # set git config
    if(NOT ("" STREQUAL "${std_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${std_proxy} https.proxy=${std_proxy})
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   GIT_REPOSITORY "https://github.com/NVIDIA/stdexec" GIT_TAG "${stdexec_version}"
                                        ${git_config} GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON
                                        SOURCE_DIR "${stdexec_source}" PATCH_COMMAND "" CONFIGURE_COMMAND ""
                                        BUILD_COMMAND "" INSTALL_COMMAND "" EXCLUDE_FROM_ALL ON USES_TERMINAL_DOWNLOAD ON
                                        USES_TERMINAL_UPDATE ON DEPENDS ${stdexec_deps} ${stdexec_UNPARSED_ARGUMENTS})
    # set library
    add_library("${stdexec_name}" INTERFACE)
    target_include_directories("${stdexec_name}" INTERFACE "${stdexec_source}/include")
    find_package(Threads REQUIRED)
    target_link_libraries("${stdexec_name}" INTERFACE Threads::Threads)
    target_compile_features("${stdexec_name}" INTERFACE cxx_std_20)
    add_dependencies("${stdexec_name}" "${pkg_name}")
    # Detect the compiler frontend (GNU, Clang, MSVC, etc.)
    if(DEFINED CMAKE_CXX_COMPILER_FRONTEND_VARIANT)
    set(stdexec_compiler_frontend ${CMAKE_CXX_COMPILER_FRONTEND_VARIANT})
    else()
    set(stdexec_compiler_frontend ${CMAKE_CXX_COMPILER_ID})
    endif()
    # Enable coroutines for GCC
    target_compile_options("${stdexec_name}" INTERFACE $<$<COMPILE_LANG_AND_ID:CXX,GNU>:-fcoroutines>)
    # Increase the concepts diagnostics depth for GCC
    target_compile_options("${stdexec_name}" INTERFACE $<$<CXX_COMPILER_ID:GNU>:-fconcepts-diagnostics-depth=10>)
    # Do you want a preprocessor that works? Picky, picky.
    target_compile_options("${stdexec_name}" INTERFACE $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/Zc:__cplusplus /Zc:preprocessor>)
    # enable extra type checking
    set(STDEXEC_ENABLE_EXTRA_TYPE_CHECKING ON)
    if (STDEXEC_ENABLE_EXTRA_TYPE_CHECKING)
        target_compile_definitions("${stdexec_name}" INTERFACE STDEXEC_ENABLE_EXTRA_TYPE_CHECKING)
    endif()
    # enable numa
    # set(STDEXEC_ENABLE_NUMA OFF)
    # if (STDEXEC_ENABLE_NUMA)
    #     find_package(numa REQUIRED)
    #     target_link_libraries("${stdexec_name}" INTERFACE numa::numa)
    #     target_compile_definitions("${stdexec_name}" INTERFACE STDEXEC_ENABLE_NUMA)
    # endif()
    # enable tbb
    # set(STDEXEC_ENABLE_TBB OFF)
    # if (STDEXEC_ENABLE_TBB)
    #     include(rapids-find)
    #     rapids_find_package(
    #         TBB REQUIRED
    #         BUILD_EXPORT_SET stdexec-exports
    #         INSTALL_EXPORT_SET stdexec-exports
    #     )
    #     file(GLOB_RECURSE tbbexec_sources include/tbbexec/*.hpp)
    #     add_library(tbbexec INTERFACE ${tbbexec_sources})
    #     list(APPEND stdexec_export_targets tbbexec)
    #     add_library(STDEXEC::tbbexec ALIAS tbbexec)
    #     target_link_libraries(tbbexec
    #         INTERFACE
    #         STDEXEC::stdexec
    #         TBB::tbb
    #         )
    # endif()
    # Support target for examples and tests
    add_library("${stdexec_name}-flags" INTERFACE)
    # Enable warnings
    target_compile_options("${stdexec_name}-flags" INTERFACE
                        $<$<STREQUAL:${stdexec_compiler_frontend},GNU>:-Wall>
                        $<$<STREQUAL:${stdexec_compiler_frontend},AppleClang>:-Wall>
                        $<$<STREQUAL:${stdexec_compiler_frontend},MSVC>:/W4>)
    # Increase the error limit with NVC++
    target_compile_options("${stdexec_name}-flags" INTERFACE
                        $<$<CXX_COMPILER_ID:NVHPC>:-e1000>)
    # Silence warnings
    target_compile_options("${stdexec_name}-flags" INTERFACE
                        $<$<CXX_COMPILER_ID:GNU>:-Wno-non-template-friend>
                        $<$<CXX_COMPILER_ID:NVHPC>:--diag_suppress177,550,111,497,554>
                        $<$<CXX_COMPILER_ID:MSVC>:/wd4100 /wd4101 /wd4127 /wd4324 /wd4456 /wd4459>)
    # Template backtrace limit
    target_compile_options("${stdexec_name}-flags" INTERFACE
                        $<$<OR:$<CXX_COMPILER_ID:Clang>,$<CXX_COMPILER_ID:AppleClang>>:
                            $<$<STREQUAL:${CMAKE_CXX_COMPILER_FRONTEND_VARIANT},MSVC>:/clang:>-ferror-limit=0
                            $<$<STREQUAL:${CMAKE_CXX_COMPILER_FRONTEND_VARIANT},MSVC>:/clang:>-fmacro-backtrace-limit=0
                            $<$<STREQUAL:${CMAKE_CXX_COMPILER_FRONTEND_VARIANT},MSVC>:/clang:>-ftemplate-backtrace-limit=0>
                        $<$<AND:$<CXX_COMPILER_ID:NVHPC>,$<VERSION_GREATER:$<CXX_COMPILER_VERSION>,23.3.0>>:
                        -ftemplate-backtrace-limit=0>)
    # Clang CUDA options
    target_compile_options("${stdexec_name}-flags" INTERFACE
                        $<$<COMPILE_LANG_AND_ID:CUDA,Clang>:
                        -Wno-unknown-cuda-version
                        -Xclang=-fcuda-allow-variadic-functions
                        -D_GLIBCXX_USE_TBB_PAR_BACKEND=0
                        -include ${stdexec_source}/include/stdexec/__detail/__force_include.hpp>
                        )
    target_compile_definitions("${stdexec_name}-flags" INTERFACE
                        $<$<NOT:$<AND:$<CXX_COMPILER_ID:NVHPC>,$<COMPILE_LANGUAGE:CXX>>>:
                        STDEXEC_ENABLE_EXTRA_TYPE_CHECKING>)
    # set include
    set("${stdexec_name}-includes" "${stdexec_source}" PARENT_SCOPE)
endfunction()

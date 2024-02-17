include(ExternalProject)

# git_shallow:
#   "git clone" will add "--depth 1". if set it,
# name: target name
# prefix: prefix path
# version: packages version
# deps: deps target
function(add_imgui)
    # params
    cmake_parse_arguments(imgui "" "name;prefix;version;freetype;backends;proxy" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${imgui_name}" OR (DEFINED "${imgui_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${imgui_name}")
    # set source path
    set(imgui_source "${imgui_prefix}/${imgui_name}")
    # set git config
    if(NOT ("" STREQUAL "${imgui_proxy}"))
        set(git_config GIT_CONFIG http.proxy="${imgui_proxy}" https.proxy="${imgui_proxy}")
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   GIT_REPOSITORY "https://github.com/ocornut/imgui" GIT_TAG "${imgui_version}"
                                        GIT_SHALLOW ON GIT_PROGRESS OFF ${git_config} SOURCE_DIR "${imgui_source}"
                                        PATCH_COMMAND "" CONFIGURE_COMMAND "" BUILD_COMMAND "" INSTALL_COMMAND ""
                                        USES_TERMINAL_DOWNLOAD ON USES_TERMINAL_UPDATE ON
                                        DEPENDS ${imgui_deps} ${imgui_UNPARSED_ARGUMENTS})
    # set library
    add_library("${imgui_name}" INTERFACE)
    target_include_directories("${imgui_name}" INTERFACE "${imgui_source}" "${imgui_source}/backends/imgui_impl_${imgui_backends}.h")
    target_sources("${imgui_name}" INTERFACE    "${imgui_source}/imgui.cpp" "${imgui_source}/imgui_demo.cpp"
                                                "${imgui_source}/imgui_draw.cpp" "${imgui_source}/imgui_tables.cpp"
                                                "${imgui_source}/imgui_widgets.cpp"
                                                "${imgui_source}/backends/imgui_impl_${imgui_backends}.cpp")
    if("${imgui_freetype}")
        target_include_directories("${imgui_name}" INTERFACE "${imgui_source}/misc/freetype/imgui_freetype.h")
        target_sources("${imgui_name}" INTERFACE "${imgui_source}/misc/freetype/imgui_freetype.cpp")
    endif()
    add_dependencies("${imgui_name}" "${pkg_name}")
    # set include
    set("${imgui_name}-includes" "${imgui_source}" PARENT_SCOPE)
endfunction()

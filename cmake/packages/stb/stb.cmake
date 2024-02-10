include(ExternalProject)

# name: target name
# prefix: prefix path
# version: packages version
# deps: deps target
function(add_stb)
    # params
    cmake_parse_arguments(stb "" "name;prefix;version;proxy" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${stb_name}" OR (DEFINED "${stb_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${stb_name}")
    # set source path
    set(stb_source "${stb_prefix}/${stb_name}")
    # set git config
    if(NOT ("" STREQUAL "${std_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${std_proxy} https.proxy=${std_proxy})
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   GIT_REPOSITORY "https://github.com/nothings/stb" GIT_TAG "${stb_version}"
                                        ${git_config} GIT_SHALLOW ON GIT_PROGRESS OFF SOURCE_DIR "${stb_source}"
                                        PATCH_COMMAND "" CONFIGURE_COMMAND "" BUILD_COMMAND "" INSTALL_COMMAND ""
                                        USES_TERMINAL_DOWNLOAD ON USES_TERMINAL_UPDATE ON
                                        DEPENDS ${stb_deps} ${stb_UNPARSED_ARGUMENTS})
    # set library
    add_library("${stb_name}" INTERFACE)
    target_include_directories("${stb_name}" INTERFACE "${stb_source}")
    add_dependencies("${stb_name}" "${pkg_name}")
    # set include
    set("${stb_name}-includes" "${stb_source}" PARENT_SCOPE)
endfunction()

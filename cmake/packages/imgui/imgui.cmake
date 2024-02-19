include(ExternalProject)

# name:     target name
# prefix:   prefix path
# version:  packages version
# deps:     deps target
# freetype: is support freetype
function(add_imgui)
    # params
    cmake_parse_arguments(imgui "" "name;prefix;version;freetype;proxy" "backends;deps" ${ARGN})
    # if target exist, return
    if(TARGET "${imgui_name}" OR (DEFINED "${imgui_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${imgui_name}")
    set(imgui_repository_url            "https://github.com/ocornut/imgui")
    list(APPEND imgui_version_list      "1.90.3" "1.90.3-docking" "1.90.2" "1.90.2-docking")
    list(APPEND imgui_hash_list         "e6056a61301eaacb269a7302b55fd9b78a5b47ebc43bfb0aafa9bc9fd265fc4a"
                                        "8d82ea44daa778cc888c8423c0baef7d312ac539dc1ad92d8256c38e1d9a562b"
                                        "75f5f0a8fb9942eb9f388c7e352c54a0b3076edf137944a0d0711bff20082390"
                                        "688e50a9e3068a70df92596415bbcd2ec675168986cd7a67432597b125ff9f26")
    # input version is in version list
    string(STRIP "${imgui_version}" imgui_version)
    if("${imgui_version}" STREQUAL "")
        set(imgui_version_index 0)
    else()
        list(FIND imgui_version_list "${imgui_version}" imgui_version_index)
    endif()
    if(imgui_version_index GREATER_EQUAL 0)
        set(imgui_url   "${imgui_repository_url}/archive/refs/tags/v${imgui_version}.zip")
        set(imgui_file  "imgui-${imgui_version}.zip")
        list(GET imgui_hash_list ${imgui_version_index} imgui_hash)
    endif()
    # set source path
    set(imgui_download  "${imgui_prefix}/cache/download")
    set(imgui_source    "${imgui_prefix}/${imgui_name}")
    # set git config
    if(NOT ("" STREQUAL "${imgui_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${imgui_proxy} https.proxy=${imgui_proxy})
    endif()
    # set url option
    if(${imgui_version_index} GREATER_EQUAL 0)
        set(imgui_url_option    URL "${imgui_url}" URL_HASH SHA256=${imgui_hash} DOWNLOAD_NAME "${imgui_file}")
    else()
        set(imgui_url_option    GIT_REPOSITORY "${imgui_repository_url}" GIT_TAG "${imgui_version}"
                                GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${imgui_download}" SOURCE_DIR "${imgui_source}" ${imgui_url_option}
                                        PATCH_COMMAND "" CONFIGURE_COMMAND "" BUILD_COMMAND "" INSTALL_COMMAND ""
                                        EXCLUDE_FROM_ALL ON USES_TERMINAL_DOWNLOAD ON USES_TERMINAL_UPDATE ON
                                        DEPENDS ${imgui_deps} ${imgui_UNPARSED_ARGUMENTS})
    # set source/include
    set(includes_paths  "${imgui_source}" "${imgui_source}/backends")
    set(sources_files   "${imgui_source}/imgui.cpp"
                        "${imgui_source}/imgui_demo.cpp"
                        "${imgui_source}/imgui_draw.cpp"
                        "${imgui_source}/imgui_tables.cpp"
                        "${imgui_source}/imgui_widgets.cpp")
    foreach(item IN LISTS imgui_backends imgui_UNPARSED_ARGUMENTS)
        list(APPEND sources_files "${imgui_source}/backends/imgui_impl_${item}.cpp")
    endforeach()
    if("${imgui_freetype}")
        list(APPEND includes_paths  "${imgui_source}/misc/freetype")
        list(APPEND sources_files   "${imgui_source}/misc/freetype/imgui_freetype.cpp")
    endif()
    # set library
    add_library("${imgui_name}" INTERFACE)
    target_include_directories("${imgui_name}" INTERFACE ${includes_paths})
    target_sources("${imgui_name}" INTERFACE ${sources_files})
    add_dependencies("${imgui_name}" "${pkg_name}")
    # set include
    set("${imgui_name}-sources"     ${sources_files}    PARENT_SCOPE)
    set("${imgui_name}-includes"    ${includes_paths}   PARENT_SCOPE)
endfunction()

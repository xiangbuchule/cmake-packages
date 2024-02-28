include(ExternalProject)

# name: target name
# prefix: prefix path
# version: packages version
# deps: deps target
function(add_rapidjson)
    # params
    cmake_parse_arguments(rapidjson "" "name;prefix;version;proxy" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${rapidjson_name}" OR (DEFINED "${rapidjson_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${rapidjson_name}")
    # address
    set(rapidjson_repository_url        "https://github.com/Tencent/rapidjson")
    list(APPEND rapidjson_version_list  "1.1.0")
    list(APPEND rapidjson_hash_list     "8E00C38829D6785A2DFB951BB87C6974FA07DFE488AA5B25DEEC4B8BC0F6A3AB")
    # input version is in version list
    string(STRIP "${rapidjson_version}" rapidjson_version)
    if("${rapidjson_version}" STREQUAL "")
        set(rapidjson_version_index 0)
    else()
        list(FIND rapidjson_version_list "${rapidjson_version}" rapidjson_version_index)
    endif()
    if(rapidjson_version_index GREATER_EQUAL 0)
        set(rapidjson_url   "${rapidjson_repository_url}/archive/refs/tags/v${rapidjson_version}.zip")
        set(rapidjson_file  "rapidjson-${rapidjson_version}.zip")
        list(GET rapidjson_hash_list ${rapidjson_version_index} rapidjson_hash)
    endif()
    # set path
    set(rapidjson_download  "${rapidjson_prefix}/cache/download")
    set(rapidjson_source    "${rapidjson_prefix}/${rapidjson_name}")
    # set git config
    if(NOT ("" STREQUAL "${std_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${std_proxy} https.proxy=${std_proxy})
    endif()
    # set url option
    if(${rapidjson_version_index} GREATER_EQUAL 0)
        set(rapidjson_url_option    URL "${rapidjson_url}" URL_HASH SHA256=${rapidjson_hash} DOWNLOAD_NAME "${rapidjson_file}")
    else()
        set(rapidjson_url_option    GIT_REPOSITORY "${rapidjson_repository_url}" GIT_TAG "${rapidjson_version}"
                                    GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${rapidjson_download}" SOURCE_DIR "${rapidjson_source}"
                                        ${rapidjson_url_option} PATCH_COMMAND "" CONFIGURE_COMMAND ""
                                        BUILD_COMMAND "" INSTALL_COMMAND "" EXCLUDE_FROM_ALL ON USES_TERMINAL_DOWNLOAD ON
                                        USES_TERMINAL_UPDATE ON DEPENDS ${rapidjson_deps} ${rapidjson_UNPARSED_ARGUMENTS})
    # set library
    add_library("${rapidjson_name}" INTERFACE)
    target_include_directories("${rapidjson_name}" INTERFACE "${rapidjson_source}/include")
    add_dependencies("${rapidjson_name}" "${pkg_name}")
    # set include
    set("${rapidjson_name}-includes" "${rapidjson_source}/include" PARENT_SCOPE)
endfunction()

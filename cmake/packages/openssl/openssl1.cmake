include(ExternalProject)

# guess target file name
function(guess_binary_file)
    # params
    cmake_parse_arguments(file "" "name;prefix;remove_prefix;suffix;remove_suffix" "" ${ARGN})
    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        if(MSVC)
            set(lib_file_default_extension ".lib")
            set(lib_file_default_prefix "")
            set(lib_file_default_suffix "")
            set(bin_file_default_extension ".dll")
            set(bin_file_default_prefix "")
            set(bin_file_default_suffix "")
        elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(lib_file_default_extension ".a")
            set(lib_file_default_prefix "lib")
            set(lib_file_default_suffix ".dll")
            set(bin_file_default_extension ".dll")
            set(bin_file_default_prefix "lib")
            set(bin_file_default_suffix "")
        elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
            message(FATAL_ERROR "TODO Setting ...")
        else()
            message(FATAL_ERROR "TODO Setting ...")
        endif()
    elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
        if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(lib_file_default_extension ".a")
            set(lib_file_default_prefix "lib")
            set(lib_file_default_suffix "")
            set(bin_file_default_extension "so")
            set(bin_file_default_prefix "lib")
            set(bin_file_default_suffix "")
        endif()
    elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
        message(FATAL_ERROR "TODO Setting ...")
    else()
        message(FATAL_ERROR "TODO Setting ...")
    endif()
    set(lib_file_default_prefix "${file_prefix}")
    set(lib_file_default_suffix "${file_suffix}")
    set(bin_file_default_prefix "${file_prefix}")
    set(bin_file_default_suffix "${file_suffix}")
    if(file_remove_prefix)
        set(lib_file_default_prefix "")
        set(bin_file_default_prefix "")
    endif()
    if(file_remove_suffix)
        set(lib_file_default_suffix "")
        set(bin_file_default_suffix "")
    endif()
    set("${file_name}_lib" "${file_prefix}${file_name}${file_suffix}${lib_file_default_extension}" PARENT_SCOPE)
    set("${file_name}_bin" "${file_prefix}${file_name}${file_suffix}${bin_file_default_extension}" PARENT_SCOPE)
endfunction()

# name:     target name
# prefix:   prefix path
# version:  packages version
# deps:     deps target
# nasm:     nasm path dir
# perl:     perl path dir
# ARGN: this will add this to build cmake args
#   ENABLE_LIB_ONLY:    ON
function(add_openssl1)
    # params
    cmake_parse_arguments(openssl1 "" "name;prefix;version;nasm;perl" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${openssl1_name}" OR (DEFINED "${openssl1_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${openssl1_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "openssl1_build_shared" args_list_name "openssl1_UNPARSED_ARGUMENTS")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "openssl1_build_type" args_list_name "openssl1_UNPARSED_ARGUMENTS")
    # address
    set(openssl1_repository_url        "https://github.com/openssl/openssl")
    list(APPEND openssl1_version_list  "1.0.8" "1.0.7")
    list(APPEND openssl1_hash_list     "2812E6714336121C48B5F20F7D9A45C4F3DA9E736FB3586218055C1CED23EA2C"
                                    "EB98DDFA88F2A48E5DA2AEAAAD49767D78183064C666CBB7BA54675BE5593CC1")
    # input version is in version list
    string(STRIP "${openssl1_version}" openssl1_version)
    if("${openssl1_version}" STREQUAL "")
        set(openssl1_version_index 0)
    else()
        list(FIND openssl1_version_list "${openssl1_version}" openssl1_version_index)
    endif()
    if(openssl1_version_index GREATER_EQUAL 0)
        set(openssl1_url   "${openssl1_repository_url}/-/archive/openssl1-${openssl1_version}/openssl1-openssl1-${openssl1_version}.zip")
        set(openssl1_file  "openssl1-${openssl1_version}.zip")
        list(GET openssl1_hash_list ${openssl1_version_index} openssl1_hash)
    endif()
    # set build path
    set(openssl1_download  "${openssl1_prefix}/cache/download")
    set(openssl1_install   "${openssl1_prefix}/cache/install/${openssl1_name}/${openssl1_build_type}")
    set(openssl1_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(openssl1_source    "${openssl1_prefix}/${openssl1_name}")
    set(openssl1_patch     "${openssl1_prefix}/cache/patch/${openssl1_name}")
    if(MSVC)
        set(openssl1_binary "${openssl1_prefix}/cache/bin/${openssl1_name}")
    else()
        set(openssl1_binary "${openssl1_prefix}/cache/bin/${openssl1_name}/${openssl1_build_type}")
    endif()
    # build option
    set(openssl1_cmake_options # default build lib only
                            "-DENABLE_LIB_ONLY=ON"
                            # default set shared/static
                            "-DBUILD_SHARED_LIBS=${openssl1_build_shared}"
                            # default set debug/release
                            "-DCMAKE_BUILD_TYPE=${openssl1_build_type}"
                            # default set lib/exe build path
                            "-DLIBRARY_OUTPUT_PATH='${openssl1_binary}'"
                            "-DEXECUTABLE_OUTPUT_PATH='${openssl1_binary}'"
                            "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${openssl1_binary}'"
                            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${openssl1_binary}'"
                            "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${openssl1_binary}'"
                            # default set lib install path
                            "-DCMAKE_INSTALL_PREFIX='${openssl1_install}'"
                            "-DCMAKE_INSTALL_LIBDIR='${openssl1_install}/lib'"
                            "-DCMAKE_INSTALL_BINDIR='${openssl1_install}/bin'"
                            "-DCMAKE_INSTALL_INCLUDEDIR='${openssl1_install}/include'"
                            # default set compile flags
                            "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                            "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                            "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                            "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                            "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                            "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("openssl1_UNPARSED_ARGUMENTS" "openssl1_cmake_options")
    # is install
    if(MSVC)
        set(openssl1_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${openssl1_build}" --config "${openssl1_build_type}")
        set(openssl1_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${openssl1_build}" --config "${openssl1_build_type}" --target INSTALL)
    endif()
    # set git config
    if(NOT ("" STREQUAL "${openssl1_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${openssl1_proxy} https.proxy=${openssl1_proxy})
    endif()
    # set url option
    if(${openssl1_version_index} GREATER_EQUAL 0)
        set(openssl1_url_option URL "${openssl1_url}" URL_HASH SHA256=${openssl1_hash} DOWNLOAD_NAME "${openssl1_file}")
    else()
        set(openssl1_url_option    GIT_REPOSITORY "${openssl1_repository_url}" GIT_TAG "${openssl1_version}"
                                GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # patch
    set(openssl1_patch_file "${openssl1_patch}/patch.cmake")
    openssl1_patch_script(script "${openssl1_patch_file}" source "${openssl1_source}" python "${openssl1_python}")
    set(openssl1_patch_cmd PATCH_COMMAND COMMAND "${CMAKE_COMMAND}" -P "${openssl1_patch_file}")
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${openssl1_download}" SOURCE_DIR "${openssl1_source}"
                                        ${openssl1_url_option} CMAKE_ARGS ${openssl1_cmake_options} EXCLUDE_FROM_ALL ON
                                        ${openssl1_patch_cmd} ${openssl1_build_cmd} ${openssl1_install_cmd} DEPENDS ${openssl1_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # check is build shared/static
    if(openssl1_build_shared)
        add_library("${openssl1_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${openssl1_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${openssl1_name}" "${pkg_name}")
    # set lib path dir
    set("${openssl1_name}-includes"    "${openssl1_install}/include"          PARENT_SCOPE)
    set("${openssl1_name}-pkgconfig"   "${openssl1_install}/lib/pkgconfig"    PARENT_SCOPE)
    set("${openssl1_name}-root"        "${openssl1_install}"                  PARENT_SCOPE)
    set(lib_path "${openssl1_install}/lib")
    set(bin_path "${openssl1_install}/lib")
    guess_binary_file(name "bz2")
    set_target_properties("${openssl1_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${bz2_lib}")
    if(openssl1_build_shared)
        set_target_properties("${openssl1_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${bz2_bin}")
    endif()
endfunction()

include(ExternalProject)

# install libzip script
# script:   script file save path
# source:   source code path
# zlib:     zlib path dir
# bzip2:    bzip2 path dir
function(libzip_patch_script)
    # params
    cmake_parse_arguments(libzip "" "script;source;zlib;bzip2" "" ${ARGN})
    # set params
    set(script_content "\
# set info
set(source  \"${libzip_source}\")
set(zlib    \"${libzip_zlib}\")
set(bzip2   \"${libzip_bzip2}\")
")
    string(APPEND script_content [[
# write CMakeLists.txt content
set(regex_string "include(CheckFunctionExists)")
string(APPEND replace_content "${regex_string}\n")
file(READ "${source}/CMakeLists.txt" old_content)
if(NOT ("" STREQUAL "${zlib}"))
    string(APPEND replace_content "set(ZLIB_ROOT \"${zlib}\")\n")
endif()
if(NOT ("" STREQUAL "${bzip2}"))
    string(APPEND replace_content "set(ENV{PATH} \"${bzip2};\$ENV{PATH}\")\n")
endif()
string(REPLACE "${regex_string}" "${replace_content}" new_content "${old_content}")
file(WRITE "${source}/CMakeLists.txt" "${new_content}")
]])
    if(NOT EXISTS "${libzip_script}" OR IS_DIRECTORY "${libzip_script}")
        file(WRITE "${libzip_script}" "${script_content}")
    endif()
endfunction()

# check and get cmake args params
# parameter:    check cmake parameter
# default:      default value
# result:       return value
function(get_cmake_args)
    # get other paramers
    cmake_parse_arguments(prefix "" "arg;default;result;args_list_name" "args_list" ${ARGN})
    # to toupper
    string(TOUPPER "${prefix_arg}" upper_arg)
    # get paramer length
    foreach(item IN LISTS prefix_args_list "${prefix_args_list_name}" prefix_UNPARSED_ARGUMENTS)
        list(APPEND cmake_args_list "${item}")
    endforeach()
    list(LENGTH cmake_args_list cmake_args_length)
    # get last index
    math(EXPR cmake_args_last_index "${cmake_args_length} - 1")
    # loop
    while(cmake_args_last_index GREATER -1)
        # get item
        list(GET cmake_args_list ${cmake_args_last_index} item)
        # to toupper
        string(TOUPPER "${item}" upper_item)
        # regex match
        string(REGEX MATCH "-D( *)?${upper_arg}( *)?=(.*)?" match_result "${upper_item}")
        if(match_result)
            # find = index
            string(FIND "${item}" "=" equal_index)
            # get length
            string(LENGTH "${item}" item_length)
            # start index
            math(EXPR equal_index "${equal_index} + 1")
            # substring length
            math(EXPR substring_length "${item_length} - ${equal_index}")
            # substring
            string(SUBSTRING "${item}" ${equal_index} ${substring_length} "${prefix_result}")
            string(STRIP "${${prefix_result}}" "${prefix_result}")
            # string(REPLACE "'"  "" "${prefix_result}" "${${prefix_result}}")
            # string(REPLACE "\"" "" "${prefix_result}" "${${prefix_result}}")
            set("${prefix_result}_FOUND" "YES" PARENT_SCOPE)
            set("${prefix_result}" "${${prefix_result}}" PARENT_SCOPE)
            return()
        endif()
        # index--
        math(EXPR cmake_args_last_index "${cmake_args_last_index} - 1")
    endwhile()
    set("${prefix_result}" "${prefix_default}" PARENT_SCOPE)
endfunction()

# replace repeat cmake args
# replace_list: need replace list name
# source_list:  need change list name
function(replace_cmake_args replace_list source_list)
    foreach(item IN LISTS "${replace_list}")
        string(STRIP "${item}" item)
        # to toupper
        string(TOUPPER "${item}" item)
        # regex match
        string(REGEX MATCH "-D(.*)?=(.*)?" match_result "${item}")
        if(match_result)
            # find = index
            string(FIND "${item}" "=" equal_index)
            # substring length
            math(EXPR substring_length "${equal_index} - 2")
            # substring
            string(SUBSTRING "${item}" 2 ${substring_length} cmake_args_tmp)
            string(STRIP "${cmake_args_tmp}" cmake_args_tmp)
            # is repeat
            foreach(source_item IN LISTS "${source_list}")
                string(TOUPPER "${source_item}" upper_source_item)
                # regex match
                string(REGEX MATCH "-D( *)?${cmake_args_tmp}( *)?=(.*)?" match_result "${upper_source_item}")
                if(match_result)
                    list(APPEND replace_list_tmp "${source_item}")
                endif()
            endforeach()
        endif()
    endforeach()
    # remove
    foreach(item IN LISTS replace_list_tmp)
        list(REMOVE_ITEM "${source_list}" "${item}")
    endforeach()
    # replace
    foreach(item IN LISTS "${replace_list}")
        list(APPEND "${source_list}" "${item}")
    endforeach()
    set("${source_list}" "${${source_list}}" PARENT_SCOPE)
endfunction()

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
# zlib:     zlib path dir
# bzip2:    bzip2 path dir
# ARGN: this will add this to build cmake args
#   ENABLE_COMMONCRYPTO:    OFF
#   ENABLE_GNUTLS:          OFF
#   ENABLE_MBEDTLS:         OFF
#   ENABLE_OPENSSL:         OFF
#   ENABLE_WINDOWS_CRYPTO:  OFF
#   ENABLE_BZIP2:           OFF
#   ENABLE_LZMA:            OFF
#   ENABLE_ZSTD:            OFF
#   ENABLE_FDOPEN:          ON
#   BUILD_TOOLS:            OFF
#   BUILD_REGRESS:          OFF
#   BUILD_EXAMPLES:         OFF
#   BUILD_DOC:              OFF
#   BUILD_SHARED_LIBS:      ON
#   LIBZIP_DO_INSTALL:      ON
#   SHARED_LIB_VERSIONNING: OFF
function(add_libzip)
    # params
    cmake_parse_arguments(libzip "" "name;prefix;version;proxy;zlib;bzip2" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${libzip_name}" OR (DEFINED "${libzip_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${libzip_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "libzip_build_shared" args_list_name "libzip_UNPARSED_ARGUMENTS")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "libzip_build_type" args_list_name "libzip_UNPARSED_ARGUMENTS")
    # address
    set(libzip_repository_url       "https://github.com/nih-at/libzip")
    list(APPEND libzip_version_list "1.10.1" "1.10.0")
    list(APPEND libzip_hash_list    "9669AE5DFE3AC5B3897536DC8466A874C8CF2C0E3B1FDD08D75B273884299363"
                                    "52A60B46182587E083B71E2B82FCAABA64DD5EB01C5B1F1BC71069A3858E40FE")
    # input version is in version list
    string(STRIP "${libzip_version}" libzip_version)
    if("${libzip_version}" STREQUAL "")
        set(libzip_version_index 0)
    else()
        list(FIND libzip_version_list "${libzip_version}" libzip_version_index)
    endif()
    if(libzip_version_index GREATER_EQUAL 0)
        set(libzip_url   "${libzip_repository_url}/releases/download/v${libzip_version}/libzip-${libzip_version}.tar.gz")
        set(libzip_file  "libzip-${libzip_version}.tar.gz")
        list(GET libzip_hash_list ${libzip_version_index} libzip_hash)
    endif()
    # set build path
    set(libzip_download  "${libzip_prefix}/cache/download")
    set(libzip_install   "${libzip_prefix}/cache/install/${libzip_name}/${libzip_build_type}")
    set(libzip_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(libzip_source    "${libzip_prefix}/${libzip_name}")
    set(libzip_patch     "${libzip_prefix}/cache/patch/${libzip_name}")
    if(MSVC)
        set(libzip_binary "${libzip_prefix}/cache/bin/${libzip_name}")
    else()
        set(libzip_binary "${libzip_prefix}/cache/bin/${libzip_name}/${libzip_build_type}")
    endif()
    # build option
    set(libzip_cmake_options    # default build TLS/SSL OFF
                                "-DENABLE_GNUTLS=OFF"
                                "-DENABLE_MBEDTLS=OFF"
                                "-DENABLE_OPENSSL=OFF"
                                # default build OFF
                                "-DENABLE_COMMONCRYPTO=OFF"
                                "-DENABLE_WINDOWS_CRYPTO=OFF"
                                "-DENABLE_BZIP2=OFF"
                                "-DENABLE_LZMA=OFF"
                                "-DENABLE_ZSTD=OFF"
                                "-DBUILD_TOOLS=OFF"
                                "-DBUILD_REGRESS=OFF"
                                "-DBUILD_EXAMPLES=OFF"
                                "-DBUILD_DOC=OFF"
                                "-DSHARED_LIB_VERSIONNING=OFF"
                                # default set shared/static
                                "-DBUILD_SHARED_LIBS=${libzip_build_shared}"
                                # default set debug/release
                                "-DCMAKE_BUILD_TYPE=${libzip_build_type}"
                                # default set lib/exe build path
                                "-DLIBRARY_OUTPUT_PATH='${libzip_binary}'"
                                "-DEXECUTABLE_OUTPUT_PATH='${libzip_binary}'"
                                "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${libzip_binary}'"
                                "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${libzip_binary}'"
                                "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${libzip_binary}'"
                                # default set lib install path
                                "-DCMAKE_INSTALL_PREFIX='${libzip_install}'"
                                "-DCMAKE_INSTALL_LIBDIR='${libzip_install}/lib'"
                                "-DCMAKE_INSTALL_BINDIR='${libzip_install}/bin'"
                                "-DCMAKE_INSTALL_INCLUDEDIR='${libzip_install}/include'"
                                # default set compile flags
                                "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                                "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                                "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                                "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                                "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                                "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("libzip_UNPARSED_ARGUMENTS" "libzip_cmake_options")
    # is install
    if(MSVC)
        set(libzip_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${libzip_build}" --config "${libzip_build_type}")
        set(libzip_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${libzip_build}" --config "${libzip_build_type}" --target INSTALL)
    endif()
    # set git config
    if(NOT ("" STREQUAL "${libzip_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${libzip_proxy} https.proxy=${libzip_proxy})
    endif()
    # set url option
    if(${libzip_version_index} GREATER_EQUAL 0)
        set(libzip_url_option URL "${libzip_url}" URL_HASH SHA256=${libzip_hash} DOWNLOAD_NAME "${libzip_file}")
    else()
        set(libzip_url_option   GIT_REPOSITORY "${libzip_repository_url}" GIT_TAG "${libzip_version}"
                                GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # patch
    set(libzip_patch_file "${libzip_patch}/patch.cmake")
    libzip_patch_script(script "${libzip_patch_file}" source "${libzip_source}" zlib "${libzip_zlib}" bzip2 "${libzip_bzip2}")
    set(libzip_patch_cmd PATCH_COMMAND COMMAND "${CMAKE_COMMAND}" -P "${libzip_patch_file}")
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${libzip_download}" SOURCE_DIR "${libzip_source}"
                                        ${libzip_url_option} CMAKE_ARGS ${libzip_cmake_options} EXCLUDE_FROM_ALL ON
                                        ${libzip_patch_cmd} ${libzip_build_cmd} ${libzip_install_cmd} DEPENDS ${libzip_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # check is build shared/static
    if(libzip_build_shared)
        add_library("${libzip_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${libzip_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${libzip_name}" "${pkg_name}")
    # set lib path dir
    set("${libzip_name}-includes"   "${libzip_install}/include"             PARENT_SCOPE)
    set("${libzip_name}-cmake"      "${libzip_install}/lib/cmake/libzip"    PARENT_SCOPE)
    set("${libzip_name}-pkgconfig"  "${libzip_install}/pkgconfig"           PARENT_SCOPE)
    set("${libzip_name}-root"       "${libzip_install}"                     PARENT_SCOPE)
    set(lib_path "${libzip_install}/lib")
    set(bin_path "${libzip_install}/bin")
    guess_binary_file(name "zip")
    set_target_properties("${libzip_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${zip_lib}")
    if(libzip_build_shared)
        set_target_properties("${libzip_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${zip_bin}")
    endif()
endfunction()

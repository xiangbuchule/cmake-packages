include(ExternalProject)

# install libarchive script
# script:   script file save path
# source:   source code path
# zlib:     zlib path dir
# bzip2:    bzip2 path dir
function(libarchive_patch_script)
    # params
    cmake_parse_arguments(libarchive "" "script;source;openssl;zlib;bzip2" "" ${ARGN})
    # set params
    set(script_content "\
# set info
set(source  \"${libarchive_source}\")
set(openssl \"${libarchive_openssl}\")
set(zlib    \"${libarchive_zlib}\")
set(bzip2   \"${libarchive_bzip2}\")
")
    string(APPEND script_content [[

# write CMakeLists.txt content
file(READ "${source}/CMakeLists.txt" content)

set(regex_string "PROJECT(libarchive C)")
string(APPEND replace_content "${regex_string}\n")
if(NOT ("" STREQUAL "${openssl}"))
    string(APPEND replace_content "set(OPENSSL_ROOT_DIR \"${openssl}\")\n")
endif()
if(NOT ("" STREQUAL "${zlib}"))
    string(APPEND replace_content "set(ZLIB_ROOT \"${zlib}\")\n")
endif()
if(NOT ("" STREQUAL "${bzip2}"))
    string(APPEND replace_content "set(ENV{PATH} \"${bzip2};\$ENV{PATH}\")\n")
endif()
string(REPLACE "${regex_string}" "${replace_content}" content "${content}")

set(regex_string "option(BUILD_SHARED_LIBS \"Build shared libraries\" ON)")
set(replace_content "${regex_string}\noption(INSTALL_DOCS \"Install docs\" OFF)")
string(REPLACE "${regex_string}" "${replace_content}" content "${content}")

set(regex_string "IF(EXISTS \${CMAKE_CURRENT_SOURCE_DIR}/doc/pdf)")
set(replace_content "IF(EXISTS \${CMAKE_CURRENT_SOURCE_DIR}/doc/pdf AND INSTALL_DOCS)")
string(REPLACE "${regex_string}" "${replace_content}" content "${content}")

set(regex_string "    INSTALL(FILES \${_man} DESTINATION \"share/man/man\${_mansect}\")")
set(replace_content "    IF(INSTALL_DOCS)\n    ${regex_string}\n    ENDIF(INSTALL_DOCS)")
string(REPLACE "${regex_string}" "${replace_content}" content "${content}")

file(WRITE "${source}/CMakeLists.txt" "${content}")
]])
    file(WRITE "${libarchive_script}" "${script_content}")
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
#   name:       binary name
#   lib_prefix: lib prefix name
#   lib_suffix: lib suffix name
#   bin_prefix: bin prefix name
#   bin_suffix: bin suffix name
function(guess_binary_file)
    # params
    cmake_parse_arguments(file "" "name;lib_prefix;lib_suffix;bin_prefix;bin_suffix" "" ${ARGN})
    # set default
    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        if(MSVC)
            set(lib_extension ".lib")
            set(bin_extension ".dll")
        elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(lib_extension ".a")
            set(lib_prefix "lib")
            set(lib_suffix ".dll")
            set(bin_extension ".dll")
            set(bin_prefix "lib")
        elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
            message(FATAL_ERROR "TODO Setting ...")
        else()
            message(FATAL_ERROR "TODO Setting ...")
        endif()
    elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
        if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(lib_extension ".a")
            set(lib_prefix "lib")
            set(bin_extension ".so")
            set(lib_prefix "lib")
        endif()
    elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
        message(FATAL_ERROR "TODO Setting ...")
    else()
        message(FATAL_ERROR "TODO Setting ...")
    endif()
    # set prefix/suffix
    if(NOT ("${lib_prefix}" STREQUAL "${file_lib_prefix}"))
        set(lib_prefix "${file_lib_prefix}")
    endif()
    if(NOT ("${lib_suffix}" STREQUAL "${file_lib_suffix}"))
        set(lib_suffix "${file_lib_suffix}")
    endif()
    if(NOT ("${bin_prefix}" STREQUAL "${file_bin_prefix}"))
        set(bin_prefix "${file_bin_prefix}")
    endif()
    if(NOT ("${bin_suffix}" STREQUAL "${file_bin_suffix}"))
        set(bin_suffix "${file_bin_suffix}")
    endif()
    set("${file_name}_lib" "${lib_prefix}${file_name}${lib_suffix}${lib_extension}" PARENT_SCOPE)
    set("${file_name}_bin" "${bin_prefix}${file_name}${bin_suffix}${bin_extension}" PARENT_SCOPE)
endfunction()

# operate list some regex item
# names:    list var names
# regex:    regex rules
# replace:  replace contents
# remove:   remove not regex item
# option:   operate option (replace,remove,replace_regex,replace_not_regex)
#   FIND:               find regex item
#   FIND_NOT_REGEX:     find not regex item
#   REPLACE:            replace this item all content
#   REPLACE_REGEX:      just replace this item regex content
#   REPLACE_NOT_REGEX:  just replace this item not regex content
function(replace_list)
    # params
    cmake_parse_arguments(list "" "option;regex;replace;remove" "names" ${ARGN})
    set(default_option_list "FIND" "FIND_NOT_REGEX"
                            "REPLACE" "REPLACE_REGEX" "REPLACE_NOT_REGEX")
    # get option
    string(STRIP "${list_option}" list_option)
    string(TOUPPER "${list_option}" list_option)
    if("" STREQUAL "${list_option}")
        set(list_option "FIND")
    else()
        list(FIND default_option_list "${list_option}" option_index)
        if(${option_index} LESS 0)
            set(list_option "FIND")
        endif()
    endif()
    if("FIND_NOT_REGEX" STREQUAL "${list_option}")
        set(list_remove OFF)
    endif()
    # foreach
    foreach(list_name IN LISTS list_names list_UNPARSED_ARGUMENTS)
        foreach(item IN LISTS "${list_name}")
            # is match
            string(REGEX MATCHALL "${list_regex}" match_result "${item}")
            if((match_result AND ("FIND_NOT_REGEX" STREQUAL "${list_option}")) OR
                (NOT match_result AND ("FIND" STREQUAL "${list_option}" OR list_remove)))
                continue()
            endif()
            if(match_result AND "REPLACE" STREQUAL "${list_option}")
                set(item "${list_replace}")
            endif()
            if(match_result AND "REPLACE_REGEX" STREQUAL "${list_option}")
                string(REGEX REPLACE "${list_regex}" "${list_replace}" item "${item}")
            endif()
            if(match_result AND "REPLACE_NOT_REGEX" STREQUAL "${list_option}")
                string(REGEX REPLACE "${list_regex}" ";" item_list "${item}")
                if(POLICY CMP0007)
                    cmake_policy(SET CMP0007 NEW)
                endif()
                list(LENGTH item_list item_list_length)
                math(EXPR item_list_length "${item_list_length} - 1")
                set(item "")
                foreach(key RANGE ${item_list_length})
                    list(GET item_list ${key} value)
                    if(${key} EQUAL ${item_list_length})
                        set(match_value "")
                    else()
                        list(GET match_result ${key} match_value)
                    endif()
                    if("" STREQUAL "${value}")
                        string(APPEND item "${match_value}")
                    else()
                        string(APPEND item "${list_replace}${match_value}")
                    endif()
                endforeach()
            endif()
            list(APPEND "${list_name}_tmp" "${item}")
        endforeach()
        set("${list_name}" "${${list_name}_tmp}" PARENT_SCOPE)
    endforeach()
endfunction()

# name:     target name
# prefix:   prefix path
# version:  packages version
# deps:     deps target
# zlib:     zlib path dir
# bzip2:    bzip2 path dir
# ARGN: this will add this to build cmake args
#   ENABLE_MBEDTLS:         OFF
#   ENABLE_NETTLE:          OFF
#   ENABLE_OPENSSL:         ON
#   ENABLE_LIBB2:           ON
#   ENABLE_LZ4:             ON
#   ENABLE_LZO:             OFF
#   ENABLE_LZMA:            ON
#   ENABLE_ZSTD:            ON
#   ENABLE_ZLIB:            ON
#   ENABLE_BZip2:           ON
#   ENABLE_LIBXML2:         ON
#   ENABLE_EXPAT:           ON
#   ENABLE_PCREPOSIX:       ON
#   ENABLE_PCRE2POSIX:      ON
#   ENABLE_LIBGCC:          ON
#   ENABLE_CNG:             OFF
#   ENABLE_TAR:             ON
#   ENABLE_TAR_SHARED:      FALSE
#   ENABLE_CPIO:            ON
#   ENABLE_CPIO_SHARED:     FALSE
#   ENABLE_CAT:             ON
#   ENABLE_CAT_SHARED:      FALSE
#   ENABLE_UNZIP:           ON
#   ENABLE_UNZIP_SHARED:    FALSE
#   ENABLE_XATTR:           ON
#   ENABLE_ACL:             ON
#   ENABLE_ICONV:           ON
#   ENABLE_TEST:            OFF
#   ENABLE_COVERAGE:        FALSE
#   ENABLE_INSTALL:         ON
#   INSTALL_DOCS:           OFF
function(add_libarchive)
    # params
    cmake_parse_arguments(libarchive "" "name;prefix;version;proxy;openssl;zlib;bzip2" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${libarchive_name}" OR (DEFINED "${libarchive_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${libarchive_name}")
    # remove some option
    replace_list(option "FIND_NOT_REGEX" regex "-D( *)?ENABLE_INSTALL( *)?=(.*)?" replace "" remove OFF
                names libarchive_UNPARSED_ARGUMENTS)
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "libarchive_build_shared" args_list_name "libarchive_UNPARSED_ARGUMENTS")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "libarchive_build_type" args_list_name "libarchive_UNPARSED_ARGUMENTS")
    # address
    set(libarchive_repository_url       "https://github.com/libarchive/libarchive")
    list(APPEND libarchive_version_list "3.7.2")
    list(APPEND libarchive_hash_list    "7A47337F6B36BC396C13843E0DC5C4C276CF0E862A8ECD9FDC5AE192F7712642")
    # input version is in version list
    string(STRIP "${libarchive_version}" libarchive_version)
    if("${libarchive_version}" STREQUAL "")
        set(libarchive_version_index 0)
    else()
        list(FIND libarchive_version_list "${libarchive_version}" libarchive_version_index)
    endif()
    if(libarchive_version_index GREATER_EQUAL 0)
        set(libarchive_url   "${libarchive_repository_url}/releases/download/v${libarchive_version}/libarchive-${libarchive_version}.zip")
        set(libarchive_file  "libarchive-${libarchive_version}.zip")
        list(GET libarchive_hash_list ${libarchive_version_index} libarchive_hash)
    endif()
    # set build path
    set(libarchive_download  "${libarchive_prefix}/cache/download")
    set(libarchive_install   "${libarchive_prefix}/cache/install/${libarchive_name}/${libarchive_build_type}")
    set(libarchive_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(libarchive_source    "${libarchive_prefix}/${libarchive_name}")
    set(libarchive_patch     "${libarchive_prefix}/cache/patch/${libarchive_name}")
    if(MSVC)
        set(libarchive_binary "${libarchive_prefix}/cache/bin/${libarchive_name}")
    else()
        set(libarchive_binary "${libarchive_prefix}/cache/bin/${libarchive_name}/${libarchive_build_type}")
    endif()
    # build option
    set(libarchive_cmake_options    # default build option
                                    "-DENABLE_TAR=OFF"
                                    "-DENABLE_CPIO=OFF"
                                    "-DENABLE_CAT=OFF"
                                    "-DENABLE_TEST=OFF"
                                    "-DINSTALL_DOCS=OFF"
                                    # default set shared/static
                                    "-DBUILD_SHARED_LIBS=${libarchive_build_shared}"
                                    # default set debug/release
                                    "-DCMAKE_BUILD_TYPE=${libarchive_build_type}"
                                    # default set lib/exe build path
                                    "-DLIBRARY_OUTPUT_PATH='${libarchive_binary}'"
                                    "-DEXECUTABLE_OUTPUT_PATH='${libarchive_binary}'"
                                    "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${libarchive_binary}'"
                                    "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${libarchive_binary}'"
                                    "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${libarchive_binary}'"
                                    # default set lib install path
                                    "-DCMAKE_INSTALL_PREFIX='${libarchive_install}'"
                                    "-DCMAKE_INSTALL_LIBDIR='${libarchive_install}/lib'"
                                    "-DCMAKE_INSTALL_BINDIR='${libarchive_install}/bin'"
                                    "-DCMAKE_INSTALL_INCLUDEDIR='${libarchive_install}/include'"
                                    # default set compile flags
                                    "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                                    "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                                    "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                                    "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                                    "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                                    "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("libarchive_UNPARSED_ARGUMENTS" "libarchive_cmake_options")
    # is install
    if(MSVC)
        set(libarchive_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${libarchive_build}" --config "${libarchive_build_type}")
        set(libarchive_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${libarchive_build}" --config "${libarchive_build_type}" --target INSTALL)
    endif()
    # set git config
    if(NOT ("" STREQUAL "${libarchive_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${libarchive_proxy} https.proxy=${libarchive_proxy})
    endif()
    # set url option
    if(${libarchive_version_index} GREATER_EQUAL 0)
        set(libarchive_url_option URL "${libarchive_url}" URL_HASH SHA256=${libarchive_hash} DOWNLOAD_NAME "${libarchive_file}")
    else()
        set(libarchive_url_option   GIT_REPOSITORY "${libarchive_repository_url}" GIT_TAG "${libarchive_version}"
                                    GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # patch
    set(libarchive_patch_file "${libarchive_patch}/patch.cmake")
    libarchive_patch_script(
        script "${libarchive_patch_file}" source "${libarchive_source}"
        openssl "${libarchive_openssl}" zlib "${libarchive_zlib}" bzip2 "${libarchive_bzip2}"
    )
    set(libarchive_patch_cmd PATCH_COMMAND COMMAND "${CMAKE_COMMAND}" -P "${libarchive_patch_file}")
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${libarchive_download}" SOURCE_DIR "${libarchive_source}"
                                        ${libarchive_url_option} CMAKE_ARGS ${libarchive_cmake_options} EXCLUDE_FROM_ALL ON
                                        ${libarchive_patch_cmd} ${libarchive_build_cmd} ${libarchive_install_cmd} DEPENDS ${libarchive_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # set lib path dir
    set("${libarchive_name}-includes"   "${libarchive_install}/include"         PARENT_SCOPE)
    set("${libarchive_name}-pkgconfig"  "${libarchive_install}/lib/pkgconfig"   PARENT_SCOPE)
    set("${libarchive_name}-root"       "${libarchive_install}"                 PARENT_SCOPE)
    set("${libarchive_name}-source"     "${libarchive_source}"                  PARENT_SCOPE)
    set(lib_path "${libarchive_install}/lib")
    set(bin_path "${libarchive_install}/bin")
    # check is build shared/static
    if(libarchive_build_shared)
        add_library("${libarchive_name}::shared" SHARED IMPORTED GLOBAL)
        add_dependencies("${libarchive_name}::shared" "${pkg_name}")
        guess_binary_file(name "archive")
        set_target_properties("${libarchive_name}::shared" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${archive_lib}")
        set_target_properties("${libarchive_name}::shared" PROPERTIES IMPORTED_LOCATION "${bin_path}/${archive_bin}")
    endif()
    add_library("${libarchive_name}::static" STATIC IMPORTED GLOBAL)
    add_dependencies("${libarchive_name}::static" "${pkg_name}")
    guess_binary_file(name "archive_static")
    set_target_properties("${libarchive_name}::static" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${archive_static_lib}")
endfunction()

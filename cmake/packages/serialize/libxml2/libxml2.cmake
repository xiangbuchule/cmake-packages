include(ExternalProject)

# install libxml2 script
# script:   script file save path
# source:   source code path
# lzma:     lzma path dir
function(libxml2_patch_script)
    # params
    cmake_parse_arguments(libxml2 "" "script;source;lzma" "" ${ARGN})
    # set params
    set(script_content "\
# set info
set(source  \"${libxml2_source}\")
set(lzma    \"${libxml2_lzma}\")
")
    string(APPEND script_content [[
# write CMakeLists.txt content
file(READ "${source}/CMakeLists.txt" content)
set(regex_string "project(libxml2 VERSION \${VERSION} LANGUAGES C)")
set(replace_content "set(ENV{PATH} \"${lzma};\$ENV{PATH}\")")
string(REPLACE "${regex_string}" "${regex_string}\n${replace_content}" content "${content}")
set(regex_string "install\\(FILES doc/xml2-config.* EXCLUDE\\)")
string(REGEX MATCH "${regex_string}" install_content "${content}")
string(REPLACE "	" "		" install_content "${install_content}")
string(REPLACE ")\n" ";" install_content "${install_content}")
string(REGEX REPLACE "(^;)|(;$)" "" install_content "${install_content}")
list(JOIN install_content ")\n	" install_content)
string(REGEX REPLACE "${regex_string}" "if(BUILD_DOCS)\n	${install_content}\nendif()" content "${content}")
file(WRITE "${source}/CMakeLists.txt" "${content}")
]])
    file(WRITE "${libxml2_script}" "${script_content}")
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

# name:     target name
# prefix:   prefix path
# version:  packages version
# deps:     deps target
# zlib:     zlib path dir
# bzip2:    bzip2 path dir
# ARGN: this will add this to build cmake args
#   LIBXML2_WITH_TESTS:     OFF
#   LIBXML2_WITH_PYTHON:    OFF
#   LIBXML2_WITH_PROGRAMS:  OFF
#   BUILD_DOCS:             OFF
function(add_libxml2)
    # params
    cmake_parse_arguments(libxml2 "" "name;prefix;version;proxy;lzma" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${libxml2_name}" OR (DEFINED "${libxml2_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${libxml2_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "libxml2_build_shared" args_list_name "libxml2_UNPARSED_ARGUMENTS")
    if(libxml2_build_shared)
        set(libxml2_build_static OFF)
    else()
        set(libxml2_build_static ON)
    endif()
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "libxml2_build_type" args_list_name "libxml2_UNPARSED_ARGUMENTS")
    # address
    set(libxml2_repository_url          "https://gitlab.gnome.org/GNOME/libxml2")
    list(APPEND libxml2_version_list    "2.12")
    list(APPEND libxml2_hash_list       "4935AF93AA484B30DDA5DD58FCAC630F349E7C5233A053341800FC9D0176E4F1")
    # input version is in version list
    string(STRIP "${libxml2_version}" libxml2_version)
    if("${libxml2_version}" STREQUAL "")
        set(libxml2_version_index 0)
    else()
        list(FIND libxml2_version_list "${libxml2_version}" libxml2_version_index)
    endif()
    if(libxml2_version_index GREATER_EQUAL 0)
        set(libxml2_url   "${libxml2_repository_url}/-/archive/${libxml2_version}/libxml${libxml2_version}.zip")
        set(libxml2_file  "libxml2-${libxml2_version}.zip")
        list(GET libxml2_hash_list ${libxml2_version_index} libxml2_hash)
    endif()
    # set build path
    set(libxml2_download  "${libxml2_prefix}/cache/download")
    set(libxml2_install   "${libxml2_prefix}/cache/install/${libxml2_name}/${libxml2_build_type}")
    set(libxml2_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(libxml2_source    "${libxml2_prefix}/${libxml2_name}")
    set(libxml2_patch     "${libxml2_prefix}/cache/patch/${libxml2_name}")
    if(MSVC)
        set(libxml2_binary "${libxml2_prefix}/cache/bin/${libxml2_name}")
    else()
        set(libxml2_binary "${libxml2_prefix}/cache/bin/${libxml2_name}/${libxml2_build_type}")
    endif()
    # build option
    set(libxml2_cmake_options   # default options
                                "-DLIBXML2_WITH_TESTS=OFF"
                                "-DLIBXML2_WITH_PYTHON=OFF"
                                "-DLIBXML2_WITH_PROGRAMS=OFF"
                                "-DBUILD_DOCS=OFF"
                                # default set shared/static
                                "-DBUILD_SHARED_LIBS=${libxml2_build_shared}"
                                # default set debug/release
                                "-DCMAKE_BUILD_TYPE=${libxml2_build_type}"
                                # default set lib/exe build path
                                "-DLIBRARY_OUTPUT_PATH='${libxml2_binary}'"
                                "-DEXECUTABLE_OUTPUT_PATH='${libxml2_binary}'"
                                "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${libxml2_binary}'"
                                "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${libxml2_binary}'"
                                "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${libxml2_binary}'"
                                # default set lib install path
                                "-DCMAKE_INSTALL_PREFIX='${libxml2_install}'"
                                "-DCMAKE_INSTALL_LIBDIR='${libxml2_install}/lib'"
                                "-DCMAKE_INSTALL_BINDIR='${libxml2_install}/bin'"
                                "-DCMAKE_INSTALL_INCLUDEDIR='${libxml2_install}/include'"
                                # default set compile flags
                                "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                                "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                                "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                                "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                                "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                                "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("libxml2_UNPARSED_ARGUMENTS" "libxml2_cmake_options")
    # is install
    if(MSVC)
        set(libxml2_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${libxml2_build}" --config "${libxml2_build_type}")
        set(libxml2_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${libxml2_build}" --config "${libxml2_build_type}" --target INSTALL)
    endif()
    # set git config
    if(NOT ("" STREQUAL "${libxml2_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${libxml2_proxy} https.proxy=${libxml2_proxy})
    endif()
    # set url option
    if(${libxml2_version_index} GREATER_EQUAL 0)
        set(libxml2_url_option URL "${libxml2_url}" URL_HASH SHA256=${libxml2_hash} DOWNLOAD_NAME "${libxml2_file}")
    else()
        set(libxml2_url_option GIT_REPOSITORY "${libxml2_repository_url}" GIT_TAG "${libxml2_version}"
                            GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # patch
    set(libxml2_patch_file "${libxml2_patch}/patch.cmake")
    libxml2_patch_script(script "${libxml2_patch_file}" source "${libxml2_source}" lzma "${libxml2_lzma}")
    set(libxml2_patch_cmd PATCH_COMMAND COMMAND "${CMAKE_COMMAND}" -P "${libxml2_patch_file}")
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${libxml2_download}" SOURCE_DIR "${libxml2_source}"
                                        ${libxml2_url_option} CMAKE_ARGS ${libxml2_cmake_options} EXCLUDE_FROM_ALL ON
                                        ${libxml2_patch_cmd} ${libxml2_build_cmd} ${libxml2_install_cmd} DEPENDS ${libxml2_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # check is build shared/static
    if(libxml2_build_shared)
        add_library("${libxml2_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${libxml2_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${libxml2_name}" "${pkg_name}")
    # set lib path dir
    set(lib_path "${libxml2_install}/lib")
    set(bin_path "${libxml2_install}/bin")
    set("${libxml2_name}-includes"  "${libxml2_install}/include"    PARENT_SCOPE)
    set("${libxml2_name}-pkgconfig" "${lib_path}/pkgconfig"         PARENT_SCOPE)
    set("${libxml2_name}-root"      "${libxml2_install}"            PARENT_SCOPE)
    set("${libxml2_name}-source"    "${libxml2_source}"             PARENT_SCOPE)
    guess_binary_file(name "libxml2")
    set_target_properties("${libxml2_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${libxml2_lib}")
    if(libxml2_build_shared)
        set_target_properties("${libxml2_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${libxml2_bin}")
    endif()
endfunction()

include(ExternalProject)

# install bzip2 script
# script:   script file save path
# source:   source code path
# python:   python path dir
function(bzip2_patch_script)
    # params
    cmake_parse_arguments(bzip2 "" "script;source;python" "" ${ARGN})
    # set params
    set(script_content "\
# set info
set(source  \"${bzip2_source}\")
set(python  \"${bzip2_python}\")
")
    string(APPEND script_content [[
# write CMakeLists.txt content
if(NOT ("" STREQUAL "${python}"))
    set(regex_string "include_directories(\${PROJECT_BINARY_DIR})")
    string(APPEND replace_content "${regex_string}\n")
    string(APPEND replace_content "set(ENV{PATH} \"${python};\$ENV{PATH}\")")
    file(READ "${source}/CMakeLists.txt" old_content)
    string(REPLACE "${regex_string}" "${replace_content}" new_content "${old_content}")
    file(WRITE "${source}/CMakeLists.txt" "${new_content}")
endif()
]])
    if(NOT EXISTS "${bzip2_script}" OR IS_DIRECTORY "${bzip2_script}")
        file(WRITE "${bzip2_script}" "${script_content}")
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
# python:   python path dir
# ARGN: this will add this to build cmake args
#   ENABLE_LIB_ONLY:    ON
function(add_bzip2)
    # params
    cmake_parse_arguments(bzip2 "" "name;prefix;version;proxy;python" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${bzip2_name}" OR (DEFINED "${bzip2_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${bzip2_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "bzip2_build_shared" args_list_name "bzip2_UNPARSED_ARGUMENTS")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "bzip2_build_type" args_list_name "bzip2_UNPARSED_ARGUMENTS")
    # address
    set(bzip2_repository_url        "https://gitlab.com/bzip2/bzip2")
    list(APPEND bzip2_version_list  "1.0.8" "1.0.7")
    list(APPEND bzip2_hash_list     "2812E6714336121C48B5F20F7D9A45C4F3DA9E736FB3586218055C1CED23EA2C"
                                    "EB98DDFA88F2A48E5DA2AEAAAD49767D78183064C666CBB7BA54675BE5593CC1")
    # input version is in version list
    string(STRIP "${bzip2_version}" bzip2_version)
    if("${bzip2_version}" STREQUAL "")
        set(bzip2_version_index 0)
    else()
        list(FIND bzip2_version_list "${bzip2_version}" bzip2_version_index)
    endif()
    if(bzip2_version_index GREATER_EQUAL 0)
        set(bzip2_url   "${bzip2_repository_url}/-/archive/bzip2-${bzip2_version}/bzip2-bzip2-${bzip2_version}.zip")
        set(bzip2_file  "bzip2-${bzip2_version}.zip")
        list(GET bzip2_hash_list ${bzip2_version_index} bzip2_hash)
    endif()
    # set build path
    set(bzip2_download  "${bzip2_prefix}/cache/download")
    set(bzip2_install   "${bzip2_prefix}/cache/install/${bzip2_name}/${bzip2_build_type}")
    set(bzip2_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(bzip2_source    "${bzip2_prefix}/${bzip2_name}")
    set(bzip2_patch     "${bzip2_prefix}/cache/patch/${bzip2_name}")
    if(MSVC)
        set(bzip2_binary "${bzip2_prefix}/cache/bin/${bzip2_name}")
    else()
        set(bzip2_binary "${bzip2_prefix}/cache/bin/${bzip2_name}/${bzip2_build_type}")
    endif()
    # build option
    set(bzip2_cmake_options # default build lib only
                            "-DENABLE_LIB_ONLY=ON"
                            # default set shared/static
                            "-DBUILD_SHARED_LIBS=${bzip2_build_shared}"
                            # default set debug/release
                            "-DCMAKE_BUILD_TYPE=${bzip2_build_type}"
                            # default set lib/exe build path
                            "-DLIBRARY_OUTPUT_PATH='${bzip2_binary}'"
                            "-DEXECUTABLE_OUTPUT_PATH='${bzip2_binary}'"
                            "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${bzip2_binary}'"
                            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${bzip2_binary}'"
                            "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${bzip2_binary}'"
                            # default set lib install path
                            "-DCMAKE_INSTALL_PREFIX='${bzip2_install}'"
                            "-DCMAKE_INSTALL_LIBDIR='${bzip2_install}/lib'"
                            "-DCMAKE_INSTALL_BINDIR='${bzip2_install}/bin'"
                            "-DCMAKE_INSTALL_INCLUDEDIR='${bzip2_install}/include'"
                            # default set compile flags
                            "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                            "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                            "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                            "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                            "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                            "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("bzip2_UNPARSED_ARGUMENTS" "bzip2_cmake_options")
    # is install
    if(MSVC)
        set(bzip2_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${bzip2_build}" --config "${bzip2_build_type}")
        set(bzip2_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${bzip2_build}" --config "${bzip2_build_type}" --target INSTALL)
    endif()
    # set git config
    if(NOT ("" STREQUAL "${bzip2_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${bzip2_proxy} https.proxy=${bzip2_proxy})
    endif()
    # set url option
    if(${bzip2_version_index} GREATER_EQUAL 0)
        set(bzip2_url_option URL "${bzip2_url}" URL_HASH SHA256=${bzip2_hash} DOWNLOAD_NAME "${bzip2_file}")
    else()
        set(bzip2_url_option    GIT_REPOSITORY "${bzip2_repository_url}" GIT_TAG "${bzip2_version}"
                                GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # patch
    set(bzip2_patch_file "${bzip2_patch}/patch.cmake")
    bzip2_patch_script(script "${bzip2_patch_file}" source "${bzip2_source}" python "${bzip2_python}")
    set(bzip2_patch_cmd PATCH_COMMAND COMMAND "${CMAKE_COMMAND}" -P "${bzip2_patch_file}")
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${bzip2_download}" SOURCE_DIR "${bzip2_source}"
                                        ${bzip2_url_option} CMAKE_ARGS ${bzip2_cmake_options} EXCLUDE_FROM_ALL ON
                                        ${bzip2_patch_cmd} ${bzip2_build_cmd} ${bzip2_install_cmd} DEPENDS ${bzip2_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # check is build shared/static
    if(bzip2_build_shared)
        add_library("${bzip2_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${bzip2_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${bzip2_name}" "${pkg_name}")
    # set lib path dir
    set("${bzip2_name}-includes" "${bzip2_install}/include" PARENT_SCOPE)
    set("${bzip2_name}-root" "${bzip2_install}" PARENT_SCOPE)
    set(lib_path "${bzip2_install}/lib")
    set(bin_path "${bzip2_install}/lib")
    guess_binary_file(name "bz2")
    set_target_properties("${bzip2_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${bz2_lib}")
    if(bzip2_build_shared)
        set_target_properties("${bzip2_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${bz2_bin}")
    endif()
endfunction()

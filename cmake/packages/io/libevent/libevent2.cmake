include(ExternalProject)

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
# ARGN: this will add this to build cmake args
#   EVENT__DISABLE_TESTS:       ON
#   EVENT__DISABLE_REGRESS:     ON
#   EVENT__DISABLE_SAMPLES:     ON
#   EVENT__DISABLE_BENCHMARK:   ON
function(add_libevent2)
    # params
    cmake_parse_arguments(libevent2 "" "name;prefix;version;proxy" "deps" ${ARGN})
    # if target exist, return
    if(DEFINED "${libevent2_name}-includes")
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${libevent2_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "libevent2_build_shared" args_list_name "libevent2_UNPARSED_ARGUMENTS")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "libevent2_build_type" args_list_name "libevent2_UNPARSED_ARGUMENTS")
    # address
    set(libevent2_repository_url        "https://github.com/libevent/libevent")
    list(APPEND libevent2_version_list  "2.1.12")
    list(APPEND libevent2_hash_list     "8836AD722AB211DE41CB82FE098911986604F6286F67D10DFB2B6787BF418F49")
    # input version is in version list
    string(STRIP "${libevent2_version}" libevent2_version)
    if("${libevent2_version}" STREQUAL "")
        set(libevent2_version_index 0)
        list(GET libevent2_version_list ${libevent2_version_index} libevent2_version)
    else()
        list(FIND libevent2_version_list "${libevent2_version}" libevent2_version_index)
    endif()
    if(libevent2_version_index GREATER_EQUAL 0)
        set(libevent2_url   "${libevent2_repository_url}/archive/refs/tags/release-${libevent2_version}-stable.zip")
        set(libevent2_file  "libevent2-${libevent2_version}.zip")
        list(GET libevent2_hash_list ${libevent2_version_index} libevent2_hash)
    endif()
    # set build path
    set(libevent2_download  "${libevent2_prefix}/cache/download")
    set(libevent2_install   "${libevent2_prefix}/cache/install/${libevent2_name}/${libevent2_build_type}")
    set(libevent2_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(libevent2_source    "${libevent2_prefix}/${libevent2_name}")
    if(MSVC)
        set(libevent2_binary "${libevent2_prefix}/cache/bin/${libevent2_name}")
    else()
        set(libevent2_binary "${libevent2_prefix}/cache/bin/${libevent2_name}/${libevent2_build_type}")
    endif()
    # build option
    set(libevent2_cmake_options #default options
                                "-DEVENT__DISABLE_TESTS=ON"
                                "-DEVENT__DISABLE_REGRESS=ON"
                                "-DEVENT__DISABLE_SAMPLES=ON"
                                "-DEVENT__DISABLE_BENCHMARK=ON"
                                # default set shared/static
                                "-DBUILD_SHARED_LIBS=${libevent2_build_shared}"
                                # default set debug/release
                                "-DCMAKE_BUILD_TYPE=${libevent2_build_type}"
                                # default set lib/exe build path
                                "-DLIBRARY_OUTPUT_PATH='${libevent2_binary}'"
                                "-DEXECUTABLE_OUTPUT_PATH='${libevent2_binary}'"
                                "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${libevent2_binary}'"
                                "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${libevent2_binary}'"
                                "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${libevent2_binary}'"
                                # default set lib install path
                                "-DCMAKE_INSTALL_PREFIX='${libevent2_install}'"
                                "-DCMAKE_INSTALL_LIBDIR='${libevent2_install}/lib'"
                                "-DCMAKE_INSTALL_BINDIR='${libevent2_install}/bin'"
                                "-DCMAKE_INSTALL_INCLUDEDIR='${libevent2_install}/include'"
                                # default set compile flags
                                "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                                "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                                "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                                "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                                "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                                "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("libevent2_UNPARSED_ARGUMENTS" "libevent2_cmake_options")
    # is install
    if(MSVC)
        set(libevent2_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${libevent2_build}" --config "${libevent2_build_type}")
        set(libevent2_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${libevent2_build}" --config "${libevent2_build_type}" --target INSTALL)
    endif()
    # set git config
    if(NOT ("" STREQUAL "${libevent2_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${libevent2_proxy} https.proxy=${libevent2_proxy})
    endif()
    # set url option
    if(${libevent2_version_index} GREATER_EQUAL 0)
        set(libevent2_url_option URL "${libevent2_url}" URL_HASH SHA256=${libevent2_hash} DOWNLOAD_NAME "${libevent2_file}")
    else()
        set(libevent2_url_option    GIT_REPOSITORY "${libevent2_repository_url}" GIT_TAG "${libevent2_version}"
                                    GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${libevent2_download}" SOURCE_DIR "${libevent2_source}"
                                        ${libevent2_url_option} CMAKE_ARGS ${libevent2_cmake_options} EXCLUDE_FROM_ALL ON
                                        ${libevent2_build_cmd} ${libevent2_install_cmd} DEPENDS ${libevent2_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # set lib path dir
    set("${libevent2_name}-includes"    "${libevent2_install}/include"              PARENT_SCOPE)
    set("${libevent2_name}-cmake"       "${libevent2_install}/lib/cmake/libevent"   PARENT_SCOPE)
    set("${libevent2_name}-pkgconfig"   "${libevent2_install}/lib/pkgconfig"        PARENT_SCOPE)
    set("${libevent2_name}-root"        "${libevent2_install}"                      PARENT_SCOPE)
    set("${libevent2_name}-source"      "${libevent2_source}"                       PARENT_SCOPE)
    set(lib_path "${libevent2_install}/lib")
    set(bin_path "${libevent2_install}/lib")
    # check is build shared/static
    if(libevent2_build_shared)
        add_library("${libevent2_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${libevent2_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${libevent2_name}" "${pkg_name}")
    # guess file
    guess_binary_file(name "event")
    # add library
    set_target_properties("${libevent2_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${event_lib}")
    if(libevent2_build_shared)
        set_target_properties("${libevent2_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${event_bin}")
    endif()
    # set binary list
    set(binary_list "core" "extra" "openssl")
    # set target
    foreach(item IN LISTS binary_list)
        # check is build shared/static
        if(libevent2_build_shared)
            add_library("${libevent2_name}::${item}" SHARED IMPORTED GLOBAL)
        else()
            add_library("${libevent2_name}::${item}" STATIC IMPORTED GLOBAL)
        endif()
        add_dependencies("${libevent2_name}::${item}" "${pkg_name}")
        # guess file
        guess_binary_file(name "event_${item}")
        # add library
        set_target_properties("${libevent2_name}::${item}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${event_${item}_lib}")
        if(libevent2_build_shared)
            set_target_properties("${libevent2_name}::${item}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${event_${item}_bin}")
        endif()
    endforeach()
endfunction()

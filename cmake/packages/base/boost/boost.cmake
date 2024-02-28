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
#   ENABLE_LIB_ONLY:    ON
function(add_boost)
    # params
    cmake_parse_arguments(boost "" "name;prefix;version;proxy" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${boost_name}" OR (DEFINED "${boost_name}-includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${boost_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "boost_build_shared" args_list_name "boost_UNPARSED_ARGUMENTS")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "boost_build_type" args_list_name "boost_UNPARSED_ARGUMENTS")
    # address
    set(boost_repository_url        "https://github.com/boostorg/boost")
    list(APPEND boost_version_list  "1.84.0" "1.83.0" "1.77.0")
    list(APPEND boost_hash_list     "f46e9a747e0828130d37ead82b796ab82348e3a7ee688cd43b6c5f35f5e71aef"
                                    "9effa3d7f9d92b8e33e2b41d82f4358f97ff7c588d5918720339f2b254d914c6"
                                    "d2886ceff60c35fc6dc9120e8faa960c1e9535f2d7ce447469eae9836110ea77")
    # input version is in version list
    string(STRIP "${boost_version}" boost_version)
    if("${boost_version}" STREQUAL "")
        set(boost_version_index 0)
        list(GET boost_version_list ${boost_version_index} boost_version)
    else()
        list(FIND boost_version_list "${boost_version}" boost_version_index)
    endif()
    if(boost_version_index GREATER_EQUAL 0)
        string(REPLACE "." "_" boost_version_tmp "${boost_version}")
        set(boost_url   "${boost_repository_url}/releases/download/boost-${boost_version}/boost-${boost_version}.zip"
                        "https://boostorg.jfrog.io/artifactory/main/release/${boost_version}/source/boost_${boost_version_tmp}.zip")
        set(boost_file  "boost-${boost_version}.zip")
        list(GET boost_hash_list ${boost_version_index} boost_hash)
    endif()
    # set build path
    set(boost_download  "${boost_prefix}/cache/download")
    set(boost_install   "${boost_prefix}/cache/install/${boost_name}/${boost_build_type}")
    set(boost_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(boost_source    "${boost_prefix}/${boost_name}")
    if(MSVC)
        set(boost_binary "${boost_prefix}/cache/bin/${boost_name}")
    else()
        set(boost_binary "${boost_prefix}/cache/bin/${boost_name}/${boost_build_type}")
    endif()
    # build option
    set(boost_cmake_options # default set shared/static
                            "-DBUILD_SHARED_LIBS=${boost_build_shared}"
                            # default set debug/release
                            "-DCMAKE_BUILD_TYPE=${boost_build_type}"
                            # default set lib/exe build path
                            "-DLIBRARY_OUTPUT_PATH='${boost_binary}'"
                            "-DEXECUTABLE_OUTPUT_PATH='${boost_binary}'"
                            "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${boost_binary}'"
                            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${boost_binary}'"
                            "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${boost_binary}'"
                            # default set lib install path
                            "-DCMAKE_INSTALL_PREFIX='${boost_install}'"
                            "-DCMAKE_INSTALL_LIBDIR='${boost_install}/lib'"
                            "-DCMAKE_INSTALL_BINDIR='${boost_install}/bin'"
                            "-DCMAKE_INSTALL_INCLUDEDIR='${boost_install}/include'"
                            # default set compile flags
                            "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                            "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                            "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                            "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                            "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                            "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("boost_UNPARSED_ARGUMENTS" "boost_cmake_options")
    # is install
    if(MSVC)
        set(boost_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${boost_build}" --config "${boost_build_type}")
        set(boost_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${boost_build}" --config "${boost_build_type}" --target INSTALL)
    endif()
    # set git config
    if(NOT ("" STREQUAL "${boost_proxy}"))
        set(git_config GIT_CONFIG http.proxy=${boost_proxy} https.proxy=${boost_proxy})
    endif()
    # set url option
    if(${boost_version_index} GREATER_EQUAL 0)
        set(boost_url_option URL "${boost_url}" URL_HASH SHA256=${boost_hash} DOWNLOAD_NAME "${boost_file}")
    else()
        set(boost_url_option    GIT_REPOSITORY "${boost_repository_url}" GIT_TAG "${boost_version}"
                                GIT_SHALLOW ON GIT_PROGRESS OFF UPDATE_DISCONNECTED ON ${git_config})
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   DOWNLOAD_DIR "${boost_download}" SOURCE_DIR "${boost_source}"
                                        ${boost_url_option} CMAKE_ARGS ${boost_cmake_options} EXCLUDE_FROM_ALL ON
                                        ${boost_build_cmd} ${boost_install_cmd} DEPENDS ${boost_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # set custom step
    if(WIN32)
        set(bootstrap_script "${boost_source}/bootstrap.bat")
    else()
        set(bootstrap_script "${boost_source}/bootstrap.sh")
    endif()
    ExternalProject_Add_Step(
        "${pkg_name}" "${pkg_name}-bootstrap"
        COMMAND "${bootstrap_script}"
        WORKING_DIRECTORY "${boost_source}"
        DEPENDEES "update"
        DEPENDERS "patch"
        USES_TERMINAL ON
    )
    # set lib path dir
    string(REPLACE "." ";" tmp_version "${boost_version}")
    list(LENGTH tmp_version tmp_version_len)
    math(EXPR tmp_version_len "${tmp_version_len} - 1")
    list(REMOVE_AT tmp_version ${tmp_version_len})
    list(JOIN tmp_version "_" tmp_version)
    set("${boost_name}-includes"    "${boost_install}/include/boost-${tmp_version}" PARENT_SCOPE)
    set("${boost_name}-cmake"       "${boost_install}/lib/cmake"                    PARENT_SCOPE)
    set("${boost_name}-root"        "${boost_install}"                              PARENT_SCOPE)
    set("${boost_name}-source"      "${boost_source}"                               PARENT_SCOPE)
    set(lib_path "${boost_install}/lib")
    set(bin_path "${boost_install}/lib")
    if(MSVC)
        set(name_suffix "-vc${MSVC_TOOLSET_VERSION}-mt-gd-${CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE}-${tmp_version}")
    endif()
    # set binary list
    set(binary_list "atomic" "chrono" "cobalt" "container" "context"
                    "contract" "coroutine" "date_time" "fiber"
                    "fiber_numa" "filesystem" "graph" "iostreams"
                    "json" "locale" "log" "log_setup" "nowide"
                    "prg_exec_monitor" "program_options" "random" "serialization"
                    "stacktrace_basic" "stacktrace_noop" "stacktrace_windbg"
                    "stacktrace_windbg_cached" "thread" "timer" "type_erasure"
                    "unit_test_framework" "url" "wave" "wserialization"
                    "exception" "test_exec_monitor")
    # set target
    foreach(item IN LISTS binary_list)
        string(REGEX REPLACE "_" "-" binary_name "${item}")
        # check is build shared/static
        if(boost_build_shared)
            add_library("${boost_name}::${binary_name}" SHARED IMPORTED GLOBAL)
        else()
            add_library("${boost_name}::${binary_name}" STATIC IMPORTED GLOBAL)
        endif()
        add_dependencies("${boost_name}::${binary_name}" "${pkg_name}")
        # guess file
        if("${item}" STREQUAL "exception" OR "${item}" STREQUAL "test_exec_monitor")
            guess_binary_file(name "boost_${item}" lib_prefix "lib" bin_prefix "lib" lib_suffix "${name_suffix}" bin_suffix "${name_suffix}")
        else()
            guess_binary_file(name "boost_${item}" lib_suffix "${name_suffix}" bin_suffix "${name_suffix}")
        endif()
        # add library
        set_target_properties("${boost_name}::${binary_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${boost_${item}_lib}")
        if(boost_build_shared)
            set_target_properties("${boost_name}::${binary_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${boost_${item}_bin}")
        endif()
    endforeach()
endfunction()

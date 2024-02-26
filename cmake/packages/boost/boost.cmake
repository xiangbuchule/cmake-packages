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
    # check is build shared/static
    if(boost_build_shared)
        add_library("${boost_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${boost_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${boost_name}" "${pkg_name}")
    # set lib path dir
    string(REPLACE "." ";" tmp_version "${boost_version}")
    list(LENGTH tmp_version tmp_version_len)
    math(EXPR tmp_version_len "${tmp_version_len} - 1")
    list(REMOVE_AT tmp_version ${tmp_version_len})
    list(JOIN tmp_version "_" tmp_version)
    set("${boost_name}-includes"    "${boost_install}/include/boost-${tmp_version}"         PARENT_SCOPE)
    set("${boost_name}-cmake"       "${boost_install}/lib/cmake"                            PARENT_SCOPE)
    set("${boost_name}-root"        "${boost_install}"                                      PARENT_SCOPE)
    set(lib_path "${boost_install}/lib")
    set(bin_path "${boost_install}/lib")
    if(MSVC)
        set(name_suffix "-vc${MSVC_TOOLSET_VERSION}-mt-gd-${CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE}-${tmp_version}")
    endif()
    guess_binary_file(name "boost_atomic"                   suffix "${name_suffix}")
    guess_binary_file(name "boost_chrono"                   suffix "${name_suffix}")
    guess_binary_file(name "boost_cobalt"                   suffix "${name_suffix}")
    guess_binary_file(name "boost_container"                suffix "${name_suffix}")
    guess_binary_file(name "boost_context"                  suffix "${name_suffix}")
    guess_binary_file(name "boost_contract"                 suffix "${name_suffix}")
    guess_binary_file(name "boost_coroutine"                suffix "${name_suffix}")
    guess_binary_file(name "boost_date_time"                suffix "${name_suffix}")
    guess_binary_file(name "boost_fiber"                    suffix "${name_suffix}")
    guess_binary_file(name "boost_fiber_numa"               suffix "${name_suffix}")
    guess_binary_file(name "boost_filesystem"               suffix "${name_suffix}")
    guess_binary_file(name "boost_graph"                    suffix "${name_suffix}")
    guess_binary_file(name "boost_iostreams"                suffix "${name_suffix}")
    guess_binary_file(name "boost_json"                     suffix "${name_suffix}")
    guess_binary_file(name "boost_locale"                   suffix "${name_suffix}")
    guess_binary_file(name "boost_log"                      suffix "${name_suffix}")
    guess_binary_file(name "boost_log_setup"                suffix "${name_suffix}")
    guess_binary_file(name "boost_nowide"                   suffix "${name_suffix}")
    guess_binary_file(name "boost_prg_exec_monitor"         suffix "${name_suffix}")
    guess_binary_file(name "boost_program_options"          suffix "${name_suffix}")
    guess_binary_file(name "boost_random"                   suffix "${name_suffix}")
    guess_binary_file(name "boost_serialization"            suffix "${name_suffix}")
    guess_binary_file(name "boost_stacktrace_basic"         suffix "${name_suffix}")
    guess_binary_file(name "boost_stacktrace_noop"          suffix "${name_suffix}")
    guess_binary_file(name "boost_stacktrace_windbg"        suffix "${name_suffix}")
    guess_binary_file(name "boost_stacktrace_windbg_cached" suffix "${name_suffix}")
    guess_binary_file(name "boost_thread"                   suffix "${name_suffix}")
    guess_binary_file(name "boost_timer"                    suffix "${name_suffix}")
    guess_binary_file(name "boost_type_erasure"             suffix "${name_suffix}")
    guess_binary_file(name "boost_unit_test_framework"      suffix "${name_suffix}")
    guess_binary_file(name "boost_url"                      suffix "${name_suffix}")
    guess_binary_file(name "boost_wave"                     suffix "${name_suffix}")
    guess_binary_file(name "boost_wserialization"           suffix "${name_suffix}")
    set(lib_list    "${lib_path}/${boost_atomic_lib}"
                    "${lib_path}/${boost_chrono_lib}"
                    "${lib_path}/${boost_cobalt_lib}"
                    "${lib_path}/${boost_container_lib}"
                    "${lib_path}/${boost_context_lib}"
                    "${lib_path}/${boost_contract_lib}"
                    "${lib_path}/${boost_coroutine_lib}"
                    "${lib_path}/${boost_date_time_lib}"
                    "${lib_path}/${boost_fiber_lib}"
                    "${lib_path}/${boost_fiber_numa_lib}"
                    "${lib_path}/${boost_filesystem_lib}"
                    "${lib_path}/${boost_graph_lib}"
                    "${lib_path}/${boost_iostreams_lib}"
                    "${lib_path}/${boost_json_lib}"
                    "${lib_path}/${boost_locale_lib}"
                    "${lib_path}/${boost_log_lib}"
                    "${lib_path}/${boost_log_setup_lib}"
                    "${lib_path}/${boost_nowide_lib}"
                    "${lib_path}/${boost_prg_exec_monitor_lib}"
                    "${lib_path}/${boost_program_options_lib}"
                    "${lib_path}/${boost_random_lib}"
                    "${lib_path}/${boost_serialization_lib}"
                    "${lib_path}/${boost_stacktrace_basic_lib}"
                    "${lib_path}/${boost_stacktrace_noop_lib}"
                    "${lib_path}/${boost_stacktrace_windbg_lib}"
                    "${lib_path}/${boost_stacktrace_windbg_cached_lib}"
                    "${lib_path}/${boost_thread_lib}"
                    "${lib_path}/${boost_timer_lib}"
                    "${lib_path}/${boost_type_erasure_lib}"
                    "${lib_path}/${boost_unit_test_framework_lib}"
                    "${lib_path}/${boost_url_lib}"
                    "${lib_path}/${boost_wave_lib}"
                    "${lib_path}/${boost_wserialization_lib}")
    set(bin_list    "${bin_path}/${boost_atomic_bin}"
                    "${bin_path}/${boost_chrono_bin}"
                    "${bin_path}/${boost_cobalt_bin}"
                    "${bin_path}/${boost_container_bin}"
                    "${bin_path}/${boost_context_bin}"
                    "${bin_path}/${boost_contract_bin}"
                    "${bin_path}/${boost_coroutine_bin}"
                    "${bin_path}/${boost_date_time_bin}"
                    "${bin_path}/${boost_fiber_bin}"
                    "${bin_path}/${boost_fiber_numa_bin}"
                    "${bin_path}/${boost_filesystem_bin}"
                    "${bin_path}/${boost_graph_bin}"
                    "${bin_path}/${boost_iostreams_bin}"
                    "${bin_path}/${boost_json_bin}"
                    "${bin_path}/${boost_locale_bin}"
                    "${bin_path}/${boost_log_bin}"
                    "${bin_path}/${boost_log_setup_bin}"
                    "${bin_path}/${boost_nowide_bin}"
                    "${bin_path}/${boost_prg_exec_monitor_bin}"
                    "${bin_path}/${boost_program_options_bin}"
                    "${bin_path}/${boost_random_bin}"
                    "${bin_path}/${boost_serialization_bin}"
                    "${bin_path}/${boost_stacktrace_basic_bin}"
                    "${bin_path}/${boost_stacktrace_noop_bin}"
                    "${bin_path}/${boost_stacktrace_windbg_bin}"
                    "${bin_path}/${boost_stacktrace_windbg_cached_bin}"
                    "${bin_path}/${boost_thread_bin}"
                    "${bin_path}/${boost_timer_bin}"
                    "${bin_path}/${boost_type_erasure_bin}"
                    "${bin_path}/${boost_unit_test_framework_bin}"
                    "${bin_path}/${boost_url_bin}"
                    "${bin_path}/${boost_wave_bin}"
                    "${bin_path}/${boost_wserialization_bin}")
    guess_binary_file(name "libboost_exception"         suffix "${name_suffix}")
    guess_binary_file(name "libboost_test_exec_monitor" suffix "${name_suffix}")
    list(APPEND lib_list "${lib_path}/${libboost_exception_lib}" "${lib_path}/${libboost_test_exec_monitor_lib}")
    set_target_properties("${boost_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${boost_atomic_lib}")
    if(boost_build_shared)
        set_target_properties("${boost_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${boost_atomic_bin}")
    endif()
endfunction()

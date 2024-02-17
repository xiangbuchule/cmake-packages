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

# name: target name
# prefix: prefix path
# version: packages version
# deps: deps target
# ARGN: this will add this to build cmake args
#   GLFW_BUILD_EXAMPLES:    ON
#   GLFW_BUILD_TESTS:       ON
#   GLFW_BUILD_DOCS:        ON
#   GLFW_INSTALL:           ON
#   GLFW_VULKAN_STATIC:     OFF
function(add_freetype)
    # params
    cmake_parse_arguments(freetype "" "name;prefix;version;proxy" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${freetype_name}" OR (DEFINED "${freetype_name}_includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${freetype_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "freetype_build_shared" args_list_name "freetype_UNPARSED_ARGUMENTS")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "freetype_build_type" args_list_name "freetype_UNPARSED_ARGUMENTS")
    # address
    set(freetype_repository_url         "https://github.com/freetype/freetype")
    # set build path
    set(freetype_download  "${freetype_prefix}/cache/download")
    set(freetype_install   "${freetype_prefix}/cache/install/${freetype_name}/${freetype_build_type}")
    set(freetype_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(freetype_source    "${freetype_prefix}/${freetype_name}")
    if(MSVC)
        set(freetype_binary "${freetype_prefix}/cache/bin/${freetype_name}")
    else()
        set(freetype_binary "${freetype_prefix}/cache/bin/${freetype_name}/${freetype_build_type}")
    endif()
    # build option
    set(freetype_cmake_options  # default set shared/static
                                "-DBUILD_SHARED_LIBS=${freetype_build_shared}"
                                # default set debug/release
                                "-DCMAKE_BUILD_TYPE=${freetype_build_type}"
                                # default set lib/exe build path
                                "-DLIBRARY_OUTPUT_PATH='${freetype_binary}'"
                                "-DEXECUTABLE_OUTPUT_PATH='${freetype_binary}'"
                                "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${freetype_binary}'"
                                "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${freetype_binary}'"
                                "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${freetype_binary}'"
                                # default set lib install path
                                "-DCMAKE_INSTALL_PREFIX='${freetype_install}'"
                                "-DCMAKE_INSTALL_LIBDIR='${freetype_install}/lib'"
                                "-DCMAKE_INSTALL_BINDIR='${freetype_install}/bin'"
                                "-DCMAKE_INSTALL_INCLUDEDIR='${freetype_install}/include'"
                                # default set compile flags
                                "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                                "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                                "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                                "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                                "-DCMAKE_CXX_FLAGS_DEBUG='${CMAKE_CXX_FLAGS_DEBUG}'"
                                "-DCMAKE_CXX_FLAGS_RELEASE='${CMAKE_CXX_FLAGS_RELEASE}'")
    # add other build args
    replace_cmake_args("freetype_UNPARSED_ARGUMENTS" "freetype_cmake_options")
    # is install
    if(MSVC)
        set(freetype_build_cmd BUILD_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${freetype_build}" --config "${freetype_build_type}")
        set(freetype_install_cmd INSTALL_COMMAND COMMAND "${CMAKE_COMMAND}" --build "${freetype_build}" --config "${freetype_build_type}" --target INSTALL)
    endif()
    # start build
    ExternalProject_Add("${pkg_name}"   GIT_REPOSITORY "${freetype_repository_url}" GIT_TAG "${freetype_version}"
                                        GIT_SHALLOW ON GIT_PROGRESS OFF DOWNLOAD_DIR "${freetype_download}"
                                        SOURCE_DIR "${freetype_source}" ${freetype_url_option}
                                        CMAKE_ARGS ${freetype_cmake_options} ${freetype_build_cmd} DEPENDS ${freetype_deps}
                                        USES_TERMINAL_DOWNLOAD  ON USES_TERMINAL_UPDATE ON # USES_TERMINAL_PATCH ON
                                        USES_TERMINAL_CONFIGURE ON USES_TERMINAL_BUILD  ON USES_TERMINAL_INSTALL ON)
    # check is build shared/static
    if(freetype_build_shared)
        add_library("${freetype_name}" SHARED IMPORTED GLOBAL)
    else()
        add_library("${freetype_name}" STATIC IMPORTED GLOBAL)
    endif()
    add_dependencies("${freetype_name}" "${pkg_name}")
    # check is build debug/release
    string(TOUPPER "${freetype_build_type}" freetype_build_type)
    if(("${freetype_build_type}" STREQUAL "DEBUG"))
        set("${freetype_name}_includes" "${freetype_source}/include" PARENT_SCOPE)
        if(MSVC)
            set(lib_path "${freetype_binary}/${freetype_build_type}")
            set(bin_path "${freetype_binary}/${freetype_build_type}")
        else()
            set(lib_path "${freetype_binary}")
            set(bin_path "${freetype_binary}")
        endif()
    else()
        set("${freetype_name}_includes" "${freetype_install}/include" PARENT_SCOPE)
        set(lib_path "${freetype_install}/lib")
        set(bin_path "${freetype_install}/bin")
    endif()
    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        if(MSVC)
            if(freetype_build_shared)
                set(lib_name "freetype.lib")
            else()
                set(lib_name "freetype.lib")
            endif()
            set(bin_name "freetype.dll")
        endif()
        if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
            if(freetype_build_shared)
                set(lib_name "libfreetype.a")
            else()
                set(lib_name "libfreetype.a")
            endif()
            set(bin_name "libfreetype.dll")
        endif()
        if(CMAKE_C_COMPILER_ID STREQUAL "Clang")
            message(FATAL_ERROR "#TODO Setting ...")
        endif()
    else()
        message(FATAL_ERROR "#TODO Setting ...")
    endif()
    set_target_properties("${freetype_name}" PROPERTIES IMPORTED_IMPLIB "${lib_path}/${lib_name}")
    if(freetype_build_shared)
        set_target_properties("${freetype_name}" PROPERTIES IMPORTED_LOCATION "${bin_path}/${bin_name}")
    endif()
endfunction()

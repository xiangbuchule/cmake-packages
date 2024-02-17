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

# git_shallow:
#   "git clone" will add "--depth 1". if set it,
#   version need be tag or branch name. don't use commit.
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
function(add_glfw3)
    # params
    cmake_parse_arguments(glfw3 "git_shallow" "name;prefix;version" "deps" ${ARGN})
    # if target exist, return
    if(TARGET "${glfw3_name}" OR (DEFINED "${glfw3_name}_includes"))
        return()
    endif()
    # set pkg name
    set(pkg_name "pkg-${glfw3_name}")
    # check is build shared/static
    get_cmake_args(arg "BUILD_SHARED_LIBS" default "${BUILD_SHARED_LIBS}" result "glfw3_build_shared" args_list_name "glfw3_UNPARSED_ARGUMENTS")
    # check is build debug/release
    get_cmake_args(arg "CMAKE_BUILD_TYPE" default "${CMAKE_BUILD_TYPE}" result "glfw3_build_type" args_list_name "glfw3_UNPARSED_ARGUMENTS")
    # address
    set(glfw3_repository_url        "https://github.com/glfw/glfw")
    list(APPEND glfw3_version_list  "3.3.8" "3.3.9")
    list(APPEND glfw3_hash_list     "4D025083CC4A3DD1F91AB9B9BA4F5807193823E565A5BCF4BE202669D9911EA6"
                                    "55261410F8C3A9CC47CE8303468A90F40A653CD8F25FB968B12440624FB26D08")
    # input version is in version list
    string(STRIP "${glfw3_version}" glfw3_version)
    if("${glfw3_version}" STREQUAL "")
        set(glfw3_version_index 0)
    else()
        list(FIND glfw3_version_list "${glfw3_version}" glfw3_version_index)
    endif()
    if(glfw3_version_index GREATER_EQUAL 0)
        set(glfw3_url   "${glfw3_repository_url}/releases/download/${glfw3_version}/glfw-${glfw3_version}.zip")
        set(glfw3_file  "glfw-${glfw3_version}.zip")
        list(GET glfw3_hash_list ${glfw3_version_index} glfw3_hash)
    endif()
    # set build path
    set(glfw3_download  "${glfw3_prefix}/cache/download")
    set(glfw3_install   "${glfw3_prefix}/cache/install/${glfw3_name}/${glfw3_build_type}")
    set(glfw3_build     "${CMAKE_CURRENT_BINARY_DIR}/${pkg_name}-prefix/src/${pkg_name}-build")
    set(glfw3_source    "${glfw3_prefix}/${glfw3_name}")
    if(MSVC)
        set(glfw3_binary "${glfw3_prefix}/cache/bin/${glfw3_name}")
    else()
        set(glfw3_binary "${glfw3_prefix}/cache/bin/${glfw3_name}/${glfw3_build_type}")
    endif()
    # 构建参数
    set(glfw3_cmake_options # default set shared/static
                            "-DBUILD_SHARED_LIBS=${glfw3_build_shared}"
                            # default set debug/release
                            "-DCMAKE_BUILD_TYPE=${glfw3_build_type}"
                            # default set lib/exe build path
                            "-DLIBRARY_OUTPUT_PATH='${glfw3_binary}'"
                            "-DEXECUTABLE_OUTPUT_PATH='${glfw3_binary}'"
                            "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY='${glfw3_binary}'"
                            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY='${glfw3_binary}'"
                            "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY='${glfw3_binary}'"
                            # default set lib install path
                            "-DCMAKE_INSTALL_PREFIX='${glfw3_install}'"
                            "-DCMAKE_INSTALL_LIBDIR='${glfw3_install}/lib'"
                            "-DCMAKE_INSTALL_BINDIR='${glfw3_install}/bin'"
                            "-DCMAKE_INSTALL_INCLUDEDIR='${glfw3_install}/include'"
                            # default set compile flags
                            "-DCMAKE_C_FLAGS='${CMAKE_C_FLAGS}'"
                            "-DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS}'"
                            "-DCMAKE_C_FLAGS_DEBUG='${CMAKE_C_FLAGS_DEBUG}'"
                            "-DCMAKE_C_FLAGS_RELEASE='${CMAKE_C_FLAGS_RELEASE}'"
                         
set(third_path "${CMAKE_CURRENT_SOURCE_DIR}/third")
file(GLOB directories_list LIST_DIRECTORIES true "${third_path}/*")
list(REMOVE_ITEM directories_list "${third_path}/cache")
file(
    REMOVE_RECURSE "${CMAKE_CURRENT_SOURCE_DIR}/build" ${directories_list}
    "${third_path}/cache/patch" "${third_path}/cache/tool"
    "${third_path}/cache/bin"   "${third_path}/cache/install"
)
#include <cstring>
#include <exception>
#include <iostream>
#include <memory>
#include <string>
#include <tuple>

#include "config.h"

#include "glad/gl.h"

#include "GLFW/glfw3.h"

#include "imgui.h"
#include "imgui_freetype.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"

#include "stb_image.h"

#include "zip.h"

extern "C" {
#include "rc.h"
}

void input_key_callback(GLFWwindow *window, GLint key, GLint scancode, GLint action, GLint mods);

// read file content from zip byte array
template <typename T>
auto read_zip_file_content(zip_t *archive, std::string_view file_name) {
    // 获取文件的信息
    zip_stat_t *entryStat = (zip_stat_t *)std::malloc(sizeof(zip_stat_t));
    zip_stat_init(entryStat);
    if (zip_stat(archive, file_name.data(), 0, entryStat) < 0)
        throw std::runtime_error(zip_strerror(archive));
    // 打开文件
    zip_file_t *file = zip_fopen(archive, file_name.data(), 0);
    if (!file) throw std::runtime_error(zip_strerror(archive));
    // 读取文件内容
    zip_uint64_t size   = entryStat->size;
    auto         buffer = std::make_unique<T[]>(size);
    zip_fread(file, buffer.get(), entryStat->size);
    // 清理资源
    std::free(entryStat);
    zip_fclose(file);
    return std::move(std::make_tuple(std::move(buffer), size));
}

int main() {
    // 创建一个zip源，从内存中读取zip数据
    zip_error_t   error;
    zip_source_t *source = zip_source_buffer_create(RC_DATA, sizeof(RC_DATA) / sizeof(RC_DATA[0]), 0, &error);
    if (!source) exit(EXIT_FAILURE);
    // 打开zip文件
    zip_t *archive = zip_open_from_source(source, 0, &error);
    if (!archive) {
        zip_source_free(source);
        exit(EXIT_FAILURE);
    }
    // shader
    auto [vert_shader, vert_shader_len] = read_zip_file_content<unsigned char>(archive, "shaders/main.vert");
    auto [frag_shader, frag_shader_len] = read_zip_file_content<unsigned char>(archive, "shaders/main.frag");
    // icons
    auto [icon_16x16, icon_16x16_len]  = read_zip_file_content<unsigned char>(archive, "icons/16x16_icon.png");
    auto [icon_32x32, icon_32x32_len]  = read_zip_file_content<unsigned char>(archive, "icons/32x32_icon.png");
    auto [icon_48x48, icon_48x48_len]  = read_zip_file_content<unsigned char>(archive, "icons/48x48_icon.png");
    // close
    zip_close(archive);
    zip_source_free(source);

    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif
    GLFWwindow *window = glfwCreateWindow(800, 600, "glfw window", NULL, NULL);
    if (!window) {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    // glfw支持16x16,32x32和48x48大小的icon
    // glfwSetWindowIcon(window, 1);
    GLFWimage *icon_array    = (GLFWimage *)malloc(sizeof(GLFWimage) * 3);
    icon_array->pixels       = stbi_load_from_memory(icon_16x16.get(), (int)icon_16x16_len * (int)sizeof(icon_16x16[0]), &icon_array->width, &icon_array->height, NULL, 0);
    (icon_array + 1)->pixels = stbi_load_from_memory(icon_32x32.get(), (int)icon_32x32_len * (int)sizeof(icon_32x32[0]), &(icon_array + 1)->width, &(icon_array + 1)->height, NULL, 0);
    (icon_array + 2)->pixels = stbi_load_from_memory(icon_48x48.get(), (int)icon_48x48_len * (int)sizeof(icon_48x48[0]), &(icon_array + 2)->width, &(icon_array + 2)->height, NULL, 0);
    glfwSetWindowIcon(window, 3, icon_array);
    icon_16x16.reset();
    icon_32x32.reset();
    icon_48x48.reset();
    stbi_image_free(icon_array->pixels);
    stbi_image_free((icon_array + 1)->pixels);
    stbi_image_free((icon_array + 2)->pixels);
    free(icon_array);
    // 设置当前窗口为glfw的context上下文
    glfwMakeContextCurrent(window);
    glfwSetKeyCallback(window, input_key_callback);
    while (!glfwWindowShouldClose(window)) {
        glfwSwapBuffers(window);
        glfwPollEvents();
    }
    glfwTerminate();
    return 0;
}

void input_key_callback(GLFWwindow *window, GLint key, GLint scancode, GLint action, GLint mods) {
    if (GLFW_KEY_ESCAPE == key && GLFW_PRESS == action) glfwSetWindowShouldClose(window, GLFW_TRUE);
}
#include <cstring>
#include <exception>
#include <iostream>
#include <memory>
#include <string>
#include <tuple>
#include <functional>

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
auto read_zip_file_content(std::shared_ptr<zip_t> archive, std::string_view file_name) {
    // 获取文件的信息
    auto entryStat = std::make_unique<zip_stat_t>();
    zip_stat_init(entryStat.get());
    if (zip_stat(archive.get(), file_name.data(), 0, entryStat.get()) < 0)
        throw std::runtime_error(zip_strerror(archive.get()));
    // 打开文件
    std::unique_ptr<zip_file_t, std::function<void(zip_file_t *ptr)>> file(zip_fopen(archive.get(), file_name.data(), 0), [](zip_file_t *ptr) { zip_fclose(ptr); });
    if (!file.get()) throw std::runtime_error(zip_strerror(archive.get()));
    // 读取文件内容
    zip_uint64_t size   = entryStat->size;
    auto         buffer = std::make_shared<T[]>(size);
    zip_fread(file.get(), buffer.get(), entryStat->size);
    return std::move(std::make_tuple(std::move(buffer), size));
}

int main() {
    // 创建一个zip源，从内存中读取zip数据
    zip_error_t   error;
    std::unique_ptr<zip_source_t, std::function<void(zip_source_t *ptr)>> source(zip_source_buffer_create(RC_DATA, sizeof(RC_DATA) / sizeof(RC_DATA[0]), 0, &error), [](zip_source_t *ptr) { zip_source_free(ptr);});
    if (!source.get()) return 0;
    // 打开zip文件
    std::shared_ptr<zip_t> archive(zip_open_from_source(source.get(), 0, &error),[](zip_t *ptr) { zip_close(ptr); });
    if (!archive.get()) return 0;
    // shader
    auto [vert_shader, vert_shader_len] = read_zip_file_content<unsigned char>(archive, "shaders/main.vert");
    auto [frag_shader, frag_shader_len] = read_zip_file_content<unsigned char>(archive, "shaders/main.frag");
    // icons
    auto [icon_16x16, icon_16x16_len]  = read_zip_file_content<unsigned char>(archive, "icons/16x16_icon.png");
    auto [icon_32x32, icon_32x32_len]  = read_zip_file_content<unsigned char>(archive, "icons/32x32_icon.png");
    auto [icon_48x48, icon_48x48_len]  = read_zip_file_content<unsigned char>(archive, "icons/48x48_icon.png");
    // init glfw
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif
    // create window
    std::unique_ptr<GLFWwindow, std::function<void(GLFWwindow *ptr)>> window(glfwCreateWindow(800, 600, "glfw window", NULL, NULL), [](GLFWwindow *ptr) { glfwDestroyWindow(ptr);});
    if (!window.get()) {
        glfwTerminate();
        return 0;
    }
    // glfw支持16x16,32x32和48x48大小的icon
    auto icon_array          = std::make_unique<GLFWimage[]>(3);
    (&icon_array[0])->pixels = stbi_load_from_memory(icon_16x16.get(), (int)icon_16x16_len * (int)sizeof(icon_16x16[0]), &(&icon_array[0])->width, &(&icon_array[0])->height, NULL, 0);
    (&icon_array[1])->pixels = stbi_load_from_memory(icon_32x32.get(), (int)icon_32x32_len * (int)sizeof(icon_32x32[0]), &(&icon_array[1])->width, &(&icon_array[1])->height, NULL, 0);
    (&icon_array[2])->pixels = stbi_load_from_memory(icon_48x48.get(), (int)icon_48x48_len * (int)sizeof(icon_48x48[0]), &(&icon_array[2])->width, &(&icon_array[2])->height, NULL, 0);
    glfwSetWindowIcon(window.get(), 3, icon_array.get());
    icon_16x16.reset();
    icon_32x32.reset();
    icon_48x48.reset();
    stbi_image_free((&icon_array[0])->pixels);
    stbi_image_free((&icon_array[1])->pixels);
    stbi_image_free((&icon_array[2])->pixels);
    icon_array.reset();
    // 设置当前窗口为glfw的context上下文
    glfwMakeContextCurrent(window.get());
    glfwSetKeyCallback(window.get(), input_key_callback);
    while (!glfwWindowShouldClose(window.get())) {
        glfwSwapBuffers(window.get());
        glfwPollEvents();
    }
    glfwTerminate();
    return 0;
}

void input_key_callback(GLFWwindow *window, GLint key, GLint scancode, GLint action, GLint mods) {
    if (GLFW_KEY_ESCAPE == key && GLFW_PRESS == action) glfwSetWindowShouldClose(window, GLFW_TRUE);
}
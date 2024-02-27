#include <functional>
#include <iostream>
#include <memory>
#include <string>

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

#include "global.hpp"
#include "init.hpp"
#include "ui/app.h"

void input_key_callback(GLFWwindow *window, GLint key, GLint scancode, GLint action, GLint mods);
void framebuffer_size_callback(GLFWwindow *window, int width, int height);
void window_size_callback(GLFWwindow *window, int width, int height);

int main() {
    // 初始化
    init();
    // zip对象
    auto [archive, source] = get_zip_object(RC_DATA, sizeof(RC_DATA) / sizeof(RC_DATA[0]));
    // shader
    auto [vert_shader, vert_shader_len] = read_zip_file_content<unsigned char>(archive, "shaders/main.vert");
    auto [frag_shader, frag_shader_len] = read_zip_file_content<unsigned char>(archive, "shaders/main.frag");
    // icons
    auto [icon_16x16, icon_16x16_len] = read_zip_file_content<unsigned char>(archive, "icons/16x16_icon.png");
    auto [icon_32x32, icon_32x32_len] = read_zip_file_content<unsigned char>(archive, "icons/32x32_icon.png");
    auto [icon_48x48, icon_48x48_len] = read_zip_file_content<unsigned char>(archive, "icons/48x48_icon.png");
    archive.reset();
    source.reset();
    // create window
    // std::unique_ptr<GLFWwindow, std::function<void(GLFWwindow * ptr)>> window(glfwCreateWindow(800, 600, "glfw window", NULL, NULL), [](GLFWwindow *ptr) { glfwDestroyWindow(ptr); });
    std::shared_ptr<GLFWwindow> window(glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, MAIN_TITLE_NAME, NULL, NULL), [](GLFWwindow *ptr) { glfwDestroyWindow(ptr); });
    if (!window) {
        // 回收资源
        release();
        return 0;
    }
    // create
    auto app = std::make_shared<App>(WINDOW_WIDTH, WINDOW_HEIGHT, true, window);
    // glfw支持16x16,32x32和48x48大小的icon
    auto icon_array          = std::make_shared<GLFWimage[]>(3);
    (&icon_array[0])->pixels = stbi_load_from_memory(icon_16x16.get(), (int)icon_16x16_len * (int)sizeof(icon_16x16[0]), &(&icon_array[0])->width, &(&icon_array[0])->height, NULL, 0);
    (&icon_array[1])->pixels = stbi_load_from_memory(icon_32x32.get(), (int)icon_32x32_len * (int)sizeof(icon_32x32[0]), &(&icon_array[1])->width, &(&icon_array[1])->height, NULL, 0);
    (&icon_array[2])->pixels = stbi_load_from_memory(icon_48x48.get(), (int)icon_48x48_len * (int)sizeof(icon_48x48[0]), &(&icon_array[2])->width, &(&icon_array[2])->height, NULL, 0);
    glfwSetWindowIcon(window.get(), 3, icon_array.get());
    // 设置当前窗口为glfw的context上下文
    glfwMakeContextCurrent(window.get());
    glfwSetKeyCallback(window.get(), input_key_callback);
    glfwSetFramebufferSizeCallback(window.get(), framebuffer_size_callback);
    glfwSetWindowSizeCallback(window.get(), window_size_callback);
    // glad2手动加载opengl的API函数
    int version = gladLoadGL((GLADloadfunc)glfwGetProcAddress);
    // printf("load openGL version %d.%d\n", GLAD_VERSION_MAJOR(version), GLAD_VERSION_MINOR(version));
    // 绑定imgui
    ImVec4   clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);
    ImGuiIO &io          = ImGui::GetIO();
    ImGui_ImplGlfw_InitForOpenGL(window.get(), true);
    ImGui_ImplOpenGL3_Init("#version 330");
    // loop
    while (!glfwWindowShouldClose(window.get())) {
        // poll events
        glfwPollEvents();
        // ui init
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();
        // content
        app->render();
        // render ui
        ImGui::Render();
        glClearColor(clear_color.x * clear_color.w, clear_color.y * clear_color.w, clear_color.z * clear_color.w, clear_color.w);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
        // Update and Render additional Platform Windows
        if (io.ConfigFlags & ImGuiConfigFlags_ViewportsEnable) {
            GLFWwindow *backup_current_context = glfwGetCurrentContext();
            ImGui::UpdatePlatformWindows();
            ImGui::RenderPlatformWindowsDefault();
            glfwMakeContextCurrent(backup_current_context);
        }
        // swap buffer
        glfwSwapBuffers(window.get());
    }
    // 回收图标内存
    stbi_image_free((&icon_array[0])->pixels);
    stbi_image_free((&icon_array[1])->pixels);
    stbi_image_free((&icon_array[2])->pixels);
    icon_array.reset();
    // 回收资源
    release();
    return 0;
}

void input_key_callback(GLFWwindow *window, GLint key, GLint scancode, GLint action, GLint mods) {
    if (GLFW_KEY_ESCAPE == key && GLFW_PRESS == action) glfwSetWindowShouldClose(window, GLFW_TRUE);
}
void framebuffer_size_callback(GLFWwindow *window, int width, int height) {
    // 更新视口大小
    glViewport(0, 0, width, height);
}
void window_size_callback(GLFWwindow *window, int width, int height) {
    // swap buffer
    // glfwSwapBuffers(window);
}
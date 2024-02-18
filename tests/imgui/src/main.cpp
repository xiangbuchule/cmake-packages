#include <iostream>
#include <memory>

#include "config.h"

#include "glad/gl.h"

#include "GLFW/glfw3.h"

#include "imgui.h"
#include "imgui_freetype.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"

#include "stb_image.h"

extern "C" {
#include "rc.h"
}

void input_key_callback(GLFWwindow *window, GLint key, GLint scancode, GLint action, GLint mods);

int main() {
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
    icon_array->pixels       = stbi_load_from_memory(RC_ICON_16x16_DATA, sizeof(RC_ICON_16x16_DATA) / sizeof(RC_ICON_16x16_DATA[0]), &icon_array->width, &icon_array->height, NULL, 0);
    (icon_array + 1)->pixels = stbi_load_from_memory(RC_ICON_32x32_DATA, sizeof(RC_ICON_32x32_DATA) / sizeof(RC_ICON_32x32_DATA[0]), &(icon_array + 1)->width, &(icon_array + 1)->height, NULL, 0);
    (icon_array + 2)->pixels = stbi_load_from_memory(RC_ICON_48x48_DATA, sizeof(RC_ICON_48x48_DATA) / sizeof(RC_ICON_48x48_DATA[0]), &(icon_array + 2)->width, &(icon_array + 2)->height, NULL, 0);
    glfwSetWindowIcon(window, 3, icon_array);
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
#include <iostream>
#include <memory>

#include "glad/gl.h"
#define GLFW_INCLUDE_NONE
#include "GLFW/glfw3.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#include "rc.hpp"

#include "window.hpp"

void input_key_callback(GLFWwindow *window, GLint key, GLint scancode, GLint action, GLint mods);

int main() {
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif
    auto window = std::make_shared<Window>(glfwCreateWindow(800, 600, "glfw window", NULL, NULL));
    glfwMakeContextCurrent(window->window);
    glfwSetKeyCallback(window->window, input_key_callback);
    while (!glfwWindowShouldClose(window->window)) {
        glfwSwapBuffers(window->window);
        glfwPollEvents();
    }
    window.reset();
    glfwTerminate();
    return 0;
}

void input_key_callback(GLFWwindow *window, GLint key, GLint scancode, GLint action, GLint mods) {
    if (GLFW_KEY_ESCAPE == key && GLFW_PRESS == action) glfwSetWindowShouldClose(window, GLFW_TRUE);
}
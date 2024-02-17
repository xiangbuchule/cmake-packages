#ifndef __WINDOW_HPP__
#define __WINDOW_HPP__

#define GLFW_INCLUDE_NONE
#include "GLFW/glfw3.h"

struct Window {
    GLFWwindow  *window;
    int height;
    int width;
    Window(GLFWwindow* window) {
        this->window = window;
        glfwGetWindowSize(window, &this->width, &this->height);
    }
    inline void  setKeyCallback(GLFWkeyfun cbfn) {
        glfwSetKeyCallback(this->window, cbfn);
    }
    ~Window(){
        glfwDestroyWindow(this->window);
    }
};
#endif
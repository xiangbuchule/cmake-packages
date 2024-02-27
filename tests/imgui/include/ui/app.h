#ifndef __APP_H__
#define __APP_H__

#include <memory>

#include "GLFW/glfw3.h"

class App {
  private:
    int width;
    int height;
    bool open;
    // window
    std::shared_ptr<GLFWwindow> window;

    // init
    bool init_flag;
  public:
    App(int width, int height, bool open, std::shared_ptr<GLFWwindow> window);
    void render();
    ~App();
};

#endif
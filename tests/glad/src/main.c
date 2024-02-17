#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "glad/gl.h"
#define GLFW_INCLUDE_NONE
#include "GLFW/glfw3.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#include "rc.h"

#include "common/array.h"
#include "shader.h"

// 帧缓冲大小变化触发得回调
void framebuffer_size_callback(GLFWwindow *window, int width, int height);
// 按键触发回调
void key_callback(GLFWwindow *window, GLint key, GLint scancode, GLint action, GLint mods);
// 窗口大小变化触发得回调
void window_size_callbak(GLFWwindow *window, int width, int height);

// 调用opengl函数之前调用的函数回调
void pre_call_gl_callback(const char *name, GLADapiproc apiproc, int len_args, ...) {
    // printf("about to call gl func: %s\n", name);
}

// 窗口宽高
const GLuint SCR_WIDTH  = 800;
const GLuint SCR_HEIGHT = 600;
// 窗口数组
Array *windowArray;
// gl数组
Array *glArray;

int main() {
    // 窗口数组
    windowArray = array_create();
    glArray     = array_create();
    // 初始化glfw
    glfwInit();
    // 设置glfw的context上下文版本为3.3, 对应opengl的3.3
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
    // 设置使用opengl的core核心模式, 非兼容或扩展模式
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_COMPAT_PROFILE, GL_TRUE);

#ifdef __APPLE__
    // 苹果系统需要添加设置兼容模式
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif

    // 创建窗口
    GLFWwindow *window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL", NULL, NULL);
    if (!window) {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    // glfw支持16x16,32x32和48x48大小的icon
    // glfwSetWindowIcon(window, 1);
    GLFWimage  *icon_array = (GLFWimage *)malloc(sizeof(GLFWimage)*3);
    icon_array->pixels = stbi_load_from_memory(RC_ICON_16x16_DATA, sizeof(RC_ICON_16x16_DATA) / sizeof(RC_ICON_16x16_DATA[0]), &icon_array->width, &icon_array->height, NULL, 0);
    (icon_array + 1)->pixels = stbi_load_from_memory(RC_ICON_32x32_DATA, sizeof(RC_ICON_32x32_DATA) / sizeof(RC_ICON_32x32_DATA[0]), &(icon_array + 1)->width, &(icon_array + 1)->height, NULL, 0);
    (icon_array + 2)->pixels = stbi_load_from_memory(RC_ICON_48x48_DATA, sizeof(RC_ICON_48x48_DATA) / sizeof(RC_ICON_48x48_DATA[0]), &(icon_array + 2)->width, &(icon_array + 2)->height, NULL, 0);
    glfwSetWindowIcon(window, 3, icon_array);
    stbi_image_free(icon_array->pixels);
    stbi_image_free((icon_array + 1)->pixels);
    stbi_image_free((icon_array + 2)->pixels);
    free(icon_array);
    // 设置窗口图标
    if (!array_push_back(windowArray, window)) {
        glfwTerminate();
        glfwSetWindowShouldClose(window, GL_TRUE);
        exit(EXIT_FAILURE);
    }
    // 设置当前窗口为glfw的context上下文
    glfwMakeContextCurrent(window);
    // 设置窗口大小变化回调
    glfwSetWindowSizeCallback(window, window_size_callbak);
    // 设置按键回调
    glfwSetKeyCallback(window, key_callback);
    // 设置帧缓冲大小变化回调
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    // 通过glad1加载opengl的API函数
    // if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
    //     printf("Failed to initialize GLAD\n");
    //     return -1;
    // }

    // 如果在构建glad2时使用了--loader和--on-demand选项
    // 那么就不允许要调用glad函数去加载opengl的API函数
    // 自动就懒加载opengl的函数
    // 推荐使用上下文自带的loader加载方式
    // #ifndef GLAD_GL_LOADER
    //     gladSetGLOnDemandLoader(glfwGetProcAddress);
    // #endif
    // #ifdef GLAD_OPTION_GL_DEBUG
    //     gladUninstallGLDebug();
    //     gladSetGLPreCallback(pre_call_gl_callback);
    // #endif

    // glad2手动加载opengl的API函数
    // int version = gladLoadGL(glfwGetProcAddress);
    // printf("load openGL version %d.%d\n", GLAD_VERSION_MAJOR(version), GLAD_VERSION_MINOR(version));

    // 如果glad2开启mx参数(多上下文支持)
    // 需要使用这种方式创建加载opengl上下文与API函数
    // 调用opengl的API函数方式发生变化
    // 如glCreateShader变为context->CreateShader
    GladGLContext *gl = (GladGLContext *)malloc(sizeof(GladGLContext));
    if (!gl) {
        glfwWindowShouldClose(window);
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    int version = gladLoadGLContext(gl, glfwGetProcAddress);
    // printf("load openGL version %d.%d\n", GLAD_VERSION_MAJOR(version), GLAD_VERSION_MINOR(version));
    if (!array_push_back(glArray, gl)) {
        free(gl);
        glfwSetWindowShouldClose(window, GL_TRUE);
        glfwTerminate();
        exit(EXIT_FAILURE);
    }

    // 编译日志记录
    GLuint infoSize = 512;
    char  *infoLog  = (char *)malloc(sizeof(char) * infoSize);
    // 创建顶点着色器对象
    GLuint vertexShader = gl->CreateShader(GL_VERTEX_SHADER);
    // 编译源码
    bool success = compile_shader_data(gl, vertexShader, RC_SHADER_VERT_SOURCE, infoLog, infoSize);
    if (!success) {
        gl->DeleteShader(vertexShader);
        free(infoLog);
        free(gl);
        glfwSetWindowShouldClose(window, GL_TRUE);
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    memset(infoLog, 0, infoSize);

    // 创建片段着色器对象
    GLuint fragmentShader = gl->CreateShader(GL_FRAGMENT_SHADER);
    // 编译源码

    success = compile_shader_data(gl, fragmentShader, RC_SHADER_FRAG_SOURCE, infoLog, infoSize);
    if (!success) {
        gl->DeleteShader(vertexShader);
        gl->DeleteShader(fragmentShader);
        free(infoLog);
        free(gl);
        glfwSetWindowShouldClose(window, GL_TRUE);
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    memset(infoLog, 0, infoSize);
    // 链接创建着色器程序
    GLuint  shaderProgram   = gl->CreateProgram();
    GLuint  shaderArraySize = 2;
    GLuint *shaderArray     = (GLuint *)malloc(sizeof(GLuint) * shaderArraySize);
    shaderArray[0]          = vertexShader;
    shaderArray[1]          = fragmentShader;
    // 编译着色器
    success = link_shader(gl, shaderProgram, shaderArray, shaderArraySize, infoLog, infoSize);
    if (!success) {
        gl->DeleteShader(vertexShader);
        gl->DeleteShader(fragmentShader);
        gl->DeleteProgram(shaderProgram);
        free(shaderArray);
        free(infoLog);
        free(gl);
        glfwSetWindowShouldClose(window, GL_TRUE);
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    // 释放资源
    free(infoLog);
    free(shaderArray);
    gl->DeleteShader(vertexShader);
    gl->DeleteShader(fragmentShader);

    // 定义顶点数组
    float vertices[] = {
        0.5f, -0.5f, 0.0f,  // bottom right
        -0.5f, -0.5f, 0.0f, // bottom left
        0.0f, 0.5f, 0.0f    // top
    };
    // 创建顶点缓冲对象VBO与顶点数组对象VAO
    GLuint VBO, VAO;
    gl->GenVertexArrays(1, &VAO);
    gl->GenBuffers(1, &VBO);

    // 使用顶点数组对象
    gl->BindVertexArray(VAO);
    // 使用顶点缓冲对象
    gl->BindBuffer(GL_ARRAY_BUFFER, VBO);

    // 顶点数据传入上述使用的顶点数组对象中
    gl->BufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // 设置顶点的读取方式
    // 顶点的读取方式的编号0
    // 每3个元素长度表示一个顶点
    // 顶点数据类型为float
    // 是否将顶点数据归一化到[0,1]或[-1,1]范围内,false
    // (步长)指定连续两个顶点属性间的字节数.如果为0,则表示顶点属性是紧密排列的.
    // 查找下一个顶点在数组中的索引位置时需要在当前顶点在数组中的索引位置跳过的元素长度.
    // 指向缓冲对象中第一个顶点属性的第一个分量的地址(offset的作用)
    gl->VertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void *)0);
    // 关联绑定该顶点的读取方式与上述使用的顶点缓冲对象
    gl->EnableVertexAttribArray(0);

    // 使用完顶点数组对象VAO后取消绑定
    // glBindVertexArray(0);

    // 渲染循环
    while (!glfwWindowShouldClose(window)) {
        // 设置清理的颜色
        gl->ClearColor(0.2f, 0.3f, 0.3f, 1.0f);
        gl->Clear(GL_COLOR_BUFFER_BIT);

        // 使用着色器
        gl->UseProgram(shaderProgram);

        // 获取时间
        double timeValue = glfwGetTime();
        // 设置rgb通道中的g通道的值随时间正弦变化
        float greenValue = sin(timeValue) / 2.0 + 0.5;
        // 获取着色器输入颜色的地址
        int vertexColorLocation = gl->GetUniformLocation(shaderProgram, "ourColor");
        // 将颜色传入着色器输入颜色的地址
        gl->Uniform4f(vertexColorLocation, 0.0f, greenValue, 0.0f, 1.0f);

        // 绘制
        gl->DrawArrays(GL_TRIANGLES, 0, 3);

        // glfw双缓冲交换
        glfwSwapBuffers(window);
        // glfw轮询glfw窗口事件
        glfwPollEvents();
    }

    // 回收opengl资源
    gl->DeleteVertexArrays(1, &VAO);
    gl->DeleteBuffers(1, &VBO);
    gl->DeleteProgram(shaderProgram);
    // for (size_t i = 0; i < global_glWindowArray->size; i++) {
    //     GLWindowsFree(global_glWindowArray->pointer[i]);
    // }
    free(gl);

    // 回收glfw资源
    glfwTerminate();
    // 回收数组
    array_free(windowArray);
    array_free(glArray);
    return 0;
}

void key_callback(GLFWwindow *window, GLint key, GLint scancode, GLint action, GLint mods) {
    if (GLFW_KEY_ESCAPE == key && GLFW_PRESS == action) {
        glfwSetWindowShouldClose(window, GL_TRUE);
    }
}

void framebuffer_size_callback(GLFWwindow *window, GLint width, GLint height) {
    GladGLContext *gl = NULL;
    for (size_t i = 0; i < windowArray->size; i++) {
        if (windowArray->pointer[i] == window) gl = glArray->pointer[i];
    }
    if (!gl) return;
    // 当帧缓冲变化时变化opengl的视口
    gl->Viewport(0, 0, width, height);
}

void window_size_callbak(GLFWwindow *window, int width, int height) {
}

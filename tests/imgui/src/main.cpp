#include <functional>
#include <memory>
#include <string>

#include "glad/gl.h"

#include "GLFW/glfw3.h"

#include "imgui.h"
#include "imgui_freetype.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"

#include "stb_image.h"

#include "jdbc/cppconn/connection.h"
#include "jdbc/cppconn/driver.h"
#include "jdbc/cppconn/exception.h"
#include "jdbc/cppconn/prepared_statement.h"
#include "jdbc/cppconn/resultset.h"
#include "jdbc/cppconn/statement.h"
#include "jdbc/mysql_connection.h"
#include "jdbc/mysql_driver.h"
#include "mysqlx/xdevapi.h"

#include "archive.h"

extern "C" {
#include "rc.h"
}

#include "global.h"
#include "init.hpp"
#include "ui/layer.h"
#include "ui/ui.h"

void input_key_callback(GLFWwindow *window, GLint key, GLint scancode, GLint action, GLint mods);
void framebuffer_size_callback(GLFWwindow *window, int width, int height);
void window_size_callback(GLFWwindow *window, int width, int height);
int  main() {
    // 创建 MySQL 连接
    sql::mysql::MySQL_Driver *driver = sql::mysql::get_mysql_driver_instance();
    sql::Connection          *con    = driver->connect("tcp://192.168.2.197:9401", "root", "cctv");
    // 选择数据库
    con->setSchema("mysql");
    // 执行查询
    sql::Statement *stmt;
    sql::ResultSet *res;
    stmt = con->createStatement();
    res  = stmt->executeQuery("SELECT 1234/2345");
    // 处理结果
    while (res->next()) {
        auto ss = res->getDouble(1);
        int  s  = 10;
    }
    delete res;
    delete stmt;
    delete con;
    // 初始化
    init();
    // shader
    auto [vert_shader, vert_shader_len] = read_zip_file_content<unsigned char>(RC_DATA, sizeof(RC_DATA) / sizeof(RC_DATA[0]), "shaders/main.vert");
    auto [frag_shader, frag_shader_len] = read_zip_file_content<unsigned char>(RC_DATA, sizeof(RC_DATA) / sizeof(RC_DATA[0]), "shaders/main.frag");
    // icons
    auto [icon_16x16, icon_16x16_len] = read_zip_file_content<unsigned char>(RC_DATA, sizeof(RC_DATA) / sizeof(RC_DATA[0]), "icons/16x16_icon.png");
    auto [icon_32x32, icon_32x32_len] = read_zip_file_content<unsigned char>(RC_DATA, sizeof(RC_DATA) / sizeof(RC_DATA[0]), "icons/32x32_icon.png");
    auto [icon_48x48, icon_48x48_len] = read_zip_file_content<unsigned char>(RC_DATA, sizeof(RC_DATA) / sizeof(RC_DATA[0]), "icons/48x48_icon.png");
    // create window
    // std::unique_ptr<GLFWwindow, std::function<void(GLFWwindow * ptr)>> window(glfwCreateWindow(800, 600, "glfw window", NULL, NULL), [](GLFWwindow *ptr) { glfwDestroyWindow(ptr); });
    std::shared_ptr<GLFWwindow> window(glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, MAIN_TITLE_NAME, NULL, NULL), [](GLFWwindow *ptr) { glfwDestroyWindow(ptr); });
    if (!window) {
        // 回收资源
        release();
        return 0;
    }
    // glfw支持16x16,32x32和48x48大小的icon
    auto icon_array          = std::make_shared<GLFWimage[]>(3);
    (&icon_array[0])->pixels = stbi_load_from_memory(icon_16x16.get(), (int)icon_16x16_len * (int)sizeof(icon_16x16[0]), &(&icon_array[0])->width, &(&icon_array[0])->height, NULL, 0);
    (&icon_array[1])->pixels = stbi_load_from_memory(icon_32x32.get(), (int)icon_32x32_len * (int)sizeof(icon_32x32[0]), &(&icon_array[1])->width, &(&icon_array[1])->height, NULL, 0);
    (&icon_array[2])->pixels = stbi_load_from_memory(icon_48x48.get(), (int)icon_48x48_len * (int)sizeof(icon_48x48[0]), &(&icon_array[2])->width, &(&icon_array[2])->height, NULL, 0);
    glfwSetWindowIcon(window.get(), 3, icon_array.get());
    // 回收图标内存
    stbi_image_free((&icon_array[0])->pixels);
    stbi_image_free((&icon_array[1])->pixels);
    stbi_image_free((&icon_array[2])->pixels);
    icon_array.reset();
    // 设置当前窗口为glfw的context上下文
    glfwMakeContextCurrent(window.get());
    glfwSetKeyCallback(window.get(), input_key_callback);
    glfwSetFramebufferSizeCallback(window.get(), framebuffer_size_callback);
    glfwSetWindowSizeCallback(window.get(), window_size_callback);
    // glad2手动加载opengl的API函数
    int version = gladLoadGL((GLADloadfunc)glfwGetProcAddress);
    // printf("load openGL version %d.%d\n", GLAD_VERSION_MAJOR(version), GLAD_VERSION_MINOR(version));
    // 绑定imgui
    ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);
    ImGui_ImplGlfw_InitForOpenGL(window.get(), true);
    ImGui_ImplOpenGL3_Init("#version 330");
    // 创建layer
    auto app = ui();
    app->children->push_back(ui_option());
    app->children->push_back(ui_log());
    app->children->push_back(ui_task());
    app->children->push_back(ui_search_mysql_data_export());
    app->children->push_back(ui_read_sql_data_import());
    app->children->push_back(ui_help());
    // loop
    while (!glfwWindowShouldClose(window.get())) {
        // poll events
        glfwPollEvents();

        glClearColor(clear_color.x * clear_color.w, clear_color.y * clear_color.w, clear_color.z * clear_color.w, clear_color.w);
        glClear(GL_COLOR_BUFFER_BIT);
        // ================= imgui =================
        // imgui ui start
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();
        // set ui
        app->render();
        // imgui render
        ImGui::Render();
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
        // Update and Render additional Platform Windows
        if (ImGui::GetIO().ConfigFlags & ImGuiConfigFlags_ViewportsEnable) {
            GLFWwindow *backup_current_context = glfwGetCurrentContext();
            ImGui::UpdatePlatformWindows();
            ImGui::RenderPlatformWindowsDefault();
            glfwMakeContextCurrent(backup_current_context);
        }
        // swap buffer
        glfwSwapBuffers(window.get());
    }
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
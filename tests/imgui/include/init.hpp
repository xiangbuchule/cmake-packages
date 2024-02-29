#ifndef __INIT_HPP__
#define __INIT_HPP__

#include <concepts>
#include <exception>
#include <functional>
#include <memory>
#include <tuple>

#include "config.h"

#include "glad/gl.h"

#include "GLFW/glfw3.h"

#include "imgui.h"
#include "imgui_freetype.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"

#include "ui/layer.h"

extern "C" {
#include "rc.h"
}

// create zip object by zip byte array
auto get_zip_object(const char *data, size_t size) {
    // 创建一个zip源，从内存中读取zip数据
    zip_error_t                   error;
    std::shared_ptr<zip_source_t> source(zip_source_buffer_create(data, size, 0, &error), [](zip_source_t *ptr) { zip_source_free(ptr); });
    if (!source) throw std::runtime_error("create zip object error !!!");
    // 打开zip文件
    std::shared_ptr<zip_t> archive(zip_open_from_source(source.get(), 0, &error), [](zip_t *ptr) { zip_close(ptr); });
    if (!archive) throw std::runtime_error("open zip object error !!!");
    return std::make_tuple(std::move(archive), std::move(source));
}

// read file content from zip byte array
template <typename T>
    requires std::same_as<T, char> || std::same_as<T, unsigned char> || std::same_as<T, int8_t> || std::same_as<T, uint8_t>
auto read_zip_file_content(std::shared_ptr<zip_t> archive, std::string_view file_name) {
    // 获取文件的信息
    auto entryStat = std::make_unique<zip_stat_t>();
    zip_stat_init(entryStat.get());
    if (zip_stat(archive.get(), file_name.data(), 0, entryStat.get()) < 0)
        throw std::runtime_error(zip_strerror(archive.get()));
    // 打开文件
    std::unique_ptr<zip_file_t, std::function<void(zip_file_t * ptr)>> file(zip_fopen(archive.get(), file_name.data(), 0), [](zip_file_t *ptr) { zip_fclose(ptr); });
    if (!file) throw std::runtime_error(zip_strerror(archive.get()));
    // 读取文件内容
    zip_uint64_t size   = entryStat->size;
    auto         buffer = std::make_shared<T[]>(size);
    zip_fread(file.get(), buffer.get(), entryStat->size);
    return std::make_tuple(std::move(buffer), size);
}

// init
void init() {
    // init glfw
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    // glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif
    // RC
    auto [archive, source] = get_zip_object(RC_DATA, sizeof(RC_DATA) / sizeof(RC_DATA[0]));
    // fonts
    auto [hack_font_ptr, hack_font_len]                             = read_zip_file_content<unsigned char>(archive, "fonts/Nerd-Font-Hack/HackNerdFont-Regular.ttf");
    auto [simplified_chinese_font_ptr, simplified_chinese_font_len] = read_zip_file_content<unsigned char>(archive, "fonts/Source-Han-Sans/SimplifiedChinese-VF.ttf");
    // imgui
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    // style
    ImGui::StyleColorsLight();
    // ImGui::StyleColorsClassic();
    // ImGui::StyleColorsDark();
    // config
    ImGuiIO &io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard; // Enable Keyboard Controls
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;  // Enable Gamepad Controls
    io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;     // enable docking
    io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable;   // 开启多视口
    io.ConfigViewportsNoAutoMerge = true;
    // ban imgui.ini
    io.IniFilename = nullptr;
    io.LogFilename = nullptr;
    // fonts
    io.Fonts->AddFontDefault();
    ImFontConfig font_cfg;
    font_cfg.FontBuilderFlags |= ImGuiFreeTypeBuilderFlags::ImGuiFreeTypeBuilderFlags_ForceAutoHint; // 表示优先使用自动hinting而不是字体的本机hinting
    // font_cfg.FontBuilderFlags |= ImGuiFreeTypeBuilderFlags::ImGuiFreeTypeBuilderFlags_Bold;          // 加粗字体
    font_cfg.FontBuilderFlags |= ImGuiFreeTypeBuilderFlags::ImGuiFreeTypeBuilderFlags_LoadColor; // 启用FreeType颜色分层字形
    font_cfg.FontBuilderFlags |= ImGuiFreeTypeBuilderFlags::ImGuiFreeTypeBuilderFlags_Bitmap;    // 启用FreeType位图字形
    font_cfg.FontDataOwnedByAtlas = false;
    font_cfg.MergeMode            = true;
    io.Fonts->AddFontFromMemoryTTF((void *)hack_font_ptr.get(), (int)hack_font_len, 13., &font_cfg, io.Fonts->GetGlyphRangesDefault());
    io.Fonts->AddFontFromMemoryTTF((void *)simplified_chinese_font_ptr.get(), (int)simplified_chinese_font_len, 13., &font_cfg, io.Fonts->GetGlyphRangesChineseFull());
    io.Fonts->Build();
}

// free
void release() {
    // imgui
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
    // glfw
    glfwTerminate();
}

#endif
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

#include "archive.h"
#include "archive_entry.h"

#include "ui/layer.h"

extern "C" {
#include "rc.h"
}

// create zip object by zip byte array
// inline auto get_zip_object(const char *data, size_t size) {
//     // 创建一个zip源，从内存中读取zip数据
//     zip_error_t error;
//     // 拷贝一遍数据
//     char *tmp = (char *)malloc(sizeof(char) * size);
//     memcpy(tmp, data, size);
//     std::shared_ptr<zip_source_t> source(zip_source_buffer_create(tmp, size, 1, &error), [](zip_source_t *ptr) {
//         // zip_source_buffer_create 中freep设置为
//         // 非0，那么创建的对象会在zip_source_close后自动释放
//         // 0，那么得手动释放，这里由于数据源是静态数据，
//         // 不能释放，不能有释放操作，即使是自动释放。
//         // 这里拷贝一遍数据。
//         // zip_source_free(ptr);
//         zip_source_close(ptr);
//     });
//     if (!source) throw std::runtime_error("create zip object error !!!");
//     // 打开zip文件
//     std::shared_ptr<zip_t> archive(zip_open_from_source(source.get(), 0, &error), [](zip_t *ptr) {
//         zip_close(ptr);
//     });
//     if (!archive) throw std::runtime_error("open zip object error !!!");
//     return std::make_tuple(std::move(archive), std::move(source));
// }

// read file content from zip byte array
template <typename T>
    requires std::same_as<T, char> || std::same_as<T, unsigned char> || std::same_as<T, int8_t> || std::same_as<T, uint8_t>
auto read_zip_file_content(const char *data, size_t size, std::string_view file_name) {
    // 创建对象
    std::shared_ptr<archive> zip(archive_read_new(), [](archive *ptr) {
        archive_read_close(ptr);
        archive_read_free(ptr);
    });
    archive_read_support_format_zip(zip.get());
    if (archive_read_open_memory(zip.get(), data, size) != ARCHIVE_OK) {
        throw std::runtime_error(std::format("Failed to open archive from memory: {}", archive_error_string(zip.get())));
    }
    struct archive_entry *entry;
    // 遍历读取文件
    while (archive_read_next_header(zip.get(), &entry) == ARCHIVE_OK) {
        const char *entry_name = archive_entry_pathname(entry);
        if (entry_name == file_name) {
            size_t len    = archive_entry_size(entry);
            auto   buffer = std::make_shared<T[]>(len);
            archive_read_data(zip.get(), buffer.get(), len);
            return std::make_tuple(std::move(buffer), len);
        }
    }
    throw std::runtime_error(std::format("Not find {} !!!", file_name));
    // // 获取文件的信息
    // auto entryStat = std::make_unique<zip_stat_t>();
    // zip_stat_init(entryStat.get());
    // if (zip_stat(archive.get(), file_name.data(), 0, entryStat.get()) < 0)
    //     throw std::runtime_error(zip_strerror(archive.get()));
    // // 打开文件
    // std::unique_ptr<zip_file_t, std::function<void(zip_file_t * ptr)>> file(zip_fopen(archive.get(), file_name.data(), 0), [](zip_file_t *ptr) { zip_fclose(ptr); });
    // if (!file) throw std::runtime_error(zip_strerror(archive.get()));
    // // 读取文件内容
    // zip_uint64_t size   = entryStat->size;
    // auto         buffer = std::make_shared<T[]>(size);
    // zip_fread(file.get(), buffer.get(), entryStat->size);
    // return std::make_tuple(std::move(buffer), size);
}

// read file content from zip byte array
template <typename T>
    requires std::same_as<T, char> || std::same_as<T, unsigned char> || std::same_as<T, int8_t> || std::same_as<T, uint8_t>
auto read_zip_file_content_ptr(const char *data, size_t size, std::string_view file_name) {
    // 创建对象
    std::shared_ptr<archive> zip(archive_read_new(), [](archive *ptr) {
        archive_read_close(ptr);
        archive_read_free(ptr);
    });
    archive_read_support_format_zip(zip.get());
    if (archive_read_open_memory(zip.get(), data, size) != ARCHIVE_OK) {
        throw std::runtime_error(std::format("Failed to open archive from memory: {}", archive_error_string(zip.get())));
    }
    struct archive_entry *entry;
    // 遍历读取文件
    while (archive_read_next_header(zip.get(), &entry) == ARCHIVE_OK) {
        const char *entry_name = archive_entry_pathname(entry);
        if (entry_name == file_name) {
            size_t len    = archive_entry_size(entry);
            auto   buffer = new T[len];
            archive_read_data(zip.get(), buffer, len);
            return std::make_tuple(buffer, len);
        }
    }
    throw std::runtime_error(std::format("Not find {} !!!", file_name));
    // // 获取文件的信息
    // auto entryStat = std::make_unique<zip_stat_t>();
    // zip_stat_init(entryStat.get());
    // if (zip_stat(archive.get(), file_name.data(), 0, entryStat.get()) < 0)
    //     throw std::runtime_error(zip_strerror(archive.get()));
    // // 打开文件
    // std::unique_ptr<zip_file_t, std::function<void(zip_file_t * ptr)>> file(zip_fopen(archive.get(), file_name.data(), 0), [](zip_file_t *ptr) { zip_fclose(ptr); });
    // if (!file) throw std::runtime_error(zip_strerror(archive.get()));
    // // 读取文件内容
    // zip_uint64_t size   = entryStat->size;
    // auto         buffer = std::make_shared<T[]>(size);
    // zip_fread(file.get(), buffer.get(), entryStat->size);
    // return std::make_tuple(std::move(buffer), size);
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
    // fonts
    auto [hack_font_ptr, hack_font_len]                             = read_zip_file_content_ptr<unsigned char>(RC_DATA, sizeof(RC_DATA) / sizeof(RC_DATA[0]), "fonts/Nerd-Font-Hack/HackNerdFont-Regular.ttf");
    auto [simplified_chinese_font_ptr, simplified_chinese_font_len] = read_zip_file_content_ptr<unsigned char>(RC_DATA, sizeof(RC_DATA) / sizeof(RC_DATA[0]), "fonts/Source-Han-Serif/SimplifiedChinese-Regular.otf");
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
    ImFontConfig font_cfg;
    font_cfg.GlyphOffset = ImVec2(0, -2);
    font_cfg.FontBuilderFlags |= ImGuiFreeTypeBuilderFlags::ImGuiFreeTypeBuilderFlags_ForceAutoHint; // 表示优先使用自动hinting而不是字体的本机hinting
    font_cfg.FontBuilderFlags |= ImGuiFreeTypeBuilderFlags::ImGuiFreeTypeBuilderFlags_LoadColor; // 启用FreeType颜色分层字形
    font_cfg.FontBuilderFlags |= ImGuiFreeTypeBuilderFlags::ImGuiFreeTypeBuilderFlags_Bitmap;    // 启用FreeType位图字形
    // font_cfg.FontDataOwnedByAtlas = false; // imgui不拥有字体数据,我们自己释放字体数据
    const ImWchar ranges[] = {0x20, 0xFFFFF, 0};
    io.Fonts->AddFontFromMemoryTTF((void *)hack_font_ptr, (int)hack_font_len, 15., &font_cfg, ranges);
    // font_cfg.FontBuilderFlags |= ImGuiFreeTypeBuilderFlags::ImGuiFreeTypeBuilderFlags_Bold;          // 加粗字体
    font_cfg.MergeMode = true; // 配置字体合并
    io.Fonts->AddFontFromMemoryTTF((void *)simplified_chinese_font_ptr, (int)simplified_chinese_font_len, 15., &font_cfg, ranges);
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
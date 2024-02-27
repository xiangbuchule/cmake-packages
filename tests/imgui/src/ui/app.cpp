#include <memory>

#include "GLFW/glfw3.h"

#include "imgui.h"
#include "imgui_freetype.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"
#include "imgui_internal.h"

#include "global.hpp"
#include "ui/app.h"

App::App(int width, int height, bool open, std::shared_ptr<GLFWwindow> window)
    : width(width), height(height), open(open), window(window), init_flag(false) {}

App::~App() {}

void App::render() {
    static ImGuiDockNodeFlags dockspace_flags = ImGuiDockNodeFlags_PassthruCentralNode | ImGuiDockNodeFlags_AutoHideTabBar;
    ImGuiWindowFlags          window_flags    = ImGuiWindowFlags_MenuBar | ImGuiWindowFlags_NoDocking;
    const ImGuiViewport      *viewport        = ImGui::GetMainViewport();
    ImGuiIO                  &io              = ImGui::GetIO();
    ImGui::SetNextWindowPos(viewport->WorkPos);
    ImGui::SetNextWindowSize(viewport->WorkSize);
    ImGui::SetNextWindowViewport(viewport->ID);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowRounding, 0.0f);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);
    window_flags |= ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove;
    window_flags |= ImGuiWindowFlags_NoBringToFrontOnFocus | ImGuiWindowFlags_NoNavFocus;
    if (dockspace_flags & ImGuiDockNodeFlags_PassthruCentralNode)
        window_flags |= ImGuiWindowFlags_NoBackground;
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0.0f, 0.0f));
    ImGui::Begin("DockSpace", nullptr, window_flags);
    ImGui::PopStyleVar();
    ImGui::PopStyleVar(2);
    if (io.ConfigFlags & ImGuiConfigFlags_DockingEnable) {
        auto dockspace_id = ImGui::GetID("DockSpace");
        ImGui::DockSpace(dockspace_id, ImVec2(0.0f, 0.0f), dockspace_flags);
        static bool first_dock = true;
        if (first_dock) {
            first_dock = false;
            ImGui::DockBuilderRemoveNode(dockspace_id);
            ImGui::DockBuilderAddNode(dockspace_id, dockspace_flags | ImGuiDockNodeFlags_DockSpace);
            ImGui::DockBuilderSetNodeSize(dockspace_id, viewport->Size);
            auto remain_dockspace = dockspace_id;
            auto dock_id_left     = ImGui::DockBuilderSplitNode(remain_dockspace, ImGuiDir_Left, 0.5f, nullptr, &remain_dockspace);
            ImGui::DockBuilderDockWindow("option", dock_id_left);
            ImGui::DockBuilderDockWindow("mmp", remain_dockspace);
            ImGui::DockBuilderFinish(dockspace_id);
        }
    }
    ImGui::End();
    ImGui::Begin("option");
    ImGui::Text("看来是就过分了");
    ImGui::End();
    ImGui::Begin("mmp");
    ImGui::Text("李开复倒过来看");
    ImGui::End();
}

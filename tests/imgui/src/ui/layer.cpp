#include <memory>

#include "GLFW/glfw3.h"

#include "imgui.h"
#include "imgui_freetype.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"
#include "imgui_internal.h"

#include "global.h"
#include "ui/layer.h"

void main_render(int opengl_version) noexcept {
    // imgui ui content
    ImGuiDockNodeFlags   dockspace_flags = ImGuiDockNodeFlags_PassthruCentralNode | ImGuiDockNodeFlags_AutoHideTabBar;
    ImGuiWindowFlags     window_flags    = ImGuiWindowFlags_MenuBar | ImGuiWindowFlags_NoDocking;
    const ImGuiViewport *viewport        = ImGui::GetMainViewport();
    ImGuiIO             &io              = ImGui::GetIO();
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
    if (ImGui::Begin("DockSpace", nullptr, window_flags)) {
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
                auto dock_id_left     = ImGui::DockBuilderSplitNode(remain_dockspace, ImGuiDir_Left, 0.2f, nullptr, &remain_dockspace);
                auto dock_id_down     = ImGui::DockBuilderSplitNode(remain_dockspace, ImGuiDir_Down, 0.3f, nullptr, &remain_dockspace);
                auto dock_id_right    = ImGui::DockBuilderSplitNode(remain_dockspace, ImGuiDir_Right, 0.25f, nullptr, &remain_dockspace);
                ImGui::DockBuilderDockWindow(OPTION_WINDOW_NAME, dock_id_left);
                ImGui::DockBuilderDockWindow(LOG_WINDOW_NAME, dock_id_down);
                ImGui::DockBuilderDockWindow(TASK_WINDOW_NAME, dock_id_right);
                ImGui::DockBuilderDockWindow(SPACE_WINDOW_NAME, remain_dockspace);
                ImGui::DockBuilderFinish(dockspace_id);
            }
        }
        if (ImGui::BeginMenuBar()) {
            if (ImGui::BeginMenu("菜单")) {
                if (ImGui::MenuItem(OPTION_WINDOW_NAME, nullptr, false, true)) {
                }
                if (ImGui::MenuItem(SPACE_WINDOW_NAME, nullptr, false, true)) {
                }
                if (ImGui::MenuItem(LOG_WINDOW_NAME, nullptr, false, true)) {
                }
                if (ImGui::MenuItem(TASK_WINDOW_NAME, nullptr, false, true)) {
                }
                ImGui::EndMenu();
            }
            if (ImGui::BeginMenu(ABOUT_BAR_NAME)) {
                if (ImGui::MenuItem(HELP_WINDOW_NAME, nullptr, false, true)) {
                }
                ImGui::EndMenu();
            }
            ImGui::EndMenuBar();
        }
        ImGui::End();
    } else {
        ImGui::PopStyleVar();
        ImGui::PopStyleVar(2);
    }
    ImGui::Begin(OPTION_WINDOW_NAME);
    ImGui::Text("看来是就过分了");
    ImGui::End();
    ImGui::Begin(SPACE_WINDOW_NAME);
    ImGui::Text("李开复倒过来看");
    ImGui::End();
    ImGui::Begin(TASK_WINDOW_NAME);
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::Text("李开复倒过来看");
    ImGui::End();
    ImGui::Begin(LOG_WINDOW_NAME);
    ImGui::Text("李开复倒过来看: %dversion", opengl_version);
    ImGui::End();
}

#include <functional>
#include <memory>
#include <vector>

#include "imgui.h"
#include "imgui_internal.h"

#include "global.h"
#include "ui/layer.h"
#include "ui/static.h"
#include "ui/ui.h"

std::shared_ptr<Layer> ui() noexcept {
    auto layer         = std::make_shared<Layer>();
    layer->render_call = [](std::shared_ptr<State> state) {
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
                if (IS_FIRST_RENDER) {
                    IS_FIRST_RENDER = !IS_FIRST_RENDER;
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
                    ImGui::DockBuilderDockWindow(SEARCH_MYSQL_DATA_EXPORT_WINDOW_NAME, remain_dockspace);
                    ImGui::DockBuilderFinish(dockspace_id);
                }
            }
            if (ImGui::BeginMenuBar()) {
                if (ImGui::BeginMenu("窗口")) {
                    if (ImGui::MenuItem(OPTION_WINDOW_NAME, nullptr, &OPTION_WINDOW_OPEN, true)) {
                    }
                    if (ImGui::MenuItem(SEARCH_MYSQL_DATA_EXPORT_WINDOW_NAME, nullptr, &SEARCH_MYSQL_DATA_EXPORT_WINDOW_OPEN, true)) {
                    }
                    if (ImGui::MenuItem(READ_SQL_DATA_IMPORT_WINDOW_NAME, nullptr, &READ_SQL_DATA_IMPORT_WINDOW_OPEN, true)) {
                    }
                    if (ImGui::MenuItem(LOG_WINDOW_NAME, nullptr, &LOG_WINDOW_OPEN, true)) {
                    }
                    if (ImGui::MenuItem(TASK_WINDOW_NAME, nullptr, &TASK_WINDOW_OPEN, true)) {
                    }
                    ImGui::EndMenu();
                }
                if (ImGui::BeginMenu("关于")) {
                    if (ImGui::MenuItem(HELP_WINDOW_NAME, nullptr, &HELP_WINDOW_OPEN, true)) {
                    }
                    if (ImGui::MenuItem(DEMO_WINDOW_NAME, nullptr, &DEMO_WINDOW_OPEN, true)) {
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
        if (DEMO_WINDOW_OPEN) {
            ImGui::ShowDemoWindow(&DEMO_WINDOW_OPEN);
        }
    };
    return layer;
}

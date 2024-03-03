#include <functional>
#include <memory>
#include <vector>

#include "imgui.h"
#include "imgui_internal.h"

#include "global.h"
#include "ui/layer.h"
#include "ui/static.h"
#include "ui/ui.h"

std::shared_ptr<Layer> ui_search_mysql_data_export() noexcept {
    auto layer         = std::make_shared<Layer>();
    layer->state->value["info"] = "xyz";
    layer->render_call          = [](std::shared_ptr<State> state) {
        // imgui ui content
        if (SEARCH_MYSQL_DATA_EXPORT_WINDOW_OPEN) {
            ImGui::Begin(SEARCH_MYSQL_DATA_EXPORT_WINDOW_NAME, &SEARCH_MYSQL_DATA_EXPORT_WINDOW_OPEN);
            SEARCH_MYSQL_DATA_EXPORT_WINDOW_DOCK_ID = ImGui::GetWindowDockID();
            ImGui::Text("查询MySQL数据并导出 %d dock_id", SEARCH_MYSQL_DATA_EXPORT_WINDOW_DOCK_ID);
            ImGui::Text("\U0000f4a2");
            ImGui::End();
        }
    };
    return layer;
}

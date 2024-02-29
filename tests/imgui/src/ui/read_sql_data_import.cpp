#include <functional>
#include <memory>
#include <vector>

#include "imgui.h"
#include "imgui_internal.h"

#include "global.h"
#include "rapidjson/document.h"
#include "ui/layer.h"
#include "ui/static.h"
#include "ui/ui.h"

std::shared_ptr<Layer> ui_read_sql_data_import() noexcept {
    auto layer         = std::make_shared<Layer>();
    layer->render_call = [](std::shared_ptr<State> state) {
        // imgui ui content
        if (READ_SQL_DATA_IMPORT_WINDOW_OPEN) {
            if (READ_SQL_DATA_IMPORT_WINDOW_IS_FIRST_RENDER) {
                READ_SQL_DATA_IMPORT_WINDOW_IS_FIRST_RENDER = !READ_SQL_DATA_IMPORT_WINDOW_IS_FIRST_RENDER;
                if (SEARCH_MYSQL_DATA_EXPORT_WINDOW_DOCK_ID > 0) {
                    ImGui::DockBuilderDockWindow(READ_SQL_DATA_IMPORT_WINDOW_NAME, SEARCH_MYSQL_DATA_EXPORT_WINDOW_DOCK_ID);
                    ImGui::DockBuilderFinish(SEARCH_MYSQL_DATA_EXPORT_WINDOW_DOCK_ID);
                }
            }
            ImGui::Begin(READ_SQL_DATA_IMPORT_WINDOW_NAME, &READ_SQL_DATA_IMPORT_WINDOW_OPEN);
            ImGui::Text("读取SQL文件数据并导入 跟随 %d dock_id", SEARCH_MYSQL_DATA_EXPORT_WINDOW_DOCK_ID);
            ImGui::End();
        }
    };
    return layer;
}

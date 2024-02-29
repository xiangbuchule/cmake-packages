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

std::shared_ptr<Layer> ui_log() noexcept {
    auto layer         = std::make_shared<Layer>();
    layer->render_call = [](std::shared_ptr<State> state) {
        // imgui ui content
        if (LOG_WINDOW_OPEN) {
            ImGui::Begin(LOG_WINDOW_NAME, &LOG_WINDOW_OPEN);
            ImGui::Text("日志测试");
            ImGui::End();
        }
    };
    return layer;
}

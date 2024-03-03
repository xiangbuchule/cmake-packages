#include <functional>
#include <memory>
#include <vector>

#include "imgui.h"
#include "imgui_internal.h"

#include "global.h"
#include "ui/layer.h"
#include "ui/static.h"
#include "ui/ui.h"

std::shared_ptr<Layer> ui_help() noexcept {
    auto layer         = std::make_shared<Layer>();
    layer->render_call = [](std::shared_ptr<State> state) {
        // imgui ui content
        if (HELP_WINDOW_OPEN) {
            ImGui::Begin(HELP_WINDOW_NAME, &HELP_WINDOW_OPEN);
            ImGui::Text("帮助");
            ImGui::End();
        }
    };
    return layer;
}

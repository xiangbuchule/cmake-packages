#include <memory>
#include <vector>

#include "rapidjson/document.h"

#include "ui/layer.h"

Layer::Layer() noexcept {
    this->state = std::make_shared<State>();
    this->state->value.SetObject();
    this->children = std::make_unique<std::vector<std::shared_ptr<Layer>>>();
}
Layer::Layer(Layer &&other) noexcept {
    this->state        = std::move(other.state);
    this->render_call  = std::move(other.render_call);
    this->children     = std::move(other.children);
}
Layer::~Layer() noexcept {};
void Layer::render() noexcept {
    if (this->render_call) {
        this->render_call(this->state);
    }
    for (auto &item : *(this->children)) {
        item->render();
    }
}

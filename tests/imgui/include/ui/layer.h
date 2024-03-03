#ifndef __Layer_H__
#define __Layer_H__

#include <vector>
#include <functional>
#include <memory>

#include "json/json.h"

struct State {
    Json::Value value;
    State() noexcept {
    }
};

struct Layer {
    // 状态
    std::shared_ptr<State> state;

    // 渲染函数
    std::function<void(std::shared_ptr<State>)> render_call;

    // 子对象
    std::unique_ptr<std::vector<std::shared_ptr<Layer>>> children;

    Layer() noexcept;
    Layer(const Layer &other) = delete;
    Layer(Layer &&other) noexcept;
    ~Layer() noexcept;
    void render() noexcept;
};

#endif
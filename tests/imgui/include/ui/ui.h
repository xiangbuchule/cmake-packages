#ifndef __UI_H__
#define __UI_H__

#include <memory>

#include "ui/layer.h"

std::shared_ptr<Layer> ui() noexcept;

std::shared_ptr<Layer> ui_option() noexcept;

std::shared_ptr<Layer> ui_log() noexcept;

std::shared_ptr<Layer> ui_task() noexcept;

std::shared_ptr<Layer> ui_read_sql_data_import() noexcept;

std::shared_ptr<Layer> ui_search_mysql_data_export() noexcept;

std::shared_ptr<Layer> ui_help() noexcept;

#endif
/**
 * ui共享变量
 */

#include "ui/static.h"

// ================= base信息 =================
// 是否第一次渲染
bool IS_FIRST_RENDER = true;


// ================= 窗口样式 =================
ThemeStyle THEME_STYLE = ThemeStyle::LIGHT;


// ================= 窗口名字 =================
// 功能窗口
const char *OPTION_WINDOW_NAME = "\U000f0bab 功能选择";
// 日志窗口
const char *LOG_WINDOW_NAME = "\uf4ed 日志记录";
// 任务窗口
const char *TASK_WINDOW_NAME = "\uf4a0 任务列表";
// 查询数据并导出窗口
const char *SEARCH_MYSQL_DATA_EXPORT_WINDOW_NAME = "\U000f162c 查询MySQL数据并导出";
// 查询数据并导出窗口
const char *READ_SQL_DATA_IMPORT_WINDOW_NAME = "\U000f162d 读取SQL文件数据并导入";
// 帮助窗口
const char *HELP_WINDOW_NAME = "\U000f0625 帮助信息";
// Demo窗口
const char *DEMO_WINDOW_NAME = "\uea74 Demo信息";

// ================= 窗口状态 =================
// ------- 功能窗口 -------
// 是否开启 默认 true
bool OPTION_WINDOW_OPEN = true;

// ------- 日志窗口 -------
// 是否开启 默认 true
bool LOG_WINDOW_OPEN = true;

// ------- 任务窗口 -------
// 是否开启 默认 true
bool TASK_WINDOW_OPEN = true;

// -- 查询数据并导出窗口 --
// 是否开启 默认 true
bool SEARCH_MYSQL_DATA_EXPORT_WINDOW_OPEN = true;
// 查询数据并导出窗口的dockid
ImGuiID SEARCH_MYSQL_DATA_EXPORT_WINDOW_DOCK_ID = 0;

// -- 读取数据并导入窗口 --
// 是否开启 默认 true
bool READ_SQL_DATA_IMPORT_WINDOW_OPEN = false;
// 是否是第一次渲染
bool READ_SQL_DATA_IMPORT_WINDOW_IS_FIRST_RENDER = true;

// ------- 帮助窗口 -------
// 是否开启 默认 false
bool HELP_WINDOW_OPEN = false;

// ------- Demo窗口 -------
// 是否开启 默认 false
bool DEMO_WINDOW_OPEN = false;

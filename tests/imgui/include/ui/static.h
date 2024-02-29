#ifndef __UI_STATIC_H__
#define __UI_STATIC_H__

#include "imgui.h"

/**
 * ui共享变量
 */


// ================= base信息 =================
// 是否第一次渲染
extern bool IS_FIRST_RENDER;


// ================= 窗口名字 =================
// 功能窗口
extern const char *OPTION_WINDOW_NAME;
// 日志窗口
extern const char *LOG_WINDOW_NAME;
// 任务窗口
extern const char *TASK_WINDOW_NAME;
// 查询数据并导出窗口
extern const char *SEARCH_MYSQL_DATA_EXPORT_WINDOW_NAME;
// 查询数据并导出窗口
extern const char *READ_SQL_DATA_IMPORT_WINDOW_NAME;
// 关于窗口
extern const char *HELP_WINDOW_NAME;
// Demo窗口
extern const char *DEMO_WINDOW_NAME;


// ================= 窗口状态 =================
// ------- 功能窗口 -------
// 是否开启 默认 true
extern bool OPTION_WINDOW_OPEN;

// ------- 日志窗口 -------
// 是否开启 默认 true
extern bool LOG_WINDOW_OPEN;

// ------- 任务窗口 -------
// 是否开启 默认 true
extern bool TASK_WINDOW_OPEN;

// -- 查询数据并导出窗口 --
// 是否开启 默认 true
extern bool SEARCH_MYSQL_DATA_EXPORT_WINDOW_OPEN;
// 查询数据并导出窗口的dockid
extern ImGuiID SEARCH_MYSQL_DATA_EXPORT_WINDOW_DOCK_ID;

// -- 读取数据并导入窗口 --
// 是否开启 默认 true
extern bool READ_SQL_DATA_IMPORT_WINDOW_OPEN;
// 是否是第一次渲染
extern bool READ_SQL_DATA_IMPORT_WINDOW_IS_FIRST_RENDER;

// ------- 帮助窗口 -------
// 是否开启 默认 false
extern bool HELP_WINDOW_OPEN;

// ------- Demo窗口 -------
// 是否开启 默认 false
extern bool DEMO_WINDOW_OPEN;

#endif
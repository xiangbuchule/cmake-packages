#ifndef __SHADER_H__
#define __SHADER_H__

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include "glad/gl.h"

// 读取文件
char *read_source_code(const char *file);
// 释放读取的文件内容
void free_source_code(void *pointer);

// 编译着色器
bool compile_shader_file(GladGLContext *gl, GLuint shader, const char *file, char *log, GLuint logSize);
bool compile_shader_data(GladGLContext *gl, GLuint shader, const char *data, char *log, GLuint logSize);
// 链接着色器
bool link_shader(GladGLContext *gl, GLuint program, GLuint *shaderArray, GLuint shaderArraySize, char *log, GLuint logSize);

#endif
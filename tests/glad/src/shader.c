#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>

#include "glad/gl.h"

#include "shader.h"

char *read_source_code(const char *file) {
    // 打开文件
    FILE *file_pointer = fopen(file, "r");
    if (!file) return NULL;
    // 定位文件指针位置到最后
    fseek(file_pointer, 0, SEEK_END);
    long end = ftell(file_pointer);
    if (-1 == end) {
        fclose(file_pointer);
        return NULL;
    }
    // 返回开头
    fseek(file_pointer, 0, SEEK_SET);

    // 创建数组存储内容
    char *data = (char *)malloc(end + 1);
    if (!data) {
        fclose(file_pointer);
        return NULL;
    }
    // 标志字符串结束
    data[end] = '\0';
    // 读取内容直到读取完成
    fread(data, sizeof(char), end / sizeof(char), file_pointer);

    // 关闭文件
    if (fclose(file_pointer) != 0) {
        free(data);
        return NULL;
    }

    // 返回指针
    return data;
}

void free_source_code(void *pointer) {
    free(pointer);
}

bool compile_shader_file(GladGLContext *gl, GLuint shader, const char *file, char *log, GLuint logSize) {
    char *sourceCode = read_source_code(file);
    if (!sourceCode) return false;
    gl->ShaderSource(shader, 1, &sourceCode, NULL);
    gl->CompileShader(shader);
    // 释放文件
    free_source_code(sourceCode);
    // 检查顶点着色器编译错误
    GLint success;
    gl->GetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        gl->GetShaderInfoLog(shader, logSize, NULL, log);
        return false;
    }
    return true;
}

bool compile_shader_data(GladGLContext *gl, GLuint shader, const char *data, char *log, GLuint logSize) {
    gl->ShaderSource(shader, 1, &data, NULL);
    gl->CompileShader(shader);
    // 检查顶点着色器编译错误
    GLint success;
    gl->GetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        gl->GetShaderInfoLog(shader, logSize, NULL, log);
        return false;
    }
    return true;
}

bool link_shader(GladGLContext *gl, GLuint program, GLuint *shaderArray, GLuint shaderArraySize, char *log, GLuint logSize) {
    for (GLuint i = 0; i < shaderArraySize; i++)
        gl->AttachShader(program, shaderArray[i]);
    gl->LinkProgram(program);
    // 检查着色器链接错误
    GLint success;
    gl->GetProgramiv(program, GL_LINK_STATUS, &success);
    if (!success) {
        gl->GetProgramInfoLog(program, logSize, NULL, log);
        return false;
    }
    return true;
}

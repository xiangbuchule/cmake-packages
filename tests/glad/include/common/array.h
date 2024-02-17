#ifndef __ARRAY_H__
#define __ARRAY_H__

#include <stdbool.h>
#include <stdlib.h>

#ifndef ARRAY_DEAULT_SIZE
#define ARRAY_DEAULT_SIZE 15
#endif
#ifndef ARRAY_SCALE_RATIO
#define ARRAY_SCALE_RATIO 2
#endif
typedef struct _array {
    // 保存了元素指针的数组的指针
    void **pointer;
    // 数组大小
    size_t size;
    // 数组容量
    size_t capacity;
} Array;
// 创建数组
Array *array_create();
Array *array_create_size(size_t size);
// 设置数组容量
bool array_resize(Array *array, size_t size);
// 在末尾添加
bool array_push_back(Array *array, void *value);
// 在头添加
bool array_push_front(Array *array, void *value);
// 获取元素
void *array_at(Array *array, size_t index);
// 删除最后一个元素
bool array_pop_back(Array *array);
// 删除第一个元素
void array_pop_front(Array *array);
// 插入元素
bool array_insert(Array *array, size_t index, void *value);
// 删除元素
bool array_remove(Array *array, size_t index);
// 清空数组
void array_clean(Array *array);
// 释放数组
void array_free(Array *array);

#endif
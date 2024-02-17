#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include "common/array.h"

#define ARRAY_DEAULT_SIZE_ 15
#define ARRAY_SCALE_RATIO_ 2

// 创建数组
Array *array_create() {
    size_t size = (0 >= ARRAY_DEAULT_SIZE) ? ARRAY_DEAULT_SIZE_ : ARRAY_DEAULT_SIZE;
    void **pointer   = (void **)malloc(sizeof(void *) * size);
    if (!pointer) return NULL;
    Array *array = (Array *)malloc(sizeof(Array));
    if (!array) {
        free(pointer);
        return NULL;
    }
    array->size     = 0;
    array->pointer  = pointer;
    array->capacity = size;
    return array;
}
Array *array_create_size(size_t size) {
    size_t capacity = (0 == size) ? (0 >= ARRAY_DEAULT_SIZE) ? ARRAY_DEAULT_SIZE_ : ARRAY_DEAULT_SIZE : size;
    void **pointer  = (void **)malloc(sizeof(void *) * capacity);
    if (!pointer) return NULL;
    Array *array = (Array *)malloc(sizeof(Array));
    if (!array) {
        free(pointer);
        return NULL;
    }
    array->size     = 0;
    array->pointer  = pointer;
    array->capacity = capacity;
    return array;
}
// 设置数组容量
bool array_resize(Array *array, size_t size) {
    if (!array) return false;
    if (0 == array->size && 0 == size) return false;
    if (array->size > size) size = array->size;
    if (size == array->capacity) return true;
    void **pointer = (void **)malloc(sizeof(void *) * size);
    if (!pointer) return false;
    memcpy(pointer, array->pointer, sizeof(void *) * size);
    free(array->pointer);
    array->capacity = size;
    array->pointer  = pointer;
    return true;
}
// 在末尾添加
bool array_push_back(Array *array, void *value) {
    if (!array) return false;
    if (array->capacity == array->size) {
        size_t new_capacity = array->capacity * ((ARRAY_SCALE_RATIO_ > ARRAY_SCALE_RATIO) ? ARRAY_SCALE_RATIO_ : ARRAY_SCALE_RATIO);
        void **pointer     = (void **)malloc(sizeof(void *) * new_capacity);
        if (!pointer) return false;
        memcpy(pointer, array->pointer, sizeof(void *) * array->size);
        free(array->pointer);
        array->capacity = new_capacity;
        array->pointer  = pointer;
    }
    array->pointer[array->size] = value;
    array->size++;
    return true;
}
// 在头添加
bool array_push_front(Array *array, void *value) {
    if (!array) return false;
    if (array->capacity == array->size) {
        size_t new_capacity = array->capacity * ((ARRAY_SCALE_RATIO_ > ARRAY_SCALE_RATIO) ? ARRAY_SCALE_RATIO_ : ARRAY_SCALE_RATIO);
        void **pointer     = (void **)malloc(sizeof(void *) * new_capacity);
        if (!pointer) return false;
        pointer[0] = value;
        // for (size_t i = 0; i < array->size; i++)
        //     pointer[i + 1] = array->pointer[i];
        memcpy(pointer + 1, array->pointer, sizeof(void *) * array->size);
        free(array->pointer);
        array->capacity = new_capacity;
        array->pointer  = pointer;
        array->size++;
        return true;
    }
    // for (size_t i = array->size; i > 0; i--)
    //     array->pointer[i] = array->pointer[i - 1];
    memmove(array->pointer + 1, array->pointer, sizeof(void *) * array->size);
    array->pointer[0] = value;
    array->size++;
    return true;
}
// 获取元素
void *array_at(Array *array, size_t index) {
    if (!array) return NULL;
    if (array->size - 1 < index) return NULL;
    return array->pointer[index];
}
// 删除最后一个元素
void array_remove_back(Array *array) {
    if (!array) return;
    // array->pointer[array->size - 1] = NULL;
    array->size--;
}
// 删除第一个元素
bool array_remove_first(Array *array) {
    if (!array) return false;
    size_t size = array->size - 1;
    // for (size_t i = 0; i < size; i++)
    //     array->pointer[i] = array->pointer[i + 1];
    memmove(array->pointer, array->pointer + 1, sizeof(void *) * size);
    // array->pointer[size] = NULL;
    array->size--;
    return true;
}
// 插入元素
bool array_insert(Array *array, size_t index, void *value) {
    if (!array) return false;
    if (array->size < index) return false;
    size_t move_size = array->size - index;
    if (array->capacity == array->size) {
        size_t new_capacity = array->capacity * ((ARRAY_SCALE_RATIO_ > ARRAY_SCALE_RATIO) ? ARRAY_SCALE_RATIO_ : ARRAY_SCALE_RATIO);
        void **pointer     = (void **)malloc(sizeof(void *) * new_capacity);
        if (!pointer) return false;
        // for (size_t i = 0; i < array->size; i++) {
        //     if (i < index) pointer[i] = array->pointer[i];
        //     if (i == index) pointer[i] = value;
        //     if (i > index) pointer[i + 1] = array->pointer[i];
        // }
        memcpy(pointer, array->pointer, sizeof(void *) * index);
        pointer[index] = value;
        memcpy(pointer + index + 1, array->pointer + index, sizeof(void *) * move_size);
        free(array->pointer);
        array->capacity = new_capacity;
        array->pointer  = pointer;
        array->size++;
        return true;
    }
    // for (size_t i = index; i < array->size; i++) {
    //     array->pointer[i + 1] = array->pointer[i];
    // }
    memmove(array->pointer + index + 1, array->pointer + index, sizeof(void *) * move_size);
    array->pointer[index] = value;
    array->size++;
    return true;
}
// 删除元素
bool array_remove(Array *array, size_t index) {
    if (!array) return false;
    size_t size = array->size - 1;
    if (size < index) return false;
    // for (size_t i = index; i < size; i++) {
    //     array->pointer[i] = array->pointer[i + 1];
    // }
    memmove(array->pointer + index, array->pointer + index + 1, sizeof(void *) * size);
    array->pointer[size] = NULL;
    array->size--;
    return true;
}
// 清空数组
void array_clean(Array *array) {
    array->size = 0;
}
// 释放数组
void array_free(Array *array) {
    free(array->pointer);
    free(array);
}
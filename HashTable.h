//----------------------------------------------------------------------------------------------------------------------
// A simple hash table for various types of values
// Copyright (c) 2024 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Types.h"
#include <cstdint>
#include <unordered_map>

struct __HashTable_Value
{
    union
    {
        int64_t i64;
        int32_t i32;
        int16_t i16;
        int8_t i8;
        float f32;
        double f64;
        uintptr_t ptr;
    };
};

inline uintptr_t HashTable_Create()
{
    return reinterpret_cast<uintptr_t>(new std::unordered_map<uintptr_t, __HashTable_Value>());
}

inline void HashTable_Destroy(uintptr_t hTable)
{
    delete reinterpret_cast<std::unordered_map<uintptr_t, __HashTable_Value> *>(hTable);
}

inline void HashTable_Clear(uintptr_t hTable)
{
    reinterpret_cast<std::unordered_map<uintptr_t, __HashTable_Value> *>(hTable)->clear();
}

inline size_t HashTable_Size(uintptr_t hTable)
{
    return reinterpret_cast<std::unordered_map<uintptr_t, __HashTable_Value> *>(hTable)->size();
}

inline qb_bool HashTable_IsEmpty(uintptr_t hTable)
{
    return TO_QB_BOOL((reinterpret_cast<std::unordered_map<uintptr_t, __HashTable_Value> *>(hTable)->empty()));
}

inline qb_bool HashTable_Contains(uintptr_t hTable, uintptr_t key)
{
    auto &table = *reinterpret_cast<std::unordered_map<uintptr_t, __HashTable_Value> *>(hTable);
    return TO_QB_BOOL(table.find(key) != table.end());
}

template <typename T>
inline void HashTable_Set(uintptr_t hTable, uintptr_t key, T value)
{
    *reinterpret_cast<T *>(&(reinterpret_cast<std::unordered_map<uintptr_t, __HashTable_Value> *>(hTable)->operator[](key))) = value;
}

template <typename T>
inline T HashTable_Get(uintptr_t hTable, uintptr_t key)
{
    return *reinterpret_cast<T *>(&reinterpret_cast<std::unordered_map<uintptr_t, __HashTable_Value> *>(hTable)->at(key));
}

inline qb_bool HashTable_Remove(uintptr_t hTable, uintptr_t key)
{
    return TO_QB_BOOL((reinterpret_cast<std::unordered_map<uintptr_t, __HashTable_Value> *>(hTable)->erase(key)));
}

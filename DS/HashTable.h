//----------------------------------------------------------------------------------------------------------------------
// C++ unordered map wrapper library for QB64-PE
// Copyright (c) 2025 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Types.h"
#include <unordered_map>
#include <string>
#include <string_view>

// These makes our life easier
using HashTable_BinaryBlobView_ = std::string_view;
using HashTable_BinaryBlob_ = std::string;
using HashTable_ = std::unordered_map<HashTable_BinaryBlob_, HashTable_BinaryBlob_>;

/// @brief Creates a new hash table.
/// @return A pointer (QB64 _OFFSET) to the hash table.
inline uintptr_t HashTable_Create()
{
    return reinterpret_cast<uintptr_t>(new HashTable_());
}

/// @brief Destroys a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
inline void HashTable_Destroy(uintptr_t hTable)
{
    delete reinterpret_cast<HashTable_ *>(hTable);
}

/// @brief Clears a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
inline void HashTable_Clear(uintptr_t hTable)
{
    reinterpret_cast<HashTable_ *>(hTable)->clear();
}

/// @brief Gets the size of a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @return The size (QB64 _OFFSET) of the hash table.
inline size_t HashTable_Size(uintptr_t hTable)
{
    return reinterpret_cast<HashTable_ *>(hTable)->size();
}

/// @brief Checks if a hash table is empty.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @return _TRUE if the hash table is empty, _FALSE otherwise.
inline qb_bool HashTable_IsEmpty(uintptr_t hTable)
{
    return TO_QB_BOOL((reinterpret_cast<HashTable_ *>(hTable)->empty()));
}

/// @brief Checks if a hash table contains a key.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (any QB64 numeric type) to check.
/// @return _TRUE if the hash table contains the key, _FALSE otherwise.
template <typename K>
inline qb_bool HashTable_Contains_(uintptr_t hTable, K key)
{
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);

    HashTable_BinaryBlobView_ keyBlob(reinterpret_cast<const char *>(&key), sizeof(K));

    return TO_QB_BOOL(table.find(keyBlob) != table.end());
}

/// @brief Checks if a hash table contains a key.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (QB64 string) to check.
/// @param keySize The size of the QB64 string (in bytes).
/// @return _TRUE if the hash table contains the key, _FALSE otherwise.
inline qb_bool HashTable_StringContains_(uintptr_t hTable, const char *key, size_t keySize)
{
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);

    HashTable_BinaryBlobView_ keyBlob(key, keySize);

    return TO_QB_BOOL(table.find(keyBlob) != table.end());
}

/// @brief Removes a key from a hash table.
/// @tparam K The key type.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (any QB64 numeric type) to remove.
/// @return _TRUE if the key was removed, _FALSE otherwise.
template <typename K>
inline qb_bool HashTable_Remove_(uintptr_t hTable, K key)
{
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);

    HashTable_BinaryBlobView_ keyBlob(reinterpret_cast<const char *>(&key), sizeof(K));

    return TO_QB_BOOL(table.erase(keyBlob));
}

/// @brief Removes a key from a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (QB64 string) to remove.
/// @param keySize The size of the QB64 string (in bytes).
/// @return _TRUE if the key was removed, _FALSE otherwise.
inline qb_bool HashTable_StringRemove_(uintptr_t hTable, const char *key, size_t keySize)
{
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);

    HashTable_BinaryBlobView_ keyBlob(key, keySize);

    return TO_QB_BOOL(table.erase(keyBlob));
}

/// @brief Sets a key-value pair in a hash table.
/// @tparam K The key type.
/// @tparam V The value type.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (any QB64 numeric type) to set.
/// @param value The value (any QB64 numeric type) to set.
template <typename K, typename V>
inline void HashTable_Set_(uintptr_t hTable, K key, V value)
{
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);

    HashTable_BinaryBlobView_ keyBlob(reinterpret_cast<const char *>(&key), sizeof(K));
    HashTable_BinaryBlobView_ valueBlob(reinterpret_cast<const char *>(&value), sizeof(V));

    table[keyBlob] = valueBlob;
}

/// @brief Sets a key-value pair in a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (QB64 string) to set.
/// @param keySize The size of the QB64 string (in bytes).
/// @param value The value (any QB64 numeric type) to set.
template <typename V>
inline void HashTable_StringSet_(uintptr_t hTable, const char *key, size_t keySize, V value)
{
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);

    HashTable_BinaryBlobView_ keyBlob(key, keySize);
    HashTable_BinaryBlobView_ valueBlob(reinterpret_cast<const char *>(&value), sizeof(V));

    table[keyBlob] = valueBlob;
}

/// @brief Sets a key-value pair in a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (QB64 string) to set.
/// @param keySize The size of the QB64 string (in bytes).
/// @param value The value (QB64 string) to set.
/// @param valueSize The size of the QB64 string (in bytes).
inline void HashTable_StringSetString_(uintptr_t hTable, const char *key, size_t keySize, const char *value, size_t valueSize)
{
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);

    HashTable_BinaryBlobView_ keyBlob(key, keySize);
    HashTable_BinaryBlobView_ valueBlob(value, valueSize);

    table[keyBlob] = valueBlob;
}

/// @brief Gets a value from a hash table.
/// @tparam K The key type.
/// @tparam T The value type.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (any QB64 numeric type) to get.
/// @return The value (any QB64 numeric type) associated with the key.
template <typename K, typename T>
inline T HashTable_Get_(uintptr_t hTable, K key)
{
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);

    HashTable_BinaryBlobView_ keyBlob(reinterpret_cast<const char *>(&key), sizeof(K));

    if (table.find(keyBlob) != table.end())
    {
        return *reinterpret_cast<T *>(table[keyBlob].data());
    }

    return T();
}

/// @brief Gets a value from a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (QB64 string) to get.
/// @param keySize The size of the QB64 string (in bytes).
/// @return The value (any QB64 numeric type) associated with the key.
template <typename T>
inline T HashTable_StringGet_(uintptr_t hTable, const char *key, size_t keySize)
{
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);

    HashTable_BinaryBlobView_ keyBlob(key, keySize);

    if (table.find(keyBlob) != table.end())
    {
        return *reinterpret_cast<T *>(table[keyBlob].data());
    }

    return T();
}

/// @brief Gets a value from a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (QB64 string) to get.
/// @param keySize The size of the QB64 string (in bytes).
/// @return The value (QB64 string) associated with the key.
inline const char *HashTable_StringGetString_(uintptr_t hTable, const char *key, size_t keySize)
{
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);

    HashTable_BinaryBlobView_ keyBlob(key, keySize);

    if (table.find(keyBlob) != table.end())
    {
        return table[keyBlob].c_str();
    }

    return nullptr;
}

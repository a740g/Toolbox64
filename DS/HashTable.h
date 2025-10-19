//----------------------------------------------------------------------------------------------------------------------
// C++17 unordered map wrapper library for QB64-PE
// Copyright (c) 2025 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "../StringOps.h"
#include "../Types.h"
#include <algorithm>
#include <cstring>
#include <string>
#include <unordered_map>

// Aliases for clarity
using HashTable_BinaryBlob_ = std::string;

// Backing container
using HashTable_ = std::unordered_map<HashTable_BinaryBlob_, HashTable_BinaryBlob_>;

/// @brief Creates a new hash table.
/// @return A pointer (QB64 _OFFSET) to the hash table.
inline uintptr_t HashTable_Create() {
    return reinterpret_cast<uintptr_t>(new HashTable_());
}

/// @brief Destroys a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
inline void HashTable_Destroy(uintptr_t hTable) {
    delete reinterpret_cast<HashTable_ *>(hTable);
}

/// @brief Clears a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
inline void HashTable_Clear(uintptr_t hTable) {
    reinterpret_cast<HashTable_ *>(hTable)->clear();
}

/// @brief Gets the size of a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @return The size (QB64 _OFFSET) of the hash table.
inline size_t HashTable_GetSize(uintptr_t hTable) {
    return reinterpret_cast<HashTable_ *>(hTable)->size();
}

/// @brief Checks if a hash table is empty.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @return _TRUE if the hash table is empty, _FALSE otherwise.
inline qb_bool HashTable_IsEmpty(uintptr_t hTable) {
    return TO_QB_BOOL(reinterpret_cast<HashTable_ *>(hTable)->empty());
}

/// @brief Checks if a hash table contains a key.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (any QB64 numeric type) to check.
/// @return _TRUE if the hash table contains the key, _FALSE otherwise.
inline qb_bool HashTable_Contains(uintptr_t hTable, uintptr_t key) {
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);
    HashTable_BinaryBlob_ keyBlob(reinterpret_cast<const char *>(&key), sizeof(key));
    return TO_QB_BOOL(table.find(keyBlob) != table.end());
}

/// @brief Checks if a hash table contains a key.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (QB64 string) to check.
/// @param keySize The size of the QB64 string (in bytes).
/// @return _TRUE if the hash table contains the key, _FALSE otherwise.
inline qb_bool HashTable_StringContains_(uintptr_t hTable, const char *key, size_t keySize) {
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);
    HashTable_BinaryBlob_ keyBlob(key, keySize);
    return TO_QB_BOOL(table.find(keyBlob) != table.end());
}

/// @brief Removes a key from a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (any QB64 numeric type) to remove.
/// @return _TRUE if the key was removed, _FALSE otherwise.
inline qb_bool HashTable_Remove(uintptr_t hTable, uintptr_t key) {
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);
    HashTable_BinaryBlob_ keyBlob(reinterpret_cast<const char *>(&key), sizeof(key));
    return TO_QB_BOOL(table.erase(keyBlob) != 0);
}

/// @brief Removes a key from a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (QB64 string) to remove.
/// @param keySize The size of the QB64 string (in bytes).
/// @return _TRUE if the key was removed, _FALSE otherwise.
inline qb_bool HashTable_StringRemove_(uintptr_t hTable, const char *key, size_t keySize) {
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);
    HashTable_BinaryBlob_ keyBlob(key, keySize);
    return TO_QB_BOOL(table.erase(keyBlob) != 0);
}

/// @brief Sets a key-value pair in a hash table.
/// @tparam T The value type.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (any QB64 numeric type) to set.
/// @param value The value (any QB64 numeric type) to set.
template <typename T> inline void HashTable_Set(uintptr_t hTable, uintptr_t key, T value) {
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);
    HashTable_BinaryBlob_ keyBlob(reinterpret_cast<const char *>(&key), sizeof(key));
    HashTable_BinaryBlob_ valBlob(reinterpret_cast<const char *>(&value), sizeof(T));
    table.insert_or_assign(std::move(keyBlob), std::move(valBlob));
}

/// @brief Sets a key-value pair in a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (any QB64 numeric type) to set.
/// @param value The value (any pointer) to set. This can a QB64 STRING or UDT.
/// @param valueSize The size of the value (in bytes).
inline void HashTable_SetBlob_(uintptr_t hTable, uintptr_t key, uintptr_t value, size_t valueSize) {
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);
    HashTable_BinaryBlob_ keyBlob(reinterpret_cast<const char *>(&key), sizeof(key));
    HashTable_BinaryBlob_ valBlob(reinterpret_cast<const char *>(value), valueSize);
    table.insert_or_assign(std::move(keyBlob), std::move(valBlob));
}

/// @brief Sets a key-value pair in a hash table.
/// @tparam T The value type.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (QB64 string) to set.
/// @param keySize The size of the QB64 string (in bytes).
/// @param value The value (any QB64 numeric type) to set.
template <typename T> inline void HashTable_StringSet_(uintptr_t hTable, const char *key, size_t keySize, T value) {
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);
    HashTable_BinaryBlob_ keyBlob(key, keySize);
    HashTable_BinaryBlob_ valBlob(reinterpret_cast<const char *>(&value), sizeof(T));
    table.insert_or_assign(std::move(keyBlob), std::move(valBlob));
}

/// @brief Sets a key-value pair in a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (QB64 string) to set.
/// @param keySize The size of the QB64 string (in bytes).
/// @param value The value (any pointer) to set. This can a QB64 STRING or UDT.
/// @param valueSize The size of the value (in bytes).
inline void HashTable_StringSetBlob_(uintptr_t hTable, const char *key, size_t keySize, uintptr_t value, size_t valueSize) {
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);
    HashTable_BinaryBlob_ keyBlob(key, keySize);
    HashTable_BinaryBlob_ valBlob(reinterpret_cast<const char *>(value), valueSize);
    table.insert_or_assign(std::move(keyBlob), std::move(valBlob));
}

/// @brief Gets a value from a hash table.
/// @tparam T The value type.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (any QB64 numeric type) to get.
/// @return The value (any QB64 numeric type) associated with the key.
template <typename T> inline T HashTable_Get(uintptr_t hTable, uintptr_t key) {
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);
    HashTable_BinaryBlob_ keyBlob(reinterpret_cast<const char *>(&key), sizeof(key));

    const auto it = table.find(keyBlob);
    if (it == table.end()) {
        return T();
    }

    T out{};
    const auto &buf = it->second;
    std::memcpy(&out, buf.data(), std::min(buf.size(), sizeof(T)));
    return out;
}

/// @brief Gets a value from a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (any QB64 numeric type) to get.
/// @param value The value (UDT pointer) to get.
/// @param valueSize The size of the value (in bytes).
inline qb_bool HashTable_GetUDT(uintptr_t hTable, uintptr_t key, uintptr_t value, size_t valueSize) {
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);
    HashTable_BinaryBlob_ keyBlob(reinterpret_cast<const char *>(&key), sizeof(key));

    const auto it = table.find(keyBlob);
    if (it == table.end()) {
        return QB_FALSE;
    }

    const auto &buf = it->second;
    std::memcpy(reinterpret_cast<void *>(value), buf.data(), std::min(buf.size(), valueSize));
    return QB_TRUE;
}

/// @brief Gets a value from a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (any QB64 numeric type) to get.
/// @return The value (QB64 string) associated with the key.
inline const char *HashTable_GetString_(uintptr_t hTable, uintptr_t key) {
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);
    HashTable_BinaryBlob_ keyBlob(reinterpret_cast<const char *>(&key), sizeof(key));

    const auto it = table.find(keyBlob);
    if (it == table.end()) {
        return String_Empty;
    }

    return it->second.c_str();
}

/// @brief Gets a value from a hash table.
/// @tparam T The value type.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (QB64 string) to get.
/// @param keySize The size of the QB64 string (in bytes).
/// @return The value (any QB64 numeric type) associated with the key.
template <typename T> inline T HashTable_StringGet_(uintptr_t hTable, const char *key, size_t keySize) {
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);
    HashTable_BinaryBlob_ keyBlob(key, keySize);

    const auto it = table.find(keyBlob);
    if (it == table.end()) {
        return T();
    }

    T out{};
    const auto &buf = it->second;
    std::memcpy(&out, buf.data(), std::min(buf.size(), sizeof(T)));
    return out;
}

/// @brief Gets a value from a hash table.
/// @param hTable A pointer (QB64 _OFFSET) to the hash table.
/// @param key The key (QB64 string) to get.
/// @param keySize The size of the QB64 string (in bytes).
/// @param value The value (any pointer) to get. This can a QB64 STRING or UDT.
/// @param valueSize The size of the value (in bytes).
inline qb_bool HashTable_StringGetBlob_(uintptr_t hTable, const char *key, size_t keySize, uintptr_t value, size_t valueSize) {
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);
    HashTable_BinaryBlob_ keyBlob(key, keySize);

    const auto it = table.find(keyBlob);
    if (it == table.end()) {
        return QB_FALSE;
    }

    const auto &buf = it->second;
    std::memcpy(reinterpret_cast<void *>(value), buf.data(), std::min(buf.size(), valueSize));
    return QB_TRUE;
}

/// @brief Gets a value from a hash table.
/// @param hTable A pointer (QB64 OFFSET) to the hash table.
/// @param key The key (QB64 string) to get.
/// @param keySize The size of the QB64 string (in bytes).
/// @return The value (QB64 string) associated with the key.
inline const char *HashTable_StringGetString_(uintptr_t hTable, const char *key, size_t keySize) {
    auto &table = *reinterpret_cast<HashTable_ *>(hTable);
    HashTable_BinaryBlob_ keyBlob(key, keySize);

    const auto it = table.find(keyBlob);
    if (it == table.end()) {
        return String_Empty;
    }

    return it->second.c_str();
}

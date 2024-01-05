//----------------------------------------------------------------------------------------------------------------------
// File I/O like routines for memory loaded files
// Copyright (c) 2024 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Debug.h"
#include "Types.h"
#include <cstdint>
#include <algorithm>
#include <vector>

/// @brief A pointer to an object of this struct is returned by MemFile_Create()
struct MemFile
{
    std::vector<uint8_t> buffer; // a std::vector of bytes
    size_t cursor;               // the current read / write position in the vector
};

/// @brief Creates a new MemFile object using an existing memory buffer
/// @param data A valid data buffer or nullptr
/// @param size The correct size of the data if data is not nullptr
/// @return A pointer to a new MemFile or nullptr on failure
uintptr_t MemFile_Create(uintptr_t data, size_t size)
{
    auto memFile = new MemFile;

    if (memFile)
    {
        memFile->buffer.assign(reinterpret_cast<const uint8_t *>(data), reinterpret_cast<const uint8_t *>(data) + size);
        memFile->cursor = 0;
    }

    return reinterpret_cast<uintptr_t>(memFile);
}

/// @brief Deletes a MemFile object created using MemFile_Create()
/// @param p A valid pointer to a MemFile object
void MemFile_Destroy(uintptr_t p)
{
    if (p)
        delete reinterpret_cast<MemFile *>(p);
    else
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
}

/// @brief Returns QB_TRUE if the cursor moved past the end of the buffer
/// @param p A valid pointer to a MemFile object
/// @return QB_TRUE if EOF, QB_FALSE otherwise
qb_bool MemFile_IsEOF(uintptr_t p)
{
    auto memFile = reinterpret_cast<const MemFile *>(p);

    if (memFile)
        return TO_QB_BOOL(memFile->cursor >= memFile->buffer.size());

    error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
    return QB_FALSE;
}

/// @brief Returns the size of the buffer in bytes
/// @param p A valid pointer to a MemFile object
/// @return The size of the buffer in bytes
size_t MemFile_GetSize(uintptr_t p)
{
    auto memFile = reinterpret_cast<const MemFile *>(p);

    if (memFile)
        return memFile->buffer.size();

    error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
    return 0;
}

/// @brief Returns the cursor position
/// @param p A valid pointer to a MemFile object
/// @return The position from the origin
size_t MemFile_GetPosition(uintptr_t p)
{
    auto memFile = reinterpret_cast<const MemFile *>(p);

    if (memFile)
        return memFile->cursor;

    error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
    return 0;
}

/// @brief Position the read / write cursor inside the data buffer
/// @param p A valid pointer to a MemFile object
/// @param position A value that is less than or equal to the size of the buffer
void MemFile_Seek(uintptr_t p, size_t position)
{
    auto memFile = reinterpret_cast<MemFile *>(p);

    if (memFile && position <= memFile->buffer.size())
        memFile->cursor = position;
    else
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
}

/// @brief Resizes the buffer of a MemFile object
/// @param p A valid pointer to a MemFile object
/// @param newSize The new size of the buffer
void MemFile_Resize(uintptr_t p, size_t newSize)
{
    auto memFile = reinterpret_cast<MemFile *>(p);

    if (memFile)
    {
        memFile->buffer.resize(newSize);

        if (memFile->cursor > newSize)
            memFile->cursor = newSize;
    }
    else
    {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
    }
}

/// @brief Reads a chunk of data from the buffer at the cursor position
/// @param p A valid pointer to a MemFile object
/// @param data Pointer to the buffer the data needs to be written to
/// @param size The size of the chuck that needs to be read
/// @return The actual number of bytes read. This can be less than `size`
size_t MemFile_Read(uintptr_t p, uintptr_t data, size_t size)
{
    auto memFile = reinterpret_cast<MemFile *>(p);

    if (memFile && data)
    {
        auto bytesToRead = std::min(size, memFile->buffer.size() - memFile->cursor);
        if (bytesToRead > 0)
        {
            std::copy(memFile->buffer.begin() + memFile->cursor, memFile->buffer.begin() + memFile->cursor + bytesToRead, (uint8_t *)data);
            memFile->cursor += bytesToRead;
        }

        return bytesToRead;
    }
    else
    {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
    }

    return 0;
}

/// @brief Writes a chunk of data to the buffer at the cursor position (optionally growing the buffer size)
/// @param p A valid pointer to a MemFile object
/// @param data Pointer to the buffer the data needs to be read from
/// @param size The size of the chuck that needs to be written
/// @return The number of bytes written
size_t MemFile_Write(uintptr_t p, uintptr_t data, size_t size)
{
    auto memFile = reinterpret_cast<MemFile *>(p);

    if (memFile && data)
    {
        memFile->buffer.insert(memFile->buffer.begin() + memFile->cursor, (uint8_t *)data, (uint8_t *)data + size);
        memFile->cursor += size;

        return size;
    }
    else
    {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
    }

    return 0;
}

/// @brief Reads a value of type T from the buffer at the cursor position
/// @tparam T A valid C+ type
/// @param p A valid pointer to a MemFile object
/// @return The T value read
template <typename T>
inline T MemFile_Read(uintptr_t p)
{
    T value = T();

    if (MemFile_Read(p, reinterpret_cast<uintptr_t>(&value), sizeof(T)) != sizeof(T))
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);

    return value;
}

/// @brief Writes a value of type T to the buffer at the cursor position
/// @tparam T A valid C+ type
/// @param p A valid pointer to a MemFile object
/// @param value The T value to write
template <typename T>
inline void MemFile_Write(uintptr_t p, T value)
{
    if (MemFile_Write(p, reinterpret_cast<uintptr_t>(&value), sizeof(T)) != sizeof(T))
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
}

#define MemFile_ReadByte(p) MemFile_Read<uint8_t>(p)
#define MemFile_WriteByte(p, byte) MemFile_Write<uint8_t>((p), (byte))
#define MemFile_ReadInteger(p) MemFile_Read<uint16_t>(p)
#define MemFile_WriteInteger(p, word) MemFile_Write<uint16_t>((p), (word))
#define MemFile_ReadLong(p) MemFile_Read<uint32_t>(p)
#define MemFile_WriteLong(p, dword) MemFile_Write<uint32_t>((p), (dword))
#define MemFile_ReadSingle(p) MemFile_Read<float>(p)
#define MemFile_WriteSingle(p, fp32) MemFile_Write<float>((p), (fp32))
#define MemFile_ReadInteger64(p) MemFile_Read<uint64_t>(p)
#define MemFile_WriteInteger64(p, qword) MemFile_Write<uint64_t>((p), (qword))
#define MemFile_ReadDouble(p) MemFile_Read<double>(p)
#define MemFile_WriteDouble(p, fp64) MemFile_Write<double>((p), (fp64))

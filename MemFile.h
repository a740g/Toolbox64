//----------------------------------------------------------------------------------------------------------------------
// File I/O like routines for memory loaded files
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <vector>
#include <algorithm>
#define TOOLBOX64_DEBUG 1
#include "Common.h"

/// @brief A pointer to an object of this struct is returned by MemFile_Create()
struct MemFile
{
    std::vector<uint8_t> buffer; // a std::vector of bytes
    size_t cursor;               // the current read / write position in the vector
};

#ifdef MEMFILE_HEADER_ONLY

MemFile *__MemFile_Create(const uint8_t *data, size_t size);
void MemFile_Destroy(MemFile *memFile);
qb_bool MemFile_IsEOF(const MemFile *memFile);
size_t MemFile_GetSize(const MemFile *memFile);
qb_bool MemFile_Seek(MemFile *memFile, size_t position);
void MemFile_Resize(MemFile *memFile, size_t newSize);
size_t __MemFile_Read(MemFile *memFile, uint8_t *data, size_t size);
size_t __MemFile_Write(MemFile *memFile, const uint8_t *data, size_t size);
qb_bool MemFile_ReadByte(MemFile *memFile, uint8_t *byte);
qb_bool MemFile_WriteByte(MemFile *memFile, uint8_t byte);
qb_bool MemFile_ReadInteger(MemFile *memFile, uint16_t *word);
qb_bool MemFile_WriteInteger(MemFile *memFile, uint16_t word);
qb_bool MemFile_ReadLong(MemFile *memFile, uint32_t *dword);
qb_bool MemFile_WriteLong(MemFile *memFile, uint32_t dword);
qb_bool MemFile_ReadSingle(MemFile *memFile, float *fp32);
qb_bool MemFile_WriteSingle(MemFile *memFile, float fp32);
qb_bool MemFile_ReadInteger64(MemFile *memFile, uint64_t *qword);
qb_bool MemFile_WriteInteger64(MemFile *memFile, uint64_t qword);
qb_bool MemFile_ReadDouble(MemFile *memFile, double *fp64);
qb_bool MemFile_WriteDouble(MemFile *memFile, double fp64);

#else

/// @brief Creates a new MemFile object using an existing memory buffer
/// @param data A valid data buffer or nullptr
/// @param size The correct size of the data if data is not nullptr
/// @return A pointer to a new MemFile or nullptr on failure
MemFile *__MemFile_Create(const uint8_t *data, size_t size)
{
    TOOLBOX64_DEBUG_PRINT("Data pointer = %p, Size = %zu", data, size);

    auto memFile = new MemFile;

    if (memFile)
    {
        memFile->buffer = std::vector<uint8_t>(data, data + size);
        memFile->cursor = 0;

        TOOLBOX64_DEBUG_PRINT("MemFile created: %p", memFile);

        return memFile;
    }

    TOOLBOX64_DEBUG_PRINT("Memory allocation failed");

    return nullptr;
}

/// @brief Deletes a MemFile object created using MemFile_Create()
/// @param memFile A valid pointer to a MemFile object
void MemFile_Destroy(MemFile *memFile)
{
    delete memFile;

    TOOLBOX64_DEBUG_PRINT("MemFile destroyed: %p", memFile);
}

/// @brief Returns QB_TRUE if the cursor moved past the end of the buffer
/// @param memFile A valid pointer to a MemFile object
/// @return QB_TRUE if EOF, QB_FALSE otherwise
qb_bool MemFile_IsEOF(const MemFile *memFile)
{
    if (memFile && memFile->cursor >= memFile->buffer.size())
    {
        TOOLBOX64_DEBUG_PRINT("End of file reached: %zu", memFile->cursor);

        return QB_TRUE;
    }

    return QB_FALSE;
}

/// @brief Returns the size of the buffer in bytes
/// @param memFile A valid pointer to a MemFile object
/// @return The size of the buffer in bytes
size_t MemFile_GetSize(const MemFile *memFile)
{
    if (memFile)
    {
        TOOLBOX64_DEBUG_PRINT("Buffer size: %zu", memFile->buffer.size());

        return memFile->buffer.size();
    }

    return 0;
}

/// @brief Position the read / write cursor inside the data buffer
/// @param memFile A valid pointer to a MemFile object
/// @param position A value that is less than or equal to the size of the buffer
/// @return QB_TRUE if successful, QB_FALSE otherwise
qb_bool MemFile_Seek(MemFile *memFile, size_t position)
{
    if (memFile && position <= memFile->buffer.size())
    {
        memFile->cursor = position;

        TOOLBOX64_DEBUG_PRINT("Moved cursor to %zu", position);

        return QB_TRUE;
    }

    TOOLBOX64_DEBUG_PRINT("Failed to re-position cursor");

    return QB_FALSE;
}

/// @brief Resizes the buffer of a MemFile object
/// @param memFile A valid pointer to a MemFile object
/// @param newSize The new size of the buffer
void MemFile_Resize(MemFile *memFile, size_t newSize)
{
    if (memFile)
    {
        memFile->buffer.resize(newSize);
        if (memFile->cursor > newSize)
        {
            memFile->cursor = newSize;
        }

        TOOLBOX64_DEBUG_PRINT("Resized buffer to %zu bytes", newSize);
    }
}

/// @brief Reads a chunk of data from the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param data Pointer to the buffer the data needs to be written to
/// @param size The size of the chuck that needs to be read
/// @return The actual number of bytes read. This can be less than `size`
size_t __MemFile_Read(MemFile *memFile, uint8_t *data, size_t size)
{
    if (memFile && data)
    {
        auto bytesToRead = std::min(size, memFile->buffer.size() - memFile->cursor);
        if (bytesToRead > 0)
        {
            std::copy(memFile->buffer.begin() + memFile->cursor, memFile->buffer.begin() + memFile->cursor + bytesToRead, data);
            memFile->cursor += bytesToRead;

            TOOLBOX64_DEBUG_PRINT("Read %zu bytes and moved cursor to %zu", bytesToRead, memFile->cursor);
        }

        return bytesToRead;
    }

    TOOLBOX64_DEBUG_PRINT("Failed to read data");

    return 0;
}

/// @brief Writes a chunk of data to the buffer at the cursor position (optionally growing the buffer size)
/// @param memFile A valid pointer to a MemFile object
/// @param data Pointer to the buffer the data needs to be read from
/// @param size The size of the chuck that needs to be written
/// @return The number of bytes written
size_t __MemFile_Write(MemFile *memFile, const uint8_t *data, size_t size)
{
    if (memFile && data)
    {
        memFile->buffer.insert(memFile->buffer.begin() + memFile->cursor, data, data + size);
        memFile->cursor += size;

        TOOLBOX64_DEBUG_PRINT("Wrote %zu bytes and moved cursor to %zu", size, memFile->cursor);

        return size;
    }

    TOOLBOX64_DEBUG_PRINT("Failed to write data");

    return 0;
}

/// @brief Reads a byte (1 byte) from the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param byte Pointer to store the read byte value
/// @return QB_TRUE if successful, QB_FALSE otherwise
qb_bool MemFile_ReadByte(MemFile *memFile, uint8_t *byte)
{
    return __MemFile_Read(memFile, byte, sizeof(uint8_t)) == sizeof(uint8_t) ? QB_TRUE : QB_FALSE;
}

/// @brief Writes a byte (1 byte) to the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param byte The byte value to write
/// @return QB_TRUE if successful, QB_FALSE otherwise
qb_bool MemFile_WriteByte(MemFile *memFile, uint8_t byte)
{
    return __MemFile_Write(memFile, &byte, sizeof(uint8_t)) == sizeof(uint8_t) ? QB_TRUE : QB_FALSE;
}

/// @brief Reads a 16-bit word (2 bytes) from the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param word Pointer to store the read 16-bit word value
/// @return QB_TRUE if successful, QB_FALSE otherwise
qb_bool MemFile_ReadInteger(MemFile *memFile, uint16_t *word)
{
    return __MemFile_Read(memFile, reinterpret_cast<uint8_t *>(word), sizeof(uint16_t)) == sizeof(uint16_t) ? QB_TRUE : QB_FALSE;
}

/// @brief Writes a 16-bit word (2 bytes) to the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param word The 16-bit word value to write
/// @return QB_TRUE if successful, QB_FALSE otherwise
qb_bool MemFile_WriteInteger(MemFile *memFile, uint16_t word)
{
    return __MemFile_Write(memFile, reinterpret_cast<const uint8_t *>(&word), sizeof(uint16_t)) == sizeof(uint16_t) ? QB_TRUE : QB_FALSE;
}

/// @brief Reads a 32-bit double word (4 bytes) from the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param dword Pointer to store the read 32-bit double word value
/// @return QB_TRUE if successful, QB_FALSE otherwise
qb_bool MemFile_ReadLong(MemFile *memFile, uint32_t *dword)
{
    return __MemFile_Read(memFile, reinterpret_cast<uint8_t *>(dword), sizeof(uint32_t)) == sizeof(uint32_t) ? QB_TRUE : QB_FALSE;
}

/// @brief Writes a 32-bit double word (4 bytes) to the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param dword The 32-bit double word value to write
/// @return QB_TRUE if successful, QB_FALSE otherwise
qb_bool MemFile_WriteLong(MemFile *memFile, uint32_t dword)
{
    return __MemFile_Write(memFile, reinterpret_cast<const uint8_t *>(&dword), sizeof(uint32_t)) == sizeof(uint32_t) ? QB_TRUE : QB_FALSE;
}

/// @brief Reads a fp32 (4 bytes) from the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param dword Pointer to store the read fp32 value
/// @return QB_TRUE if successful, QB_FALSE otherwise
qb_bool MemFile_ReadSingle(MemFile *memFile, float *fp32)
{
    return __MemFile_Read(memFile, reinterpret_cast<uint8_t *>(fp32), sizeof(float)) == sizeof(float) ? QB_TRUE : QB_FALSE;
}

/// @brief Writes a fp32 (4 bytes) to the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param dword The fp32 value to write
/// @return QB_TRUE if successful, QB_FALSE otherwise
qb_bool MemFile_WriteSingle(MemFile *memFile, float fp32)
{
    return __MemFile_Write(memFile, reinterpret_cast<const uint8_t *>(&fp32), sizeof(float)) == sizeof(float) ? QB_TRUE : QB_FALSE;
}

/// @brief Reads a 64-bit qword (8 bytes) from the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param int64 Pointer to store the read 64-bit qword value
/// @return QB_TRUE if successful, QB_FALSE otherwise
qb_bool MemFile_ReadInteger64(MemFile *memFile, uint64_t *qword)
{
    return __MemFile_Read(memFile, reinterpret_cast<uint8_t *>(qword), sizeof(uint64_t)) == sizeof(uint64_t) ? QB_TRUE : QB_FALSE;
}

/// @brief Writes a 64-bit qword (8 bytes) to the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param int64 The 64-bit qword value to write
/// @return QB_TRUE if successful, QB_FALSE otherwise
qb_bool MemFile_WriteInteger64(MemFile *memFile, uint64_t qword)
{
    return __MemFile_Write(memFile, reinterpret_cast<const uint8_t *>(&qword), sizeof(uint64_t)) == sizeof(uint64_t) ? QB_TRUE : QB_FALSE;
}

/// @brief Reads a fp64 (8 bytes) from the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param int64 Pointer to store the read fp64 value
/// @return QB_TRUE if successful, QB_FALSE otherwise
qb_bool MemFile_ReadDouble(MemFile *memFile, double *fp64)
{
    return __MemFile_Read(memFile, reinterpret_cast<uint8_t *>(fp64), sizeof(double)) == sizeof(double) ? QB_TRUE : QB_FALSE;
}

/// @brief Writes a fp64 (8 bytes) to the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param int64 The fp64 value to write
/// @return QB_TRUE if successful, QB_FALSE otherwise
qb_bool MemFile_WriteDouble(MemFile *memFile, double fp64)
{
    return __MemFile_Write(memFile, reinterpret_cast<const uint8_t *>(&fp64), sizeof(double)) == sizeof(double) ? QB_TRUE : QB_FALSE;
}

#endif

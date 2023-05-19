//----------------------------------------------------------------------------------------------------------------------
// File I/O like routines memory loaded files
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <iostream>
#include <vector>
#include <algorithm>
#define TOOLBOX64_DEBUG 1
#include "Logger.h"

/// @brief A pointer to an object of this struct is returned by MemFile_Create()
struct MemFile
{
    std::vector<uint8_t> buffer;
    size_t cursor;
};

/// @brief Creates a new MemFile object using an existing memory buffer
/// @param data A valid data buffer or nullptr
/// @param size The correct size of the data if data is not nullptr
/// @return A pointer to a new MemFile or nullptr on failure
MemFile *MemFile_Create(const uint8_t *data, size_t size)
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

/// @brief Returns true if the cursor moved past the end of the buffer
/// @param memFile A valid pointer to a MemFile object
/// @return True if EOF, false otherwise
bool MemFile_IsEOF(const MemFile *memFile)
{
    if (memFile && memFile->cursor >= memFile->buffer.size())
    {
        TOOLBOX64_DEBUG_PRINT("End of file reached: %zu", memFile->cursor);

        return true;
    }

    return false;
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
/// @return True if successful, false otherwise
bool MemFile_Seek(MemFile *memFile, size_t position)
{
    if (memFile && position <= memFile->buffer.size())
    {
        memFile->cursor = position;

        TOOLBOX64_DEBUG_PRINT("Moved cursor to %zu", position);

        return true;
    }

    TOOLBOX64_DEBUG_PRINT("Failed to re-position cursor");

    return false;
}

/// @brief Reads a chunk of data from the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param data Pointer to the buffer the data needs to be written to
/// @param size The size of the chuck that needs to be read
/// @return The actual number of bytes read. This can be less than `size`
size_t MemFile_Read(MemFile *memFile, uint8_t *data, size_t size)
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
size_t MemFile_Write(MemFile *memFile, const uint8_t *data, size_t size)
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
/// @return True if successful, false otherwise
bool MemFile_ReadByte(MemFile *memFile, uint8_t *byte)
{
    return MemFile_Read(memFile, byte, sizeof(uint8_t)) == sizeof(uint8_t);
}

/// @brief Writes a byte (1 byte) to the buffer at the cursor position
/// @param memFile A valid pointer to a MemFile object
/// @param byte The byte value to write
/// @return True if successful, false otherwise
bool MemFile_WriteByte(MemFile *memFile, uint8_t byte)
{
    return MemFile_Write(memFile, &byte, sizeof(uint8_t)) == sizeof(uint8_t);
}

/// @brief Reads a 16-bit word (2 bytes) from the buffer at the cursor position (little-endian)
/// @param memFile A valid pointer to a MemFile object
/// @param word Pointer to store the read 16-bit word value
/// @return True if successful, false otherwise
bool MemFile_ReadInteger(MemFile *memFile, uint16_t *word)
{
    return MemFile_Read(memFile, reinterpret_cast<uint8_t *>(word), sizeof(uint16_t)) == sizeof(uint16_t);
}

/// @brief Writes a 16-bit word (2 bytes) to the buffer at the cursor position (little-endian)
/// @param memFile A valid pointer to a MemFile object
/// @param word The 16-bit word value to write
/// @return True if successful, false otherwise
bool MemFile_WriteInteger(MemFile *memFile, uint16_t word)
{
    return MemFile_Write(memFile, reinterpret_cast<const uint8_t *>(&word), sizeof(uint16_t)) == sizeof(uint16_t);
}

/// @brief Reads a 32-bit double word (4 bytes) from the buffer at the cursor position (little-endian)
/// @param memFile A valid pointer to a MemFile object
/// @param dword Pointer to store the read 32-bit double word value
/// @return True if successful, false otherwise
bool MemFile_ReadLong(MemFile *memFile, uint32_t *dword)
{
    return MemFile_Read(memFile, reinterpret_cast<uint8_t *>(dword), sizeof(uint32_t)) == sizeof(uint32_t);
}

/// @brief Writes a 32-bit double word (4 bytes) to the buffer at the cursor position (little-endian)
/// @param memFile A valid pointer to a MemFile object
/// @param dword The 32-bit double word value to write
/// @return True if successful, false otherwise
bool MemFile_WriteLong(MemFile *memFile, uint32_t dword)
{
    return MemFile_Write(memFile, reinterpret_cast<const uint8_t *>(&dword), sizeof(uint32_t)) == sizeof(uint32_t);
}

/// @brief Reads a 64-bit qword (8 bytes) from the buffer at the cursor position (little-endian)
/// @param memFile A valid pointer to a MemFile object
/// @param int64 Pointer to store the read 64-bit qword value
/// @return True if successful, false otherwise
bool MemFile_ReadInteger64(MemFile *memFile, uint64_t *qword)
{
    return MemFile_Read(memFile, reinterpret_cast<uint8_t *>(qword), sizeof(uint64_t)) == sizeof(uint64_t);
}

/// @brief Writes a 64-bit qword (8 bytes) to the buffer at the cursor position (little-endian)
/// @param memFile A valid pointer to a MemFile object
/// @param int64 The 64-bit qword value to write
/// @return True if successful, false otherwise
bool MemFile_WriteInteger64(MemFile *memFile, uint64_t qword)
{
    return MemFile_Write(memFile, reinterpret_cast<const uint8_t *>(&qword), sizeof(uint64_t)) == sizeof(uint64_t);
}

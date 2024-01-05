//----------------------------------------------------------------------------------------------------------------------
// File, path and filesystem routines
// Copyright (c) 2024 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Common.h"
#include <cstdint>
#include <algorithm>
#include <cstdio>
#include <cstring>
#include <sys/stat.h>

// These must be kept in sync with FileOps.bi
#define __FILE_ATTRIBUTE_DIRECTORY 1
#define __FILE_ATTRIBUTE_READOLY 2
#define __FILE_ATTRIBUTE_HIDDEN 4
#define __FILE_ATTRIBUTE_ARCHIVE 8
#define __FILE_ATTRIBUTE_SYSTEM 16

// TODO: Implement Win32 versions of these!

/// @brief Returns some basic attributes of a file or directory
/// @param pathName The path name to get the attribute for
/// @return A 32-bit value where each bit represents an attribute (see __FILE_* above)
inline uint32_t __GetFileAttributes(const char *pathName)
{
    uint32_t attributes = 0;

    struct stat info;
    stat(pathName, &info);

    // Read-only attribute
    if (!(info.st_mode & S_IWUSR))
        attributes |= __FILE_ATTRIBUTE_READOLY;

    // Hidden attribute (files starting with '.')
    if (pathName[0] == '.')
        attributes |= __FILE_ATTRIBUTE_HIDDEN;

    // System attribute (character devices, block devices, FIFOs)
    if (S_ISCHR(info.st_mode) || S_ISBLK(info.st_mode) || S_ISFIFO(info.st_mode))
        attributes |= __FILE_ATTRIBUTE_SYSTEM;

    // Directory or Archive attribute
    if (S_ISDIR(info.st_mode))
        attributes |= __FILE_ATTRIBUTE_DIRECTORY;
    else
        attributes |= __FILE_ATTRIBUTE_ARCHIVE; // Archive attribute for non-directory files

    return attributes;
}

/// @brief Returns the 64-bit file size without opening the file
/// @param fileName The file name to get the size for
/// @return A 64-bit integer value (size)
inline int64_t __GetFileSize(const char *fileName)
{
    struct stat64 st;

    if (stat64(fileName, &st) == 0 && S_ISREG(st.st_mode))
        return st.st_size;

    return -1; // -1 to indicate file not found or not a regular file
}

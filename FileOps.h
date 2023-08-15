//----------------------------------------------------------------------------------------------------------------------
// File, path and filesystem routines
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Common.h"
#include <cstdint>
#include <algorithm>
#include <cstdio>
#include <cstring>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>

// These must be kept in sync with FileOps.bi
#define __FILE_ATTRIBUTE_DIRECTORY 1
#define __FILE_ATTRIBUTE_READOLY 2
#define __FILE_ATTRIBUTE_HIDDEN 4
#define __FILE_ATTRIBUTE_ARCHIVE 8
#define __FILE_ATTRIBUTE_SYSTEM 16

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

/// @brief This is a basic pattern matching function used by __Dir64()
/// @param fileSpec The pattern to match
/// @param fileName The filename to match
/// @return True if it is a match, false otherwise
static inline bool __Dir64MatchSpec(const char *fileSpec, const char *fileName)
{
    auto spec = fileSpec;
    auto name = fileName;
    const char *any = nullptr;

    while (*spec || *name)
    {
        switch (*spec)
        {
        case '*':
            any = spec;
            spec++;
            while (*name && *name != *spec)
                name++;
            break;

        case '?':
            spec++;
            if (*name)
                name++;
            break;

        default:
            if (*spec != *name)
            {
                if (any && *name)
                    spec = any;
                else
                    return false;
            }
            else
            {
                spec++;
                name++;
            }
            break;
        }
    }

    return true;
}

/// @brief A MS BASIC PDS DIR$ style function
/// @param fileSpec This can be a directory with wildcard for the final level (i.e. C:/Windows/*.* or /usr/lib/* etc.)
/// @return Returns a file or directory name  matching fileSpec or an empty string when there is nothing left
inline const char *__Dir64(const char *fileSpec)
{
    static DIR *pDir = nullptr;
    static char pattern[FILENAME_MAX];

    commonTemporaryBuffer[0] = '\0'; // Set to an empty string

    if (!IS_STRING_EMPTY(fileSpec))
    {
        // We got a filespec. Check if we have one already going and if so, close it
        if (pDir)
        {
            closedir(pDir);
            pDir = nullptr;
        }

        char dirName[FILENAME_MAX]; // we only need this for opendir()

        if (strchr(fileSpec, '*') || strchr(fileSpec, '?'))
        {
            // We have a pattern. Check if we have a path in it
            auto p = strrchr(fileSpec, '/'); // try *nix style separator
#ifdef _WIN32
            if (!p)
                p = strrchr(fileSpec, '\\'); // try windows style separator
#endif

            if (p)
            {
                // Split the path and the filespec
                strncpy(pattern, p + 1, FILENAME_MAX);
                pattern[FILENAME_MAX - 1] = '\0';
                auto len = std::min<size_t>((p - fileSpec) + 1, FILENAME_MAX - 1);
                memcpy(dirName, fileSpec, len);
                dirName[len] = '\0';
            }
            else
            {
                // No path. Use the current path
                strncpy(pattern, fileSpec, FILENAME_MAX);
                pattern[FILENAME_MAX - 1] = '\0';
                strcpy(dirName, "./");
            }
        }
        else
        {
            // No pattern. We'll just assume it's a directory
            strncpy(dirName, fileSpec, FILENAME_MAX);
            dirName[FILENAME_MAX - 1] = '\0';
            strcpy(pattern, "*");
        }

        pDir = opendir(dirName);
    }

    if (pDir)
    {
        for (;;)
        {
            auto pDirent = readdir(pDir);
            if (!pDirent)
            {
                closedir(pDir);
                pDir = nullptr;

                break;
            }

            if (__Dir64MatchSpec(pattern, pDirent->d_name))
            {
                strncpy(commonTemporaryBuffer, pDirent->d_name, sizeof(commonTemporaryBuffer) - 1);
                commonTemporaryBuffer[sizeof(commonTemporaryBuffer) - 1] = '\0';

                break;
            }
        }
    }

    return commonTemporaryBuffer;
}

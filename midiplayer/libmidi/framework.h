
/** $VER: framework.h (2024.05.12) P. Stuer **/

#pragma once

#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <string>
#include <cstring>
#include <cstdarg>
#include <algorithm>
#include <cmath>
#include <cassert>
#include <vector>
#include <stdexcept>
#include <cerrno>

#define TOSTRING_IMPL(x) #x
#define TOSTRING(x) TOSTRING_IMPL(x)

#ifdef _DEBUG
#define _RCP_VERBOSE
#else
#undef _RCP_VERBOSE
#endif

#ifndef _countof
#ifndef __cplusplus
#define _countof(_Array) (sizeof(_Array) / sizeof(_Array[0]))
#else
template <typename T, size_t N>
static inline constexpr size_t _countof(T const (&_Array)[N])
{
    return std::extent<T[N]>::value;
}
#endif
#endif

static inline auto strcat_safe(char *dest, size_t destsz, const char *src)
{
    if (dest && src && destsz)
    {
        auto dest_len = strlen(dest);

        // Ensure there's enough space for the source string and null terminator
        if (dest_len + strlen(src) + 1 <= destsz)
        {
            strncat(dest, src, destsz - dest_len - 1);

            return 0; // success
        }
        else
        {
            return EINVAL; // dest is too small
        }
    }

    return EINVAL; // dest or src is null
}

static inline auto fopen_safe(FILE **file, const char *filename, const char *mode)
{
    if (!file)
        return EINVAL; // invalid argument

    *file = fopen(filename, mode);
    if (!(*file))
        return errno; // return the error code

    return 0; // success
}

static inline auto sprintf_safe(char *buffer, size_t size, const char *format, ...)
{
    if (!buffer || !format || !size)
        return -1;

    va_list args;
    va_start(args, format);
    auto result = vsnprintf(buffer, size, format, args);
    va_end(args);

    if (result < 0 || size_t(result) >= size)
        return -1;

    return result; // number of characters written, excluding null terminator
}

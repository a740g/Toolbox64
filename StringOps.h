//----------------------------------------------------------------------------------------------------------------------
// String related routines
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Common.h"
#include <cstring>

static char formatBuffer[4096]; // 4k static buffer

/// @brief Format a 32-bit integer
/// @param n A 32-bit integer
/// @param fmt The format specifier
/// @return A formatted string
inline const char *__FormatLong(int32_t n, const char *fmt)
{
    formatBuffer[0] = 0;
    snprintf(formatBuffer, sizeof(formatBuffer), fmt, n);
    return formatBuffer;
}

/// @brief Format a 64-bit integer
/// @param n A 64-bit integer
/// @param fmt The format specifier
/// @return A formatted string
inline const char *__FormatInteger64(int64_t n, const char *fmt)
{
    formatBuffer[0] = 0;
    snprintf(formatBuffer, sizeof(formatBuffer), fmt, n);
    return formatBuffer;
}

/// @brief Format a 32-bit float
/// @param n A 32-bit float
/// @param fmt The format specifier
/// @return A formatted string
inline const char *__FormatSingle(float n, const char *fmt)
{
    formatBuffer[0] = 0;
    snprintf(formatBuffer, sizeof(formatBuffer), fmt, n);
    return formatBuffer;
}

/// @brief Format a 64-bit double
/// @param n A 64-bit double
/// @param fmt The format specifier
/// @return A formatted string
inline const char *__FormatDouble(double n, const char *fmt)
{
    formatBuffer[0] = 0;
    snprintf(formatBuffer, sizeof(formatBuffer), fmt, n);
    return formatBuffer;
}

/// @brief Format a pointer
/// @param n A pointer
/// @param fmt The format specifier
/// @return A formatted string
inline const char *__FormatOffset(uintptr_t n, const char *fmt)
{
    formatBuffer[0] = 0;
    snprintf(formatBuffer, sizeof(formatBuffer), fmt, n);
    return formatBuffer;
}

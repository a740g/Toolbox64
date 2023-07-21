//----------------------------------------------------------------------------------------------------------------------
// String related routines
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Common.h"
#include <cstring>
#include <cctype>
#include <cstdio>

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

/// @brief Check if the character is an alphanumeric character
/// @param ch The character to check
/// @return True if the character is an alphanumeric character
inline qb_bool IsAlphaNumeric(uint32_t ch)
{
    return TO_QB_BOOL(isalnum(ch));
}

/// @brief Check if the character is an alphabetic character
/// @param ch The character to check
/// @return True if the character is an alphabetic character
inline qb_bool IsAlphabetic(uint32_t ch)
{
    return TO_QB_BOOL(isalpha(ch));
}

/// @brief Check if the character is a lowercase characte
/// @param ch The character to check
/// @return True if the character is a lowercase characte
inline qb_bool IsLowerCase(uint32_t ch)
{
    return TO_QB_BOOL(islower(ch));
}

/// @brief Check if the character is an uppercase character
/// @param ch The character to check
/// @return True if the character is an uppercase character
inline qb_bool IsUpperCase(uint32_t ch)
{
    return TO_QB_BOOL(isupper(ch));
}

/// @brief Check if the character is a numeric character
/// @param ch The character to check
/// @return True if the character is a numeric character
inline qb_bool IsDigit(uint32_t ch)
{
    return TO_QB_BOOL(isdigit(ch));
}

/// @brief Check if the character is a hexadecimal numeric character
/// @param ch The character to check
/// @return True if the character is a hexadecimal numeric character
inline qb_bool IsHexadecimalDigit(uint32_t ch)
{
    return TO_QB_BOOL(isxdigit(ch));
}

/// @brief Check if the character is a control character
/// @param ch The character to check
/// @return True if the character is a control character
inline qb_bool IsControlCharacter(uint32_t ch)
{
    return TO_QB_BOOL(iscntrl(ch));
}

/// @brief Check if the character has a graphical representation
/// @param ch The character to check
/// @return True if the character has a graphical representation
inline qb_bool IsGraphicalCharacter(uint32_t ch)
{
    return TO_QB_BOOL(isgraph(ch));
}

/// @brief Check if the character is a white-space character
/// @param ch The character to check
/// @return True if the character is white-space character
inline qb_bool IsWhiteSpace(uint32_t ch)
{
    return TO_QB_BOOL(isspace(ch));
}

/// @brief Check if the character is a blank character
/// @param ch The character to check
/// @return True if the character is a blank character
inline qb_bool IsBlank(uint32_t ch)
{
    return TO_QB_BOOL(isblank(ch));
}

/// @brief Check if the character can be printed
/// @param ch The character to check
/// @return True if the character can be printed
inline qb_bool IsPrintable(uint32_t ch)
{
    return TO_QB_BOOL(isprint(ch));
}

/// @brief Check if the character is a punctuation character
/// @param ch The character to check
/// @return True if the character is a punctuation character
inline qb_bool IsPunctuation(uint32_t ch)
{
    return TO_QB_BOOL(ispunct(ch));
}

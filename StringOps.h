//----------------------------------------------------------------------------------------------------------------------
// String related routines
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Common.h"
#include "Types.h"
#include <cstdint>
#include <cstring>
#include <cctype>
#include <cstdio>
#include <regex>

/// @brief Format a 32-bit integer
/// @param n A 32-bit integer
/// @param fmt The format specifier
/// @return A formatted string
inline const char *__FormatLong(int32_t n, const char *fmt)
{
    commonTemporaryBuffer[0] = '\0';
    snprintf(commonTemporaryBuffer, sizeof(commonTemporaryBuffer), fmt, n);
    return commonTemporaryBuffer;
}

/// @brief Format a 64-bit integer
/// @param n A 64-bit integer
/// @param fmt The format specifier
/// @return A formatted string
inline const char *__FormatInteger64(int64_t n, const char *fmt)
{
    commonTemporaryBuffer[0] = '\0';
    snprintf(commonTemporaryBuffer, sizeof(commonTemporaryBuffer), fmt, n);
    return commonTemporaryBuffer;
}

/// @brief Format a 32-bit float
/// @param n A 32-bit float
/// @param fmt The format specifier
/// @return A formatted string
inline const char *__FormatSingle(float n, const char *fmt)
{
    commonTemporaryBuffer[0] = '\0';
    snprintf(commonTemporaryBuffer, sizeof(commonTemporaryBuffer), fmt, n);
    return commonTemporaryBuffer;
}

/// @brief Format a 64-bit double
/// @param n A 64-bit double
/// @param fmt The format specifier
/// @return A formatted string
inline const char *__FormatDouble(double n, const char *fmt)
{
    commonTemporaryBuffer[0] = '\0';
    snprintf(commonTemporaryBuffer, sizeof(commonTemporaryBuffer), fmt, n);
    return commonTemporaryBuffer;
}

/// @brief Format a pointer
/// @param n A pointer
/// @param fmt The format specifier
/// @return A formatted string
inline const char *__FormatOffset(uintptr_t n, const char *fmt)
{
    commonTemporaryBuffer[0] = '\0';
    snprintf(commonTemporaryBuffer, sizeof(commonTemporaryBuffer), fmt, n);
    return commonTemporaryBuffer;
}

/// @brief Gets a string form of the boolean value passed
/// @param n A boolean value
/// @param fmt The format type needed
/// @return A string form of the boolean value
inline const char *FormatBoolean(int32_t n, uint32_t fmt)
{
    static const char *const BOOLEAN_STRINGS[][2] = {
        {"False", "True"},
        {"0", "1"},
        {"0", "-1"},
        {"Off", "On"},
        {"Disabled", "Enabled"},
        {"Disable", "Enable"},
        {"Low", "High"},
        {"Closed", "Opened"},
        {"Close", "Open"},
        {"Inactive", "Active"},
        {"Absent", "Present"},
        {"Disengaged", "Engaged"},
        {"Disengage", "Engage"},
        {"Disconnected", "Connected"},
        {"Disconnect", "Connect"},
        {"Invalid", "Valid"},
        {"Down", "Up"},
        {"Stopped", "Started"},
        {"Stop", "Start"},
        {"Unavailable", "Available"},
        {"Out", "In"}};

    n = n != 0; // limit the values to 0-1
    if (fmt >= GET_ARRAY_SIZE(BOOLEAN_STRINGS))
        fmt = 0;

    return BOOLEAN_STRINGS[fmt][n];
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

/// @brief Reverses the order of bytes in memory
/// @param ptr A pointer to a memory buffer
/// @param size The size of the memory buffer
inline void ReverseMemory(uintptr_t ptr, size_t size)
{
    auto start = (uint8_t *)ptr;
    auto end = start + size - 1;

    while (start < end)
    {
        *start ^= *end;
        *end ^= *start;
        *start ^= *end;

        start++;
        end--;
    }
}

/// @brief Compiles a RegEx and returns a context
/// @param pattern A RegEx pattern
/// @return A RegEx context
inline uintptr_t __RegExCompile(const char *pattern)
{
    try
    {
        auto regexPtr = new std::regex(pattern);
        return reinterpret_cast<uintptr_t>(regexPtr);
    }
    catch (const std::regex_error &e)
    {
        return 0; // return null context on error
    }
}

/// @brief Frees resources for a compiled pattern
/// @param pattern A RegEx context
inline void RegExFree(uintptr_t pattern)
{
    if (pattern)
    {
        delete reinterpret_cast<std::regex *>(pattern);
    }
}

/// @brief Searches of a occurence of a compiled pattern in `text`
/// @param pattern A RegEx context
/// @param text The string to search
/// @param index The position in the string to start searching
/// @param matchLength The length of the match [output]
/// @return Starting position of the match (>= 0) or a negative value indicating the error
inline int32_t __RegExSearchCompiled(uintptr_t pattern, const char *text, int32_t index, int32_t *matchLength)
{
    if (!pattern)
        return -2; // invalid context

    auto regexPtr = reinterpret_cast<std::regex *>(pattern);
    std::cmatch cm;

    // Convert index to size_t for regex_search
    auto startIndex = static_cast<size_t>(index) - 1; // QB string index starts at 1
    if (std::regex_search(text + startIndex, cm, *regexPtr))
    {
        *matchLength = static_cast<int32_t>(cm.length());
        return static_cast<int32_t>(cm.position()); // return the starting position of the match (must be adjusted on the QB64 side!!!)
    }

    return -1; // no match found
}

/// @brief Searches for an occurrence of a pattern in `text`
/// @param pattern A RegEx pattern
/// @param text The string to search
/// @param index The position in the string to start searching
/// @param matchLength The length of the match [output]
/// @return Starting position of the match (>= 0) or a negative value indicating the error
inline int32_t __RegExSearch(const char *pattern, const char *text, int32_t index, int32_t *matchLength)
{
    auto compiledPattern = __RegExCompile(pattern);
    auto result = __RegExSearchCompiled(compiledPattern, text, index, matchLength);
    RegExFree(compiledPattern); // clean up compiled context
    return result;
}

/// @brief Checks if `text` is a RegEx match
/// @param pattern A RegEx context
/// @param text The string to match
/// @return True if it is a match. False otherwise
inline qb_bool __RegExMatchCompiled(uintptr_t pattern, const char *text)
{
    if (!pattern)
        return QB_FALSE; // invalid context

    auto regexPtr = reinterpret_cast<std::regex *>(pattern);
    return TO_QB_BOOL(std::regex_match(text, *regexPtr));
}

/// @brief Checks if `text` is a RegEx match
/// @param pattern A RegEx pattern
/// @param text The string to match
/// @return True if it is a match. False otherwise
inline qb_bool __RegExMatch(const char *pattern, const char *text)
{
    uintptr_t compiledPattern = __RegExCompile(pattern);
    auto result = __RegExMatchCompiled(compiledPattern, text);
    RegExFree(compiledPattern); // clean up compiled context
    return result;
}

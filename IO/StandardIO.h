//----------------------------------------------------------------------------------------------------------------------
// Standard Input/Output functions
// Copyright (c) 2025 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdio>
#include <algorithm>
#include "../Common.h"

inline void StandardIO_Write_(const char *text)
{
    std::fputs(text, stdout);
}

inline const char *StandardIO_Read_(size_t maxLength)
{
    g_TmpBuf[0] = '\0';

    std::fgets(reinterpret_cast<char *>(g_TmpBuf), std::min<int>(maxLength, sizeof(g_TmpBuf)), stdin);

    return reinterpret_cast<char *>(g_TmpBuf);
}

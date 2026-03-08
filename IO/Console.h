//----------------------------------------------------------------------------------------------------------------------
// Console Input/Output functions
// Copyright (c) 2025 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "../Core/Common.h"
#include <algorithm>
#include <cstdio>

inline void Console_Write_(const char *text) {
    std::fputs(text, stdout);
}

inline const char *Console_Read_(size_t maxLength) {
    g_TmpBuf[0] = '\0';

    if (maxLength) {
        g_TmpBuf.resize(std::max(maxLength, g_TmpBuf.size()));
        std::fgets(reinterpret_cast<char *>(g_TmpBuf.data()), maxLength, stdin);
    }

    return reinterpret_cast<char *>(g_TmpBuf.data());
}

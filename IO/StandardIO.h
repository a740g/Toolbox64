//----------------------------------------------------------------------------------------------------------------------
// Standard Input/Output functions
// Copyright (c) 2025 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdio>

inline void __StandardIO_Write(const char *text)
{
    std::fputs(text, stdout);
}

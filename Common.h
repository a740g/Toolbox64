//----------------------------------------------------------------------------------------------------------------------
// Common header (stuff that we share across files)
// Copyright (c) 2024 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>

// Use these with care. Expressions passed to macros can be evaluated multiple times and wrong types can cause all kinds of bugs
#define IS_STRING_EMPTY(_s_) ((_s_) == nullptr || (_s_)[0] == 0)
#define ZERO_MEMORY(_p_, _s_) memset((_p_), 0, (_s_))
#define ZERO_VARIABLE(_v_) memset(&(_v_), 0, sizeof(_v_))
#define ZERO_OBJECT(_p_) memset((_p_), 0, sizeof(*(_p_)))

// Temporary 4k static buffer shared by various modules
static uint8_t g_TmpBuf[4096];

#define Compiler_GetDate() (__DATE__)
#define Compiler_GetTime() (__TIME__)
#define Compiler_GetFunctionName() (__func__)

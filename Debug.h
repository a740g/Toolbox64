//----------------------------------------------------------------------------------------------------------------------
// Simple stderr based logging & debugging macros
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>
#include <cstdio>

#if defined(TOOLBOX64_DEBUG) && TOOLBOX64_DEBUG > 0
#define TOOLBOX64_DEBUG_PRINT(_fmt_, _args_...) fprintf(stderr, "\e[1;37mDEBUG: %s:%d:%s(): \e[1;33m" _fmt_ "\e[1;37m\n", __FILE__, __LINE__, __func__, ##_args_)
#define TOOLBOX64_DEBUG_CHECK(_exp_) \
    if (!(_exp_))                    \
    TOOLBOX64_DEBUG_PRINT("\e[0;31mCondition (%s) failed", #_exp_)
#else
#define TOOLBOX64_DEBUG_PRINT(_fmt_, _args_...) // Don't do anything in release builds
#define TOOLBOX64_DEBUG_CHECK(_exp_)            // Don't do anything in release builds
#endif

#define ERROR_ILLEGAL_FUNCTION_CALL 5

extern void error(int32_t error_number);

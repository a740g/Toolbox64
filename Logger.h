//----------------------------------------------------------------------------------------------------------------------
// Simple header-only macro-based logging library
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>
#include <cstdio>

#if defined(TOOLBOX64_DEBUG) && TOOLBOX64_DEBUG > 0
#ifdef _MSC_VER
#define TOOLBOX64_DEBUG_PRINT(_fmt_, ...) fprintf(stderr, "\e[1;37mDEBUG: %s:%d:%s(): \e[1;33m" _fmt_ "\n", __FILE__, __LINE__, __func__, __VA_ARGS__)
#else
#define TOOLBOX64_DEBUG_PRINT(_fmt_, _args_...) fprintf(stderr, "\e[1;37mDEBUG: %s:%d:%s(): \e[1;33m" _fmt_ "\n", __FILE__, __LINE__, __func__, ##_args_)
#endif
#define TOOLBOX64_DEBUG_CHECK(_exp_) \
    if (!(_exp_))                    \
    TOOLBOX64_DEBUG_PRINT("\e[0;31mCondition (%s) failed", #_exp_)
#else
#ifdef _MSC_VER
#define TOOLBOX64_DEBUG_PRINT(_fmt_, ...) // Don't do anything in release builds
#else
#define TOOLBOX64_DEBUG_PRINT(_fmt_, _args_...) // Don't do anything in release builds
#endif
#define TOOLBOX64_DEBUG_CHECK(_exp_) // Don't do anything in release builds
#endif

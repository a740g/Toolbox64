//----------------------------------------------------------------------------------------------------------------------
// Common header
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

// QB64 false is 0 and true is -1 (sad, but true XD)
enum qb_bool : int8_t
{
    QB_TRUE = -1,
    QB_FALSE = 0
};

// Use these with care. Expressions passed to macros can be evaluated multiple times and wrong types can cause all kinds of bugs

#define TO_C_BOOL(_exp_) ((_exp_) != false)
#define TO_QB_BOOL(_exp_) ((qb_bool)(-TO_C_BOOL(_exp_)))
#define IS_STRING_EMPTY(_s_) ((_s_) == nullptr || (_s_)[0] == 0)
#define CLAMP(_x_, _low_, _high_) (((_x_) > (_high_)) ? (_high_) : (((_x_) < (_low_)) ? (_low_) : (_x_)))
#define ZERO_MEMORY(_p_, _s_) memset((_p_), 0, (_s_))
#define ZERO_VARIABLE(_v_) memset(&(_v_), 0, sizeof(_v_))
#define ZERO_OBJECT(_p_) memset((_p_), 0, sizeof(*(_p_)))
#define TO_BGRA(_r_, _g_, _b_, _a_) (((uint32_t)(_a_) << 24) | ((uint32_t)(_r_) << 16) | ((uint32_t)(_g_) << 8) | (uint32_t)(_b_))
#define GET_BGRA_A(_bgra_) ((uint8_t)((_bgra_) >> 24))
#define GET_BGRA_R(_bgra_) ((uint8_t)(((_bgra_) >> 16) & 0xFFu))
#define GET_BGRA_G(_bgra_) ((uint8_t)(((_bgra_) >> 8) & 0xFFu))
#define GET_BGRA_B(_bgra_) ((uint8_t)((_bgra_)&0xFFu))
#define TO_RGBA(_r_, _g_, _b_, _a_) (((uint32_t)(_a_) << 24) | ((uint32_t)(_b_) << 16) | ((uint32_t)(_g_) << 8) | (uint32_t)(_r_))
#define GET_RGBA_A(_rgba_) ((uint8_t)((_rgba_) >> 24))
#define GET_RGBA_B(_rgba_) ((uint8_t)(((_rgba_) >> 16) & 0xFFu))
#define GET_RGBA_G(_rgba_) ((uint8_t)(((_rgba_) >> 8) & 0xFFu))
#define GET_RGBA_R(_rgba_) ((uint8_t)((_rgba_)&0xFFu))
#define GET_RGB(_clr_) ((_clr_)&0xFFFFFFu)
#define SWAP_RED_BLUE(_clr_) (((_clr_)&0xFF00FF00u) | (((_clr_)&0x00FF0000u) >> 16) | (((_clr_)&0x000000FFu) << 16))
#define TO_FOURCC(_a_, _b_, _c_, _d_) (((uint32_t)(_d_) << 24) | ((uint32_t)(_c_) << 16) | ((uint32_t)(_b_) << 8) | (uint32_t)(_a_))
#define GET_ARRAY_SIZE(_x_) (sizeof(_x_) / sizeof(_x_[0]))
#define GET_RANDOM_BETWEEN(_l_, _h_) ((_l_) + (rand() % ((_h_) - (_l_) + 1)))
#define IS_EVEN(_x_) (((_x_)&1) == 0)
#define GET_SIGN(_x_) (((_x_) == 0) ? 0 : (((_x_) > 0) ? 1 : -1))
#define GET_ABSOLUTE(_x_) (((_x_) > 0) ? (_x_) : -(_x_))
#define TO_BE_SHORT(_x_) __builtin_bswap16(_x_)
#define TO_BE_LONG(_x_) __builtin_bswap32(_x_)
#define TO_BE_LONGLONG(_x_) __builtin_bswap64(_x_)

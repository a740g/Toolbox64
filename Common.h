//----------------------------------------------------------------------------------------------------------------------
// Common header
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>
#include <cstdio>

#if defined(TOOLBOX64_DEBUG) && TOOLBOX64_DEBUG > 0
#define TOOLBOX64_DEBUG_PRINT(_fmt_, _args_...) fprintf(stderr, "\e[1;37mDEBUG: %s:%d:%s(): \e[1;33m" _fmt_ "\n", __FILE__, __LINE__, __func__, ##_args_)
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

// Use these with care. Expressions passed to macros can be evaluated multiple times
#define TO_C_BOOL(_exp_) ((_exp_) != false)
#define TO_QB_BOOL(_exp_) ((qb_bool)(-TO_C_BOOL(_exp_)))
#define IS_STRING_EMPTY(_s_) ((_s_) == nullptr || (_s_)[0] == 0)
#define CLAMP(_x_, _low_, _high_) (((_x_) > (_high_)) ? (_high_) : (((_x_) < (_low_)) ? (_low_) : (_x_)))
#define ZERO_MEMORY(_m_, _l_) memset((_m_), 0, (_l_))
#define ZERO_VARIABLE(_v_) memset(&(_v_), 0, sizeof(_v_))
#define ZERO_OBJECT(_p_) memset((_p_), 0, sizeof(*(_p_)))
#define GET_BGRA_RED(_c_) ((uint8_t)((uint32_t)(_c_) >> 16 & 0xFF))
#define GET_BGRA_GREEN(_c_) ((uint8_t)((uint32_t)(_c_) >> 8 & 0xFF))
#define GET_BGRA_BLUE(_c_) ((uint8_t)((uint32_t)(_c_) & 0xFF))
#define GET_BGRA_ALPHA(_c_) ((uint8_t)((uint32_t)(_c_) >> 24))
#define GET_BGRA_BGR(_c_) ((uint32_t)(_c_) & 0xFFFFFF)
#define MAKE_BGRA(_b_, _g_, _r_, _a_) ((uint32_t)(((uint8_t)(_b_) | ((uint32_t)((uint8_t)(_g_)) << 8)) | ((uint32_t)((uint8_t)(_r_)) << 16) | ((uint32_t)((uint8_t)(_a_)) << 24)))
#define MAKE_FOURCC(_a_, _b_, _c_, _d_) ((uint32_t)(_a_) | ((uint32_t)(_b_) << 8) | ((uint32_t)(_c_) << 16) | ((uint32_t)(_d_) << 24))
#define GET_ARRAY_SIZE(_x_) (sizeof(_x_) / sizeof(_x_[0]))
#define GET_RANDOM_BETWEEN(_l_, _h_) ((_l_) + (rand() % ((_h_) - (_l_) + 1)))
#define IS_EVEN(_x_) (((_x_) & 1) == 0)
#define GET_SIGN(_x_) (((_x_) == 0) ? 0 : (((_x_) > 0) ? 1 : -1))
#define GET_ABSOLUTE(_x_) (((_x_) > 0) ? (_x_) : -(_x_))
#define GET_BE_SHORT(_x_) __builtin_bswap16(_x_)
#define GET_BE_LONG(_x_) __builtin_bswap32(_x_)

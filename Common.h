//----------------------------------------------------------------------------------------------------------------------
// Common header
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>

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
#define TO_FOURCC(_a_, _b_, _c_, _d_) (((uint32_t)(_d_) << 24) | ((uint32_t)(_c_) << 16) | ((uint32_t)(_b_) << 8) | (uint32_t)(_a_))
#define GET_ARRAY_SIZE(_x_) (sizeof(_x_) / sizeof(_x_[0]))
#define GET_RANDOM_VALUE(_l_, _h_) ((_l_) + (rand() % ((_h_) - (_l_) + 1)))
#define IS_EVEN(_x_) (((_x_)&1) == 0)
#define GET_SIGN(_x_) (((_x_) == 0) ? 0 : (((_x_) > 0) ? 1 : -1))
#define GET_ABSOLUTE(_x_) (((_x_) > 0) ? (_x_) : -(_x_))
#define TO_BE_SHORT(_x_) __builtin_bswap16(_x_)
#define TO_BE_LONG(_x_) __builtin_bswap32(_x_)
#define TO_BE_LONGLONG(_x_) __builtin_bswap64(_x_)

/// @brief Returns QB style bool
/// @param x Any number
/// @return 0 when x is 0 and -1 when x is non-zero
inline qb_bool ToQBBool(int32_t x)
{
    return TO_QB_BOOL(x);
}

/// @brief Returns C style bool
/// @param x Any number
/// @return 0 when x is 0 and 1 when x is non-zero
inline bool ToCBool(int32_t x)
{
    return TO_C_BOOL(x);
}

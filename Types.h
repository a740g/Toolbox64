//----------------------------------------------------------------------------------------------------------------------
// Variable type support, size and limits
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

#define TO_C_BOOL(_exp_) ((_exp_) != false)
#define TO_QB_BOOL(_exp_) ((qb_bool)(-TO_C_BOOL(_exp_)))

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

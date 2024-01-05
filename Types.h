//----------------------------------------------------------------------------------------------------------------------
// Variable type support, size and limits
// Copyright (c) 2024 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>

// QB64 false is 0 and true is -1 (sad, but true XD)
typedef int8_t qb_bool;

#ifndef INC_COMMON_CPP
#define QB_TRUE -1
#define QB_FALSE 0
#endif

#define TO_C_BOOL(_exp_) ((_exp_) != false)
#define TO_QB_BOOL(_exp_) ((qb_bool)(-TO_C_BOOL(_exp_)))
#define TO_L_NOT(_exp_) (-(not(_exp_)))

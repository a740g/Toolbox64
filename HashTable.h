//----------------------------------------------------------------------------------------------------------------------
// A simple hash table for integers and QB64-PE handles
// Copyright (c) 2024 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>

// Simple hash function: k is the 32-bit key and l is the upper bound of the array
// Actually this should be k MOD (l + 1)
// However, we can get away using AND because our arrays size always doubles in multiples of 2
// So, if l = 255, then (k MOD (l + 1)) = (k AND l)
// Another nice thing here is that we do not need to do the addition :)
#define __HashTable_GetHash(_k_, _l_) uint32_t((_k_) & (_l_))

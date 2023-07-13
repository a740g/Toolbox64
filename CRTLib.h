//----------------------------------------------------------------------------------------------------------------------
// QB64-PE low level support functions
// Copyright (c) 2023 Samuel Gomes
//
// Some of these came from my old game library and some from:
// https://graphics.stanford.edu/~seander/bithacks.html
// https://bits.stephan-brumme.com/
// http://aggregate.org/MAGIC/
// http://www.azillionmonkeys.com/qed/asmexample.html
// https://dspguru.com/dsp/tricks/
// http://programming.sirrida.de/
// https://gcc.gnu.org/onlinedocs/gcc/Other-Builtins.html
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Common.h"
#include <cstdlib>
#include <climits>

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

/// @brief Returns the next (ceiling) power of 2 for x. E.g. n = 600 then returns 1024
/// @param n Any number
/// @return Next (ceiling) power of 2 for x
inline uint32_t RoundUpToPowerOf2(uint32_t n)
{
    --n;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    return ++n;
}

/// @brief Returns the previous (floor) power of 2 for x. E.g. n = 600 then returns 512
/// @param n Any number
/// @return Previous (floor) power of 2 for x
inline uint32_t RoundDownToPowerOf2(uint32_t n)
{
    n |= (n >> 1);
    n |= (n >> 2);
    n |= (n >> 4);
    n |= (n >> 8);
    n |= (n >> 16);
    return n - (n >> 1);
}

/// @brief Returns the number using which we need to shift 1 left to get n. E.g. n = 2 then returns 1
/// @param n A power of 2 number
/// @return A number (x) that we use in 1 << x to get n
inline uint32_t LeftShiftOneCount(uint32_t n)
{
    return n == 0 ? 0 : (CHAR_BIT * sizeof(n)) - 1 - __builtin_clz(n);
}

/// @brief Reverses bits in a 8-bit number
/// @param x The number
/// @return A number with bits reversed
inline uint8_t ReverseBitsByte(uint8_t x)
{
    x = ((x & 0x55) << 1) | ((x & 0xAA) >> 1);
    x = ((x & 0x33) << 2) | ((x & 0xCC) >> 2);
    return (x >> 4) | (x << 4);
}

/// @brief Reverses bits in a 16-bit number
/// @param x The number
/// @return A number with bits reversed
inline uint16_t ReverseBitsInteger(uint16_t x)
{
    x = ((x & 0xaaaa) >> 1) | ((x & 0x5555) << 1);
    x = ((x & 0xcccc) >> 2) | ((x & 0x3333) << 2);
    x = ((x & 0xf0f0) >> 4) | ((x & 0x0f0f) << 4);
    return (x >> 8) | (x << 8);
}

/// @brief Reverses bits in a 32-bit number
/// @param x The number
/// @return A number with bits reversed
inline uint32_t ReverseBitsLong(uint32_t x)
{
    x = ((x & 0xaaaaaaaa) >> 1) | ((x & 0x55555555) << 1);
    x = ((x & 0xcccccccc) >> 2) | ((x & 0x33333333) << 2);
    x = ((x & 0xf0f0f0f0) >> 4) | ((x & 0x0f0f0f0f) << 4);
    x = ((x & 0xff00ff00) >> 8) | ((x & 0x00ff00ff) << 8);
    return (x >> 16) | (x << 16);
}

/// @brief Reverses bits in a 64-bit number
/// @param x The number
/// @return A number with bits reversed
inline uint64_t ReverseBitsInteger64(uint64_t x)
{
    x = ((x & 0xaaaaaaaaaaaaaaaa) >> 1) | ((x & 0x5555555555555555) << 1);
    x = ((x & 0xcccccccccccccccc) >> 2) | ((x & 0x3333333333333333) << 2);
    x = ((x & 0xf0f0f0f0f0f0f0f0) >> 4) | ((x & 0x0f0f0f0f0f0f0f0f) << 4);
    x = ((x & 0xff00ff00ff00ff00) >> 8) | ((x & 0x00ff00ff00ff00ff) << 8);
    x = ((x & 0xffff0000ffff0000) >> 16) | ((x & 0x0000ffff0000ffff) << 16);
    return (x >> 32) | (x << 32);
}

/// @brief Reverses the order of bytes in memory
/// @param ptr A pointer to a memory buffer
/// @param size The size of the memory buffer
inline void ReverseBytes(uintptr_t ptr, size_t size)
{
    auto start = (uint8_t *)ptr;
    auto end = start + size - 1;

    while (start < end)
    {
        *start ^= *end;
        *end ^= *start;
        *start ^= *end;

        start++;
        end--;
    }
}

/// @brief Returns a random number between lo and hi (inclusive). Use srand() to seed RNG
/// @param lo The lower limit
/// @param hi The upper limit
/// @return A number between lo and hi
inline int32_t GetRandomValue(int32_t lo, int32_t hi)
{
    return GET_RANDOM_VALUE(lo, hi);
}

/// @brief Clamps n between lo and hi
/// @param n A number
/// @param lo Lower limit
/// @param hi Upper limit
/// @return Clamped value
inline int32_t ClampLong(int32_t n, int32_t lo, int32_t hi)
{
    return CLAMP(n, lo, hi);
}

/// @brief Clamps n between lo and hi
/// @param n A number
/// @param lo Lower limit
/// @param hi Upper limit
/// @return Clamped value
inline int64_t ClampInteger64(int64_t n, int64_t lo, int64_t hi)
{
    return CLAMP(n, lo, hi);
}

/// @brief Clamps n between lo and hi
/// @param n A number
/// @param lo Lower limit
/// @param hi Upper limit
/// @return Clamped value
inline float ClampSingle(float n, float lo, float hi)
{
    return CLAMP(n, lo, hi);
}

/// @brief Clamps n between lo and hi
/// @param n A number
/// @param lo Lower limit
/// @param hi Upper limit
/// @return Clamped value
inline double ClampDouble(double n, double lo, double hi)
{
    return CLAMP(n, lo, hi);
}

/// @brief Get the digit from position p in integer n
/// @param n A number
/// @param p The position (where 1 is unit, 2 is tens and so on)
/// @return The digit at position p
inline int32_t GetDigitFromLong(uint32_t n, uint32_t p)
{
    switch (p)
    {
    case 0:
        break;
    case 1:
        n /= 10;
        break;
    case 2:
        n /= 100;
        break;
    case 3:
        n /= 1000;
        break;
    case 4:
        n /= 10000;
        break;
    case 5:
        n /= 100000;
        break;
    case 6:
        n /= 1000000;
        break;
    case 7:
        n /= 10000000;
        break;
    case 8:
        n /= 100000000;
        break;
    case 9:
        n /= 1000000000;
        break;
    }

    return n % 10;
}

/// @brief Get the digit from position p in integer n
/// @param n A number
/// @param p The position (where 1 is unit, 2 is tens and so on)
/// @return The digit at position p
inline int32_t GetDigitFromInteger64(uint64_t n, uint32_t p)
{
    return (n / (uint64_t)__builtin_powi(10, p)) % 10;
}

/// @brief Calculates the average of x and y without overflowing
/// @param x A number
/// @param y A number
/// @return Average of x & y
inline int32_t AverageLong(int32_t x, int32_t y)
{
    return (x & y) + ((x ^ y) / 2);
}

/// @brief Calculates the average of x and y without overflowing
/// @param x A number
/// @param y A number
/// @return Average of x & y
inline int64_t AverageInteger64(int64_t x, int64_t y)
{
    return (x & y) + ((x ^ y) / 2);
}

/// @brief Check if n is a power of 2
/// @param n A number
/// @return True if n is a power of 2
inline int32_t IsPowerOfTwo(uint32_t n)
{
    return n && !(n & (n - 1)) ? -1 : 0;
}

/// @brief Finds the position of LSb set in a number
/// @param n An integer
/// @return Returns one plus the index of the least significant 1-bit of x, or if x is zero, returns zero
inline int32_t FindFirstBitSetLong(uint32_t x)
{
    return __builtin_ffs(x);
}

/// @brief Finds the position of LSb set in a number
/// @param n An integer
/// @return Returns one plus the index of the least significant 1-bit of x, or if x is zero, returns zero
inline int32_t FindFirstBitSetInteger64(uint64_t x)
{
    return __builtin_ffsll(x);
}

/// @brief Count leading zeroes in a number
/// @param n An integer
/// @return Returns the number of leading 0-bits in x, starting at the most significant bit position. If x is 0, the result is undefined
inline int32_t CountLeadingZerosLong(uint32_t x)
{
    return __builtin_clz(x);
}

/// @brief Count leading zeroes in a number
/// @param n An integer
/// @return Returns the number of leading 0-bits in x, starting at the most significant bit position. If x is 0, the result is undefined
inline int32_t CountLeadingZerosInteger64(uint64_t x)
{
    return __builtin_clzll(x);
}

/// @brief Count trailing zeroes in a number
/// @param n An integer
/// @return Returns the number of trailing 0-bits in x, starting at the least significant bit position. If x is 0, the result is undefined
inline int32_t CountTrailingZerosLong(uint32_t x)
{
    return __builtin_ctz(x);
}

/// @brief Count trailing zeroes in a number
/// @param n An integer
/// @return Returns the number of trailing 0-bits in x, starting at the least significant bit position. If x is 0, the result is undefined
inline int32_t CountTrailingZerosInteger64(uint64_t x)
{
    return __builtin_ctzll(x);
}

/// @brief Return the count of 1s in a number
/// @param n An integer
/// @return Returns the number of 1-bits in x
inline int32_t PopulationCountLong(uint32_t x)
{
    return __builtin_popcount(x);
}

/// @brief Return the count of 1s in a number
/// @param x An integer
/// @return Returns the number of 1-bits in x
inline int32_t PopulationCountInteger64(uint64_t x)
{
    return __builtin_popcountll(x);
}

/// @brief Returns x with the order of the bytes reversed; for example, 0xaabb becomes 0xbbaa. Byte here always means exactly 8 bits
/// @param n An integer
/// @return Returns x with the order of the bytes reversed; for example, 0xaabb becomes 0xbbaa. Byte here always means exactly 8 bits
inline uint16_t ByteSwapInteger(uint16_t x)
{
    return TO_BE_SHORT(x);
}

/// @brief Similar to ByteSwapInteger, except the argument and return types are 32-bit
/// @param n An integer
/// @return Similar to ByteSwapInteger, except the argument and return types are 32-bit
inline uint32_t ByteSwapLong(uint32_t x)
{
    return TO_BE_LONG(x);
}

/// @brief Similar to ByteSwapInteger, except the argument and return types are 64-bit
/// @param n An integer
/// @return Similar to ByteSwapInteger, except the argument and return types are 64-bit
inline uint64_t ByteSwapInteger64(uint64_t x)
{
    return TO_BE_LONGLONG(x);
}

/// @brief Makes a four-character code
/// @param ch0 Character 0
/// @param ch1 Character 1
/// @param ch2 Character 2
/// @param ch3 Character 3
/// @return The FOURCC
inline uint32_t MakeFourCC(uint8_t ch0, uint8_t ch1, uint8_t ch2, uint8_t ch3)
{
    return TO_FOURCC(ch0, ch1, ch2, ch3);
}

/// @brief Makes a BYTE out of two nibbles
/// @param x Nibble 1
/// @param y Nibble 2
/// @return A BYTE
inline uint8_t MakeByte(uint8_t x, uint8_t y)
{
    return (uint8_t)y | (x << 4);
}

/// @brief Makes an INTEGER out of two BYTEs
/// @param x BYTE 1
/// @param y BYTE 2
/// @return An INTEGER
inline uint16_t MakeInteger(uint8_t x, uint8_t y)
{
    return (uint16_t)y | ((uint16_t)x << 8);
}

/// @brief Makes a LONG out of two INTEGERs
/// @param x INTEGER 1
/// @param y INTEGER 2
/// @return A LONG
inline uint32_t MakeLong(uint16_t x, uint16_t y)
{
    return (uint32_t)y | ((uint32_t)x << 16);
}

/// @brief Makes a INTEGER64 out of two LONGs
/// @param x LONG 1
/// @param y LONG 2
/// @return An INTEGER64
inline uint64_t MakeInteger64(uint32_t x, uint32_t y)
{
    return (uint64_t)y | ((uint64_t)x << 32);
}

/// @brief Returns the high nibble from a BYTE
/// @param x A BYTE
/// @return A Nibble
inline uint8_t HiNibble(uint8_t x)
{
    return x >> 4;
}

/// @brief Returns the low nibble from a BYTE
/// @param x A BYTE
/// @return A nibble
inline uint8_t LoNibble(uint8_t x)
{
    return x & 0xFu;
}

/// @brief Returns the high BYTE from an INTEGER
/// @param x An INTEGER
/// @return A BYTE
inline uint8_t HiByte(uint16_t x)
{
    return (uint8_t)(x >> 8);
}

/// @brief Returns the low BYTE from an INTEGER
/// @param x An INTEGER
/// @return A BYTE
inline uint8_t LoByte(uint16_t x)
{
    return (uint8_t)(x);
}

/// @brief Returns the high INTEGER from an LONG
/// @param x A LONG
/// @return An INTEGER
inline uint16_t HiInteger(uint32_t x)
{
    return (uint16_t)(x >> 16);
}

/// @brief Returns the low INTEGER from an LONG
/// @param x A LONG
/// @return An INTEGER
inline uint16_t LoInteger(uint32_t x)
{
    return (uint16_t)(x);
}

/// @brief Returns the high LONG from an INTEGER64
/// @param x A INTEGER64
/// @return An LONG
inline uint32_t HiLong(uint64_t x)
{
    return (uint32_t)(x >> 32);
}

/// @brief Returns the low LONG from an INTEGER64
/// @param x A INTEGER64
/// @return An LONG
inline uint32_t LoLong(uint64_t x)
{
    return (uint32_t)(x);
}

/// @brief Return the max of a or b
/// @param a A number
/// @param b A number
/// @return Max value
inline int32_t MaxLong(int32_t a, int32_t b)
{
    return a > b ? a : b;
}

/// @brief Return the max of a or b
/// @param a A number
/// @param b A number
/// @return Max value
inline int64_t MaxInteger64(int64_t a, int64_t b)
{
    return a > b ? a : b;
}

/// @brief Return the min of a or b
/// @param a A number
/// @param b A number
/// @return Min value
inline int32_t MinLong(int32_t a, int32_t b)
{
    return a < b ? a : b;
}

/// @brief Return the min of a or b
/// @param a A number
/// @param b A number
/// @return Min value
inline int64_t MinInteger64(int64_t a, int64_t b)
{
    return a < b ? a : b;
}

//----------------------------------------------------------------------------------------------------------------------
// Math routines
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Types.h"
#include <cstdint>
#include <cfloat>
#include <cstdlib>
#include <cmath>

#define MaxLong(_a_, _b_) std::max(int32_t(_a_), int32_t(_b_))
#define MaxInteger64(_a_, _b_) std::max(int64_t(_a_), int64_t(_b_))
#define MinLong(_a_, _b_) std::min(int32_t(_a_), int32_t(_b_))
#define MinInteger64(_a_, _b_) std::min(int64_t(_a_), int64_t(_b_))

extern void sub_randomize(double seed, int32_t passed); // QB64's random seed function

/// @brief Set the seed for the random number generator (CRT and QB64)
/// @param seed Any number
inline void SetRandomSeed(uint32_t seed)
{
    srand(seed);
    sub_randomize(seed, 1);
}

/// @brief Returns a random number between lo and hi (inclusive). Use srand() to seed RNG
/// @param lo The lower limit
/// @param hi The upper limit
/// @return A number between lo and hi
inline int32_t GetRandomBetween(int32_t lo, int32_t hi)
{
    return lo + rand() % (hi - lo + 1);
}

/// @brief Returns the maximum value rand() can generate
/// @return The maximum random value
inline uint32_t GetRandomMaximum()
{
    return RAND_MAX;
}

/// @brief Returns true if n is even
/// @param n Any integer
/// @return True if n is even
inline qb_bool IsLongEven(int32_t n)
{
    return TO_QB_BOOL((n & 1) == 0);
}

/// @brief Returns true if n is even
/// @param n Any integer
/// @return True if n is even
inline qb_bool IsInteger64Even(int64_t n)
{
    return TO_QB_BOOL((n & 1) == 0);
}

/// @brief Check if n is a power of 2
/// @param n A number
/// @return True if n is a power of 2
inline qb_bool IsLongPowerOf2(uint32_t n)
{
    return TO_QB_BOOL(n && !(n & (n - 1)));
}

/// @brief Check if n is a power of 2
/// @param n A number
/// @return True if n is a power of 2
inline qb_bool IsInteger64PowerOf2(uint64_t n)
{
    return TO_QB_BOOL(n && !(n & (n - 1)));
}

/// @brief Returns the next (ceiling) power of 2 for x. E.g. n = 600 then returns 1024
/// @param n Any number
/// @return Next (ceiling) power of 2 for x
inline uint32_t RoundLongUpToPowerOf2(uint32_t n)
{
    --n;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    return ++n;
}

/// @brief Returns the next (ceiling) power of 2 for x. E.g. n = 600 then returns 1024
/// @param n Any number
/// @return Next (ceiling) power of 2 for x
inline uint64_t RoundInteger64UpToPowerOf2(uint64_t n)
{
    --n;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    n |= n >> 32;
    return ++n;
}

/// @brief Returns the previous (floor) power of 2 for x. E.g. n = 600 then returns 512
/// @param n Any number
/// @return Previous (floor) power of 2 for x
inline uint32_t RoundLongDownToPowerOf2(uint32_t n)
{
    n |= (n >> 1);
    n |= (n >> 2);
    n |= (n >> 4);
    n |= (n >> 8);
    n |= (n >> 16);
    return n - (n >> 1);
}

/// @brief Returns the previous (floor) power of 2 for x. E.g. n = 600 then returns 512
/// @param n Any number
/// @return Previous (floor) power of 2 for x
inline uint64_t RoundInteger64DownToPowerOf2(uint64_t n)
{
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    n |= n >> 32;
    return n - (n >> 1);
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

/// @brief Clamps n between lo and hi
/// @param n A number
/// @param lo Lower limit
/// @param hi Upper limit
/// @return Clamped value
inline int32_t ClampLong(int32_t n, int32_t lo, int32_t hi)
{
    return (n < lo) ? lo : (n > hi) ? hi
                                    : n;
}

/// @brief Clamps n between lo and hi
/// @param n A number
/// @param lo Lower limit
/// @param hi Upper limit
/// @return Clamped value
inline int64_t ClampInteger64(int64_t n, int64_t lo, int64_t hi)
{
    return (n < lo) ? lo : (n > hi) ? hi
                                    : n;
}

/// @brief Clamps n between lo and hi
/// @param n A number
/// @param lo Lower limit
/// @param hi Upper limit
/// @return Clamped value
inline float ClampSingle(float n, float lo, float hi)
{
    return (n < lo) ? lo : (n > hi) ? hi
                                    : n;
}

/// @brief Clamps n between lo and hi
/// @param n A number
/// @param lo Lower limit
/// @param hi Upper limit
/// @return Clamped value
inline double ClampDouble(double n, double lo, double hi)
{
    return (n < lo) ? lo : (n > hi) ? hi
                                    : n;
}

/// @brief Remap input value within input range to output range
/// @param value The value to remap
/// @param oldMin Old range minimum
/// @param oldMax Old range maximum
/// @param newMin New range minimum
/// @param newMax New range maximum
/// @return The value remapped to the new range
inline int32_t RemapLong(int32_t value, int32_t oldMin, int32_t oldMax, int32_t newMin, int32_t newMax)
{
    return (value - oldMin) * (newMax - newMin) / (oldMax - oldMin) + newMin;
}

/// @brief Remap input value within input range to output range
/// @param value The value to remap
/// @param oldMin Old range minimum
/// @param oldMax Old range maximum
/// @param newMin New range minimum
/// @param newMax New range maximum
/// @return The value remapped to the new range
inline int64_t RemapInteger64(int64_t value, int64_t oldMin, int64_t oldMax, int64_t newMin, int64_t newMax)
{
    return (value - oldMin) * (newMax - newMin) / (oldMax - oldMin) + newMin;
}

/// @brief Remap input value within input range to output range
/// @param value The value to remap
/// @param oldMin Old range minimum
/// @param oldMax Old range maximum
/// @param newMin New range minimum
/// @param newMax New range maximum
/// @return The value remapped to the new range
inline float RemapSingle(float value, float oldMin, float oldMax, float newMin, float newMax)
{
    return (value - oldMin) * (newMax - newMin) / (oldMax - oldMin) + newMin;
}

/// @brief Remap input value within input range to output range
/// @param value The value to remap
/// @param oldMin Old range minimum
/// @param oldMax Old range maximum
/// @param newMin New range minimum
/// @param newMax New range maximum
/// @return The value remapped to the new range
inline double RemapDouble(double value, double oldMin, double oldMax, double newMin, double newMax)
{
    return (value - oldMin) * (newMax - newMin) / (oldMax - oldMin) + newMin;
}

/// @brief Calculate linear interpolation between two floats
/// @param start The starting value (the value at amount = 0)
/// @param end TThe ending value (the value at amount = 1)
/// @param amount An amount (usually 0.0 - 1.0)
/// @return An interpolated value
inline float LerpSingle(float start, float end, float amount)
{
    return start + amount * (end - start);
}

/// @brief Calculate linear interpolation between two doubles
/// @param start The starting value (the value at amount = 0)
/// @param end TThe ending value (the value at amount = 1)
/// @param amount An amount (usually 0.0 - 1.0)
/// @return An interpolated value
inline double LerpDouble(double start, double end, double amount)
{
    return start + amount * (end - start);
}

/// @brief Normalize input value within input range
/// @param value The value to normalize
/// @param start The starting value of the input range
/// @param end The ending value of the input range
/// @return A normalized value between 0.0 and 1.0
inline float NormalizeSingle(float value, float start, float end)
{
    return (value - start) / (end - start);
}

/// @brief Normalize input value within input range
/// @param value The value to normalize
/// @param start The starting value of the input range
/// @param end The ending value of the input range
/// @return A normalized value between 0.0 and 1.0
inline double NormalizeDouble(double value, double start, double end)
{
    return (value - start) / (end - start);
}

/// @brief Wrap input value from min to max
/// @param value The input value that needs to be wrapped
/// @param min The minimum value of the range
/// @param max The maximum value of the range
/// @return The wrapped value
inline float WrapSingle(float value, float min, float max)
{
    return value - (max - min) * floorf((value - min) / (max - min));
}

/// @brief Wrap input value from min to max
/// @param value The input value that needs to be wrapped
/// @param min The minimum value of the range
/// @param max The maximum value of the range
/// @return The wrapped value
inline double WrapDouble(double value, double min, double max)
{
    return value - (max - min) * floor((value - min) / (max - min));
}

/// @brief Check whether two given floats are almost equal
/// @param x A floating point value
/// @param y A floating point value
/// @return True if both are almost equal
inline qb_bool SingleEquals(float x, float y)
{
    return TO_QB_BOOL(fabsf(x - y) <= FLT_EPSILON * fmaxf(1.0f, fmaxf(fabsf(x), fabsf(y))));
}

/// @brief Check whether two given floats are almost equal
/// @param x A floating point value
/// @param y A floating point value
/// @return True if both are almost equal
inline qb_bool DoubleEquals(double x, double y)
{
    return TO_QB_BOOL(fabs(x - y) <= DBL_EPSILON * fmax(1.0, fmax(fabs(x), fabs(y))));
}

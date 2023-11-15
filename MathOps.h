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

template <class T>
inline constexpr T Math_Clamp(T x, T lo, T hi)
{
    if (lo > hi)
        std::swap(lo, hi);
    return std::max(std::min(x, hi), lo);
}

#define Math_ClampLong(_x_, _lo_, _hi_) Math_Clamp<int32_t>((_x_), (_lo_), (_hi_))
#define Math_ClampInteger64(_x_, _lo_, _hi_) Math_Clamp<int64_t>((_x_), (_lo_), (_hi_))
#define Math_ClampSingle(_x_, _lo_, _hi_) Math_Clamp<float>((_x_), (_lo_), (_hi_))
#define Math_ClampDouble(_x_, _lo_, _hi_) Math_Clamp<double>((_x_), (_lo_), (_hi_))
#define Math_GetMaxLong(_a_, _b_) std::max<int32_t>((_a_), (_b_))
#define Math_GetMaxInteger64(_a_, _b_) std::max<int64_t>((_a_), (_b_))
#define Math_GetMinLong(_a_, _b_) std::min<int32_t>((_a_), (_b_))
#define Math_GetMinInteger64(_a_, _b_) std::min<int64_t>((_a_), (_b_))
#define Math_GetRandomMax() RAND_MAX

extern void sub_randomize(double seed, int32_t passed); // QB64's random seed function

/// @brief Set the seed for the random number generator (CRT and QB64)
/// @param seed Any number
inline void Math_SetRandomSeed(uint32_t seed)
{
    srand(seed);
    sub_randomize(seed, 1);
}

/// @brief Returns a random number between lo and hi (inclusive). Use srand() to seed RNG
/// @param lo The lower limit
/// @param hi The upper limit
/// @return A number between lo and hi
inline int32_t Math_GetRandomBetween(int32_t lo, int32_t hi)
{
    return lo + rand() % (hi - lo + 1);
}

/// @brief Determines if the given floating point number arg is a not-a-number (NaN) value
/// @param n A single value
/// @return True if the value is NaN
inline constexpr qb_bool Math_IsSingleNaN(float n)
{
    return TO_QB_BOOL(std::isnan(n));
}

/// @brief Determines if the given floating point number arg is a not-a-number (NaN) value
/// @param n A double value
/// @return True if the value is NaN
inline constexpr qb_bool Math_IsDoubleNaN(double n)
{
    return TO_QB_BOOL(std::isnan(n));
}

/// @brief Returns true if n is even
/// @param n Any integer
/// @return True if n is even
inline constexpr qb_bool Math_IsLongEven(int32_t n)
{
    return TO_QB_BOOL((n & 1) == 0);
}

/// @brief Returns true if n is even
/// @param n Any integer
/// @return True if n is even
inline constexpr qb_bool Math_IsInteger64Even(int64_t n)
{
    return TO_QB_BOOL((n & 1) == 0);
}

/// @brief Check if n is a power of 2
/// @param n A number
/// @return True if n is a power of 2
inline constexpr qb_bool Math_IsLongPowerOf2(uint32_t n)
{
    return TO_QB_BOOL(n && !(n & (n - 1)));
}

/// @brief Check if n is a power of 2
/// @param n A number
/// @return True if n is a power of 2
inline constexpr qb_bool Math_IsInteger64PowerOf2(uint64_t n)
{
    return TO_QB_BOOL(n && !(n & (n - 1)));
}

/// @brief Returns the next (ceiling) power of 2 for x. E.g. n = 600 then returns 1024
/// @param n Any number
/// @return Next (ceiling) power of 2 for x
inline constexpr uint32_t Math_RoundUpLongToPowerOf2(uint32_t n)
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
inline constexpr uint64_t Math_RoundUpInteger64ToPowerOf2(uint64_t n)
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
inline constexpr uint32_t Math_RoundDownLongToPowerOf2(uint32_t n)
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
inline constexpr uint64_t Math_RoundDownInteger64ToPowerOf2(uint64_t n)
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
inline constexpr int32_t Math_GetDigitFromLong(uint32_t n, uint32_t p)
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
inline int32_t Math_GetDigitFromInteger64(uint64_t n, uint32_t p)
{
    return (n / (uint64_t)__builtin_powi(10, p)) % 10;
}

/// @brief Calculates the average of x and y without overflowing
/// @param x A number
/// @param y A number
/// @return Average of x & y
inline constexpr int32_t Math_AverageLong(int32_t x, int32_t y)
{
    return (x & y) + ((x ^ y) / 2);
}

/// @brief Calculates the average of x and y without overflowing
/// @param x A number
/// @param y A number
/// @return Average of x & y
inline constexpr int64_t Math_AverageInteger64(int64_t x, int64_t y)
{
    return (x & y) + ((x ^ y) / 2);
}

/// @brief Remap input value within input range to output range
/// @param value The value to remap
/// @param oldMin Old range minimum
/// @param oldMax Old range maximum
/// @param newMin New range minimum
/// @param newMax New range maximum
/// @return The value remapped to the new range
inline constexpr int32_t Math_RemapLong(int32_t value, int32_t oldMin, int32_t oldMax, int32_t newMin, int32_t newMax)
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
inline constexpr int64_t Math_RemapInteger64(int64_t value, int64_t oldMin, int64_t oldMax, int64_t newMin, int64_t newMax)
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
inline constexpr float Math_RemapSingle(float value, float oldMin, float oldMax, float newMin, float newMax)
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
inline constexpr double Math_RemapDouble(double value, double oldMin, double oldMax, double newMin, double newMax)
{
    return (value - oldMin) * (newMax - newMin) / (oldMax - oldMin) + newMin;
}

/// @brief Calculate linear interpolation between two floats
/// @param start The starting value (the value at amount = 0)
/// @param end TThe ending value (the value at amount = 1)
/// @param amount An amount (usually 0.0 - 1.0)
/// @return An interpolated value
inline constexpr float Math_LerpSingle(float start, float end, float amount)
{
    return start + amount * (end - start);
}

/// @brief Calculate linear interpolation between two doubles
/// @param start The starting value (the value at amount = 0)
/// @param end TThe ending value (the value at amount = 1)
/// @param amount An amount (usually 0.0 - 1.0)
/// @return An interpolated value
inline constexpr double Math_LerpDouble(double start, double end, double amount)
{
    return start + amount * (end - start);
}

/// @brief Normalize input value within input range
/// @param value The value to normalize
/// @param start The starting value of the input range
/// @param end The ending value of the input range
/// @return A normalized value between 0.0 and 1.0
inline constexpr float Math_NormalizeSingle(float value, float start, float end)
{
    return (value - start) / (end - start);
}

/// @brief Normalize input value within input range
/// @param value The value to normalize
/// @param start The starting value of the input range
/// @param end The ending value of the input range
/// @return A normalized value between 0.0 and 1.0
inline constexpr double Math_NormalizeDouble(double value, double start, double end)
{
    return (value - start) / (end - start);
}

/// @brief Wrap input value from min to max
/// @param value The input value that needs to be wrapped
/// @param min The minimum value of the range
/// @param max The maximum value of the range
/// @return The wrapped value
inline float Math_WrapSingle(float value, float min, float max)
{
    return value - (max - min) * floorf((value - min) / (max - min));
}

/// @brief Wrap input value from min to max
/// @param value The input value that needs to be wrapped
/// @param min The minimum value of the range
/// @param max The maximum value of the range
/// @return The wrapped value
inline double Math_WrapDouble(double value, double min, double max)
{
    return value - (max - min) * floor((value - min) / (max - min));
}

/// @brief Check whether two given floats are almost equal
/// @param x A floating point value
/// @param y A floating point value
/// @return True if both are almost equal
inline qb_bool Math_IsSingleEqual(float x, float y)
{
    return TO_QB_BOOL(fabsf(x - y) <= FLT_EPSILON * fmaxf(1.0f, fmaxf(fabsf(x), fabsf(y))));
}

/// @brief Check whether two given floats are almost equal
/// @param x A floating point value
/// @param y A floating point value
/// @return True if both are almost equal
inline qb_bool Math_IsDoubleEqual(double x, double y)
{
    return TO_QB_BOOL(fabs(x - y) <= DBL_EPSILON * fmax(1.0, fmax(fabs(x), fabs(y))));
}

/// @brief This one comes from https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Approximations_that_depend_on_the_floating_point_representation
/// @param x A floating-pointer number
/// @return An approximate square root
inline float Math_FastSquareRoot(float x)
{
    auto i = reinterpret_cast<int32_t *>(&x);
    *i -= (1 << 23);
    *i >>= 1;
    *i += (1 << 29);
    return x;
}

/// @brief This one comes from https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Reciprocal_of_the_square_root
/// @param x A floating-pointer number
/// @return An approximate square root
inline float Math_FastInverseSquareRoot(float x)
{
    auto xhalf = 0.5f * x;
    auto i = reinterpret_cast<int32_t *>(&x);
    *i = 0x5f375a86 - (*i >> 1);
    x = x * (1.5f - xhalf * x * x);
    return x;
}

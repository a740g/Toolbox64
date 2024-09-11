//----------------------------------------------------------------------------------------------------------------------
// 2D Vector routines
// Copyright (c) 2024 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "../Types.h"
#include <algorithm>
#include <cmath>
#include <cstdint>

struct Vector2D
{
    float x;
    float y;
};

inline void Vector2D_Reset(void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<Vector2D *>(dst)->y = 0.0f;
}

inline void Vector2D_Initialize(float x, float y, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = x;
    reinterpret_cast<Vector2D *>(dst)->y = y;
}

inline void Vector2D_Assign(const void *src, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x;
    reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y;
}

inline auto constexpr Vector2D_IsNull(const void *src)
{
    return TO_QB_BOOL(reinterpret_cast<const Vector2D *>(src)->x == 0.0f && reinterpret_cast<const Vector2D *>(src)->y == 0.0f);
}

inline void Vector2D_Add(const void *src1, const void *src2, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src1)->x + reinterpret_cast<const Vector2D *>(src2)->x;
    reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src1)->y + reinterpret_cast<const Vector2D *>(src2)->y;
}

inline void Vector2D_AddValue(const void *src, float value, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x + value;
    reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y + value;
}

inline void Vector2D_AddXY(const void *src, float x, float y, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x + x;
    reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y + y;
}

inline void Vector2D_Subtract(const void *src1, const void *src2, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src1)->x - reinterpret_cast<const Vector2D *>(src2)->x;
    reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src1)->y - reinterpret_cast<const Vector2D *>(src2)->y;
}

inline void Vector2D_SubtractValue(const void *src, float value, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x - value;
    reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y - value;
}

inline void Vector2D_SubtractXY(const void *src, float x, float y, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x - x;
    reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y - y;
}

inline void Vector2D_Multiply(const void *src1, const void *src2, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src1)->x * reinterpret_cast<const Vector2D *>(src2)->x;
    reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src1)->y * reinterpret_cast<const Vector2D *>(src2)->y;
}

inline void Vector2D_MultiplyValue(const void *src, float value, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x * value;
    reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y * value;
}

inline void Vector2D_MultiplyXY(const void *src, float x, float y, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x * x;
    reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y * y;
}

inline void Vector2D_Divide(const void *src1, const void *src2, void *dst)
{
    if (reinterpret_cast<const Vector2D *>(src2)->x == 0.0f)
        reinterpret_cast<Vector2D *>(dst)->x = 0.0f;
    else
        reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src1)->x / reinterpret_cast<const Vector2D *>(src2)->x;

    if (reinterpret_cast<const Vector2D *>(src2)->y == 0.0f)
        reinterpret_cast<Vector2D *>(dst)->y = 0.0f;
    else
        reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src1)->y / reinterpret_cast<const Vector2D *>(src2)->y;
}

inline void Vector2D_DivideValue(const void *src, float value, void *dst)
{
    if (value == 0.0f)
    {
        reinterpret_cast<Vector2D *>(dst)->x = 0.0f;
        reinterpret_cast<Vector2D *>(dst)->y = 0.0f;
    }
    else
    {
        value = 1.0f / value;

        reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x * value;
        reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y * value;
    }
}

inline void Vector2D_DivideXY(const void *src, float x, float y, void *dst)
{
    if (x == 0.0f)
        reinterpret_cast<Vector2D *>(dst)->x = 0.0f;
    else
        reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x / x;

    if (y == 0.0f)
        reinterpret_cast<Vector2D *>(dst)->y = 0.0f;
    else
        reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y / y;
}

inline void Vector2D_Negate(const void *src, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = -reinterpret_cast<const Vector2D *>(src)->x;
    reinterpret_cast<Vector2D *>(dst)->y = -reinterpret_cast<const Vector2D *>(src)->y;
}

inline auto constexpr Vector2D_GetLengthSquared(const void *src)
{
    return (reinterpret_cast<const Vector2D *>(src)->x * reinterpret_cast<const Vector2D *>(src)->x) + (reinterpret_cast<const Vector2D *>(src)->y * reinterpret_cast<const Vector2D *>(src)->y);
}

inline auto constexpr Vector2D_GetLength(const void *src)
{
    return std::sqrt(Vector2D_GetLengthSquared(src));
}

inline auto constexpr Vector2D_GetDistanceSquared(const void *src1, const void *src2)
{
    return (reinterpret_cast<const Vector2D *>(src1)->x - reinterpret_cast<const Vector2D *>(src2)->x) * (reinterpret_cast<const Vector2D *>(src1)->x - reinterpret_cast<const Vector2D *>(src2)->x) +
           (reinterpret_cast<const Vector2D *>(src1)->y - reinterpret_cast<const Vector2D *>(src2)->y) * (reinterpret_cast<const Vector2D *>(src1)->y - reinterpret_cast<const Vector2D *>(src2)->y);
}

inline auto constexpr Vector2D_GetDistance(const void *src1, const void *src2)
{
    return std::sqrt(Vector2D_GetDistanceSquared(src1, src2));
}

inline void Vector2D_GetSizeVector(const void *src1, const void *src2, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = 1.0f + std::abs(reinterpret_cast<const Vector2D *>(src1)->x - reinterpret_cast<const Vector2D *>(src2)->x);
    reinterpret_cast<Vector2D *>(dst)->y = 1.0f + std::abs(reinterpret_cast<const Vector2D *>(src1)->y - reinterpret_cast<const Vector2D *>(src2)->y);
}

inline auto constexpr Vector2D_GetArea(const void *src)
{
    return reinterpret_cast<const Vector2D *>(src)->x * reinterpret_cast<const Vector2D *>(src)->y;
}

inline auto constexpr Vector2D_GetPerimeter(const void *src)
{
    return 2.0f * (reinterpret_cast<const Vector2D *>(src)->x + reinterpret_cast<const Vector2D *>(src)->y);
}

inline auto constexpr Vector2D_GetDotProduct(const void *src1, const void *src2)
{
    return (reinterpret_cast<const Vector2D *>(src1)->x * reinterpret_cast<const Vector2D *>(src2)->x) + (reinterpret_cast<const Vector2D *>(src1)->y * reinterpret_cast<const Vector2D *>(src2)->y);
}

inline auto constexpr Vector2D_GetAngle(const void *src1, const void *src2)
{
    return std::atan2(reinterpret_cast<const Vector2D *>(src1)->x * reinterpret_cast<const Vector2D *>(src2)->y - reinterpret_cast<const Vector2D *>(src1)->y * reinterpret_cast<const Vector2D *>(src2)->x, Vector2D_GetDotProduct(src1, src2));
}

inline auto constexpr Vector2D_GetLineAngle(const void *src1, const void *src2)
{
    return -std::atan2(reinterpret_cast<const Vector2D *>(src2)->y - reinterpret_cast<const Vector2D *>(src1)->y, reinterpret_cast<const Vector2D *>(src2)->x - reinterpret_cast<const Vector2D *>(src1)->x);
}

inline void Vector2D_Normalize(const void *src, void *dst)
{
    auto length = Vector2D_GetLength(src);

    if (length > 0.0f)
    {
        auto inverseLength = 1.0f / length;

        reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x * inverseLength;
        reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y * inverseLength;
    }
    else
    {
        reinterpret_cast<Vector2D *>(dst)->x = 0.0f;
        reinterpret_cast<Vector2D *>(dst)->y = 0.0f;
    }
}

inline void Vector2D_Lerp(const void *src1, const void *src2, float t, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src1)->x + (reinterpret_cast<const Vector2D *>(src2)->x - reinterpret_cast<const Vector2D *>(src1)->x) * t;
    reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src1)->y + (reinterpret_cast<const Vector2D *>(src2)->y - reinterpret_cast<const Vector2D *>(src1)->y) * t;
}

inline void Vector2D_Reflect(const void *src, const void *normal, void *dst)
{
    auto dot = Vector2D_GetDotProduct(src, normal);

    reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x - 2.0f * reinterpret_cast<const Vector2D *>(normal)->x * dot;
    reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y - 2.0f * reinterpret_cast<const Vector2D *>(normal)->y * dot;
}

inline void Vector2D_Rotate(const void *src, float angle, void *dst)
{
    auto cosres = std::cos(angle);
    auto sinres = std::sin(angle);

    reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x * cosres - reinterpret_cast<const Vector2D *>(src)->y * sinres;
    reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->x * sinres + reinterpret_cast<const Vector2D *>(src)->y * cosres;
}

inline void Vector2D_MoveTowards(const void *src, const void *target, float maxDistance, void *dst)
{
    auto dx = reinterpret_cast<const Vector2D *>(target)->x - reinterpret_cast<const Vector2D *>(src)->x;
    auto dy = reinterpret_cast<const Vector2D *>(target)->y - reinterpret_cast<const Vector2D *>(src)->y;
    auto value = (dx * dx) + (dy * dy);

    if ((value == 0) || ((maxDistance >= 0) && (value <= maxDistance * maxDistance)))
    {
        reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(target)->x;
        reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(target)->y;
    }
    else
    {
        auto dist = std::sqrt(value);
        reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x + dx / dist * maxDistance;
        reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y + dy / dist * maxDistance;
    }
}

inline void Vector2D_Invert(const void *src, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = 1.0f / reinterpret_cast<const Vector2D *>(src)->x;
    reinterpret_cast<Vector2D *>(dst)->y = 1.0f / reinterpret_cast<const Vector2D *>(src)->y;
}

inline void Vector2D_Clamp(const void *src, const void *min, const void *max, void *dst)
{
    reinterpret_cast<Vector2D *>(dst)->x = std::min(std::max(reinterpret_cast<const Vector2D *>(src)->x, reinterpret_cast<const Vector2D *>(min)->x), reinterpret_cast<const Vector2D *>(max)->x);
    reinterpret_cast<Vector2D *>(dst)->y = std::min(std::max(reinterpret_cast<const Vector2D *>(src)->y, reinterpret_cast<const Vector2D *>(min)->y), reinterpret_cast<const Vector2D *>(max)->y);
}

inline void Vector2D_ClampValue(const void *src, float min, float max, void *dst)
{
    auto length = reinterpret_cast<const Vector2D *>(src)->x * reinterpret_cast<const Vector2D *>(src)->x + reinterpret_cast<const Vector2D *>(src)->y * reinterpret_cast<const Vector2D *>(src)->y;

    if (length > 0.0f)
    {
        length = std::sqrt(length);

        if (length < min)
        {
            auto scale = min / length;
            reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x * scale;
            reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y * scale;
        }
        else if (length > max)
        {
            auto scale = max / length;
            reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x * scale;
            reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y * scale;
        }
        else
        {
            reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x;
            reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y;
        }
    }
    else
    {
        reinterpret_cast<Vector2D *>(dst)->x = reinterpret_cast<const Vector2D *>(src)->x;
        reinterpret_cast<Vector2D *>(dst)->y = reinterpret_cast<const Vector2D *>(src)->y;
    }
}

//----------------------------------------------------------------------------------------------------------------------
// 2D Vector (integer) routines
// Copyright (c) 2025 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "../Types.h"
#include <algorithm>
#include <cmath>
#include <cstdint>

struct Vector2i {
    int32_t x;
    int32_t y;
};

inline void Vector2i_Reset(void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<Vector2i *>(dst)->y = 0;
}

inline void Vector2i_Initialize(int32_t x, int32_t y, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = x;
    reinterpret_cast<Vector2i *>(dst)->y = y;
}

inline void Vector2i_Assign(const void *src, void *dst) {
    *reinterpret_cast<Vector2i *>(dst) = *reinterpret_cast<const Vector2i *>(src);
}

inline qb_bool Vector2i_IsNull(const void *src) {
    return TO_QB_BOOL(reinterpret_cast<const Vector2i *>(src)->x == 0 && reinterpret_cast<const Vector2i *>(src)->y == 0);
}

inline void Vector2i_Add(const void *src1, const void *src2, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src1)->x + reinterpret_cast<const Vector2i *>(src2)->x;
    reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src1)->y + reinterpret_cast<const Vector2i *>(src2)->y;
}

inline void Vector2i_AddValue(const void *src, int32_t value, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x + value;
    reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->y + value;
}

inline void Vector2i_AddXY(const void *src, int32_t x, int32_t y, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x + x;
    reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->y + y;
}

inline void Vector2i_Subtract(const void *src1, const void *src2, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src1)->x - reinterpret_cast<const Vector2i *>(src2)->x;
    reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src1)->y - reinterpret_cast<const Vector2i *>(src2)->y;
}

inline void Vector2i_SubtractValue(const void *src, int32_t value, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x - value;
    reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->y - value;
}

inline void Vector2i_SubtractXY(const void *src, int32_t x, int32_t y, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x - x;
    reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->y - y;
}

inline void Vector2i_Multiply(const void *src1, const void *src2, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src1)->x * reinterpret_cast<const Vector2i *>(src2)->x;
    reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src1)->y * reinterpret_cast<const Vector2i *>(src2)->y;
}

inline void Vector2i_MultiplyValue(const void *src, int32_t value, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x * value;
    reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->y * value;
}

inline void Vector2i_MultiplyXY(const void *src, int32_t x, int32_t y, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x * x;
    reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->y * y;
}

inline void Vector2i_Divide(const void *src1, const void *src2, void *dst) {
    if (reinterpret_cast<const Vector2i *>(src2)->x == 0)
        reinterpret_cast<Vector2i *>(dst)->x = 0;
    else
        reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src1)->x / reinterpret_cast<const Vector2i *>(src2)->x;

    if (reinterpret_cast<const Vector2i *>(src2)->y == 0)
        reinterpret_cast<Vector2i *>(dst)->y = 0;
    else
        reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src1)->y / reinterpret_cast<const Vector2i *>(src2)->y;
}

inline void Vector2i_DivideValue(const void *src, int32_t value, void *dst) {
    if (value == 0) {
        reinterpret_cast<Vector2i *>(dst)->x = 0;
        reinterpret_cast<Vector2i *>(dst)->y = 0;
    } else {
        reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x / value;
        reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->y / value;
    }
}

inline void Vector2i_DivideXY(const void *src, int32_t x, int32_t y, void *dst) {
    if (x == 0)
        reinterpret_cast<Vector2i *>(dst)->x = 0;
    else
        reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x / x;

    if (y == 0)
        reinterpret_cast<Vector2i *>(dst)->y = 0;
    else
        reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->y / y;
}

inline void Vector2i_Negate(const void *src, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = -reinterpret_cast<const Vector2i *>(src)->x;
    reinterpret_cast<Vector2i *>(dst)->y = -reinterpret_cast<const Vector2i *>(src)->y;
}

inline int32_t Vector2i_GetLengthSquared(const void *src) {
    return (reinterpret_cast<const Vector2i *>(src)->x * reinterpret_cast<const Vector2i *>(src)->x) +
           (reinterpret_cast<const Vector2i *>(src)->y * reinterpret_cast<const Vector2i *>(src)->y);
}

inline int32_t Vector2i_GetLength(const void *src) {
    return std::sqrt(Vector2i_GetLengthSquared(src));
}

inline int32_t Vector2i_GetDistanceSquared(const void *src1, const void *src2) {
    Vector2i diff;
    Vector2i_Subtract(src1, src2, &diff);
    return Vector2i_GetLengthSquared(&diff);
}

inline int32_t Vector2i_GetDistance(const void *src1, const void *src2) {
    return std::sqrt(Vector2i_GetDistanceSquared(src1, src2));
}

inline void Vector2i_GetSizeVector(const void *src1, const void *src2, void *dst) {
    Vector2i diff;
    Vector2i_Subtract(src1, src2, &diff);
    reinterpret_cast<Vector2i *>(dst)->x = 1 + std::abs(diff.x);
    reinterpret_cast<Vector2i *>(dst)->y = 1 + std::abs(diff.y);
}

inline int32_t Vector2i_GetArea(const void *src) {
    return reinterpret_cast<const Vector2i *>(src)->x * reinterpret_cast<const Vector2i *>(src)->y;
}

inline int32_t Vector2i_GetPerimeter(const void *src) {
    return 2 * (reinterpret_cast<const Vector2i *>(src)->x + reinterpret_cast<const Vector2i *>(src)->y);
}

inline int32_t Vector2i_GetDotProduct(const void *src1, const void *src2) {
    return (reinterpret_cast<const Vector2i *>(src1)->x * reinterpret_cast<const Vector2i *>(src2)->x) +
           (reinterpret_cast<const Vector2i *>(src1)->y * reinterpret_cast<const Vector2i *>(src2)->y);
}

inline int32_t Vector2i_GetCrossProduct(const void *src1, const void *src2) {
    return (reinterpret_cast<const Vector2i *>(src1)->x * reinterpret_cast<const Vector2i *>(src2)->y) -
           (reinterpret_cast<const Vector2i *>(src1)->y * reinterpret_cast<const Vector2i *>(src2)->x);
}

inline void Vector2i_TurnRight(const void *src, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->y;
    reinterpret_cast<Vector2i *>(dst)->y = -reinterpret_cast<const Vector2i *>(src)->x;
}

inline void Vector2i_TurnLeft(const void *src, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = -reinterpret_cast<const Vector2i *>(src)->y;
    reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->x;
}

inline void Vector2i_FlipHorizontal(const void *src, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = -reinterpret_cast<const Vector2i *>(src)->x;
    reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->y;
}

inline void Vector2i_FlipVertical(const void *src, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x;
    reinterpret_cast<Vector2i *>(dst)->y = -reinterpret_cast<const Vector2i *>(src)->y;
}

inline void Vector2i_Lerp(const void *src1, const void *src2, float amount, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x =
        reinterpret_cast<const Vector2i *>(src1)->x + (reinterpret_cast<const Vector2i *>(src2)->x - reinterpret_cast<const Vector2i *>(src1)->x) * amount;
    reinterpret_cast<Vector2i *>(dst)->y =
        reinterpret_cast<const Vector2i *>(src1)->y + (reinterpret_cast<const Vector2i *>(src2)->y - reinterpret_cast<const Vector2i *>(src1)->y) * amount;
}

inline void Vector2i_Reflect(const void *src, const void *normal, void *dst) {
    auto dot = Vector2i_GetDotProduct(src, normal);
    Vector2i scaled;
    Vector2i_MultiplyValue(normal, 2 * dot, &scaled);
    Vector2i_Subtract(src, &scaled, dst);
}

inline void Vector2i_Rotate(const void *src, float angle, void *dst) {
    auto cosres = std::cos(angle);
    auto sinres = std::sin(angle);

    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x * cosres - reinterpret_cast<const Vector2i *>(src)->y * sinres;
    reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->x * sinres + reinterpret_cast<const Vector2i *>(src)->y * cosres;
}

inline void Vector2i_MoveTowards(const void *src, const void *target, int32_t maxDistance, void *dst) {
    auto dx = reinterpret_cast<const Vector2i *>(target)->x - reinterpret_cast<const Vector2i *>(src)->x;
    auto dy = reinterpret_cast<const Vector2i *>(target)->y - reinterpret_cast<const Vector2i *>(src)->y;
    auto value = (dx * dx) + (dy * dy);

    if ((value == 0) || ((maxDistance >= 0) && (value <= maxDistance * maxDistance))) {
        reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(target)->x;
        reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(target)->y;
    } else {
        auto dist = std::sqrt(value);
        reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x + dx / dist * maxDistance;
        reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->y + dy / dist * maxDistance;
    }
}

inline void Vector2i_Clamp(const void *src, const void *min, const void *max, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x =
        std::min(std::max(reinterpret_cast<const Vector2i *>(src)->x, reinterpret_cast<const Vector2i *>(min)->x), reinterpret_cast<const Vector2i *>(max)->x);
    reinterpret_cast<Vector2i *>(dst)->y =
        std::min(std::max(reinterpret_cast<const Vector2i *>(src)->y, reinterpret_cast<const Vector2i *>(min)->y), reinterpret_cast<const Vector2i *>(max)->y);
}

inline void Vector2i_ClampValue(const void *src, int32_t min, int32_t max, void *dst) {
    auto length = reinterpret_cast<const Vector2i *>(src)->x * reinterpret_cast<const Vector2i *>(src)->x +
                  reinterpret_cast<const Vector2i *>(src)->y * reinterpret_cast<const Vector2i *>(src)->y;

    if (length > 0) {
        length = std::sqrt(length);

        if (length < min) {
            auto scale = min / length;
            reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x * scale;
            reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->y * scale;
        } else if (length > max) {
            auto scale = max / length;
            reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x * scale;
            reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->y * scale;
        } else {
            reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x;
            reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->y;
        }
    } else {
        reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Vector2i *>(src)->x;
        reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Vector2i *>(src)->y;
    }
}

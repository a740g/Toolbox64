//----------------------------------------------------------------------------------------------------------------------
// 2D Vector (floating point) routines
// Copyright (c) 2025 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "../Core/Types.h"
#include <algorithm>
#include <cmath>
#include <cstdint>

struct Vector2f {
    float x;
    float y;
};

inline void Vector2f_Reset(void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<Vector2f *>(dst)->y = 0.0f;
}

inline void Vector2f_Initialize(float x, float y, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = x;
    reinterpret_cast<Vector2f *>(dst)->y = y;
}

inline void Vector2f_Assign(const void *src, void *dst) {
    *reinterpret_cast<Vector2f *>(dst) = *reinterpret_cast<const Vector2f *>(src);
}

inline qb_bool Vector2f_IsNull(const void *src) {
    return TO_QB_BOOL(reinterpret_cast<const Vector2f *>(src)->x == 0.0f && reinterpret_cast<const Vector2f *>(src)->y == 0.0f);
}

inline void Vector2f_Add(const void *src1, const void *src2, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src1)->x + reinterpret_cast<const Vector2f *>(src2)->x;
    reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src1)->y + reinterpret_cast<const Vector2f *>(src2)->y;
}

inline void Vector2f_AddValue(const void *src, float value, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x + value;
    reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y + value;
}

inline void Vector2f_AddXY(const void *src, float x, float y, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x + x;
    reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y + y;
}

inline void Vector2f_Subtract(const void *src1, const void *src2, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src1)->x - reinterpret_cast<const Vector2f *>(src2)->x;
    reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src1)->y - reinterpret_cast<const Vector2f *>(src2)->y;
}

inline void Vector2f_SubtractValue(const void *src, float value, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x - value;
    reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y - value;
}

inline void Vector2f_SubtractXY(const void *src, float x, float y, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x - x;
    reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y - y;
}

inline void Vector2f_Multiply(const void *src1, const void *src2, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src1)->x * reinterpret_cast<const Vector2f *>(src2)->x;
    reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src1)->y * reinterpret_cast<const Vector2f *>(src2)->y;
}

inline void Vector2f_MultiplyValue(const void *src, float value, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x * value;
    reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y * value;
}

inline void Vector2f_MultiplyXY(const void *src, float x, float y, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x * x;
    reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y * y;
}

inline void Vector2f_Divide(const void *src1, const void *src2, void *dst) {
    if (reinterpret_cast<const Vector2f *>(src2)->x == 0.0f)
        reinterpret_cast<Vector2f *>(dst)->x = 0.0f;
    else
        reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src1)->x / reinterpret_cast<const Vector2f *>(src2)->x;

    if (reinterpret_cast<const Vector2f *>(src2)->y == 0.0f)
        reinterpret_cast<Vector2f *>(dst)->y = 0.0f;
    else
        reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src1)->y / reinterpret_cast<const Vector2f *>(src2)->y;
}

inline void Vector2f_DivideValue(const void *src, float value, void *dst) {
    if (value == 0.0f) {
        reinterpret_cast<Vector2f *>(dst)->x = 0.0f;
        reinterpret_cast<Vector2f *>(dst)->y = 0.0f;
    } else {
        value = 1.0f / value;

        reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x * value;
        reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y * value;
    }
}

inline void Vector2f_DivideXY(const void *src, float x, float y, void *dst) {
    if (x == 0.0f)
        reinterpret_cast<Vector2f *>(dst)->x = 0.0f;
    else
        reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x / x;

    if (y == 0.0f)
        reinterpret_cast<Vector2f *>(dst)->y = 0.0f;
    else
        reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y / y;
}

inline void Vector2f_Negate(const void *src, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = -reinterpret_cast<const Vector2f *>(src)->x;
    reinterpret_cast<Vector2f *>(dst)->y = -reinterpret_cast<const Vector2f *>(src)->y;
}

inline float Vector2f_GetLengthSquared(const void *src) {
    return (reinterpret_cast<const Vector2f *>(src)->x * reinterpret_cast<const Vector2f *>(src)->x) +
           (reinterpret_cast<const Vector2f *>(src)->y * reinterpret_cast<const Vector2f *>(src)->y);
}

inline float Vector2f_GetLength(const void *src) {
    return std::sqrt(Vector2f_GetLengthSquared(src));
}

inline float Vector2f_GetDistanceSquared(const void *src1, const void *src2) {
    return (reinterpret_cast<const Vector2f *>(src1)->x - reinterpret_cast<const Vector2f *>(src2)->x) *
               (reinterpret_cast<const Vector2f *>(src1)->x - reinterpret_cast<const Vector2f *>(src2)->x) +
           (reinterpret_cast<const Vector2f *>(src1)->y - reinterpret_cast<const Vector2f *>(src2)->y) *
               (reinterpret_cast<const Vector2f *>(src1)->y - reinterpret_cast<const Vector2f *>(src2)->y);
}

inline float Vector2f_GetDistance(const void *src1, const void *src2) {
    return std::sqrt(Vector2f_GetDistanceSquared(src1, src2));
}

inline void Vector2f_GetSizeVector(const void *src1, const void *src2, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = 1.0f + std::abs(reinterpret_cast<const Vector2f *>(src1)->x - reinterpret_cast<const Vector2f *>(src2)->x);
    reinterpret_cast<Vector2f *>(dst)->y = 1.0f + std::abs(reinterpret_cast<const Vector2f *>(src1)->y - reinterpret_cast<const Vector2f *>(src2)->y);
}

inline float Vector2f_GetArea(const void *src) {
    return reinterpret_cast<const Vector2f *>(src)->x * reinterpret_cast<const Vector2f *>(src)->y;
}

inline float Vector2f_GetPerimeter(const void *src) {
    return 2.0f * (reinterpret_cast<const Vector2f *>(src)->x + reinterpret_cast<const Vector2f *>(src)->y);
}

inline float Vector2f_GetDotProduct(const void *src1, const void *src2) {
    return (reinterpret_cast<const Vector2f *>(src1)->x * reinterpret_cast<const Vector2f *>(src2)->x) +
           (reinterpret_cast<const Vector2f *>(src1)->y * reinterpret_cast<const Vector2f *>(src2)->y);
}

inline float Vector2f_GetCrossProduct(const void *src1, const void *src2) {
    return (reinterpret_cast<const Vector2f *>(src1)->x * reinterpret_cast<const Vector2f *>(src2)->y) -
           (reinterpret_cast<const Vector2f *>(src1)->y * reinterpret_cast<const Vector2f *>(src2)->x);
}

inline float Vector2f_GetAngle(const void *src1, const void *src2) {
    return std::atan2(reinterpret_cast<const Vector2f *>(src1)->x * reinterpret_cast<const Vector2f *>(src2)->y -
                          reinterpret_cast<const Vector2f *>(src1)->y * reinterpret_cast<const Vector2f *>(src2)->x,
                      Vector2f_GetDotProduct(src1, src2));
}

inline float Vector2f_GetLineAngle(const void *src1, const void *src2) {
    return -std::atan2(reinterpret_cast<const Vector2f *>(src2)->y - reinterpret_cast<const Vector2f *>(src1)->y,
                       reinterpret_cast<const Vector2f *>(src2)->x - reinterpret_cast<const Vector2f *>(src1)->x);
}

inline void Vector2f_Normalize(const void *src, void *dst) {
    auto length = Vector2f_GetLength(src);

    if (length > 0.0f) {
        auto inverseLength = 1.0f / length;

        reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x * inverseLength;
        reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y * inverseLength;
    } else {
        reinterpret_cast<Vector2f *>(dst)->x = 0.0f;
        reinterpret_cast<Vector2f *>(dst)->y = 0.0f;
    }
}

inline void Vector2f_Lerp(const void *src1, const void *src2, float t, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x =
        reinterpret_cast<const Vector2f *>(src1)->x + (reinterpret_cast<const Vector2f *>(src2)->x - reinterpret_cast<const Vector2f *>(src1)->x) * t;
    reinterpret_cast<Vector2f *>(dst)->y =
        reinterpret_cast<const Vector2f *>(src1)->y + (reinterpret_cast<const Vector2f *>(src2)->y - reinterpret_cast<const Vector2f *>(src1)->y) * t;
}

inline void Vector2f_Reflect(const void *src, const void *normal, void *dst) {
    auto dot = Vector2f_GetDotProduct(src, normal);

    reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x - 2.0f * reinterpret_cast<const Vector2f *>(normal)->x * dot;
    reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y - 2.0f * reinterpret_cast<const Vector2f *>(normal)->y * dot;
}

inline void Vector2f_Rotate(const void *src, float angle, void *dst) {
    auto cosres = std::cos(angle);
    auto sinres = std::sin(angle);

    reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x * cosres - reinterpret_cast<const Vector2f *>(src)->y * sinres;
    reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->x * sinres + reinterpret_cast<const Vector2f *>(src)->y * cosres;
}

inline void Vector2f_MoveTowards(const void *src, const void *target, float maxDistance, void *dst) {
    auto dx = reinterpret_cast<const Vector2f *>(target)->x - reinterpret_cast<const Vector2f *>(src)->x;
    auto dy = reinterpret_cast<const Vector2f *>(target)->y - reinterpret_cast<const Vector2f *>(src)->y;
    auto value = (dx * dx) + (dy * dy);

    if ((value == 0) || ((maxDistance >= 0) && (value <= maxDistance * maxDistance))) {
        reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(target)->x;
        reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(target)->y;
    } else {
        auto dist = std::sqrt(value);
        reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x + dx / dist * maxDistance;
        reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y + dy / dist * maxDistance;
    }
}

inline void Vector2f_TurnLeft(const void *src, void *dst) {
    // 90 degree CCW rotation: (x, y) -> (-y, x)
    reinterpret_cast<Vector2f *>(dst)->x = -reinterpret_cast<const Vector2f *>(src)->y;
    reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->x;
}

inline void Vector2f_TurnRight(const void *src, void *dst) {
    // 90 degree CW rotation: (x, y) -> (y, -x)
    reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->y;
    reinterpret_cast<Vector2f *>(dst)->y = -reinterpret_cast<const Vector2f *>(src)->x;
}

inline void Vector2f_FlipVertical(const void *src, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x;
    reinterpret_cast<Vector2f *>(dst)->y = -reinterpret_cast<const Vector2f *>(src)->y;
}

inline void Vector2f_FlipHorizontal(const void *src, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = -reinterpret_cast<const Vector2f *>(src)->x;
    reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y;
}

inline void Vector2f_Reciprocal(const void *src, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x = 1.0f / reinterpret_cast<const Vector2f *>(src)->x;
    reinterpret_cast<Vector2f *>(dst)->y = 1.0f / reinterpret_cast<const Vector2f *>(src)->y;
}

inline void Vector2f_Clamp(const void *src, const void *min, const void *max, void *dst) {
    reinterpret_cast<Vector2f *>(dst)->x =
        std::min(std::max(reinterpret_cast<const Vector2f *>(src)->x, reinterpret_cast<const Vector2f *>(min)->x), reinterpret_cast<const Vector2f *>(max)->x);
    reinterpret_cast<Vector2f *>(dst)->y =
        std::min(std::max(reinterpret_cast<const Vector2f *>(src)->y, reinterpret_cast<const Vector2f *>(min)->y), reinterpret_cast<const Vector2f *>(max)->y);
}

inline void Vector2f_ClampValue(const void *src, float min, float max, void *dst) {
    auto length = reinterpret_cast<const Vector2f *>(src)->x * reinterpret_cast<const Vector2f *>(src)->x +
                  reinterpret_cast<const Vector2f *>(src)->y * reinterpret_cast<const Vector2f *>(src)->y;

    if (length > 0.0f) {
        length = std::sqrt(length);

        if (length < min) {
            auto scale = min / length;
            reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x * scale;
            reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y * scale;
        } else if (length > max) {
            auto scale = max / length;
            reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x * scale;
            reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y * scale;
        } else {
            reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x;
            reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y;
        }
    } else {
        reinterpret_cast<Vector2f *>(dst)->x = reinterpret_cast<const Vector2f *>(src)->x;
        reinterpret_cast<Vector2f *>(dst)->y = reinterpret_cast<const Vector2f *>(src)->y;
    }
}

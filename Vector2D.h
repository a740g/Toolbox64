//----------------------------------------------------------------------------------------------------------------------
// 2D Vector routines
// Copyright (c) 2024 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Types.h"

struct Vector2D
{
    int32_t x;
    int32_t y;
};

inline void Vector2D_Reset(Vector2D *v)
{
    v->x = v->y = 0;
}

inline void Vector2D_Initialize(Vector2D *v, int32_t x, int32_t y)
{
    v->x = x;
    v->y = y;
}

inline void Vector2D_Assign(Vector2D *v, const Vector2D *other)
{
    v->x = other->x;
    v->y = other->y;
}

inline qb_bool Vector2D_IsNull(Vector2D *v)
{
    return TO_QB_BOOL(!v->x && !v->y);
}

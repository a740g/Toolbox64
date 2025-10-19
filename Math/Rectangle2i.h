//----------------------------------------------------------------------------------------------------------------------
// 2D Rectangle (integer) routines
// Copyright (c) 2024 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Vector2i.h"

struct Rectangle2i {
    Vector2i position;
    Vector2i size;
};

inline void Rectangle2i_Reset(void *dst) {
    reinterpret_cast<Rectangle2i *>(dst)->position.x = reinterpret_cast<Rectangle2i *>(dst)->position.y = 0;
    reinterpret_cast<Rectangle2i *>(dst)->size.x = reinterpret_cast<Rectangle2i *>(dst)->size.y = 0;
}

inline void Rectangle2i_Initialize(int32_t x, int32_t y, int32_t w, int32_t h, void *dst) {
    reinterpret_cast<Rectangle2i *>(dst)->position.x = x;
    reinterpret_cast<Rectangle2i *>(dst)->position.y = y;
    reinterpret_cast<Rectangle2i *>(dst)->size.x = w;
    reinterpret_cast<Rectangle2i *>(dst)->size.y = h;
}

inline void Rectangle2i_Assign(const void *src, void *dst) {
    *reinterpret_cast<Rectangle2i *>(dst) = *reinterpret_cast<const Rectangle2i *>(src);
}

inline void Rectangle2i_InitializeFromPositionSize(const void *position, const void *size, void *dst) {
    reinterpret_cast<Rectangle2i *>(dst)->position = *reinterpret_cast<const Vector2i *>(position);
    reinterpret_cast<Rectangle2i *>(dst)->size = *reinterpret_cast<const Vector2i *>(size);
}

inline void Rectangle2i_InitializeFromPoints(const void *p1, const void *p2, void *dst) {
    reinterpret_cast<Rectangle2i *>(dst)->position = *reinterpret_cast<const Vector2i *>(p1);
    Vector2i_GetSizeVector(p1, p2, &reinterpret_cast<Rectangle2i *>(dst)->size);
}

inline qb_bool Rectangle2i_IsEmpty(const void *src) {
    return TO_QB_BOOL(reinterpret_cast<const Rectangle2i *>(src)->size.x <= 0 || reinterpret_cast<const Rectangle2i *>(src)->size.y <= 0);
}

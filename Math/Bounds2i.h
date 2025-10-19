//----------------------------------------------------------------------------------------------------------------------
// 2D Bounding Box (integer) routines
// Copyright (c) 2024 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Vector2i.h"

struct Bounds2i {
    Vector2i lt;
    Vector2i rb;
};

inline void Bounds2i_Reset(void *dst) {
    reinterpret_cast<Bounds2i *>(dst)->lt.x = reinterpret_cast<Bounds2i *>(dst)->lt.y = 0;
    reinterpret_cast<Bounds2i *>(dst)->rb.x = reinterpret_cast<Bounds2i *>(dst)->rb.y = 0;
}

inline void Bounds2i_Initialize(int32_t x1, int32_t y1, int32_t x2, int32_t y2, void *dst) {
    reinterpret_cast<Bounds2i *>(dst)->lt.x = x1;
    reinterpret_cast<Bounds2i *>(dst)->lt.y = y1;
    reinterpret_cast<Bounds2i *>(dst)->rb.x = x2;
    reinterpret_cast<Bounds2i *>(dst)->rb.y = y2;
}

inline void Bounds2i_Assign(const void *src, void *dst) {
    *reinterpret_cast<Bounds2i *>(dst) = *reinterpret_cast<const Bounds2i *>(src);
}

inline void Bounds2i_InitializeFromPositionSize(const void *position, const void *size, void *dst) {
    Vector2i_Assign(position, &reinterpret_cast<Bounds2i *>(dst)->lt);
    Vector2i_Add(position, size, &reinterpret_cast<Bounds2i *>(dst)->rb);
}

inline void Bounds2i_InitializeFromPoints(const void *p1, const void *p2, void *dst) {
    reinterpret_cast<Bounds2i *>(dst)->lt = *reinterpret_cast<const Vector2i *>(p1);
    reinterpret_cast<Bounds2i *>(dst)->rb = *reinterpret_cast<const Vector2i *>(p2);
}

inline qb_bool Bounds2i_IsEmpty(const void *src) {
    return TO_QB_BOOL(reinterpret_cast<const Bounds2i *>(src)->rb.x < reinterpret_cast<const Bounds2i *>(src)->lt.x ||
                      reinterpret_cast<const Bounds2i *>(src)->rb.y < reinterpret_cast<const Bounds2i *>(src)->lt.y);
}

inline qb_bool Bounds2i_IsValid(const void *src) {
    return TO_QB_BOOL(reinterpret_cast<const Bounds2i *>(src)->rb.x >= reinterpret_cast<const Bounds2i *>(src)->lt.x &&
                      reinterpret_cast<const Bounds2i *>(src)->rb.y >= reinterpret_cast<const Bounds2i *>(src)->lt.y);
}

inline qb_bool Bounds2i_HasNoWidth(const void *src) {
    return TO_QB_BOOL(reinterpret_cast<const Bounds2i *>(src)->rb.x < reinterpret_cast<const Bounds2i *>(src)->lt.x);
}

inline qb_bool Bounds2i_HasNoHeight(const void *src) {
    return TO_QB_BOOL(reinterpret_cast<const Bounds2i *>(src)->rb.y < reinterpret_cast<const Bounds2i *>(src)->lt.y);
}

inline int32_t Bounds2i_GetWidth(const void *src) {
    auto w = reinterpret_cast<const Bounds2i *>(src)->rb.x - reinterpret_cast<const Bounds2i *>(src)->lt.x + 1;
    return w > 0 ? w : 0;
}

inline int32_t Bounds2i_GetHeight(const void *src) {
    auto h = reinterpret_cast<const Bounds2i *>(src)->rb.y - reinterpret_cast<const Bounds2i *>(src)->lt.y + 1;
    return h > 0 ? h : 0;
}

inline void Bounds2i_GetCenter(const void *src, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = (reinterpret_cast<const Bounds2i *>(src)->lt.x + reinterpret_cast<const Bounds2i *>(src)->rb.x) / 2;
    reinterpret_cast<Vector2i *>(dst)->y = (reinterpret_cast<const Bounds2i *>(src)->lt.y + reinterpret_cast<const Bounds2i *>(src)->rb.y) / 2;
}

inline void Bounds2i_GetSize(const void *src, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = Bounds2i_GetWidth(src);
    reinterpret_cast<Vector2i *>(dst)->y = Bounds2i_GetHeight(src);
}

inline void Bounds2i_Sanitize(void *src) {
    if (reinterpret_cast<Bounds2i *>(src)->lt.x > reinterpret_cast<Bounds2i *>(src)->rb.x) {
        std::swap(reinterpret_cast<Bounds2i *>(src)->lt.x, reinterpret_cast<Bounds2i *>(src)->rb.x);
    }
    if (reinterpret_cast<Bounds2i *>(src)->lt.y > reinterpret_cast<Bounds2i *>(src)->rb.y) {
        std::swap(reinterpret_cast<Bounds2i *>(src)->lt.y, reinterpret_cast<Bounds2i *>(src)->rb.y);
    }
}

inline void Bounds2i_GetRightTop(const void *src, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Bounds2i *>(src)->rb.x;
    reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Bounds2i *>(src)->lt.y;
}

inline void Bounds2i_GetLeftBottom(const void *src, void *dst) {
    reinterpret_cast<Vector2i *>(dst)->x = reinterpret_cast<const Bounds2i *>(src)->lt.x;
    reinterpret_cast<Vector2i *>(dst)->y = reinterpret_cast<const Bounds2i *>(src)->rb.y;
}

inline void Bounds2i_SetRightTop(const void *src, const void *point, void *dst) {
    reinterpret_cast<Bounds2i *>(dst)->rb.x = reinterpret_cast<const Vector2i *>(point)->x;
    reinterpret_cast<Bounds2i *>(dst)->lt.y = reinterpret_cast<const Vector2i *>(point)->y;
}

inline void Bounds2i_SetLeftBottom(const void *src, const void *point, void *dst) {
    reinterpret_cast<Bounds2i *>(dst)->lt.x = reinterpret_cast<const Vector2i *>(point)->x;
    reinterpret_cast<Bounds2i *>(dst)->rb.y = reinterpret_cast<const Vector2i *>(point)->y;
}

inline int32_t Bounds2i_GetArea(const void *src) {
    return Bounds2i_GetWidth(src) * Bounds2i_GetHeight(src);
}

inline int32_t Bounds2i_GetPerimeter(const void *src) {
    return (Bounds2i_GetWidth(src) + Bounds2i_GetHeight(src)) * 2;
}

inline int32_t Bounds2i_GetDiagonalLength(const void *src) {
    return Vector2i_GetDistance(&reinterpret_cast<const Bounds2i *>(src)->lt, &reinterpret_cast<const Bounds2i *>(src)->rb);
}

inline qb_bool Bounds2i_HasSameArea(const void *src1, const void *src2) {
    return TO_QB_BOOL(Bounds2i_GetArea(src1) == Bounds2i_GetArea(src2));
}

inline void Bounds2i_Inflate(const void *src, int32_t x, int32_t y, void *dst) {
    Vector2i_SubtractXY(&reinterpret_cast<const Bounds2i *>(src)->lt, x, y, &reinterpret_cast<Bounds2i *>(dst)->lt);
    Vector2i_AddXY(&reinterpret_cast<const Bounds2i *>(src)->rb, x, y, &reinterpret_cast<Bounds2i *>(dst)->rb);
}

inline void Bounds2i_InflateByVector(const void *src, const void *vector, void *dst) {
    Vector2i_Subtract(&reinterpret_cast<const Bounds2i *>(src)->lt, vector, &reinterpret_cast<Bounds2i *>(dst)->lt);
    Vector2i_Add(&reinterpret_cast<const Bounds2i *>(src)->rb, vector, &reinterpret_cast<Bounds2i *>(dst)->rb);
}

inline void Bounds2i_Deflate(const void *src, int32_t x, int32_t y, void *dst) {
    Vector2i_AddXY(&reinterpret_cast<const Bounds2i *>(src)->lt, x, y, &reinterpret_cast<Bounds2i *>(dst)->lt);
    Vector2i_SubtractXY(&reinterpret_cast<const Bounds2i *>(src)->rb, x, y, &reinterpret_cast<Bounds2i *>(dst)->rb);
}

inline void Bounds2i_DeflateByVector(const void *src, const void *vector, void *dst) {
    Vector2i_Add(&reinterpret_cast<const Bounds2i *>(src)->lt, vector, &reinterpret_cast<Bounds2i *>(dst)->lt);
    Vector2i_Subtract(&reinterpret_cast<const Bounds2i *>(src)->rb, vector, &reinterpret_cast<Bounds2i *>(dst)->rb);
}

inline void Bounds2i_IncludePoint(const void *src, const void *point, void *dst) {
    reinterpret_cast<Bounds2i *>(dst)->lt.x = std::min(reinterpret_cast<const Bounds2i *>(src)->lt.x, reinterpret_cast<const Vector2i *>(point)->x);
    reinterpret_cast<Bounds2i *>(dst)->lt.y = std::min(reinterpret_cast<const Bounds2i *>(src)->lt.y, reinterpret_cast<const Vector2i *>(point)->y);
    reinterpret_cast<Bounds2i *>(dst)->rb.x = std::max(reinterpret_cast<const Bounds2i *>(src)->rb.x, reinterpret_cast<const Vector2i *>(point)->x);
    reinterpret_cast<Bounds2i *>(dst)->rb.y = std::max(reinterpret_cast<const Bounds2i *>(src)->rb.y, reinterpret_cast<const Vector2i *>(point)->y);
}

inline void Bounds2i_Translate(const void *src, int32_t x, int32_t y, void *dst) {
    Vector2i_AddXY(&reinterpret_cast<const Bounds2i *>(src)->lt, x, y, &reinterpret_cast<Bounds2i *>(dst)->lt);
    Vector2i_AddXY(&reinterpret_cast<const Bounds2i *>(src)->rb, x, y, &reinterpret_cast<Bounds2i *>(dst)->rb);
}

inline void Bounds2i_TranslateByVector(const void *src, const void *vector, void *dst) {
    Vector2i_Add(&reinterpret_cast<const Bounds2i *>(src)->lt, vector, &reinterpret_cast<Bounds2i *>(dst)->lt);
    Vector2i_Add(&reinterpret_cast<const Bounds2i *>(src)->rb, vector, &reinterpret_cast<Bounds2i *>(dst)->rb);
}

inline qb_bool Bounds2i_ContainsXY(const void *src, int32_t x, int32_t y) {
    return TO_QB_BOOL(reinterpret_cast<const Bounds2i *>(src)->lt.x <= x && reinterpret_cast<const Bounds2i *>(src)->rb.x >= x &&
                      reinterpret_cast<const Bounds2i *>(src)->lt.y <= y && reinterpret_cast<const Bounds2i *>(src)->rb.y >= y);
}

inline qb_bool Bounds2i_ContainsPoint(const void *src, const void *point) {
    return TO_QB_BOOL(reinterpret_cast<const Bounds2i *>(src)->lt.x <= reinterpret_cast<const Vector2i *>(point)->x &&
                      reinterpret_cast<const Bounds2i *>(src)->rb.x >= reinterpret_cast<const Vector2i *>(point)->x &&
                      reinterpret_cast<const Bounds2i *>(src)->lt.y <= reinterpret_cast<const Vector2i *>(point)->y &&
                      reinterpret_cast<const Bounds2i *>(src)->rb.y >= reinterpret_cast<const Vector2i *>(point)->y);
}

inline qb_bool Bounds2i_ContainsBounds(const void *src1, const void *src2) {
    return TO_QB_BOOL(Bounds2i_ContainsPoint(src1, &reinterpret_cast<const Bounds2i *>(src2)->lt) &&
                      Bounds2i_ContainsPoint(src1, &reinterpret_cast<const Bounds2i *>(src2)->rb));
}

inline qb_bool Bounds2i_Intersects(const void *src1, const void *src2) {
    auto a = reinterpret_cast<const Bounds2i *>(src1);
    auto b = reinterpret_cast<const Bounds2i *>(src2);
    return TO_QB_BOOL(a->lt.x <= b->rb.x && b->lt.x <= a->rb.x && a->lt.y <= b->rb.y && b->lt.y <= a->rb.y);
}

inline void Bounds2i_MakeUnion(const void *src1, const void *src2, void *dst) {
    auto src1Empty = Bounds2i_IsEmpty(src1);
    auto src2Empty = Bounds2i_IsEmpty(src2);

    if (src1Empty && src2Empty) {
        Bounds2i_Reset(dst);
    } else if (src1Empty) {
        Bounds2i_Assign(src2, dst);
    } else if (src2Empty) {
        Bounds2i_Assign(src1, dst);
    } else {
        reinterpret_cast<Bounds2i *>(dst)->lt.x = std::min(reinterpret_cast<const Bounds2i *>(src1)->lt.x, reinterpret_cast<const Bounds2i *>(src2)->lt.x);
        reinterpret_cast<Bounds2i *>(dst)->lt.y = std::min(reinterpret_cast<const Bounds2i *>(src1)->lt.y, reinterpret_cast<const Bounds2i *>(src2)->lt.y);
        reinterpret_cast<Bounds2i *>(dst)->rb.x = std::max(reinterpret_cast<const Bounds2i *>(src1)->rb.x, reinterpret_cast<const Bounds2i *>(src2)->rb.x);
        reinterpret_cast<Bounds2i *>(dst)->rb.y = std::max(reinterpret_cast<const Bounds2i *>(src1)->rb.y, reinterpret_cast<const Bounds2i *>(src2)->rb.y);
    }
}

inline void Bounds2i_MakeIntersection(const void *src1, const void *src2, void *dst) {
    if (Bounds2i_IsEmpty(src1) || Bounds2i_IsEmpty(src2) || !Bounds2i_Intersects(src1, src2)) {
        Bounds2i_Reset(dst);
    } else {
        reinterpret_cast<Bounds2i *>(dst)->lt.x = std::max(reinterpret_cast<const Bounds2i *>(src1)->lt.x, reinterpret_cast<const Bounds2i *>(src2)->lt.x);
        reinterpret_cast<Bounds2i *>(dst)->lt.y = std::max(reinterpret_cast<const Bounds2i *>(src1)->lt.y, reinterpret_cast<const Bounds2i *>(src2)->lt.y);
        reinterpret_cast<Bounds2i *>(dst)->rb.x = std::min(reinterpret_cast<const Bounds2i *>(src1)->rb.x, reinterpret_cast<const Bounds2i *>(src2)->rb.x);
        reinterpret_cast<Bounds2i *>(dst)->rb.y = std::min(reinterpret_cast<const Bounds2i *>(src1)->rb.y, reinterpret_cast<const Bounds2i *>(src2)->rb.y);
    }
}

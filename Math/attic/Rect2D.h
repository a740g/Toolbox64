#pragma once

#include "Point2D.h"
#include "Size2D.h"
#include <algorithm>

// 2D Rect class
class Rect2D {
  public:
    friend class Point2D;
    friend class Size2D;

    // Rectangle
    Point2D a; // top
    Point2D b; // bottom

    Rect2D(int ax = 0, int ay = 0, int bx = 0, int by = 0);
    Rect2D(const Point2D &p1, const Point2D &p2);
    Rect2D(const Point2D &p, const Size2D &s);

    void initialize(int ax = 0, int ay = 0, int bx = 0, int by = 0);
    void initialize(const Point2D &p1, const Point2D &p2);
    void initialize(const Point2D &p, const Size2D &s);
    void finalize();
    bool isValid();
    void normalize();
    bool isEmpty(); // if size is 0,0
    Point2D getLeftTop();
    Point2D getRightBottom();
    void setLeftTop(const Point2D &p);
    void setRightBottom(const Point2D &p);
    Size2D getSize();
    void inflate(int x, int y);
    void inflate(const Size2D &s);
    int getDiagonalLength();
    int getArea();
    int getPerimeter();
    bool overlaps(const Rect2D &r);
    void move(int x, int y);
    void move(const Point2D &p);
    void makeIntersection(const Rect2D &r);
    void makeUnion(const Rect2D &r);
    bool intersects(const Rect2D &r);
    bool contains(int p, int y);
    bool contains(const Point2D &p);
    bool contains(const Rect2D &r);

    bool operator==(const Rect2D &r);
    bool operator!=(const Rect2D &r);
};

Rect2D::Rect2D(int ax, int ay, int bx, int by) {
    initialize(ax, ay, bx, by);
}

Rect2D::Rect2D(const Point2D &p1, const Point2D &p2) {
    initialize(p1, p2);
}

Rect2D::Rect2D(const Point2D &p, const Size2D &s) {
    initialize(p, s);
}

void Rect2D::initialize(int ax, int ay, int bx, int by) {
    a.x = ax;
    a.y = ay;
    b.x = bx;
    b.y = by;
}

void Rect2D::initialize(const Point2D &p1, const Point2D &p2) {
    a.x = p1.x;
    a.y = p1.y;
    b.x = p2.x;
    b.y = p2.y;
}

void Rect2D::initialize(const Point2D &p, const Size2D &s) {
    a.x = p.x;
    a.y = p.y;
    b.x = p.x + s.w - 1;
    b.y = p.y + s.h - 1;
}

void Rect2D::finalize() {
    a.x = 0;
    a.y = 0;
    b.x = 0;
    b.y = 0;
}

bool Rect2D::isValid() {
    return (b.x >= a.x && b.y >= a.y);
}

void Rect2D::normalize() {
    int i;

    if (b.x < a.x) {
        i = b.x;
        b.x = a.x;
        a.x = i;
    }

    if (b.y < a.y) {
        i = b.y;
        b.y = a.y;
        a.y = i;
    }
}

bool Rect2D::isEmpty() {
    return ((a.x >= b.x) || (a.y >= b.y));
}

Point2D Rect2D::getLeftTop() {
    return Point2D(a.x, a.y);
}

Point2D Rect2D::getRightBottom() {
    return Point2D(b.x, b.y);
}

void Rect2D::setLeftTop(const Point2D &p) {
    a.x = p.x;
    a.y = p.y;
}

void Rect2D::setRightBottom(const Point2D &p) {
    b.x = p.x;
    b.y = p.y;
}

Size2D Rect2D::getSize() {
    return Size2D(1 + b.x - a.x, 1 + b.y - a.y);
}

void Rect2D::inflate(int x, int y) {
    a.x -= x;
    b.x += x;
    a.y -= y;
    b.y += y;
}

void Rect2D::inflate(const Size2D &s) {
    a.x -= s.w;
    b.x += s.w;
    a.y -= s.h;
    b.y += s.h;
}

int Rect2D::getDiagonalLength() {
    return getSize().getDiagonalLength();
}

int Rect2D::getArea() {
    return getSize().getArea();
}

int Rect2D::getPerimeter() {
    return getSize().getPerimeter();
}

bool Rect2D::overlaps(const Rect2D &r) {
    return (!(a.x > r.b.x || r.a.x > b.x || a.y > r.b.y || r.a.y > b.y));
}

void Rect2D::move(int x, int y) {
    a.x += x;
    b.x += x;
    a.y += y;
    b.y += y;
}

void Rect2D::move(const Point2D &p) {
    a.x += p.x;
    b.x += p.x;
    a.y += p.y;
    b.y += p.y;
}

void Rect2D::makeIntersection(const Rect2D &r) {
    a.x = std::max(a.x, r.a.x);
    a.y = std::max(a.y, r.a.y);
    b.x = std::min(b.x, r.b.x);
    b.y = std::min(b.y, r.b.y);
}

void Rect2D::makeUnion(const Rect2D &r) {
    a.x = std::min(a.x, r.a.x);
    a.y = std::min(a.y, r.a.y);
    b.x = std::max(b.x, r.b.x);
    b.y = std::max(b.y, r.b.y);
}

bool Rect2D::intersects(const Rect2D &r) {
    return (a.x < r.b.x && b.x > r.a.x && a.y < r.b.y && b.y > r.a.y);
}

bool Rect2D::contains(int x, int y) {
    return (x >= a.x && x < b.x && y >= a.y && y < b.y);
}

bool Rect2D::contains(const Point2D &p) {
    return (p.x >= a.x && p.x < b.x && p.y >= a.y && p.y < b.y);
}

bool Rect2D::contains(const Rect2D &r) {
    return (r.a.x >= a.x && r.a.y >= a.y && r.b.x <= b.x && r.b.y <= b.y);
}

bool Rect2D::operator==(const Rect2D &r) {
    return (a == r.a && b == r.b);
}

bool Rect2D::operator!=(const Rect2D &r) {
    return !(*this == r);
}

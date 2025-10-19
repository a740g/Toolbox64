///////////////////////////////////////////////////////////////////////
//     _    _ _                 _    _ _
//    / \  | (_) ___ _ __      / \  | | | ___ _   _
//   / _ \ | | |/ _ \ '_ \    / _ \ | | |/ _ \ | | |
//  / ___ \| | |  __/ | | |  / ___ \| | |  __/ |_| |
// /_/   \_\_|_|\___|_| |_| /_/   \_\_|_|\___|\__, |
//                                            |___/
//
//  This implements 2D geometry / shape classes
//  We use implementation ideas from ReactOS rect.c & ATL
//
//  Sourceport / mod copyright � Samuel Gomes
//
///////////////////////////////////////////////////////////////////////

#pragma once

#include "Geometry2D.h"

Vector2D::Vector2D() {
    x = y = 0;
}

Vector2D::Vector2D(int nX, int nY) {
    x = nX;
    y = nY;
}

void Vector2D::initialize(int nX, int nY) {
    x = nX;
    y = nY;
}

void Vector2D::reset() {
    x = y = 0;
}

bool Vector2D::isValid() const {
    return x >= 0 && y >= 0;
}

bool Vector2D::isNull() const {
    return x <= 0 && y <= 0;
}

int Vector2D::getDiagonalLength() const {
    return (int)sqrt(x * x + y * y);
}

int Vector2D::getArea() const {
    return x * y;
}

int Vector2D::getPerimeter() const {
    return 2 * (x + y);
}

void Vector2D::add(int nI) {
    x += nI;
    y += nI;
}

void Vector2D::subtract(int nI) {
    x -= nI;
    y -= nI;
}

void Vector2D::add(int nX, int nY) {
    x += nX;
    y += nY;
}

void Vector2D::subtract(int nX, int nY) {
    x -= nX;
    y -= nY;
}

void Vector2D::add(const Vector2D &v) {
    x += v.x;
    y += v.y;
}

void Vector2D::subtract(const Vector2D &v) {
    x -= v.x;
    y -= v.y;
}

Vector2D Vector2D::getDistanceVector2D(const Vector2D &v) const {
    return Vector2D(1 + abs(v.x - x), 1 + abs(v.y - y));
}

int Vector2D::getDistance(const Vector2D &v) const {
    int w = 1 + abs(v.x - x);
    int h = 1 + abs(v.y - y);

    return (int)sqrt(w * w + h * h);
}

void Vector2D::operator+=(const Vector2D &v) {
    x += v.x;
    y += v.y;
}

void Vector2D::operator-=(const Vector2D &v) {
    x -= v.x;
    y -= v.y;
}

bool Vector2D::operator==(const Vector2D &v) const {
    return x == v.x && y == v.y;
}

bool Vector2D::operator!=(const Vector2D &v) const {
    return x != v.x || y != v.y;
}

Rectangle::Rectangle() {
    // lt.x = lt.y = rb.x = rb.y = 0;
}

Rectangle::Rectangle(int l, int t, int r, int b) {
    lt.x = l;
    lt.y = t;
    rb.x = r;
    rb.y = b;
}

Rectangle::Rectangle(const Vector2D &leftTop, const Vector2D &rightBottom) {
    lt = leftTop;
    rb = rightBottom;
}

void Rectangle::initialize(int l, int t, int r, int b) {
    lt.x = l;
    lt.y = t;
    rb.x = r;
    rb.y = b;
}

void Rectangle::initialize(const Vector2D &leftTop, const Vector2D &rightBottom) {
    lt = leftTop;
    rb = rightBottom;
}

void Rectangle::reset() {
    lt.x = lt.y = rb.x = rb.y = 0;
}

bool Rectangle::isValid() const {
    return rb.x >= lt.x && rb.y >= lt.y;
}

void Rectangle::normalize() {
    if (rb.x < lt.x)
        std::swap(rb.x, lt.x);
    if (rb.y < lt.y)
        std::swap(rb.y, lt.y);
}

bool Rectangle::isEmpty() const {
    return lt.x >= rb.x || lt.y >= rb.y;
}

bool Rectangle::isNull() const {
    return (lt.x == 0 && rb.x == 0 && lt.y == 0 && rb.y == 0);
}

bool Rectangle::noWidth() const {
    return (lt.x >= rb.x);
}

bool Rectangle::noHeight() const {
    return (lt.y >= rb.y);
}

Vector2D Rectangle::getLeftTop() const {
    return Vector2D(lt.x, lt.y);
}

Vector2D Rectangle::getRightBottom() const {
    return Vector2D(rb.x, rb.y);
}

void Rectangle::setLeftTop(const Vector2D &p) {
    lt = p;
}

void Rectangle::setRightBottom(const Vector2D &p) {
    rb = p;
}

int Rectangle::getWidth() const {
    return 1 + rb.x - lt.x;
}

int Rectangle::getHeight() const {
    return 1 + rb.y - lt.y;
}

void Rectangle::setWidth(int w) {
    rb.x = lt.x + w - 1;
}

void Rectangle::setHeight(int h) {
    rb.y = lt.y + h - 1;
}

Vector2D Rectangle::getSize() const {
    return Vector2D(1 + rb.x - lt.x, 1 + rb.y - lt.y);
}

void Rectangle::setSize(const Vector2D &s) {
    rb.x = lt.x + s.x - 1;
    rb.y = lt.y + s.y - 1;
}

Vector2D Rectangle::getCenterPoint() const {
    return Vector2D(lt.x + ((1 + rb.x - lt.x) / 2), lt.y + ((1 + rb.y - lt.y) / 2));
}

void Rectangle::inflate(int l, int t, int r, int b) {
    lt.x -= l;
    lt.y -= t;
    rb.x += r;
    rb.y += b;
}

void Rectangle::inflate(int dx, int dy) {
    lt.x -= dx;
    lt.y -= dy;
    rb.x += dx;
    rb.y += dy;
}

void Rectangle::inflate(const Vector2D &s) {
    lt.x -= s.x;
    lt.y -= s.y;
    rb.x += s.x;
    rb.y += s.y;
}

void Rectangle::inflate(const Rectangle &r) {
    lt.x -= r.lt.x;
    lt.y -= r.lt.y;
    rb.x += r.rb.x;
    rb.y += r.rb.y;
}

void Rectangle::deflate(int l, int t, int r, int b) {
    lt.x += l;
    lt.y += t;
    rb.x -= r;
    rb.y -= b;
}

void Rectangle::deflate(int dx, int dy) {
    lt.x += dx;
    lt.y += dy;
    rb.x -= dx;
    rb.y -= dy;
}

void Rectangle::deflate(const Vector2D &s) {
    lt.x += s.x;
    lt.y += s.y;
    rb.x -= s.x;
    rb.y -= s.y;
}

void Rectangle::deflate(const Rectangle &r) {
    lt.x += r.lt.x;
    lt.y += r.lt.y;
    rb.x -= r.rb.x;
    rb.y -= r.rb.y;
}

int Rectangle::getDiagonalLength() const {
    int w = 1 + rb.x - lt.x;
    int h = 1 + rb.y - lt.y;

    return (int)sqrt(w * w + h * h);
}

int Rectangle::getArea() const {
    return (1 + rb.x - lt.x) * (1 + rb.y - lt.y);
}

int Rectangle::getPerimeter() const {
    return 2 * ((1 + rb.x - lt.x) + (1 + rb.y - lt.y));
}

bool Rectangle::intersects(const Rectangle &r) const {
    return !(lt.x > r.rb.x || r.lt.x > rb.x || lt.y > r.rb.y || r.lt.y > rb.y);
}

bool Rectangle::contains(int x, int y) const {
    return (x >= lt.x && x <= rb.x && y >= lt.y && y <= rb.y);
}

bool Rectangle::contains(const Vector2D &pt) const {
    return (pt.x >= lt.x && pt.x <= rb.x && pt.y >= lt.y && pt.y <= rb.y);
}

bool Rectangle::contains(const Rectangle &r) const {
    return (r.lt.x >= lt.x && r.lt.y >= lt.y && r.rb.x <= rb.x && r.rb.y <= rb.y);
}

void Rectangle::offset(int dx, int dy) {
    lt.x += dx;
    lt.y += dy;
    rb.x += dx;
    rb.y += dy;
}

void Rectangle::offset(const Vector2D &p) {
    lt.x += p.x;
    lt.y += p.y;
    rb.x += p.x;
    rb.y += p.y;
}

void Rectangle::moveToX(int x) {
    int w = rb.x - lt.x; // we need the width *before* we change anything!
    lt.x = x;
    rb.x = lt.x + w;
}

void Rectangle::moveToY(int y) {
    int h = rb.y - lt.y; // we need the height *before* we change anything!
    lt.y = y;
    rb.y = lt.y + h;
}

void Rectangle::moveToXY(int x, int y) {
    int w = rb.x - lt.x; // we need the width *before* we change anything!
    int h = rb.y - lt.y; // we need the height *before* we change anything!
    lt.x = x;
    rb.x = lt.x + w;
    lt.y = y;
    rb.y = lt.y + h;
}

void Rectangle::moveToPoint(const Vector2D &p) {
    int w = rb.x - lt.x; // we need the width *before* we change anything!
    int h = rb.y - lt.y; // we need the height *before* we change anything!
    lt.x = p.x;
    rb.x = lt.x + w;
    lt.y = p.y;
    rb.y = lt.y + h;
}

void Rectangle::makeIntersection(const Rectangle &r) {
    if (isEmpty() || r.isEmpty() || lt.x >= r.rb.x || r.lt.x >= rb.x || lt.y >= r.rb.y || r.lt.y >= rb.y) {
        // Set empty rectangle
        reset();
    }

    lt.x = std::max(lt.x, r.lt.x);
    rb.x = std::min(rb.x, r.rb.x);
    lt.y = std::max(lt.y, r.lt.y);
    rb.y = std::min(rb.y, r.rb.y);
}

void Rectangle::makeIntersection(const Rectangle &r1, const Rectangle &r2) {
    if (r1.isEmpty() || r2.isEmpty() || r1.lt.x >= r2.rb.x || r2.lt.x >= r1.rb.x || r1.lt.y >= r2.rb.y || r2.lt.y >= r1.rb.y) {
        // Set empty rectangle
        reset();
    }

    lt.x = std::max(r1.lt.x, r2.lt.x);
    rb.x = std::min(r1.rb.x, r2.rb.x);
    lt.y = std::max(r1.lt.y, r2.lt.y);
    rb.y = std::min(r1.rb.y, r2.rb.y);
}

void Rectangle::makeUnion(const Rectangle &r) {
    if (isEmpty()) {
        if (r.isEmpty()) {
            reset();
        } else {
            *this = r;
        }
    } else {
        if (!r.isEmpty()) {
            lt.x = std::min(lt.x, r.lt.x);
            lt.y = std::min(lt.y, r.lt.y);
            rb.x = std::max(rb.x, r.rb.x);
            rb.y = std::max(rb.y, r.rb.y);
        }
    }
}

void Rectangle::makeUnion(const Rectangle &r1, const Rectangle &r2) {
    if (r1.isEmpty()) {
        if (r2.isEmpty()) {
            reset();
        } else {
            *this = r2;
        }
    } else {
        if (r2.isEmpty()) {
            *this = r1;
        } else {
            lt.x = std::min(r1.lt.x, r2.lt.x);
            lt.y = std::min(r1.lt.y, r2.lt.y);
            rb.x = std::max(r1.rb.x, r2.rb.x);
            rb.y = std::max(r1.rb.y, r2.rb.y);
        }
    }
}

bool Rectangle::operator==(const Rectangle &r) const {
    return (lt.x == r.lt.x && lt.y == r.lt.y && rb.x == r.rb.x && rb.y == r.rb.y);
}

bool Rectangle::operator!=(const Rectangle &r) const {
    return (lt.x != r.lt.x || lt.y != r.lt.y || rb.x != r.rb.x || rb.y == r.rb.y);
}

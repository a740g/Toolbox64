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

#include <cmath>

// Vector 2D class
class Vector2D {
  public:
    int x;
    int y;

    Vector2D();                                            // Constructor
    Vector2D(int nX, int nY);                              // Constructor
    void initialize(int nX, int nY);                       // Initializes the vector with X & Y
    void reset();                                          // Resets the vector to zero
    bool isValid() const;                                  // Returns true if both x & y >= zero
    bool isNull() const;                                   // Returns true if both x & y <= 0
    int getDiagonalLength() const;                         // What is the diagonal length?
    int getArea() const;                                   // What is the area?
    int getPerimeter() const;                              // What is the perimeter?
    void add(int nI);                                      // Adds i to both x & y
    void subtract(int nI);                                 // Subtracts i from both x & y
    void add(int nX, int nY);                              // Adds X & Y to vector
    void subtract(int nX, int nY);                         // Subtracts nX & nY from vector
    void add(const Vector2D &v);                           // Adds with given vector
    void subtract(const Vector2D &v);                      // Subtracts with given vector
    Vector2D getDistanceVector2D(const Vector2D &v) const; // Returns a vector with distance (x, y) from another vector
    int getDistance(const Vector2D &v) const;              // Gets distance from another vector
    void operator+=(const Vector2D &v);                    // Addition assignment operator
    void operator-=(const Vector2D &v);                    // Subtraction assignment operator
    bool operator==(const Vector2D &v) const;              // Are the two vectors equal?
    bool operator!=(const Vector2D &v) const;              // Are the two vector not equal?
};

// Rectangle class
class Rectangle {
  public:
    Vector2D lt; // Left-top
    Vector2D rb; // Right-bottom

    Rectangle();                                                           // Constructor
    Rectangle(int l, int t, int r, int b);                                 // Constructor
    Rectangle(const Vector2D &leftTop, const Vector2D &rightBottom);       // Constructor
    void initialize(int l, int t, int r, int b);                           // Initialize with left, top, right & bottom
    void initialize(const Vector2D &leftTop, const Vector2D &rightBottom); // Initialize with left-top & right-bottom
    void reset();                                                          // Reset the rectangle to nothing
    bool isValid() const;                                                  // Is right-bottom >= left-top?
    void normalize();                                                      // Normalize the reactangle
    bool isEmpty() const;                                                  // Is rectangle empty (i.e. has no space)
    bool isNull() const;                                                   // Is rectangle nothing?
    bool noWidth() const;                                                  // True if rectange has no width
    bool noHeight() const;                                                 // True if rectange has no height
    Vector2D getLeftTop() const;                                           // Get the top-left point
    Vector2D getRightBottom() const;                                       // Get the bottom-right point
    void setLeftTop(const Vector2D &p);                                    // Set top-left point
    void setRightBottom(const Vector2D &p);                                // Set bottom-right point
    int getWidth() const;                                                  // Get rect width
    int getHeight() const;                                                 // Get rect height
    void setWidth(int w);                                                  // Set the width keeping left-top anchored
    void setHeight(int h);                                                 // Set the height keeping the left-top anchored
    Vector2D getSize() const;                                              // Gets the size of the rectangle
    void setSize(const Vector2D &s);                                       // Sets the size of the rectangle keeping the top-left anchored
    Vector2D getCenterPoint() const;                                       // Gets the mid-point of the rectangle
    void inflate(int l, int t, int r, int b);                              // Inflates the rectangle using left, top, right & bottom
    void inflate(int dx, int dy);                                          // Inflates the rectangle using dx & dy
    void inflate(const Vector2D &s);                                       // Inflates the rectangle using the given size
    void inflate(const Rectangle &r);                                      // Inflate the rectangle usign another rectangle
    void deflate(int l, int t, int r, int b);                              // Deflates the rectangle using left, top, right & bottom
    void deflate(int dx, int dy);                                          // Inflates the rectangle using dx & dy
    void deflate(const Vector2D &s);                                       // Inflates the rectangle using the given size
    void deflate(const Rectangle &r);                                      // Inflate the rectangle usign another rectangle
    int getDiagonalLength() const;                                         // What is diagonal length of the rectangle
    int getArea() const;                                                   // Get the area of the rectangle
    int getPerimeter() const;                                              // Get the perimeter of the rectangle
    bool intersects(const Rectangle &r) const;                             // Does this rectangle overlap with r?
    bool contains(int x, int y) const;                                     // Does the rectangle containg both x & y?
    bool contains(const Vector2D &pt) const;                               // Does this contain point pt?
    bool contains(const Rectangle &r) const;                               // Does this rectangle completely contain rectangle r?
    void offset(int dx, int dy);                                           // Offset the rectangle using dx & dy
    void offset(const Vector2D &p);                                        // Offset the rectangle using a point
    void moveToX(int x);                                                   // Moves the rectange to absolute X
    void moveToY(int y);                                                   // Moves the rectange to absolute Y
    void moveToXY(int x, int y);                                           // Moves the rectangle to absolute x & y position
    void moveToPoint(const Vector2D &p);                                   // Moves the rectangle to absolute point
    void makeIntersection(const Rectangle &r); // Make this an intersection of itself and another rectangle. Empty rectangle if no intersection
    void makeIntersection(const Rectangle &r1, const Rectangle &r2); // Make this an intersection of two rectangles. Empty rectangle if no intersection
    void makeUnion(const Rectangle &r);                              // Make this a union of itself and another rectangle
    void makeUnion(const Rectangle &r1, const Rectangle &r2);        // Make this a union of two rectangles
    bool operator==(const Rectangle &r) const;                       // Is this equal to another rectangle?
    bool operator!=(const Rectangle &r) const;                       // Is this not equal to another rectangle?
};

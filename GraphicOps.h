//----------------------------------------------------------------------------------------------------------------------
// Extended graphics routines
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#define TOOLBOX64_DEBUG 0
#include "Debug.h"
#include "Common.h"
#include <cmath>
#include <cstring>
#include <algorithm>

#ifndef INC_COMMON_CPP
// This stuff is from QB64-PE common.h and is only here for debugging purposes
struct img_struct
{
    void *lock_offset;
    int64_t lock_id;
    uint8_t valid;   // 0,1 0=invalid
    uint8_t text;    // if set, surface is a text surface
    uint8_t console; // dummy surface to absorb unimplemented console functionality
    uint16_t width, height;
    uint8_t bytes_per_pixel;  // 1,2,4
    uint8_t bits_per_pixel;   // 1,2,4,8,16(text),32
    uint32_t mask;            // 1,3,0xF,0xFF,0xFFFF,0xFFFFFFFF
    uint16_t compatible_mode; // 0,1,2,7,8,9,10,11,12,13,32,256
    uint32_t color, background_color, draw_color;
    uint32_t font;               // 8,14,16,?
    int16_t top_row, bottom_row; // VIEW PRINT settings, unique (as in QB) to each "page"
    int16_t cursor_x, cursor_y;  // unique (as in QB) to each "page"
    uint8_t cursor_show, cursor_firstvalue, cursor_lastvalue;
    union
    {
        uint8_t *offset;
        uint32_t *offset32;
    };
    uint32_t flags;
    uint32_t *pal;
    int32_t transparent_color; //-1 means no color is transparent
    uint8_t alpha_disabled;
    uint8_t holding_cursor;
    uint8_t print_mode;
    // BEGIN apm ('active page migration')
    // everything between apm points is migrated during active page changes
    // note: apm data is only relevent to graphics modes
    uint8_t apm_p1;
    int32_t view_x1, view_y1, view_x2, view_y2;
    int32_t view_offset_x, view_offset_y;
    float x, y;
    uint8_t clipping_or_scaling;
    float scaling_x, scaling_y, scaling_offset_x, scaling_offset_y;
    float window_x1, window_y1, window_x2, window_y2;
    double draw_ta;
    double draw_scale;
    uint8_t apm_p2;
    // END apm
};
#else
struct img_struct;
#endif

// These are QB64-PE internal structures
extern img_struct *write_page;

// These are QB64-PE internal functions
extern void pset_and_clip(int32_t x, int32_t y, uint32_t color);
extern void fast_boxfill(int32_t x1, int32_t y1, int32_t x2, int32_t y2, uint32_t color);

/// @brief This is a function pointer type that we'll use to plot "pixels" on graphics as well and "text" surfaces
typedef void (*Graphics_SetPixelFunction)(int32_t x, int32_t y, uint32_t clrAtr);

/// @brief We'll use this internally so that we do not have the overhead of calling __Graphics_SetSetPixelFunction() for every pixel
static Graphics_SetPixelFunction __Graphics_SetPixelInternal = nullptr;

/// @brief This is used to plot a text "pixel" on a "text" surface. The pixel is clipped if it is outside bounds
/// @param x The x position
/// @param y The y position
/// @param clrAtr A combination of the ASCII character and the text color attributes
inline static void __Graphics_SetTextPixelClipped(int32_t x, int32_t y, uint32_t clrAtr)
{
    if (x >= 0 and x < write_page->width and y >= 0 and y < write_page->height)
    {
        *(reinterpret_cast<uint16_t *>(write_page->offset) + write_page->width * y + x) = (uint16_t)clrAtr;
    }
}

/// @brief This selects the correct "SetPixel" function for later rendering
inline static void __Graphics_SelectSetPixelFunction()
{
    __Graphics_SetPixelInternal = write_page->text ? __Graphics_SetTextPixelClipped : pset_and_clip;
}

/// @brief Public library function for plotting pixels on text and graphic surfaces. This will clip out-of-bounds pixels
/// @param x The x position
/// @param y The y position
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
inline void Graphics_SetPixel(int32_t x, int32_t y, uint32_t clrAtr)
{
    __Graphics_SelectSetPixelFunction();
    __Graphics_SetPixelInternal(x, y, clrAtr);
}

/// @brief Makes a character + text atttribute pair for text mode images
/// @param character An ASCII character
/// @param fColor The foreground color (0 - 15)
/// @param bColor The background color (0 - 15)
/// @return A 16-bit text + color attribute pair
inline constexpr uint16_t Graphics_MakeTextColorAttribute(uint8_t character, uint8_t fColor, uint8_t bColor)
{
    return (uint16_t)character | ((((bColor > 7) << 7) | (bColor << 4) | (fColor & 0x0F)) << 8);
}

/// @brief Makes a character + text atttribute pair for text mode images using the _DEFAULTCOLOR and _BACKGROUNDCOLOR
/// @param character An ASCII character
/// @return A 16-bit text + color attribute pair
inline uint16_t Graphics_MakeDefaultTextColorAttribute(uint8_t character)
{
    return (uint16_t)character | ((((write_page->color > 15) << 7) | ((write_page->background_color & 0xFF) << 4) | (write_page->color & 0x0F)) << 8);
}

/// @brief Sets the foreground color for the current destination image
/// @param fColor The foreground color (0 - 15 for text mode)
inline void Graphics_SetForegroundColor(uint32_t fColor)
{
    write_page->color = write_page->text ? fColor & 0x0F : fColor;
}

/// @brief Gets the foreground color for the current destination image
/// @return The foreground color (0 - 15 for text mode)
inline uint32_t Graphics_GetForegroundColor()
{
    return write_page->text ? write_page->color & 0x0F : write_page->color;
}

/// @brief Sets the background color for the current destination image
/// @param bColor The background color (0 - 15 for text mode)
inline void Graphics_SetBackgroundColor(uint32_t bColor)
{
    if (write_page->text)
    {
        write_page->background_color = bColor & 0x07;
        write_page->color = write_page->color | ((bColor > 7) << 4);
    }
    else
    {
        write_page->background_color = bColor;
    }
}

/// @brief Gets the background color for the current destination image
/// @return The background color (0 - 15 for text mode)
inline uint32_t Graphics_GetBackgroundColor()
{
    return write_page->text ? (write_page->background_color & 0x07) | ((write_page->color > 15) << 3) : write_page->background_color;
}

/// @brief Draws a horizontal line (works in both text and graphics modes)
/// @param lx Left x position
/// @param ty Top y position
/// @param rx Right x position
/// @param c A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawHorizontalLine(int32_t lx, int32_t ty, int32_t rx, uint32_t clrAtr)
{
    // Ensure the starting and ending coordinates are ordered correctly
    if (lx > rx)
        std::swap(lx, rx);

    // Ensure ty is within the image height
    if (ty < 0 || ty >= write_page->height || lx >= write_page->width || rx < 0)
        return; // Line is completely outside the image

    // Clip the line to the image boundaries
    if (lx < 0)
        lx = 0;
    if (rx >= write_page->width)
        rx = write_page->width - 1;

    TOOLBOX64_DEBUG_PRINT("Drawing line segment: (%i, %i) - (%i, %i)", lx, ty, rx, ty);

    if (write_page->text)
    {
        // Get pointer to the starting "pixel"
        auto buffer = (reinterpret_cast<uint16_t *>(write_page->offset) + write_page->width * ty + lx);

        // Draw the complete line
        std::fill(buffer, buffer + (1 + rx - lx), clrAtr);
    }
    else
    {
        // Use a different method for non-text mode
        fast_boxfill(lx, ty, rx, ty, clrAtr);
    }
}

/// @brief Draws a vertical line (works in both text and graphics modes)
/// @param lx Left x position
/// @param ty Top y position
/// @param by Bottom y position
/// @param c A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawVerticalLine(int32_t lx, int32_t ty, int32_t by, uint32_t clrAtr)
{
    // Ensure the starting and ending coordinates are ordered correctly
    if (ty > by)
        std::swap(ty, by);

    // Ensure lx is within the image width
    if (lx < 0 || lx >= write_page->width || ty >= write_page->height || by < 0)
        return; // Line is completely outside the image

    // Clip the line to the image boundaries
    if (ty < 0)
        ty = 0;
    if (by >= write_page->height)
        by = write_page->height - 1;

    TOOLBOX64_DEBUG_PRINT("Drawing line segment: (%i, %i) - (%i, %i)", lx, ty, lx, by);

    if (write_page->text)
    {
        // Get pointer to the starting "pixel"
        auto buffer = (reinterpret_cast<uint16_t *>(write_page->offset) + write_page->width * ty + lx);

        // Draw the "pixels" and then step by image width to get to the next pixel
        for (auto y = ty; y <= by; y++)
        {
            *buffer = clrAtr;
            buffer += write_page->width;
        }
    }
    else
    {
        // Use a different method for non-text mode
        fast_boxfill(lx, ty, lx, by, clrAtr);
    }
}

/// @brief Draws a rectangle (works in both text and graphics modes)
/// @param lx Left x position
/// @param ty Top y position
/// @param rx Right x position
/// @param by Bottom y position
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawRectangle(int32_t lx, int32_t ty, int32_t rx, int32_t by, uint32_t clrAtr)
{
    auto xMin = std::min(lx, rx);
    auto xMax = std::max(lx, rx);

    // Draw the top and bottom sides
    Graphics_DrawHorizontalLine(xMin, ty, xMax, clrAtr);
    Graphics_DrawHorizontalLine(xMin, by, xMax, clrAtr);

    auto yMin = std::min(ty, by) + 1; // Avoid re-drawing corners
    auto yMax = std::max(ty, by) - 1; // Avoid re-drawing corners

    // Draw the left and right sides
    if (yMax >= yMin)
    {
        Graphics_DrawVerticalLine(xMin, yMin, yMax, clrAtr);
        Graphics_DrawVerticalLine(xMax, yMin, yMax, clrAtr);
    }
}

/// @brief Draws a filled rectangle (works in both text and graphics modes)
/// @param lx Left x position
/// @param ty Top y position
/// @param rx Right x position
/// @param by Bottom y position
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawFilledRectangle(int32_t lx, int32_t ty, int32_t rx, int32_t by, uint32_t clrAtr)
{
    // Ensure the starting and ending coordinates are ordered correctly
    if (lx > rx)
        std::swap(lx, rx);
    if (ty > by)
        std::swap(ty, by);

    // Leave if rectangle is completely outside the image
    if (lx >= write_page->width || ty >= write_page->height || rx < 0 || by < 0)
        return;

    // Clip rectangle to image
    if (lx < 0)
        lx = 0;
    if (rx >= write_page->width)
        rx = write_page->width - 1;
    if (ty < 0)
        ty = 0;
    if (by >= write_page->height)
        by = write_page->height - 1;

    TOOLBOX64_DEBUG_PRINT("Drawing filled rectangle: (%i, %i) - (%i, %i)", lx, ty, rx, ty);

    if (write_page->text)
    {
        // Get pointer to the starting "pixel"
        auto buffer = (reinterpret_cast<uint16_t *>(write_page->offset) + write_page->width * ty + lx);

        // Draw one complete line
        auto rectWidth = 1 + rx - lx;
        std::fill(buffer, buffer + rectWidth, clrAtr);

        // Copy the remaining lines
        rectWidth <<= 1;                        // Since we are dealing with 2 byte attributes
        auto dest = buffer + write_page->width; // Get the pointer to the next line
        for (auto y = ty; y < by; y++)          // "y < by" since we already rendered the first line using std::fill
        {
            memcpy(dest, buffer, rectWidth); // Copy the first line
            dest += write_page->width;       // Move to the next line
        }
    }
    else
    {
        // Use a different method for non-text mode
        fast_boxfill(lx, ty, rx, by, clrAtr);
    }
}

/// @brief Draws a line from x1, y1 to x2, y2 (works in both text and graphics modes)
/// @param x1 Starting position x
/// @param y1 Starting position y
/// @param x2 Ending position x
/// @param y2 Ending position y
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawLine(int32_t x1, int32_t y1, int32_t x2, int32_t y2, uint32_t clrAtr)
{
    // Check if both endpoints of the line are outside the image bounds
    if ((x1 < 0 && x2 < 0) || (x1 >= write_page->width && x2 >= write_page->width) || (y1 < 0 && y2 < 0) || (y1 >= write_page->height && y2 >= write_page->height))
        return; // Line is completely outside the image

    __Graphics_SelectSetPixelFunction();

    int32_t deltaX = abs(x2 - x1);
    int32_t deltaY = -abs(y2 - y1);
    int32_t sx = x1 < x2 ? 1 : -1;
    int32_t sy = y1 < y2 ? 1 : -1;
    int32_t err = deltaX + deltaY; // Error value

    while (x1 != x2 || y1 != y2)
    {
        __Graphics_SetPixelInternal(x1, y1, clrAtr);

        int32_t err2 = err << 1;

        if (err2 >= deltaY)
        {
            err += deltaY;
            x1 += sx;
        }

        if (err2 <= deltaX)
        {
            err += deltaX;
            y1 += sy;
        }
    }

    // Plot the ending pixel
    __Graphics_SetPixelInternal(x2, y2, clrAtr);
}

/// @brief Draws a circle (works in both text and graphics modes)
/// @param x The circles center x position
/// @param y The circles center y position
/// @param radius The radius of the circle
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawCircle(int32_t x, int32_t y, int32_t radius, uint32_t clrAtr)
{
    // Clip the circle completely if bounding box is completely off-image
    if (x + radius < 0 || x - radius >= write_page->width || y + radius < 0 || y - radius >= write_page->height)
        return;

    __Graphics_SelectSetPixelFunction();

    // Special case: draw a single pixel if the radius is <= zero
    if (radius <= 0)
    {
        __Graphics_SetPixelInternal(x, y, clrAtr);
        return;
    }

    int32_t p = 1 - radius, cx = 0, cy = radius, px, py;

    do
    {
        // Calculate the eight symmetric points and set the pixels
        px = x + cx;
        py = y + cy;
        __Graphics_SetPixelInternal(px, py, clrAtr);
        px = x - cx;
        __Graphics_SetPixelInternal(px, py, clrAtr);
        px = x + cx;
        py = y - cy;
        __Graphics_SetPixelInternal(px, py, clrAtr);
        px = x - cx;
        __Graphics_SetPixelInternal(px, py, clrAtr);
        px = x + cy;
        py = y + cx;
        __Graphics_SetPixelInternal(px, py, clrAtr);
        py = y - cx;
        __Graphics_SetPixelInternal(px, py, clrAtr);
        px = x - cy;
        py = y + cx;
        __Graphics_SetPixelInternal(px, py, clrAtr);
        py = y - cx;
        __Graphics_SetPixelInternal(px, py, clrAtr);

        ++cx;

        if (p < 0)
        {
            p += ((cx << 1) + 1);
        }
        else
        {
            cy--;
            p += (((cx - cy) << 1) + 1);
        }
    } while (cx <= cy);
}

/// @brief Draws a filled circle (works in both text and graphics modes)
/// @param x The circles center x position
/// @param y The circles center y position
/// @param radius The radius of the circle
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawFilledCircle(int32_t x, int32_t y, int32_t radius, uint32_t clrAtr)
{
    // Clip the circle completely if bounding box is completely off-image
    if (x + radius < 0 || x - radius >= write_page->width || y + radius < 0 || y - radius >= write_page->height)
        return;

    // Special case: draw a single pixel if the radius is < zero
    if (radius <= 0)
    {
        Graphics_SetPixel(x, y, clrAtr);
        return;
    }

    int32_t cx = 0;
    int32_t cy = radius;
    int32_t df = 1 - radius;
    int32_t d_e = 3;
    int32_t d_se = -2 * radius + 5;

    do
    {
        Graphics_DrawHorizontalLine(x - cy, y - cx, x + cy, clrAtr);
        Graphics_DrawHorizontalLine(x - cy, y + cx, x + cy, clrAtr);

        if (df < 0)
        {
            df += d_e;
            d_e += 2;
            d_se += 2;
        }
        else
        {
            Graphics_DrawHorizontalLine(x - cx, y - cy, x + cx, clrAtr);
            Graphics_DrawHorizontalLine(x - cx, y + cy, x + cx, clrAtr);

            df += d_se;
            d_e += 2;
            d_se += 4;
            --cy;
        }

        ++cx;
    } while (cx <= cy);
}

/// @brief Draws an ellipse (works in both text and graphics modes)
/// @param x The circles center x position
/// @param y The circles center y position
/// @param rx The horizontal radius
/// @param ry The vertical radius
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawEllipse(int32_t x, int32_t y, int32_t rx, int32_t ry, uint32_t clrAtr)
{
    // Calculate the bounding box
    auto left = x - rx;
    auto right = x + rx;
    auto top = y - ry;
    auto bottom = y + ry;

    // Clip the ellipse completely if bounding box is completely off-image
    if (right < 0 || left >= write_page->width || bottom < 0 || top >= write_page->height)
        return;

    __Graphics_SelectSetPixelFunction();

    // Special case: draw a single pixel if both rx and ry are <= zero
    if (rx <= 0 && ry <= 0)
    {
        __Graphics_SetPixelInternal(x, y, clrAtr);
        return;
    }

    // Special case for rx = 0: draw a vline
    if (rx == 0)
    {
        Graphics_DrawVerticalLine(x, top, bottom, clrAtr);
        return;
    }

    // Special case for ry = 0: draw a hline
    if (ry == 0)
    {
        Graphics_DrawHorizontalLine(left, y, right, clrAtr);
        return;
    }

    int32_t ix, iy;
    int32_t h, i, j, k;
    h = i = j = k = 0xFFFF;

    if (rx > ry)
    {
        ix = 0;
        iy = rx << 6;

        do
        {
            int32_t oh = h;
            int32_t oi = i;
            int32_t oj = j;
            int32_t ok = k;

            h = (ix + 32) >> 6;
            i = (iy + 32) >> 6;
            j = (h * ry) / rx;
            k = (i * ry) / rx;

            if ((h != oh || k != ok) && (h < oi))
            {
                __Graphics_SetPixelInternal(x + h, y + k, clrAtr);
                __Graphics_SetPixelInternal(x - h, y + k, clrAtr);
                __Graphics_SetPixelInternal(x + h, y - k, clrAtr);
                __Graphics_SetPixelInternal(x - h, y - k, clrAtr);
            }

            if ((i != oi || j != oj) && (h < i))
            {
                __Graphics_SetPixelInternal(x + i, y + j, clrAtr);
                __Graphics_SetPixelInternal(x - i, y + j, clrAtr);
                __Graphics_SetPixelInternal(x + i, y - j, clrAtr);
                __Graphics_SetPixelInternal(x - i, y - j, clrAtr);
            }

            ix = ix + (iy / rx);
            iy = iy - (ix / rx);
        } while (i > h);
    }
    else
    {
        ix = 0;
        iy = ry << 6;

        do
        {
            int32_t oh = h;
            int32_t oi = i;
            int32_t oj = j;
            int32_t ok = k;

            h = (ix + 32) >> 6;
            i = (iy + 32) >> 6;
            j = (h * rx) / ry;
            k = (i * rx) / ry;

            if ((j != oj || i != oi) && (h < i))
            {
                __Graphics_SetPixelInternal(x + j, y + i, clrAtr);
                __Graphics_SetPixelInternal(x - j, y + i, clrAtr);
                __Graphics_SetPixelInternal(x + j, y - i, clrAtr);
                __Graphics_SetPixelInternal(x - j, y - i, clrAtr);
            }

            if ((k != ok || h != oh) && (h < oi))
            {
                __Graphics_SetPixelInternal(x + k, y + h, clrAtr);
                __Graphics_SetPixelInternal(x - k, y + h, clrAtr);
                __Graphics_SetPixelInternal(x + k, y - h, clrAtr);
                __Graphics_SetPixelInternal(x - k, y - h, clrAtr);
            }

            ix = ix + (iy / ry);
            iy = iy - (ix / ry);
        } while (i > h);
    }
}

/// @brief Draws a filled ellipse (works in both text and graphics modes)
/// @param x The circles center x position
/// @param y The circles center y position
/// @param rx The horizontal radius
/// @param ry The vertical radius
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawFilledEllipse(int32_t x, int32_t y, int32_t rx, int32_t ry, uint32_t clrAtr)
{
    // Calculate the bounding box
    auto left = x - rx;
    auto right = x + rx;
    auto top = y - ry;
    auto bottom = y + ry;

    // Clip the ellipse completely if bounding box is outside the image bounds
    if (right < 0 || left >= write_page->width || bottom < 0 || top >= write_page->height)
        return;

    // Special case if both rx and ry are <= zero: draw a single pixel
    if (rx <= 0 && ry <= 0)
    {
        Graphics_SetPixel(x, y, clrAtr);
        return;
    }

    // Special case for rx = 0: draw a vline
    if (rx == 0)
    {
        Graphics_DrawVerticalLine(x, top, bottom, clrAtr);
        return;
    }

    // Special case for ry = 0: draw a hline
    if (ry == 0)
    {
        Graphics_DrawHorizontalLine(left, y, right, clrAtr);
        return;
    }

    // Init vars
    int32_t x1, y1, x2, y2;
    int32_t ix, iy;
    int32_t h, i, j, k;
    int32_t xmh, xph;
    int32_t xmi, xpi;
    int32_t xmj, xpj;
    int32_t xmk, xpk;
    int32_t oh, oi, oj, ok;
    oh = oi = oj = ok = 0xFFFF;

    // Draw
    if (rx > ry)
    {
        ix = 0;
        iy = rx << 6;

        do
        {
            h = (ix + 32) >> 6;
            i = (iy + 32) >> 6;
            j = (h * ry) / rx;
            k = (i * ry) / rx;

            if ((ok != k) && (oj != k))
            {
                xph = x + h;
                xmh = x - h;
                if (k > 0)
                {
                    Graphics_DrawHorizontalLine(xmh, y + k, xph, clrAtr);
                    Graphics_DrawHorizontalLine(xmh, y - k, xph, clrAtr);
                }
                else
                {
                    Graphics_DrawHorizontalLine(xmh, y, xph, clrAtr);
                }
                ok = k;
            }
            if ((oj != j) && (ok != j) && (k != j))
            {
                xmi = x - i;
                xpi = x + i;
                if (j > 0)
                {
                    Graphics_DrawHorizontalLine(xmi, y + j, xpi, clrAtr);
                    Graphics_DrawHorizontalLine(xmi, y - j, xpi, clrAtr);
                }
                else
                {
                    Graphics_DrawHorizontalLine(xmi, y, xpi, clrAtr);
                }
                oj = j;
            }

            ix = ix + iy / rx;
            iy = iy - ix / rx;

        } while (i > h);
    }
    else
    {
        ix = 0;
        iy = ry << 6;

        do
        {
            h = (ix + 32) >> 6;
            i = (iy + 32) >> 6;
            j = (h * rx) / ry;
            k = (i * rx) / ry;

            if ((oi != i) && (oh != i))
            {
                xmj = x - j;
                xpj = x + j;
                if (i > 0)
                {
                    Graphics_DrawHorizontalLine(xmj, y + i, xpj, clrAtr);
                    Graphics_DrawHorizontalLine(xmj, y - i, xpj, clrAtr);
                }
                else
                {
                    Graphics_DrawHorizontalLine(xmj, y, xpj, clrAtr);
                }
                oi = i;
            }
            if ((oh != h) && (oi != h) && (i != h))
            {
                xmk = x - k;
                xpk = x + k;
                if (h > 0)
                {
                    Graphics_DrawHorizontalLine(xmk, y + h, xpk, clrAtr);
                    Graphics_DrawHorizontalLine(xmk, y - h, xpk, clrAtr);
                }
                else
                {
                    Graphics_DrawHorizontalLine(xmk, y, xpk, clrAtr);
                }
                oh = h;
            }

            ix = ix + iy / ry;
            iy = iy - ix / ry;

        } while (i > h);
    }
}

/// @brief Draws a triangle outline (works in both text and graphics modes)
/// @param x1 Vertex 1 x
/// @param y1 Vertex 1 y
/// @param x2 Vertex 2 x
/// @param y2 Vertex 2 y
/// @param x3 Vertex 3 x
/// @param y3 Vertex 3 y
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawTriangle(int32_t x1, int32_t y1, int32_t x2, int32_t y2, int32_t x3, int32_t y3, uint32_t clrAtr)
{
    Graphics_DrawLine(x1, y1, x2, y2, clrAtr);
    Graphics_DrawLine(x2, y2, x3, y3, clrAtr);
    Graphics_DrawLine(x3, y3, x1, y1, clrAtr);
}

/// @brief Draws a filled triangle (works in both text and graphics modes)
/// @param x1 Vertex 1 x
/// @param y1 Vertex 1 y
/// @param x2 Vertex 2 x
/// @param y2 Vertex 2 y
/// @param x3 Vertex 3 x
/// @param y3 Vertex 3 y
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawFilledTriangle(int32_t x1, int32_t y1, int32_t x2, int32_t y2, int32_t x3, int32_t y3, uint32_t clrAtr)
{
    // Sort vertices by their y-coordinates
    if (y1 > y2)
    {
        std::swap(x1, x2);
        std::swap(y1, y2);
    }
    if (y1 > y3)
    {
        std::swap(x1, x3);
        std::swap(y1, y3);
    }
    if (y2 > y3)
    {
        std::swap(x2, x3);
        std::swap(y2, y3);
    }

    // Check if the entire triangle is outside the image bounds
    if (x3 < 0 || x1 >= write_page->width || y3 < 0 || y1 >= write_page->height)
    {
        return; // The triangle is completely outside the image
    }

    // Calculate slopes of the two lines
    float invSlope1 = (float)(x2 - x1) / (y2 - y1);
    float invSlope2 = (float)(x3 - x1) / (y3 - y1);

    float curX1 = x1;
    float curX2 = x1;

    // Fill the top part of the clipped triangle
    for (int32_t scanlineY = y1; scanlineY <= y2; scanlineY++)
    {
        Graphics_DrawHorizontalLine(curX1, scanlineY, curX2, clrAtr);
        curX1 += invSlope1;
        curX2 += invSlope2;
    }

    // Calculate the new slope for the bottom part of the clipped triangle
    invSlope1 = (float)(x3 - x2) / (y3 - y2);
    curX1 = x2;

    // Fill the bottom part of the clipped triangle
    for (int32_t scanlineY = y2 + 1; scanlineY <= y3; scanlineY++)
    {
        Graphics_DrawHorizontalLine(curX1, scanlineY, curX2, clrAtr);
        curX1 += invSlope1;
        curX2 += invSlope2;
    }
}

/// @brief Makes a BGRA color from RGBA components.
/// This is multiple times faster than QB64's built-in _RGB32
/// @param r Red (0 - 255)
/// @param g Green (0 - 255)
/// @param b Blue (0 - 255)
/// @param a Alpha (0 - 255)
/// @return Returns an RGBA color
inline constexpr uint32_t Graphics_MakeBGRA(uint8_t r, uint8_t g, uint8_t b, uint8_t a)
{
    return ((static_cast<uint32_t>(a) << 24) | (static_cast<uint32_t>(r) << 16) | (static_cast<uint32_t>(g) << 8) | static_cast<uint32_t>(b));
}

/// @brief Makes a RGBA color from RGBA components
/// @param r Red (0 - 255)
/// @param g Green (0 - 255)
/// @param b Blue (0 - 255)
/// @param a Alpha (0 - 255)
/// @return Returns an RGBA color
inline constexpr uint32_t Graphics_MakeRGBA(uint8_t r, uint8_t g, uint8_t b, uint8_t a)
{
    return ((static_cast<uint32_t>(a) << 24) | (static_cast<uint32_t>(b) << 16) | (static_cast<uint32_t>(g) << 8) | static_cast<uint32_t>(r));
}

/// @brief Returns the Red component
/// @param rgba An RGBA color
/// @return Red
inline constexpr uint8_t Graphics_GetRedFromRGBA(uint32_t rgba)
{
    return static_cast<uint8_t>(rgba);
}

/// @brief Returns the Green component
/// @param rgba An RGBA color
/// @return Green
inline constexpr uint8_t Graphics_GetGreenFromRGBA(uint32_t rgba)
{
    return static_cast<uint8_t>(rgba >> 8);
}

/// @brief Returns the Blue component
/// @param rgba An RGBA color
/// @return Blue
inline constexpr uint8_t Graphics_GetBlueFromRGBA(uint32_t rgba)
{
    return static_cast<uint8_t>(rgba >> 16);
}

/// @brief Returns the Alpha value
/// @param rgba An RGBA color
/// @return Alpha
inline constexpr uint8_t Graphics_GetAlphaFromRGBA(uint32_t rgba)
{
    return static_cast<uint8_t>(rgba >> 24);
}

/// @brief Gets the RGB or BGR value without the alpha
/// @param rgba An RGBA or BGRA color
/// @return RGB or BGR value
inline constexpr uint32_t Graphics_GetRGB(uint32_t clr)
{
    return clr & 0xFFFFFFu;
}

/// @brief Helps convert a BGRA color to an RGBA color and back
/// @param bgra A BGRA color or an RGBA color
/// @return An RGBA color or a BGRA color
inline constexpr uint32_t Graphics_SwapRedBlue(uint32_t clr)
{
    return ((clr & 0xFF00FF00u) | ((clr & 0x00FF0000u) >> 16) | ((clr & 0x000000FFu) << 16));
}

//----------------------------------------------------------------------------------------------------------------------
// Extended graphics routines
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

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
extern void pset(int32_t x, int32_t y, uint32_t color);
extern void fast_boxfill(int32_t x1, int32_t y1, int32_t x2, int32_t y2, uint32_t color);

/// @brief This is a function pointer type that we'll use to plot "pixels" on graphics as well and "text" surfaces
typedef void (*Graphics_SetPixelFunction)(int32_t x, int32_t y, uint32_t clrAtr);

/// @brief We'll use this internally so that we do not have the overhead of calling __Graphics_SetSetPixelFunction() for every pixel
static Graphics_SetPixelFunction __Graphics_SetPixel = nullptr;

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

/// @brief This is used to plot a text "pixel" on a "text" surface. No clipping is done
/// @param x The x position
/// @param y The y position
/// @param clrAtr A combination of the ASCII character and the text color attributes
inline static void __Graphics_SetTextPixel(int32_t x, int32_t y, uint32_t clrAtr)
{
    *(reinterpret_cast<uint16_t *>(write_page->offset) + write_page->width * y + x) = (uint16_t)clrAtr;
}

/// @brief This selects the correct "SetPixel" function for later rendering
inline static void __Graphics_SelectSetPixelFunction(bool clipped)
{
    __Graphics_SetPixel = clipped ? (write_page->text ? __Graphics_SetTextPixelClipped : pset_and_clip) : (write_page->text ? __Graphics_SetTextPixel : pset);
}

/// @brief Public library function for plotting pixels on text and graphic surfaces
/// @param x The x position
/// @param y The y position
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
inline void Graphics_SetPixel(int32_t x, int32_t y, uint32_t clrAtr)
{
    __Graphics_SelectSetPixelFunction(true); // always used clipped versions for public function
    __Graphics_SetPixel(x, y, clrAtr);
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
    __Graphics_SelectSetPixelFunction(false); // we'll do custom clipping below

    // Check for unusual cases
    if (lx > rx)
        std::swap(lx, rx);

    // Leave if line is completely outside the image
    if (ty < 0 or ty >= write_page->height or (lx < 0 and rx < 0) or (lx >= write_page->width and rx >= write_page->width))
        return;

    if (lx < 0)
        lx = 0;
    if (rx >= write_page->width)
        rx = write_page->width - 1;

    for (auto x = lx; x <= rx; x++)
        __Graphics_SetPixel(x, ty, clrAtr);
}

/// @brief Draws a vertical line (works in both text and graphics modes)
/// @param lx Left x position
/// @param ty Top y position
/// @param by Bottom y position
/// @param c A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawVerticalLine(int32_t lx, int32_t ty, int32_t by, uint32_t clrAtr)
{
    __Graphics_SelectSetPixelFunction(false); // we'll do custom clipping below

    // Check for unusual cases
    if (ty > by)
        std::swap(ty, by);

    // Leave if line is completely outside the image
    if (lx < 0 or lx >= write_page->width or (ty < 0 and by < 0) or (ty >= write_page->height and by >= write_page->height))
        return;

    if (ty < 0)
        ty = 0;
    if (by >= write_page->height)
        by = write_page->height - 1;

    for (auto y = ty; y <= by; y++)
        __Graphics_SetPixel(lx, y, clrAtr);
}

/// @brief Draws a rectangle (works in both text and graphics modes)
/// @param lx Left x position
/// @param ty Top y position
/// @param rx Right x position
/// @param by Bottom y position
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawRectangle(int32_t lx, int32_t ty, int32_t rx, int32_t by, uint32_t clrAtr)
{
    __Graphics_SelectSetPixelFunction(true);

    auto xMin = std::min(lx, rx);
    auto xMax = std::max(lx, rx);
    auto yMin = std::min(ty, by) + 1; // avoid re-drawing the corners
    auto yMax = std::max(ty, by) - 1; // same as above

    for (auto x = xMin; x <= xMax; x++)
    {
        __Graphics_SetPixel(x, ty, clrAtr);
        __Graphics_SetPixel(x, by, clrAtr);
    }

    for (auto y = yMin; y <= yMax; y++)
    {
        __Graphics_SetPixel(lx, y, clrAtr);
        __Graphics_SetPixel(rx, y, clrAtr);
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
    // Check for unusual cases
    if (lx > rx)
        std::swap(lx, rx);
    if (ty > by)
        std::swap(ty, by);

    // Leave if rectangle is completely outside the image
    if ((lx < 0 and rx < 0) or (ty < 0 and by < 0) or (lx >= write_page->width and rx >= write_page->width) or (ty >= write_page->height and by >= write_page->height))
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

    if (write_page->text)
    {
        // Get pointer to the starting "pixel"
        auto buffer = (reinterpret_cast<uint16_t *>(write_page->offset) + write_page->width * ty + lx);

        // Draw one complete line
        auto rectWidth = 1 + rx - lx;
        std::fill(buffer, buffer + rectWidth, clrAtr);

        // Copy the remaining lines
        rectWidth <<= 1;                        // since we are dealing with 2 byte attributes
        auto dest = buffer + write_page->width; // get the pointer to the next line
        for (auto y = ty; y < by; y++)          // y < by since we already rendered the first line using std::fill
        {
            memcpy(dest, buffer, rectWidth);
            dest += write_page->width; // move to the next line
        }
    }
    else
    {
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
    __Graphics_SelectSetPixelFunction(true);

    int32_t deltaX = abs(x2 - x1);
    int32_t deltaY = -abs(y2 - y1);
    int32_t sx = x1 < x2 ? 1 : -1;
    int32_t sy = y1 < y2 ? 1 : -1;
    int32_t err = deltaX + deltaY; // error value

    while (x1 != x2 || y1 != y2)
    {
        __Graphics_SetPixel(x1, y1, clrAtr);

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
    __Graphics_SetPixel(x2, y2, clrAtr);
}

/// @brief Draws a circle (works in both text and graphics modes)
/// @param x The circles center x position
/// @param y The circles center y position
/// @param radius The radius of the circle
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawCircle(int32_t x, int32_t y, int32_t radius, uint32_t clrAtr)
{
    __Graphics_SelectSetPixelFunction(true);

    int32_t p = 1 - radius, cx = 0, cy = radius, px, py;

    do
    {
        px = x + cx;
        py = y + cy;
        __Graphics_SetPixel(px, py, clrAtr);
        px = x - cx;
        __Graphics_SetPixel(px, py, clrAtr);
        px = x + cx;
        py = y - cy;
        __Graphics_SetPixel(px, py, clrAtr);
        px = x - cx;
        __Graphics_SetPixel(px, py, clrAtr);
        px = x + cy;
        py = y + cx;
        __Graphics_SetPixel(px, py, clrAtr);
        py = y - cx;
        __Graphics_SetPixel(px, py, clrAtr);
        px = x - cy;
        py = y + cx;
        __Graphics_SetPixel(px, py, clrAtr);
        py = y - cx;
        __Graphics_SetPixel(px, py, clrAtr);

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
void Graphics_DrawFilledCircle(int32_t cx, int32_t cy, int32_t r, uint32_t c)
{
    auto radius = abs(r), radiusError = -radius, x = radius, y = 0;

    if (!radius)
    {
        Graphics_SetPixel(cx, cy, c);
        return;
    }

    Graphics_DrawFilledRectangle(cx - x, cy, cx + x, cy, c);

    while (x > y)
    {
        radiusError += (y << 1) + 1;

        if (radiusError >= 0)
        {
            if (x != y + 1)
            {
                Graphics_DrawFilledRectangle(cx - y, cy - x, cx + y, cy - x, c);
                Graphics_DrawFilledRectangle(cx - y, cy + x, cx + y, cy + x, c);
            }
            --x;
            radiusError -= x << 1;
        }

        ++y;

        Graphics_DrawFilledRectangle(cx - x, cy - y, cx + x, cy - y, c);
        Graphics_DrawFilledRectangle(cx - x, cy + y, cx + x, cy + y, c);
    }
}

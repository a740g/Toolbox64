//----------------------------------------------------------------------------------------------------------------------
// QB64-PE 32-bit color functions
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>

#define TO_BGRA(_r_, _g_, _b_, _a_) (((uint32_t)(_a_) << 24) | ((uint32_t)(_r_) << 16) | ((uint32_t)(_g_) << 8) | (uint32_t)(_b_))
#define GET_BGRA_A(_bgra_) ((uint8_t)((_bgra_) >> 24))
#define GET_BGRA_R(_bgra_) ((uint8_t)(((_bgra_) >> 16) & 0xFFu))
#define GET_BGRA_G(_bgra_) ((uint8_t)(((_bgra_) >> 8) & 0xFFu))
#define GET_BGRA_B(_bgra_) ((uint8_t)((_bgra_)&0xFFu))
#define TO_RGBA(_r_, _g_, _b_, _a_) (((uint32_t)(_a_) << 24) | ((uint32_t)(_b_) << 16) | ((uint32_t)(_g_) << 8) | (uint32_t)(_r_))
#define GET_RGBA_A(_rgba_) ((uint8_t)((_rgba_) >> 24))
#define GET_RGBA_B(_rgba_) ((uint8_t)(((_rgba_) >> 16) & 0xFFu))
#define GET_RGBA_G(_rgba_) ((uint8_t)(((_rgba_) >> 8) & 0xFFu))
#define GET_RGBA_R(_rgba_) ((uint8_t)((_rgba_)&0xFFu))
#define GET_RGB(_clr_) ((_clr_)&0xFFFFFFu)
#define SWAP_RED_BLUE(_clr_) (((_clr_)&0xFF00FF00u) | (((_clr_)&0x00FF0000u) >> 16) | (((_clr_)&0x000000FFu) << 16))

/// @brief Makes a BGRA color from RGBA components.
/// This is multiple times faster than QB64's built-in _RGB32
/// @param r Red (0 - 255)
/// @param g Green (0 - 255)
/// @param b Blue (0 - 255)
/// @param a Alpha (0 - 255)
/// @return Returns an RGBA color
inline uint32_t ToBGRA(uint8_t r, uint8_t g, uint8_t b, uint8_t a)
{
    return TO_BGRA(r, g, b, a);
}

/// @brief Makes a RGBA color from RGBA components
/// @param r Red (0 - 255)
/// @param g Green (0 - 255)
/// @param b Blue (0 - 255)
/// @param a Alpha (0 - 255)
/// @return Returns an RGBA color
inline uint32_t ToRGBA(uint8_t r, uint8_t g, uint8_t b, uint8_t a)
{
    return TO_RGBA(r, g, b, a);
}

/// @brief Returns the Red component
/// @param rgba An RGBA color
/// @return Red
inline uint8_t GetRedFromRGBA(uint32_t rgba)
{
    return GET_RGBA_R(rgba);
}

/// @brief Returns the Green component
/// @param rgba An RGBA color
/// @return Green
inline uint8_t GetGreenFromRGBA(uint32_t rgba)
{
    return GET_RGBA_G(rgba);
}

/// @brief Returns the Blue component
/// @param rgba An RGBA color
/// @return Blue
inline uint8_t GetBlueFromRGBA(uint32_t rgba)
{
    return GET_RGBA_B(rgba);
}

/// @brief Returns the Alpha value
/// @param rgba An RGBA color
/// @return Alpha
inline uint8_t GetAlphaFromRGBA(uint32_t rgba)
{
    return GET_RGBA_A(rgba);
}

/// @brief Gets the RGB or BGR value without the alpha
/// @param rgba An RGBA or BGRA color
/// @return RGB or BGR value
inline uint32_t GetRGB(uint32_t clr)
{
    return GET_RGB(clr);
}

/// @brief Helps convert a BGRA color to an RGBA color and back
/// @param bgra A BGRA color or an RGBA color
/// @return An RGBA color or a BGRA color
inline uint32_t SwapRedBlue(uint32_t clr)
{
    return SWAP_RED_BLUE(clr);
}

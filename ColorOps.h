//----------------------------------------------------------------------------------------------------------------------
// QB64-PE 32-bit color functions
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>

/// @brief Makes a BGRA color from RGBA components.
/// This is multiple times faster than QB64's built-in _RGB32
/// @param r Red (0 - 255)
/// @param g Green (0 - 255)
/// @param b Blue (0 - 255)
/// @param a Alpha (0 - 255)
/// @return Returns an RGBA color
inline uint32_t ToBGRA(uint8_t r, uint8_t g, uint8_t b, uint8_t a)
{
    return ((static_cast<uint32_t>(a) << 24) | (static_cast<uint32_t>(r) << 16) | (static_cast<uint32_t>(g) << 8) | static_cast<uint32_t>(b));
}

/// @brief Makes a RGBA color from RGBA components
/// @param r Red (0 - 255)
/// @param g Green (0 - 255)
/// @param b Blue (0 - 255)
/// @param a Alpha (0 - 255)
/// @return Returns an RGBA color
inline uint32_t ToRGBA(uint8_t r, uint8_t g, uint8_t b, uint8_t a)
{
    return ((static_cast<uint32_t>(a) << 24) | (static_cast<uint32_t>(b) << 16) | (static_cast<uint32_t>(g) << 8) | static_cast<uint32_t>(r));
}

/// @brief Returns the Red component
/// @param rgba An RGBA color
/// @return Red
inline uint8_t GetRedFromRGBA(uint32_t rgba)
{
    return static_cast<uint8_t>(rgba);
}

/// @brief Returns the Green component
/// @param rgba An RGBA color
/// @return Green
inline uint8_t GetGreenFromRGBA(uint32_t rgba)
{
    return static_cast<uint8_t>(rgba >> 8);
}

/// @brief Returns the Blue component
/// @param rgba An RGBA color
/// @return Blue
inline uint8_t GetBlueFromRGBA(uint32_t rgba)
{
    return static_cast<uint8_t>(rgba >> 16);
}

/// @brief Returns the Alpha value
/// @param rgba An RGBA color
/// @return Alpha
inline uint8_t GetAlphaFromRGBA(uint32_t rgba)
{
    return static_cast<uint8_t>(rgba >> 24);
}

/// @brief Gets the RGB or BGR value without the alpha
/// @param rgba An RGBA or BGRA color
/// @return RGB or BGR value
inline uint32_t GetRGB(uint32_t clr)
{
    return clr & 0xFFFFFFu;
}

/// @brief Helps convert a BGRA color to an RGBA color and back
/// @param bgra A BGRA color or an RGBA color
/// @return An RGBA color or a BGRA color
inline uint32_t SwapRedBlue(uint32_t clr)
{
    return ((clr & 0xFF00FF00u) | ((clr & 0x00FF0000u) >> 16) | ((clr & 0x000000FFu) << 16));
}

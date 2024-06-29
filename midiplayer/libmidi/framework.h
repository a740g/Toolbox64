
/** $VER: framework.h (2024.05.12) P. Stuer **/

#pragma once

#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <strsafe.h>
#include <cstring>
#include <algorithm>
#include <cmath>
#include <cassert>
#include <format>
#include <string>
#include <vector>
#include <stdexcept>

#define TOSTRING_IMPL(x) #x
#define TOSTRING(x) TOSTRING_IMPL(x)

#ifdef _DEBUG
#define _RCP_VERBOSE
#else
#undef _RCP_VERBOSE
#endif

#ifndef mmioFOURCC
#define mmioFOURCC(char1, char2, char3, char4) (static_cast<uint32_t>(char1) | (static_cast<uint32_t>(char2) << 8) | (static_cast<uint32_t>(char3) << 16) | (static_cast<uint32_t>(char4) << 24))
#endif

#ifndef _WIN32
typedef uint32_t FOURCC;
#endif

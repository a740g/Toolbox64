size_t RandomMaximum() { return RAND_MAX; }

size_t OffsetToNumber(void *p) { return (size_t)p; }

void *NumberToOffset(size_t n) { return (void *)n; }

void *OffsetToString(void *p) { return p; }

void *PeekOffset(void **p) { return *p; }

uint8_t PeekByteAtOffset(void *p, size_t o) { return *((uint8_t *)p + o); }

uint16_t PeekIntegerAtOffset(void *p, size_t o) { return *((uint16_t *)p + o); }

uint32_t PeekLongAtOffset(void *p, size_t o) { return *((uint32_t *)p + o); }

uint64_t PeekInteger64AtOffset(void *p, size_t o) { return *((uint64_t *)p + o); }

float PeekSingleAtOffset(void *p, size_t o) { return *((float *)p + o); }

double PeekDoubleAtOffset(void *p, size_t o) { return *((double *)p + o); }

void *PeekOffsetAtOffset(void *p, size_t o) { return (void *)(*((size_t *)p + o)); }

uint8_t PeekString(char *s, size_t o) { return s[o]; }

void PokeByteAtOffset(void *p, size_t o, uint8_t n) { *((uint8_t *)p + o) = n; }

void PokeIntegerAtOffset(void *p, size_t o, uint16_t n) { *((uint16_t *)p + o) = n; }

void PokeLongAtOffset(void *p, size_t o, uint32_t n) { *((uint32_t *)p + o) = n; }

void PokeInteger64AtOffset(void *p, size_t o, uint64_t n) { *((uint64_t *)p + o) = n; }

void PokeOffsetAtOffset(void *p, size_t o, void *n) { *((size_t *)p + o) = (size_t)n; }

void PokeString(char *s, size_t o, uint8_t n) { s[o] = n; }

float CastLongToSingle(int32_t n) { return *(float *)&n; }

int32_t CastSingleToLong(float n) { return *(int32_t *)&n; }

uint32_t NextPowerOfTwo(uint32_t n) {
    --n;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    return ++n;
}

/// @brief Returns the previous (floor) power of 2 for x. E.g. x = 600 then returns 512
/// @param x Any number
/// @return Previous (floor) power of 2 for x
uint32_t PreviousPowerOfTwo(uint32_t n) {
    n |= (n >> 1);
    n |= (n >> 2);
    n |= (n >> 4);
    n |= (n >> 8);
    n |= (n >> 16);
    return n - (n >> 1);
}

/// @brief Returns the number using which we need to shift 1 left to get x
/// @param x A power of 2 number
/// @return A number (n) that we use in 1 << n to get x
uint32_t LShOneCount(uint32_t x) { return x == 0 ? 0 : (CHAR_BIT * sizeof(x)) - 1 - __builtin_clz(x); }
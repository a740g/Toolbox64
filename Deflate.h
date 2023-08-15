//----------------------------------------------------------------------------------------------------------------------
// Compression library for QB64-PE based on Google Zopfli
// Copyright (c) 2023 Samuel Gomes
//
// This is a heavily modified and amalgamated version of the Google Zopfli library
// Only the zlib and deflate capabilities are kept (so that QB64-PE's _INFLATE can be used to decompress the data)
// https://github.com/google/zopfli
//
// Copyright 2011 Google Inc.
// https://github.com/google/zopfli/blob/master/COPYING
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>
#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstring>
#include <cstdio>

/* Minimum and maximum length that can be encoded in deflate. */
#define ZOPFLI_MAX_MATCH 258
#define ZOPFLI_MIN_MATCH 3

/* Number of distinct literal/length and distance symbols in DEFLATE */
#define ZOPFLI_NUM_LL 288
#define ZOPFLI_NUM_D 32

/*
The window size for deflate. Must be a power of two. This should be 32768, the
maximum possible by the deflate spec. Anything less hurts compression more than
speed.
*/
#define ZOPFLI_WINDOW_SIZE 32768

/*
The window mask used to wrap indices into the window. This is why the
window size must be a power of two.
*/
#define ZOPFLI_WINDOW_MASK (ZOPFLI_WINDOW_SIZE - 1)

/*
A block structure of huge, non-smart, blocks to divide the input into, to allow
operating on huge files without exceeding memory, such as the 1GB wiki9 corpus.
The whole compression algorithm, including the smarter block splitting, will
be executed independently on each huge block.
Dividing into huge blocks hurts compression, but not much relative to the size.
Set it to 0 to disable master blocks.
*/
#define ZOPFLI_MASTER_BLOCK_SIZE 1000000

/*
Used to initialize costs for example
*/
#define ZOPFLI_LARGE_FLOAT 1e30

/*
For longest match cache. max 256. Uses huge amounts of memory but makes it
faster. Uses this many times three bytes per single byte of the input data.
This is so because longest match finding has to find the exact distance
that belongs to each length for the best lz77 strategy.
Good values: e.g. 5, 8.
*/
#define ZOPFLI_CACHE_LENGTH 8

/*
limit the max hash chain hits for this hash value. This has an effect only
on files where the hash value is the same very often. On these files, this
gives worse compression (the value should ideally be 32768, which is the
ZOPFLI_WINDOW_SIZE, while zlib uses 4096 even for best level), but makes it
faster on some specific files.
Good value: e.g. 8192.
*/
#define ZOPFLI_MAX_CHAIN_HITS 8192

/*
Whether to use the longest match cache for ZopfliFindLongestMatch. This cache
consumes a lot of memory but speeds it up. No effect on compression size.
*/
#define ZOPFLI_LONGEST_MATCH_CACHE

/*
Enable to remember amount of successive identical bytes in the hash chain for
finding longest match
required for ZOPFLI_HASH_SAME_HASH and ZOPFLI_SHORTCUT_LONG_REPETITIONS
This has no effect on the compression result, and enabling it increases speed.
*/
#define ZOPFLI_HASH_SAME

/*
Switch to a faster hash based on the info from ZOPFLI_HASH_SAME once the
best length so far is long enough. This is way faster for files with lots of
identical bytes, on which the compressor is otherwise too slow. Regular files
are unaffected or maybe a tiny bit slower.
This has no effect on the compression result, only on speed.
*/
#define ZOPFLI_HASH_SAME_HASH

/*
Enable this, to avoid slowness for files which are a repetition of the same
character more than a multiple of ZOPFLI_MAX_MATCH times. This should not affect
the compression result.
*/
#define ZOPFLI_SHORTCUT_LONG_REPETITIONS

/*
Whether to use lazy matching in the greedy LZ77 implementation. This gives a
better result of ZopfliLZ77Greedy, but the effect this has on the optimal LZ77
varies from file to file.
*/
#define ZOPFLI_LAZY_MATCHING

#define __ZOPFLI_HASH_SHIFT 5
#define __ZOPFLI_HASH_MASK 32767

/* __has_builtin available in clang */
#ifdef __has_builtin
#if __has_builtin(__builtin_clz)
#define ZOPFLI_HAS_BUILTIN_CLZ
#endif
/* __builtin_clz available beginning with GCC 3.4 */
#elif __GNUC__ * 100 + __GNUC_MINOR__ >= 304
#define ZOPFLI_HAS_BUILTIN_CLZ
#endif

/*
Appends value to dynamically allocated memory, doubling its allocation size
whenever needed.

value: the value to append, type T
data: pointer to the dynamic array to append to, type T**
size: pointer to the size of the array to append to, type size_t*. This is the
size that you consider the array to be, not the internal allocation size.
Precondition: allocated size of data is at least a power of two greater than or
equal than *size.
*/
#ifdef __cplusplus /* C++ cannot assign void* from malloc to *data */
#define ZOPFLI_APPEND_DATA(/* T */ value, /* T** */ data, /* size_t* */ size)           \
    {                                                                                   \
        if (!((*size) & ((*size) - 1)))                                                 \
        {                                                                               \
            /*double alloc size if it's a power of two*/                                \
            void **data_void = reinterpret_cast<void **>(data);                         \
            *data_void = (*size) == 0 ? malloc(sizeof(**data))                          \
                                      : realloc((*data), (*size) * 2 * sizeof(**data)); \
        }                                                                               \
        (*data)[(*size)] = (value);                                                     \
        (*size)++;                                                                      \
    }
#else /* C gives problems with strict-aliasing rules for (void**) cast */
#define ZOPFLI_APPEND_DATA(/* T */ value, /* T** */ data, /* size_t* */ size)        \
    {                                                                                \
        if (!((*size) & ((*size) - 1)))                                              \
        {                                                                            \
            /*double alloc size if it's a power of two*/                             \
            (*data) = (*size) == 0 ? malloc(sizeof(**data))                          \
                                   : realloc((*data), (*size) * 2 * sizeof(**data)); \
        }                                                                            \
        (*data)[(*size)] = (value);                                                  \
        (*size)++;                                                                   \
    }
#endif

/*
Stores lit/length and dist pairs for LZ77.
Parameter litlens: Contains the literal symbols or length values.
Parameter dists: Contains the distances. A value is 0 to indicate that there is
no dist and the corresponding litlens value is a literal instead of a length.
Parameter size: The size of both the litlens and dists arrays.
The memory can best be managed by using ZopfliInitLZ77Store to initialize it,
ZopfliCleanLZ77Store to destroy it, and ZopfliStoreLitLenDist to append values.

*/
typedef struct ZopfliLZ77Store
{
    unsigned short *litlens; /* Lit or len. */
    unsigned short *dists;   /* If 0: indicates literal in corresponding litlens,
         if > 0: length in corresponding litlens, this is the distance. */
    size_t size;

    const unsigned char *data; /* original data */
    size_t *pos;               /* position in data where this LZ77 command begins */

    unsigned short *ll_symbol;
    unsigned short *d_symbol;

    /* Cumulative histograms wrapping around per chunk. Each chunk has the amount
    of distinct symbols as length, so using 1 value per LZ77 symbol, we have a
    precise histogram at every N symbols, and the rest can be calculated by
    looping through the actual symbols of this chunk. */
    size_t *ll_counts;
    size_t *d_counts;
} ZopfliLZ77Store;

/*
Options used throughout the program.
*/
typedef struct ZopfliOptions
{
    /* Whether to print output */
    int verbose;

    /* Whether to print more detailed output */
    int verbose_more;

    /*
    Maximum amount of times to rerun forward and backward pass to optimize LZ77
    compression cost. Good values: 10, 15 for small files, 5 for files over
    several MB in size or it will be too slow.
    */
    int numiterations;

    /*
    If true, splits the data in multiple deflate blocks with optimal choice
    for the block boundaries. Block splitting gives better compression. Default:
    true (1).
    */
    int blocksplitting;

    /*
    No longer used, left for compatibility.
    */
    int blocksplittinglast;

    /*
    Maximum amount of blocks to split into (0 for unlimited, but this can give
    extreme results that hurt compression on some files). Default value: 15.
    */
    int blocksplittingmax;
} ZopfliOptions;

/*
Cache used by ZopfliFindLongestMatch to remember previously found length/dist
values.
This is needed because the squeeze runs will ask these values multiple times for
the same position.
Uses large amounts of memory, since it has to remember the distance belonging
to every possible shorter-than-the-best length (the so called "sublen" array).
*/
typedef struct ZopfliLongestMatchCache
{
    unsigned short *length;
    unsigned short *dist;
    unsigned char *sublen;
} ZopfliLongestMatchCache;

/*
Some state information for compressing a block.
This is currently a bit under-used (with mainly only the longest match cache),
but is kept for easy future expansion.
*/
typedef struct ZopfliBlockState
{
    const ZopfliOptions *options;

#ifdef ZOPFLI_LONGEST_MATCH_CACHE
    /* Cache for length/distance pairs found so far. */
    ZopfliLongestMatchCache *lmc;
#endif

    /* The start (inclusive) and end (not inclusive) of the current block. */
    size_t blockstart;
    size_t blockend;
} ZopfliBlockState;

typedef struct ZopfliHash
{
    int *head;            /* Hash value to index of its most recent occurrence. */
    unsigned short *prev; /* Index to index of prev. occurrence of same hash. */
    int *hashval;         /* Index to hash value at this index. */
    int val;              /* Current hash value. */

#ifdef ZOPFLI_HASH_SAME_HASH
    /* Fields with similar purpose as the above hash, but for the second hash with
    a value that is calculated differently.  */
    int *head2;            /* Hash value to index of its most recent occurrence. */
    unsigned short *prev2; /* Index to index of prev. occurrence of same hash. */
    int *hashval2;         /* Index to hash value at this index. */
    int val2;              /* Current hash value. */
#endif

#ifdef ZOPFLI_HASH_SAME
    unsigned short *same; /* Amount of repetitions of same byte after this .*/
#endif
} ZopfliHash;

typedef struct __zopfli_SplitCostContext
{
    const ZopfliLZ77Store *lz77;
    size_t start;
    size_t end;
} __zopfli_SplitCostContext;

typedef struct __zopfli_SymbolStats
{
    /* The literal and length symbols. */
    size_t litlens[ZOPFLI_NUM_LL];
    /* The 32 unique dist symbols, not the 32768 possible dists. */
    size_t dists[ZOPFLI_NUM_D];

    /* Length of each lit/len symbol in bits. */
    double ll_symbols[ZOPFLI_NUM_LL];
    /* Length of each dist symbol in bits. */
    double d_symbols[ZOPFLI_NUM_D];
} __zopfli_SymbolStats;

typedef struct __zopfli_RanState
{
    unsigned int m_w, m_z;
} __zopfli_RanState;

typedef struct __zopfli_Node __zopfli_Node;

/*
Nodes forming chains. Also used to represent leaves.
*/
struct __zopfli_Node
{
    size_t weight;       /* Total weight (symbol count) of this chain. */
    __zopfli_Node *tail; /* Previous node(s) of this chain, or 0 if none. */
    int count;           /* Leaf symbol index, or number of leaves before this chain. */
};

/*
Memory pool for nodes.
*/
typedef struct __zopfli_NodePool
{
    __zopfli_Node *next; /* Pointer to a free node in the pool. */
} __zopfli_NodePool;

/*
Function that calculates a cost based on a model for the given LZ77 symbol.
litlen: means literal symbol if dist is 0, length otherwise.
*/
typedef double __zopfli_CostModelFun(unsigned litlen, unsigned dist, void *context);

/*
The "f" for the __zopfli_FindMinimum function below.
i: the current parameter of f(i)
context: for your implementation
*/
typedef double __zopfli_FindMinimumFun(size_t i, void *context);

static void ZopfliInitLZ77Store(const unsigned char *data, ZopfliLZ77Store *store)
{
    store->size = 0;
    store->litlens = 0;
    store->dists = 0;
    store->pos = 0;
    store->data = data;
    store->ll_symbol = 0;
    store->d_symbol = 0;
    store->ll_counts = 0;
    store->d_counts = 0;
}

static void ZopfliInitCache(size_t blocksize, ZopfliLongestMatchCache *lmc)
{
    size_t i;
    lmc->length = (unsigned short *)malloc(sizeof(unsigned short) * blocksize);
    lmc->dist = (unsigned short *)malloc(sizeof(unsigned short) * blocksize);
    /* Rather large amount of memory. */
    lmc->sublen = (unsigned char *)malloc(ZOPFLI_CACHE_LENGTH * 3 * blocksize);
    if (lmc->sublen == NULL)
    {
        fprintf(stderr, "Error: Out of memory. Tried allocating %lu bytes of memory.\n",
                (unsigned long)ZOPFLI_CACHE_LENGTH * 3 * blocksize);
        exit(EXIT_FAILURE);
    }

    /* length > 0 and dist 0 is invalid combination, which indicates on purpose
    that this cache value is not filled in yet. */
    for (i = 0; i < blocksize; i++)
        lmc->length[i] = 1;
    for (i = 0; i < blocksize; i++)
        lmc->dist[i] = 0;
    for (i = 0; i < ZOPFLI_CACHE_LENGTH * blocksize * 3; i++)
        lmc->sublen[i] = 0;
}

static void ZopfliInitBlockState(const ZopfliOptions *options, size_t blockstart, size_t blockend, int add_lmc,
                                 ZopfliBlockState *s)
{
    s->options = options;
    s->blockstart = blockstart;
    s->blockend = blockend;
#ifdef ZOPFLI_LONGEST_MATCH_CACHE
    if (add_lmc)
    {
        s->lmc = (ZopfliLongestMatchCache *)malloc(sizeof(ZopfliLongestMatchCache));
        ZopfliInitCache(blockend - blockstart, s->lmc);
    }
    else
    {
        s->lmc = 0;
    }
#endif
}

/*
bp = bitpointer, always in range [0, 7].
The outsize is number of necessary bytes to encode the bits.
Given the value of bp and the amount of bytes, the amount of bits represented
is not simply bytesize * 8 + bp because even representing one bit requires a
whole byte. It is: (bp == 0) ? (bytesize * 8) : ((bytesize - 1) * 8 + bp)
*/
static void __zopfli_AddBit(int bit, unsigned char *bp, unsigned char **out, size_t *outsize)
{
    if (*bp == 0)
        ZOPFLI_APPEND_DATA(0, out, outsize);
    (*out)[*outsize - 1] |= bit << *bp;
    *bp = (*bp + 1) & 7;
}

/* Since an uncompressed block can be max 65535 in size, it actually adds
multible blocks if needed. */
static void __zopfli_AddNonCompressedBlock(const ZopfliOptions *options, int final, const unsigned char *in, size_t instart,
                                           size_t inend, unsigned char *bp, unsigned char **out, size_t *outsize)
{
    size_t pos = instart;
    (void)options;
    for (;;)
    {
        size_t i;
        unsigned short blocksize = 65535;
        unsigned short nlen;
        int currentfinal;

        if (pos + blocksize > inend)
            blocksize = inend - pos;
        currentfinal = pos + blocksize >= inend;

        nlen = ~blocksize;

        __zopfli_AddBit(final && currentfinal, bp, out, outsize);
        /* BTYPE 00 */
        __zopfli_AddBit(0, bp, out, outsize);
        __zopfli_AddBit(0, bp, out, outsize);

        /* Any bits of input up to the next byte boundary are ignored. */
        *bp = 0;

        ZOPFLI_APPEND_DATA(blocksize % 256, out, outsize);
        ZOPFLI_APPEND_DATA((blocksize / 256) % 256, out, outsize);
        ZOPFLI_APPEND_DATA(nlen % 256, out, outsize);
        ZOPFLI_APPEND_DATA((nlen / 256) % 256, out, outsize);

        for (i = 0; i < blocksize; i++)
        {
            ZOPFLI_APPEND_DATA(in[pos + i], out, outsize);
        }

        if (currentfinal)
            break;
        pos += blocksize;
    }
}

static void ZopfliAllocHash(size_t window_size, ZopfliHash *h)
{
    h->head = (int *)malloc(sizeof(*h->head) * 65536);
    h->prev = (unsigned short *)malloc(sizeof(*h->prev) * window_size);
    h->hashval = (int *)malloc(sizeof(*h->hashval) * window_size);

#ifdef ZOPFLI_HASH_SAME
    h->same = (unsigned short *)malloc(sizeof(*h->same) * window_size);
#endif

#ifdef ZOPFLI_HASH_SAME_HASH
    h->head2 = (int *)malloc(sizeof(*h->head2) * 65536);
    h->prev2 = (unsigned short *)malloc(sizeof(*h->prev2) * window_size);
    h->hashval2 = (int *)malloc(sizeof(*h->hashval2) * window_size);
#endif
}

/* Gets the amount of extra bits for the given dist, cfr. the DEFLATE spec. */
static int ZopfliGetDistExtraBits(int dist)
{
#ifdef ZOPFLI_HAS_BUILTIN_CLZ
    if (dist < 5)
        return 0;
    return (31 ^ __builtin_clz(dist - 1)) - 1; /* log2(dist - 1) - 1 */
#else
    if (dist < 5)
        return 0;
    else if (dist < 9)
        return 1;
    else if (dist < 17)
        return 2;
    else if (dist < 33)
        return 3;
    else if (dist < 65)
        return 4;
    else if (dist < 129)
        return 5;
    else if (dist < 257)
        return 6;
    else if (dist < 513)
        return 7;
    else if (dist < 1025)
        return 8;
    else if (dist < 2049)
        return 9;
    else if (dist < 4097)
        return 10;
    else if (dist < 8193)
        return 11;
    else if (dist < 16385)
        return 12;
    else
        return 13;
#endif
}

/* Gets the amount of extra bits for the given length, cfr. the DEFLATE spec. */
static int ZopfliGetLengthExtraBits(int l)
{
    static const int table[259] = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3,
        3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
        5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
        5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
        5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0};
    return table[l];
}

/*
Gets the symbol for the given length, cfr. the DEFLATE spec.
Returns the symbol in the range [257-285] (inclusive)
*/
static int ZopfliGetLengthSymbol(int l)
{
    static const int table[259] = {
        0, 0, 0, 257, 258, 259, 260, 261, 262, 263, 264, 265, 265, 266, 266, 267, 267, 268, 268, 269, 269, 269,
        269, 270, 270, 270, 270, 271, 271, 271, 271, 272, 272, 272, 272, 273, 273, 273, 273, 273, 273, 273, 273, 274,
        274, 274, 274, 274, 274, 274, 274, 275, 275, 275, 275, 275, 275, 275, 275, 276, 276, 276, 276, 276, 276, 276,
        276, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 278, 278, 278, 278, 278,
        278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 279, 279, 279, 279, 279, 279, 279, 279, 279, 279, 279,
        279, 279, 279, 279, 279, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 281,
        281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281,
        281, 281, 281, 281, 281, 281, 281, 281, 281, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282,
        282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 283, 283, 283,
        283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283,
        283, 283, 283, 283, 283, 283, 283, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284,
        284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 285};
    return table[l];
}

/*
Cost model which should exactly match fixed tree.
type: __zopfli_CostModelFun
*/
static double __zopfli_GetCostFixed(unsigned litlen, unsigned dist, void *unused)
{
    (void)unused;
    if (dist == 0)
    {
        if (litlen <= 143)
            return 8;
        else
            return 9;
    }
    else
    {
        int dbits = ZopfliGetDistExtraBits(dist);
        int lbits = ZopfliGetLengthExtraBits(litlen);
        int lsym = ZopfliGetLengthSymbol(litlen);
        int cost = 0;
        if (lsym <= 279)
            cost += 7;
        else
            cost += 8;
        cost += 5; /* Every dist symbol has length 5. */
        return cost + dbits + lbits;
    }
}

/*
Finds the minimum possible cost this cost model can return for valid length and
distance symbols.
*/
static double __zopfli_GetCostModelMinCost(__zopfli_CostModelFun *costmodel, void *costcontext)
{
    double mincost;
    int bestlength = 0; /* length that has lowest cost in the cost model */
    int bestdist = 0;   /* distance that has lowest cost in the cost model */
    int i;
    /*
    Table of distances that have a different distance symbol in the deflate
    specification. Each value is the first distance that has a new symbol. Only
    different symbols affect the cost model so only these need to be checked.
    See RFC 1951 section 3.2.5. Compressed blocks (length and distance codes).
    */
    static const int dsymbols[30] = {1, 2, 3, 4, 5, 7, 9, 13, 17, 25,
                                     33, 49, 65, 97, 129, 193, 257, 385, 513, 769,
                                     1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577};

    mincost = ZOPFLI_LARGE_FLOAT;
    for (i = 3; i < 259; i++)
    {
        double c = costmodel(i, 1, costcontext);
        if (c < mincost)
        {
            bestlength = i;
            mincost = c;
        }
    }

    mincost = ZOPFLI_LARGE_FLOAT;
    for (i = 0; i < 30; i++)
    {
        double c = costmodel(3, dsymbols[i], costcontext);
        if (c < mincost)
        {
            bestdist = dsymbols[i];
            mincost = c;
        }
    }

    return costmodel(bestlength, bestdist, costcontext);
}

static void ZopfliResetHash(size_t window_size, ZopfliHash *h)
{
    size_t i;

    h->val = 0;
    for (i = 0; i < 65536; i++)
    {
        h->head[i] = -1; /* -1 indicates no head so far. */
    }
    for (i = 0; i < window_size; i++)
    {
        h->prev[i] = i; /* If prev[j] == j, then prev[j] is uninitialized. */
        h->hashval[i] = -1;
    }

#ifdef ZOPFLI_HASH_SAME
    for (i = 0; i < window_size; i++)
    {
        h->same[i] = 0;
    }
#endif

#ifdef ZOPFLI_HASH_SAME_HASH
    h->val2 = 0;
    for (i = 0; i < 65536; i++)
    {
        h->head2[i] = -1;
    }
    for (i = 0; i < window_size; i++)
    {
        h->prev2[i] = i;
        h->hashval2[i] = -1;
    }
#endif
}

/*
Update the sliding hash value with the given byte. All calls to this function
must be made on consecutive input characters. Since the hash value exists out
of multiple input bytes, a few warmups with this function are needed initially.
*/
static void __zopfli_UpdateHashValue(ZopfliHash *h, unsigned char c) { h->val = (((h->val) << __ZOPFLI_HASH_SHIFT) ^ (c)) & __ZOPFLI_HASH_MASK; }

static void ZopfliWarmupHash(const unsigned char *array, size_t pos, size_t end, ZopfliHash *h)
{
    __zopfli_UpdateHashValue(h, array[pos + 0]);
    if (pos + 1 < end)
        __zopfli_UpdateHashValue(h, array[pos + 1]);
}

static void ZopfliUpdateHash(const unsigned char *array, size_t pos, size_t end, ZopfliHash *h)
{
    unsigned short hpos = pos & ZOPFLI_WINDOW_MASK;
#ifdef ZOPFLI_HASH_SAME
    size_t amount = 0;
#endif

    __zopfli_UpdateHashValue(h, pos + ZOPFLI_MIN_MATCH <= end ? array[pos + ZOPFLI_MIN_MATCH - 1] : 0);
    h->hashval[hpos] = h->val;
    if (h->head[h->val] != -1 && h->hashval[h->head[h->val]] == h->val)
    {
        h->prev[hpos] = h->head[h->val];
    }
    else
        h->prev[hpos] = hpos;
    h->head[h->val] = hpos;

#ifdef ZOPFLI_HASH_SAME
    /* Update "same". */
    if (h->same[(pos - 1) & ZOPFLI_WINDOW_MASK] > 1)
    {
        amount = h->same[(pos - 1) & ZOPFLI_WINDOW_MASK] - 1;
    }
    while (pos + amount + 1 < end && array[pos] == array[pos + amount + 1] && amount < (unsigned short)(-1))
    {
        amount++;
    }
    h->same[hpos] = amount;
#endif

#ifdef ZOPFLI_HASH_SAME_HASH
    h->val2 = ((h->same[hpos] - ZOPFLI_MIN_MATCH) & 255) ^ h->val;
    h->hashval2[hpos] = h->val2;
    if (h->head2[h->val2] != -1 && h->hashval2[h->head2[h->val2]] == h->val2)
    {
        h->prev2[hpos] = h->head2[h->val2];
    }
    else
        h->prev2[hpos] = hpos;
    h->head2[h->val2] = hpos;
#endif
}

/*
Returns the length up to which could be stored in the cache.
*/
static unsigned ZopfliMaxCachedSublen(const ZopfliLongestMatchCache *lmc, size_t pos, size_t length)
{
    unsigned char *cache;
#if ZOPFLI_CACHE_LENGTH == 0
    return 0;
#endif
    cache = &lmc->sublen[ZOPFLI_CACHE_LENGTH * pos * 3];
    (void)length;
    if (cache[1] == 0 && cache[2] == 0)
        return 0; /* No sublen cached. */
    return cache[(ZOPFLI_CACHE_LENGTH - 1) * 3] + 3;
}

static void ZopfliCacheToSublen(const ZopfliLongestMatchCache *lmc, size_t pos, size_t length, unsigned short *sublen)
{
    size_t i, j;
    unsigned maxlength = ZopfliMaxCachedSublen(lmc, pos, length);
    unsigned prevlength = 0;
    unsigned char *cache;
#if ZOPFLI_CACHE_LENGTH == 0
    return;
#endif
    if (length < 3)
        return;
    cache = &lmc->sublen[ZOPFLI_CACHE_LENGTH * pos * 3];
    for (j = 0; j < ZOPFLI_CACHE_LENGTH; j++)
    {
        unsigned length = cache[j * 3] + 3;
        unsigned dist = cache[j * 3 + 1] + 256 * cache[j * 3 + 2];
        for (i = prevlength; i <= length; i++)
        {
            sublen[i] = dist;
        }
        if (length == maxlength)
            break;
        prevlength = length + 1;
    }
}

static void ZopfliSublenToCache(const unsigned short *sublen, size_t pos, size_t length, ZopfliLongestMatchCache *lmc)
{
    size_t i;
    size_t j = 0;
    unsigned bestlength = 0;
    unsigned char *cache;

#if ZOPFLI_CACHE_LENGTH == 0
    return;
#endif

    cache = &lmc->sublen[ZOPFLI_CACHE_LENGTH * pos * 3];
    if (length < 3)
        return;
    for (i = 3; i <= length; i++)
    {
        if (i == length || sublen[i] != sublen[i + 1])
        {
            cache[j * 3] = i - 3;
            cache[j * 3 + 1] = sublen[i] % 256;
            cache[j * 3 + 2] = (sublen[i] >> 8) % 256;
            bestlength = i;
            j++;
            if (j >= ZOPFLI_CACHE_LENGTH)
                break;
        }
    }
    if (j < ZOPFLI_CACHE_LENGTH)
    {
        assert(bestlength == length);
        cache[(ZOPFLI_CACHE_LENGTH - 1) * 3] = bestlength - 3;
    }
    else
    {
        assert(bestlength <= length);
    }
    assert(bestlength == ZopfliMaxCachedSublen(lmc, pos, length));
}

/*
Gets distance, length and sublen values from the cache if possible.
Returns 1 if it got the values from the cache, 0 if not.
Updates the limit value to a smaller one if possible with more limited
information from the cache.
*/
static int __zopfli_TryGetFromLongestMatchCache(ZopfliBlockState *s, size_t pos, size_t *limit, unsigned short *sublen,
                                                unsigned short *distance, unsigned short *length)
{
    /* The LMC cache starts at the beginning of the block rather than the
       beginning of the whole array. */
    size_t lmcpos = pos - s->blockstart;

    /* Length > 0 and dist 0 is invalid combination, which indicates on purpose
       that this cache value is not filled in yet. */
    unsigned char cache_available = s->lmc && (s->lmc->length[lmcpos] == 0 || s->lmc->dist[lmcpos] != 0);
    unsigned char limit_ok_for_cache =
        cache_available && (*limit == ZOPFLI_MAX_MATCH || s->lmc->length[lmcpos] <= *limit ||
                            (sublen && ZopfliMaxCachedSublen(s->lmc, lmcpos, s->lmc->length[lmcpos]) >= *limit));

    if (s->lmc && limit_ok_for_cache && cache_available)
    {
        if (!sublen || s->lmc->length[lmcpos] <= ZopfliMaxCachedSublen(s->lmc, lmcpos, s->lmc->length[lmcpos]))
        {
            *length = s->lmc->length[lmcpos];
            if (*length > *limit)
                *length = *limit;
            if (sublen)
            {
                ZopfliCacheToSublen(s->lmc, lmcpos, *length, sublen);
                *distance = sublen[*length];
                if (*limit == ZOPFLI_MAX_MATCH && *length >= ZOPFLI_MIN_MATCH)
                {
                    assert(sublen[*length] == s->lmc->dist[lmcpos]);
                }
            }
            else
            {
                *distance = s->lmc->dist[lmcpos];
            }
            return 1;
        }
        /* Can't use much of the cache, since the "sublens" need to be calculated,
           but at  least we already know when to stop. */
        *limit = s->lmc->length[lmcpos];
    }

    return 0;
}

/*
Stores the found sublen, distance and length in the longest match cache, if
possible.
*/
static void __zopfli_StoreInLongestMatchCache(ZopfliBlockState *s, size_t pos, size_t limit, const unsigned short *sublen,
                                              unsigned short distance, unsigned short length)
{
    /* The LMC cache starts at the beginning of the block rather than the
       beginning of the whole array. */
    size_t lmcpos = pos - s->blockstart;

    /* Length > 0 and dist 0 is invalid combination, which indicates on purpose
       that this cache value is not filled in yet. */
    unsigned char cache_available = s->lmc && (s->lmc->length[lmcpos] == 0 || s->lmc->dist[lmcpos] != 0);

    if (s->lmc && limit == ZOPFLI_MAX_MATCH && sublen && !cache_available)
    {
        assert(s->lmc->length[lmcpos] == 1 && s->lmc->dist[lmcpos] == 0);
        s->lmc->dist[lmcpos] = length < ZOPFLI_MIN_MATCH ? 0 : distance;
        s->lmc->length[lmcpos] = length < ZOPFLI_MIN_MATCH ? 0 : length;
        assert(!(s->lmc->length[lmcpos] == 1 && s->lmc->dist[lmcpos] == 0));
        ZopfliSublenToCache(sublen, lmcpos, length, s->lmc);
    }
}

/*
Finds how long the match of scan and match is. Can be used to find how many
bytes starting from scan, and from match, are equal. Returns the last byte
after scan, which is still equal to the correspondinb byte after match.
scan is the position to compare
match is the earlier position to compare.
end is the last possible byte, beyond which to stop looking.
safe_end is a few (8) bytes before end, for comparing multiple bytes at once.
*/
static const unsigned char *__zopfli_GetMatch(const unsigned char *scan, const unsigned char *match, const unsigned char *end,
                                              const unsigned char *safe_end)
{

    if (sizeof(size_t) == 8)
    {
        /* 8 checks at once per array bounds check (size_t is 64-bit). */
        while (scan < safe_end && *((size_t *)scan) == *((size_t *)match))
        {
            scan += 8;
            match += 8;
        }
    }
    else if (sizeof(unsigned int) == 4)
    {
        /* 4 checks at once per array bounds check (unsigned int is 32-bit). */
        while (scan < safe_end && *((unsigned int *)scan) == *((unsigned int *)match))
        {
            scan += 4;
            match += 4;
        }
    }
    else
    {
        /* do 8 checks at once per array bounds check. */
        while (scan < safe_end && *scan == *match && *++scan == *++match && *++scan == *++match &&
               *++scan == *++match && *++scan == *++match && *++scan == *++match && *++scan == *++match &&
               *++scan == *++match)
        {
            scan++;
            match++;
        }
    }

    /* The remaining few bytes. */
    while (scan != end && *scan == *match)
    {
        scan++;
        match++;
    }

    return scan;
}

static void ZopfliFindLongestMatch(ZopfliBlockState *s, const ZopfliHash *h, const unsigned char *array, size_t pos,
                                   size_t size, size_t limit, unsigned short *sublen, unsigned short *distance,
                                   unsigned short *length)
{
    unsigned short hpos = pos & ZOPFLI_WINDOW_MASK, p, pp;
    unsigned short bestdist = 0;
    unsigned short bestlength = 1;
    const unsigned char *scan;
    const unsigned char *match;
    const unsigned char *arrayend;
    const unsigned char *arrayend_safe;
#if ZOPFLI_MAX_CHAIN_HITS < ZOPFLI_WINDOW_SIZE
    int chain_counter = ZOPFLI_MAX_CHAIN_HITS; /* For quitting early. */
#endif

    unsigned dist = 0; /* Not unsigned short on purpose. */

    int *hhead = h->head;
    unsigned short *hprev = h->prev;
    int *hhashval = h->hashval;
    int hval = h->val;

#ifdef ZOPFLI_LONGEST_MATCH_CACHE
    if (__zopfli_TryGetFromLongestMatchCache(s, pos, &limit, sublen, distance, length))
    {
        assert(pos + *length <= size);
        return;
    }
#endif

    assert(limit <= ZOPFLI_MAX_MATCH);
    assert(limit >= ZOPFLI_MIN_MATCH);
    assert(pos < size);

    if (size - pos < ZOPFLI_MIN_MATCH)
    {
        /* The rest of the code assumes there are at least ZOPFLI_MIN_MATCH bytes to
           try. */
        *length = 0;
        *distance = 0;
        return;
    }

    if (pos + limit > size)
    {
        limit = size - pos;
    }
    arrayend = &array[pos] + limit;
    arrayend_safe = arrayend - 8;

    assert(hval < 65536);

    pp = hhead[hval]; /* During the whole loop, p == hprev[pp]. */
    p = hprev[pp];

    assert(pp == hpos);

    dist = p < pp ? pp - p : ((ZOPFLI_WINDOW_SIZE - p) + pp);

    /* Go through all distances. */
    while (dist < ZOPFLI_WINDOW_SIZE)
    {
        unsigned short currentlength = 0;

        assert(p < ZOPFLI_WINDOW_SIZE);
        assert(p == hprev[pp]);
        assert(hhashval[p] == hval);

        if (dist > 0)
        {
            assert(pos < size);
            assert(dist <= pos);
            scan = &array[pos];
            match = &array[pos - dist];

            /* Testing the byte at position bestlength first, goes slightly faster. */
            if (pos + bestlength >= size || *(scan + bestlength) == *(match + bestlength))
            {

#ifdef ZOPFLI_HASH_SAME
                unsigned short same0 = h->same[pos & ZOPFLI_WINDOW_MASK];
                if (same0 > 2 && *scan == *match)
                {
                    unsigned short same1 = h->same[(pos - dist) & ZOPFLI_WINDOW_MASK];
                    unsigned short same = same0 < same1 ? same0 : same1;
                    if (same > limit)
                        same = limit;
                    scan += same;
                    match += same;
                }
#endif
                scan = __zopfli_GetMatch(scan, match, arrayend, arrayend_safe);
                currentlength = scan - &array[pos]; /* The found length. */
            }

            if (currentlength > bestlength)
            {
                if (sublen)
                {
                    unsigned short j;
                    for (j = bestlength + 1; j <= currentlength; j++)
                    {
                        sublen[j] = dist;
                    }
                }
                bestdist = dist;
                bestlength = currentlength;
                if (currentlength >= limit)
                    break;
            }
        }

#ifdef ZOPFLI_HASH_SAME_HASH
        /* Switch to the other hash once this will be more efficient. */
        if (hhead != h->head2 && bestlength >= h->same[hpos] && h->val2 == h->hashval2[p])
        {
            /* Now use the hash that encodes the length and first byte. */
            hhead = h->head2;
            hprev = h->prev2;
            hhashval = h->hashval2;
            hval = h->val2;
        }
#endif

        pp = p;
        p = hprev[p];
        if (p == pp)
            break; /* Uninited prev value. */

        dist += p < pp ? pp - p : ((ZOPFLI_WINDOW_SIZE - p) + pp);

#if ZOPFLI_MAX_CHAIN_HITS < ZOPFLI_WINDOW_SIZE
        chain_counter--;
        if (chain_counter <= 0)
            break;
#endif
    }

#ifdef ZOPFLI_LONGEST_MATCH_CACHE
    __zopfli_StoreInLongestMatchCache(s, pos, limit, sublen, bestdist, bestlength);
#endif

    assert(bestlength <= limit);

    *distance = bestdist;
    *length = bestlength;
    assert(pos + *length <= size);
}

/*
Performs the forward pass for "squeeze". Gets the most optimal length to reach
every byte from a previous byte, using cost calculations.
s: the ZopfliBlockState
in: the input data array
instart: where to start
inend: where to stop (not inclusive)
costmodel: function to calculate the cost of some lit/len/dist pair.
costcontext: abstract context for the costmodel function
length_array: output array of size (inend - instart) which will receive the best
    length to reach this byte from a previous byte.
returns the cost that was, according to the costmodel, needed to get to the end.
*/
static double __zopfli_GetBestLengths(ZopfliBlockState *s, const unsigned char *in, size_t instart, size_t inend,
                                      __zopfli_CostModelFun *costmodel, void *costcontext, unsigned short *length_array, ZopfliHash *h,
                                      float *costs)
{
    /* Best cost to get here so far. */
    size_t blocksize = inend - instart;
    size_t i = 0, k, kend;
    unsigned short leng;
    unsigned short dist;
    unsigned short sublen[259];
    size_t windowstart = instart > ZOPFLI_WINDOW_SIZE ? instart - ZOPFLI_WINDOW_SIZE : 0;
    double result;
    double mincost = __zopfli_GetCostModelMinCost(costmodel, costcontext);
    double mincostaddcostj;

    if (instart == inend)
        return 0;

    ZopfliResetHash(ZOPFLI_WINDOW_SIZE, h);
    ZopfliWarmupHash(in, windowstart, inend, h);
    for (i = windowstart; i < instart; i++)
    {
        ZopfliUpdateHash(in, i, inend, h);
    }

    for (i = 1; i < blocksize + 1; i++)
        costs[i] = ZOPFLI_LARGE_FLOAT;
    costs[0] = 0; /* Because it's the start. */
    length_array[0] = 0;

    for (i = instart; i < inend; i++)
    {
        size_t j = i - instart; /* Index in the costs array and length_array. */
        ZopfliUpdateHash(in, i, inend, h);

#ifdef ZOPFLI_SHORTCUT_LONG_REPETITIONS
        /* If we're in a long repetition of the same character and have more than
        ZOPFLI_MAX_MATCH characters before and after our position. */
        if (h->same[i & ZOPFLI_WINDOW_MASK] > ZOPFLI_MAX_MATCH * 2 && i > instart + ZOPFLI_MAX_MATCH + 1 &&
            i + ZOPFLI_MAX_MATCH * 2 + 1 < inend &&
            h->same[(i - ZOPFLI_MAX_MATCH) & ZOPFLI_WINDOW_MASK] > ZOPFLI_MAX_MATCH)
        {
            double symbolcost = costmodel(ZOPFLI_MAX_MATCH, 1, costcontext);
            /* Set the length to reach each one to ZOPFLI_MAX_MATCH, and the cost to
            the cost corresponding to that length. Doing this, we skip
            ZOPFLI_MAX_MATCH values to avoid calling ZopfliFindLongestMatch. */
            for (k = 0; k < ZOPFLI_MAX_MATCH; k++)
            {
                costs[j + ZOPFLI_MAX_MATCH] = costs[j] + symbolcost;
                length_array[j + ZOPFLI_MAX_MATCH] = ZOPFLI_MAX_MATCH;
                i++;
                j++;
                ZopfliUpdateHash(in, i, inend, h);
            }
        }
#endif

        ZopfliFindLongestMatch(s, h, in, i, inend, ZOPFLI_MAX_MATCH, sublen, &dist, &leng);

        /* Literal. */
        if (i + 1 <= inend)
        {
            double newCost = costmodel(in[i], 0, costcontext) + costs[j];
            assert(newCost >= 0);
            if (newCost < costs[j + 1])
            {
                costs[j + 1] = newCost;
                length_array[j + 1] = 1;
            }
        }
        /* Lengths. */
        kend = std::min((size_t)leng, inend - i);
        mincostaddcostj = mincost + costs[j];
        for (k = 3; k <= kend; k++)
        {
            double newCost;

            /* Calling the cost model is expensive, avoid this if we are already at
            the minimum possible cost that it can return. */
            if (costs[j + k] <= mincostaddcostj)
                continue;

            newCost = costmodel(k, sublen[k], costcontext) + costs[j];
            assert(newCost >= 0);
            if (newCost < costs[j + k])
            {
                assert(k <= ZOPFLI_MAX_MATCH);
                costs[j + k] = newCost;
                length_array[j + k] = k;
            }
        }
    }

    assert(costs[blocksize] >= 0);
    result = costs[blocksize];

    return result;
}

/*
Calculates the optimal path of lz77 lengths to use, from the calculated
length_array. The length_array must contain the optimal length to reach that
byte. The path will be filled with the lengths to use, so its data size will be
the amount of lz77 symbols.
*/
static void __zopfli_TraceBackwards(size_t size, const unsigned short *length_array, unsigned short **path, size_t *pathsize)
{
    size_t index = size;
    if (size == 0)
        return;
    for (;;)
    {
        ZOPFLI_APPEND_DATA(length_array[index], path, pathsize);
        assert(length_array[index] <= index);
        assert(length_array[index] <= ZOPFLI_MAX_MATCH);
        assert(length_array[index] != 0);
        index -= length_array[index];
        if (index == 0)
            break;
    }

    /* Mirror result. */
    for (index = 0; index < *pathsize / 2; index++)
    {
        unsigned short temp = (*path)[index];
        (*path)[index] = (*path)[*pathsize - index - 1];
        (*path)[*pathsize - index - 1] = temp;
    }
}

static void ZopfliVerifyLenDist(const unsigned char *data, size_t datasize, size_t pos, unsigned short dist,
                                unsigned short length)
{

    /* TODO(lode): make this only run in a debug compile, it's for assert only. */
    size_t i;

    assert(pos + length <= datasize);
    for (i = 0; i < length; i++)
    {
        if (data[pos - dist + i] != data[pos + i])
        {
            assert(data[pos - dist + i] == data[pos + i]);
            break;
        }
    }
}

/* Gets the symbol for the given dist, cfr. the DEFLATE spec. */
static int ZopfliGetDistSymbol(int dist)
{
#ifdef ZOPFLI_HAS_BUILTIN_CLZ
    if (dist < 5)
    {
        return dist - 1;
    }
    else
    {
        int l = (31 ^ __builtin_clz(dist - 1)); /* log2(dist - 1) */
        int r = ((dist - 1) >> (l - 1)) & 1;
        return l * 2 + r;
    }
#else
    if (dist < 193)
    {
        if (dist < 13)
        { /* dist 0..13. */
            if (dist < 5)
                return dist - 1;
            else if (dist < 7)
                return 4;
            else if (dist < 9)
                return 5;
            else
                return 6;
        }
        else
        { /* dist 13..193. */
            if (dist < 17)
                return 7;
            else if (dist < 25)
                return 8;
            else if (dist < 33)
                return 9;
            else if (dist < 49)
                return 10;
            else if (dist < 65)
                return 11;
            else if (dist < 97)
                return 12;
            else if (dist < 129)
                return 13;
            else
                return 14;
        }
    }
    else
    {
        if (dist < 2049)
        { /* dist 193..2049. */
            if (dist < 257)
                return 15;
            else if (dist < 385)
                return 16;
            else if (dist < 513)
                return 17;
            else if (dist < 769)
                return 18;
            else if (dist < 1025)
                return 19;
            else if (dist < 1537)
                return 20;
            else
                return 21;
        }
        else
        { /* dist 2049..32768. */
            if (dist < 3073)
                return 22;
            else if (dist < 4097)
                return 23;
            else if (dist < 6145)
                return 24;
            else if (dist < 8193)
                return 25;
            else if (dist < 12289)
                return 26;
            else if (dist < 16385)
                return 27;
            else if (dist < 24577)
                return 28;
            else
                return 29;
        }
    }
#endif
}

/*
Appends the length and distance to the LZ77 arrays of the ZopfliLZ77Store.
context must be a ZopfliLZ77Store*.
*/
static void ZopfliStoreLitLenDist(unsigned short length, unsigned short dist, size_t pos, ZopfliLZ77Store *store)
{
    size_t i;
    /* Needed for using ZOPFLI_APPEND_DATA multiple times. */
    size_t origsize = store->size;
    size_t llstart = ZOPFLI_NUM_LL * (origsize / ZOPFLI_NUM_LL);
    size_t dstart = ZOPFLI_NUM_D * (origsize / ZOPFLI_NUM_D);

    /* Everytime the index wraps around, a new cumulative histogram is made: we're
    keeping one histogram value per LZ77 symbol rather than a full histogram for
    each to save memory. */
    if (origsize % ZOPFLI_NUM_LL == 0)
    {
        size_t llsize = origsize;
        for (i = 0; i < ZOPFLI_NUM_LL; i++)
        {
            ZOPFLI_APPEND_DATA(origsize == 0 ? 0 : store->ll_counts[origsize - ZOPFLI_NUM_LL + i], &store->ll_counts,
                               &llsize);
        }
    }
    if (origsize % ZOPFLI_NUM_D == 0)
    {
        size_t dsize = origsize;
        for (i = 0; i < ZOPFLI_NUM_D; i++)
        {
            ZOPFLI_APPEND_DATA(origsize == 0 ? 0 : store->d_counts[origsize - ZOPFLI_NUM_D + i], &store->d_counts,
                               &dsize);
        }
    }

    ZOPFLI_APPEND_DATA(length, &store->litlens, &store->size);
    store->size = origsize;
    ZOPFLI_APPEND_DATA(dist, &store->dists, &store->size);
    store->size = origsize;
    ZOPFLI_APPEND_DATA(pos, &store->pos, &store->size);
    assert(length < 259);

    if (dist == 0)
    {
        store->size = origsize;
        ZOPFLI_APPEND_DATA(length, &store->ll_symbol, &store->size);
        store->size = origsize;
        ZOPFLI_APPEND_DATA(0, &store->d_symbol, &store->size);
        store->ll_counts[llstart + length]++;
    }
    else
    {
        store->size = origsize;
        ZOPFLI_APPEND_DATA(ZopfliGetLengthSymbol(length), &store->ll_symbol, &store->size);
        store->size = origsize;
        ZOPFLI_APPEND_DATA(ZopfliGetDistSymbol(dist), &store->d_symbol, &store->size);
        store->ll_counts[llstart + ZopfliGetLengthSymbol(length)]++;
        store->d_counts[dstart + ZopfliGetDistSymbol(dist)]++;
    }
}

static void __zopfli_FollowPath(ZopfliBlockState *s, const unsigned char *in, size_t instart, size_t inend, unsigned short *path,
                                size_t pathsize, ZopfliLZ77Store *store, ZopfliHash *h)
{
    size_t i, j, pos = 0;
    size_t windowstart = instart > ZOPFLI_WINDOW_SIZE ? instart - ZOPFLI_WINDOW_SIZE : 0;

    size_t total_length_test = 0;

    if (instart == inend)
        return;

    ZopfliResetHash(ZOPFLI_WINDOW_SIZE, h);
    ZopfliWarmupHash(in, windowstart, inend, h);
    for (i = windowstart; i < instart; i++)
    {
        ZopfliUpdateHash(in, i, inend, h);
    }

    pos = instart;
    for (i = 0; i < pathsize; i++)
    {
        unsigned short length = path[i];
        unsigned short dummy_length;
        unsigned short dist;
        assert(pos < inend);

        ZopfliUpdateHash(in, pos, inend, h);

        /* Add to output. */
        if (length >= ZOPFLI_MIN_MATCH)
        {
            /* Get the distance by recalculating longest match. The found length
            should match the length from the path. */
            ZopfliFindLongestMatch(s, h, in, pos, inend, length, 0, &dist, &dummy_length);
            assert(!(dummy_length != length && length > 2 && dummy_length > 2));
            ZopfliVerifyLenDist(in, inend, pos, dist, length);
            ZopfliStoreLitLenDist(length, dist, pos, store);
            total_length_test += length;
        }
        else
        {
            length = 1;
            ZopfliStoreLitLenDist(in[pos], 0, pos, store);
            total_length_test++;
        }

        assert(pos + length <= inend);
        for (j = 1; j < length; j++)
        {
            ZopfliUpdateHash(in, pos + j, inend, h);
        }

        pos += length;
    }
}

/*
Does a single run for ZopfliLZ77Optimal. For good compression, repeated runs
with updated statistics should be performed.
s: the block state
in: the input data array
instart: where to start
inend: where to stop (not inclusive)
path: pointer to dynamically allocated memory to store the path
pathsize: pointer to the size of the dynamic path array
length_array: array of size (inend - instart) used to store lengths
costmodel: function to use as the cost model for this squeeze run
costcontext: abstract context for the costmodel function
store: place to output the LZ77 data
returns the cost that was, according to the costmodel, needed to get to the end.
    This is not the actual cost.
*/
static double __zopfli_LZ77OptimalRun(ZopfliBlockState *s, const unsigned char *in, size_t instart, size_t inend,
                                      unsigned short **path, size_t *pathsize, unsigned short *length_array,
                                      __zopfli_CostModelFun *costmodel, void *costcontext, ZopfliLZ77Store *store, ZopfliHash *h,
                                      float *costs)
{
    double cost = __zopfli_GetBestLengths(s, in, instart, inend, costmodel, costcontext, length_array, h, costs);
    free(*path);
    *path = 0;
    *pathsize = 0;
    __zopfli_TraceBackwards(inend - instart, length_array, path, pathsize);
    __zopfli_FollowPath(s, in, instart, inend, *path, *pathsize, store, h);
    assert(cost < ZOPFLI_LARGE_FLOAT);
    return cost;
}

static void ZopfliCleanHash(ZopfliHash *h)
{
    free(h->head);
    free(h->prev);
    free(h->hashval);

#ifdef ZOPFLI_HASH_SAME_HASH
    free(h->head2);
    free(h->prev2);
    free(h->hashval2);
#endif

#ifdef ZOPFLI_HASH_SAME
    free(h->same);
#endif
}

static void ZopfliLZ77OptimalFixed(ZopfliBlockState *s, const unsigned char *in, size_t instart, size_t inend,
                                   ZopfliLZ77Store *store)
{
    /* Dist to get to here with smallest cost. */
    size_t blocksize = inend - instart;
    unsigned short *length_array = (unsigned short *)malloc(sizeof(unsigned short) * (blocksize + 1));
    unsigned short *path = 0;
    size_t pathsize = 0;
    ZopfliHash hash;
    ZopfliHash *h = &hash;
    float *costs = (float *)malloc(sizeof(float) * (blocksize + 1));

    if (!costs)
        exit(-1); /* Allocation failed. */
    if (!length_array)
        exit(-1); /* Allocation failed. */

    ZopfliAllocHash(ZOPFLI_WINDOW_SIZE, h);

    s->blockstart = instart;
    s->blockend = inend;

    /* Shortest path for fixed tree This one should give the shortest possible
    result for fixed tree, no repeated runs are needed since the tree is known. */
    __zopfli_LZ77OptimalRun(s, in, instart, inend, &path, &pathsize, length_array, __zopfli_GetCostFixed, 0, store, h, costs);

    free(length_array);
    free(path);
    free(costs);
    ZopfliCleanHash(h);
}

static size_t ZopfliLZ77GetByteRange(const ZopfliLZ77Store *lz77, size_t lstart, size_t lend)
{
    size_t l = lend - 1;
    if (lstart == lend)
        return 0;
    return lz77->pos[l] + ((lz77->dists[l] == 0) ? 1 : lz77->litlens[l]) - lz77->pos[lstart];
}

static void __zopfli_GetFixedTree(unsigned *ll_lengths, unsigned *d_lengths)
{
    size_t i;
    for (i = 0; i < 144; i++)
        ll_lengths[i] = 8;
    for (i = 144; i < 256; i++)
        ll_lengths[i] = 9;
    for (i = 256; i < 280; i++)
        ll_lengths[i] = 7;
    for (i = 280; i < 288; i++)
        ll_lengths[i] = 8;
    for (i = 0; i < 32; i++)
        d_lengths[i] = 5;
}

static void ZopfliLZ77GetHistogramAt(const ZopfliLZ77Store *lz77, size_t lpos, size_t *ll_counts, size_t *d_counts)
{
    /* The real histogram is created by using the histogram for this chunk, but
    all superfluous values of this chunk subtracted. */
    size_t llpos = ZOPFLI_NUM_LL * (lpos / ZOPFLI_NUM_LL);
    size_t dpos = ZOPFLI_NUM_D * (lpos / ZOPFLI_NUM_D);
    size_t i;
    for (i = 0; i < ZOPFLI_NUM_LL; i++)
    {
        ll_counts[i] = lz77->ll_counts[llpos + i];
    }
    for (i = lpos + 1; i < llpos + ZOPFLI_NUM_LL && i < lz77->size; i++)
    {
        ll_counts[lz77->ll_symbol[i]]--;
    }
    for (i = 0; i < ZOPFLI_NUM_D; i++)
    {
        d_counts[i] = lz77->d_counts[dpos + i];
    }
    for (i = lpos + 1; i < dpos + ZOPFLI_NUM_D && i < lz77->size; i++)
    {
        if (lz77->dists[i] != 0)
            d_counts[lz77->d_symbol[i]]--;
    }
}

static void ZopfliLZ77GetHistogram(const ZopfliLZ77Store *lz77, size_t lstart, size_t lend, size_t *ll_counts,
                                   size_t *d_counts)
{
    size_t i;
    if (lstart + ZOPFLI_NUM_LL * 3 > lend)
    {
        memset(ll_counts, 0, sizeof(*ll_counts) * ZOPFLI_NUM_LL);
        memset(d_counts, 0, sizeof(*d_counts) * ZOPFLI_NUM_D);
        for (i = lstart; i < lend; i++)
        {
            ll_counts[lz77->ll_symbol[i]]++;
            if (lz77->dists[i] != 0)
                d_counts[lz77->d_symbol[i]]++;
        }
    }
    else
    {
        /* Subtract the cumulative histograms at the end and the start to get the
        histogram for this range. */
        ZopfliLZ77GetHistogramAt(lz77, lend - 1, ll_counts, d_counts);
        if (lstart > 0)
        {
            size_t ll_counts2[ZOPFLI_NUM_LL];
            size_t d_counts2[ZOPFLI_NUM_D];
            ZopfliLZ77GetHistogramAt(lz77, lstart - 1, ll_counts2, d_counts2);

            for (i = 0; i < ZOPFLI_NUM_LL; i++)
            {
                ll_counts[i] -= ll_counts2[i];
            }
            for (i = 0; i < ZOPFLI_NUM_D; i++)
            {
                d_counts[i] -= d_counts2[i];
            }
        }
    }
}

/*
Comparator for sorting the leaves. Has the function signature for qsort.
*/
static int __zopfli_LeafComparator(const void *a, const void *b)
{
    return ((const __zopfli_Node *)a)->weight - ((const __zopfli_Node *)b)->weight;
}

/*
Initializes a chain node with the given values and marks it as in use.
*/
static void __zopfli_InitNode(size_t weight, int count, __zopfli_Node *tail, __zopfli_Node *node)
{
    node->weight = weight;
    node->count = count;
    node->tail = tail;
}

/*
Initializes each list with as lookahead chains the two leaves with lowest
weights.
*/
static void __zopfli_InitLists(__zopfli_NodePool *pool, const __zopfli_Node *leaves, int maxbits, __zopfli_Node *(*lists)[2])
{
    int i;
    __zopfli_Node *node0 = pool->next++;
    __zopfli_Node *node1 = pool->next++;
    __zopfli_InitNode(leaves[0].weight, 1, 0, node0);
    __zopfli_InitNode(leaves[1].weight, 2, 0, node1);
    for (i = 0; i < maxbits; i++)
    {
        lists[i][0] = node0;
        lists[i][1] = node1;
    }
}

/*
Performs a Boundary Package-Merge step. Puts a new chain in the given list. The
new chain is, depending on the weights, a leaf or a combination of two chains
from the previous list.
lists: The lists of chains.
maxbits: Number of lists.
leaves: The leaves, one per symbol.
numsymbols: Number of leaves.
pool: the node memory pool.
index: The index of the list in which a new chain or leaf is required.
*/
static void __zopfli_BoundaryPM(__zopfli_Node *(*lists)[2], __zopfli_Node *leaves, int numsymbols, __zopfli_NodePool *pool, int index)
{
    __zopfli_Node *newchain;
    __zopfli_Node *oldchain;
    int lastcount = lists[index][1]->count; /* Count of last chain of list. */

    if (index == 0 && lastcount >= numsymbols)
        return;

    newchain = pool->next++;
    oldchain = lists[index][1];

    /* These are set up before the recursive calls below, so that there is a list
    pointing to the new node, to let the garbage collection know it's in use. */
    lists[index][0] = oldchain;
    lists[index][1] = newchain;

    if (index == 0)
    {
        /* New leaf node in list 0. */
        __zopfli_InitNode(leaves[lastcount].weight, lastcount + 1, 0, newchain);
    }
    else
    {
        size_t sum = lists[index - 1][0]->weight + lists[index - 1][1]->weight;
        if (lastcount < numsymbols && sum > leaves[lastcount].weight)
        {
            /* New leaf inserted in list, so count is incremented. */
            __zopfli_InitNode(leaves[lastcount].weight, lastcount + 1, oldchain->tail, newchain);
        }
        else
        {
            __zopfli_InitNode(sum, lastcount, lists[index - 1][1], newchain);
            /* Two lookahead chains of previous list used up, create new ones. */
            __zopfli_BoundaryPM(lists, leaves, numsymbols, pool, index - 1);
            __zopfli_BoundaryPM(lists, leaves, numsymbols, pool, index - 1);
        }
    }
}

static void __zopfli_BoundaryPMFinal(__zopfli_Node *(*lists)[2], __zopfli_Node *leaves, int numsymbols, __zopfli_NodePool *pool, int index)
{
    int lastcount = lists[index][1]->count; /* Count of last chain of list. */

    size_t sum = lists[index - 1][0]->weight + lists[index - 1][1]->weight;

    if (lastcount < numsymbols && sum > leaves[lastcount].weight)
    {
        __zopfli_Node *newchain = pool->next;
        __zopfli_Node *oldchain = lists[index][1]->tail;

        lists[index][1] = newchain;
        newchain->count = lastcount + 1;
        newchain->tail = oldchain;
    }
    else
    {
        lists[index][1]->tail = lists[index - 1][1];
    }
}

/*
Converts result of boundary package-merge to the bitlengths. The result in the
last chain of the last list contains the amount of active leaves in each list.
chain: Chain to extract the bit length from (last chain from last list).
*/
static void __zopfli_ExtractBitLengths(__zopfli_Node *chain, __zopfli_Node *leaves, unsigned *bitlengths)
{
    int counts[16] = {0};
    unsigned end = 16;
    unsigned ptr = 15;
    unsigned value = 1;
    __zopfli_Node *node;
    int val;

    for (node = chain; node; node = node->tail)
    {
        counts[--end] = node->count;
    }

    val = counts[15];
    while (ptr >= end)
    {
        for (; val > counts[ptr - 1]; val--)
        {
            bitlengths[leaves[val - 1].count] = value;
        }
        ptr--;
        value++;
    }
}

static int ZopfliLengthLimitedCodeLengths(const size_t *frequencies, int n, int maxbits, unsigned *bitlengths)
{
    __zopfli_NodePool pool;
    int i;
    int numsymbols = 0; /* Amount of symbols with frequency > 0. */
    int numBoundaryPMRuns;
    __zopfli_Node *nodes;

    /* Array of lists of chains. Each list requires only two lookahead chains at
    a time, so each list is a array of two __zopfli_Node*'s. */
    __zopfli_Node *(*lists)[2];

    /* One leaf per symbol. Only numsymbols leaves will be used. */
    __zopfli_Node *leaves = (__zopfli_Node *)malloc(n * sizeof(*leaves));

    /* Initialize all bitlengths at 0. */
    for (i = 0; i < n; i++)
    {
        bitlengths[i] = 0;
    }

    /* Count used symbols and place them in the leaves. */
    for (i = 0; i < n; i++)
    {
        if (frequencies[i])
        {
            leaves[numsymbols].weight = frequencies[i];
            leaves[numsymbols].count = i; /* Index of symbol this leaf represents. */
            numsymbols++;
        }
    }

    /* Check special cases and error conditions. */
    if ((1 << maxbits) < numsymbols)
    {
        free(leaves);
        return 1; /* Error, too few maxbits to represent symbols. */
    }
    if (numsymbols == 0)
    {
        free(leaves);
        return 0; /* No symbols at all. OK. */
    }
    if (numsymbols == 1)
    {
        bitlengths[leaves[0].count] = 1;
        free(leaves);
        return 0; /* Only one symbol, give it bitlength 1, not 0. OK. */
    }
    if (numsymbols == 2)
    {
        bitlengths[leaves[0].count]++;
        bitlengths[leaves[1].count]++;
        free(leaves);
        return 0;
    }

    /* Sort the leaves from lightest to heaviest. Add count into the same
    variable for stable sorting. */
    for (i = 0; i < numsymbols; i++)
    {
        if (leaves[i].weight >= ((size_t)1 << (sizeof(leaves[0].weight) * CHAR_BIT - 9)))
        {
            free(leaves);
            return 1; /* Error, we need 9 bits for the count. */
        }
        leaves[i].weight = (leaves[i].weight << 9) | leaves[i].count;
    }
    qsort(leaves, numsymbols, sizeof(__zopfli_Node), __zopfli_LeafComparator);
    for (i = 0; i < numsymbols; i++)
    {
        leaves[i].weight >>= 9;
    }

    if (numsymbols - 1 < maxbits)
    {
        maxbits = numsymbols - 1;
    }

    /* Initialize node memory pool. */
    nodes = (__zopfli_Node *)malloc(maxbits * 2 * numsymbols * sizeof(__zopfli_Node));
    pool.next = nodes;

    lists = (__zopfli_Node * (*)[2]) malloc(maxbits * sizeof(*lists));
    __zopfli_InitLists(&pool, leaves, maxbits, lists);

    /* In the last list, 2 * numsymbols - 2 active chains need to be created. Two
    are already created in the initialization. Each __zopfli_BoundaryPM run creates one. */
    numBoundaryPMRuns = 2 * numsymbols - 4;
    for (i = 0; i < numBoundaryPMRuns - 1; i++)
    {
        __zopfli_BoundaryPM(lists, leaves, numsymbols, &pool, maxbits - 1);
    }
    __zopfli_BoundaryPMFinal(lists, leaves, numsymbols, &pool, maxbits - 1);

    __zopfli_ExtractBitLengths(lists[maxbits - 1][1], leaves, bitlengths);

    free(lists);
    free(leaves);
    free(nodes);
    return 0; /* OK. */
}

static void ZopfliCalculateBitLengths(const size_t *count, size_t n, int maxbits, unsigned *bitlengths)
{
    int error = ZopfliLengthLimitedCodeLengths(count, n, maxbits, bitlengths);
    (void)error;
    assert(!error);
}

/*
Ensures there are at least 2 distance codes to support buggy decoders.
Zlib 1.2.1 and below have a bug where it fails if there isn't at least 1
distance code (with length > 0), even though it's valid according to the
deflate spec to have 0 distance codes. On top of that, some mobile phones
require at least two distance codes. To support these decoders too (but
potentially at the cost of a few bytes), add dummy code lengths of 1.
References to this bug can be found in the changelog of
Zlib 1.2.2 and here: http://www.jonof.id.au/forum/index.php?topic=515.0.

d_lengths: the 32 lengths of the distance codes.
*/
static void __zopfli_PatchDistanceCodesForBuggyDecoders(unsigned *d_lengths)
{
    int num_dist_codes = 0; /* Amount of non-zero distance codes */
    int i;
    for (i = 0; i < 30 /* Ignore the two unused codes from the spec */; i++)
    {
        if (d_lengths[i])
            num_dist_codes++;
        if (num_dist_codes >= 2)
            return; /* Two or more codes is fine. */
    }

    if (num_dist_codes == 0)
    {
        d_lengths[0] = d_lengths[1] = 1;
    }
    else if (num_dist_codes == 1)
    {
        d_lengths[d_lengths[0] ? 1 : 0] = 1;
    }
}

static void ZopfliLengthsToSymbols(const unsigned *lengths, size_t n, unsigned maxbits, unsigned *symbols)
{
    size_t *bl_count = (size_t *)malloc(sizeof(size_t) * (maxbits + 1));
    size_t *next_code = (size_t *)malloc(sizeof(size_t) * (maxbits + 1));
    unsigned bits, i;
    unsigned code;

    for (i = 0; i < n; i++)
    {
        symbols[i] = 0;
    }

    /* 1) Count the number of codes for each code length. Let bl_count[N] be the
    number of codes of length N, N >= 1. */
    for (bits = 0; bits <= maxbits; bits++)
    {
        bl_count[bits] = 0;
    }
    for (i = 0; i < n; i++)
    {
        assert(lengths[i] <= maxbits);
        bl_count[lengths[i]]++;
    }
    /* 2) Find the numerical value of the smallest code for each code length. */
    code = 0;
    bl_count[0] = 0;
    for (bits = 1; bits <= maxbits; bits++)
    {
        code = (code + bl_count[bits - 1]) << 1;
        next_code[bits] = code;
    }
    /* 3) Assign numerical values to all codes, using consecutive values for all
    codes of the same length with the base values determined at step 2. */
    for (i = 0; i < n; i++)
    {
        unsigned len = lengths[i];
        if (len != 0)
        {
            symbols[i] = next_code[len];
            next_code[len]++;
        }
    }

    free(bl_count);
    free(next_code);
}

static void __zopfli_AddBits(unsigned symbol, unsigned length, unsigned char *bp, unsigned char **out, size_t *outsize)
{
    /* TODO(lode): make more efficient (add more bits at once). */
    unsigned i;
    for (i = 0; i < length; i++)
    {
        unsigned bit = (symbol >> i) & 1;
        if (*bp == 0)
            ZOPFLI_APPEND_DATA(0, out, outsize);
        (*out)[*outsize - 1] |= bit << *bp;
        *bp = (*bp + 1) & 7;
    }
}

/*
Adds bits, like __zopfli_AddBits, but the order is inverted. The deflate specification
uses both orders in one standard.
*/
static void __zopfli_AddHuffmanBits(unsigned symbol, unsigned length, unsigned char *bp, unsigned char **out, size_t *outsize)
{
    /* TODO(lode): make more efficient (add more bits at once). */
    unsigned i;
    for (i = 0; i < length; i++)
    {
        unsigned bit = (symbol >> (length - i - 1)) & 1;
        if (*bp == 0)
            ZOPFLI_APPEND_DATA(0, out, outsize);
        (*out)[*outsize - 1] |= bit << *bp;
        *bp = (*bp + 1) & 7;
    }
}

/*
Encodes the Huffman tree and returns how many bits its encoding takes. If out
is a null pointer, only returns the size and runs faster.
*/
static size_t __zopfli_EncodeTree(const unsigned *ll_lengths, const unsigned *d_lengths, int use_16, int use_17, int use_18,
                                  unsigned char *bp, unsigned char **out, size_t *outsize)
{
    unsigned lld_total; /* Total amount of literal, length, distance codes. */
    /* Runlength encoded version of lengths of litlen and dist trees. */
    unsigned *rle = 0;
    unsigned *rle_bits = 0;   /* Extra bits for rle values 16, 17 and 18. */
    size_t rle_size = 0;      /* Size of rle array. */
    size_t rle_bits_size = 0; /* Should have same value as rle_size. */
    unsigned hlit = 29;       /* 286 - 257 */
    unsigned hdist = 29;      /* 32 - 1, but gzip does not like hdist > 29.*/
    unsigned hclen;
    unsigned hlit2;
    size_t i, j;
    size_t clcounts[19];
    unsigned clcl[19]; /* Code length code lengths. */
    unsigned clsymbols[19];
    /* The order in which code length code lengths are encoded as per deflate. */
    static const unsigned order[19] = {16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15};
    int size_only = !out;
    size_t result_size = 0;

    for (i = 0; i < 19; i++)
        clcounts[i] = 0;

    /* Trim zeros. */
    while (hlit > 0 && ll_lengths[257 + hlit - 1] == 0)
        hlit--;
    while (hdist > 0 && d_lengths[1 + hdist - 1] == 0)
        hdist--;
    hlit2 = hlit + 257;

    lld_total = hlit2 + hdist + 1;

    for (i = 0; i < lld_total; i++)
    {
        /* This is an encoding of a huffman tree, so now the length is a symbol */
        unsigned char symbol = i < hlit2 ? ll_lengths[i] : d_lengths[i - hlit2];
        unsigned count = 1;
        if (use_16 || (symbol == 0 && (use_17 || use_18)))
        {
            for (j = i + 1; j < lld_total && symbol == (j < hlit2 ? ll_lengths[j] : d_lengths[j - hlit2]); j++)
            {
                count++;
            }
        }
        i += count - 1;

        /* Repetitions of zeroes */
        if (symbol == 0 && count >= 3)
        {
            if (use_18)
            {
                while (count >= 11)
                {
                    unsigned count2 = count > 138 ? 138 : count;
                    if (!size_only)
                    {
                        ZOPFLI_APPEND_DATA(18, &rle, &rle_size);
                        ZOPFLI_APPEND_DATA(count2 - 11, &rle_bits, &rle_bits_size);
                    }
                    clcounts[18]++;
                    count -= count2;
                }
            }
            if (use_17)
            {
                while (count >= 3)
                {
                    unsigned count2 = count > 10 ? 10 : count;
                    if (!size_only)
                    {
                        ZOPFLI_APPEND_DATA(17, &rle, &rle_size);
                        ZOPFLI_APPEND_DATA(count2 - 3, &rle_bits, &rle_bits_size);
                    }
                    clcounts[17]++;
                    count -= count2;
                }
            }
        }

        /* Repetitions of any symbol */
        if (use_16 && count >= 4)
        {
            count--; /* Since the first one is hardcoded. */
            clcounts[symbol]++;
            if (!size_only)
            {
                ZOPFLI_APPEND_DATA(symbol, &rle, &rle_size);
                ZOPFLI_APPEND_DATA(0, &rle_bits, &rle_bits_size);
            }
            while (count >= 3)
            {
                unsigned count2 = count > 6 ? 6 : count;
                if (!size_only)
                {
                    ZOPFLI_APPEND_DATA(16, &rle, &rle_size);
                    ZOPFLI_APPEND_DATA(count2 - 3, &rle_bits, &rle_bits_size);
                }
                clcounts[16]++;
                count -= count2;
            }
        }

        /* No or insufficient repetition */
        clcounts[symbol] += count;
        while (count > 0)
        {
            if (!size_only)
            {
                ZOPFLI_APPEND_DATA(symbol, &rle, &rle_size);
                ZOPFLI_APPEND_DATA(0, &rle_bits, &rle_bits_size);
            }
            count--;
        }
    }

    ZopfliCalculateBitLengths(clcounts, 19, 7, clcl);
    if (!size_only)
        ZopfliLengthsToSymbols(clcl, 19, 7, clsymbols);

    hclen = 15;
    /* Trim zeros. */
    while (hclen > 0 && clcounts[order[hclen + 4 - 1]] == 0)
        hclen--;

    if (!size_only)
    {
        __zopfli_AddBits(hlit, 5, bp, out, outsize);
        __zopfli_AddBits(hdist, 5, bp, out, outsize);
        __zopfli_AddBits(hclen, 4, bp, out, outsize);

        for (i = 0; i < hclen + 4; i++)
        {
            __zopfli_AddBits(clcl[order[i]], 3, bp, out, outsize);
        }

        for (i = 0; i < rle_size; i++)
        {
            unsigned symbol = clsymbols[rle[i]];
            __zopfli_AddHuffmanBits(symbol, clcl[rle[i]], bp, out, outsize);
            /* Extra bits. */
            if (rle[i] == 16)
                __zopfli_AddBits(rle_bits[i], 2, bp, out, outsize);
            else if (rle[i] == 17)
                __zopfli_AddBits(rle_bits[i], 3, bp, out, outsize);
            else if (rle[i] == 18)
                __zopfli_AddBits(rle_bits[i], 7, bp, out, outsize);
        }
    }

    result_size += 14;              /* hlit, hdist, hclen bits */
    result_size += (hclen + 4) * 3; /* clcl bits */
    for (i = 0; i < 19; i++)
    {
        result_size += clcl[i] * clcounts[i];
    }
    /* Extra bits. */
    result_size += clcounts[16] * 2;
    result_size += clcounts[17] * 3;
    result_size += clcounts[18] * 7;

    /* Note: in case of "size_only" these are null pointers so no effect. */
    free(rle);
    free(rle_bits);

    return result_size;
}

/*
Gives the exact size of the tree, in bits, as it will be encoded in DEFLATE.
*/
static size_t __zopfli_CalculateTreeSize(const unsigned *ll_lengths, const unsigned *d_lengths)
{
    size_t result = 0;
    int i;

    for (i = 0; i < 8; i++)
    {
        size_t size = __zopfli_EncodeTree(ll_lengths, d_lengths, i & 1, i & 2, i & 4, 0, 0, 0);
        if (result == 0 || size < result)
            result = size;
    }

    return result;
}

/* Gets the amount of extra bits for the given length symbol. */
static int ZopfliGetLengthSymbolExtraBits(int s)
{
    static const int table[29] = {0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2,
                                  2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0};
    return table[s - 257];
}

/* Gets the amount of extra bits for the given distance symbol. */
static int ZopfliGetDistSymbolExtraBits(int s)
{
    static const int table[30] = {0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6,
                                  6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13};
    return table[s];
}

/*
Same as __zopfli_CalculateBlockSymbolSize, but for block size smaller than histogram
size.
*/
static size_t __zopfli_CalculateBlockSymbolSizeSmall(const unsigned *ll_lengths, const unsigned *d_lengths,
                                                     const ZopfliLZ77Store *lz77, size_t lstart, size_t lend)
{
    size_t result = 0;
    size_t i;
    for (i = lstart; i < lend; i++)
    {
        assert(i < lz77->size);
        assert(lz77->litlens[i] < 259);
        if (lz77->dists[i] == 0)
        {
            result += ll_lengths[lz77->litlens[i]];
        }
        else
        {
            int ll_symbol = ZopfliGetLengthSymbol(lz77->litlens[i]);
            int d_symbol = ZopfliGetDistSymbol(lz77->dists[i]);
            result += ll_lengths[ll_symbol];
            result += d_lengths[d_symbol];
            result += ZopfliGetLengthSymbolExtraBits(ll_symbol);
            result += ZopfliGetDistSymbolExtraBits(d_symbol);
        }
    }
    result += ll_lengths[256]; /*end symbol*/
    return result;
}

/*
Same as __zopfli_CalculateBlockSymbolSize, but with the histogram provided by the caller.
*/
static size_t __zopfli_CalculateBlockSymbolSizeGivenCounts(const size_t *ll_counts, const size_t *d_counts,
                                                           const unsigned *ll_lengths, const unsigned *d_lengths,
                                                           const ZopfliLZ77Store *lz77, size_t lstart, size_t lend)
{
    size_t result = 0;
    size_t i;
    if (lstart + ZOPFLI_NUM_LL * 3 > lend)
    {
        return __zopfli_CalculateBlockSymbolSizeSmall(ll_lengths, d_lengths, lz77, lstart, lend);
    }
    else
    {
        for (i = 0; i < 256; i++)
        {
            result += ll_lengths[i] * ll_counts[i];
        }
        for (i = 257; i < 286; i++)
        {
            result += ll_lengths[i] * ll_counts[i];
            result += ZopfliGetLengthSymbolExtraBits(i) * ll_counts[i];
        }
        for (i = 0; i < 30; i++)
        {
            result += d_lengths[i] * d_counts[i];
            result += ZopfliGetDistSymbolExtraBits(i) * d_counts[i];
        }
        result += ll_lengths[256]; /*end symbol*/
        return result;
    }
}

static size_t __zopfli_AbsDiff(size_t x, size_t y)
{
    if (x > y)
        return x - y;
    else
        return y - x;
}

/*
Changes the population counts in a way that the consequent Huffman tree
compression, especially its rle-part, will be more likely to compress this data
more efficiently. length contains the size of the histogram.
*/
static void __zopfli_OptimizeHuffmanForRle(int length, size_t *counts)
{
    int i, k, stride;
    size_t symbol, sum, limit;
    int *good_for_rle;

    /* 1) We don't want to touch the trailing zeros. We may break the
    rules of the format by adding more data in the distance codes. */
    for (; length >= 0; --length)
    {
        if (length == 0)
        {
            return;
        }
        if (counts[length - 1] != 0)
        {
            /* Now counts[0..length - 1] does not have trailing zeros. */
            break;
        }
    }
    /* 2) Let's mark all population counts that already can be encoded
    with an rle code.*/
    good_for_rle = (int *)malloc((unsigned)length * sizeof(int));
    for (i = 0; i < length; ++i)
        good_for_rle[i] = 0;

    /* Let's not spoil any of the existing good rle codes.
    Mark any seq of 0's that is longer than 5 as a good_for_rle.
    Mark any seq of non-0's that is longer than 7 as a good_for_rle.*/
    symbol = counts[0];
    stride = 0;
    for (i = 0; i < length + 1; ++i)
    {
        if (i == length || counts[i] != symbol)
        {
            if ((symbol == 0 && stride >= 5) || (symbol != 0 && stride >= 7))
            {
                for (k = 0; k < stride; ++k)
                {
                    good_for_rle[i - k - 1] = 1;
                }
            }
            stride = 1;
            if (i != length)
            {
                symbol = counts[i];
            }
        }
        else
        {
            ++stride;
        }
    }

    /* 3) Let's replace those population counts that lead to more rle codes. */
    stride = 0;
    limit = counts[0];
    sum = 0;
    for (i = 0; i < length + 1; ++i)
    {
        if (i == length ||
            good_for_rle[i]
            /* Heuristic for selecting the stride ranges to collapse. */
            || __zopfli_AbsDiff(counts[i], limit) >= 4)
        {
            if (stride >= 4 || (stride >= 3 && sum == 0))
            {
                /* The stride must end, collapse what we have, if we have enough (4). */
                int count = (sum + stride / 2) / stride;
                if (count < 1)
                    count = 1;
                if (sum == 0)
                {
                    /* Don't make an all zeros stride to be upgraded to ones. */
                    count = 0;
                }
                for (k = 0; k < stride; ++k)
                {
                    /* We don't want to change value at counts[i],
                    that is already belonging to the next stride. Thus - 1. */
                    counts[i - k - 1] = count;
                }
            }
            stride = 0;
            sum = 0;
            if (i < length - 3)
            {
                /* All interesting strides have a count of at least 4,
                at least when non-zeros. */
                limit = (counts[i] + counts[i + 1] + counts[i + 2] + counts[i + 3] + 2) / 4;
            }
            else if (i < length)
            {
                limit = counts[i];
            }
            else
            {
                limit = 0;
            }
        }
        ++stride;
        if (i != length)
        {
            sum += counts[i];
        }
    }

    free(good_for_rle);
}

/*
Tries out __zopfli_OptimizeHuffmanForRle for this block, if the result is smaller,
uses it, otherwise keeps the original. Returns size of encoded tree and data in
bits, not including the 3-bit block header.
*/
static double __zopfli_TryOptimizeHuffmanForRle(const ZopfliLZ77Store *lz77, size_t lstart, size_t lend, const size_t *ll_counts,
                                                const size_t *d_counts, unsigned *ll_lengths, unsigned *d_lengths)
{
    size_t ll_counts2[ZOPFLI_NUM_LL];
    size_t d_counts2[ZOPFLI_NUM_D];
    unsigned ll_lengths2[ZOPFLI_NUM_LL];
    unsigned d_lengths2[ZOPFLI_NUM_D];
    double treesize;
    double datasize;
    double treesize2;
    double datasize2;

    treesize = __zopfli_CalculateTreeSize(ll_lengths, d_lengths);
    datasize = __zopfli_CalculateBlockSymbolSizeGivenCounts(ll_counts, d_counts, ll_lengths, d_lengths, lz77, lstart, lend);

    memcpy(ll_counts2, ll_counts, sizeof(ll_counts2));
    memcpy(d_counts2, d_counts, sizeof(d_counts2));
    __zopfli_OptimizeHuffmanForRle(ZOPFLI_NUM_LL, ll_counts2);
    __zopfli_OptimizeHuffmanForRle(ZOPFLI_NUM_D, d_counts2);
    ZopfliCalculateBitLengths(ll_counts2, ZOPFLI_NUM_LL, 15, ll_lengths2);
    ZopfliCalculateBitLengths(d_counts2, ZOPFLI_NUM_D, 15, d_lengths2);
    __zopfli_PatchDistanceCodesForBuggyDecoders(d_lengths2);

    treesize2 = __zopfli_CalculateTreeSize(ll_lengths2, d_lengths2);
    datasize2 = __zopfli_CalculateBlockSymbolSizeGivenCounts(ll_counts, d_counts, ll_lengths2, d_lengths2, lz77, lstart, lend);

    if (treesize2 + datasize2 < treesize + datasize)
    {
        memcpy(ll_lengths, ll_lengths2, sizeof(ll_lengths2));
        memcpy(d_lengths, d_lengths2, sizeof(d_lengths2));
        return treesize2 + datasize2;
    }
    return treesize + datasize;
}

/*
Calculates the bit lengths for the symbols for dynamic blocks. Chooses bit
lengths that give the smallest size of tree encoding + encoding of all the
symbols to have smallest output size. This are not necessarily the ideal Huffman
bit lengths. Returns size of encoded tree and data in bits, not including the
3-bit block header.
*/
static double __zopfli_GetDynamicLengths(const ZopfliLZ77Store *lz77, size_t lstart, size_t lend, unsigned *ll_lengths,
                                         unsigned *d_lengths)
{
    size_t ll_counts[ZOPFLI_NUM_LL];
    size_t d_counts[ZOPFLI_NUM_D];

    ZopfliLZ77GetHistogram(lz77, lstart, lend, ll_counts, d_counts);
    ll_counts[256] = 1; /* End symbol. */
    ZopfliCalculateBitLengths(ll_counts, ZOPFLI_NUM_LL, 15, ll_lengths);
    ZopfliCalculateBitLengths(d_counts, ZOPFLI_NUM_D, 15, d_lengths);
    __zopfli_PatchDistanceCodesForBuggyDecoders(d_lengths);
    return __zopfli_TryOptimizeHuffmanForRle(lz77, lstart, lend, ll_counts, d_counts, ll_lengths, d_lengths);
}

static void __zopfli_AddDynamicTree(const unsigned *ll_lengths, const unsigned *d_lengths, unsigned char *bp,
                                    unsigned char **out, size_t *outsize)
{
    int i;
    int best = 0;
    size_t bestsize = 0;

    for (i = 0; i < 8; i++)
    {
        size_t size = __zopfli_EncodeTree(ll_lengths, d_lengths, i & 1, i & 2, i & 4, 0, 0, 0);
        if (bestsize == 0 || size < bestsize)
        {
            bestsize = size;
            best = i;
        }
    }

    __zopfli_EncodeTree(ll_lengths, d_lengths, best & 1, best & 2, best & 4, bp, out, outsize);
}

/* Gets value of the extra bits for the given length, cfr. the DEFLATE spec. */
static int ZopfliGetLengthExtraBitsValue(int l)
{
    static const int table[259] = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 2, 3, 0, 1, 2,
        3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7, 0,
        1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
        11, 12, 13, 14, 15, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 1, 2, 3, 4,
        5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
        15, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
        25, 26, 27, 28, 29, 30, 31, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
        19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
        13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 0, 1, 2, 3, 4, 5, 6,
        7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 0};
    return table[l];
}

/* Gets value of the extra bits for the given dist, cfr. the DEFLATE spec. */
static int ZopfliGetDistExtraBitsValue(int dist)
{
#ifdef ZOPFLI_HAS_BUILTIN_CLZ
    if (dist < 5)
    {
        return 0;
    }
    else
    {
        int l = 31 ^ __builtin_clz(dist - 1); /* log2(dist - 1) */
        return (dist - (1 + (1 << l))) & ((1 << (l - 1)) - 1);
    }
#else
    if (dist < 5)
        return 0;
    else if (dist < 9)
        return (dist - 5) & 1;
    else if (dist < 17)
        return (dist - 9) & 3;
    else if (dist < 33)
        return (dist - 17) & 7;
    else if (dist < 65)
        return (dist - 33) & 15;
    else if (dist < 129)
        return (dist - 65) & 31;
    else if (dist < 257)
        return (dist - 129) & 63;
    else if (dist < 513)
        return (dist - 257) & 127;
    else if (dist < 1025)
        return (dist - 513) & 255;
    else if (dist < 2049)
        return (dist - 1025) & 511;
    else if (dist < 4097)
        return (dist - 2049) & 1023;
    else if (dist < 8193)
        return (dist - 4097) & 2047;
    else if (dist < 16385)
        return (dist - 8193) & 4095;
    else
        return (dist - 16385) & 8191;
#endif
}

/*
Adds all lit/len and dist codes from the lists as huffman symbols. Does not add
end code 256. expected_data_size is the uncompressed block size, used for
assert, but you can set it to 0 to not do the assertion.
*/
static void __zopfli_AddLZ77Data(const ZopfliLZ77Store *lz77, size_t lstart, size_t lend, size_t expected_data_size,
                                 const unsigned *ll_symbols, const unsigned *ll_lengths, const unsigned *d_symbols,
                                 const unsigned *d_lengths, unsigned char *bp, unsigned char **out, size_t *outsize)
{
    size_t testlength = 0;
    size_t i;

    for (i = lstart; i < lend; i++)
    {
        unsigned dist = lz77->dists[i];
        unsigned litlen = lz77->litlens[i];
        if (dist == 0)
        {
            assert(litlen < 256);
            assert(ll_lengths[litlen] > 0);
            __zopfli_AddHuffmanBits(ll_symbols[litlen], ll_lengths[litlen], bp, out, outsize);
            testlength++;
        }
        else
        {
            unsigned lls = ZopfliGetLengthSymbol(litlen);
            unsigned ds = ZopfliGetDistSymbol(dist);
            assert(litlen >= 3 && litlen <= 288);
            assert(ll_lengths[lls] > 0);
            assert(d_lengths[ds] > 0);
            __zopfli_AddHuffmanBits(ll_symbols[lls], ll_lengths[lls], bp, out, outsize);
            __zopfli_AddBits(ZopfliGetLengthExtraBitsValue(litlen), ZopfliGetLengthExtraBits(litlen), bp, out, outsize);
            __zopfli_AddHuffmanBits(d_symbols[ds], d_lengths[ds], bp, out, outsize);
            __zopfli_AddBits(ZopfliGetDistExtraBitsValue(dist), ZopfliGetDistExtraBits(dist), bp, out, outsize);
            testlength += litlen;
        }
    }
    assert(expected_data_size == 0 || testlength == expected_data_size);
}

/*
Adds a deflate block with the given LZ77 data to the output.
options: global program options
btype: the block type, must be 1 or 2
final: whether to set the "final" bit on this block, must be the last block
litlens: literal/length array of the LZ77 data, in the same format as in
    ZopfliLZ77Store.
dists: distance array of the LZ77 data, in the same format as in
    ZopfliLZ77Store.
lstart: where to start in the LZ77 data
lend: where to end in the LZ77 data (not inclusive)
expected_data_size: the uncompressed block size, used for assert, but you can
  set it to 0 to not do the assertion.
bp: output bit pointer
out: dynamic output array to append to
outsize: dynamic output array size
*/
static void __zopfli_AddLZ77Block(const ZopfliOptions *options, int btype, int final, const ZopfliLZ77Store *lz77, size_t lstart,
                                  size_t lend, size_t expected_data_size, unsigned char *bp, unsigned char **out,
                                  size_t *outsize)
{
    unsigned ll_lengths[ZOPFLI_NUM_LL];
    unsigned d_lengths[ZOPFLI_NUM_D];
    unsigned ll_symbols[ZOPFLI_NUM_LL];
    unsigned d_symbols[ZOPFLI_NUM_D];
    size_t detect_block_size = *outsize;
    size_t compressed_size;
    size_t uncompressed_size = 0;
    size_t i;
    if (btype == 0)
    {
        size_t length = ZopfliLZ77GetByteRange(lz77, lstart, lend);
        size_t pos = lstart == lend ? 0 : lz77->pos[lstart];
        size_t end = pos + length;
        __zopfli_AddNonCompressedBlock(options, final, lz77->data, pos, end, bp, out, outsize);
        return;
    }

    __zopfli_AddBit(final, bp, out, outsize);
    __zopfli_AddBit(btype & 1, bp, out, outsize);
    __zopfli_AddBit((btype & 2) >> 1, bp, out, outsize);

    if (btype == 1)
    {
        /* Fixed block. */
        __zopfli_GetFixedTree(ll_lengths, d_lengths);
    }
    else
    {
        /* Dynamic block. */
        unsigned detect_tree_size;
        assert(btype == 2);

        __zopfli_GetDynamicLengths(lz77, lstart, lend, ll_lengths, d_lengths);

        detect_tree_size = *outsize;
        __zopfli_AddDynamicTree(ll_lengths, d_lengths, bp, out, outsize);
        if (options->verbose)
        {
            fprintf(stderr, "treesize: %d\n", (int)(*outsize - detect_tree_size));
        }
    }

    ZopfliLengthsToSymbols(ll_lengths, ZOPFLI_NUM_LL, 15, ll_symbols);
    ZopfliLengthsToSymbols(d_lengths, ZOPFLI_NUM_D, 15, d_symbols);

    detect_block_size = *outsize;
    __zopfli_AddLZ77Data(lz77, lstart, lend, expected_data_size, ll_symbols, ll_lengths, d_symbols, d_lengths, bp, out, outsize);
    /* End symbol. */
    __zopfli_AddHuffmanBits(ll_symbols[256], ll_lengths[256], bp, out, outsize);

    for (i = lstart; i < lend; i++)
    {
        uncompressed_size += lz77->dists[i] == 0 ? 1 : lz77->litlens[i];
    }
    compressed_size = *outsize - detect_block_size;
    if (options->verbose)
    {
        fprintf(stderr, "compressed block size: %d (%dk) (unc: %d)\n", (int)compressed_size,
                (int)(compressed_size / 1024), (int)(uncompressed_size));
    }
}

static void ZopfliCleanCache(ZopfliLongestMatchCache *lmc)
{
    free(lmc->length);
    free(lmc->dist);
    free(lmc->sublen);
}

static void ZopfliCleanBlockState(ZopfliBlockState *s)
{
#ifdef ZOPFLI_LONGEST_MATCH_CACHE
    if (s->lmc)
    {
        ZopfliCleanCache(s->lmc);
        free(s->lmc);
    }
#endif
}

static void ZopfliCleanLZ77Store(ZopfliLZ77Store *store)
{
    free(store->litlens);
    free(store->dists);
    free(store->pos);
    free(store->ll_symbol);
    free(store->d_symbol);
    free(store->ll_counts);
    free(store->d_counts);
}

/*
Gets a score of the length given the distance. Typically, the score of the
length is the length itself, but if the distance is very long, decrease the
score of the length a bit to make up for the fact that long distances use large
amounts of extra bits.

This is not an accurate score, it is a heuristic only for the greedy LZ77
implementation. More accurate cost models are employed later. Making this
heuristic more accurate may hurt rather than improve compression.

The two direct uses of this heuristic are:
-avoid using a length of 3 in combination with a long distance. This only has
 an effect if length == 3.
-make a slightly better choice between the two options of the lazy matching.

Indirectly, this affects:
-the block split points if the default of block splitting first is used, in a
 rather unpredictable way
-the first zopfli run, so it affects the chance of the first run being closer
 to the optimal output
*/
static int __zopfli_GetLengthScore(int length, int distance)
{
    /*
    At 1024, the distance uses 9+ extra bits and this seems to be the sweet spot
    on tested files.
    */
    return distance > 1024 ? length - 1 : length;
}

static void ZopfliLZ77Greedy(ZopfliBlockState *s, const unsigned char *in, size_t instart, size_t inend,
                             ZopfliLZ77Store *store, ZopfliHash *h)
{
    size_t i = 0, j;
    unsigned short leng;
    unsigned short dist;
    int lengthscore;
    size_t windowstart = instart > ZOPFLI_WINDOW_SIZE ? instart - ZOPFLI_WINDOW_SIZE : 0;
    unsigned short dummysublen[259];

#ifdef ZOPFLI_LAZY_MATCHING
    /* Lazy matching. */
    unsigned prev_length = 0;
    unsigned prev_match = 0;
    int prevlengthscore;
    int match_available = 0;
#endif

    if (instart == inend)
        return;

    ZopfliResetHash(ZOPFLI_WINDOW_SIZE, h);
    ZopfliWarmupHash(in, windowstart, inend, h);
    for (i = windowstart; i < instart; i++)
    {
        ZopfliUpdateHash(in, i, inend, h);
    }

    for (i = instart; i < inend; i++)
    {
        ZopfliUpdateHash(in, i, inend, h);

        ZopfliFindLongestMatch(s, h, in, i, inend, ZOPFLI_MAX_MATCH, dummysublen, &dist, &leng);
        lengthscore = __zopfli_GetLengthScore(leng, dist);

#ifdef ZOPFLI_LAZY_MATCHING
        /* Lazy matching. */
        prevlengthscore = __zopfli_GetLengthScore(prev_length, prev_match);
        if (match_available)
        {
            match_available = 0;
            if (lengthscore > prevlengthscore + 1)
            {
                ZopfliStoreLitLenDist(in[i - 1], 0, i - 1, store);
                if (lengthscore >= ZOPFLI_MIN_MATCH && leng < ZOPFLI_MAX_MATCH)
                {
                    match_available = 1;
                    prev_length = leng;
                    prev_match = dist;
                    continue;
                }
            }
            else
            {
                /* Add previous to output. */
                leng = prev_length;
                dist = prev_match;
                lengthscore = prevlengthscore;
                /* Add to output. */
                ZopfliVerifyLenDist(in, inend, i - 1, dist, leng);
                ZopfliStoreLitLenDist(leng, dist, i - 1, store);
                for (j = 2; j < leng; j++)
                {
                    assert(i < inend);
                    i++;
                    ZopfliUpdateHash(in, i, inend, h);
                }
                continue;
            }
        }
        else if (lengthscore >= ZOPFLI_MIN_MATCH && leng < ZOPFLI_MAX_MATCH)
        {
            match_available = 1;
            prev_length = leng;
            prev_match = dist;
            continue;
        }
        /* End of lazy matching. */
#endif

        /* Add to output. */
        if (lengthscore >= ZOPFLI_MIN_MATCH)
        {
            ZopfliVerifyLenDist(in, inend, i, dist, leng);
            ZopfliStoreLitLenDist(leng, dist, i, store);
        }
        else
        {
            leng = 1;
            ZopfliStoreLitLenDist(in[i], 0, i, store);
        }
        for (j = 1; j < leng; j++)
        {
            assert(i < inend);
            i++;
            ZopfliUpdateHash(in, i, inend, h);
        }
    }
}

/*
Calculates size of the part after the header and tree of an LZ77 block, in bits.
*/
static size_t __zopfli_CalculateBlockSymbolSize(const unsigned *ll_lengths, const unsigned *d_lengths,
                                                const ZopfliLZ77Store *lz77, size_t lstart, size_t lend)
{
    if (lstart + ZOPFLI_NUM_LL * 3 > lend)
    {
        return __zopfli_CalculateBlockSymbolSizeSmall(ll_lengths, d_lengths, lz77, lstart, lend);
    }
    else
    {
        size_t ll_counts[ZOPFLI_NUM_LL];
        size_t d_counts[ZOPFLI_NUM_D];
        ZopfliLZ77GetHistogram(lz77, lstart, lend, ll_counts, d_counts);
        return __zopfli_CalculateBlockSymbolSizeGivenCounts(ll_counts, d_counts, ll_lengths, d_lengths, lz77, lstart, lend);
    }
}

static double ZopfliCalculateBlockSize(const ZopfliLZ77Store *lz77, size_t lstart, size_t lend, int btype)
{
    unsigned ll_lengths[ZOPFLI_NUM_LL];
    unsigned d_lengths[ZOPFLI_NUM_D];

    double result = 3; /* bfinal and btype bits */

    if (btype == 0)
    {
        size_t length = ZopfliLZ77GetByteRange(lz77, lstart, lend);
        size_t rem = length % 65535;
        size_t blocks = length / 65535 + (rem ? 1 : 0);
        /* An uncompressed block must actually be split into multiple blocks if it's
           larger than 65535 bytes long. Eeach block header is 5 bytes: 3 bits,
           padding, LEN and NLEN (potential less padding for first one ignored). */
        return blocks * 5 * 8 + length * 8;
    }
    if (btype == 1)
    {
        __zopfli_GetFixedTree(ll_lengths, d_lengths);
        result += __zopfli_CalculateBlockSymbolSize(ll_lengths, d_lengths, lz77, lstart, lend);
    }
    else
    {
        result += __zopfli_GetDynamicLengths(lz77, lstart, lend, ll_lengths, d_lengths);
    }

    return result;
}

static double ZopfliCalculateBlockSizeAutoType(const ZopfliLZ77Store *lz77, size_t lstart, size_t lend)
{
    double uncompressedcost = ZopfliCalculateBlockSize(lz77, lstart, lend, 0);
    /* Don't do the expensive fixed cost calculation for larger blocks that are
       unlikely to use it. */
    double fixedcost = (lz77->size > 1000) ? uncompressedcost : ZopfliCalculateBlockSize(lz77, lstart, lend, 1);
    double dyncost = ZopfliCalculateBlockSize(lz77, lstart, lend, 2);
    return (uncompressedcost < fixedcost && uncompressedcost < dyncost) ? uncompressedcost
                                                                        : (fixedcost < dyncost ? fixedcost : dyncost);
}

/*
Returns estimated cost of a block in bits.  It includes the size to encode the
tree and the size to encode all literal, length and distance symbols and their
extra bits.

litlens: lz77 lit/lengths
dists: ll77 distances
lstart: start of block
lend: end of block (not inclusive)
*/
static double __zopfli_EstimateCost(const ZopfliLZ77Store *lz77, size_t lstart, size_t lend)
{
    return ZopfliCalculateBlockSizeAutoType(lz77, lstart, lend);
}

/*
Gets the cost which is the sum of the cost of the left and the right section
of the data.
type: __zopfli_FindMinimumFun
*/
static double __zopfli_SplitCost(size_t i, void *context)
{
    __zopfli_SplitCostContext *c = (__zopfli_SplitCostContext *)context;
    return __zopfli_EstimateCost(c->lz77, c->start, i) + __zopfli_EstimateCost(c->lz77, i, c->end);
}

/*
Finds minimum of function f(i) where is is of type size_t, f(i) is of type
double, i is in range start-end (excluding end).
Outputs the minimum value in *smallest and returns the index of this value.
*/
static size_t __zopfli_FindMinimum(__zopfli_FindMinimumFun f, void *context, size_t start, size_t end, double *smallest)
{
    if (end - start < 1024)
    {
        double best = ZOPFLI_LARGE_FLOAT;
        size_t result = start;
        size_t i;
        for (i = start; i < end; i++)
        {
            double v = f(i, context);
            if (v < best)
            {
                best = v;
                result = i;
            }
        }
        *smallest = best;
        return result;
    }
    else
    {
        /* Try to find minimum faster by recursively checking multiple points. */
#define __ZOPFLI_NUM 9 /* Good value: 9. */
        size_t i;
        size_t p[__ZOPFLI_NUM];
        double vp[__ZOPFLI_NUM];
        size_t besti;
        double best;
        double lastbest = ZOPFLI_LARGE_FLOAT;
        size_t pos = start;

        for (;;)
        {
            if (end - start <= __ZOPFLI_NUM)
                break;

            for (i = 0; i < __ZOPFLI_NUM; i++)
            {
                p[i] = start + (i + 1) * ((end - start) / (__ZOPFLI_NUM + 1));
                vp[i] = f(p[i], context);
            }
            besti = 0;
            best = vp[0];
            for (i = 1; i < __ZOPFLI_NUM; i++)
            {
                if (vp[i] < best)
                {
                    best = vp[i];
                    besti = i;
                }
            }
            if (best > lastbest)
                break;

            start = besti == 0 ? start : p[besti - 1];
            end = besti == __ZOPFLI_NUM - 1 ? end : p[besti + 1];

            pos = p[besti];
            lastbest = best;
        }
        *smallest = lastbest;
        return pos;
#undef __ZOPFLI_NUM
    }
}

static void __zopfli_AddSorted(size_t value, size_t **out, size_t *outsize)
{
    size_t i;
    ZOPFLI_APPEND_DATA(value, out, outsize);
    for (i = 0; i + 1 < *outsize; i++)
    {
        if ((*out)[i] > value)
        {
            size_t j;
            for (j = *outsize - 1; j > i; j--)
            {
                (*out)[j] = (*out)[j - 1];
            }
            (*out)[i] = value;
            break;
        }
    }
}

/*
Finds next block to try to split, the largest of the available ones.
The largest is chosen to make sure that if only a limited amount of blocks is
requested, their sizes are spread evenly.
lz77size: the size of the LL77 data, which is the size of the done array here.
done: array indicating which blocks starting at that position are no longer
    splittable (splitting them increases rather than decreases cost).
splitpoints: the splitpoints found so far.
npoints: the amount of splitpoints found so far.
lstart: output variable, giving start of block.
lend: output variable, giving end of block.
returns 1 if a block was found, 0 if no block found (all are done).
*/
static int __zopfli_FindLargestSplittableBlock(size_t lz77size, const unsigned char *done, const size_t *splitpoints,
                                               size_t npoints, size_t *lstart, size_t *lend)
{
    size_t longest = 0;
    int found = 0;
    size_t i;
    for (i = 0; i <= npoints; i++)
    {
        size_t start = i == 0 ? 0 : splitpoints[i - 1];
        size_t end = i == npoints ? lz77size - 1 : splitpoints[i];
        if (!done[start] && end - start > longest)
        {
            *lstart = start;
            *lend = end;
            found = 1;
            longest = end - start;
        }
    }
    return found;
}

/*
Prints the block split points as decimal and hex values in the terminal.
*/
static void __zopfli_PrintBlockSplitPoints(const ZopfliLZ77Store *lz77, const size_t *lz77splitpoints, size_t nlz77points)
{
    size_t *splitpoints = 0;
    size_t npoints = 0;
    size_t i;
    /* The input is given as lz77 indices, but we want to see the uncompressed
    index values. */
    size_t pos = 0;
    if (nlz77points > 0)
    {
        for (i = 0; i < lz77->size; i++)
        {
            size_t length = lz77->dists[i] == 0 ? 1 : lz77->litlens[i];
            if (lz77splitpoints[npoints] == i)
            {
                ZOPFLI_APPEND_DATA(pos, &splitpoints, &npoints);
                if (npoints == nlz77points)
                    break;
            }
            pos += length;
        }
    }
    assert(npoints == nlz77points);

    fprintf(stderr, "block split points: ");
    for (i = 0; i < npoints; i++)
    {
        fprintf(stderr, "%d ", (int)splitpoints[i]);
    }
    fprintf(stderr, "(hex:");
    for (i = 0; i < npoints; i++)
    {
        fprintf(stderr, " %x", (int)splitpoints[i]);
    }
    fprintf(stderr, ")\n");

    free(splitpoints);
}

static void ZopfliBlockSplitLZ77(const ZopfliOptions *options, const ZopfliLZ77Store *lz77, size_t maxblocks,
                                 size_t **splitpoints, size_t *npoints)
{
    size_t lstart, lend;
    size_t i;
    size_t llpos = 0;
    size_t numblocks = 1;
    unsigned char *done;
    double splitcost, origcost;

    if (lz77->size < 10)
        return; /* This code fails on tiny files. */

    done = (unsigned char *)malloc(lz77->size);
    if (!done)
        exit(-1); /* Allocation failed. */
    for (i = 0; i < lz77->size; i++)
        done[i] = 0;

    lstart = 0;
    lend = lz77->size;
    for (;;)
    {
        __zopfli_SplitCostContext c;

        if (maxblocks > 0 && numblocks >= maxblocks)
        {
            break;
        }

        c.lz77 = lz77;
        c.start = lstart;
        c.end = lend;
        assert(lstart < lend);
        llpos = __zopfli_FindMinimum(__zopfli_SplitCost, &c, lstart + 1, lend, &splitcost);

        assert(llpos > lstart);
        assert(llpos < lend);

        origcost = __zopfli_EstimateCost(lz77, lstart, lend);

        if (splitcost > origcost || llpos == lstart + 1 || llpos == lend)
        {
            done[lstart] = 1;
        }
        else
        {
            __zopfli_AddSorted(llpos, splitpoints, npoints);
            numblocks++;
        }

        if (!__zopfli_FindLargestSplittableBlock(lz77->size, done, *splitpoints, *npoints, &lstart, &lend))
        {
            break; /* No further split will probably reduce compression. */
        }

        if (lend - lstart < 10)
        {
            break;
        }
    }

    if (options->verbose)
    {
        __zopfli_PrintBlockSplitPoints(lz77, *splitpoints, *npoints);
    }

    free(done);
}

static void ZopfliBlockSplit(const ZopfliOptions *options, const unsigned char *in, size_t instart, size_t inend,
                             size_t maxblocks, size_t **splitpoints, size_t *npoints)
{
    size_t pos = 0;
    size_t i;
    ZopfliBlockState s;
    size_t *lz77splitpoints = 0;
    size_t nlz77points = 0;
    ZopfliLZ77Store store;
    ZopfliHash hash;
    ZopfliHash *h = &hash;

    ZopfliInitLZ77Store(in, &store);
    ZopfliInitBlockState(options, instart, inend, 0, &s);
    ZopfliAllocHash(ZOPFLI_WINDOW_SIZE, h);

    *npoints = 0;
    *splitpoints = 0;

    /* Unintuitively, Using a simple LZ77 method here instead of ZopfliLZ77Optimal
    results in better blocks. */
    ZopfliLZ77Greedy(&s, in, instart, inend, &store, h);

    ZopfliBlockSplitLZ77(options, &store, maxblocks, &lz77splitpoints, &nlz77points);

    /* Convert LZ77 positions to positions in the uncompressed input. */
    pos = instart;
    if (nlz77points > 0)
    {
        for (i = 0; i < store.size; i++)
        {
            size_t length = store.dists[i] == 0 ? 1 : store.litlens[i];
            if (lz77splitpoints[*npoints] == i)
            {
                ZOPFLI_APPEND_DATA(pos, splitpoints, npoints);
                if (*npoints == nlz77points)
                    break;
            }
            pos += length;
        }
    }
    assert(*npoints == nlz77points);

    free(lz77splitpoints);
    ZopfliCleanBlockState(&s);
    ZopfliCleanLZ77Store(&store);
    ZopfliCleanHash(h);
}

static void __zopfli_InitRanState(__zopfli_RanState *state)
{
    state->m_w = 1;
    state->m_z = 2;
}

/* Sets everything to 0. */
static void __zopfli_InitStats(__zopfli_SymbolStats *stats)
{
    memset(stats->litlens, 0, ZOPFLI_NUM_LL * sizeof(stats->litlens[0]));
    memset(stats->dists, 0, ZOPFLI_NUM_D * sizeof(stats->dists[0]));

    memset(stats->ll_symbols, 0, ZOPFLI_NUM_LL * sizeof(stats->ll_symbols[0]));
    memset(stats->d_symbols, 0, ZOPFLI_NUM_D * sizeof(stats->d_symbols[0]));
}

static void ZopfliCalculateEntropy(const size_t *count, size_t n, double *bitlengths)
{
    static const double kInvLog2 = 1.4426950408889; /* 1.0 / log(2.0) */
    unsigned sum = 0;
    unsigned i;
    double log2sum;
    for (i = 0; i < n; ++i)
    {
        sum += count[i];
    }
    log2sum = (sum == 0 ? log(n) : log(sum)) * kInvLog2;
    for (i = 0; i < n; ++i)
    {
        /* When the count of the symbol is 0, but its cost is requested anyway, it
        means the symbol will appear at least once anyway, so give it the cost as if
        its count is 1.*/
        if (count[i] == 0)
            bitlengths[i] = log2sum;
        else
            bitlengths[i] = log2sum - log(count[i]) * kInvLog2;
        /* Depending on compiler and architecture, the above subtraction of two
        floating point numbers may give a negative result very close to zero
        instead of zero (e.g. -5.973954e-17 with gcc 4.1.2 on Ubuntu 11.4). Clamp
        it to zero. These floating point imprecisions do not affect the cost model
        significantly so this is ok. */
        if (bitlengths[i] < 0 && bitlengths[i] > -1e-5)
            bitlengths[i] = 0;
        assert(bitlengths[i] >= 0);
    }
}

/* Calculates the entropy of the statistics */
static void __zopfli_CalculateStatistics(__zopfli_SymbolStats *stats)
{
    ZopfliCalculateEntropy(stats->litlens, ZOPFLI_NUM_LL, stats->ll_symbols);
    ZopfliCalculateEntropy(stats->dists, ZOPFLI_NUM_D, stats->d_symbols);
}

/* Appends the symbol statistics from the store. */
static void __zopfli_GetStatistics(const ZopfliLZ77Store *store, __zopfli_SymbolStats *stats)
{
    size_t i;
    for (i = 0; i < store->size; i++)
    {
        if (store->dists[i] == 0)
        {
            stats->litlens[store->litlens[i]]++;
        }
        else
        {
            stats->litlens[ZopfliGetLengthSymbol(store->litlens[i])]++;
            stats->dists[ZopfliGetDistSymbol(store->dists[i])]++;
        }
    }
    stats->litlens[256] = 1; /* End symbol. */

    __zopfli_CalculateStatistics(stats);
}

/*
Cost model based on symbol statistics.
type: __zopfli_CostModelFun
*/
static double __zopfli_GetCostStat(unsigned litlen, unsigned dist, void *context)
{
    __zopfli_SymbolStats *stats = (__zopfli_SymbolStats *)context;
    if (dist == 0)
    {
        return stats->ll_symbols[litlen];
    }
    else
    {
        int lsym = ZopfliGetLengthSymbol(litlen);
        int lbits = ZopfliGetLengthExtraBits(litlen);
        int dsym = ZopfliGetDistSymbol(dist);
        int dbits = ZopfliGetDistExtraBits(dist);
        return lbits + dbits + stats->ll_symbols[lsym] + stats->d_symbols[dsym];
    }
}

static size_t __zopfli_CeilDiv(size_t a, size_t b) { return (a + b - 1) / b; }

static void ZopfliCopyLZ77Store(const ZopfliLZ77Store *source, ZopfliLZ77Store *dest)
{
    size_t i;
    size_t llsize = ZOPFLI_NUM_LL * __zopfli_CeilDiv(source->size, ZOPFLI_NUM_LL);
    size_t dsize = ZOPFLI_NUM_D * __zopfli_CeilDiv(source->size, ZOPFLI_NUM_D);
    ZopfliCleanLZ77Store(dest);
    ZopfliInitLZ77Store(source->data, dest);
    dest->litlens = (unsigned short *)malloc(sizeof(*dest->litlens) * source->size);
    dest->dists = (unsigned short *)malloc(sizeof(*dest->dists) * source->size);
    dest->pos = (size_t *)malloc(sizeof(*dest->pos) * source->size);
    dest->ll_symbol = (unsigned short *)malloc(sizeof(*dest->ll_symbol) * source->size);
    dest->d_symbol = (unsigned short *)malloc(sizeof(*dest->d_symbol) * source->size);
    dest->ll_counts = (size_t *)malloc(sizeof(*dest->ll_counts) * llsize);
    dest->d_counts = (size_t *)malloc(sizeof(*dest->d_counts) * dsize);

    /* Allocation failed. */
    if (!dest->litlens || !dest->dists)
        exit(-1);
    if (!dest->pos)
        exit(-1);
    if (!dest->ll_symbol || !dest->d_symbol)
        exit(-1);
    if (!dest->ll_counts || !dest->d_counts)
        exit(-1);

    dest->size = source->size;
    for (i = 0; i < source->size; i++)
    {
        dest->litlens[i] = source->litlens[i];
        dest->dists[i] = source->dists[i];
        dest->pos[i] = source->pos[i];
        dest->ll_symbol[i] = source->ll_symbol[i];
        dest->d_symbol[i] = source->d_symbol[i];
    }
    for (i = 0; i < llsize; i++)
    {
        dest->ll_counts[i] = source->ll_counts[i];
    }
    for (i = 0; i < dsize; i++)
    {
        dest->d_counts[i] = source->d_counts[i];
    }
}

static void __zopfli_CopyStats(__zopfli_SymbolStats *source, __zopfli_SymbolStats *dest)
{
    memcpy(dest->litlens, source->litlens, ZOPFLI_NUM_LL * sizeof(dest->litlens[0]));
    memcpy(dest->dists, source->dists, ZOPFLI_NUM_D * sizeof(dest->dists[0]));

    memcpy(dest->ll_symbols, source->ll_symbols, ZOPFLI_NUM_LL * sizeof(dest->ll_symbols[0]));
    memcpy(dest->d_symbols, source->d_symbols, ZOPFLI_NUM_D * sizeof(dest->d_symbols[0]));
}

static void __zopfli_ClearStatFreqs(__zopfli_SymbolStats *stats)
{
    size_t i;
    for (i = 0; i < ZOPFLI_NUM_LL; i++)
        stats->litlens[i] = 0;
    for (i = 0; i < ZOPFLI_NUM_D; i++)
        stats->dists[i] = 0;
}

/* Adds the bit lengths. */
static void __zopfli_AddWeighedStatFreqs(const __zopfli_SymbolStats *stats1, double w1, const __zopfli_SymbolStats *stats2, double w2,
                                         __zopfli_SymbolStats *result)
{
    size_t i;
    for (i = 0; i < ZOPFLI_NUM_LL; i++)
    {
        result->litlens[i] = (size_t)(stats1->litlens[i] * w1 + stats2->litlens[i] * w2);
    }
    for (i = 0; i < ZOPFLI_NUM_D; i++)
    {
        result->dists[i] = (size_t)(stats1->dists[i] * w1 + stats2->dists[i] * w2);
    }
    result->litlens[256] = 1; /* End symbol. */
}

/* Get random number: "Multiply-With-Carry" generator of G. Marsaglia */
static unsigned int __zopfli_Ran(__zopfli_RanState *state)
{
    state->m_z = 36969 * (state->m_z & 65535) + (state->m_z >> 16);
    state->m_w = 18000 * (state->m_w & 65535) + (state->m_w >> 16);
    return (state->m_z << 16) + state->m_w; /* 32-bit result. */
}

static void __zopfli_RandomizeFreqs(__zopfli_RanState *state, size_t *freqs, int n)
{
    int i;
    for (i = 0; i < n; i++)
    {
        if ((__zopfli_Ran(state) >> 4) % 3 == 0)
            freqs[i] = freqs[__zopfli_Ran(state) % n];
    }
}

static void __zopfli_RandomizeStatFreqs(__zopfli_RanState *state, __zopfli_SymbolStats *stats)
{
    __zopfli_RandomizeFreqs(state, stats->litlens, ZOPFLI_NUM_LL);
    __zopfli_RandomizeFreqs(state, stats->dists, ZOPFLI_NUM_D);
    stats->litlens[256] = 1; /* End symbol. */
}

static void ZopfliLZ77Optimal(ZopfliBlockState *s, const unsigned char *in, size_t instart, size_t inend, int numiterations,
                              ZopfliLZ77Store *store)
{
    /* Dist to get to here with smallest cost. */
    size_t blocksize = inend - instart;
    unsigned short *length_array = (unsigned short *)malloc(sizeof(unsigned short) * (blocksize + 1));
    unsigned short *path = 0;
    size_t pathsize = 0;
    ZopfliLZ77Store currentstore;
    ZopfliHash hash;
    ZopfliHash *h = &hash;
    __zopfli_SymbolStats stats, beststats, laststats;
    int i;
    float *costs = (float *)malloc(sizeof(float) * (blocksize + 1));
    double cost;
    double bestcost = ZOPFLI_LARGE_FLOAT;
    double lastcost = 0;
    /* Try randomizing the costs a bit once the size stabilizes. */
    __zopfli_RanState ran_state;
    int lastrandomstep = -1;

    if (!costs)
        exit(-1); /* Allocation failed. */
    if (!length_array)
        exit(-1); /* Allocation failed. */

    __zopfli_InitRanState(&ran_state);
    __zopfli_InitStats(&stats);
    ZopfliInitLZ77Store(in, &currentstore);
    ZopfliAllocHash(ZOPFLI_WINDOW_SIZE, h);

    /* Do regular deflate, then loop multiple shortest path runs, each time using
    the statistics of the previous run. */

    /* Initial run. */
    ZopfliLZ77Greedy(s, in, instart, inend, &currentstore, h);
    __zopfli_GetStatistics(&currentstore, &stats);

    /* Repeat statistics with each time the cost model from the previous stat
    run. */
    for (i = 0; i < numiterations; i++)
    {
        ZopfliCleanLZ77Store(&currentstore);
        ZopfliInitLZ77Store(in, &currentstore);
        __zopfli_LZ77OptimalRun(s, in, instart, inend, &path, &pathsize, length_array, __zopfli_GetCostStat, (void *)&stats,
                                &currentstore, h, costs);
        cost = ZopfliCalculateBlockSize(&currentstore, 0, currentstore.size, 2);
        if (s->options->verbose_more || (s->options->verbose && cost < bestcost))
        {
            fprintf(stderr, "Iteration %d: %d bit\n", i, (int)cost);
        }
        if (cost < bestcost)
        {
            /* Copy to the output store. */
            ZopfliCopyLZ77Store(&currentstore, store);
            __zopfli_CopyStats(&stats, &beststats);
            bestcost = cost;
        }
        __zopfli_CopyStats(&stats, &laststats);
        __zopfli_ClearStatFreqs(&stats);
        __zopfli_GetStatistics(&currentstore, &stats);
        if (lastrandomstep != -1)
        {
            /* This makes it converge slower but better. Do it only once the
            randomness kicks in so that if the user does few iterations, it gives a
            better result sooner. */
            __zopfli_AddWeighedStatFreqs(&stats, 1.0, &laststats, 0.5, &stats);
            __zopfli_CalculateStatistics(&stats);
        }
        if (i > 5 && cost == lastcost)
        {
            __zopfli_CopyStats(&beststats, &stats);
            __zopfli_RandomizeStatFreqs(&ran_state, &stats);
            __zopfli_CalculateStatistics(&stats);
            lastrandomstep = i;
        }
        lastcost = cost;
    }

    free(length_array);
    free(path);
    free(costs);
    ZopfliCleanLZ77Store(&currentstore);
    ZopfliCleanHash(h);
}

static void ZopfliAppendLZ77Store(const ZopfliLZ77Store *store, ZopfliLZ77Store *target)
{
    size_t i;
    for (i = 0; i < store->size; i++)
    {
        ZopfliStoreLitLenDist(store->litlens[i], store->dists[i], store->pos[i], target);
    }
}

static void __zopfli_AddLZ77BlockAutoType(const ZopfliOptions *options, int final, const ZopfliLZ77Store *lz77, size_t lstart,
                                          size_t lend, size_t expected_data_size, unsigned char *bp, unsigned char **out,
                                          size_t *outsize)
{
    double uncompressedcost = ZopfliCalculateBlockSize(lz77, lstart, lend, 0);
    double fixedcost = ZopfliCalculateBlockSize(lz77, lstart, lend, 1);
    double dyncost = ZopfliCalculateBlockSize(lz77, lstart, lend, 2);

    /* Whether to perform the expensive calculation of creating an optimal block
    with fixed huffman tree to check if smaller. Only do this for small blocks or
    blocks which already are pretty good with fixed huffman tree. */
    int expensivefixed = (lz77->size < 1000) || fixedcost <= dyncost * 1.1;

    ZopfliLZ77Store fixedstore;
    if (lstart == lend)
    {
        /* Smallest empty block is represented by fixed block */
        __zopfli_AddBits(final, 1, bp, out, outsize);
        __zopfli_AddBits(1, 2, bp, out, outsize); /* btype 01 */
        __zopfli_AddBits(0, 7, bp, out, outsize); /* end symbol has code 0000000 */
        return;
    }
    ZopfliInitLZ77Store(lz77->data, &fixedstore);
    if (expensivefixed)
    {
        /* Recalculate the LZ77 with ZopfliLZ77OptimalFixed */
        size_t instart = lz77->pos[lstart];
        size_t inend = instart + ZopfliLZ77GetByteRange(lz77, lstart, lend);

        ZopfliBlockState s;
        ZopfliInitBlockState(options, instart, inend, 1, &s);
        ZopfliLZ77OptimalFixed(&s, lz77->data, instart, inend, &fixedstore);
        fixedcost = ZopfliCalculateBlockSize(&fixedstore, 0, fixedstore.size, 1);
        ZopfliCleanBlockState(&s);
    }

    if (uncompressedcost < fixedcost && uncompressedcost < dyncost)
    {
        __zopfli_AddLZ77Block(options, 0, final, lz77, lstart, lend, expected_data_size, bp, out, outsize);
    }
    else if (fixedcost < dyncost)
    {
        if (expensivefixed)
        {
            __zopfli_AddLZ77Block(options, 1, final, &fixedstore, 0, fixedstore.size, expected_data_size, bp, out, outsize);
        }
        else
        {
            __zopfli_AddLZ77Block(options, 1, final, lz77, lstart, lend, expected_data_size, bp, out, outsize);
        }
    }
    else
    {
        __zopfli_AddLZ77Block(options, 2, final, lz77, lstart, lend, expected_data_size, bp, out, outsize);
    }

    ZopfliCleanLZ77Store(&fixedstore);
}

static void ZopfliInitOptions(ZopfliOptions *options)
{
    options->verbose = 0;
    options->verbose_more = 0;
    options->numiterations = 15;
    options->blocksplitting = 1;
    options->blocksplittinglast = 0;
    options->blocksplittingmax = 15;
}

/* Calculates the __zopfli_adler32 checksum of the data */
static unsigned __zopfli_adler32(const unsigned char *data, size_t size)
{
    static const unsigned sums_overflow = 5550;
    unsigned s1 = 1;
    unsigned s2 = 1 >> 16;

    while (size > 0)
    {
        size_t amount = size > sums_overflow ? sums_overflow : size;
        size -= amount;
        while (amount > 0)
        {
            s1 += (*data++);
            s2 += s1;
            amount--;
        }
        s1 %= 65521;
        s2 %= 65521;
    }

    return (s2 << 16) | s1;
}

/*
Deflate a part, to allow ZopfliDeflate() to use multiple master blocks if
needed.
It is possible to call this function multiple times in a row, shifting
instart and inend to next bytes of the data. If instart is larger than 0, then
previous bytes are used as the initial dictionary for LZ77.
This function will usually output multiple deflate blocks. If final is 1, then
the final bit will be set on the last block.
*/
static void ZopfliDeflatePart(const ZopfliOptions *options, int btype, int final, const unsigned char *in, size_t instart,
                              size_t inend, unsigned char *bp, unsigned char **out, size_t *outsize)
{
    size_t i;
    /* byte coordinates rather than lz77 index */
    size_t *splitpoints_uncompressed = 0;
    size_t npoints = 0;
    size_t *splitpoints = 0;
    double totalcost = 0;
    ZopfliLZ77Store lz77;

    /* If btype=2 is specified, it tries all block types. If a lesser btype is
    given, then however it forces that one. Neither of the lesser types needs
    block splitting as they have no dynamic huffman trees. */
    if (btype == 0)
    {
        __zopfli_AddNonCompressedBlock(options, final, in, instart, inend, bp, out, outsize);
        return;
    }
    else if (btype == 1)
    {
        ZopfliLZ77Store store;
        ZopfliBlockState s;
        ZopfliInitLZ77Store(in, &store);
        ZopfliInitBlockState(options, instart, inend, 1, &s);

        ZopfliLZ77OptimalFixed(&s, in, instart, inend, &store);
        __zopfli_AddLZ77Block(options, btype, final, &store, 0, store.size, 0, bp, out, outsize);

        ZopfliCleanBlockState(&s);
        ZopfliCleanLZ77Store(&store);
        return;
    }

    if (options->blocksplitting)
    {
        ZopfliBlockSplit(options, in, instart, inend, options->blocksplittingmax, &splitpoints_uncompressed, &npoints);
        splitpoints = (size_t *)malloc(sizeof(*splitpoints) * npoints);
    }

    ZopfliInitLZ77Store(in, &lz77);

    for (i = 0; i <= npoints; i++)
    {
        size_t start = i == 0 ? instart : splitpoints_uncompressed[i - 1];
        size_t end = i == npoints ? inend : splitpoints_uncompressed[i];
        ZopfliBlockState s;
        ZopfliLZ77Store store;
        ZopfliInitLZ77Store(in, &store);
        ZopfliInitBlockState(options, start, end, 1, &s);
        ZopfliLZ77Optimal(&s, in, start, end, options->numiterations, &store);
        totalcost += ZopfliCalculateBlockSizeAutoType(&store, 0, store.size);

        ZopfliAppendLZ77Store(&store, &lz77);
        if (i < npoints)
            splitpoints[i] = lz77.size;

        ZopfliCleanBlockState(&s);
        ZopfliCleanLZ77Store(&store);
    }

    /* Second block splitting attempt */
    if (options->blocksplitting && npoints > 1)
    {
        size_t *splitpoints2 = 0;
        size_t npoints2 = 0;
        double totalcost2 = 0;

        ZopfliBlockSplitLZ77(options, &lz77, options->blocksplittingmax, &splitpoints2, &npoints2);

        for (i = 0; i <= npoints2; i++)
        {
            size_t start = i == 0 ? 0 : splitpoints2[i - 1];
            size_t end = i == npoints2 ? lz77.size : splitpoints2[i];
            totalcost2 += ZopfliCalculateBlockSizeAutoType(&lz77, start, end);
        }

        if (totalcost2 < totalcost)
        {
            free(splitpoints);
            splitpoints = splitpoints2;
            npoints = npoints2;
        }
        else
        {
            free(splitpoints2);
        }
    }

    for (i = 0; i <= npoints; i++)
    {
        size_t start = i == 0 ? 0 : splitpoints[i - 1];
        size_t end = i == npoints ? lz77.size : splitpoints[i];
        __zopfli_AddLZ77BlockAutoType(options, i == npoints && final, &lz77, start, end, 0, bp, out, outsize);
    }

    ZopfliCleanLZ77Store(&lz77);
    free(splitpoints);
    free(splitpoints_uncompressed);
}

static void ZopfliDeflate(const ZopfliOptions *options, int btype, int final, const unsigned char *in, size_t insize,
                          unsigned char *bp, unsigned char **out, size_t *outsize)
{
    size_t offset = *outsize;
#if ZOPFLI_MASTER_BLOCK_SIZE == 0
    ZopfliDeflatePart(options, btype, final, in, 0, insize, bp, out, outsize);
#else
    size_t i = 0;
    do
    {
        int masterfinal = (i + ZOPFLI_MASTER_BLOCK_SIZE >= insize);
        int final2 = final && masterfinal;
        size_t size = masterfinal ? insize - i : ZOPFLI_MASTER_BLOCK_SIZE;
        ZopfliDeflatePart(options, btype, final2, in, i, i + size, bp, out, outsize);
        i += size;
    } while (i < insize);
#endif
    if (options->verbose)
    {
        fprintf(stderr, "Original Size: %lu, Deflate: %lu, Compression: %f%% Removed\n", (unsigned long)insize,
                (unsigned long)(*outsize - offset), 100.0 * (double)(insize - (*outsize - offset)) / (double)insize);
    }
}

static void ZopfliZlibCompress(const ZopfliOptions *options, const unsigned char *in, size_t insize, unsigned char **out,
                               size_t *outsize)
{
    unsigned char bitpointer = 0;
    unsigned checksum = __zopfli_adler32(in, (unsigned)insize);
    unsigned cmf = 120; /* CM 8, CINFO 7. See zlib spec.*/
    unsigned flevel = 3;
    unsigned fdict = 0;
    unsigned cmfflg = 256 * cmf + fdict * 32 + flevel * 64;
    unsigned fcheck = 31 - cmfflg % 31;
    cmfflg += fcheck;

    ZOPFLI_APPEND_DATA(cmfflg / 256, out, outsize);
    ZOPFLI_APPEND_DATA(cmfflg % 256, out, outsize);

    ZopfliDeflate(options, 2 /* dynamic block */, 1 /* final */, in, insize, &bitpointer, out, outsize);

    ZOPFLI_APPEND_DATA((checksum >> 24) % 256, out, outsize);
    ZOPFLI_APPEND_DATA((checksum >> 16) % 256, out, outsize);
    ZOPFLI_APPEND_DATA((checksum >> 8) % 256, out, outsize);
    ZOPFLI_APPEND_DATA(checksum % 256, out, outsize);

    if (options->verbose)
    {
        fprintf(stderr, "Original Size: %d, Zlib: %d, Compression: %f%% Removed\n", (int)insize, (int)*outsize,
                100.0 * (double)(insize - *outsize) / (double)insize);
    }
}

/// @brief Top level function that calls the appropriate Zopfli library functions
/// @param iterations The number of iterations (if this is 0 then the default of 15 is used)
/// @param input_buffer The input buffer to compress
/// @param input_size The size of the input buffer
/// @param output_buffer A pointer to the compressed buffer. This should be freed once used
/// @param output_size The size of the compressed buffer
inline void __Zopfli_Compress(uint16_t iterations, const char *input_buffer, size_t input_size, uintptr_t *output_buffer, size_t *output_size)
{
    ZopfliOptions options;
    ZopfliInitOptions(&options); // intialize options

    // Set iterations only if it is > 0
    if (iterations)
        options.numiterations = iterations;

    // Finally call ZopfliZlibCompress (the caller should free output_buffer)
    ZopfliZlibCompress(&options, (const unsigned char *)input_buffer, input_size, (unsigned char **)output_buffer, output_size);
}

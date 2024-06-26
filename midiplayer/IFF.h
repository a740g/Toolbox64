
/** $VER: IFF.h (2024.05.18) **/

#pragma once

#include "framework.h"

const FOURCC FOURCC_FORM = mmioFOURCC('F', 'O', 'R', 'M');
const FOURCC FOURCC_CAT = mmioFOURCC('C', 'A', 'T', ' ');
const FOURCC FOURCC_EVNT = mmioFOURCC('E', 'V', 'N', 'T');

const FOURCC FOURCC_XDIR = mmioFOURCC('X', 'D', 'I', 'R');
const FOURCC FOURCC_XMID = mmioFOURCC('X', 'M', 'I', 'D');

struct iff_chunk_t
{
    FOURCC Id;
    FOURCC Type;
    std::vector<uint8_t> _Data;
    std::vector<iff_chunk_t> _Chunks;

    iff_chunk_t() : Id(), Type()
    {
    }

    iff_chunk_t(const iff_chunk_t &other)
    {
        Id = other.Id;
        Type = other.Type;
        _Data = other._Data;
        _Chunks = other._Chunks;
    }

    iff_chunk_t &operator=(const iff_chunk_t &other)
    {
        Id = other.Id;
        Type = other.Type;
        _Data = other._Data;
        _Chunks = other._Chunks;

        return *this;
    }

    /// <summary>
    /// Gets the n-th chunk with the specified id.
    /// </summary>
    const iff_chunk_t &FindChunk(FOURCC id, uint32_t n = 0) const
    {
        for (const auto &Chunk : _Chunks)
        {
            if (Chunk.Id == id)
            {
                if (n != 0)
                    --n;

                if (n == 0)
                    return Chunk;
            }
        }

        return *this; // throw exception_io_data( pfc::string_formatter() << "Missing IFF chunk: " << p_id );
    }

    /// <summary>
    /// Gets the number of chunks with the specified id.
    /// </summary>
    uint32_t GetChunkCount(FOURCC id) const
    {
        uint32_t ChunkCount = 0;

        for (const auto &Chunk : _Chunks)
        {
            if (Chunk.Id == id)
                ++ChunkCount;
        }

        return ChunkCount;
    }
};

struct iff_stream_t
{
    std::vector<iff_chunk_t> _Chunks;

    iff_chunk_t fail;

    /// <summary>
    /// Finds the first chunk with the specified id.
    /// </summary>
    const iff_chunk_t &FindChunk(FOURCC id) const
    {
        for (const auto &Chunk : _Chunks)
        {
            if (Chunk.Id == id)
                return Chunk;
        }

        return fail; // throw exception_io_data( pfc::string_formatter() << "Missing IFF chunk: " << p_id );
    }
};

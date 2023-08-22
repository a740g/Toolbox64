//----------------------------------------------------------------------------------------------------------------------
// Audio resampling routines
// Copyright (c) 2019 Zhihan Gao
// Copyright (c) 2023 Samuel Gomes
//
// Modified and adapted from https://github.com/cpuimage/resampler
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>

/// @brief Resamples 16-bit audio samples. Set output to NULL to get the output buffer size in samples frames
/// @param input The input 16-bit integer sample frame buffer
/// @param output The output 16-bit integer sample frame buffer
/// @param inSampleRate The input sample rate
/// @param outSampleRate The output sample rate
/// @param inputSize The number of samples frames in the input
/// @param channels The number of channels for both input and output
/// @return The number of samples frames written to the output
uint64_t AudioResample16(const int16_t *input, int16_t *output, int inSampleRate, int outSampleRate, uint64_t inputSize, uint32_t channels)
{
    if (!input)
        return 0;

    auto outputSize = (uint64_t)(inputSize * (double)outSampleRate / (double)inSampleRate);
    outputSize -= outputSize % channels;

    if (!output)
        return outputSize;

    auto stepDist = ((double)inSampleRate / (double)outSampleRate);
    const uint64_t fixedFraction = (1LL << 32);
    const double normFixed = (1.0 / (1LL << 32));
    auto step = ((uint64_t)(stepDist * fixedFraction + 0.5));
    uint64_t curOffset = 0;

    for (uint32_t i = 0; i < outputSize; i += 1)
    {
        for (uint32_t c = 0; c < channels; c += 1)
        {
            *output++ = (int16_t)(input[c] + (input[c + channels] - input[c]) * ((double)(curOffset >> 32) + ((curOffset & (fixedFraction - 1)) * normFixed)));
        }
        curOffset += step;
        input += (curOffset >> 32) * channels;
        curOffset &= (fixedFraction - 1);
    }

    return outputSize;
}

/// @brief Resamples 32-bit audio samples. Set output to NULL to get the output buffer size in samples frames
/// @param input The input 32-bit floating point sample frame buffer
/// @param output The output 32-bit floating point sample frame buffer
/// @param inSampleRate The input sample rate
/// @param outSampleRate The output sample rate
/// @param inputSize The number of samples frames in the input
/// @param channels The number of channels for both input and output
/// @return The number of samples frames written to the output
uint64_t AudioResample32(const float *input, float *output, int inSampleRate, int outSampleRate, uint64_t inputSize, uint32_t channels)
{
    if (!input)
        return 0;

    auto outputSize = (uint64_t)(inputSize * (double)outSampleRate / (double)inSampleRate);
    outputSize -= outputSize % channels;

    if (!output)
        return outputSize;

    auto stepDist = ((double)inSampleRate / (double)outSampleRate);
    const uint64_t fixedFraction = (1LL << 32);
    const double normFixed = (1.0 / (1LL << 32));
    auto step = ((uint64_t)(stepDist * fixedFraction + 0.5));
    uint64_t curOffset = 0;

    for (uint32_t i = 0; i < outputSize; i += 1)
    {
        for (uint32_t c = 0; c < channels; c += 1)
        {
            *output++ = (float)(input[c] + (input[c + channels] - input[c]) * ((double)(curOffset >> 32) + ((curOffset & (fixedFraction - 1)) * normFixed)));
        }
        curOffset += step;
        input += (curOffset >> 32) * channels;
        curOffset &= (fixedFraction - 1);
    }

    return outputSize;
}

/// @brief Resamples and converts 8-bit signed audio samples to 32-bit. Set output to NULL to get the output buffer size in samples frames
/// @param input The input 8-bit signed integer sample frame buffer
/// @param output The output 32-bit floating point sample frame buffer
/// @param inSampleRate The input sample rate
/// @param outSampleRate The output sample rate
/// @param inputSize The number of samples frames in the input
/// @param channels The number of channels for both input and output
/// @return The number of samples frames written to the output
uint64_t AudioResampleAndConvert8(const int8_t *input, float *output, uint32_t inSampleRate, uint32_t outSampleRate, uint64_t inputSampleFrames, uint32_t channels)
{
    if (!input)
        return 0;

    auto outputSize = (uint64_t)(inputSampleFrames * (double)outSampleRate / (double)inSampleRate);
    outputSize -= outputSize % channels;

    if (!output)
        return outputSize;

    auto stepDist = ((double)inSampleRate / (double)outSampleRate);
    const uint64_t fixedFraction = (1LL << 32);
    const double normFixed = (1.0 / (1LL << 32));
    auto step = ((uint64_t)(stepDist * fixedFraction + 0.5));
    uint64_t curOffset = 0;
    float sampleFP1, sampleFP2;

    for (uint32_t i = 0; i < outputSize; i += 1)
    {
        for (uint32_t c = 0; c < channels; c += 1)
        {
            sampleFP1 = (float)input[c] / 128.0f;
            sampleFP2 = (float)input[c + channels] / 128.0f;
            *output++ = (float)(sampleFP1 + (sampleFP2 - sampleFP1) * ((double)(curOffset >> 32) + ((curOffset & (fixedFraction - 1)) * normFixed)));
        }
        curOffset += step;
        input += (curOffset >> 32) * channels;
        curOffset &= (fixedFraction - 1);
    }

    return outputSize;
}

/// @brief Resamples and converts 16-bit audio samples to 32-bit. Set output to NULL to get the output buffer size in samples frames
/// @param input The input 16-bit integer sample frame buffer
/// @param output The output 32-bit floating point sample frame buffer
/// @param inSampleRate The input sample rate
/// @param outSampleRate The output sample rate
/// @param inputSize The number of samples frames in the input
/// @param channels The number of channels for both input and output
/// @return The number of samples frames written to the output
uint64_t AudioResampleAndConvert16(const int16_t *input, float *output, uint32_t inSampleRate, uint32_t outSampleRate, uint64_t inputSampleFrames, uint32_t channels)
{
    if (!input)
        return 0;

    auto outputSize = (uint64_t)(inputSampleFrames * (double)outSampleRate / (double)inSampleRate);
    outputSize -= outputSize % channels;

    if (!output)
        return outputSize;

    auto stepDist = ((double)inSampleRate / (double)outSampleRate);
    const uint64_t fixedFraction = (1LL << 32);
    const double normFixed = (1.0 / (1LL << 32));
    auto step = ((uint64_t)(stepDist * fixedFraction + 0.5));
    uint64_t curOffset = 0;
    float sampleFP1, sampleFP2;

    for (uint32_t i = 0; i < outputSize; i += 1)
    {
        for (uint32_t c = 0; c < channels; c += 1)
        {
            sampleFP1 = (float)input[c] / 32768.0f;
            sampleFP2 = (float)input[c + channels] / 32768.0f;
            *output++ = (float)(sampleFP1 + (sampleFP2 - sampleFP1) * ((double)(curOffset >> 32) + ((curOffset & (fixedFraction - 1)) * normFixed)));
        }
        curOffset += step;
        input += (curOffset >> 32) * channels;
        curOffset &= (fixedFraction - 1);
    }

    return outputSize;
}

//----------------------------------------------------------------------------------------------------------------------
// Simple audio conversion and resampling library
// Copyright (c) 2024 Samuel Gomes
// Copyright (c) 2019 Zhihan Gao
// Copyright (c) 2012 bogdan
//
// This includes heavily modified code from the following projects:
// https://github.com/cpuimage/resampler
// https://github.com/dystopiancode/pcm-g711
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>

/// @brief Converts unsigned 8-bit audio samples to signed 8-bit inplace.
/// @param source The input unsigned 8-bit sample frame buffer.
/// @param samples The number of samples in the sample frame buffer, where samples = frames * channels.
inline void __AudioConv_ConvertU8ToS8(void *source, uint32_t samples)
{
    if (!source or !samples)
        return;

    auto buffer = reinterpret_cast<uint8_t *>(source);

    for (size_t i = 0; i < samples; i++)
        buffer[i] ^= 0x80; // xor_eq
}

/// @brief Converts unsigned 16-bit audio samples to signed 16-bit inplace.
/// @param source The input unsigned 16-bit sample frame buffer.
/// @param samples The number of samples in the sample frame buffer, where samples = frames * channels.
inline void __AudioConv_ConvertU16ToS16(void *source, uint32_t samples)
{
    if (!source or !samples)
        return;

    auto buffer = reinterpret_cast<uint16_t *>(source);

    for (size_t i = 0; i < samples; i++)
        buffer[i] ^= 0x8000; // xor_eq
}

/// @brief Converts signed 8-bit audio samples to floating point.
/// @param src The input signed 8-bit sample frame buffer.
/// @param samples The number of samples in the buffer, where samples = frames * channels.
/// @param dst The output floating point sample frame buffer. The buffer size must be at least samples * sizeof(float) bytes.
/// @return True if successful.
inline void __AudioConv_ConvertS8ToF32(const void *src, uint32_t samples, void *dst)
{
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const int8_t *>(src);
    auto dstBuffer = reinterpret_cast<float *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = (float)srcBuffer[i] / 128.0f;
}

/// @brief Converts signed 8-bit audio samples to signed 16-bit.
/// @param src The input signed 8-bit sample frame buffer.
/// @param samples The number of samples in the buffer, where samples = frames * channels.
/// @param dst The output signed 16-bit sample frame buffer. The buffer size must be at least samples * sizeof(int16_t) bytes.
inline void __AudioConv_ConvertS8ToS16(const void *src, uint32_t samples, void *dst)
{
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const int8_t *>(src);
    auto dstBuffer = reinterpret_cast<int16_t *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = srcBuffer[i] << 8;
}

/// @brief Converts signed 16-bit audio samples to floating point.
/// @param src The input signed 16-bit sample frame buffer.
/// @param samples The number of samples in the buffer, where samples = frames * channels.
/// @param dst The output floating point sample frame buffer. The buffer size must be at least samples * sizeof(float) bytes.
/// @return True if successful.
inline void __AudioConv_ConvertS16ToF32(const void *src, uint32_t samples, void *dst)
{
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const int16_t *>(src);
    auto dstBuffer = reinterpret_cast<float *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = (float)srcBuffer[i] / 32768.0f;
}

/// @brief Decodes an 8-bit unsigned integer using the A-Law.
/// @param number The number that will be decoded.
/// @return The decoded number.
static inline int16_t __AudioConv_DecodeALawSample(int8_t number)
{
    uint8_t sign = 0x00;  // The sign of the decoded number
    uint8_t position = 0; // The position of the decoded number
    int16_t decoded = 0;  // The decoded number

    number ^= 0x55;

    if (number & 0x80)
    {
        number &= ~(1 << 7);
        sign = -1;
    }

    position = ((number & 0xF0) >> 4) + 4;
    if (position != 4)
        decoded = ((1 << position) | ((number & 0x0F) << (position - 4)) | (1 << (position - 5)));
    else
        decoded = (number << 1) | 1;

    return (sign == 0) ? (decoded) : (-decoded);
}

/// @brief Converts A-Law encoded audio samples to signed 16-bit samples.
/// @param src Pointer to the A-Law encoded audio samples buffer.
/// @param samples Number of samples in the buffer, where samples = frames * channels.
/// @param dst Pointer to the buffer where the signed 16-bit samples will be stored. The buffer size must be at least samples * sizeof(int16_t) bytes.
void __AudioConv_ConvertALawToS16(const void *src, uint32_t samples, void *dst)
{
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const int8_t *>(src);
    auto dstBuffer = reinterpret_cast<int16_t *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = __AudioConv_DecodeALawSample(srcBuffer[i]);
}

/// @brief Converts A-Law encoded audio samples to floating point samples.
/// @param src Pointer to the A-Law encoded audio samples buffer.
/// @param frames Number of samples in the buffer.
/// @param dst Pointer to the buffer where the floating point samples will be stored. The buffer size must be at least samples * sizeof(float) bytes.
void __AudioConv_ConvertALawToF32(const void *src, uint32_t frames, void *dst)
{
    if (!src or !dst or !frames)
        return;

    auto srcBuffer = reinterpret_cast<const int8_t *>(src);
    auto dstBuffer = reinterpret_cast<float *>(dst);

    for (size_t i = 0; i < frames; i++)
        dstBuffer[i] = (float)__AudioConv_DecodeALawSample(srcBuffer[i]) / 32768.0f;
}

/// @brief Decodes an 8-bit unsigned integer using the mu-Law.
/// @param number The number that will be decoded.
/// @return The decoded number.
static inline int16_t __AudioConv_DecodeMuLawSample(int8_t number)
{
    const uint16_t MULAW_BIAS = 33;
    uint8_t sign = 0, position = 0;
    int16_t decoded = 0;

    number = ~number;

    if (number & 0x80)
    {
        number &= ~(1 << 7);
        sign = -1;
    }

    position = ((number & 0xF0) >> 4) + 5;
    decoded = ((1 << position) | ((number & 0x0F) << (position - 4)) | (1 << (position - 5))) - MULAW_BIAS;

    return (sign == 0) ? (decoded) : (-(decoded));
}

/// @brief Converts mu-Law encoded audio samples to signed 16-bit samples.
/// @param src Pointer to the mu-Law encoded audio samples buffer.
/// @param samples Number of samples in the buffer, where samples = frames * channels.
/// @param dst Pointer to the buffer where the signed 16-bit samples will be stored. The buffer size must be at least samples * sizeof(int16_t) bytes.
void __AudioConv_ConvertMuLawToS16(const void *src, uint32_t samples, void *dst)
{
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const int8_t *>(src);
    auto dstBuffer = reinterpret_cast<int16_t *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = __AudioConv_DecodeMuLawSample(srcBuffer[i]);
}

/// @brief Converts mu-Law encoded audio samples to floating point samples.
/// @param src Pointer to the mu-Law encoded audio samples buffer.
/// @param samples Number of samples in the buffer.
/// @param dst Pointer to the buffer where the floating point samples will be stored. The buffer size must be at least samples * sizeof(float) bytes.
void __AudioConv_ConvertMuLawToF32(const void *src, uint32_t samples, void *dst)
{
    if (!src or !dst or !samples)
        return;

    auto srcBuffer = reinterpret_cast<const int8_t *>(src);
    auto dstBuffer = reinterpret_cast<float *>(dst);

    for (size_t i = 0; i < samples; i++)
        dstBuffer[i] = (float)__AudioConv_DecodeMuLawSample(srcBuffer[i]) / 32768.0f;
}

/// @brief Converts 4-bit ADPCM compressed audio samples to 8-bit signed samples.
/// @param src Pointer to the ADPCM compressed audio samples buffer.
/// @param srcLen The number of bytes in the input buffer.
/// @param compTab Pointer to the compression table used to decode the ADPCM codes.
/// @param dst Pointer to the buffer where the 8-bit signed samples will be stored. The buffer size must be at least srcLen * 2 bytes.
inline void __AudioConv_ConvertADPCM4ToS8(const void *src, uint32_t srcLen, const char *compTab, void *dst)
{
    auto srcBuffer = reinterpret_cast<const uint8_t *>(src);
    auto dstBuffer = reinterpret_cast<int8_t *>(dst);

    int8_t delta = 0;

    for (size_t i = 0; i < srcLen; i++)
    {
        delta += compTab[*srcBuffer & 0x0F];
        *(dstBuffer++) = delta;
        delta += compTab[(*srcBuffer >> 4) & 0x0F];
        *(dstBuffer++) = delta;
        srcBuffer++;
    }
}

/// @brief Converts a dual mono audio buffer to a stereo interleaved audio buffer (inplace).
/// @tparam T Data type of the audio samples.
/// @param src Pointer to the dual mono audio buffer.
/// @param samples Number of samples in the buffer.
/// @param dst Pointer to the buffer where the stereo interleaved audio samples will be stored. The buffer size must be at least samples * sizeof(T) bytes.
template <typename T>
inline void AudioConv_ConvertDualMonoToStereoInterleaved(const void *src, uint32_t samples, void *dst)
{
    // Check parameters
    if (!src || !dst || samples < 4)
        return;

    // Cast the input and output buffers to the appropriate types
    auto srcBuffer = reinterpret_cast<const T *>(src);
    auto dstBuffer = reinterpret_cast<T *>(dst);

    // Calculate the half length of the input buffer (number of samples in each channel)
    uint32_t halfLength = samples >> 1;

    // Iterate through each sample in the input buffer and copy them to the output
    // buffer, interleaving them.
    for (size_t i = 0, j = 0; i < halfLength; i++, j += 2)
    {
        dstBuffer[j] = srcBuffer[i];
        dstBuffer[j + 1] = srcBuffer[halfLength + i];
    }
}

// Specializations of AudioConv_ConvertDualMonoToStereoInterleaved() for different data types
#define __AudioConv_ConvertDualMonoToStereoInterleavedS8(_src_, _samples_, _dst_) AudioConv_ConvertDualMonoToStereoInterleaved<int8_t>(_src_, _samples_, _dst_)
#define __AudioConv_ConvertDualMonoToStereoInterleavedS16(_src_, _samples_, _dst_) AudioConv_ConvertDualMonoToStereoInterleaved<int16_t>(_src_, _samples_, _dst_)
#define __AudioConv_ConvertDualMonoToStereoInterleavedF32(_src_, _samples_, _dst_) AudioConv_ConvertDualMonoToStereoInterleaved<float>(_src_, _samples_, _dst_)

/// @brief Resamples 16-bit audio samples. Set output to NULL to get the output buffer size in samples frames
/// @param input The input 16-bit integer sample frame buffer
/// @param output The output 16-bit integer sample frame buffer
/// @param inSampleRate The input sample rate
/// @param outSampleRate The output sample rate
/// @param inputSize The number of samples frames in the input
/// @param channels The number of channels for both input and output
/// @return The number of samples frames written to the output
uint64_t AudioConv_ResampleS16(const int16_t *input, int16_t *output, int inSampleRate, int outSampleRate, uint64_t inputSize, uint32_t channels)
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
uint64_t AudioConv_ResampleF32(const float *input, float *output, int inSampleRate, int outSampleRate, uint64_t inputSize, uint32_t channels)
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
uint64_t AudioConv_ResampleAndConvertS8ToF32(const int8_t *input, float *output, uint32_t inSampleRate, uint32_t outSampleRate, uint64_t inputSampleFrames, uint32_t channels)
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
uint64_t AudioConv_ResampleAndConvertS16ToF32(const int16_t *input, float *output, uint32_t inSampleRate, uint32_t outSampleRate, uint64_t inputSampleFrames, uint32_t channels)
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

//----------------------------------------------------------------------------------------------------------------------
// FFT routines for spectrum analyzers
// Copyright (c) 2024 Samuel Gomes
// Copyright (c) 2004-2022 Stian Skjelstad
// Copyright (c) 1994-2005 Niklas Beisert
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include <cstdint>
#include <algorithm>
#include <cmath>
#include <cstdlib>

class AnalyzerFFT
{
private:
    static const auto POW = 11;
    static const auto SAMPLES = 1 << POW;
    static const auto SAMPLES2 = 1 << (POW - 1);
    static const auto SAMPLES2Q = 1 << (POW - 2);
    static const auto SCALE_FACTOR = 1 << 28;
    static const auto S16_TO_F32_MUL = 1.0f / 32768.0f;
    static const auto F32_TO_S16_MUL = 32767.0f;

    static uint16_t fft_permtab[SAMPLES];
    static int32_t fft_x86[SAMPLES][2];
    static int32_t fft_cossintab86[SAMPLES2][2];

    static constexpr auto IMul29(int32_t a, int32_t b)
    {
        return (int32_t)((int64_t(a) * int64_t(b)) >> 29);
    }

    static void Calc(int32_t *xi, int32_t *curcossin, uint32_t d2)
    {
        auto xd0 = xi[0] - xi[d2 + 0];
        xi[0] = (xi[0] + xi[d2 + 0]) >> 1;

        auto xd1 = xi[1] - xi[d2 + 1];
        xi[1] = (xi[1] + xi[d2 + 1]) >> 1;

        xi[d2 + 0] = IMul29(xd0, curcossin[0]) - IMul29(xd1, curcossin[1]);
        xi[d2 + 1] = IMul29(xd0, curcossin[1]) + IMul29(xd1, curcossin[0]);
    }

    static void Do86(int32_t (*x)[2], int n)
    {
        auto xe = x[1 << n];
        int32_t curcossin[2];
        int32_t *xi;

        for (auto i = POW - n; i < POW; ++i)
        {
            const auto s2dk = SAMPLES2 >> i;
            const auto d2 = 2 * s2dk;

            for (auto j = 0; j < s2dk; ++j)
            {
                curcossin[0] = fft_cossintab86[j << i][0];
                curcossin[1] = fft_cossintab86[j << i][1];

                for (xi = x[j]; xi < xe; xi += 2 * d2)
                    Calc(xi, curcossin, d2);
            }
        }
    }

public:
    AnalyzerFFT()
    {
        for (auto i = 0; i < SAMPLES2Q; i++)
        {
            double angle = (2.0 * M_PI * i) / (4.0 * SAMPLES2Q);
            fft_cossintab86[i][0] = int32_t(std::cos(angle) * SCALE_FACTOR);
            fft_cossintab86[i][1] = int32_t(std::sin(angle) * SCALE_FACTOR);
        }

        auto j = 0, k = 0;

        for (auto i = 0; i < SAMPLES; ++i)
        {
            fft_permtab[i] = j;
            for (k = SAMPLES2; k && (k <= j); k >>= 1)
                j -= k;
            j += k;
        }

        for (auto i = SAMPLES2 / 4 + 1; i <= SAMPLES2 / 2; ++i)
        {
            fft_cossintab86[i][0] = fft_cossintab86[SAMPLES2 / 2 - i][1];
            fft_cossintab86[i][1] = fft_cossintab86[SAMPLES2 / 2 - i][0];
        }

        for (auto i = SAMPLES2 / 2 + 1; i < SAMPLES2; ++i)
        {
            fft_cossintab86[i][0] = -fft_cossintab86[SAMPLES2 - i][0];
            fft_cossintab86[i][1] = fft_cossintab86[SAMPLES2 - i][1];
        }
    }

    /// @brief The top level FFT function for 16-bit samples. This will automatically initialize everything when called the first time.
    /// This computes the amplitude spectrum for the positive frequencies only. Hence, ana can have half the elements of samp
    /// @param ana The array where the resulting data is written. This cannot be NULL
    /// @param samp An array of 16-bit samples
    /// @param inc The number to use to get to the next sample in samp. For stereo interleaved samples use 2, else 1
    /// @param bits The size of the sample data. So if bits = 9, then samples = 1 << 9 or 512
    /// @return Returns the power level of the audio
    auto DoInteger(uint16_t *ana, const int16_t *samp, int inc, int bits)
    {
        const auto full = std::min(1 << bits, SAMPLES);
        const auto half = full >> 1;
        auto intensity = 0.0f;

        for (auto i = 0; i < full; ++i)
        {
            auto sample = float(*samp) * S16_TO_F32_MUL;
            fft_x86[i][0] = *samp << 12;
            intensity = intensity + sample * sample;
            samp += inc;
            fft_x86[i][1] = 0;
        }
        intensity = (float)inc * intensity / (float)full;

        Do86(fft_x86, bits);

        for (auto i = 1; i <= half; ++i)
        {
            auto xr0 = fft_x86[fft_permtab[i] >> (POW - bits)][0] >> 12;
            auto xr1 = fft_x86[fft_permtab[i] >> (POW - bits)][1] >> 12;
            ana[i - 1] = std::sqrt((xr0 * xr0 + xr1 * xr1) * i);
        }

        return intensity;
    }

    /// @brief This is a variation of AnalyzerFFTInteger() for floating point samples.
    /// The samples are converted to 16-bit on the fly. It automatically initialize everything when called the first time.
    /// This computes the amplitude spectrum for the positive frequencies only. Hence, ana can have half the elements of samp
    /// @param ana The array where the resulting data is written. This cannot be NULL
    /// @param samp An array of floating point (FP32) samples
    /// @param inc The number to use to get to the next sample in samp. For stereo interleaved samples use 2, else 1
    /// @param bits The size of the sample data. So if bits = 9, then samples = 1 << 9 or 512
    /// @return Returns the power level of the audio
    float DoSingle(uint16_t *ana, const float *samp, int inc, int bits)
    {
        const auto full = std::min(1 << bits, SAMPLES);
        const auto half = full >> 1;
        auto intensity = 0.0f;

        for (auto i = 0; i < full; ++i)
        {
            auto sample = *samp;
            fft_x86[i][0] = (int32_t)(fmaxf(fminf(sample, 1.0f), -1.0f) * F32_TO_S16_MUL) << 12;
            intensity = intensity + sample * sample;
            samp += inc;
            fft_x86[i][1] = 0;
        }
        intensity = (float)inc * intensity / (float)full;

        Do86(fft_x86, bits);

        for (auto i = 1; i <= half; ++i)
        {
            auto xr0 = fft_x86[fft_permtab[i] >> (POW - bits)][0] >> 12;
            auto xr1 = fft_x86[fft_permtab[i] >> (POW - bits)][1] >> 12;
            ana[i - 1] = std::sqrt((xr0 * xr0 + xr1 * xr1) * i);
        }

        return intensity;
    }
};

static AnalyzerFFT g_AnalyzerFFT;

float AnalyzerFFTInteger(uint16_t *ana, const int16_t *samp, int inc, int bits)
{
    return g_AnalyzerFFT.DoInteger(ana, samp, inc, bits);
}

float AnalyzerFFTSingle(uint16_t *ana, const float *samp, int inc, int bits)
{
    return g_AnalyzerFFT.DoSingle(ana, samp, inc, bits);
}

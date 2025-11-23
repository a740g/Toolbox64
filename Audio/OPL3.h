//----------------------------------------------------------------------------------------------------------------------
// OPL3 emulation for QB64-PE using Opal
// Copyright (c) 2024 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "../Core/Types.h"
#include "../external/opal.h"
#include <memory>

class OPL3 {
  private:
    std::unique_ptr<Opal> chip;
    uint32_t sampleRate;

  public:
    OPL3(uint32_t sampleRate) {
        this->sampleRate = sampleRate;
        Reset();
    }

    ~OPL3() {
        chip.reset();
    }

    void Reset() {
        chip.reset();
        chip = std::make_unique<Opal>(sampleRate);
    }

    uint32_t GetSampleRate() const {
        return sampleRate;
    }

    void WriteRegister(uint16_t address, uint8_t data) {
        chip->Port(address, data);
    }

    void GenerateSamples(float *buffer, uint32_t frames) {
        static constexpr float normalization_factor = 1.0f / 32768.0f;

        std::pair<int16_t, int16_t> output;
        uint32_t sample = 0;

        while (sample < frames * 2) {
            chip->Sample(&output.first, &output.second);
            buffer[sample] = output.first * normalization_factor;
            buffer[sample + 1] = output.second * normalization_factor;

            sample += 2;
        }
    }

    OPL3() = delete;
    OPL3(const OPL3 &) = delete;
    OPL3(OPL3 &&) = delete;
    OPL3 &operator=(const OPL3 &) = delete;
    OPL3 &operator=(OPL3 &&) = delete;
};

static std::unique_ptr<OPL3> g_OPL3Chip;

inline qb_bool __OPL3_Initialize(uint32_t sampleRate) {
    if (g_OPL3Chip)
        return QB_TRUE;

    if (!sampleRate)
        return QB_FALSE;

    g_OPL3Chip = std::make_unique<OPL3>(sampleRate);

    return TO_QB_BOOL(g_OPL3Chip != nullptr);
}

inline void __OPL3_Finalize() {
    if (!g_OPL3Chip)
        return;

    g_OPL3Chip.reset();
}

inline qb_bool OPL3_IsInitialized() {
    return TO_QB_BOOL(g_OPL3Chip != nullptr);
}

inline void OPL3_Reset() {
    if (!g_OPL3Chip)
        return;

    g_OPL3Chip->Reset();
}

inline void OPL3_WriteRegister(uint16_t address, uint8_t data) {
    if (!g_OPL3Chip)
        return;

    g_OPL3Chip->WriteRegister(address, data);
}

inline void __OPL3_GenerateSamples(float *buffer, uint32_t frames) {
    if (!g_OPL3Chip)
        return;

    g_OPL3Chip->GenerateSamples(buffer, frames);
}

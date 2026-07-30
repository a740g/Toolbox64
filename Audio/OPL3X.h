//----------------------------------------------------------------------------------------------------------------------
// OPL3 emulation for QB64-PE using Opal
// Copyright (c) 2026 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "../Core/Types.h"
#include "../external/opal.h"
#include <algorithm>
#include <cstdint>
#include <memory>
#include <vector>

class OPL3X {
  public:
    OPL3X(uint32_t chipCount, uint32_t sampleRateHz) {
        if (chipCount < 1) {
            chipCount = 1;
        }

        sampleRate = sampleRateHz ? sampleRateHz : 44100;

        chips.resize(chipCount);

        for (size_t i = 0; i < chips.size(); ++i) {
            chips[i] = std::make_unique<Opal>(sampleRate);
        }
    }

    ~OPL3X() {
        chips.clear();
    }

    void Reset() {
        for (auto &chip : chips) {
            chip.reset();
            chip = std::make_unique<Opal>(sampleRate);
        }
    }

    uint32_t GetSampleRate() const {
        return sampleRate;
    }

    uint32_t GetChipCount() const {
        return static_cast<uint32_t>(chips.size());
    }

    bool WriteRegister(uint32_t chipIndex, uint16_t address, uint8_t data) {
        if (chipIndex >= chips.size()) {
            return false;
        }

        chips[chipIndex]->Port(address, data);

        return true;
    }

    bool WriteRegister(uint16_t address, uint8_t data) {
        if (chips.empty()) {
            return false;
        }

        for (auto &chip : chips) {
            chip->Port(address, data);
        }

        return true;
    }

    void GetFrame(float *left, float *right) {
        int32_t mixedLeft = 0, mixedRight = 0;

        for (size_t i = 0; i < chips.size(); ++i) {
            int16_t chipLeft, chipRight;
            chips[i]->Sample(&chipLeft, &chipRight);

            mixedLeft += chipLeft;
            mixedRight += chipRight;
        }

        *left = std::clamp(mixedLeft, -32768, 32767) * SampleNormalizationFactor;
        *right = std::clamp(mixedRight, -32768, 32767) * SampleNormalizationFactor;
    }

    void GetFrames(float *buffer, uint32_t frames) {
        size_t sampleIndex = 0;
        size_t sampleCount = static_cast<size_t>(frames) << 1;

        while (sampleIndex < sampleCount) {
            GetFrame(&buffer[sampleIndex], &buffer[sampleIndex + 1]);
            sampleIndex += 2;
        }
    }

    void MixFrames(float *buffer, uint32_t frames) {
        size_t sampleIndex = 0;
        size_t sampleCount = static_cast<size_t>(frames) << 1;

        while (sampleIndex < sampleCount) {
            float leftSample, rightSample;
            GetFrame(&leftSample, &rightSample);

            buffer[sampleIndex] += leftSample;
            buffer[sampleIndex + 1] += rightSample;

            sampleIndex += 2;
        }
    }

    OPL3X() = delete;
    OPL3X(const OPL3X &) = delete;
    OPL3X(OPL3X &&) = delete;
    OPL3X &operator=(const OPL3X &) = delete;
    OPL3X &operator=(OPL3X &&) = delete;

  private:
    static constexpr float SampleNormalizationFactor = 1.0f / 32768.0f;

    std::vector<std::unique_ptr<Opal>> chips;
    uint32_t sampleRate;
};

uintptr_t OPL3X_CreateEx(uint32_t chipCount, uint32_t sampleRate) {
    if (!sampleRate) {
        return 0;
    }

    try {
        return reinterpret_cast<uintptr_t>(new OPL3X(chipCount, sampleRate));
    } catch (...) {
        return 0;
    }
}

void OPL3X_Destroy(uintptr_t emulator) {
    delete reinterpret_cast<OPL3X *>(emulator);
}

void OPL3X_Reset(uintptr_t emulator) {
    reinterpret_cast<OPL3X *>(emulator)->Reset();
}

uint32_t OPL3X_GetSampleRate(uintptr_t emulator) {
    return reinterpret_cast<OPL3X *>(emulator)->GetSampleRate();
}

uint32_t OPL3X_GetChipCount(uintptr_t emulator) {
    return reinterpret_cast<OPL3X *>(emulator)->GetChipCount();
}

qb_bool OPL3X_WriteChipRegister(uintptr_t emulator, uint32_t chipIndex, uint16_t address, uint8_t data) {
    return TO_QB_BOOL(reinterpret_cast<OPL3X *>(emulator)->WriteRegister(chipIndex, address, data));
}

qb_bool OPL3X_WriteRegister(uintptr_t emulator, uint16_t address, uint8_t data) {
    return TO_QB_BOOL(reinterpret_cast<OPL3X *>(emulator)->WriteRegister(address, data));
}

void OPL3X_GetFrame(uintptr_t emulator, float *leftSample, float *rightSample) {
    reinterpret_cast<OPL3X *>(emulator)->GetFrame(leftSample, rightSample);
}

void OPL3X_GetFrames(uintptr_t emulator, float *buffer, uint32_t frames) {
    reinterpret_cast<OPL3X *>(emulator)->GetFrames(buffer, frames);
}

void OPL3X_MixFrames(uintptr_t emulator, float *buffer, uint32_t frames) {
    reinterpret_cast<OPL3X *>(emulator)->MixFrames(buffer, frames);
}

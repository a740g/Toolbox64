//----------------------------------------------------------------------------------------------------------------------
// OPL3 emulation for QB64-PE using ymfm
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Types.h"
#include "external/ymfm/ymfm_adpcm.cpp"
#include "external/ymfm/ymfm_pcm.cpp"
#include "external/ymfm/ymfm_opl.cpp"

class OPL3 : public ymfm::ymfm_interface
{
private:
    static const auto MASTER_CLOCK = 14318181;
    static const auto RSM_FRAC = 10;

    ymfm::ymf262 *chip;
    uint32_t chipSampleRate;
    uint32_t sampleRate;
    int32_t rateRatio;
    int32_t sampleCnt;
    ymfm::ymf262::output_data outputFrame;
    ymfm::ymf262::output_data oldOutputFrame;
    float gain;

public:
    OPL3(uint32_t sampleRate) : ymfm::ymfm_interface()
    {
        chip = new ymfm::ymf262(*this);
        chipSampleRate = chip->sample_rate(MASTER_CLOCK);
        this->sampleRate = sampleRate;
        rateRatio = (sampleRate << RSM_FRAC) / chipSampleRate;
        sampleCnt = 0;
        outputFrame.clear();
        oldOutputFrame.clear();
        SetGain(1.0f);
        Reset();
    }

    ~OPL3()
    {
        delete chip;
    }

    void Reset()
    {
        chip->reset();
    }

    void SetGain(float gain)
    {
        this->gain = gain;
    }

    void WriteRegister(uint16_t address, uint8_t data)
    {
        if (address < 0x100)
            chip->write_address((uint8_t)address);
        else
            chip->write_address_hi((uint8_t)address);

        chip->write_data(data);
    }

    void GenerateSamples(float *buffer, uint32_t frames)
    {
        for (uint32_t i = 0; i < frames; i++)
        {
            while (sampleCnt >= rateRatio)
            {
                oldOutputFrame.data[0] = outputFrame.data[0];
                oldOutputFrame.data[1] = outputFrame.data[1];
                oldOutputFrame.data[2] = outputFrame.data[2];
                oldOutputFrame.data[3] = outputFrame.data[3];

                chip->generate(&outputFrame);

                sampleCnt -= rateRatio;
            }

            auto buf0 = (int16_t)((oldOutputFrame.data[0] * (rateRatio - sampleCnt) + outputFrame.data[0] * sampleCnt) / rateRatio);
            auto buf1 = (int16_t)((oldOutputFrame.data[1] * (rateRatio - sampleCnt) + outputFrame.data[1] * sampleCnt) / rateRatio);
            auto buf2 = (int16_t)((oldOutputFrame.data[2] * (rateRatio - sampleCnt) + outputFrame.data[2] * sampleCnt) / rateRatio);
            auto buf3 = (int16_t)((oldOutputFrame.data[3] * (rateRatio - sampleCnt) + outputFrame.data[3] * sampleCnt) / rateRatio);

            *buffer++ = ((float)(buf0 + buf2) / 32768.0f) * gain;
            *buffer++ = ((float)(buf1 + buf3) / 32768.0f) * gain;

            sampleCnt += 1 << RSM_FRAC;
        }
    }
};

static OPL3 *opl3Chip = nullptr;

inline qb_bool __OPL3_Initialize(uint32_t sampleRate)
{
    if (opl3Chip)
        return QB_TRUE;

    opl3Chip = new OPL3(sampleRate);

    return TO_QB_BOOL(opl3Chip != nullptr);
}

inline void __OPL3_Finalize()
{
    if (!opl3Chip)
        return;

    delete opl3Chip;
    opl3Chip = nullptr;
}

inline qb_bool OPL3_IsInitialized()
{
    return TO_QB_BOOL(opl3Chip != nullptr);
}

inline void OPL3_Reset()
{
    if (!opl3Chip)
        return;

    return opl3Chip->Reset();
}

inline void OPL3_SetGain(float gain)
{
    if (!opl3Chip)
        return;

    opl3Chip->SetGain(gain);
}

inline void OPL3_WriteRegister(uint16_t address, uint8_t data)
{
    if (!opl3Chip)
        return;

    opl3Chip->WriteRegister(address, data);
}

inline void __OPL3_GenerateSamples(float *buffer, uint32_t frames)
{
    if (!opl3Chip)
        return;

    opl3Chip->GenerateSamples(buffer, frames);
}

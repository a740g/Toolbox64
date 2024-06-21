#pragma once

#include "MIDIPlayer.h"
#include "primesynth.h"
#include "InstrumentBankManager.h"

class PSPlayer : public MIDIPlayer
{
public:
    PSPlayer() = delete;
    PSPlayer(const PSPlayer &) = delete;
    PSPlayer(PSPlayer &&) = delete;
    PSPlayer &operator=(const PSPlayer &) = delete;
    PSPlayer &operator=(PSPlayer &&) = delete;

    PSPlayer(InstrumentBankManager *ibm);
    virtual ~PSPlayer();

    uint32_t GetActiveVoiceCount() const override;

protected:
    virtual bool Startup() override;
    virtual void Shutdown() override;
    virtual void Render(audio_sample *buffer, uint32_t frames) override;

    virtual void SendEvent(uint32_t data) override;
    virtual void SendSysEx(const uint8_t *event, size_t size, uint32_t portNumber) override;

private:
    static constexpr unsigned renderEffectsFrameSize = 64; // the lower this block size, the more accurate the effects are

    InstrumentBankManager *instrumentBankManager;
    primesynth::Synthesizer *synth;
};

#pragma once

#include "MIDIPlayer.h"
#include "OpalMIDI.h"

class FMPlayer : public MIDIPlayer
{
public:
    FMPlayer();
    virtual ~FMPlayer();

    uint32_t GetActiveVoiceCount() const noexcept;

protected:
    virtual bool Startup() override;
    virtual void Shutdown() override;
    virtual void Render(audio_sample *buffer, uint32_t frames) override;

    virtual void SendEvent(uint32_t data) override;
    virtual void SendSysEx(const uint8_t *event, size_t size, uint32_t portNumber) override;

private:
    static constexpr unsigned chipCount = 4;                 // each OPL3 chip has 18 voices
    static constexpr unsigned renderEffectsSampleBlock = 64; // the lower this block size is the more accurate the effects are.

    OPLPlayer *synth;

    static const uint8_t defaultBank[];
};

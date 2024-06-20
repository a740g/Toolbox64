#pragma once

#include "MIDIPlayer.h"
#include "tsf.h"

class TSFPlayer : public MIDIPlayer
{
public:
    TSFPlayer();
    virtual ~TSFPlayer();

    uint32_t GetActiveVoiceCount() const override;

protected:
    virtual bool Startup() override;
    virtual void Shutdown() override;
    virtual void Render(audio_sample *buffer, uint32_t frames) override;

    virtual void SendEvent(uint32_t data) override;

private:
    tsf *synth;

    static const uint8_t defaultSoundFont[];
};

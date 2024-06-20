#pragma once

#include "MIDIPlayer.h"
#include "tsf.h"
#include "InstrumentBankManager.h"

class TSFPlayer : public MIDIPlayer
{
public:
    TSFPlayer() = delete;
    TSFPlayer(const TSFPlayer &) = delete;
    TSFPlayer(TSFPlayer &&) = delete;
    TSFPlayer &operator=(const TSFPlayer &) = delete;
    TSFPlayer &operator=(TSFPlayer &&) = delete;

    TSFPlayer(InstrumentBankManager *ibm);
    virtual ~TSFPlayer();

    uint32_t GetActiveVoiceCount() const override;

protected:
    virtual bool Startup() override;
    virtual void Shutdown() override;
    virtual void Render(audio_sample *buffer, uint32_t frames) override;

    virtual void SendEvent(uint32_t data) override;

private:
    InstrumentBankManager *instrumentBankManager;
    tsf *synth;
};

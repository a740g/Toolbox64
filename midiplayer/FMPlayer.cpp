#include "FMPlayer.h"

FMPlayer::FMPlayer(InstrumentBankManager *ibm) : MIDIPlayer(), instrumentBankManager(ibm), synth(nullptr)
{
    Startup();
}

FMPlayer::~FMPlayer()
{
    Shutdown();
}

bool FMPlayer::Startup()
{
    if (_IsInitialized)
        return true;

    if (!instrumentBankManager || instrumentBankManager->GetType() != InstrumentBankManager::Type::Opal)
        return false;

    synth = new OPLPlayer(chipCount, _SampleRate);
    if (synth)
    {
        if (instrumentBankManager->GetLocation() == InstrumentBankManager::Location::File)
        {
            if (!synth->loadPatches(instrumentBankManager->GetPath()))
            {
                delete synth;
                synth = nullptr;

                return false;
            }
        }
        else
        {
            if (!synth->loadPatches(instrumentBankManager->GetData(), instrumentBankManager->GetDataSize()))
            {
                delete synth;
                synth = nullptr;

                return false;
            }
        }

        _MIDIFlavor = MIDIFlavor::None;
        _FilterEffects = false;
        _IsInitialized = true;

        return true;
    }

    return false;
}

void FMPlayer::Shutdown()
{
    delete synth;
    synth = nullptr;
    _IsInitialized = false;
}

uint32_t FMPlayer::GetActiveVoiceCount() const
{
    return synth->activeVoiceCount();
}

void FMPlayer::Render(audio_sample *buffer, uint32_t frames)
{
    auto data = buffer;

    while (frames != 0)
    {
        auto todo = (frames > FMPlayer::renderEffectsFrameSize) ? FMPlayer::renderEffectsFrameSize : frames;

        synth->generate(data, todo);

        data += (todo << 1);
        frames -= todo;
    }
}

void FMPlayer::SendEvent(uint32_t message)
{
    auto channel = uint8_t(message & 0x0F);
    auto command = uint8_t(message & 0xF0);
    auto param1 = uint8_t((message >> 8) & 0xFF);
    auto param2 = uint8_t((message >> 16) & 0xFF);

    if (param1 > 0x7F)
        param1 = 0x7F;

    if (param2 > 0x7F)
        param2 = 0x7F;

    switch (command)
    {
    case MIDI_EVENT_NOTE_OFF:
        synth->midiNoteOff(channel, param1);
        break;

    case MIDI_EVENT_NOTE_ON:
        synth->midiNoteOn(channel, param1, param2);
        break;

    case MIDI_EVENT_CONTROLLER:
        synth->midiControlChange(channel, param1, param2);
        break;

    case MIDI_EVENT_PROGRAM_CHANGE:
        synth->midiProgramChange(channel, param1);
        break;

    case MIDI_EVENT_PITCH_BEND:
        synth->midiPitchControl(channel, double((int16_t)(param1 | (param2 << 7)) - 8192) / 8192.0);
        break;
    }
}

void FMPlayer::SendSysEx(const uint8_t *event, size_t size, uint32_t portNumber)
{
    synth->midiSysEx(event, size);
}

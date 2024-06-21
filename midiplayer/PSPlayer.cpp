#include "PSPlayer.h"

PSPlayer::PSPlayer(InstrumentBankManager *ibm) : MIDIPlayer(), instrumentBankManager(ibm), synth(nullptr)
{
    Startup();
}

PSPlayer::~PSPlayer()
{
    Shutdown();
}

uint32_t PSPlayer::GetActiveVoiceCount() const
{
    return 0;
}

bool PSPlayer::Startup()
{
    if (_IsInitialized)
        return true;

    if (!instrumentBankManager || instrumentBankManager->GetType() != InstrumentBankManager::Type::Primesynth || instrumentBankManager->GetLocation() == InstrumentBankManager::Location::Memory)
        return false;

    try
    {
        synth = new primesynth::Synthesizer(_SampleRate);
    }
    catch (...)
    {
        return false;
    }

    if (synth)
    {
        try
        {
            synth->loadSoundFont(instrumentBankManager->GetPath());
        }
        catch (...)
        {
            delete synth;
            synth = nullptr;

            return false;
        }

        _MIDIFlavor = MIDIFlavor::None;
        _FilterEffects = false;
        _IsInitialized = true;

        return true;
    }

    return false;
}

void PSPlayer::Shutdown()
{
    delete synth;
    synth = nullptr;
    _IsInitialized = false;
}

void PSPlayer::Render(audio_sample *buffer, uint32_t frames)
{
    auto data = buffer;

    while (frames != 0)
    {
        auto todo = frames > PSPlayer::renderEffectsFrameSize ? PSPlayer::renderEffectsFrameSize : frames;

        try
        {
            synth->render_float(data, todo << 1);
        }
        catch (...)
        {
            return;
        }

        data += (todo << 1);
        frames -= todo;
    }
}

void PSPlayer::SendEvent(uint32_t data)
{
    auto channel = uint8_t(data & 0x0F);
    auto command = uint8_t(data & 0xF0);
    auto param1 = uint8_t((data >> 8) & 0xFF);
    auto param2 = uint8_t((data >> 16) & 0xFF);

    if (param1 > 0x7F)
        param1 = 0x7F;

    if (param2 > 0x7F)
        param2 = 0x7F;

    try
    {
        switch (command)
        {
        case MIDI_EVENT_NOTE_OFF:
            synth->processChannelMessage(primesynth::midi::MessageStatus::NoteOff, channel, param1);
            break;

        case MIDI_EVENT_NOTE_ON:
            synth->processChannelMessage(primesynth::midi::MessageStatus::NoteOn, channel, param1, param2);
            break;

        case MIDI_EVENT_NOTE_AFTERTOUCH:
            synth->processChannelMessage(primesynth::midi::MessageStatus::KeyPressure, channel, param1, param2);
            break;

        case MIDI_EVENT_CONTROLLER:
            synth->processChannelMessage(primesynth::midi::MessageStatus::ControlChange, channel, param1, param2);
            break;

        case MIDI_EVENT_PROGRAM_CHANGE:
            synth->processChannelMessage(primesynth::midi::MessageStatus::ProgramChange, channel, param1);
            break;

        case MIDI_EVENT_CHAN_AFTERTOUCH:
            synth->processChannelMessage(primesynth::midi::MessageStatus::ChannelPressure, channel, param1);
            break;

        case MIDI_EVENT_PITCH_BEND:
            synth->processChannelMessage(primesynth::midi::MessageStatus::PitchBend, channel, param1, param2);
            break;
        }
    }
    catch (...)
    {
        return;
    }
}

void PSPlayer::SendSysEx(const uint8_t *event, size_t size, uint32_t portNumber)
{
    try
    {
        synth->processSysEx(reinterpret_cast<const char *>(event), size);
    }
    catch (...)
    {
        return;
    }
}

#include "TSFPlayer.h"
#define STB_VORBIS_HEADER_ONLY
#include "../external/stb/stb_vorbis.c"
#define TSF_IMPLEMENTATION
#include "tsf.h"
#include "SoundFont.h"

TSFPlayer::TSFPlayer() : MIDIPlayer()
{
    synth = nullptr;

    Startup();
}

TSFPlayer::~TSFPlayer()
{
    Shutdown();
}

bool TSFPlayer::Startup()
{
    if (_IsInitialized)
        return true;

    synth = tsf_load_memory(defaultSoundFont, sizeof(defaultSoundFont)); // attempt to load the soundfont from memory

    if (synth)
    {
        tsf_channel_set_bank_preset(synth, 9, 128, 0);              // initialize preset on special 10th MIDI channel to use percussion sound bank (128) if available
        tsf_set_output(synth, TSF_STEREO_INTERLEAVED, _SampleRate); // set the SoundFont rendering output mode

        _MIDIFlavor = MIDIFlavor::None;
        _FilterEffects = false;
        _IsInitialized = true;

        return true;
    }

    return false;
}

void TSFPlayer::Shutdown()
{
    tsf_close(synth);
    synth = nullptr;
    _IsInitialized = false;
}

uint32_t TSFPlayer::GetActiveVoiceCount() const
{
    return tsf_active_voice_count(synth);
}

void TSFPlayer::Render(audio_sample *buffer, uint32_t frames)
{
    auto data = buffer;

    while (frames != 0)
    {
        auto todo = frames > TSF_RENDER_EFFECTSAMPLEBLOCK ? TSF_RENDER_EFFECTSAMPLEBLOCK : frames;

        tsf_render_float(synth, data, todo, true);

        data += (todo << 1);
        frames -= todo;
    }
}

void TSFPlayer::SendEvent(uint32_t message)
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
        tsf_channel_note_off(synth, channel, param1);
        break;

    case MIDI_EVENT_NOTE_ON:
        tsf_channel_note_on(synth, channel, param1, float(param2) / 127.0f);
        break;

    case MIDI_EVENT_CONTROLLER:
        tsf_channel_midi_control(synth, channel, param1, param2);
        break;

    case MIDI_EVENT_PROGRAM_CHANGE:
        tsf_channel_set_presetnumber(synth, channel, param1, channel == 9);
        tsf_channel_midi_control(synth, channel, 123, 0); // ALL_NOTES_OFF; https://github.com/schellingb/TinySoundFont/issues/59
        break;

    case MIDI_EVENT_PITCH_BEND:
        tsf_channel_set_pitchwheel(synth, channel, uint32_t(param1) | uint32_t(param2 << 7));
        break;
    }
}

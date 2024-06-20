#pragma once

#include "MIDIContainer.h"

#define MIDI_EVENT_NOTE_OFF 0x80
#define MIDI_EVENT_NOTE_ON 0x90
#define MIDI_EVENT_NOTE_AFTERTOUCH 0xa0
#define MIDI_EVENT_CONTROLLER 0xb0
#define MIDI_EVENT_PROGRAM_CHANGE 0xc0
#define MIDI_EVENT_CHAN_AFTERTOUCH 0xd0
#define MIDI_EVENT_PITCH_BEND 0xe0
#define MIDI_EVENT_SYSEX 0xf0
#define MIDI_CONTROLLER_MAIN_VOLUME 0x7
#define MIDI_CONTROLLER_PAN 0xa
#define MIDI_CONTROLLER_ALL_NOTES_OFF 0x7b

typedef float audio_sample;

enum class MIDIFlavor
{
    None = 0,
    GM,
    GM2,
    SC55,
    SC88,
    SC88Pro,
    SC8850,
    XG
};

enum class LoopType
{
    NeverLoop = 0,             // Never loop
    NeverLoopAddDecayTime = 1, // Never loop, add configured decay time at the end

    LoopAndFadeWhenDetected = 2, // Loop and fade when detected
    LoopAndFadeAlways = 3,       // Loop and fade always

    PlayIndefinitelyWhenDetected = 4, // Play indefinitely when detected
    PlayIndefinitely = 5,             // Play indefinitely
};

enum
{
    DefaultSampleRate = 44100,
    DefaultPlaybackLoopType = 0,
    DefaultOtherLoopType = 0,
    DefaultDecayTime = 1000,

    default_cfg_thloopz = 1,
    default_cfg_rpgmloopz = 1,
    default_cfg_xmiloopz = 1,
    default_cfg_ff7loopz = 1,

    DefaultMIDIFlavor = (int)MIDIFlavor::None,
    DefaultUseMIDIEffects = 1,
    DefaultUseSuperMuntWithMT32 = 1,
    DefaultUseSecretSauceWithXG = 0,

    DefaultEmuDeMIDIExclusion = 1,
    DefaultFilterInstruments = 0,
    DefaultFilterBanks = 0,

    DefaultBASSMIDIInterpolationMode = 1,

    DefaultGMSet = 0,

    // Munt
    DefaultNukeSynth = 0,
    DefaultNukeBank = 2,
    DefaultNukePanning = 0,

    DefaultADLBank = 72,
    DefaultADLChipCount = 10,
    DefaultADLPanning = 1,
    //  DefaultADL4Op = 14,
};

class MIDIPlayer
{
public:
    MIDIPlayer();
    virtual ~MIDIPlayer(){};

    enum LoopMode
    {
        None = 0x00,
        Enabled = 0x01,
        Forced = 0x02
    };

    bool Load(const MIDIContainer &midiContainer, uint32_t subsongIndex, LoopType loopMode, uint32_t cleanFlags);
    uint32_t Play(audio_sample *samples, uint32_t samplesSize) noexcept;
    void Seek(uint32_t seekTime);

    void SetSampleRate(uint32_t sampleRate);

    void Configure(MIDIFlavor midiFlavor, bool filterEffects);

    uint32_t GetPosition() const noexcept { return uint32_t((uint64_t(_Position) * 1000ul) / uint64_t(_SampleRate)); }

    virtual uint32_t GetActiveVoiceCount() const { return 0; }

    virtual bool GetErrorMessage(std::string &) { return false; }

protected:
    virtual bool Startup() { return false; }
    virtual void Shutdown() {};
    virtual void Render(audio_sample *, uint32_t) {}
    virtual bool Reset() { return false; }

    // Should return the block size that the player expects, otherwise 0.
    virtual uint32_t GetSampleBlockSize() const noexcept { return 0; }

    virtual void SendEvent(uint32_t) {}
    virtual void SendSysEx(const uint8_t *, size_t, uint32_t) {};

    // Only implemented by Secret Sauce and VSTi-specific
    virtual void SendEvent(uint32_t, uint32_t){};
    virtual void SendSysEx(const uint8_t *, size_t, uint32_t, uint32_t) {};

    void SendSysExReset(uint8_t portNumber, uint32_t time);

    uint32_t GetProcessorArchitecture(const std::string &filePath) const;

protected:
    bool _IsInitialized;
    uint32_t _SampleRate;
    SysExTable _SysExMap;

    MIDIFlavor _MIDIFlavor;
    bool _FilterEffects;

private:
    void SendEventFiltered(uint32_t data);
    void SendEventFiltered(uint32_t data, uint32_t time);

    void SendSysExFiltered(const uint8_t *event, size_t size, uint8_t portNumber);
    void SendSysExFiltered(const uint8_t *event, size_t size, uint8_t portNumber, uint32_t time);

    void SendSysExSetToneMapNumber(uint8_t portNumber, uint32_t time);
    void SendSysExGS(uint8_t *data, size_t size, uint8_t portNumber, uint32_t time);

    static inline constexpr int MulDiv(int v1, int v2, int v3)
    {
        return lround((double)v1 * (double)v2 / (double)v3);
    }

private:
    std::vector<MIDIStreamEvent> _Stream;
    size_t _StreamPosition; // Current position in the event stream

    uint32_t _Position;  // Current position in the sample stream
    uint32_t _Length;    // Total length of the sample stream
    uint32_t _Remainder; // In samples

    LoopType _LoopType;

    uint32_t _StreamLoopBegin;
    uint32_t _StreamLoopEnd;

    uint32_t _LoopBegin; // Position of the start of a loop in the sample stream
};
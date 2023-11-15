//----------------------------------------------------------------------------------------------------------------------
// Simple floatimg-point stereo PCM software synthesizer
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Debug.h"
#include "Types.h"
#include "MathOps.h"
#include <cstdint>
#include <vector>
#include <memory>

struct Voice
{
    static const auto NO_SOUND = -1; // used to unbind a sound from a voice

    /// @brief Various playing modes
    enum PlayMode
    {
        FORWARD = 0,        // single-shot forward playback
        FORWARD_LOOP,       // forward-looping playback
        REVERSE,            // single-shot reverse playback
        REVERSE_LOOP,       // reverse-looping playback
        BIDIRECTIONAL_LOOP, // bi-directional looping playback
        COUNT               // total number of playback modes
    };

    int32_t sound;          // the Sound to be mixed. This is set to -1 once the mixer is done with the Sound
    uint32_t frequency;     // the frequency of the sound
    float pitch;            // the mixer uses this to step through the sound frames correctly
    float volume;           // voice volume (0.0 - 1.0)
    float balance;          // position -0.5 is leftmost ... 0.5 is rightmost
    float position;         // sample frame position in the sound buffer
    uint32_t startPosition; // this can be loop start or just start depending on play mode (in frames!)
    uint32_t endPosition;   // this can be loop end or just end depending on play mode (in frames!)
    int32_t mode;           // how should the sound be played?
    float frame;            // current frame
    float oldFrame;         // the previous frame

    /// @brief Initialized the voice (including pan position)
    Voice()
    {
        Reset();
        balance = 0.0f; // center the voice only when creating it the first time
    }

    /// @brief Resets the voice to defaults. Balance is intentionally left out so that we do not reset pan positions set by the user
    void Reset()
    {
        sound = NO_SOUND;
        volume = 1.0f;
        frequency = startPosition = endPosition = 0;
        position = pitch = frame = oldFrame = 0.0f;
        mode = PlayMode::FORWARD;
    }
};

struct SoftSynth
{
    std::vector<std::vector<float>> sounds; // managed sounds
    std::vector<Voice> voices;              // managed voices
    uint32_t sampleRate;                    // the mixer sampling rate
    uint32_t activeVoices;                  // active voices
    float volume;                           // global volume (0.0 - 1.0)
};

static std::unique_ptr<SoftSynth> g_SoftSynth; // global softynth object

static inline constexpr bool SoftSynth_IsChannelsValid(uint8_t channels)
{
    return channels >= 1;
}

static inline constexpr bool SoftSynth_IsBytesPerSampleValid(uint8_t bytesPerSample)
{
    return bytesPerSample == sizeof(int8_t) or bytesPerSample == sizeof(int16_t) or bytesPerSample == sizeof(float);
}

inline constexpr uint32_t SoftSynth_BytesToFrames(uint32_t bytes, uint8_t bytesPerSample, uint8_t channels)
{
    return bytes / ((uint32_t)bytesPerSample * (uint32_t)channels);
}

inline void __SoftSynth_ConvertU8ToS8(char *source, uint32_t frames)
{
    auto buffer = reinterpret_cast<uint8_t *>(source);

    for (size_t i = 0; i < frames; i++)
        buffer[i] ^= 0x80; // xor_eq
}

/// @brief Initializes the SoftSynth object
/// @param sampleRate This should ideally be the device sampling rate
inline qb_bool __SoftSynth_Initialize(uint32_t sampleRate)
{
    if (g_SoftSynth)
        return QB_TRUE;

    if (!sampleRate)
        return QB_FALSE;

    g_SoftSynth = std::make_unique<SoftSynth>();
    if (!g_SoftSynth)
        return QB_FALSE;

    g_SoftSynth->sampleRate = sampleRate;
    g_SoftSynth->activeVoices = 0;
    g_SoftSynth->volume = 1.0f;

    return QB_TRUE;
}

inline void __SoftSynth_Finalize()
{
    g_SoftSynth.reset();
}

inline qb_bool SoftSynth_IsInitialized()
{
    return TO_QB_BOOL(g_SoftSynth != nullptr);
}

uint32_t SoftSynth_GetSampleRate()
{
    if (!g_SoftSynth)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return g_SoftSynth->sampleRate;
}

uint32_t SoftSynth_GetTotalSounds()
{
    if (!g_SoftSynth)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return (uint32_t)g_SoftSynth->sounds.size();
}

uint32_t SoftSynth_GetTotalVoices()
{
    if (!g_SoftSynth)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return (uint32_t)g_SoftSynth->voices.size();
}

void SoftSynth_SetTotalVoices(uint32_t voices)
{
    if (!g_SoftSynth or voices < 1)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices.clear();
    g_SoftSynth->voices.resize(voices);
}

uint32_t SoftSynth_GetActiveVoices()
{
    if (!g_SoftSynth)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return g_SoftSynth->activeVoices;
}

float SoftSynth_GetGlobalVolume()
{
    if (!g_SoftSynth)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_SoftSynth->volume;
}

void SoftSynth_SetGlobalVolume(float volume)
{
    if (!g_SoftSynth)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->volume = Math_ClampSingle(volume, 0.0f, 1.0f);
}

/// @brief Copies and prepares the sound data in memory. Multi-channel sounds are flattened to mono.
/// All sample types are converted to 32-bit floating point. All interger based samples passed must be signed.
/// @param sound The sound slot / index
/// @param source A pointer to the raw sound data
/// @param bytes The size of the raw sound in bytes
/// @param bytesPerSample The bytes / samples (this can be 1 for 8-bit, 2 for 16-bit or 3 for 32-bit)
/// @param channels The number of channels (this must be 1 or more)
inline void __SoftSynth_LoadSound(int32_t sound, const char *const source, uint32_t bytes, uint8_t bytesPerSample, uint8_t channels)
{
    if (!g_SoftSynth or sound < 0 or !source or !SoftSynth_IsBytesPerSampleValid(bytesPerSample) or !SoftSynth_IsChannelsValid(channels))
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    // Resize the vector to fit the number of sounds if needed
    if (sound >= g_SoftSynth->sounds.size())
        g_SoftSynth->sounds.resize(sound + 1);

    auto frames = SoftSynth_BytesToFrames(bytes, bytesPerSample, channels);
    auto &data = g_SoftSynth->sounds[sound];

    data.clear(); // resize to zero frames

    if (!frames)
        return; // no need to proceed if we have no frames to load

    data.resize(frames); // resize the buffer

    switch (bytesPerSample)
    {
    case sizeof(int8_t):
    {
        auto src = reinterpret_cast<const int8_t *>(source);
        for (size_t i = 0; i < frames; i++)
        {
            // Flatten all channels to mono
            for (auto j = 0; j < channels; j++)
            {
                data[i] += *src / 128.0f;
                ++src;
            }
        }
    }
    break;

    case sizeof(int16_t):
    {
        auto src = reinterpret_cast<const int16_t *>(source);
        for (size_t i = 0; i < frames; i++)
        {
            // Flatten all channels to mono
            for (auto j = 0; j < channels; j++)
            {
                data[i] += *src / 32768.0f;
                ++src;
            }
        }
    }
    break;

    case sizeof(float):
    {
        auto src = reinterpret_cast<const float *>(source);
        for (size_t i = 0; i < frames; i++)
        {
            // Flatten all channels to mono
            for (auto j = 0; j < channels; j++)
            {
                data[i] += *src;
                ++src;
            }
        }
    }
    break;

    default:
        error(ERROR_ILLEGAL_FUNCTION_CALL);
    }
}

/// @brief Gets a raw sound frame (in fp32 format)
/// @param sound The sound slot / index
/// @param position The frame position
/// @return A floating point sample frame
float SoftSynth_PeekSoundFrameSingle(int32_t sound, uint32_t position)
{
    if (!g_SoftSynth or sound < 0 or sound >= g_SoftSynth->sounds.size() or position >= g_SoftSynth->sounds[sound].size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_SoftSynth->sounds[sound][position];
}

/// @brief Sets a raw sound frame (in fp32 format)
/// @param sound The sound slot / index
/// @param position The frame position
/// @param frame A floating point sample frame
void SoftSynth_PokeSoundFrameSingle(int32_t sound, uint32_t position, float frame)
{
    if (!g_SoftSynth or sound < 0 or sound >= g_SoftSynth->sounds.size() or position >= g_SoftSynth->sounds[sound].size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->sounds[sound][position] = frame;
}

inline int16_t SoftSynth_PeekSoundFrameInteger(int32_t sound, uint32_t position)
{
    return SoftSynth_PeekSoundFrameSingle(sound, position) * 32768.0f;
}

inline void SoftSynth_PokeSoundFrameInteger(int32_t sound, uint32_t position, int16_t frame)
{
    static constexpr auto SOFTSYNTH_POKESOUNDFRAMEINTEGER_MULTIPLIER = 1.0f / 32768.0f;
    SoftSynth_PokeSoundFrameSingle(sound, position, SOFTSYNTH_POKESOUNDFRAMEINTEGER_MULTIPLIER * frame);
}

inline int8_t SoftSynth_PeekSoundFrameByte(int32_t sound, uint32_t position)
{
    return SoftSynth_PeekSoundFrameSingle(sound, position) * 128.0f;
}

inline void SoftSynth_PokeSoundFrameByte(int32_t sound, uint32_t position, int8_t frame)
{
    static constexpr auto SOFTSYNTH_POKESOUNDFRAMEBYTE_MULTIPLIER = 1.0f / 128.0f;
    SoftSynth_PokeSoundFrameSingle(sound, position, SOFTSYNTH_POKESOUNDFRAMEBYTE_MULTIPLIER * frame);
}

float SoftSynth_GetVoiceVolume(uint32_t voice)
{
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_SoftSynth->voices[voice].volume;
}

void SoftSynth_SetVoiceVolume(uint32_t voice, float volume)
{
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices[voice].volume = Math_ClampSingle(volume, 0.0f, 1.0f);
}

float SoftSynth_GetVoiceBalance(uint32_t voice)
{
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_SoftSynth->voices[voice].balance * 2.0f; // scale to -1.0 to 1.0 range
}

void SoftSynth_SetVoiceBalance(uint32_t voice, float balance)
{
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices[voice].balance = Math_ClampSingle(balance * 0.5f, -0.5f, 0.5f); // scale and clamp (-1.0 to 1.0 > -0.5 to 0.5)
}

/// @brief Gets the voice frequency
/// @param voice The voice number to get the frequency for
/// @return The frequency value
uint32_t SoftSynth_GetVoiceFrequency(uint32_t voice)
{
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_SoftSynth->voices[voice].frequency;
}

/// @brief Sets the voice frequency
/// @param voice The voice number to set the frequency for
/// @param frequency The frequency to be set (must be > 0)
void SoftSynth_SetVoiceFrequency(uint32_t voice, uint32_t frequency)
{
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size() or !frequency)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices[voice].frequency = frequency; // save this to avoid a division in GetVoiceFrequency()
    g_SoftSynth->voices[voice].pitch = (float)frequency / (float)g_SoftSynth->sampleRate;
}

void SoftSynth_StopVoice(uint32_t voice)
{
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices[voice].Reset();
}

/// @brief Plays a sound using a voice
/// @param voice The voice to use to play the sound
/// @param sound The sound to play
/// @param position The position (in frames) in the sound where playback should start
/// @param mode The playback mode
/// @param start The playback start frame or loop start frame (based on playMode)
/// @param end The playback end frame or loop end frame (based on playMode)
void SoftSynth_PlayVoice(uint32_t voice, int32_t sound, uint32_t position, int32_t mode, uint32_t startPosition, uint32_t endPosition)
{
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size() or sound < 0 or sound >= g_SoftSynth->sounds.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices[voice].mode = mode < Voice::PlayMode::FORWARD or mode >= Voice::PlayMode::COUNT ? Voice::PlayMode::FORWARD : mode;
    g_SoftSynth->voices[voice].position = position;           // if this value is junk then the mixer should deal with it correctly
    g_SoftSynth->voices[voice].startPosition = startPosition; // if this value is junk then the mixer should deal with it correctly
    g_SoftSynth->voices[voice].endPosition = endPosition;     // if this value is junk then the mixer should deal with it correctly
    g_SoftSynth->voices[voice].sound = sound;
    g_SoftSynth->voices[voice].frame = 0.0f;
    g_SoftSynth->voices[voice].oldFrame = 0.0f;
}

/// @brief This mixes and writes the mixed samples to "buffer"
/// @param buffer A buffer pointer that will receive the mixed samples (the buffer is not cleared before mixing)
/// @param frames The number of frames to mix
inline void __SoftSynth_Update(float *buffer, uint32_t frames)
{
    if (!g_SoftSynth or !buffer or !frames)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    // Get the total voices we need to mix
    auto voiceCount = g_SoftSynth->voices.size();

    //  Set the active voice count to zero
    g_SoftSynth->activeVoices = 0;

    // We will iterate through each channel completely rather than jumping from channel to channel
    // We are doing this because it is easier for the CPU to access adjacent memory rather than something far away
    for (size_t v = 0; v < voiceCount; v++)
    {
        // Get the current voice we need to work with
        auto &voice = g_SoftSynth->voices[v];

        // Only proceed if we have a valid sound number (>= 0)
        if (voice.sound >= 0)
        {
            // Get the sample data we need to work with
            auto &soundData = g_SoftSynth->sounds[voice.sound];

            // Cache the total sound frames as we need to use this frequently inside the loop
            auto soundFrames = soundData.size();

            // Only proceed if we have something to play in the sound
            if (soundFrames > 0)
            {
                // Increment the active voices
                ++g_SoftSynth->activeVoices;

                // Copy the buffer address
                auto output = buffer;

                //  Next we go through the channel sample data and mix it to our mixer buffer
                for (uint32_t s = 0; s < frames; s++)
                {
                    // Check if we crossed the end of the sound and take action based on the playback mode
                    if (voice.position > voice.endPosition)
                    {
                        if (Voice::PlayMode::FORWARD_LOOP == voice.mode)
                        {
                            // Reset loop position if we reached the end of the loop
                            voice.position = voice.startPosition;
                        }
                        else
                        {
                            // For non-looping sound simply stop playing if we reached the end
                            voice.sound = Voice::NO_SOUND; // just invalidate the sound leaving other properties intact
                            break;                         // exit the mixing loop as we have no more samples to mix for this channel
                        }
                    }

                    // Fetch the sample frame to mix
                    voice.oldFrame = voice.frame; // first save the previous frame
                    auto iPos = (uint32_t)voice.position;
                    if (iPos < soundFrames)
                        voice.frame = soundData[iPos];

                    // Lerp & volume
                    auto lerpAmnt = voice.position - iPos;
                    auto outFrame = ((1.0f - lerpAmnt) * voice.oldFrame + lerpAmnt * voice.frame) * voice.volume;

                    // Move to the next sample position based on the pitch
                    voice.position += voice.pitch;

                    // Mixing and panning
                    *output += outFrame * (0.5f - voice.balance); // left channel
                    ++output;
                    *output += outFrame * (0.5f + voice.balance); // right channel
                    ++output;
                }
            }
        }
    }

    // Make one more pass to apply global volume
    auto output = buffer;
    for (uint32_t s = 0; s < frames; s++)
    {
        *output *= g_SoftSynth->volume;
        ++output;
        *output *= g_SoftSynth->volume;
        ++output;
    }
}

//----------------------------------------------------------------------------------------------------------------------
// Simple floatimg-point stereo sample-based software synthesizer
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#define TOOLBOX64_DEBUG 0
#include "Debug.h"
#include "MathOps.h"
#include <cstdint>
#include <vector>
#include <memory>

struct SoftSynth
{
    /// @brief This manages just a single raw sound in memory
    struct Sound
    {
        static const auto NO_SOUND = -1;

        std::vector<float> data; // raw sound data + size (always 32-bit floating point mono)

        /// @brief Copies and prepares the sound data in memory.Multi-channel sounds are flattened to mono.
        /// All sample types are converted to 32-bit floating point. All interger based samples passed must be signed.
        /// @param source A pointer to the raw sound data
        /// @param frames The number of frames the sound has
        /// @param bytesPerSample The bytes / samples (this can be 1 for 8-bit, 2 for 16-bit or 3 for 32-bit)
        /// @param channels The number of channels (this must be 1 or more)
        void Load(const void const *source, uint32_t frames, uint8_t bytesPerSample, uint8_t channels)
        {
            TOOLBOX64_DEBUG_CHECK(source != nullptr);
            TOOLBOX64_DEBUG_CHECK(IsBytesPerSampleValid(bytesPerSample));
            TOOLBOX64_DEBUG_CHECK(IsChannelsValid(channels));

            data.clear(); // resize to zero frames

            if (!frames)
                return; // no need to proceed if we have no frames to load

            data.resize(frames, 0.0f); // initialize all frames to silence

            TOOLBOX64_DEBUG_PRINT("Loading %i frames (%i bytes, bytes / sample = %i, channels = %i)", frames, frames * bytesPerSample * channels, (int)bytesPerSample, (int)channels);

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
                        data[i] = data[i] + *src / 128.0f;
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
                        data[i] = data[i] + *src / 32768.0f;
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
                        data[i] = data[i] + *src;
                        ++src;
                    }
                }
            }
            break;

            default:
                TOOLBOX64_DEBUG_PRINT("Unsupported bytes / sample");
            }
        }
    };

    /// @brief This is single voice that can be associated to a single sound
    struct Voice
    {
        /// @brief Various playing modes
        enum struct PlayMode
        {
            Forward = 0,
            ForwardLoop,
            Reverse,
            ReverseLoop,
            BidirectionalLoop,
            Count
        };

        /// @brief Playback direction values for BIDI mode
        enum struct PlayDirection
        {
            Reverse = -1,
            Forward = 1
        };

    private:
        float frequency; // the frequency of the sound
        double pitch;    // the mixer uses this to step through the sample correctly
    public:
        int32_t sound;           // the Sound to be mixed. This is set to -1 once the mixer is done with the Sound
        float volume;            // voice volume (0.0 - 1.0)
        float balance;           // position -0.5 is leftmost ... 0.5 is rightmost
        double position;         // sample frame position in the sample buffer
        double start;            // this can be loop start or just start depending on play mode
        double end;              // this can be loop end or just end depending on play mode
        PlayMode mode;           // how should the sound be played?
        PlayDirection direction; // direction for BIDI sounds

        /// @brief Initialized the voice (including pan position)
        Voice()
        {
            Reset();
            balance = 0.0f;
        }

        /// @brief Resets the voice to defaults. Balance is intentionally left out so that we do not reset pan positions set by the user
        void Reset()
        {
            sound = Sound::NO_SOUND;
            volume = 1.0f;
            frequency = 0;
            pitch = position = start = end = 0.0f;
            direction = PlayDirection::Forward;
            mode = PlayMode::Forward;
        }

        /// @brief Sets the voice frequency
        /// @param softSynth The parent SoftSynth object needed to get the sample rate
        /// @param frequency The frequency to be set (must be > 0)
        void SetFrequency(SoftSynth &softSynth, float frequency)
        {
            this->frequency = frequency;
            pitch = (double)frequency / (double)softSynth.sampleRate;
        }

        /// @brief Gets the voice frequency
        /// @return The frequency value
        float GetFrequency()
        {
            return frequency;
        }

        /// @brief Advances the cursor to the next playback position based on the pitch
        void MoveToNextPosition()
        {
            switch (mode)
            {
            case PlayMode::BidirectionalLoop:
                if (PlayDirection::Reverse == direction)
                {
                    position -= pitch;
                }
                else
                {
                    position += pitch;
                }
                break;

            case PlayMode::Reverse:
            case PlayMode::ReverseLoop:
                position -= pitch;
                break;

            case PlayMode::ForwardLoop:
            case PlayMode::Forward:
            default:
                position += pitch;
            }
        }
    };

    uint32_t sampleRate;       // the mixer sampling rate
    std::vector<Sound> sounds; // managed sounds
    std::vector<Voice> voices; // managed voices
    uint32_t activeVoices;     // active voices
    float volume;              // global volume

    static bool IsChannelsValid(uint8_t channels)
    {
        return channels >= 1;
    }

    static bool IsBytesPerSampleValid(uint8_t bytesPerSample)
    {
        return bytesPerSample == sizeof(int8_t) or bytesPerSample == sizeof(int16_t) or bytesPerSample == sizeof(float);
    }

    SoftSynth() = delete;
    SoftSynth(const SoftSynth &) = delete;
    SoftSynth &operator=(const SoftSynth &) = delete;
    SoftSynth &operator=(SoftSynth &&) = delete;
    SoftSynth(SoftSynth &&) = delete;

    /// @brief Initialized the SoftSynth object
    /// @param sampleRate This should ideally be the device sampling rate
    SoftSynth(uint32_t sampleRate)
    {
        this->sampleRate = sampleRate;
        activeVoices = 0;
        volume = 1.0f;

        TOOLBOX64_DEBUG_PRINT("SoftSynth initialized at sampling rate of %uhz", sampleRate);
    }

    /// @brief Loads and prepares a raw sound in memory (see Sound::Load())
    /// @param sound The sound slot / index
    /// @param source A pointer to the raw sound data
    /// @param frames The number of frames the sound has
    /// @param bytesPerSample The bytes / samples (this can be 1 for 8-bit, 2 for 16-bit or 3 for 32-bit)
    /// @param channels The number of channels (this must be 1 or more)
    void LoadSound(int32_t sound, const void const *source, uint32_t frames, uint8_t bytesPerSample, uint8_t channels)
    {
        TOOLBOX64_DEBUG_CHECK(sound >= 0);

        // Resize the vector to fit the number of sounds if needed
        if (sound >= sounds.size())
        {
            sounds.resize(sound + 1);
            TOOLBOX64_DEBUG_PRINT("SoftSynth::sounds resized to %zu", sounds.size());
        }

        TOOLBOX64_DEBUG_PRINT("Loading sound %i", sound);

        sounds[sound].Load(source, frames, bytesPerSample, channels);
    }

    /// @brief Gets a raw sound frame (in fp32 format)
    /// @param sound The sound slot / index
    /// @param position The frame position
    /// @return A floating point sample frame
    float PeekSoundFrame(int32_t sound, uint32_t position)
    {
        TOOLBOX64_DEBUG_CHECK(sound >= 0 and sound < sounds.size());
        TOOLBOX64_DEBUG_CHECK(position < sounds[sound].data.size());

        return sounds[sound].data[position];
    }

    /// @brief Sets a raw sound frame (in fp32 format)
    /// @param sound The sound slot / index
    /// @param position The frame position
    /// @param frame A floating point sample frame
    void PokeSoundFrame(int32_t sound, uint32_t position, float frame)
    {
        TOOLBOX64_DEBUG_CHECK(sound >= 0 and sound < sounds.size());
        TOOLBOX64_DEBUG_CHECK(position < sounds[sound].data.size());

        sounds[sound].data[position] = frame;
    }

    /// @brief Plays a sound using a voice
    /// @param voice The voice to use to play the sound
    /// @param sound The sound to play
    /// @param position The position (in frames) in the sound where playback should start
    /// @param mode The play mode (see PlayMode enum)
    /// @param start The playback start frame or loop start frame (based on playMode)
    /// @param end The playback end frame or loop end frame (based on playMode)
    void PlayVoice(uint32_t voice, int32_t sound, uint32_t position, SoftSynth::Voice::PlayMode mode, uint32_t start, uint32_t end)
    {
        TOOLBOX64_DEBUG_CHECK(sound >= 0 and sound < sounds.size());
        TOOLBOX64_DEBUG_CHECK(voice >= 0 and voice < voices.size());

        voices[voice].mode = mode < Voice::PlayMode::Forward or mode >= Voice::PlayMode::Count ? SoftSynth::Voice::PlayMode::Forward : mode;
        voices[voice].direction = Voice::PlayDirection::Forward;

        auto maxFrame = sounds[sound].data.size() - 1;

        TOOLBOX64_DEBUG_PRINT("Original position = %u, start = %u, end = %u", position, start, end);

        voices[voice].position = position; // if this value is junk then the mixer should deal with it correctly
        voices[voice].start = start > maxFrame ? maxFrame : start;
        voices[voice].end = end > maxFrame ? maxFrame : end;

        TOOLBOX64_DEBUG_CHECK(start < sounds[sound].data.size() and end < sounds[sound].data.size());
        TOOLBOX64_DEBUG_PRINT("Voice %u, sound %i, position = %f, start = %f, end = %f, mode = %i", voice, sound + 1, voices[voice].position, voices[voice].start, voices[voice].end, (int)voices[voice].mode);

        voices[voice].sound = sound;
    }

    /// @brief This mixes and writes the mixed samples to "buffer"
    /// @param buffer A buffer pointer that will receive the mixed samples (the buffer is not cleared before mixing)
    /// @param frames The number of frames to mix
    void Update(float *buffer, uint32_t frames)
    {
        auto voiceCount = voices.size();
        activeVoices = 0;

        for (size_t v = 0; v < voiceCount; v++)
        {
            auto &voice = voices[v];

            if (voice.sound >= 0 && sounds[voice.sound].data.size() > 0)
            {
                ++activeVoices;

                auto output = buffer;
                auto &soundData = sounds[voice.sound].data;
                float currentFrame, nextFrame;
                int64_t currentPosition, nextPosition;

                for (uint32_t s = 0; s < frames; s++)
                {
                    // Update frame position based on the playback mode
                    if (Voice::PlayMode::Reverse == voice.mode)
                    {
                        if (voice.position < voice.start)
                        {
                            voice.sound = Sound::NO_SOUND; // just invalidate the sound leaving other properties intact
                            break;                         // exit the for loop
                        }

                        currentPosition = (int64_t)voice.position;
                        currentFrame = soundData[currentPosition];
                        nextPosition = currentPosition - 1;
                        nextFrame = nextPosition < voice.start ? 0.0f : soundData[nextPosition];
                    }
                    else if (Voice::PlayMode::ForwardLoop == voice.mode)
                    {
                        if (voice.position > voice.end)
                            voice.position = voice.start;

                        currentPosition = (int64_t)voice.position;
                        currentFrame = soundData[currentPosition];
                        nextPosition = currentPosition + 1;
                        nextFrame = nextPosition > voice.end ? soundData[voice.start] : soundData[nextPosition];
                    }
                    else if (Voice::PlayMode::ReverseLoop == voice.mode)
                    {
                        if (voice.position < voice.start)
                            voice.position = voice.end;

                        currentPosition = (int64_t)voice.position;
                        currentFrame = soundData[currentPosition];
                        nextPosition = currentPosition - 1;
                        nextFrame = nextPosition < voice.start ? soundData[voice.end] : soundData[nextPosition];
                    }
                    else if (Voice::PlayMode::BidirectionalLoop == voice.mode)
                    {
                        if (voice.position < voice.start and voice.start < voice.end) // reverse playback if we have 2 or more frames
                        {
                            voice.position = voice.start + 1;
                            voice.direction = Voice::PlayDirection::Forward;
                        }
                        else if (voice.position > voice.end and voice.start < voice.end) // reverse playback if we have 2 or more frames
                        {
                            voice.position = voice.end - 1;
                            voice.direction = Voice::PlayDirection::Reverse;
                        }
                        else if (voice.position < voice.start or voice.position > voice.end) // we just have a single frame so just sit on that single frame
                        {
                            voice.position = voice.start;
                        }

                        currentPosition = (int64_t)voice.position;
                        currentFrame = soundData[currentPosition];
                        nextPosition = currentPosition + (int)voice.direction;
                        nextFrame = nextPosition < voice.start ? soundData[currentPosition] : (nextPosition > voice.start ? soundData[currentPosition] : soundData[nextPosition]);
                    }
                    else
                    {
                        if (voice.position > voice.end)
                        {
                            voice.sound = Sound::NO_SOUND; // just invalidate the sound leaving other properties intact
                            break;                         // exit the for loop
                        }

                        currentPosition = (int64_t)voice.position;
                        currentFrame = soundData[currentPosition];
                        nextPosition = currentPosition + 1;
                        nextFrame = nextPosition > voice.end ? 0.0f : soundData[nextPosition];
                    }

                    // The following lines mixes the frames, does volume & balance
                    currentFrame = (currentFrame + (nextFrame - currentFrame) * (voice.position - currentPosition)) * voice.volume;
                    *output += currentFrame * (0.5f - voice.balance);
                    ++output; // go to the current frame right channel
                    *output += currentFrame * (0.5f + voice.balance);
                    ++output; // go to the next frame left channel

                    // Move to the next position
                    voice.MoveToNextPosition();
                }
            }
        }

        // Make one more pass to apply global volume
        auto output = buffer;
        for (uint32_t s = 0; s < frames; s++)
        {
            *output *= volume;
            ++output;
            *output *= volume;
            ++output;
        }
    }
};

static std::unique_ptr<SoftSynth> g_SoftSynth;

inline qb_bool __SoftSynth_Initialize(uint32_t sampleRate)
{
    if (g_SoftSynth)
        return QB_TRUE;

    if (!sampleRate)
        return QB_FALSE;

    g_SoftSynth = std::make_unique<SoftSynth>(sampleRate);

    return TO_QB_BOOL(g_SoftSynth != nullptr);
}

inline void __SoftSynth_Finalize()
{
    g_SoftSynth.reset();
}

qb_bool SoftSynth_IsInitialized()
{
    return TO_QB_BOOL(g_SoftSynth != nullptr);
}

inline void __SoftSynth_Update(float *buffer, uint32_t frames)
{
    if (!g_SoftSynth or !buffer or !frames)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->Update(buffer, frames);
}

void SoftSynth_SetVoiceVolume(uint32_t voice, float volume)
{
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices[voice].volume = ClampSingle(volume, 0.0f, 1.0f);
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

void SoftSynth_SetVoiceBalance(uint32_t voice, float balance)
{
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices[voice].balance = ClampSingle(balance * 0.5f, -0.5f, 0.5f);
}

float SoftSynth_GetVoiceBalance(uint32_t voice)
{
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_SoftSynth->voices[voice].balance * 2.0f;
}

void SoftSynth_SetVoiceFrequency(uint32_t voice, float frequency)
{
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size() or frequency < 0.0f)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->voices[voice].SetFrequency(*g_SoftSynth, frequency);

    TOOLBOX64_DEBUG_PRINT("Voice, %u, frequency = %f, pitch = %f", voice, frequency, g_SoftSynth->voices[voice].pitch);
}

float SoftSynth_GetVoiceFrequency(uint32_t voice)
{
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_SoftSynth->voices[voice].GetFrequency();
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

void SoftSynth_PlayVoice(uint32_t voice, int32_t sound, uint32_t position, int32_t mode, uint32_t start, uint32_t end)
{
    if (!g_SoftSynth or voice >= g_SoftSynth->voices.size() or sound < 0 or sound >= g_SoftSynth->sounds.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->PlayVoice(voice, sound, position, (SoftSynth::Voice::PlayMode)mode, start, end);
}

void SoftSynth_SetGlobalVolume(float volume)
{
    if (!g_SoftSynth)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->volume = ClampSingle(volume, 0.0f, 1.0f);
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

void SoftSynth_LoadSound(int32_t sound, const char const *source, uint32_t frames, uint8_t bytesPerSample, uint8_t channels)
{
    if (!g_SoftSynth or sound < 0 or !source or !SoftSynth::IsBytesPerSampleValid(bytesPerSample) or !SoftSynth::IsChannelsValid(channels))
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->LoadSound(sound, source, frames, bytesPerSample, channels);
}

float SoftSynth_PeekSoundFrameSingle(int32_t sound, uint32_t position)
{
    if (!g_SoftSynth or sound < 0 or sound >= g_SoftSynth->sounds.size() or position >= g_SoftSynth->sounds[sound].data.size())
    {
        TOOLBOX64_DEBUG_PRINT("Tried to access sound %i, position %u", sound, position);
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_SoftSynth->PeekSoundFrame(sound, position);
}

void SoftSynth_PokeSoundFrameSingle(int32_t sound, uint32_t position, float frame)
{
    if (!g_SoftSynth or sound < 0 or sound >= g_SoftSynth->sounds.size() or position >= g_SoftSynth->sounds[sound].data.size())
    {
        TOOLBOX64_DEBUG_PRINT("Tried to access sound %i, position %u", sound, position);
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->PokeSoundFrame(sound, position, frame);
}

int16_t SoftSynth_PeekSoundFrameInteger(int32_t sound, uint32_t position)
{
    if (!g_SoftSynth or sound < 0 or sound >= g_SoftSynth->sounds.size() or position >= g_SoftSynth->sounds[sound].data.size())
    {
        TOOLBOX64_DEBUG_PRINT("Tried to access sound %i, position %u", sound, position);
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return g_SoftSynth->PeekSoundFrame(sound, position) * 32768.0f;
}

void SoftSynth_PokeSoundFrameInteger(int32_t sound, uint32_t position, int16_t frame)
{
    static constexpr auto SoftSynth_PokeSoundFrameInteger_Multiplier = 1.0f / 32768.0f;

    if (!g_SoftSynth or sound < 0 or sound >= g_SoftSynth->sounds.size() or position >= g_SoftSynth->sounds[sound].data.size())
    {
        TOOLBOX64_DEBUG_PRINT("Tried to access sound %i, position %u", sound, position);
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->PokeSoundFrame(sound, position, frame * SoftSynth_PokeSoundFrameInteger_Multiplier);
}

int8_t SoftSynth_PeekSoundFrameByte(int32_t sound, uint32_t position)
{
    if (!g_SoftSynth or sound < 0 or sound >= g_SoftSynth->sounds.size() or position >= g_SoftSynth->sounds[sound].data.size())
    {
        TOOLBOX64_DEBUG_PRINT("Tried to access sound %i, position %u", sound, position);
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return g_SoftSynth->PeekSoundFrame(sound, position) * 128.0f;
}

void SoftSynth_PokeSoundFrameByte(int32_t sound, uint32_t position, int8_t frame)
{
    static constexpr auto SoftSynth_PokeSoundFrameByte_Multiplier = 1.0f / 128.0f;

    if (!g_SoftSynth or sound < 0 or sound >= g_SoftSynth->sounds.size() or position >= g_SoftSynth->sounds[sound].data.size())
    {
        TOOLBOX64_DEBUG_PRINT("Tried to access sound %i, position %u", sound, position);
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_SoftSynth->PokeSoundFrame(sound, position, frame * SoftSynth_PokeSoundFrameByte_Multiplier);
}

inline uint32_t SoftSynth_BytesToFrames(uint32_t bytes, uint8_t bytesPerSample, uint8_t channels)
{
    TOOLBOX64_DEBUG_CHECK(bytesPerSample > 0 and channels > 0);

    return bytes / ((uint32_t)bytesPerSample * (uint32_t)channels);
}

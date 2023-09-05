//----------------------------------------------------------------------------------------------------------------------
// Simple floatimg-point stereo sample-based software synthesizer
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

// #define TOOLBOX64_DEBUG 1
#include "Debug.h"
#include "MathOps.h"
#include <cstdint>
#include <vector>

struct SoftSynth
{
    /// @brief This manages just a single raw sound in memory
    struct Sound
    {
        /// @brief A single stereo floating-point sound frame
        struct Frame
        {
            float left;  // left channel sample
            float right; // right channel sample
        };

        std::vector<Frame> data; // raw sound data + size (always 32-bit floating point stereo)

        /// @brief Copies and prepares the sound data in memory
        /// @param source A pointer to the raw sound data
        /// @param frames The number of frames the sound has
        /// @param bytesPerSample The bytes / samples (this can be 1 for 8-bit, 2 for 16-bit or 3 for 32-bit)
        /// @param channels The number of channels (this can be 1 for mono or 2 for stereo)
        void Load(const void *source, int32_t frames, int32_t bytesPerSample, int32_t channels)
        {
            TOOLBOX64_DEBUG_CHECK(source != nullptr);
            TOOLBOX64_DEBUG_CHECK(IsFramesValid(frames));
            TOOLBOX64_DEBUG_CHECK(IsBytesPerSampleValid(bytesPerSample));
            TOOLBOX64_DEBUG_CHECK(IsChannelsValid(channels));

            data.resize(frames);

            TOOLBOX64_DEBUG_PRINT("Loading %i frames (%i bytes, bytes / sample = %i, channels = %i)", frames, frames * bytesPerSample * channels, (int)bytesPerSample, (int)channels);

            switch (bytesPerSample)
            {
            case sizeof(int8_t):
            {
                auto src = (const int8_t *)source;
                for (int32_t i = 0; i < frames; i++)
                {
                    switch (channels)
                    {
                    case 1:
                        data[i].left = *src / 256.0f;
                        data[i].right = data[i].left;
                        ++src;
                        break;

                    case 2:
                        data[i].left = *src / 128.0f;
                        ++src;
                        data[i].right = *src / 128.0f;
                        ++src;
                        break;

                    default:
                        TOOLBOX64_DEBUG_PRINT("Unsupported channels (%i)", channels);
                    }
                }
            }
            break;

            case sizeof(int16_t):
            {
                auto src = (const int16_t *)source;
                for (int32_t i = 0; i < frames; i++)
                {
                    switch (channels)
                    {
                    case 1:
                        data[i].left = *src / 65536.0f;
                        data[i].right = data[i].left;
                        ++src;
                        break;

                    case 2:
                        data[i].left = *src / 32768.0f;
                        ++src;
                        data[i].right = *src / 32768.0f;
                        ++src;
                        break;

                    default:
                        TOOLBOX64_DEBUG_PRINT("Unsupported channels (%i)", channels);
                    }
                }
            }
            break;

            case sizeof(float):
            {
                auto src = (const float *)source;
                for (int32_t i = 0; i < frames; i++)
                {
                    switch (channels)
                    {
                    case 1:
                        data[i].left = *src / 2.0f;
                        data[i].right = data[i].left;
                        ++src;
                        break;

                    case 2:
                        data[i].left = *src;
                        ++src;
                        data[i].right = *src;
                        ++src;
                        break;

                    default:
                        TOOLBOX64_DEBUG_PRINT("Unsupported channels (%i)", channels);
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
        static const auto RSM_FRAC = 10;

        /// @brief Various playing modes
        enum struct PlayMode : int32_t
        {
            Forward = 0,
            ForwardLoop,
            Reverse,
            ReverseLoop,
            BidirectionalLoop,
            Count
        };

        enum struct PlayDirection : int32_t
        {
            Reverse = -1,
            Forward = 1
        };

        int32_t sound;           // the Sound to be mixed. This is set to -1 once the mixer is done with the Sound
        float volume;            // voice volume (0.0 - 1.0)
        uint32_t frequency;      // the frequency of the sound
        uint32_t rateRatio;      // ratio between the desired output sample rate and the device sample rate
        uint32_t sampleCnt;      // the fractional part of the current sample position
        float balance;           // position -1.0 is leftmost ... 1.0 is rightmost
        float leftGain;          // left channel gain
        float rightGain;         // rigth channel gain
        int32_t position;        // position in frames
        int32_t start;           // this can be loop start or just start depending on play mode
        int32_t end;             // this can be loop end or just end depending on play mode
        PlayDirection direction; // direction for BIDI sounds
        PlayMode playMode;       // how should the sound be played?
        Sound::Frame frame;      // current frame
        Sound::Frame oldFrame;   // previous frame

        Voice()
        {
            Reset();
            SetBalance(0.0f);
        }

        void Reset()
        {
            // Balance & channel gains are intentionally left out so that we do not reset pan positions set by the user
            sound = -1;
            volume = 1.0f;
            frequency = rateRatio = sampleCnt = position = start = end = 0;
            direction = PlayDirection::Forward;
            playMode = PlayMode::Forward;
            frame = oldFrame = {};
        }

        void SetFrequency(SoftSynth &softSynth, uint32_t frequency)
        {
            this->frequency = frequency;
            rateRatio = (softSynth.sampleRate << RSM_FRAC) / frequency;

            TOOLBOX64_DEBUG_PRINT("Sample rate ratio = %i", rateRatio);
        }

        uint32_t GetFrequency()
        {
            return frequency;
        }

        void SetBalance(float balance)
        {
            this->balance = balance;

            if (balance < 0.0f)
            {
                leftGain = 1.0f;
                rightGain = 1.0f + balance;
            }
            else if (balance > 0.0f)
            {
                leftGain = 1.0f - balance;
                rightGain = 1.0f;
            }
            else
            {
                leftGain = rightGain = 1.0f;
            }

            TOOLBOX64_DEBUG_PRINT("Balance = %5.2f, left gain = %5.2f, right gain = %5.2f", balance, leftGain, rightGain);
        }

        float GetBalance()
        {
            return balance;
        }

        void SetSound(SoftSynth &softSynth, int32_t sound)
        {
            TOOLBOX64_DEBUG_CHECK(sound >= 0 and sound < softSynth.Sounds.size());

            // Reset some stuff
            sampleCnt = 0;
            frame = oldFrame = {};

            this->sound = sound;

            if (playMode == PlayMode::Reverse or playMode == PlayMode::ReverseLoop)
            {
                position = end; // set to the end position

                TOOLBOX64_DEBUG_PRINT("Set position to %i for reverse playack", position);
            }

            TOOLBOX64_DEBUG_PRINT("Sound %i set", sound);
        }

        /// @brief This return a single frame from the associated Sound after resampling based on the set frequency
        /// @return A single Frame object
        Sound::Frame GetFrame(SoftSynth &softSynth)
        {
            TOOLBOX64_DEBUG_CHECK(sound >= 0 and sound < softSynth.Sounds.size());
            TOOLBOX64_DEBUG_CHECK(frequency > 0);

            Sound::Frame temp, output; // output frame

            if (!rateRatio)
            {
                output = {};
                return output;
            }

            while (sampleCnt >= rateRatio)
            {
                // TOOLBOX64_DEBUG_PRINT("Position = %i", position);

                oldFrame = frame;
                frame = softSynth.Sounds[sound].data[position];

                switch (playMode)
                {
                case PlayMode::Reverse:
                    --position;

                    if (position < start)
                    {
                        position = end;
                        sound = -1; // just invalidate the sound index
                    }

                    break;

                case PlayMode::ForwardLoop:
                    ++position;

                    if (position > end)
                        position = start;

                    break;

                case PlayMode::ReverseLoop:
                    --position;

                    if (position < start)
                        position = end;

                    break;

                case PlayMode::BidirectionalLoop:
                    position += (int32_t)direction;

                    if (position < start and start < end) // reverse playback if we have 2 or more frames
                    {
                        position = start + 1;
                        direction = PlayDirection::Forward;
                    }
                    else if (position > end and start < end) // reverse playback if we have 2 or more frames
                    {
                        position = end - 1;
                        direction = PlayDirection::Reverse;
                    }
                    else if (position < start or position > end) // we just have a single frame so just sit on that single frame
                    {
                        position = start;
                    }

                    break;

                case PlayMode::Forward:
                default:
                    ++position;

                    if (position > end)
                    {
                        position = 0;
                        sound = -1; // just invalidate the sound index
                    }
                }

                sampleCnt -= rateRatio;
            }

            // Interpolation & volume
            temp.left = ((oldFrame.left * (rateRatio - sampleCnt) + frame.left * sampleCnt) / rateRatio) * volume;
            temp.right = ((oldFrame.right * (rateRatio - sampleCnt) + frame.right * sampleCnt) / rateRatio) * volume;
            // Panning & crossfading
            output.left = temp.left * leftGain + temp.right * (1.0f - rightGain);
            output.right = temp.right * rightGain + temp.left * (1.0f - leftGain);

            sampleCnt += 1 << RSM_FRAC;

            return output;
        }
    };

    uint32_t sampleRate;       // device sample rate
    std::vector<Sound> Sounds; // managed sounds
    std::vector<Voice> Voices; // managed voices
    int32_t activeVoices;      // active voices
    float volume;              // global volume

    static bool IsFramesValid(int32_t frames)
    {
        return frames >= 0; // we'll allow zero frame sounds
    }

    static bool IsChannelsValid(int32_t channels)
    {
        return channels == 1 or channels == 2;
    }

    static bool IsBytesPerSampleValid(int32_t bytesPerSample)
    {
        return bytesPerSample == sizeof(int8_t) or bytesPerSample == sizeof(int16_t) or bytesPerSample == sizeof(float);
    }

    SoftSynth() = delete;
    SoftSynth(const SoftSynth &) = delete;
    SoftSynth &operator=(const SoftSynth &) = delete;
    SoftSynth &operator=(SoftSynth &&) = delete;
    SoftSynth(SoftSynth &&) = delete;

    SoftSynth(uint32_t sampleRate)
    {
        this->sampleRate = sampleRate;
        activeVoices = 0;
        volume = 1.0f;
    }

    void LoadSound(int32_t sound, const void *source, int32_t frames, int32_t bytesPerSample, int32_t channels)
    {
        TOOLBOX64_DEBUG_CHECK(sound >= 0);

        if (sound >= Sounds.size())
            Sounds.resize(sound + 1); // resize the vector

        Sounds[sound].Load(source, frames, bytesPerSample, channels);
    }

    Sound::Frame PeekSoundFrame(int32_t sound, int32_t position)
    {
        TOOLBOX64_DEBUG_CHECK(sound >= 0 and sound < Sounds.size());
        TOOLBOX64_DEBUG_CHECK(position >= 0 and position < Sounds[sound].data.size());

        return Sounds[sound].data[position];
    }

    void PokeSoundFrame(int32_t sound, int32_t position, Sound::Frame frame)
    {
        TOOLBOX64_DEBUG_CHECK(sound >= 0 and sound < Sounds.size());
        TOOLBOX64_DEBUG_CHECK(position >= 0 and position < Sounds[sound].data.size());

        Sounds[sound].data[position] = frame;
    }

    /// @brief
    /// @param voice The voice to use to play the sound
    /// @param sound The sound to play
    /// @param position The position (in frames) in the sound where playback should start
    /// @param playMode The play mode (see PlayMode enum)
    /// @param start The playback start frame or loop start frame (based on playMode)
    /// @param end The playback end frame or loop end frame (based on playMode)
    void PlayVoice(int32_t voice, int32_t sound, int32_t position, SoftSynth::Voice::PlayMode playMode, int32_t start, int32_t end)
    {
        if (playMode < Voice::PlayMode::Forward or playMode >= Voice::PlayMode::Count)
            Voices[voice].playMode = SoftSynth::Voice::PlayMode::Forward;
        else
            Voices[voice].playMode = playMode;

        TOOLBOX64_DEBUG_PRINT("Original position = %i, start = %i, end = %i", position, start, end);

        auto totalFrames = Sounds[sound].data.size();

        if (position >= totalFrames and SoftSynth::Voice::PlayMode::Forward == playMode)
        {
            Voices[voice].sound = -1; // trying to play past sound; just invalidate the sound index
            TOOLBOX64_DEBUG_PRINT("Play position (%i) >= frame count (%llu)", position, totalFrames);
            return;
        }
        else if (position < 0 and SoftSynth::Voice::PlayMode::Reverse == playMode)
        {
            Voices[voice].sound = -1; // trying to play past sound; just invalidate the sound index
            TOOLBOX64_DEBUG_PRINT("Play position (%i) < 0", position);
            return;
        }
        else if (position < 0 or position >= totalFrames)
        {
            Voices[voice].position = 0;
        }
        else
        {
            Voices[voice].position = position;
        }

        if (start < 0 or start >= totalFrames)
            Voices[voice].start = 0;
        else
            Voices[voice].start = start;

        if (end < 0 or end >= totalFrames)
            Voices[voice].end = (int32_t)(totalFrames - 1);
        else
            Voices[voice].end = end;

        TOOLBOX64_DEBUG_PRINT("Adjusted position = %i, start = %i, end = %i", Voices[voice].position, Voices[voice].start, Voices[voice].end);

        Voices[voice].SetSound(*this, sound);
    }

    /// @brief This mixes and writes the mixed samples to "buffer"
    /// @param buffer A pointer that will receive the mixed samples (the buffer is not cleared before mixing)
    /// @param frames The number of frames to mix
    void Update(float *buffer, uint32_t frames)
    {
        auto voiceCount = Voices.size();
        activeVoices = 0;

        for (size_t v = 0; v < voiceCount; v++)
        {
            auto &voice = Voices[v];

            if (voice.sound >= 0 and Sounds[voice.sound].data.size() > 0)
            {
                // TOOLBOX64_DEBUG_PRINT("Painting voice %i", v);

                ++activeVoices;

                auto output = buffer;

                for (uint32_t s = 0; s < frames; s++)
                {
                    auto frame = voice.GetFrame(*this);
                    *output += frame.left;
                    ++output;
                    *output += frame.right;
                    ++output;

                    // Leave the loop early if we are done with the sound
                    if (voice.sound < 0)
                    {
                        TOOLBOX64_DEBUG_PRINT("Voice %llu: end of sound reached", v);
                        break;
                    }
                }
            }
        }

        // Make one more pass to apply global volume
        // We could have done this above but then it would have been too many multiplications
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

static SoftSynth *g_softSynth = nullptr;

inline qb_bool __SoftSynth_Initialize(uint32_t sampleRate)
{
    if (g_softSynth)
        return QB_TRUE;

    if (!sampleRate)
        return QB_FALSE;

    g_softSynth = new SoftSynth(sampleRate);

    return TO_QB_BOOL(g_softSynth != nullptr);
}

inline void __SoftSynth_Finalize()
{
    if (g_softSynth)
    {
        delete g_softSynth;
        g_softSynth = nullptr;
    }
}

qb_bool SoftSynth_IsInitialized()
{
    return TO_QB_BOOL(g_softSynth != nullptr);
}

inline void __SoftSynth_Update(float *buffer, uint32_t frames)
{
    if (!g_softSynth or !buffer or !frames)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_softSynth->Update(buffer, frames);
}

void SoftSynth_SetVoiceVolume(int32_t voice, float volume)
{
    if (!g_softSynth or voice < 0 or voice >= g_softSynth->Voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_softSynth->Voices[voice].volume = ClampSingle(volume, 0.0f, 1.0f);
}

float SoftSynth_GetVoiceVolume(int32_t voice)
{
    if (!g_softSynth or voice < 0 or voice >= g_softSynth->Voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_softSynth->Voices[voice].volume;
}

void SoftSynth_SetVoiceBalance(int32_t voice, float balance)
{
    if (!g_softSynth or voice < 0 or voice >= g_softSynth->Voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_softSynth->Voices[voice].SetBalance(ClampSingle(balance, -1.0f, 1.0f));
}

float SoftSynth_GetVoiceBalance(int32_t voice)
{
    if (!g_softSynth or voice < 0 or voice >= g_softSynth->Voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_softSynth->Voices[voice].GetBalance();
}

void SoftSynth_SetVoiceFrequency(int32_t voice, uint32_t frequency)
{
    if (!g_softSynth or voice < 0 or voice >= g_softSynth->Voices.size() or !frequency)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_softSynth->Voices[voice].SetFrequency(*g_softSynth, frequency);
}

uint32_t SoftSynth_GetVoiceFrequency(int32_t voice)
{
    if (!g_softSynth or voice < 0 or voice >= g_softSynth->Voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return g_softSynth->Voices[voice].GetFrequency();
}

void SoftSynth_StopVoice(int32_t voice)
{
    if (!g_softSynth or voice < 0 or voice >= g_softSynth->Voices.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_softSynth->Voices[voice].Reset();
}

void SoftSynth_PlayVoice(int32_t voice, int32_t sound, int32_t position, int32_t playMode, int32_t start, int32_t end)
{
    if (!g_softSynth or voice < 0 or voice >= g_softSynth->Voices.size() or sound < 0 or sound >= g_softSynth->Sounds.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_softSynth->PlayVoice(voice, sound, position, (SoftSynth::Voice::PlayMode)playMode, start, end);
}

void SoftSynth_SetGlobalVolume(float volume)
{
    if (!g_softSynth)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_softSynth->volume = ClampSingle(volume, 0.0f, 1.0f);
}

float SoftSynth_GetGlobalVolume()
{
    if (!g_softSynth)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0.0f;
    }

    return g_softSynth->volume;
}

uint32_t SoftSynth_GetSampleRate()
{
    if (!g_softSynth)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return g_softSynth->sampleRate;
}

int32_t SoftSynth_GetTotalSounds()
{
    if (!g_softSynth)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return (int32_t)g_softSynth->Sounds.size();
}

int32_t SoftSynth_GetTotalVoices()
{
    if (!g_softSynth)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return (int32_t)g_softSynth->Voices.size();
}

void SoftSynth_SetTotalVoices(int32_t voices)
{
    if (!g_softSynth or voices < 1)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_softSynth->Voices.resize(voices);
}

int32_t SoftSynth_GetActiveVoices()
{
    if (!g_softSynth)
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return 0;
    }

    return g_softSynth->activeVoices;
}

void SoftSynth_LoadSound(int32_t sound, const char *source, int32_t frames, int32_t bytesPerSample, int32_t channels)
{
    TOOLBOX64_DEBUG_PRINT("Sound = %i, frames = %i, bytes / sample = %i, channels = %i", sound, frames, bytesPerSample, channels);

    if (!g_softSynth or sound < 0 or !source or !SoftSynth::IsFramesValid(frames) or !SoftSynth::IsBytesPerSampleValid(bytesPerSample) or !SoftSynth::IsChannelsValid(channels))
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_softSynth->LoadSound(sound, source, frames, bytesPerSample, channels);
}

void SoftSynth_PeekSoundFrameSingle(int32_t sound, int32_t position, float *L, float *R)
{
    if (!g_softSynth or sound < 0 or sound >= g_softSynth->Sounds.size() or position < 0 or position >= g_softSynth->Sounds[sound].data.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    auto frame = g_softSynth->PeekSoundFrame(sound, position);

    *L = frame.left;
    *R = frame.right;
}

void SoftSynth_PokeSoundFrameSingle(int32_t sound, int32_t position, float L, float R)
{
    if (!g_softSynth or sound < 0 or sound >= g_softSynth->Sounds.size() or position < 0 or position >= g_softSynth->Sounds[sound].data.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_softSynth->PokeSoundFrame(sound, position, {L, R});
}

void SoftSynth_PeekSoundFrameInteger(int32_t sound, int32_t position, int16_t *L, int16_t *R)
{
    if (!g_softSynth or sound < 0 or sound >= g_softSynth->Sounds.size() or position < 0 or position >= g_softSynth->Sounds[sound].data.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    auto frame = g_softSynth->PeekSoundFrame(sound, position);

    *L = (int16_t)(frame.left * 32768.0f);
    *R = (int16_t)(frame.right * 32768.0f);
}

void SoftSynth_PokeSoundFrameInteger(int32_t sound, int32_t position, int16_t L, int16_t R)
{
    if (!g_softSynth or sound < 0 or sound >= g_softSynth->Sounds.size() or position < 0 or position >= g_softSynth->Sounds[sound].data.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_softSynth->PokeSoundFrame(sound, position, {(float)L / 32768.0f, (float)R / 32768.0f});
}

void SoftSynth_PeekSoundFrameByte(int32_t sound, int32_t position, int8_t *L, int8_t *R)
{
    if (!g_softSynth or sound < 0 or sound >= g_softSynth->Sounds.size() or position < 0 or position >= g_softSynth->Sounds[sound].data.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    auto frame = g_softSynth->PeekSoundFrame(sound, position);

    *L = (int16_t)(frame.left * 128.0f);
    *R = (int16_t)(frame.right * 128.0f);
}

void SoftSynth_PokeSoundFrameByte(int32_t sound, int32_t position, int8_t L, int8_t R)
{
    if (!g_softSynth or sound < 0 or sound >= g_softSynth->Sounds.size() or position < 0 or position >= g_softSynth->Sounds[sound].data.size())
    {
        error(ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    g_softSynth->PokeSoundFrame(sound, position, {(float)L / 128.0f, (float)R / 128.0f});
}

inline int32_t SoftSynth_BytesToFrames(int32_t bytes, int32_t bytesPerSample, int32_t channels)
{
    return bytes / (bytesPerSample * channels);
}

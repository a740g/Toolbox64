//----------------------------------------------------------------------------------------------------------------------
// MIDI Player library using fmidi + RtMidi
// Copyright (c) 2024 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#ifndef RTMIDI_SOURCE_INCLUDED
// Platform-specific API selection
#ifdef _WIN32
#define __WINDOWS_MM__
#elif __APPLE__
#define __MACOSX_CORE__
#elif __linux__
#define __LINUX_ALSA__
#endif

// This is needed since we are including the .cpp files
#define RTMIDI_SOURCE_INCLUDED

#include "external/rtmidi/RtMidi.cpp"
#include "external/rtmidi/rtmidi_c.cpp"
#endif

// This need to be defined to link the library statically
#define FMIDI_STATIC

// Set to 1 to enable debug messages
#define TOOLBOX64_DEBUG 1

#include "Debug.h"
#include "Types.h"
#include "external/fmidi/fmidi.cpp"
#include <chrono>
#include <thread>
#include <functional>

class MIDIPlayer
{
public:
    const char *GetErrorMessage()
    {
        auto errorCode = fmidi_errno();

        if (errorCode != fmidi_status::fmidi_ok)
        {
            return fmidi_strerror(errorCode);
        }
        else
        {
            if (rtMidiOut && !rtMidiOut->ok)
            {
                return rtMidiOut->msg;
            }
        }

        return "";
    }

    qb_bool PlayFromMemory(const char *buffer, size_t bufferSize)
    {
        Stop();

        TOOLBOX64_DEBUG_PRINT("Starting MIDI playback");

        rtMidiOut = rtmidi_out_create_default();
        if (rtMidiOut && rtMidiOut->ok)
        {
            TOOLBOX64_DEBUG_PRINT("rtMidiOut created");

            if (rtmidi_get_port_count(rtMidiOut) && rtMidiOut->ok)
            {
                TOOLBOX64_DEBUG_PRINT("Found output ports");

                rtmidi_open_port(rtMidiOut, 0, "QB64-PE-MIDI-Player");
                if (rtMidiOut->ok)
                {
                    TOOLBOX64_DEBUG_PRINT("Port 0 opened");

                    MIDIOutReset();

                    smf = fmidi_auto_mem_read(reinterpret_cast<const uint8_t *>(buffer), bufferSize);
                    if (smf)
                    {
                        TOOLBOX64_DEBUG_PRINT("File parsed and loaded");

                        player = fmidi_player_new(smf);
                        if (player)
                        {
                            TOOLBOX64_DEBUG_PRINT("Player created");

                            totalTime = fmidi_smf_compute_duration(smf);

                            TOOLBOX64_DEBUG_PRINT("Total time: %f", totalTime);

                            fmidi_player_event_callback(player, PlayerEventCallback, this);
                            fmidi_player_finish_callback(player, PlayerFinishCallback, this);

                            fmidi_player_start(player);

                            TOOLBOX64_DEBUG_PRINT("Player started");

                            midiTimer.SetCallback([this]()
                                                  {
                                                    auto now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
                                                    
                                                    if (haveMIDITick)
                                                    {
                                                        fmidi_player_tick(player, now - lastMIDITick);
                                                    }

                                                    haveMIDITick = true;
                                                    lastMIDITick = now; },
                                                  std::chrono::milliseconds(1));

                            midiTimer.Start();

                            TOOLBOX64_DEBUG_PRINT("Timer started");

                            TOOLBOX64_DEBUG_PRINT("MIDI playback started");

                            return QB_TRUE;
                        }
                    }
                }
            }
        }

        TOOLBOX64_DEBUG_PRINT("MIDI playback failed");

        Stop();

        return QB_FALSE;
    }

    void Stop()
    {
        TOOLBOX64_DEBUG_PRINT("Stopping MIDI playback");

        MIDIOutReset();

        midiTimer.Stop();

        TOOLBOX64_DEBUG_PRINT("Timer stopped");

        fmidi_player_free(player);
        player = nullptr;

        TOOLBOX64_DEBUG_PRINT("Player freed");

        fmidi_smf_free(smf);
        smf = nullptr;

        TOOLBOX64_DEBUG_PRINT("File freed");

        if (rtMidiOut)
        {
            rtmidi_close_port(rtMidiOut);
            rtmidi_out_free(rtMidiOut);
            rtMidiOut = nullptr;

            TOOLBOX64_DEBUG_PRINT("Port closed and freed");
        }

        totalTime = 0.0;
        haveMIDITick = false;
        lastMIDITick = 0.0;

        TOOLBOX64_DEBUG_PRINT("MIDI playback stopped");
    }

    qb_bool IsPlaying()
    {
        if (player)
        {
            return fmidi_player_running(player) ? QB_TRUE : QB_FALSE;
        }
    }

    void Loop(int32_t loops) {}

    qb_bool IsLooping() {}

    void Pause(int8_t state) {}

    qb_bool IsPaused() {}

    double GetTotalTime()
    {
        return totalTime;
    }

    double GetCurrentTime()
    {
        if (player)
        {
            return fmidi_player_current_time(player);
        }

        return 0.0;
    }

    static MIDIPlayer &Instance()
    {
        static MIDIPlayer instance;
        return instance;
    }

private:
    static const auto Channels = 16;
    static const auto SysExEnd = 0xF7u;
    static constexpr uint8_t SysExResetGM[] = {0xF0, 0x7E, 0x7F, 0x09, 0x01, 0xF7};
    static constexpr uint8_t SysExResetGM2[] = {0xF0, 0x7E, 0x7F, 0x09, 0x03, 0xF7};
    static constexpr uint8_t SysExResetGS[] = {0xF0, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7F, 0x00, 0x41, 0xF7};
    static constexpr uint8_t SysExResetXG[] = {0xF0, 0x43, 0x10, 0x4C, 0x00, 0x00, 0x7E, 0x00, 0xF7};

    class Timer
    {
    public:
        Timer() : running(false) {}

        ~Timer() { Stop(); }

        void SetCallback(std::function<void()> callback,
                         std::chrono::milliseconds interval)
        {
            this->callback = callback;
            this->interval = interval;
        }

        bool Start()
        {
            if (!callback)
            {
                return false;
            }

            if (running)
            {
                Stop();
            }

            running = true;
            worker = std::thread([this]()
                                 {
            while (running) {
                std::this_thread::sleep_for(interval);

                if (running && callback) {
                    callback();
                }
            } });

            return true;
        }

        void Stop()
        {
            running = false;

            if (worker.joinable())
            {
                worker.join();
            }
        }

        bool IsRunning() const { return running; }

    private:
        std::thread worker;
        bool running;

        std::function<void()> callback;
        std::chrono::milliseconds interval;
    };

    MIDIPlayer() : smf(nullptr), player(nullptr), totalTime(0.0), rtMidiOut(nullptr), lastMIDITick(0.0), haveMIDITick(false), loops(0) {}

    ~MIDIPlayer()
    {
        Stop();
    }

    MIDIPlayer(const MIDIPlayer &) = delete;
    MIDIPlayer &operator=(const MIDIPlayer &) = delete;

    void MIDIOutReset()
    {
        if (rtMidiOut)
        {
            for (unsigned c = 0; c < Channels; c++)
            {
                // All sound off
                {
                    uint8_t msg[]{(uint8_t)((0b1011 << 4) | c), 120, 0};
                    rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                }
                // Reset all controllers
                {
                    uint8_t msg[]{(uint8_t)((0b1011 << 4) | c), 121, 0};
                    rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                }
                // Bank select
                {
                    uint8_t msg[]{(uint8_t)((0b1011 << 4) | c), 0, 0};
                    rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                }
                {
                    uint8_t msg[]{(uint8_t)((0b1011 << 4) | c), 32, 0};
                    rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                }
                // Program change
                {
                    uint8_t msg[]{(uint8_t)((0b1100 << 4) | c), 0};
                    rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                }
                // Pitch bend change
                {
                    uint8_t msg[]{(uint8_t)((0b1110 << 4) | c), 0, 0b1000000};
                    rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                }
            }
        }
    }

    void MidiOutSoundOff()
    {
        if (rtMidiOut)
        {
            for (unsigned c = 0; c < Channels; ++c)
            {
                // All sound off
                {
                    uint8_t msg[]{(uint8_t)((0b1011 << 4) | c), 120, 0};
                    rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                }
            }
        }
    }

    void MIDIOutSysExReset(bool isXG)
    {
        if (!rtMidiOut)
            return;

        // Send SysEx reset messages using rtmidi_out_send_message
        rtmidi_out_send_message(rtMidiOut, SysExResetXG, sizeof(SysExResetXG));
        rtmidi_out_send_message(rtMidiOut, SysExResetGM2, sizeof(SysExResetGM2));
        rtmidi_out_send_message(rtMidiOut, SysExResetGM, sizeof(SysExResetGM));

        // Loop for sending control changes and other events for each channel
        for (uint8_t i = 0; i < Channels; ++i)
        {
            {
                uint8_t msg[]{(uint8_t)((0b1011 << 4) | i), 120, 0}; // CC 120 Channel Mute / Sound Off
                rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
            }
            {
                uint8_t msg[]{(uint8_t)((0b1011 << 4) | i), 121, 0}; // CC 121 Reset All Controllers
                rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
            }

            if (!isXG || i != 9)
            {
                {
                    uint8_t msg[]{(uint8_t)((0b1011 << 4) | i), 32, 0}; // CC 32 Bank select LSB
                    rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                }
                {
                    uint8_t msg[]{(uint8_t)((0b1011 << 4) | i), 0, 0}; // CC 0 Bank select MSB
                    rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                }
                {
                    uint8_t msg[]{(uint8_t)((0b1100 << 4) | i), 0}; // Program Change 0
                    rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                }
            }
        }

        // Configure channel 10 as drum kit in XG mode
        if (isXG)
        {
            {
                uint8_t msg[]{(uint8_t)((0b1011 << 4) | 9), 32, 0}; // CC 32 Bank select LSB
                rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
            }
            {
                uint8_t msg[]{(uint8_t)((0b1011 << 4) | 9), 0, 0}; // CC 0 Bank select MSB (Drum Kit in XG)
                rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
            }
            {
                uint8_t msg[]{(uint8_t)((0b1100 << 4) | 9), 0}; // Program Change 0
                rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
            }
        }
    }

    static bool IsSysExReset(const uint8_t *data)
    {
        return IsSysExEqual(data, SysExResetGM) || IsSysExEqual(data, SysExResetGM2) || IsSysExEqual(data, SysExResetGS) || IsSysExEqual(data, SysExResetXG);
    }

    static bool IsSysExEqual(const uint8_t *a, const uint8_t *b)
    {
        while ((*a != SysExEnd) && (*b != SysExEnd) && (*a == *b))
        {
            a++;
            b++;
        }

        return (*a == *b);
    }

    static void PlayerEventCallback(const fmidi_event_t *event, void *data)
    {
        auto player = static_cast<MIDIPlayer *>(data);

        if (event->type == fmidi_event_message)
        {
            if (event->datalen)
            {
                if (IsSysExEqual(event->data, SysExResetXG))
                {
                    player->MIDIOutSysExReset(true);
                }
                else if (IsSysExReset(event->data))
                {
                    player->MIDIOutSysExReset(false);
                }
                else
                {
                    rtmidi_out_send_message(player->rtMidiOut, event->data, event->datalen);
                }
            }
        }
    }

    static void PlayerFinishCallback(void *data)
    {
        return;

        auto player = static_cast<MIDIPlayer *>(data);

        if (player->loops > 0)
        {
            player->loops--;
            fmidi_player_start(player->player);
        }
        else
        {
            // player->Stop();
        }
    }

    fmidi_smf_t *smf;
    fmidi_player_t *player;
    double totalTime;
    RtMidiOutPtr rtMidiOut;
    Timer midiTimer;
    bool haveMIDITick;
    double lastMIDITick;
    int32_t loops;
};

const char *MIDI_GetErrorMessage()
{
    return MIDIPlayer::Instance().GetErrorMessage();
}

inline qb_bool __MIDI_PlayFromMemory(const char *buffer, size_t bufferSize)
{
    return MIDIPlayer::Instance().PlayFromMemory(buffer, bufferSize);
}

void MIDI_Stop()
{
    MIDIPlayer::Instance().Stop();
}

qb_bool MIDI_IsPlaying()
{
    return MIDIPlayer::Instance().IsPlaying();
}

void MIDI_Loop(int32_t loops)
{
    MIDIPlayer::Instance().Loop(loops);
}

qb_bool MIDI_IsLooping()
{
    return MIDIPlayer::Instance().IsLooping();
}

void MIDI_Pause(int8_t state)
{
    MIDIPlayer::Instance().Pause(state);
}

qb_bool MIDI_IsPaused()
{
    return MIDIPlayer::Instance().IsPaused();
}

double MIDI_GetTotalTime()
{
    return MIDIPlayer::Instance().GetTotalTime();
}

double MIDI_GetCurrentTime()
{
    return MIDIPlayer::Instance().GetCurrentTime();
}

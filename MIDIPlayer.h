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

                            fmidi_player_event_callback(player, PlayerEventCallback, rtMidiOut);

                            fmidi_player_start(player);

                            TOOLBOX64_DEBUG_PRINT("Player started");

                            midiTimer.Start([=]()
                                            {
                                    auto now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
                                    
                                    if (haveMIDITick)
                                    {
                                        fmidi_player_tick(player, now - lastMIDITick);
                                    }

                                    haveMIDITick = true;
                                    lastMIDITick = now; },
                                            std::chrono::milliseconds(1));

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

    qb_bool IsPlaying() {}

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

    static void PlayerEventCallback(const fmidi_event_t *event, void *data)
    {
        auto rtMidiOut = static_cast<RtMidiOutPtr>(data);

        if (event->type == fmidi_event_message)
        {
            rtmidi_out_send_message(rtMidiOut, event->data, event->datalen);
        }
    }

    class Timer
    {
    public:
        Timer() : running(false) {}

        ~Timer() { Stop(); }

        void Start(std::function<void()> callback, std::chrono::milliseconds interval)
        {
            if (running)
            {
                Stop();
            }
            running = true;
            worker = std::thread([=]()
                                 {
                while (running) {
                    std::this_thread::sleep_for(interval);
                    if (running) {
                        callback();
                    }
                } });
        }

        void Stop()
        {
            running = false;
            if (worker.joinable())
            {
                worker.join();
            }
        }

    private:
        std::thread worker;
        bool running;
    };

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

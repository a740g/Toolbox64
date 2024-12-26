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

// This needs to be defined to link the library statically
#define FMIDI_STATIC

#include "Types.h"
#include "external/fmidi/fmidi.cpp"
#include <chrono>
#include <thread>
#include <functional>

/// @brief The MIDI player singleton class.
class __MIDIPlayer
{
public:
    /// @brief Retrieves the last error message associated with the MIDI player.
    /// @return A pointer to the error message string if there is an error; otherwise, an empty string.
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

    /// @brief Retrieves the number of available MIDI ports for the MIDI player.
    /// @return The number of available MIDI ports if successful; otherwise, 0.
    uint32_t GetPortCount()
    {
        // Only create the RtMidiOut instance if it doesn't exist yet
        if (!rtMidiOut)
        {
            rtMidiOut = rtmidi_out_create_default();
        }

        if (rtMidiOut && rtMidiOut->ok)
        {
            auto count = rtmidi_get_port_count(rtMidiOut);

            if (rtMidiOut->ok)
            {
                return count;
            }
        }

        return 0u;
    }

    /// @brief Retrieves the name of a specified MIDI port.
    /// @param portIndex The index of the MIDI port for which the name is retrieved.
    /// @return A pointer to the name of the MIDI port if successful; otherwise, an empty string.
    const char *GetPortName(uint32_t portIndex)
    {
        static thread_local std::string buffer;

        // Only create the RtMidiOut instance if it doesn't exist yet
        if (!rtMidiOut)
        {
            rtMidiOut = rtmidi_out_create_default();
        }

        if (rtMidiOut && rtMidiOut->ok)
        {
            auto bufLen = 0;
            rtmidi_get_port_name(rtMidiOut, portIndex, nullptr, &bufLen); // get the required buffer size
            buffer.resize(bufLen);
            rtmidi_get_port_name(rtMidiOut, portIndex, buffer.data(), &bufLen);

            if (rtMidiOut->ok)
            {
                return buffer.c_str();
            }
        }

        buffer.clear();

        return buffer.c_str();
    }

    /// @brief Sets the MIDI port that will be used when sending MIDI messages.
    /// @param portIndex The index of the MIDI port to set.
    /// @return QB_TRUE if the MIDI port was set successfully; otherwise, QB_FALSE.
    qb_bool SetPort(uint32_t portIndex)
    {
        if (portIndex < GetPortCount())
        {
            userPort = portIndex;

            return QB_TRUE;
        }

        return QB_FALSE;
    }

    /// @brief Retrieves the currently selected MIDI port index.
    /// @return The current MIDI port index.
    uint32_t GetPort()
    {
        return userPort;
    }

    /// @brief Starts playing a MIDI file from memory.
    /// @param buffer The MIDI file data as a byte array.
    /// @param bufferSize The size of the MIDI file data in bytes.
    /// @return QB_TRUE if the file is successfully loaded and playback starts; QB_FALSE otherwise.
    qb_bool PlayFromMemory(const char *buffer, size_t bufferSize)
    {
        Stop();

        if (GetPortCount())
        {
            port = userPort;
            rtmidi_open_port(rtMidiOut, port, "QB64-PE-MIDI-Player"); // TODO: Check this on macOS / Linux
            if (rtMidiOut->ok)
            {
                MIDIOutSysExReset(false);

                smf = fmidi_auto_mem_read(reinterpret_cast<const uint8_t *>(buffer), bufferSize);
                if (smf)
                {
                    format = fmidi_mem_identify(reinterpret_cast<const uint8_t *>(buffer), bufferSize);
                    player = fmidi_player_new(smf);
                    if (player)
                    {
                        totalTime = fmidi_smf_compute_duration(smf);

                        fmidi_player_event_callback(player, PlayerEventCallback, this);
                        fmidi_player_finish_callback(player, PlayerFinishCallback, this);
                        fmidi_player_start(player);

                        midiTimer.SetCallback([this]()
                                              {
                                                    auto now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
                                                    
                                                    if (haveMIDITick)
                                                    {
                                                        fmidi_player_tick(player, now - lastMIDITick);
                                                        currentTime = fmidi_player_current_time(player);
                                                    }

                                                    haveMIDITick = true;
                                                    lastMIDITick = now; },
                                              std::chrono::milliseconds(TimerInterval));

                        midiTimer.Start();

                        return QB_TRUE;
                    }
                }
            }
        }

        Stop();

        return QB_FALSE;
    }

    /// @brief Stops MIDI playback if it is currently playing and releases all related resources.
    void Stop()
    {
        midiTimer.Stop();

        fmidi_player_free(player);
        player = nullptr;

        fmidi_smf_free(smf);
        smf = nullptr;

        if (rtMidiOut)
        {
            if (port >= 0)
            {
                rtmidi_close_port(rtMidiOut);
                port = -1;
            }

            rtmidi_out_free(rtMidiOut);

            rtMidiOut = nullptr;
        }

        haveMIDITick = false;
        lastMIDITick = 0.0;
        totalTime = 0.0;
        currentTime = 0.0;
        paused = false;
        volumeDirtyCounter = VolumeDirtyCounterTicks;
    }

    /// @brief Checks if the MIDI player is currently playing.
    /// @return QB_TRUE if the player is running; QB_FALSE otherwise.
    qb_bool IsPlaying()
    {
        return (player && (loops || currentTime < totalTime)) ? QB_TRUE : QB_FALSE;
    }

    /// @brief Sets the number of times the MIDI playback will loop.
    /// @param loops The number of loops to set. A value of 0 means no looping, a positive value indicates the number of times to repeat playback, while a negative value indicates an infinite loop.
    void Loop(int32_t loops)
    {
        this->loops = loops;
    }

    /// @brief Checks if the MIDI player is currently set to loop.
    /// @return QB_TRUE if the player is set to loop; QB_FALSE otherwise.
    qb_bool IsLooping()
    {
        return loops != 0 ? QB_TRUE : QB_FALSE;
    }

    /// @brief Pauses or unpauses the MIDI playback.
    /// @param state QB_TRUE to pause, QB_FALSE to unpause.
    void Pause(int8_t state)
    {
        if (player)
        {
            if (state)
            {
                midiTimer.Stop();
                haveMIDITick = false;
                fmidi_player_stop(player);
                MidiOutSoundOff();
            }
            else
            {
                fmidi_player_start(player);
                midiTimer.Start();
            }
        }
    }

    qb_bool IsPaused()
    {
        return midiTimer.IsRunning() ? QB_FALSE : QB_TRUE;
    }

    /// @brief Gets the total time in seconds of the currently loaded MIDI file.
    /// @return The total time in seconds of the currently loaded MIDI file.
    double GetTotalTime()
    {
        return totalTime;
    }

    /// @brief Gets the current time in seconds of the currently playing MIDI file.
    /// @return The current time in seconds of the currently playing MIDI file. If the player is not running, returns 0.0.
    double GetCurrentTime()
    {
        return currentTime;
    }

    /// @brief Sets the volume of the MIDI output.
    /// @param volume The volume to set, specified as a value between 0.0 and 1.0.
    void SetVolume(float volume)
    {
        volume = std::clamp(volume, 0.0f, 1.0f);
        if (this->volume != volume)
        {
            this->volume = volume;
            volumeDirtyCounter = VolumeDirtyCounterTicks;
        }
    }

    /// @brief Gets the volume of the MIDI output.
    /// @return The volume of the MIDI output, specified as a value between 0.0 and 1.0.
    float GetVolume()
    {
        return volume;
    }

    /// @brief Seeks the MIDI playback to the specified time position.
    /// @param time The time position in seconds to seek to.
    void SeekToTime(double time)
    {
        if (player)
        {
            fmidi_player_goto_time(player, time);
        }
    }

    /// @brief Gets the format of the currently loaded MIDI file.
    /// @return The format of the currently loaded MIDI file, specified as a null-terminated string.
    const char *GetFormat()
    {
        switch (format)
        {
        case fmidi_fileformat_smf:
            return "Standard MIDI";
        case fmidi_fileformat_xmi:
            return "eXtended MIDI";
        case fmidi_fileformat_mus:
            return "DMX MIDI";
        default:
            return "Unknown";
        }
    }

    /// @brief Retrieves the singleton instance of the MIDI player.
    static __MIDIPlayer &Instance()
    {
        static __MIDIPlayer instance;
        return instance;
    }

private:
    static constexpr auto DefaultPort = 0;              // Default MIDI port number
    static constexpr auto TimerInterval = 1;            // Timer interval in milliseconds
    static constexpr auto Channels = 16;                // Number of MIDI channels
    static constexpr auto SysExEnd = 0xF7u;             // SysEx end byte status code
    static constexpr auto VolumeDirtyCounterTicks = 10; // Number of MIDI ticks before sending the volume change message
    static constexpr uint8_t SysExResetGM[] = {0xF0, 0x7E, 0x7F, 0x09, 0x01, 0xF7};
    static constexpr uint8_t SysExResetGM2[] = {0xF0, 0x7E, 0x7F, 0x09, 0x03, 0xF7};
    static constexpr uint8_t SysExResetGS[] = {0xF0, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7F, 0x00, 0x41, 0xF7};
    static constexpr uint8_t SysExResetXG[] = {0xF0, 0x43, 0x10, 0x4C, 0x00, 0x00, 0x7E, 0x00, 0xF7};

    /// @brief A timer class for MIDI playback.
    class Timer
    {
    public:
        Timer() : running(false) {}

        ~Timer() { Stop(); }

        /// @brief Sets the callback function for this timer, which will be called at the given interval.
        /// @param callback A callable object (such as a lambda or a std::function) that takes no arguments and returns void.
        /// @param interval The interval at which the callback will be called, specified in milliseconds.
        void SetCallback(std::function<void()> callback,
                         std::chrono::milliseconds interval)
        {
            this->callback = callback;
            this->interval = interval;
        }

        /// @brief Starts the timer, which will call the callback function at the given interval.
        /// @return true if the timer was started successfully, false otherwise.
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

        /// @brief Stops the timer, halting the callback function calls. If the timer is not running, this function does nothing. If the timer is running, this function will wait for the worker thread to finish before returning.
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

    __MIDIPlayer() : rtMidiOut(nullptr), port(-1), userPort(DefaultPort), smf(nullptr), player(nullptr), haveMIDITick(false), lastMIDITick(0.0), totalTime(0.0), currentTime(0.0), loops(0), paused(false), volume(1.0f), volumeDirtyCounter(VolumeDirtyCounterTicks), format(fmidi_fileformat_smf) {}

    ~__MIDIPlayer()
    {
        Stop();
    }

    __MIDIPlayer(const __MIDIPlayer &) = delete;
    __MIDIPlayer &operator=(const __MIDIPlayer &) = delete;

    /// @brief Stops all sounds on all MIDI channels. This is used when pausing a MIDI file playback to ensure there is no sound coming from the MIDI output.
    void MidiOutSoundOff()
    {
        if (rtMidiOut)
        {
            for (uint8_t c = 0; c < Channels; c++)
            {
                // All sound off
                {
                    uint8_t msg[]{(uint8_t)((0b1011 << 4) | c), 120, 0};
                    rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                }
            }
        }
    }

    /// @brief Resets all MIDI channels by sending SysEx reset messages for XG, GM2 and GM modes.
    /// @param isXG Channel 10 is configured as a drum kit in XG mode if this is true.
    void MIDIOutSysExReset(bool isXG)
    {
        if (rtMidiOut)
        {

            // Send SysEx reset messages using rtmidi_out_send_message
            rtmidi_out_send_message(rtMidiOut, SysExResetXG, sizeof(SysExResetXG));
            rtmidi_out_send_message(rtMidiOut, SysExResetGM2, sizeof(SysExResetGM2));
            rtmidi_out_send_message(rtMidiOut, SysExResetGM, sizeof(SysExResetGM));

            // Loop for sending control changes and other events for each channel
            for (uint8_t c = 0; c < Channels; c++)
            {
                {
                    uint8_t msg[]{(uint8_t)((0b1011 << 4) | c), 120, 0}; // CC 120 Channel Mute / Sound Off
                    rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                }

                {
                    uint8_t msg[]{(uint8_t)((0b1011 << 4) | c), 121, 0}; // CC 121 Reset All Controllers
                    rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                }

                if (!isXG || c != 9)
                {
                    {
                        uint8_t msg[]{(uint8_t)((0b1011 << 4) | c), 32, 0}; // CC 32 Bank select LSB
                        rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                    }

                    {
                        uint8_t msg[]{(uint8_t)((0b1011 << 4) | c), 0, 0}; // CC 0 Bank select MSB
                        rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                    }

                    {
                        uint8_t msg[]{(uint8_t)((0b1100 << 4) | c), 0}; // Program Change 0
                        rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
                    }
                }

                {
                    uint8_t msg[]{(uint8_t)((0b1110 << 4) | c), 0, 0b1000000}; // Pitch bend change
                    rtmidi_out_send_message(rtMidiOut, msg, sizeof(msg));
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
    }

    /// @brief Check if the given SysEx message is a reset message.
    /// @param data The SysEx message to check.
    /// @returns true if the message is a reset message, false otherwise.
    static bool IsSysExReset(const uint8_t *data)
    {
        return IsSysExEqual(data, SysExResetGM) || IsSysExEqual(data, SysExResetGM2) || IsSysExEqual(data, SysExResetGS) || IsSysExEqual(data, SysExResetXG);
    }

    /// @brief Compares two SysEx messages to determine if they are equal.
    /// @param a Pointer to the first SysEx message.
    /// @param b Pointer to the second SysEx message.
    /// @return true if both SysEx messages are equal, false otherwise.
    static bool IsSysExEqual(const uint8_t *a, const uint8_t *b)
    {
        while ((*a != SysExEnd) && (*b != SysExEnd) && (*a == *b))
        {
            a++;
            b++;
        }

        return (*a == *b);
    }

    /// @brief Callback function to handle MIDI player events.
    /// @param event Pointer to the MIDI event structure.
    /// @param data Pointer to user data, expected to be a __MIDIPlayer instance.
    static void PlayerEventCallback(const fmidi_event_t *event, void *data)
    {
        auto player = static_cast<__MIDIPlayer *>(data);

        if (event->type == fmidi_event_message)
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

            if (player->volumeDirtyCounter > 0)
            {
                player->volumeDirtyCounter--;
            }
            else if (player->volumeDirtyCounter == 0)
            {
                uint16_t volume = player->volume * 16383; // clamp volume to [0.0, 1.0] and scale volume to 14-bit range

                // Construct the SysEx message for setting the global volume
                uint8_t msg[]{0xF0, 0x7F, 0x7F, 0x04, 0x01, uint8_t(volume & 0x7F), uint8_t((volume >> 7) & 0x7F), 0xF7};

                rtmidi_out_send_message(player->rtMidiOut, msg, sizeof(msg));

                player->volumeDirtyCounter--; // push the counter to a negative value to prevent sending the volume change message again
            }
        }
    }

    /// @brief Callback function to handle the finish of a MIDI player.
    /// @param data Pointer to user data, expected to be a __MIDIPlayer instance.
    static void PlayerFinishCallback(void *data)
    {
        auto player = static_cast<__MIDIPlayer *>(data);

        if (player->loops > 0)
        {
            player->loops--;

            if (player->loops > 0)
            {
                fmidi_player_rewind(player->player);
                fmidi_player_start(player->player);
            }
        }
        else if (player->loops < 0)
        {
            fmidi_player_rewind(player->player);
            fmidi_player_start(player->player);
        }
    }

    RtMidiOutPtr rtMidiOut;
    int64_t port;
    uint32_t userPort;
    fmidi_smf_t *smf;
    fmidi_player_t *player;
    Timer midiTimer;
    bool haveMIDITick;
    double lastMIDITick;
    double totalTime;
    double currentTime;
    int32_t loops;
    bool paused;
    float volume;
    int volumeDirtyCounter;
    fmidi_fileformat_t format;
};

const char *MIDI_GetErrorMessage()
{
    return __MIDIPlayer::Instance().GetErrorMessage();
}

uint32_t MIDI_GetPortCount()
{
    return __MIDIPlayer::Instance().GetPortCount();
}

const char *MIDI_GetPortName(uint32_t portIndex)
{
    return __MIDIPlayer::Instance().GetPortName(portIndex);
}

qb_bool MIDI_SetPort(uint32_t portIndex)
{
    return __MIDIPlayer::Instance().SetPort(portIndex);
}

uint32_t MIDI_GetPort()
{
    return __MIDIPlayer::Instance().GetPort();
}

inline qb_bool __MIDI_PlayFromMemory(const char *buffer, size_t bufferSize)
{
    return __MIDIPlayer::Instance().PlayFromMemory(buffer, bufferSize);
}

void MIDI_Stop()
{
    __MIDIPlayer::Instance().Stop();
}

qb_bool MIDI_IsPlaying()
{
    return __MIDIPlayer::Instance().IsPlaying();
}

void MIDI_Loop(int32_t loops)
{
    __MIDIPlayer::Instance().Loop(loops);
}

qb_bool MIDI_IsLooping()
{
    return __MIDIPlayer::Instance().IsLooping();
}

void MIDI_Pause(int8_t state)
{
    __MIDIPlayer::Instance().Pause(state);
}

qb_bool MIDI_IsPaused()
{
    return __MIDIPlayer::Instance().IsPaused();
}

double MIDI_GetTotalTime()
{
    return __MIDIPlayer::Instance().GetTotalTime();
}

double MIDI_GetCurrentTime()
{
    return __MIDIPlayer::Instance().GetCurrentTime();
}

void MIDI_SetVolume(float volume)
{
    __MIDIPlayer::Instance().SetVolume(volume);
}

float MIDI_GetVolume()
{
    return __MIDIPlayer::Instance().GetVolume();
}

const char *MIDI_GetFormat()
{
    return __MIDIPlayer::Instance().GetFormat();
}

void MIDI_SeekToTime(double time)
{
    __MIDIPlayer::Instance().SeekToTime(time);
}

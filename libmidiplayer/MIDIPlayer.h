//----------------------------------------------------------------------------------------------------------------------
// MIDI Player Library
// Copyright (c) 2024 Samuel Gomes
//
// This uses:
// foo_midi (heavily modified) from https://github.com/stuerp/foo_midi (MIT license)
// libmidi (modified) https://github.com/stuerp/libmidi (MIT license)
// Opal (refactored) from https://www.3eality.com/productions/reality-adlib-tracker (Public Domain)
// primesynth (heavily modified) from https://github.com/mosmeh/primesynth (MIT license)
// stb_vorbis.c from https://github.com/nothings/stb (Public Domain)
// TinySoundFont from https://github.com/schellingb/TinySoundFont (MIT license)
// ymfmidi (heavily modified) from https://github.com/devinacker/ymfmidi (BSD-3-Clause license)
//----------------------------------------------------------------------------------------------------------------------

#pragma once

// #define TOOLBOX64_DEBUG 1
#include "../Debug.h"
#include "../Types.h"
#include "foo_midi/InstrumentBankManager.cpp"
#include "foo_midi/MIDIPlayer.cpp"
#include "foo_midi/OpalPlayer.cpp"
#include "foo_midi/PSPlayer.cpp"
#include "foo_midi/TSFPlayer.cpp"
#ifdef _WIN32
#include "foo_midi/VSTiPlayer.cpp"
#endif
#include "libmidi/MIDIContainer.cpp"
#include "libmidi/MIDIProcessor.cpp"
#include "libmidi/MIDIProcessorGMF.cpp"
#include "libmidi/MIDIProcessorHMI.cpp"
#include "libmidi/MIDIProcessorHMP.cpp"
#include "libmidi/MIDIProcessorLDS.cpp"
#include "libmidi/MIDIProcessorMDS.cpp"
#include "libmidi/MIDIProcessorMUS.cpp"
#include "libmidi/MIDIProcessorRCP.cpp"
#include "libmidi/MIDIProcessorRIFF.cpp"
#include "libmidi/MIDIProcessorSMF.cpp"
#include "libmidi/MIDIProcessorXMI.cpp"
#include "libmidi/Recomposer/CM6File.cpp"
#include "libmidi/Recomposer/GDSFile.cpp"
#include "libmidi/Recomposer/MIDIStream.cpp"
#include "libmidi/Recomposer/RCP.cpp"
#include "libmidi/Recomposer/RCPConverter.cpp"
#include "libmidi/Recomposer/RunningNotes.cpp"
#include "libmidi/Recomposer/Support.cpp"
#include "primesynth/primesynth.cpp"
#include "TinySoundFont/tsf.cpp"
#include "ymfmidi/player.cpp"
#include "ymfmidi/patches.cpp"

class DoubleBufferFrameBlock
{
    struct Frame
    {
        float l;
        float r;
    };

    std::vector<Frame> blocks[2];
    size_t index = 0;  // current reading block index
    size_t cursor = 0; // cursor in the active block

public:
    DoubleBufferFrameBlock(const DoubleBufferFrameBlock &) = delete;
    DoubleBufferFrameBlock(DoubleBufferFrameBlock &&) = delete;
    DoubleBufferFrameBlock &operator=(const DoubleBufferFrameBlock &) = delete;
    DoubleBufferFrameBlock &operator=(DoubleBufferFrameBlock &&) = delete;

    DoubleBufferFrameBlock() { Reset(); }

    void Reset()
    {
        blocks[0].clear();
        blocks[1].clear();
        index = 0;
        cursor = 0;
    }

    bool IsEmpty() const { return blocks[0].empty() && blocks[1].empty(); }

    float *Put(size_t frames)
    {
        auto writeIndex = 1 - index;

        if (blocks[writeIndex].empty())
        {
            blocks[writeIndex].resize(frames);
            return reinterpret_cast<float *>(blocks[writeIndex].data());
        }

        return nullptr;
    }

    void Get(float *data, size_t frames)
    {
        if (blocks[index].empty())
        {
            index = 1 - index;
            cursor = 0;

            if (blocks[index].empty())
                return; // no data available
        }

        auto toCopy = std::min(frames, blocks[index].size() - cursor); // clip to block size
        std::memcpy(data, blocks[index].data() + cursor, toCopy * sizeof(Frame));
        cursor += toCopy;

        if (toCopy < frames)
        {
            blocks[index].clear();
            index = 1 - index;
            cursor = 0;

            if (blocks[index].empty())
                return; // partial data copied

            auto remaining = std::min(frames - toCopy, blocks[index].size()); // clip to block size
            std::memcpy(data + toCopy * 2, blocks[index].data(), remaining * sizeof(Frame));
            cursor += remaining;
        }

        if (cursor >= blocks[index].size())
        {
            blocks[index].clear();
            index = 1 - index;
            cursor = 0;
        }
    }
};

struct MIDIManager
{
    MIDIPlayer *sequencer;
    midi_container_t *container;
    InstrumentBankManager instrumentBankManager;
    std::string songName;
    uint32_t totalTime;
    qb_bool isLooping;
    qb_bool isPlaying;
    uint32_t trackNumber;
    DoubleBufferFrameBlock frameBlock; // only needed when a player cannot do variable frame rendering (e.g. VSTiPlayer)
    bool isReallyPlaying;              // again, only needed when a player cannot do variable frame rendering

    MIDIManager() : sequencer(nullptr), container(nullptr), totalTime(0), isLooping(QB_FALSE), isPlaying(QB_FALSE), trackNumber(0), isReallyPlaying(false) {}
};

static MIDIManager g_MIDIManager;

/// @brief Check if a MIDI file is playing
/// @return Returns QB64 TRUE if we are playing a MIDI file
inline qb_bool MIDI_IsPlaying()
{
    return g_MIDIManager.sequencer && g_MIDIManager.container ? g_MIDIManager.isPlaying : QB_FALSE;
}

/// @brief Checks the MIDI file is set to loop
/// @return Returns QB64 TRUE if a file is set to loop
inline qb_bool MIDI_IsLooping()
{
    return g_MIDIManager.sequencer && g_MIDIManager.container ? g_MIDIManager.isLooping : QB_FALSE;
}

/// @brief Sets the MIDI to until unit it is stopped
/// @param looping QB64 TRUE or FALSE
void MIDI_Loop(qb_bool looping)
{
    if (g_MIDIManager.sequencer && g_MIDIManager.container)
        g_MIDIManager.isLooping = TO_QB_BOOL(looping); // save the looping flag
}

/// @brief Returns the total playback times in msecs
/// @return time in msecs
inline uint32_t MIDI_GetTotalTime()
{
    return g_MIDIManager.sequencer && g_MIDIManager.container ? g_MIDIManager.totalTime : 0;
}

/// @brief Returns the current playback time in msec
/// @return Times in msecs
inline uint32_t MIDI_GetCurrentTime()
{
    return g_MIDIManager.sequencer && g_MIDIManager.container ? g_MIDIManager.sequencer->GetPosition() : 0;
}

/// @brief Returns the total number of voice that are playing
/// @return Count of active voices
inline uint32_t MIDI_GetActiveVoices()
{
    // 18 if we are in OPL3 mode else whatever TSF returns
    return g_MIDIManager.sequencer && g_MIDIManager.container ? g_MIDIManager.sequencer->GetActiveVoiceCount() : 0;
}

/// @brief Returns the identifier of the MIDI renderer is use
/// @return A
inline uint32_t MIDI_GetSynthType()
{
    return uint32_t(g_MIDIManager.instrumentBankManager.GetType());
}

/// @brief Sets the MIDI renderer
/// @param fileNameOrBuffer The name or buffer of the MIDI instrument
/// @param bufferSize The size of the buffer in BYTES! If zero, fileNameOrBuffer is assumed to be a file name
/// @param synthType The MIDI renderer to use. This is ignored if fileNameOrBuffer is a file name
inline void __MIDI_SetSynth(const char *fileNameOrBuffer, size_t bufferSize, uint32_t synthType)
{
    if (bufferSize)
        g_MIDIManager.instrumentBankManager.SetData(reinterpret_cast<uint8_t const *>(fileNameOrBuffer), bufferSize, (InstrumentBankManager::Type)synthType);
    else
        g_MIDIManager.instrumentBankManager.SetPath(fileNameOrBuffer);
}

/// @brief Kickstarts playback if library is initalized and MIDI file is loaded
void MIDI_Play()
{
    if (g_MIDIManager.sequencer && g_MIDIManager.container)
    {
        try
        {
            if (g_MIDIManager.sequencer->Load(*g_MIDIManager.container, g_MIDIManager.trackNumber, g_MIDIManager.isLooping ? LoopType::PlayIndefinitely : LoopType::NeverLoop, 0))
            {
                g_MIDIManager.isPlaying = QB_TRUE;
                g_MIDIManager.isReallyPlaying = true;
                g_MIDIManager.frameBlock.Reset();
            }
        }
        catch (std::exception &e)
        {
            TOOLBOX64_DEBUG_PRINT("Exception: %s", e.what());
        }
    }
}

/// @brief Stops playback and unloads the MIDI file from memory
void MIDI_Stop()
{
    if (g_MIDIManager.sequencer || g_MIDIManager.container)
    {
        delete g_MIDIManager.sequencer;
        g_MIDIManager.sequencer = nullptr;

        delete g_MIDIManager.container;
        g_MIDIManager.container = nullptr;

        g_MIDIManager.totalTime = 0;
        g_MIDIManager.trackNumber = 0;
        g_MIDIManager.isPlaying = QB_FALSE;
        g_MIDIManager.isReallyPlaying = false;

        g_MIDIManager.songName.clear();

        TOOLBOX64_DEBUG_PRINT("MIDI stopped");
    }
}

/// @brief Get the song name if any
/// @return A string containing the name (and other information)
const char *MIDI_GetSongName()
{
    return g_MIDIManager.songName.c_str();
}

/// @brief This frees resources (if a file was previously loaded) and then loads a MIDI file from memory for playback
/// @param buffer The memory buffer containing the full file
/// @param bufferSize The size of the memory buffer
/// @param sampleRate The sample rate to use
/// @return Returns QB64 TRUE if the operation was successful
inline qb_bool __MIDI_LoadTuneFromMemory(const void *buffer, uint32_t bufferSize, uint32_t sampleRate)
{
    TOOLBOX64_DEBUG_PRINT("Loading tune from memory");

    if (!buffer || !bufferSize || !sampleRate)
    {
        TOOLBOX64_DEBUG_PRINT("Invalid parameters");

        return QB_FALSE;
    }

    MIDI_Stop();

    std::vector<uint8_t> buf(reinterpret_cast<const uint8_t *>(buffer), reinterpret_cast<const uint8_t *>(buffer) + bufferSize);

    switch (g_MIDIManager.instrumentBankManager.GetType())
    {
    case InstrumentBankManager::Type::Opal:
        g_MIDIManager.sequencer = new OpalPlayer(&g_MIDIManager.instrumentBankManager);
        TOOLBOX64_DEBUG_PRINT("Using OpalPlayer");
        break;

    case InstrumentBankManager::Type::Primesynth:
        g_MIDIManager.sequencer = new PSPlayer(&g_MIDIManager.instrumentBankManager);
        TOOLBOX64_DEBUG_PRINT("Using PSPlayer");
        break;

    case InstrumentBankManager::Type::TinySoundFont:
        g_MIDIManager.sequencer = new TSFPlayer(&g_MIDIManager.instrumentBankManager);
        TOOLBOX64_DEBUG_PRINT("Using TSFPlayer");
        break;

#ifdef _WIN32
    case InstrumentBankManager::Type::VSTi:
        g_MIDIManager.sequencer = new VSTiPlayer(&g_MIDIManager.instrumentBankManager);
        TOOLBOX64_DEBUG_PRINT("Using VSTiPlayer");
        break;
#endif

    default:
        TOOLBOX64_DEBUG_PRINT("Unknown synth type");
        error(QB_ERROR_FEATURE_UNAVAILABLE);
        return QB_FALSE;
    }

    if (g_MIDIManager.sequencer)
    {
        g_MIDIManager.sequencer->SetSampleRate(sampleRate);
        TOOLBOX64_DEBUG_PRINT("Sample rate set to %u", sampleRate);

        g_MIDIManager.container = new midi_container_t();
        if (g_MIDIManager.container)
        {
            bool success = false;

            try
            {
                success = midi_processor_t::Process(buf, "", *g_MIDIManager.container);
                TOOLBOX64_DEBUG_CHECK(success == true);
            }
            catch (std::exception &e)
            {
                TOOLBOX64_DEBUG_PRINT("Exception: %s", e.what());
            }

            if (success)
            {
                auto trackCount = g_MIDIManager.container->GetTrackCount();
                if (trackCount != 0)
                {
                    bool hasDuration = false;
                    g_MIDIManager.trackNumber = 0;

                    for (uint32_t i = 0; i < trackCount; ++i)
                    {
                        g_MIDIManager.totalTime = g_MIDIManager.container->GetDuration(i, true);
                        TOOLBOX64_DEBUG_PRINT("MIDI track %u, duration: %u", i, g_MIDIManager.totalTime);

                        if (g_MIDIManager.totalTime != 0)
                        {
                            hasDuration = true;
                            g_MIDIManager.trackNumber = i;
                            break;
                        }
                    }

                    if (hasDuration)
                    {
                        try
                        {
                            // Get the song name
                            midi_metadata_table_t metaData;
                            g_MIDIManager.container->GetMetaData(g_MIDIManager.trackNumber, metaData);
                            midi_metadata_item_t metaDataItem;
                            if (metaData.GetItem("track_name_00", metaDataItem))
                                g_MIDIManager.songName = metaDataItem.Value;
                        }
                        catch (std::exception &e)
                        {
                            TOOLBOX64_DEBUG_PRINT("Exception: %s", e.what());
                        }

                        g_MIDIManager.container->DetectLoops(true, true, true, true, true);

                        return QB_TRUE; // the only success exit point
                    }
                }
            }
        }
    }

    // Anything that is allocated and falls here will be cleaned up
    MIDI_Stop();

    return QB_FALSE;
}

/// @brief The calls the correct render function based on which renderer was chosen
/// @param buffer The buffer when the audio should be rendered
/// @param bufferSize The size of the buffer in BYTES!
inline void __MIDI_Render(float *buffer, uint32_t bufferSize)
{
    const auto fixedFrames = g_MIDIManager.sequencer->GetSampleBlockSize();

    if (fixedFrames)
    {
        // Only attempt to render if we are actually playing
        if (g_MIDIManager.isReallyPlaying)
        {
            auto dest = g_MIDIManager.frameBlock.Put(fixedFrames);
            if (dest)
                g_MIDIManager.isReallyPlaying = g_MIDIManager.sequencer->Play(dest, fixedFrames) > 0;
        }

        // Get partial data from the frame block
        g_MIDIManager.frameBlock.Get(buffer, bufferSize >> 3); // >> 3 = `/ channels * sizeof(float)`

        // Set the isPlaying flag to true if we still have some data in the buffers
        g_MIDIManager.isPlaying = TO_QB_BOOL(!g_MIDIManager.frameBlock.IsEmpty());
    }
    else
    {
        g_MIDIManager.isPlaying = TO_QB_BOOL(g_MIDIManager.sequencer->Play(buffer, bufferSize >> 3)); // >> 3 = `/ channels * sizeof(float)`
    }
}

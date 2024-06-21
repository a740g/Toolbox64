//----------------------------------------------------------------------------------------------------------------------
// MIDI Player Library
// Copyright (c) 2024 Samuel Gomes
//
// This uses:
// foo_midi (heavily modified) from https://github.com/stuerp/foo_midi (MIT license)
// Opal (refactored) from https://www.3eality.com/productions/reality-adlib-tracker (Public Domain)
// primesynth (heavily modified) from https://github.com/mosmeh/primesynth (MIT license)
// stb_vorbis.c from https://github.com/nothings/stb (Public Domain)
// TinySoundFont from https://github.com/schellingb/TinySoundFont (MIT license)
// ymfmidi (heavily modified) from https://github.com/devinacker/ymfmidi (BSD-3-Clause license)
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Types.h"
#include "Debug.h"
#include "midiplayer/OpalPlayer.cpp"
#include "midiplayer/PSPlayer.cpp"
#include "midiplayer/TSFPlayer.cpp"
#include "midiplayer/MIDIPlayer.cpp"
#include "midiplayer/MIDIContainer.cpp"
#include "midiplayer/MIDIProcessor.cpp"
#include "midiplayer/MIDIProcessorGMF.cpp"
#include "midiplayer/MIDIProcessorHMI.cpp"
#include "midiplayer/MIDIProcessorHMP.cpp"
#include "midiplayer/MIDIProcessorLDS.cpp"
#include "midiplayer/MIDIProcessorMDS.cpp"
#include "midiplayer/MIDIProcessorMUS.cpp"
#include "midiplayer/MIDIProcessorRCP.cpp"
#include "midiplayer/MIDIProcessorRIFF.cpp"
#include "midiplayer/MIDIProcessorSMF.cpp"
#include "midiplayer/MIDIProcessorXMI.cpp"
#include "midiplayer/OPLPatch.cpp"
#include "midiplayer/OpalMIDI.cpp"
#include "midiplayer/primesynth.cpp"
#include "midiplayer/InstrumentBankManager.cpp"

struct MIDIManager
{
    MIDIPlayer *sequencer;
    MIDIContainer *container;
    InstrumentBankManager instrumentBankManager;
    std::string songName;
    uint32_t totalTime;
    qb_bool isLooping;
    qb_bool isPlaying;

    MIDIManager() : sequencer(nullptr), container(nullptr), totalTime(0), isLooping(QB_FALSE), isPlaying(QB_FALSE) {}
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
        g_MIDIManager.sequencer->Load(*g_MIDIManager.container, 0, g_MIDIManager.isLooping ? LoopType::PlayIndefinitely : LoopType::NeverLoop, 0);
        g_MIDIManager.isPlaying = QB_TRUE;
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
        g_MIDIManager.isPlaying = QB_FALSE;

        g_MIDIManager.songName.clear();
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
    if (!buffer || !bufferSize || !sampleRate)
        return QB_FALSE;

    MIDI_Stop();

    std::vector<uint8_t> buf(reinterpret_cast<const uint8_t *>(buffer), reinterpret_cast<const uint8_t *>(buffer) + bufferSize);
    MIDIProcessor MIDI_Processor;

    switch (g_MIDIManager.instrumentBankManager.GetType())
    {
    case InstrumentBankManager::Type::Opal:
        g_MIDIManager.sequencer = new OpalPlayer(&g_MIDIManager.instrumentBankManager);
        break;

    case InstrumentBankManager::Type::Primesynth:
        g_MIDIManager.sequencer = new PSPlayer(&g_MIDIManager.instrumentBankManager);
        break;

    case InstrumentBankManager::Type::TinySoundFont:
        g_MIDIManager.sequencer = new TSFPlayer(&g_MIDIManager.instrumentBankManager);
        break;

    default:
        error(QB_ERROR_FEATURE_UNAVAILABLE);
        return QB_FALSE;
    }

    if (g_MIDIManager.sequencer)
    {
        g_MIDIManager.sequencer->SetSampleRate(sampleRate);

        g_MIDIManager.container = new MIDIContainer();
        if (g_MIDIManager.container)
        {
            if (MIDI_Processor.Process(buf, "", *g_MIDIManager.container))
            {
                g_MIDIManager.totalTime = g_MIDIManager.container->GetDuration(0, true);

                // Get the song name
                MIDIMetaData metaData;
                g_MIDIManager.container->GetMetaData(0, metaData);
                MIDIMetaDataItem metaDataItem;
                if (metaData.GetItem("track_name_00", metaDataItem))
                    g_MIDIManager.songName = metaDataItem.Value;

                return QB_TRUE;
            }
        }
    }

    MIDI_Stop();

    return QB_FALSE;
}

/// @brief The calls the correct render function based on which renderer was chosen
/// @param buffer The buffer when the audio should be rendered
/// @param bufferSize The size of the buffer in BYTES!
inline void __MIDI_Render(float *buffer, uint32_t bufferSize)
{
    g_MIDIManager.isPlaying = TO_QB_BOOL(g_MIDIManager.sequencer->Play(buffer, bufferSize >> 3));
}

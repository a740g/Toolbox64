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
#include "midiplayer/FMPlayer.cpp"
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

static MIDIPlayer *MIDI_Sequencer = nullptr;
static MIDIContainer *MIDI_Container = nullptr;
static uint32_t totalMsec = 0;
static qb_bool isLooping = QB_FALSE;
static qb_bool isPlaying = QB_FALSE;
static qb_bool useOPL3 = QB_FALSE;
static std::string g_SongName;

/// @brief Check if a MIDI file is playing
/// @return Returns QB64 TRUE if we are playing a MIDI file
inline qb_bool MIDI_IsPlaying()
{
    return MIDI_Sequencer && MIDI_Container ? isPlaying : QB_FALSE;
}

/// @brief Checks the MIDI file is set to loop
/// @return Returns QB64 TRUE if a file is set to loop
inline qb_bool MIDI_IsLooping()
{
    return MIDI_Sequencer && MIDI_Container ? isLooping : QB_FALSE;
}

/// @brief Sets the MIDI to until unit it is stopped
/// @param looping QB64 TRUE or FALSE
void MIDI_Loop(qb_bool looping)
{
    if (MIDI_Sequencer && MIDI_Container)
        isLooping = TO_QB_BOOL(looping); // Save the looping flag
}

/// @brief Returns the total playback times in msecs
/// @return time in msecs
inline uint32_t MIDI_GetTotalTime()
{
    return MIDI_Sequencer && MIDI_Container ? totalMsec : 0;
}

/// @brief Returns the current playback time in msec
/// @return Times in msecs
inline uint32_t MIDI_GetCurrentTime()
{
    return MIDI_Sequencer && MIDI_Container ? MIDI_Sequencer->GetPosition() : 0;
}

/// @brief Returns the total number of voice that are playing
/// @return Count of active voices
inline uint32_t MIDI_GetActiveVoices()
{
    // 18 if we are in OPL3 mode else whatever TSF returns
    return MIDI_Sequencer && MIDI_Container ? MIDI_Sequencer->GetActiveVoiceCount() : 0;
}

/// @brief Check what kind of MIDI renderer is being used
/// @return Return QB64 TRUE if using FM synthesis. Sample synthesis otherwise
inline qb_bool MIDI_IsFMSynthesis()
{
    return useOPL3;
}

/// @brief Kickstarts playback if library is initalized and MIDI file is loaded
void MIDI_Play()
{
    if (MIDI_Sequencer && MIDI_Container)
    {
        MIDI_Sequencer->Load(*MIDI_Container, 0, isLooping ? LoopType::PlayIndefinitely : LoopType::NeverLoop, 0);
        isPlaying = QB_TRUE;
    }
}

/// @brief Stops playback and unloads the MIDI file from memory
void MIDI_Stop()
{
    if (MIDI_Sequencer || MIDI_Container)
    {
        delete MIDI_Sequencer;
        MIDI_Sequencer = nullptr;

        delete MIDI_Container;
        MIDI_Container = nullptr;

        totalMsec = 0;
        isPlaying = QB_FALSE;

        g_SongName.clear();
    }
}

/// @brief Get the song name if any
/// @return A string containing the name (and other information)
const char *MIDI_GetSongName()
{
    return g_SongName.c_str();
}

/// @brief This frees resources (if a file was previously loaded) and then loads a MIDI file from memory for playback
/// @param buffer The memory buffer containing the full file
/// @param bufferSize The size of the memory buffer
/// @return Returns QB64 TRUE if the operation was successful
inline qb_bool __MIDI_LoadTuneFromMemory(const void *buffer, uint32_t bufferSize, uint32_t sampleRate, qb_bool useOPL3QB64)
{
    MIDI_Stop();

    if (!buffer || !bufferSize || !sampleRate)
        return QB_FALSE;

    std::vector<uint8_t> buf(reinterpret_cast<const uint8_t *>(buffer), reinterpret_cast<const uint8_t *>(buffer) + bufferSize);
    MIDIProcessor MIDI_Processor;

    useOPL3 = TO_QB_BOOL(useOPL3QB64);

    if (useOPL3)
        MIDI_Sequencer = new FMPlayer();
    else
        MIDI_Sequencer = new TSFPlayer();

    if (MIDI_Sequencer)
    {
        MIDI_Sequencer->SetSampleRate(sampleRate);

        MIDI_Container = new MIDIContainer();
        if (MIDI_Container)
        {
            if (MIDI_Processor.Process(buf, "", *MIDI_Container))
            {
                totalMsec = MIDI_Container->GetDuration(0, true);

                // Get the song name
                MIDIMetaData metaData;
                MIDI_Container->GetMetaData(0, metaData);
                MIDIMetaDataItem metaDataItem;
                if (metaData.GetItem("track_name_00", metaDataItem))
                    g_SongName = metaDataItem.Value;

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
    isPlaying = TO_QB_BOOL(MIDI_Sequencer->Play(buffer, bufferSize >> 3));
}

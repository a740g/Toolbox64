//----------------------------------------------------------------------------------------------------------------------
// MIDI Player Library
// Copyright (c) 2023 Samuel Gomes
//
// This uses:
// TinySoundFont from https://github.com/schellingb/TinySoundFont/blob/master/tsf.h
// TinyMidiLoader from https://github.com/schellingb/TinySoundFont/blob/master/tml.h
// ymfm from https://github.com/aaronsgiles/ymfm
// ymfmidi from https://github.com/devinacker/ymfmidi
// stb_vorbis.c from https://github.com/nothings/stb/blob/master/stb_vorbis.c
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#define STB_VORBIS_HEADER_ONLY
#include "external/stb_vorbis.c"
#define TSF_IMPLEMENTATION
#include "external/tsf.h"
#define TML_IMPLEMENTATION
#include "external/tml.h"
#include "external/soundfont.h"
#undef STB_VORBIS_HEADER_ONLY
#include "Common.h"
#include "external/ymfm/ymfm_adpcm.cpp"
#include "external/ymfm/ymfm_pcm.cpp"
#include "external/ymfm/ymfm_opl.cpp"
#include "external/ymfmidi/patchnames.cpp"
#include "external/ymfmidi/patches.cpp"
#include "external/ymfmidi/ymf_player.cpp"
#include "external/opl3_bank.h"

static void *contextTSFOPL3 = nullptr;         // TSF / OPL3 context
static tml_message *tinyMIDILoader = nullptr;  // TML context
static tml_message *tinyMIDIMessage = nullptr; // next message to be played (this is set to NULL once the song is over)
static uint32_t totalMsec = 0;                 // total duration of the MIDI song
static double currentMsec = 0;                 // current playback time
static uint32_t sampleRate = 0;                // the mixing sample rate (should be same as SndRate in QB64)
static float globalVolume = 1.0f;              // this is the global volume (0.0 - 1.0)
static qb_bool isLooping = QB_FALSE;           // flag to indicate if we should loop a song
static qb_bool isOPL3Active = QB_FALSE;        // flag to indicate if we are using TSF or OPL3
static int16_t *bufferOPL = nullptr;           // this buffer will be used to render 16-bit 44100 samples from the OPL

/// @brief Check if MIDI library is initialized
/// @return Returns QB64 TRUE if it is initialized
qb_bool MIDI_IsInitialized()
{
    return contextTSFOPL3 ? QB_TRUE : QB_FALSE;
}

/// @brief Checks if a MIDI file is loaded into memory
/// @return Returns QB64 TRUE if a MIDI tune is loaded
qb_bool MIDI_IsTuneLoaded()
{
    return contextTSFOPL3 && tinyMIDILoader ? QB_TRUE : QB_FALSE;
}

/// @brief Check if a MIDI file is playing
/// @return Returns QB64 TRUE if we are playing a MIDI file
qb_bool MIDI_IsPlaying()
{
    return contextTSFOPL3 && tinyMIDIMessage ? QB_TRUE : QB_FALSE;
}

/// @brief Checks the MIDI file is set to loop
/// @return Returns QB64 TRUE if a file is set to loop
qb_bool MIDI_IsLooping()
{
    return contextTSFOPL3 && tinyMIDIMessage ? isLooping : QB_FALSE;
}

/// @brief Sets the MIDI to until unit it is stopped
/// @param looping QB64 TRUE or FALSE
void MIDI_Loop(int8_t looping)
{
    if (contextTSFOPL3 && tinyMIDILoader)
        isLooping = (qb_bool)looping; // Save the looping flag
}

/// @brief Sets the playback volume when a file is loaded
/// @param volume 0.0 = none, 1.0 = full
void MIDI_SetVolume(float volume)
{
    if (contextTSFOPL3 && tinyMIDILoader)
    {
        if (isOPL3Active)
            globalVolume = volume; // simply save the volume for OPL3. We'll use it elsewhere
        else
            tsf_set_volume((tsf *)contextTSFOPL3, globalVolume = volume); // save and apply the volume
    }
}

/// @brief Returns the current playback volume
/// @return 0.0 = none, 1.0 = full
float MIDI_GetVolume()
{
    return globalVolume;
}

/// @brief Returns the total playback times in msecs
/// @return time in msecs
double MIDI_GetTotalTime()
{
    return contextTSFOPL3 && tinyMIDILoader ? totalMsec : 0;
}

/// @brief Returns the current playback time in msec
/// @return Times in msecs
double MIDI_GetCurrentTime()
{
    return contextTSFOPL3 && tinyMIDILoader ? currentMsec : 0;
}

/// @brief Returns the total number of voice that are playing
/// @return Count of active voices
uint32_t MIDI_GetActiveVoices()
{
    // 18 if we are in OPL3 mode else whatever TSF returns
    return contextTSFOPL3 && tinyMIDIMessage ? (isOPL3Active ? 18 : tsf_active_voice_count((tsf *)contextTSFOPL3)) : 0;
}

/// @brief Kickstarts playback if library is initalized and MIDI file is loaded
void MIDI_Play()
{
    if (contextTSFOPL3 && tinyMIDILoader)
    {
        tinyMIDIMessage = tinyMIDILoader; // Set up the global MidiMessage pointer to the first MIDI message
        currentMsec = 0;                  // Reset playback time

        if (!isOPL3Active) // set TSF volume here because OPL volume is updated with each render pass
            tsf_set_volume((tsf *)contextTSFOPL3, globalVolume);
    }
}

/// @brief Stops playback and unloads the MIDI file from memory
void MIDI_Stop()
{
    if (contextTSFOPL3 && tinyMIDILoader)
    {
        if (isOPL3Active)
            reinterpret_cast<OPLPlayer *>(contextTSFOPL3)->reset(); // stop playing whatever is playing
        else
            tsf_reset((tsf *)contextTSFOPL3); // stop playing whatever is playing

        tml_free(tinyMIDILoader);                   // free TML resources
        tinyMIDILoader = tinyMIDIMessage = nullptr; // reset globals
        currentMsec = totalMsec = 0;                // reset times
    }
}

/// @brief This frees resources (if a file was previously loaded) and then loads a MIDI file into memory for playback
/// @param midi_filename A valid file name
/// @return Returns QB64 TRUE if the operation was successful
qb_bool __MIDI_LoadTuneFromFile(const char *midi_filename)
{
    if (MIDI_IsTuneLoaded())
        MIDI_Stop(); // stop if anything is playing

    if (contextTSFOPL3)
    {
        tinyMIDILoader = tml_load_filename(midi_filename);
        if (!tinyMIDILoader)
            return QB_FALSE;

        // Get the total duration of the song ignoring the rest of the stuff
        tml_get_info(tinyMIDILoader, nullptr, nullptr, nullptr, nullptr, &totalMsec);

        return QB_TRUE;
    }

    return QB_FALSE;
}

/// @brief This frees resources (if a file was previously loaded) and then loads a MIDI file from memory for playback
/// @param buffer The memory buffer containing the full file
/// @param bufferSize The size of the memory buffer
/// @return Returns QB64 TRUE if the operation was successful
qb_bool __MIDI_LoadTuneFromMemory(const void *buffer, uint32_t bufferSize)
{
    if (MIDI_IsTuneLoaded())
        MIDI_Stop(); // stop if anything is playing

    if (contextTSFOPL3)
    {
        tinyMIDILoader = tml_load_memory(buffer, bufferSize);
        if (!tinyMIDILoader)
            return QB_FALSE;

        // Get the total duration of the song ignoring the rest of the stuff
        tml_get_info(tinyMIDILoader, nullptr, nullptr, nullptr, nullptr, &totalMsec);

        return QB_TRUE;
    }

    return QB_FALSE;
}

/// @brief This shuts down the library and stop any MIDI playback and frees resources (if a file was previously loaded)
void __MIDI_Finalize()
{
    if (MIDI_IsTuneLoaded())
        MIDI_Stop(); // stop if anything is playing

    // Free TSF/OPL resources if initialized
    if (contextTSFOPL3)
    {
        if (isOPL3Active)
            delete reinterpret_cast<OPLPlayer *>(contextTSFOPL3);
        else
            tsf_close((tsf *)contextTSFOPL3);

        // Free temp buffers if it was allocated
        if (bufferOPL)
        {
            free(bufferOPL);
            bufferOPL = nullptr;
        }

        contextTSFOPL3 = nullptr;
    }
}

/// @brief This initializes the library
/// @param sampleRateQB64 QB64 device sample rate
/// @param useOPL3 If this is true then the OPL3 emulation is used instead of TSF
/// @return Returns QB64 TRUE if everything went well
qb_bool __MIDI_Initialize(uint32_t sampleRateQB64, int8_t useOPL3)
{
    // Return success if we are already initialized
    if (contextTSFOPL3)
        return QB_TRUE;

    sampleRate = sampleRateQB64; // save the sample rate. No checks are done. Bad stuff may happen if this is garbage

    if (useOPL3)
    {
        contextTSFOPL3 = new OPLPlayer(sampleRate); // use OPL3 FM synth
        if (!contextTSFOPL3)
            return QB_FALSE;

        if (!reinterpret_cast<OPLPlayer *>(contextTSFOPL3)->loadPatches("fmbank.wopl") &&
            !reinterpret_cast<OPLPlayer *>(contextTSFOPL3)->loadPatches("fmbank.op2") &&
            !reinterpret_cast<OPLPlayer *>(contextTSFOPL3)->loadPatches("fmbank.tmb") &&
            !reinterpret_cast<OPLPlayer *>(contextTSFOPL3)->loadPatches("fmbank.bnk") &&
            !reinterpret_cast<OPLPlayer *>(contextTSFOPL3)->loadPatches("fmbank.ad") &&
            !reinterpret_cast<OPLPlayer *>(contextTSFOPL3)->loadPatches("fmbank.opl"))
        {
            TOOLBOX64_DEBUG_PRINT("fmbank.wopl/op2/tmb/bnk/ad/opl not found");

            if (!reinterpret_cast<OPLPlayer *>(contextTSFOPL3)->loadPatches(fmbank_wopl, sizeof(fmbank_wopl)))
            {
                delete reinterpret_cast<OPLPlayer *>(contextTSFOPL3);
                return QB_FALSE;
            }
        }
    }
    else
    {
        contextTSFOPL3 = tsf_load_filename("soundfont.sf3"); // attempt to load a SF3 SoundFont from a file
        if (!contextTSFOPL3)
        {
            TOOLBOX64_DEBUG_PRINT("soundfont.sf3 not found");
            contextTSFOPL3 = tsf_load_filename("soundfont.sf2"); // attempt to load a SF2 SoundFont from a file
            if (!contextTSFOPL3)
            {
                TOOLBOX64_DEBUG_PRINT("soundfont.sf2 not found");
                contextTSFOPL3 = tsf_load_memory(soundfont_sf3, sizeof(soundfont_sf3)); // attempt to load the soundfont from memory
                if (!contextTSFOPL3)
                    return QB_FALSE; // return failue if loading from memory also failed. This should not happen though
            }
        }
    }

    isOPL3Active = (qb_bool)useOPL3; // save the type of renderer

    if (!isOPL3Active)
    {
        tsf_channel_set_bank_preset((tsf *)contextTSFOPL3, 9, 128, 0);             // initialize preset on special 10th MIDI channel to use percussion sound bank (128) if available
        tsf_set_output((tsf *)contextTSFOPL3, TSF_STEREO_INTERLEAVED, sampleRate); // set the SoundFont rendering output mode
    }

    return QB_TRUE;
}

/// @brief Check what kind of MIDI renderer is being used
/// @return Return QB64 TRUE if using FM synthesis. Sample synthesis otherwise
qb_bool MIDI_IsFMSynthesis()
{
    return contextTSFOPL3 ? isOPL3Active : QB_FALSE;
}

/// @brief This is used to render the MIDI audio when sample synthesis is in use
/// @param buffer The buffer when the audio should be rendered
/// @param bufferSize The size of the buffer in BYTES!
static void __MIDI_RenderTSF(uint8_t *buffer, uint32_t bufferSize)
{
    // Number of samples to process
    uint32_t sampleBlock, sampleCount = (bufferSize / (2 * sizeof(float))); // 2 channels, 32-bit FP (4 bytes) samples

    for (sampleBlock = TSF_RENDER_EFFECTSAMPLEBLOCK; sampleCount; sampleCount -= sampleBlock, buffer += (sampleBlock * (2 * sizeof(float))))
    {
        // We progress the MIDI playback and then process TSF_RENDER_EFFECTSAMPLEBLOCK samples at once
        if (sampleBlock > sampleCount)
            sampleBlock = sampleCount;

        // Loop through all MIDI messages which need to be played up until the current playback time
        for (currentMsec += sampleBlock * (1000.0 / sampleRate); tinyMIDIMessage && currentMsec >= tinyMIDIMessage->time; tinyMIDIMessage = tinyMIDIMessage->next)
        {
            switch (tinyMIDIMessage->type)
            {
            case TML_PROGRAM_CHANGE: // Channel program (preset) change (special handling for 10th MIDI channel with drums)
                tsf_channel_set_presetnumber((tsf *)contextTSFOPL3, tinyMIDIMessage->channel, tinyMIDIMessage->program, (tinyMIDIMessage->channel == 9));
                tsf_channel_midi_control((tsf *)contextTSFOPL3, tinyMIDIMessage->channel, TML_ALL_NOTES_OFF, 0); // https://github.com/schellingb/TinySoundFont/issues/59
                break;
            case TML_NOTE_ON: // Play a note
                tsf_channel_note_on((tsf *)contextTSFOPL3, tinyMIDIMessage->channel, tinyMIDIMessage->key, tinyMIDIMessage->velocity / 127.0f);
                break;
            case TML_NOTE_OFF: // Stop a note
                tsf_channel_note_off((tsf *)contextTSFOPL3, tinyMIDIMessage->channel, tinyMIDIMessage->key);
                break;
            case TML_PITCH_BEND: // Pitch wheel modification
                tsf_channel_set_pitchwheel((tsf *)contextTSFOPL3, tinyMIDIMessage->channel, tinyMIDIMessage->pitch_bend);
                break;
            case TML_CONTROL_CHANGE: // MIDI controller messages
                tsf_channel_midi_control((tsf *)contextTSFOPL3, tinyMIDIMessage->channel, tinyMIDIMessage->control, tinyMIDIMessage->control_value);
                break;
            }
        }

        // Render the block of audio samples in float format
        tsf_render_float((tsf *)contextTSFOPL3, (float *)buffer, sampleBlock, 0);

        // Reset the MIDI message pointer if we are looping & have reached the end of the message list
        if (isLooping && !tinyMIDIMessage)
        {
            tinyMIDIMessage = tinyMIDILoader;
            currentMsec = 0;
        }
    }
}

/// @brief This is used to render the MIDI audio when FM synthesis is in use
/// @param buffer The buffer when the audio should be rendered
/// @param bufferSize The size of the buffer in BYTES!
static void __MIDI_RenderOPL(uint8_t *buffer, uint32_t bufferSize)
{
    // Number of samples to process
    uint32_t sampleBlock, sampleCount = (bufferSize / (2 * sizeof(float))); // 2 channels, 32-bit FP (4 bytes) samples

    for (sampleBlock = TSF_RENDER_EFFECTSAMPLEBLOCK; sampleCount; sampleCount -= sampleBlock, buffer += (sampleBlock * (2 * sizeof(float))))
    {
        // We progress the MIDI playback and then process TSF_RENDER_EFFECTSAMPLEBLOCK samples at once
        if (sampleBlock > sampleCount)
            sampleBlock = sampleCount;

        // Loop through all MIDI messages which need to be played up until the current playback time
        for (currentMsec += sampleBlock * (1000.0 / sampleRate); tinyMIDIMessage && currentMsec >= tinyMIDIMessage->time; tinyMIDIMessage = tinyMIDIMessage->next)
        {
            switch (tinyMIDIMessage->type)
            {
            case TML_PROGRAM_CHANGE: // Channel program (preset) change
                reinterpret_cast<OPLPlayer *>(contextTSFOPL3)->midiProgramChange(tinyMIDIMessage->channel, tinyMIDIMessage->program);
                break;
            case TML_NOTE_ON: // Play a note
                reinterpret_cast<OPLPlayer *>(contextTSFOPL3)->midiNoteOn(tinyMIDIMessage->channel, tinyMIDIMessage->key, tinyMIDIMessage->velocity);
                break;
            case TML_NOTE_OFF: // Stop a note
                reinterpret_cast<OPLPlayer *>(contextTSFOPL3)->midiNoteOff(tinyMIDIMessage->channel, tinyMIDIMessage->key);
                break;
            case TML_PITCH_BEND: // Pitch wheel modification
                reinterpret_cast<OPLPlayer *>(contextTSFOPL3)->midiPitchControl(tinyMIDIMessage->channel, ((double)tinyMIDIMessage->pitch_bend / 8192.0) - 1.0);
                break;
            case TML_CONTROL_CHANGE: // MIDI controller messages
                reinterpret_cast<OPLPlayer *>(contextTSFOPL3)->midiControlChange(tinyMIDIMessage->channel, tinyMIDIMessage->control, tinyMIDIMessage->control_value);
                break;
            }
        }

        // Render the block of audio samples in float format
        reinterpret_cast<OPLPlayer *>(contextTSFOPL3)->generate((float *)buffer, sampleBlock);

        // Reset the MIDI message pointer if we are looping & have reached the end of the message list
        if (isLooping && !tinyMIDIMessage)
        {
            tinyMIDIMessage = tinyMIDILoader;
            currentMsec = 0;
        }
    }
}

/// @brief The calls the correct render function based on which renderer was chosen
/// @param buffer The buffer when the audio should be rendered
/// @param bufferSize The size of the buffer in BYTES!
void __MIDI_Render(uint8_t *buffer, uint32_t bufferSize)
{
    if (isOPL3Active)
        __MIDI_RenderOPL(buffer, bufferSize);
    else
        __MIDI_RenderTSF(buffer, bufferSize);
}

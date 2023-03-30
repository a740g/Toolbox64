//-----------------------------------------------------------------------------------------------------
// QB64 MIDI Player Library
// Copyright (c) 2023 Samuel Gomes
//
// This uses:
// TinySoundFont from https://github.com/schellingb/TinySoundFont/blob/master/tsf.h
// TinyMidiLoader from https://github.com/schellingb/TinySoundFont/blob/master/tml.h
// opl.h from https://github.com/mattiasgustavsson/libs/blob/main/opl.h
// stb_vorbis.c from https://github.com/nothings/stb/blob/master/stb_vorbis.c
//-----------------------------------------------------------------------------------------------------

#pragma once

#include <stdint.h>
#define STB_VORBIS_HEADER_ONLY
#include "stb_vorbis.c"
#define OPL_IMPLEMENTATION
#include "opl.h"
#define TSF_IMPLEMENTATION
#include "tsf.h"
#define TML_IMPLEMENTATION
#include "tml.h"
#include "soundfont.h"
#undef STB_VORBIS_HEADER_ONLY

#define QB_FALSE TSF_FALSE
#define QB_TRUE -TSF_TRUE

#define OPL_DEFAULT_SAMPLE_RATE 44100.0

static void *contextTSFOPL3 = nullptr;         // TSF / OPL3 context
static tml_message *tinyMIDILoader = nullptr;  // TML context
static tml_message *tinyMIDIMessage = nullptr; // next message to be played (this is set to NULL once the song is over)
static uint32_t totalMsec = 0;                 // total duration of the MIDI song
static double currentMsec = 0;                 // current playback time
static uint32_t sampleRate = 0;                // the mixing sample rate (should be same as SndRate in QB64)
static float globalVolume = 1.0f;              // this is the global volume (0.0 - 1.0)
static int32_t isLooping = QB_FALSE;           // flag to indicate if we should loop a song
static int32_t isOPL3Active = QB_FALSE;        // flag to indicate if we are using TSF or OPL3
static int16_t *bufferOPL = nullptr;           // this buffer will be used to render 16-bit 44100 samples from the OPL

/// @brief Check if MIDI library is initialized
/// @return Returns QB64 TRUE if it is initialized
int32_t MIDI_IsInitialized()
{
    return contextTSFOPL3 ? QB_TRUE : QB_FALSE;
}

/// @brief Checks if a MIDI file is loaded into memory
/// @return Returns QB64 TRUE if a MIDI tune is loaded
int32_t MIDI_IsTuneLoaded()
{
    return contextTSFOPL3 && tinyMIDILoader ? QB_TRUE : QB_FALSE;
}

/// @brief Check if a MIDI file is playing
/// @return Returns QB64 TRUE if we are playing a MIDI file
int32_t MIDI_IsPlaying()
{
    return contextTSFOPL3 && tinyMIDIMessage ? QB_TRUE : QB_FALSE;
}

/// @brief Checks the MIDI file is set to loop
/// @return Returns QB64 TRUE if a file is set to loop
int32_t MIDI_IsLooping()
{
    return contextTSFOPL3 && tinyMIDIMessage ? isLooping : QB_FALSE;
}

/// @brief Sets the MIDI to until unit it is stopped
/// @param looping QB64 TRUE or FALSE
void MIDI_SetLooping(const int32_t looping)
{
    if (contextTSFOPL3 && tinyMIDILoader)
        isLooping = looping; // Save the looping flag
}

/// @brief Sets the playback volume when a file is loaded
/// @param volume 0.0 = none, 1.0 = full
void MIDI_SetVolume(const float volume)
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
    return contextTSFOPL3 && tinyMIDIMessage ? (isOPL3Active ? voicescount : tsf_active_voice_count((tsf *)contextTSFOPL3)) : 0;
}

/// @brief Kickstarts playback if library is initalized and MIDI file is loaded
void MIDI_StartPlayer()
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
void MIDI_StopPlayer()
{
    if (contextTSFOPL3 && tinyMIDILoader)
    {
        if (isOPL3Active)
            opl_clear((opl_t *)contextTSFOPL3); // stop playing whatever is playing
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
int32_t __MIDI_LoadTuneFromFile(const char *midi_filename)
{
    if (MIDI_IsTuneLoaded())
        MIDI_StopPlayer(); // stop if anything is playing

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
int32_t __MIDI_LoadTuneFromMemory(const void *buffer, const uint32_t bufferSize)
{
    if (MIDI_IsTuneLoaded())
        MIDI_StopPlayer(); // stop if anything is playing

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
        MIDI_StopPlayer(); // stop if anything is playing

    // Free TSF/OPL resources if initialized
    if (contextTSFOPL3)
    {
        if (isOPL3Active)
            opl_destroy((opl_t *)contextTSFOPL3);
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
int32_t __MIDI_Initialize(const uint32_t sampleRateQB64, const int32_t useOPL3)
{
    // Return success if we are already initialized
    if (contextTSFOPL3)
        return QB_TRUE;

    if (useOPL3)
    {
        contextTSFOPL3 = opl_create(); // use OPL3 FM synth
        if (!contextTSFOPL3)
            return QB_FALSE;
    }
    else
    {

        contextTSFOPL3 = tsf_load_filename("soundfont.sf3"); // attempt to load a SF3 SoundFont from a file
        if (!contextTSFOPL3)
        {
            contextTSFOPL3 = tsf_load_filename("soundfont.sf2"); // attempt to load a SF2 SoundFont from a file
            if (!contextTSFOPL3)
            {
                contextTSFOPL3 = tsf_load_memory(soundfont_sf3, sizeof(soundfont_sf3)); // attempt to load the soundfont from memory
                if (!contextTSFOPL3)
                    return QB_FALSE; // return failue if loading from memory also failed. This should not happen though
            }
        }
    }

    isOPL3Active = useOPL3;      // same the type of renderer
    sampleRate = sampleRateQB64; // save the sample rate. No checks are done. Bad stuff may happen if this is garbage

    if (!isOPL3Active)
    {
        tsf_channel_set_bank_preset((tsf *)contextTSFOPL3, 9, 128, 0);             // initialize preset on special 10th MIDI channel to use percussion sound bank (128) if available
        tsf_set_output((tsf *)contextTSFOPL3, TSF_STEREO_INTERLEAVED, sampleRate); // set the SoundFont rendering output mode
    }

    // OPL3 runs at a fixed 44100 Hz. So we need to do sample rate conversion if the device sample rate is something else

    return QB_TRUE;
}

/// @brief Check what kind of MIDI renderer is being used
/// @return Return QB64 TRUE if using FM synthesis. Sample synthesis otherwise
int32_t MIDI_IsFMSynthesis()
{
    return contextTSFOPL3 ? isOPL3Active : QB_FALSE;
}

/// @brief This is used to render the MIDI audio when sample synthesis is in use
/// @param buffer The buffer when the audio should be rendered
/// @param bufferSize The size of the buffer in BYTES!
static void __MIDI_RenderTSF(uint8_t *buffer, const uint32_t bufferSize)
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

/// @brief A simple and efficient audio converter & resampler. Set output to NULL to get the output buffer size in samples frames
/// @param input The input 16-bit integer sample frame buffer
/// @param output The output 32-bit floating point sample frame buffer
/// @param inSampleRate The input sample rate
/// @param outSampleRate The output sample rate
/// @param inputSize The number of samples frames in the input
/// @param channels The number of channels for both input and output
/// @return Returns the number of samples frames written to the output
static uint64_t __MIDI_ResampleAndConvertFP32(const int16_t *input, float *output, uint32_t inSampleRate, uint32_t outSampleRate, uint64_t inputSampleFrames, uint32_t channels)
{
    if (!input)
        return 0;

    auto outputSize = (uint64_t)(inputSampleFrames * (double)outSampleRate / (double)inSampleRate);
    outputSize -= outputSize % channels;

    if (!output)
        return outputSize;

    auto stepDist = ((double)inSampleRate / (double)outSampleRate);
    const uint64_t fixedFraction = (1LL << 32);
    const double normFixed = (1.0 / (1LL << 32));
    auto step = ((uint64_t)(stepDist * fixedFraction + 0.5));
    uint64_t curOffset = 0;
    float sampleFP1, sampleFP2;

    for (uint32_t i = 0; i < outputSize; i += 1)
    {
        for (uint32_t c = 0; c < channels; c += 1)
        {
            sampleFP1 = (float)input[c] / 32768.0f;
            sampleFP2 = (float)input[c + channels] / 32768.0f;
            *output++ = (float)(sampleFP1 + (sampleFP2 - sampleFP1) * ((double)(curOffset >> 32) + ((curOffset & (fixedFraction - 1)) * normFixed)));
        }
        curOffset += step;
        input += (curOffset >> 32) * channels;
        curOffset &= (fixedFraction - 1);
    }

    return outputSize;
}

/// @brief This is used to render the MIDI audio when FM synthesis is in use
/// @param buffer The buffer when the audio should be rendered
/// @param bufferSize The size of the buffer in BYTES!
static void __MIDI_RenderOPL(uint8_t *buffer, const uint32_t bufferSize)
{
    // The sample frame count we can render that can be fully copied to the buffer after converting and resampling
    uint64_t sourceSampleFrameCount = ceil(((double)bufferSize * OPL_DEFAULT_SAMPLE_RATE) / (2.0 * sizeof(float) * (double)sampleRate));

    // Re-allocate the buffer to render 16-bit samples
    auto tempBuffer = (uint8_t *)realloc(bufferOPL, sourceSampleFrameCount * sizeof(int16_t) * 2);
    if (!tempBuffer)
        return; // buffer allocation failed!

    bufferOPL = (int16_t *)tempBuffer; // save the pointer to the reallocated buffer

    // Number of samples to process
    uint32_t sampleBlock, frameCount = sourceSampleFrameCount;

    for (sampleBlock = TSF_RENDER_EFFECTSAMPLEBLOCK; frameCount; frameCount -= sampleBlock, tempBuffer += (sampleBlock * (2 * sizeof(int16_t))))
    {
        // We progress the MIDI playback and then process TSF_RENDER_EFFECTSAMPLEBLOCK samples at once
        if (sampleBlock > frameCount)
            sampleBlock = frameCount;

        // Loop through all MIDI messages which need to be played up until the current playback time
        for (currentMsec += sampleBlock * (1000.0 / OPL_DEFAULT_SAMPLE_RATE); tinyMIDIMessage && currentMsec >= tinyMIDIMessage->time; tinyMIDIMessage = tinyMIDIMessage->next)
        {
            switch (tinyMIDIMessage->type)
            {
            case TML_PROGRAM_CHANGE: // Channel program (preset) change
                opl_midi_changeprog((opl_t *)contextTSFOPL3, tinyMIDIMessage->channel, tinyMIDIMessage->program);
                break;
            case TML_NOTE_ON: // Play a note
                opl_midi_noteon((opl_t *)contextTSFOPL3, tinyMIDIMessage->channel, tinyMIDIMessage->key, tinyMIDIMessage->velocity);
                break;
            case TML_NOTE_OFF: // Stop a note
                opl_midi_noteoff((opl_t *)contextTSFOPL3, tinyMIDIMessage->channel, tinyMIDIMessage->key);
                break;
            case TML_PITCH_BEND: // Pitch wheel modification
                opl_midi_pitchwheel((opl_t *)contextTSFOPL3, tinyMIDIMessage->channel, (tinyMIDIMessage->pitch_bend - 8192) / 64);
                break;
            case TML_CONTROL_CHANGE: // MIDI controller messages
                opl_midi_controller((opl_t *)contextTSFOPL3, tinyMIDIMessage->channel, tinyMIDIMessage->control, tinyMIDIMessage->control_value);
                break;
            }
        }

        // Render the block of audio samples in int16 format
        opl_render((opl_t *)contextTSFOPL3, (int16_t *)tempBuffer, sampleBlock, globalVolume);

        // Reset the MIDI message pointer if we are looping & have reached the end of the message list
        if (isLooping && !tinyMIDIMessage)
        {
            tinyMIDIMessage = tinyMIDILoader;
            currentMsec = 0;
        }
    }

    // Convert and resample the buffer
    __MIDI_ResampleAndConvertFP32(bufferOPL, (float *)buffer, OPL_DEFAULT_SAMPLE_RATE, sampleRate, sourceSampleFrameCount, 2);
}

/// @brief The calls the correct render function based on which renderer was chosen
/// @param buffer The buffer when the audio should be rendered
/// @param bufferSize The size of the buffer in BYTES!
void __MIDI_Render(uint8_t *buffer, const uint32_t bufferSize)
{
    if (isOPL3Active)
        __MIDI_RenderOPL(buffer, bufferSize);
    else
        __MIDI_RenderTSF(buffer, bufferSize);
}

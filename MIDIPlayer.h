//-----------------------------------------------------------------------------------------------------
//
// QB64 MIDI Player Library
// Copyright (c) 2022 Samuel Gomes
//
// This uses TinySoundFont + TinyMidiLoader libraries from https://github.com/schellingb/TinySoundFont
// Soundfont (awe32rom.h) from https://github.com/mattiasgustavsson/dos-like
//
//-----------------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------------
// HEADER FILES
//-----------------------------------------------------------------------------------------------------
#include "awe32rom.h"
#define TSF_IMPLEMENTATION
#include "tsf.h"
#define TML_IMPLEMENTATION
#include "tml.h"
//-----------------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------------
// CONSTANTS
//-----------------------------------------------------------------------------------------------------
#define TSF_VOLUME_MAX 100
#define QB_FALSE TSF_FALSE
#define QB_TRUE -TSF_TRUE
//-----------------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------------
// GLOBAL VARIABLES
//-----------------------------------------------------------------------------------------------------
static tsf *g_TinySoundFont = TSF_NULL;          // TinySoundFont context
static tml_message *g_TinyMidiLoader = TSF_NULL; // TinyMidiLoader context
static unsigned int g_TotalMsec = 0;             // Total duration of the MIDI song
static double g_Msec = 0;                        // Current playback time
static tml_message *g_MidiMessage = TSF_NULL;    // Next message to be played (this is set to NULL once the song is over)
static int g_SampleRate = 0;                     // The mixing sample rate (should be same as SndRate in QB64)
static int g_Volume = TSF_VOLUME_MAX;            // This is the global volume (0 - 100)
static int g_Looping = QB_FALSE;                 // Flag to indicate if we should loop a song
//-----------------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------------
// PUBLIC LIBRARY FUNCTIONS
//-----------------------------------------------------------------------------------------------------
// Return true if TSF is initialized
// Returns QB64 friendly boolean values
int TSFIsInitialized() { return g_TinySoundFont ? QB_TRUE : QB_FALSE; }

// Return true if a MIDI file is loaded
// Returns QB64 friendly boolean values
int TSFIsFileLoaded() { return g_TinySoundFont && g_TinyMidiLoader ? QB_TRUE : QB_FALSE; }

// Returns true if we are playing a MIDI file
// Returns QB64 friendly boolean values
int TSFIsPlaying() { return g_TinySoundFont && g_MidiMessage ? QB_TRUE : QB_FALSE; }

// Returns true if a file is set to loop
// Returns QB64 friendly boolean values
// This will only work when the file is actually playing
int TSFGetIsLooping() { return g_Looping; }

// Simply sets the looping flag
void TSFSetIsLooping(int looping) {
    g_Looping = looping; // Save the looping flag
}

// Set the playback volume (0 = none, 100 = full)
// This will only work when a file is loaded
void TSFSetVolume(int volume) {
    if (g_TinySoundFont && g_TinyMidiLoader) {
        if (volume < 0) {
            g_Volume = 0;
        } else if (volume > 100) {
            g_Volume = 100;
        } else {
            g_Volume = volume;
        }

        tsf_set_volume(g_TinySoundFont, (float)g_Volume / TSF_VOLUME_MAX);
    }
}

// Return the current playback volume (0 = none, 100 = full)
// This will only work when a file is loaded
int TSFGetVolume() { return g_Volume; }

// Return the total song time in msec
// This will only work when a file is loaded
double TSFGetTotalTime() { return g_TinySoundFont && g_TinyMidiLoader ? g_TotalMsec : 0; }

// Return the current playback time in msec
// This will only work when a file is loaded
double TSFGetCurrentTime() { return g_TinySoundFont && g_TinyMidiLoader ? g_Msec : 0; }

// Returns the total number of voice that are playing
// This will only work when the file is actually playing
int TSFGetActiveVoices() { return g_TinySoundFont && g_MidiMessage ? tsf_active_voice_count(g_TinySoundFont) : 0; }

// This will kickstart playback if TSF is initalized and MIDI file is loaded
// Return true if it succeeded
void TSFStartPlayer() {
    if (g_TinySoundFont && g_TinyMidiLoader) {
        g_MidiMessage = g_TinyMidiLoader; // Set up the global MidiMessage pointer to the first MIDI message
        g_Msec = 0;                       // Reset playback time
    }
}

// Stops playback and unloads the MIDI file from memory
void TSFStopPlayer() {
    if (g_TinySoundFont && g_TinyMidiLoader) {
        tsf_reset(g_TinySoundFont);                  // Stop playing whatever is playing
        tml_free(g_TinyMidiLoader);                  // Free TML resources
        g_TinyMidiLoader = g_MidiMessage = TSF_NULL; // Reset globals
        g_Msec = g_TotalMsec = 0;                    // Reset times
    }
}

// This loads a MIDI file into memory for playback
// This is also stop any MIDI playback and frees resources (if one is loaded)
int __TSFLoadFile(char *midi_filename) {
    if (TSFIsFileLoaded())
        TSFStopPlayer(); // Stop if anything is playing

    if (g_TinySoundFont) {
        g_TinyMidiLoader = tml_load_filename(midi_filename);
        if (!g_TinyMidiLoader)
            return QB_FALSE;

        // Get the total duration of the song ignoring the rest of the stuff
        tml_get_info(g_TinyMidiLoader, NULL, NULL, NULL, NULL, &g_TotalMsec);

        return QB_TRUE;
    }

    return QB_FALSE;
}

// Shutdown TSF
// This is also stop any MIDI playback and frees resources (if one is loaded)
// This must not be called directly by the end user
void __TSFFinalize() {
    if (TSFIsFileLoaded())
        TSFStopPlayer(); // Stop if anything is playing

    // Free TSF resources if initialized
    if (g_TinySoundFont) {
        tsf_close(g_TinySoundFont);
        g_TinySoundFont = TSF_NULL;
    }
}

// This initializes TSF
// Returns -1 if everything went well or zero otherwise
// This must not be called directly by the end user
int __TSFInitialize(int sample_rate) {
    // Return success if we are already initialized
    if (g_TinySoundFont)
        return QB_TRUE;

    // Attempt to load a SoundFont from a file
    g_TinySoundFont = tsf_load_filename("soundfont.sf2");

    if (!g_TinySoundFont) {
        // Attempt to load the soundfont from memory
        g_TinySoundFont = tsf_load_memory(awe32rom, sizeof(awe32rom));

        // Return failue if loading from memory also failed. This should not happen though
        if (!g_TinySoundFont)
            return QB_FALSE;
    }

    // Save the sample rate
    // No checks are done. Bad stuff may happen if this is garbage
    g_SampleRate = sample_rate;

    // Initialize preset on special 10th MIDI channel to use percussion sound bank (128) if available
    tsf_channel_set_bank_preset(g_TinySoundFont, 9, 128, 0);

    // Set the SoundFont rendering output mode
    tsf_set_output(g_TinySoundFont, TSF_STEREO_INTERLEAVED, g_SampleRate);

    return QB_TRUE;
}

// This is used on the QB64 side to render the actual samples for playback
void __TSFRender(char *buffer, int size) {
    // Number of samples to process
    int SampleBlock, SampleCount = (size / (2 * sizeof(float))); // 2 channels, 32-bit FP (4 bytes) samples

    for (SampleBlock = TSF_RENDER_EFFECTSAMPLEBLOCK; SampleCount; SampleCount -= SampleBlock, buffer += (SampleBlock * (2 * sizeof(float)))) {
        // We progress the MIDI playback and then process TSF_RENDER_EFFECTSAMPLEBLOCK samples at once
        if (SampleBlock > SampleCount)
            SampleBlock = SampleCount;

        // Loop through all MIDI messages which need to be played up until the current playback time
        for (g_Msec += SampleBlock * (1000.0 / g_SampleRate); g_MidiMessage && g_Msec >= g_MidiMessage->time; g_MidiMessage = g_MidiMessage->next) {
            switch (g_MidiMessage->type) {
            case TML_PROGRAM_CHANGE: // Channel program (preset) change (special handling for 10th MIDI channel with drums)
                tsf_channel_set_presetnumber(g_TinySoundFont, g_MidiMessage->channel, g_MidiMessage->program, (g_MidiMessage->channel == 9));
                tsf_channel_midi_control(g_TinySoundFont, g_MidiMessage->channel, TML_ALL_NOTES_OFF,
                                         0); // https://github.com/schellingb/TinySoundFont/issues/59
                break;
            case TML_NOTE_ON: // Play a note
                tsf_channel_note_on(g_TinySoundFont, g_MidiMessage->channel, g_MidiMessage->key, g_MidiMessage->velocity / 127.0f);
                break;
            case TML_NOTE_OFF: // Stop a note
                tsf_channel_note_off(g_TinySoundFont, g_MidiMessage->channel, g_MidiMessage->key);
                break;
            case TML_PITCH_BEND: // Pitch wheel modification
                tsf_channel_set_pitchwheel(g_TinySoundFont, g_MidiMessage->channel, g_MidiMessage->pitch_bend);
                break;
            case TML_CONTROL_CHANGE: // MIDI controller messages
                tsf_channel_midi_control(g_TinySoundFont, g_MidiMessage->channel, g_MidiMessage->control, g_MidiMessage->control_value);
                break;
            }
        }

        // Render the block of audio samples in float format
        tsf_render_float(g_TinySoundFont, (float *)buffer, SampleBlock, 0);

        // Reset the MIDI message pointer if we are looping & have reached the end of the message list
        if (g_Looping && !g_MidiMessage) {
            g_MidiMessage = g_TinyMidiLoader;
            g_Msec = 0;
        }
    }
}
//-----------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------

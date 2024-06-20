'-----------------------------------------------------------------------------------------------------------------------
' MIDI Player Library
' Copyright (c) 2024 Samuel Gomes
'
' This uses:
' foo_midi (heavily modified) from https://github.com/stuerp/foo_midi (MIT license)
' Opal (refactored) from https://www.3eality.com/productions/reality-adlib-tracker (Public Domain)
' primesynth (heavily modified) from https://github.com/mosmeh/primesynth (MIT license)
' stb_vorbis.c from https://github.com/nothings/stb (Public Domain)
' TinySoundFont from https://github.com/schellingb/TinySoundFont (MIT license)
' ymfmidi (heavily modified) from https://github.com/devinacker/ymfmidi (BSD-3-Clause license)
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'
'$INCLUDE:'Types.bi'
'$INCLUDE:'MathOps.bi'
'$INCLUDE:'FileOps.bi'
'$INCLUDE:'PointerOps.bi'

CONST __MIDI_SOUND_BUFFER_CHANNELS& = 2& ' 2 channels (stereo)
CONST __MIDI_SOUND_BUFFER_SAMPLE_SIZE& = 4& ' 4 bytes (32-bits floating point)
CONST __MIDI_SOUND_BUFFER_FRAME_SIZE& = __MIDI_SOUND_BUFFER_SAMPLE_SIZE * __MIDI_SOUND_BUFFER_CHANNELS
CONST __MIDI_SOUND_BUFFER_CHUNKS = 2 ' chunks per buffer (should be power of 2)
CONST MIDI_SOUND_BUFFER_TIME_DEFAULT! = 0.08! ' we will check that we have this amount of time left in the QB64 sound pipe
CONST MIDI_VOLUME_MAX! = 1! ' max volume
CONST MIDI_VOLUME_MIN! = 0! ' min volume
' Various synth types
CONST MIDI_SYNTH_OPAL& = 0&
CONST MIDI_SYNTH_PRIMESYNTH& = 1&
CONST MIDI_SYNTH_TINYSOUNDFONT& = 2&
$IF WINDOWS THEN
    CONST MIDI_SYNTH_VSTI& = 3&
$END IF

' QB64 specific stuff
TYPE __MIDI_PlayerType
    isPaused AS _BYTE ' set to true if tune is paused
    soundBufferFrames AS _UNSIGNED LONG ' size of the render buffer in frames
    soundBufferSamples AS _UNSIGNED LONG ' size of the rendered buffer in samples
    soundBufferBytes AS _UNSIGNED LONG ' size of the render buffer in bytes
    soundBufferTime AS SINGLE ' the amount of time (seconds) our buffer really plays
    soundHandle AS LONG ' the sound pipe that we wll use to play the rendered samples
    globalVolume AS SINGLE ' this is the global volume (0.0 - 1.0)
END TYPE

' Anything with a '__' prefix is not supposed to be called directly
' There are QB64 wrappers for these functions
DECLARE LIBRARY "MIDIPlayer"
    FUNCTION __MIDI_LoadTuneFromMemory%% (buffer AS STRING, BYVAL size AS _UNSIGNED LONG, BYVAL sampleRate AS _UNSIGNED LONG)
    SUB MIDI_Play
    SUB MIDI_Stop
    FUNCTION MIDI_IsPlaying%%
    SUB MIDI_Loop (BYVAL isLooping AS _BYTE)
    FUNCTION MIDI_IsLooping%%
    FUNCTION MIDI_GetTotalTime~&
    FUNCTION MIDI_GetCurrentTime~&
    FUNCTION MIDI_GetActiveVoices~&
    FUNCTION MIDI_GetSynthType~&
    SUB __MIDI_SetSynth (fileNameOrBuffer AS STRING, BYVAL bufferSize AS _UNSIGNED _OFFSET, BYVAL synthType AS _UNSIGNED LONG)
    FUNCTION MIDI_GetSongName$
    SUB __MIDI_Render (buffer AS SINGLE, BYVAL size AS _UNSIGNED LONG)
END DECLARE

DIM __MIDI_Player AS __MIDI_PlayerType ' this is used to track the library state as such
REDIM __MIDI_SoundBuffer(0 TO 0) AS SINGLE ' this is the buffer that holds the rendered samples from the library

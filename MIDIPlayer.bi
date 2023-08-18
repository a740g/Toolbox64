'-----------------------------------------------------------------------------------------------------------------------
' MIDI Player Library
' Copyright (c) 2023 Samuel Gomes
'
' This uses:
' TinySoundFont from https://github.com/schellingb/TinySoundFont/blob/master/tsf.h
' TinyMidiLoader from https://github.com/schellingb/TinySoundFont/blob/master/tml.h
' ymfm from https://github.com/aaronsgiles/ymfm
' ymfmidi from https://github.com/devinacker/ymfmidi
' stb_vorbis.c from https://github.com/nothings/stb/blob/master/stb_vorbis.c
'-----------------------------------------------------------------------------------------------------------------------

$IF MIDIPLAYER_BI = UNDEFINED THEN
    $LET MIDIPLAYER_BI = TRUE

    '$INCLUDE:'Common.bi'
    '$INCLUDE:'Types.bi'
    '$INCLUDE:'MathOps.bi'
    '$INCLUDE:'FileOps.bi'
    '$INCLUDE:'PointerOps.bi'

    CONST __MIDI_SOUND_BUFFER_CHANNELS = 2 ' 2 channels (stereo)
    CONST __MIDI_SOUND_BUFFER_SAMPLE_SIZE = 4 ' 4 bytes (32-bits floating point)
    CONST __MIDI_SOUND_BUFFER_FRAME_SIZE = __MIDI_SOUND_BUFFER_SAMPLE_SIZE * __MIDI_SOUND_BUFFER_CHANNELS
    CONST MIDI_SOUND_BUFFER_TIME_DEFAULT = 0.2 ' we will check that we have this amount of time left in the QB64 sound pipe
    CONST MIDI_VOLUME_MAX = 1! ' max volume
    CONST MIDI_VOLUME_MIN = 0! ' min volume

    ' QB64 specific stuff
    TYPE __MIDI_PlayerType
        isPaused AS _BYTE ' set to true if tune is paused
        soundBufferFrames AS _UNSIGNED LONG ' size of the render buffer in frames
        soundBufferSamples AS _UNSIGNED LONG ' size of the rendered buffer in samples
        soundBufferBytes AS _UNSIGNED LONG ' size of the render buffer in bytes
        soundHandle AS LONG ' the sound pipe that we wll use to play the rendered samples
    END TYPE

    ' Anything with a '__' prefix is not supposed to be called directly
    ' There are QB64 wrappers for these functions
    DECLARE LIBRARY "MIDIPlayer"
        FUNCTION __MIDI_Initialize%% (BYVAL sampleRate AS _UNSIGNED LONG, BYVAL useOPL3 AS _BYTE)
        FUNCTION MIDI_IsInitialized%%
        SUB __MIDI_Finalize
        FUNCTION __MIDI_LoadTuneFromMemory%% (buffer AS STRING, BYVAL size AS _UNSIGNED LONG)
        FUNCTION MIDI_IsTuneLoaded%%
        SUB MIDI_Play
        SUB MIDI_Stop
        FUNCTION MIDI_IsPlaying%%
        SUB MIDI_Loop (BYVAL isLooping AS _BYTE)
        FUNCTION MIDI_IsLooping%%
        FUNCTION MIDI_GetVolume!
        SUB MIDI_SetVolume (BYVAL volume AS SINGLE)
        FUNCTION MIDI_GetTotalTime#
        FUNCTION MIDI_GetCurrentTime#
        FUNCTION MIDI_GetActiveVoices~&
        FUNCTION MIDI_IsFMSynthesis%%
        SUB __MIDI_Render (buffer AS SINGLE, BYVAL size AS _UNSIGNED LONG)
    END DECLARE

    DIM __MIDI_Player AS __MIDI_PlayerType ' this is used to track the library state as such
    REDIM __MIDI_SoundBuffer(0 TO 0) AS SINGLE ' this is the buffer that holds the rendered samples from the library

$END IF

'-----------------------------------------------------------------------------------------------------------------------
' OPL3 emulation for QB64-PE using ymfm (https://github.com/aaronsgiles/ymfm)
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF OPL3_BI = UNDEFINED THEN
    $LET OPL3_BI = TRUE

    '$INCLUDE:'Common.bi'
    '$INCLUDE:'Types.bi'
    '$INCLUDE:'MathOps.bi'
    '$INCLUDE:'PointerOps.bi'

    CONST __OPL3_SOUND_BUFFER_CHANNELS = 2 ' 2 channels (stereo)
    CONST __OPL3_SOUND_BUFFER_SAMPLE_SIZE = 4 ' 4 bytes (32-bits floating point)
    CONST __OPL3_SOUND_BUFFER_FRAME_SIZE = __OPL3_SOUND_BUFFER_SAMPLE_SIZE * __OPL3_SOUND_BUFFER_CHANNELS
    CONST OPL3_SOUND_BUFFER_TIME_DEFAULT = 0.2 ' we will check that we have this amount of time left in the QB64 sound pipe

    ' QB64 specific stuff
    TYPE __OPL3Type
        soundBufferFrames AS _UNSIGNED LONG ' size of the render buffer in frames
        soundBufferSamples AS _UNSIGNED LONG ' size of the rendered buffer in samples
        soundBufferBytes AS _UNSIGNED LONG ' size of the render buffer in bytes
        soundHandle AS LONG ' the sound pipe that we wll use to play the rendered samples
    END TYPE

    DECLARE LIBRARY "OPL3"
        FUNCTION __OPL3_Initialize%% (BYVAL sampleRate AS _UNSIGNED LONG)
        SUB __OPL3_Finalize
        FUNCTION OPL3_IsInitialized%%
        SUB OPL3_Reset
        SUB OPL3_SetGain (BYVAL gain AS SINGLE)
        SUB OPL3_WriteRegister (BYVAL address AS _UNSIGNED INTEGER, BYVAL value AS _UNSIGNED _BYTE)
        SUB __OPL3_GenerateSamples (buffer AS SINGLE, BYVAL frames AS _UNSIGNED LONG)
    END DECLARE

    DIM __OPL3 AS __OPL3Type ' this is used to track the library state as such
    REDIM __OPL3_SoundBuffer(0 TO 0) AS SINGLE ' this is the buffer that holds the rendered samples from the library

$END IF

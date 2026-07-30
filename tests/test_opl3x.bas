$LET TOOLBOX64_STRICT = TRUE

'$INCLUDE:'../Core/Types.bi'
'$INCLUDE:'../Math/Math.bi'
'$INCLUDE:'../Audio/OPL3X.bi'

CONST OPL3_SOUND_BUFFER_CHANNELS = 2 ' 2 channels (stereo)
CONST OPL3_SOUND_BUFFER_SAMPLE_SIZE = 4 ' 4 bytes (32-bits floating point)
CONST OPL3_SOUND_BUFFER_FRAME_SIZE = OPL3_SOUND_BUFFER_SAMPLE_SIZE * OPL3_SOUND_BUFFER_CHANNELS
CONST OPL3_SOUND_BUFFER_TIME_DEFAULT = 0.2 ' we will check that we have this amount of time left in the QB64 sound pipe

' QB64 specific stuff
TYPE __OPL3Type
    emulator AS _UNSIGNED _OFFSET
    soundBufferFrames AS _UNSIGNED LONG ' size of the render buffer in frames
    soundBufferSamples AS _UNSIGNED LONG ' size of the rendered buffer in samples
    soundBufferBytes AS _UNSIGNED LONG ' size of the render buffer in bytes
    soundHandle AS LONG ' the sound pipe that we wll use to play the rendered samples
END TYPE

DIM __OPL3 AS __OPL3Type ' this is used to track the library state as such
REDIM __OPL3_SoundBuffer(0 TO 0) AS SINGLE ' this is the buffer that holds the rendered samples from the library

'-----------------------------------------------------------------------------------------------------------------------
' Test code for debugging the library
'-----------------------------------------------------------------------------------------------------------------------
IF OPL3_Initialize THEN
    OPL3X_WriteChipRegister __OPL3.emulator, 0, 1, 0
    OPL3X_WriteChipRegister __OPL3.emulator, 0, &H23, &H21
    OPL3X_WriteChipRegister __OPL3.emulator, 0, &H43, 0
    OPL3X_WriteChipRegister __OPL3.emulator, 0, &H63, &HFF
    OPL3X_WriteChipRegister __OPL3.emulator, 0, &H83, &H05
    OPL3X_WriteChipRegister __OPL3.emulator, 0, &H20, &H20
    OPL3X_WriteChipRegister __OPL3.emulator, 0, &H40, &H3F
    OPL3X_WriteChipRegister __OPL3.emulator, 0, &H60, &H44
    OPL3X_WriteChipRegister __OPL3.emulator, 0, &H80, &H5
    OPL3X_WriteChipRegister __OPL3.emulator, 0, &HA0, &H41
    OPL3X_WriteChipRegister __OPL3.emulator, 0, &HB0, &H32

    PRINT "Emulating"; OPL3X_GetChipCount(__OPL3.emulator); "OPL3 chip(s) @"; OPL3X_GetSampleRate(__OPL3.emulator); "Hz"

    PRINT "Playing sine wave @ 440Hz"

    DO
        OPL3_Update OPL3_SOUND_BUFFER_TIME_DEFAULT
        _LIMIT 60
    LOOP UNTIL _KEYHIT = 27

    PRINT "Key off"

    OPL3X_WriteChipRegister __OPL3.emulator, 0, &HB0, &H12
    OPL3_Update OPL3_SOUND_BUFFER_TIME_DEFAULT

    OPL3_Finalize
END IF

END
'-----------------------------------------------------------------------------------------------------------------------

FUNCTION OPL3_Initialize%%
    SHARED __OPL3 AS __OPL3Type
    SHARED __OPL3_SoundBuffer() AS SINGLE

    IF __OPL3.emulator <> NULL THEN
        OPL3_Initialize = _TRUE
        EXIT FUNCTION
    END IF

    __OPL3.soundHandle = _SNDOPENRAW ' allocate a sound pipe
    IF __OPL3.soundHandle < 1 THEN EXIT FUNCTION

    __OPL3.emulator = OPL3X_Create(1) ' we'll emulate a single OPL3 chip

    IF __OPL3.emulator = NULL THEN
        _SNDCLOSE __OPL3.soundHandle
        EXIT FUNCTION
    END IF

    ' Allocate a 40 ms mixer buffer and ensure we round down to power of 2
    ' Power of 2 above is required by most FFT functions
    __OPL3.soundBufferFrames = Math_RoundDownLongToPowerOf2(_SNDRATE * OPL3_SOUND_BUFFER_TIME_DEFAULT * OPL3_SOUND_BUFFER_TIME_DEFAULT) ' buffer frames
    __OPL3.soundBufferSamples = __OPL3.soundBufferFrames * OPL3_SOUND_BUFFER_CHANNELS ' buffer samples
    __OPL3.soundBufferBytes = __OPL3.soundBufferSamples * OPL3_SOUND_BUFFER_SAMPLE_SIZE ' buffer bytes
    REDIM __OPL3_SoundBuffer(0 TO __OPL3.soundBufferSamples - 1) AS SINGLE ' stereo interleaved buffer

    OPL3_Initialize = _TRUE
END FUNCTION


SUB OPL3_Finalize
    SHARED __OPL3 AS __OPL3Type

    IF __OPL3.emulator <> NULL THEN
        _SNDRAWDONE __OPL3.soundHandle ' submit whatever is remaining in the raw buffer for playback
        _SNDCLOSE __OPL3.soundHandle ' close and free the QB64 sound pipe
        OPL3X_Destroy __OPL3.emulator
        __OPL3.emulator = NULL
    END IF
END SUB


SUB OPL3_SetVolume (volume AS SINGLE)
    SHARED __OPL3 AS __OPL3Type

    IF __OPL3.emulator <> NULL THEN
        _SNDVOL __OPL3.soundHandle, volume
    END IF
END SUB


' This handles playback and keeps track of the render buffer
' You can call this as frequently as you want. The routine will simply exit if nothing is to be done
SUB OPL3_Update (bufferTimeSecs AS SINGLE)
    SHARED __OPL3 AS __OPL3Type
    SHARED __OPL3_SoundBuffer() AS SINGLE

    ' Only render more samples if song is playing, not paused and we do not have enough samples with the sound device
    IF _SNDRAWLEN(__OPL3.soundHandle) < bufferTimeSecs THEN
        ' Render some samples to the buffer
        OPL3X_GetFrames __OPL3.emulator, __OPL3_SoundBuffer(0), __OPL3.soundBufferFrames

        ' Push the samples to the sound pipe
        _SNDRAWBATCH __OPL3_SoundBuffer(), 2, __OPL3.soundHandle, __OPL3.soundBufferFrames
    END IF
END SUB

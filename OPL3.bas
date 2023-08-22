'-----------------------------------------------------------------------------------------------------------------------
' OPL3 emulation for QB64-PE using ymfm (https://github.com/aaronsgiles/ymfm)
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF OPL3_BAS = UNDEFINED THEN
    $LET OPL3_BAS = TRUE

    '$INCLUDE:'OPL3.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    'IF OPL3_Initialize THEN
    '    OPL3_WriteRegister 1, 0
    '    OPL3_WriteRegister &H23, &H21
    '    OPL3_WriteRegister &H43, 0
    '    OPL3_WriteRegister &H63, &HFF
    '    OPL3_WriteRegister &H83, &H05
    '    OPL3_WriteRegister &H20, &H20
    '    OPL3_WriteRegister &H40, &H3F
    '    OPL3_WriteRegister &H60, &H44
    '    OPL3_WriteRegister &H80, &H5
    '    OPL3_WriteRegister &HA0, &H41
    '    OPL3_WriteRegister &HB0, &H32

    '    PRINT "Playing sine wave @ 440Hz"

    '    DO
    '        OPL3_Update OPL3_SOUND_BUFFER_TIME_DEFAULT
    '        _LIMIT 60
    '    LOOP UNTIL _KEYHIT = 27

    '    PRINT "Key off"

    '    OPL3_WriteRegister &HB0, &H12
    '    OPL3_Update OPL3_SOUND_BUFFER_TIME_DEFAULT

    '    OPL3_Finalize
    'END IF

    'END
    '-------------------------------------------------------------------------------------------------------------------

    FUNCTION OPL3_Initialize%%
        SHARED __OPL3 AS __OPL3Type
        SHARED __OPL3_SoundBuffer() AS SINGLE

        IF OPL3_IsInitialized THEN
            OPL3_Initialize = TRUE
            EXIT FUNCTION
        END IF

        __OPL3.soundHandle = _SNDOPENRAW ' allocate a sound pipe
        IF __OPL3.soundHandle < 1 THEN EXIT FUNCTION

        IF NOT __OPL3_Initialize(_SNDRATE) THEN
            _SNDCLOSE __OPL3.soundHandle
            EXIT FUNCTION
        END IF

        ' Allocate a 40 ms mixer buffer and ensure we round down to power of 2
        ' Power of 2 above is required by most FFT functions
        __OPL3.soundBufferFrames = RoundLongDownToPowerOf2(_SNDRATE * OPL3_SOUND_BUFFER_TIME_DEFAULT * OPL3_SOUND_BUFFER_TIME_DEFAULT) ' buffer frames
        __OPL3.soundBufferSamples = __OPL3.soundBufferFrames * __OPL3_SOUND_BUFFER_CHANNELS ' buffer samples
        __OPL3.soundBufferBytes = __OPL3.soundBufferSamples * __OPL3_SOUND_BUFFER_SAMPLE_SIZE ' buffer bytes
        REDIM __OPL3_SoundBuffer(0 TO __OPL3.soundBufferSamples - 1) AS SINGLE ' stereo interleaved buffer

        OPL3_Initialize = TRUE
    END FUNCTION


    SUB OPL3_Finalize
        SHARED __OPL3 AS __OPL3Type

        IF OPL3_IsInitialized THEN
            _SNDRAWDONE __OPL3.soundHandle ' sumbit whatever is remaining in the raw buffer for playback
            _SNDCLOSE __OPL3.soundHandle ' close and free the QB64 sound pipe
            __OPL3_Finalize ' call the C side finalizer
        END IF
    END SUB


    ' This handles playback and keeps track of the render buffer
    ' You can call this as frequenctly as you want. The routine will simply exit if nothing is to be done
    SUB OPL3_Update (bufferTimeSecs AS SINGLE)
        $CHECKING:OFF
        SHARED __OPL3 AS __OPL3Type
        SHARED __OPL3_SoundBuffer() AS SINGLE

        ' Only render more samples if song is playing, not paused and we do not have enough samples with the sound device
        IF _SNDRAWLEN(__OPL3.soundHandle) < bufferTimeSecs THEN
            ' Clear the render buffer
            SetMemory _OFFSET(__OPL3_SoundBuffer(0)), NULL, __OPL3.soundBufferBytes

            ' Render some samples to the buffer
            __OPL3_GenerateSamples __OPL3_SoundBuffer(0), __OPL3.soundBufferFrames

            ' Push the samples to the sound pipe
            DIM i AS _UNSIGNED LONG
            DO WHILE i < __OPL3.soundBufferSamples
                _SNDRAW __OPL3_SoundBuffer(i), __OPL3_SoundBuffer(i + 1), __OPL3.soundHandle
                i = i + __OPL3_SOUND_BUFFER_CHANNELS
            LOOP
        END IF
        $CHECKING:ON
    END SUB

$END IF

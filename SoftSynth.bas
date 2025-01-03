'-----------------------------------------------------------------------------------------------------------------------
' Simple floatimg-point stereo PCM software synthesizer
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'SoftSynth.bi'

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'IF SoftSynth_Initialize THEN
'    SoftSynth_SetTotalVoices 4

'    DIM rawSound AS STRING: rawSound = LoadFile("../../../../Downloads/laser.8")

'    SoftSynth_ConvertU8ToS8 rawSound

'    SoftSynth_LoadSound 0, rawSound, SIZE_OF_BYTE, 1

'    SoftSynth_SetVoiceFrequency 1, 11025

'    DO
'        DIM k AS LONG: k = _KEYHIT

'        IF k = 32 THEN SoftSynth_PlayVoice 1, 0, 0, SOFTSYNTH_VOICE_PLAY_FORWARD, 0, SoftSynth_BytesToFrames(LEN(rawSound), SIZE_OF_BYTE, 1) - 1
'        IF k = 19200 THEN SoftSynth_SetVoiceBalance 1, SoftSynth_GetVoiceBalance(1) - 0.01!
'        IF k = 19712 THEN SoftSynth_SetVoiceBalance 1, SoftSynth_GetVoiceBalance(1) + 0.01!

'        IF SoftSynth_GetBufferedSoundTime < SOFTSYNTH_SOUND_BUFFER_TIME_DEFAULT THEN SoftSynth_Update 1024

'        LOCATE 10, 1
'        PRINT USING "Balance: ###.###"; SoftSynth_GetVoiceBalance(1)

'        _LIMIT 60
'    LOOP UNTIL k = 27

'    SoftSynth_Finalize
'END IF

'END

'FUNCTION LoadFile$ (path AS STRING)
'    IF _FILEEXISTS(path) THEN
'        DIM AS LONG fh: fh = FREEFILE
'        OPEN path FOR BINARY ACCESS READ AS fh
'        LoadFile = INPUT$(LOF(fh), fh)
'        CLOSE fh
'    END IF
'END FUNCTION
'-----------------------------------------------------------------------------------------------------------------------

' Initializes the softsynth and allocates all required resources
FUNCTION SoftSynth_Initialize%%
    SHARED __SoftSynth AS __SoftSynthType
    SHARED __SoftSynth_SoundBuffer() AS SINGLE

    ' Return true if we have already been initialized
    IF SoftSynth_IsInitialized THEN
        SoftSynth_Initialize = _TRUE
        EXIT FUNCTION
    END IF

    ' Allocate a QB64 sound pipe
    __SoftSynth.soundHandle = _SNDOPENRAW
    IF __SoftSynth.soundHandle < 1 THEN EXIT FUNCTION

    IF NOT __SoftSynth_Initialize(_SNDRATE) THEN
        _SNDCLOSE __SoftSynth.soundHandle
        EXIT FUNCTION
    END IF

    __SoftSynth.soundMasterVolume = SOFTSYNTH_MASTER_VOLUME_MAX ' QB64 sound pipe volunme is set to max by default

    ' Allocate a 40 ms mixer buffer and ensure we round down to power of 2
    ' Power of 2 sizes is required by most FFT functions
    __SoftSynth.soundBufferFrames = Math_RoundDownLongToPowerOf2(_SNDRATE * 0.04!) ' buffer frames
    __SoftSynth.soundBufferSamples = __SoftSynth.soundBufferFrames * SOFTSYNTH_SOUND_BUFFER_CHANNELS ' buffer samples
    __SoftSynth.soundBufferBytes = __SoftSynth.soundBufferSamples * SOFTSYNTH_SOUND_BUFFER_SAMPLE_SIZE ' buffer bytes
    REDIM __SoftSynth_SoundBuffer(0 TO __SoftSynth.soundBufferSamples - 1) AS SINGLE ' stereo interleaved buffer

    SoftSynth_Initialize = _TRUE
END FUNCTION


' Close the mixer - free all allocated resources
SUB SoftSynth_Finalize
    SHARED __SoftSynth AS __SoftSynthType

    IF SoftSynth_IsInitialized THEN
        _SNDRAWDONE __SoftSynth.soundHandle ' Sumbit whatever is remaining in the raw buffer for playback
        _SNDCLOSE __SoftSynth.soundHandle ' Close QB64 sound pipe
        __SoftSynth_Finalize ' call the C side finalizer
    END IF
END SUB


' This should be called by code using the mixer at regular intervals
SUB SoftSynth_Update (frames AS _UNSIGNED LONG)
    $CHECKING:OFF
    SHARED __SoftSynth AS __SoftSynthType
    SHARED __SoftSynth_SoundBuffer() AS SINGLE

    IF __SoftSynth.soundBufferFrames <> frames THEN
        ' Only resize the buffer is frames is different from what was last set
        __SoftSynth.soundBufferFrames = frames ' buffer frames
        __SoftSynth.soundBufferSamples = __SoftSynth.soundBufferFrames * SOFTSYNTH_SOUND_BUFFER_CHANNELS ' buffer samples
        __SoftSynth.soundBufferBytes = __SoftSynth.soundBufferSamples * SOFTSYNTH_SOUND_BUFFER_SAMPLE_SIZE ' buffer bytes
        REDIM __SoftSynth_SoundBuffer(0 TO __SoftSynth.soundBufferSamples - 1) AS SINGLE ' stereo interleaved buffer
    ELSE
        ' Else we'll just fill the buffer with zeros
        SetMemoryByte _OFFSET(__SoftSynth_SoundBuffer(0)), NULL, __SoftSynth.soundBufferBytes
    END IF

    ' Render some samples to the buffer
    __SoftSynth_Update __SoftSynth_SoundBuffer(0), frames

    ' Feed the samples to the QB64 sound pipe
    _SNDRAWBATCH __SoftSynth_SoundBuffer(), SOFTSYNTH_SOUND_BUFFER_CHANNELS, __SoftSynth.soundHandle
    $CHECKING:ON
END SUB


' Loads and prepares a raw sound from a string buffer
SUB SoftSynth_LoadSound (snd AS LONG, buffer AS STRING, bytesPerSample AS _UNSIGNED _BYTE, channels AS _UNSIGNED _BYTE)
    $CHECKING:OFF
    __SoftSynth_LoadSound snd, buffer, LEN(buffer), bytesPerSample, channels
    $CHECKING:ON
END SUB


' Returns the amount of buffered sample time remaining to be played
FUNCTION SoftSynth_GetBufferedSoundTime#
    $CHECKING:OFF
    SHARED __SoftSynth AS __SoftSynthType

    SoftSynth_GetBufferedSoundTime = _SNDRAWLEN(__SoftSynth.soundHandle)
    $CHECKING:ON
END FUNCTION


' Sets the master volume
SUB SoftSynth_SetMasterVolume (volume AS SINGLE)
    $CHECKING:OFF
    SHARED __SoftSynth AS __SoftSynthType

    __SoftSynth.soundMasterVolume = Math_ClampSingle(volume, 0!, SOFTSYNTH_MASTER_VOLUME_MAX)

    _SNDVOL __SoftSynth.soundHandle, __SoftSynth.soundMasterVolume
    $CHECKING:ON
END SUB


' Gets the master volume
FUNCTION SoftSynth_GetMasterVolume!
    $CHECKING:OFF
    SHARED __SoftSynth AS __SoftSynthType

    SoftSynth_GetMasterVolume = __SoftSynth.soundMasterVolume
    $CHECKING:ON
END FUNCTION

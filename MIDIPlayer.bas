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

$IF MIDIPLAYER_BAS = UNDEFINED THEN
    $LET MIDIPLAYER_BAS = TRUE

    '$INCLUDE:'MIDIPlayer.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    '$DEBUG
    '$CONSOLE
    'IF MIDI_Initialize(TRUE) THEN
    '    IF MIDI_LoadTuneFromFile(ENVIRON$("SYSTEMROOT") + "/Media/onestop.mid") THEN
    '        MIDI_Play
    '        MIDI_Loop TRUE
    '        DO
    '            MIDI_Update MIDI_SOUND_BUFFER_TIME_DEFAULT
    '            SELECT CASE _KEYHIT
    '                CASE 27
    '                    EXIT DO
    '                CASE 32
    '                    MIDI_Pause NOT MIDI_IsPaused
    '            END SELECT
    '            LOCATE , 1: PRINT USING "Time: ########.## / ########.##   Voices: ####"; MIDI_GetCurrentTime; MIDI_GetTotalTime; MIDI_GetActiveVoices;
    '            _LIMIT 60
    '        LOOP WHILE MIDI_IsPlaying
    '        MIDI_Stop
    '    END IF
    '    MIDI_Finalize
    'END IF
    'END
    '-------------------------------------------------------------------------------------------------------------------

    ' This basically allocate stuff on the QB64 side and initializes the underlying C library
    FUNCTION MIDI_Initialize%% (useOPL3 AS _BYTE)
        SHARED __MIDI_Player AS __MIDI_PlayerType
        SHARED __MIDI_SoundBuffer() AS SINGLE

        ' Exit if we are already initialized
        IF MIDI_IsInitialized THEN
            MIDI_Initialize = TRUE
            EXIT FUNCTION
        END IF

        __MIDI_Player.soundHandle = _SNDOPENRAW ' allocate a sound pipe
        IF __MIDI_Player.soundHandle < 1 THEN EXIT FUNCTION

        IF NOT __MIDI_Initialize(_SNDRATE, useOPL3) THEN
            _SNDCLOSE __MIDI_Player.soundHandle
            EXIT FUNCTION
        END IF

        ' Allocate a 40 ms mixer buffer and ensure we round down to power of 2
        ' Power of 2 above is required by most FFT functions
        __MIDI_Player.soundBufferFrames = RoundLongDownToPowerOf2(_SNDRATE * MIDI_SOUND_BUFFER_TIME_DEFAULT * MIDI_SOUND_BUFFER_TIME_DEFAULT) ' buffer frames
        __MIDI_Player.soundBufferSamples = __MIDI_Player.soundBufferFrames * __MIDI_SOUND_BUFFER_CHANNELS ' buffer samples
        __MIDI_Player.soundBufferBytes = __MIDI_Player.soundBufferSamples * __MIDI_SOUND_BUFFER_SAMPLE_SIZE ' buffer bytes
        REDIM __MIDI_SoundBuffer(0 TO __MIDI_Player.soundBufferSamples - 1) AS SINGLE ' stereo interleaved buffer

        MIDI_Initialize = TRUE
    END FUNCTION


    ' The closes the library and frees all resources
    SUB MIDI_Finalize
        SHARED __MIDI_Player AS __MIDI_PlayerType

        IF MIDI_IsInitialized THEN
            _SNDRAWDONE __MIDI_Player.soundHandle ' sumbit whatever is remaining in the raw buffer for playback
            _SNDCLOSE __MIDI_Player.soundHandle ' close and free the QB64 sound pipe
            __MIDI_Finalize ' call the C side finalizer
        END IF
    END SUB


    ' Loads a MIDI file for playback from file
    FUNCTION MIDI_LoadTuneFromFile%% (fileName AS STRING)
        MIDI_LoadTuneFromFile = MIDI_LoadTuneFromMemory(LoadFile(fileName))
    END FUNCTION


    ' Loads a MIDI file for playback from memory
    FUNCTION MIDI_LoadTuneFromMemory%% (buffer AS STRING)
        MIDI_LoadTuneFromMemory = __MIDI_LoadTuneFromMemory(buffer, LEN(buffer))
    END FUNCTION


    ' Pause any MIDI playback
    SUB MIDI_Pause (state AS _BYTE)
        SHARED __MIDI_Player AS __MIDI_PlayerType

        IF MIDI_IsTuneLoaded THEN
            __MIDI_Player.isPaused = state
        END IF
    END SUB


    ' Return true if playback is paused
    FUNCTION MIDI_IsPaused%%
        $CHECKING:OFF
        SHARED __MIDI_Player AS __MIDI_PlayerType

        IF MIDI_IsTuneLoaded THEN
            MIDI_IsPaused = __MIDI_Player.isPaused
        END IF
        $CHECKING:ON
    END FUNCTION


    ' This handles playback and keeps track of the render buffer
    ' You can call this as frequenctly as you want. The routine will simply exit if nothing is to be done
    SUB MIDI_Update (bufferTimeSecs AS SINGLE)
        $CHECKING:OFF
        SHARED __MIDI_Player AS __MIDI_PlayerType
        SHARED __MIDI_SoundBuffer() AS SINGLE

        ' Only render more samples if song is playing, not paused and we do not have enough samples with the sound device
        IF MIDI_IsPlaying AND NOT __MIDI_Player.isPaused AND _SNDRAWLEN(__MIDI_Player.soundHandle) < bufferTimeSecs THEN
            ' Clear the render buffer
            SetMemory _OFFSET(__MIDI_SoundBuffer(0)), NULL, __MIDI_Player.soundBufferBytes

            ' Render some samples to the buffer
            __MIDI_Render __MIDI_SoundBuffer(0), __MIDI_Player.soundBufferBytes

            ' Push the samples to the sound pipe
            DIM i AS _UNSIGNED LONG
            DO WHILE i < __MIDI_Player.soundBufferSamples
                _SNDRAW __MIDI_SoundBuffer(i), __MIDI_SoundBuffer(i + 1), __MIDI_Player.soundHandle
                i = i + __MIDI_SOUND_BUFFER_CHANNELS
            LOOP
        END IF
        $CHECKING:ON
    END SUB

    '$INCLUDE:'FileOps.bas'

$END IF

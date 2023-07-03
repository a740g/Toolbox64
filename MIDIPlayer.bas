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
    '-------------------------------------------------------------------------------------------------------------------
    ' HEADER FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'MIDIPlayer.bi'
    '-------------------------------------------------------------------------------------------------------------------

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

    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
    ' This basically allocate stuff on the QB64 side and initializes the underlying C library
    FUNCTION MIDI_Initialize%% (useOPL3 AS _BYTE)
        SHARED __MIDI_Player AS __MIDI_PlayerType

        ' Exit if we are already initialized
        IF MIDI_IsInitialized THEN
            MIDI_Initialize = TRUE
            EXIT FUNCTION
        END IF

        __MIDI_Player.soundBufferFrames = RoundDownToPowerOf2(_SNDRATE * MIDI_SOUND_BUFFER_TIME_DEFAULT * MIDI_SOUND_BUFFER_TIME_DEFAULT) ' 40 ms buffer round down to power of 2
        __MIDI_Player.soundBufferBytes = __MIDI_Player.soundBufferFrames * __MIDI_SOUND_BUFFER_FRAME_SIZE ' calculate the mixer buffer size
        __MIDI_Player.soundBuffer = _MEMNEW(__MIDI_Player.soundBufferBytes) ' allocate the mixer buffer

        IF __MIDI_Player.soundBuffer.SIZE = 0 THEN EXIT FUNCTION ' exit if memory was not allocated

        __MIDI_Player.soundHandle = _SNDOPENRAW ' allocate a sound pipe

        IF __MIDI_Player.soundHandle < 1 THEN
            _MEMFREE __MIDI_Player.soundBuffer
            EXIT FUNCTION
        END IF

        IF NOT __MIDI_Initialize(_SNDRATE, useOPL3) THEN
            _SNDCLOSE __MIDI_Player.soundHandle
            _MEMFREE __MIDI_Player.soundBuffer
            EXIT FUNCTION
        END IF

        MIDI_Initialize = TRUE
    END FUNCTION


    ' The closes the library and frees all resources
    SUB MIDI_Finalize
        SHARED __MIDI_Player AS __MIDI_PlayerType

        IF MIDI_IsInitialized THEN
            _SNDRAWDONE __MIDI_Player.soundHandle ' sumbit whatever is remaining in the raw buffer for playback
            _SNDCLOSE __MIDI_Player.soundHandle ' close and free the QB64 sound pipe
            _MEMFREE __MIDI_Player.soundBuffer ' free the mixer buffer
            __MIDI_Finalize ' call the C side finalizer
        END IF
    END SUB


    ' Loads a MIDI file for playback from file
    FUNCTION MIDI_LoadTuneFromFile%% (fileName AS STRING)
        MIDI_LoadTuneFromFile = __MIDI_LoadTuneFromFile(fileName + CHR$(NULL))
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
        SHARED __MIDI_Player AS __MIDI_PlayerType

        IF MIDI_IsTuneLoaded THEN
            MIDI_IsPaused = __MIDI_Player.isPaused
        END IF
    END FUNCTION


    ' This handles playback and keeps track of the render buffer
    ' You can call this as frequenctly as you want. The routine will simply exit if nothing is to be done
    SUB MIDI_Update (bufferTimeSecs AS SINGLE)
        SHARED __MIDI_Player AS __MIDI_PlayerType

        ' Only render more samples if song is playing, not paused and we do not have enough samples with the sound device
        IF MIDI_IsPlaying AND NOT __MIDI_Player.isPaused AND _SNDRAWLEN(__MIDI_Player.soundHandle) < bufferTimeSecs THEN
            ' Clear the render buffer
            _MEMFILL __MIDI_Player.soundBuffer, __MIDI_Player.soundBuffer.OFFSET, __MIDI_Player.soundBufferBytes, NULL AS _BYTE

            ' Render some samples to the buffer
            __MIDI_Render __MIDI_Player.soundBuffer.OFFSET, __MIDI_Player.soundBufferBytes

            ' Push the samples to the sound pipe
            DIM i AS _UNSIGNED LONG
            FOR i = 0 TO __MIDI_Player.soundBufferBytes - __MIDI_SOUND_BUFFER_SAMPLE_SIZE STEP __MIDI_SOUND_BUFFER_FRAME_SIZE
                _SNDRAW _MEMGET(__MIDI_Player.soundBuffer, __MIDI_Player.soundBuffer.OFFSET + i, SINGLE), _MEMGET(__MIDI_Player.soundBuffer, __MIDI_Player.soundBuffer.OFFSET + i + __MIDI_SOUND_BUFFER_SAMPLE_SIZE, SINGLE), __MIDI_Player.soundHandle
            NEXT
        END IF
    END SUB
    '-------------------------------------------------------------------------------------------------------------------
$END IF
'-----------------------------------------------------------------------------------------------------------------------

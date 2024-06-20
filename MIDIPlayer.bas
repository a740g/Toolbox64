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

'$INCLUDE:'MIDIPlayer.bi'

'-----------------------------------------------------------------------------------------------------------------------
' Small test code for debugging the library
'-----------------------------------------------------------------------------------------------------------------------
'$DEBUG
'$CONSOLE
'IF MIDI_Initialize(TRUE) THEN
'    IF MIDI_LoadTuneFromFile(ENVIRON$("SYSTEMROOT") + "/Media/onestop.mid") THEN
'        MIDI_Play
'        MIDI_Loop FALSE
'        PRINT "Playing "; MIDI_GetSongName
'        DO
'            MIDI_Update
'            SELECT CASE _KEYHIT
'                CASE 27
'                    EXIT DO
'                CASE 32
'                    MIDI_Pause NOT MIDI_IsPaused
'            END SELECT
'            LOCATE , 1: PRINT USING "Time: ########## / ##########   Voices: ####"; MIDI_GetCurrentTime; MIDI_GetTotalTime; MIDI_GetActiveVoices;
'            _LIMIT 60
'        LOOP WHILE MIDI_IsPlaying
'        MIDI_Stop
'    END IF
'    MIDI_Finalize
'END IF
'END
'-----------------------------------------------------------------------------------------------------------------------

' This basically allocate stuff on the QB64 side and initializes the underlying C library
FUNCTION MIDI_Initialize%% (useOPL3 AS _BYTE)
    SHARED __MIDI_Player AS __MIDI_PlayerType
    SHARED __MIDI_SoundBuffer() AS SINGLE

    ' Exit if we are already initialized
    IF __MIDI_Player.soundHandle > 0 THEN
        MIDI_Initialize = TRUE
        EXIT FUNCTION
    END IF

    __MIDI_Player.soundHandle = _SNDOPENRAW ' allocate a sound pipe
    IF __MIDI_Player.soundHandle < 1 THEN EXIT FUNCTION

    ' Power of 2 above is required by most FFT functions
    __MIDI_Player.soundBufferFrames = Math_RoundDownLongToPowerOf2(_SNDRATE * MIDI_SOUND_BUFFER_TIME_DEFAULT) \ Math_RoundDownLongToPowerOf2(__MIDI_SOUND_BUFFER_CHUNKS) ' buffer frames
    __MIDI_Player.soundBufferTime = (__MIDI_Player.soundBufferFrames * Math_RoundDownLongToPowerOf2(__MIDI_SOUND_BUFFER_CHUNKS)) / _SNDRATE ' this is how much time we are really buffering
    __MIDI_Player.soundBufferSamples = __MIDI_Player.soundBufferFrames * __MIDI_SOUND_BUFFER_CHANNELS ' buffer samples
    __MIDI_Player.soundBufferBytes = __MIDI_Player.soundBufferSamples * __MIDI_SOUND_BUFFER_SAMPLE_SIZE ' buffer bytes
    REDIM __MIDI_SoundBuffer(0 TO __MIDI_Player.soundBufferSamples - 1) AS SINGLE ' stereo interleaved buffer

    __MIDI_Player.globalVolume = 1!
    __MIDI_Player.useFM = useOPL3

    MIDI_Initialize = TRUE
END FUNCTION


' The closes the library and frees all resources
SUB MIDI_Finalize
    SHARED __MIDI_Player AS __MIDI_PlayerType

    IF __MIDI_Player.soundHandle > 0 THEN
        _SNDRAWDONE __MIDI_Player.soundHandle ' sumbit whatever is remaining in the raw buffer for playback
        _SNDCLOSE __MIDI_Player.soundHandle ' close and free the QB64 sound pipe
        __MIDI_Player.soundHandle = 0 ' reset sound handle
        MIDI_Stop ' close stuff on the C side finalizer
    END IF
END SUB


' Loads a MIDI file for playback from file
FUNCTION MIDI_LoadTuneFromFile%% (fileName AS STRING)
    MIDI_LoadTuneFromFile = MIDI_LoadTuneFromMemory(LoadFile(fileName))
END FUNCTION


' Loads a MIDI file for playback from memory
FUNCTION MIDI_LoadTuneFromMemory%% (buffer AS STRING)
    SHARED __MIDI_Player AS __MIDI_PlayerType

    MIDI_LoadTuneFromMemory = __MIDI_LoadTuneFromMemory(buffer, LEN(buffer), _SNDRATE, __MIDI_Player.useFM)
END FUNCTION


' Pause any MIDI playback
SUB MIDI_Pause (state AS _BYTE)
    SHARED __MIDI_Player AS __MIDI_PlayerType

    IF MIDI_IsPlaying THEN
        __MIDI_Player.isPaused = state
    END IF
END SUB


' Return true if playback is paused
FUNCTION MIDI_IsPaused%%
    $CHECKING:OFF
    SHARED __MIDI_Player AS __MIDI_PlayerType

    IF MIDI_IsPlaying THEN
        MIDI_IsPaused = __MIDI_Player.isPaused
    END IF
    $CHECKING:ON
END FUNCTION


' Gets the global volume
FUNCTION MIDI_GetVolume!
    $CHECKING:OFF
    SHARED __MIDI_Player AS __MIDI_PlayerType

    MIDI_GetVolume = __MIDI_Player.globalVolume
    $CHECKING:ON
END FUNCTION


' Sets the global volume
SUB MIDI_SetVolume (volume AS SINGLE)
    $CHECKING:OFF
    SHARED __MIDI_Player AS __MIDI_PlayerType

    __MIDI_Player.globalVolume = Math_ClampSingle(volume, 0!, 1!)

    _SNDVOL __MIDI_Player.soundHandle, __MIDI_Player.globalVolume
    $CHECKING:ON
END SUB


' This handles playback and keeps track of the render buffer
' You can call this as frequenctly as you want. The routine will simply exit if nothing is to be done
SUB MIDI_Update
    $CHECKING:OFF
    SHARED __MIDI_Player AS __MIDI_PlayerType
    SHARED __MIDI_SoundBuffer() AS SINGLE

    ' If we are not initialized or song is done or we are paused, then exit
    IF _NEGATE MIDI_IsPlaying _ORELSE __MIDI_Player.isPaused THEN EXIT SUB

    ' Loop and fill the buffer until we have soundBufferTime worth of samples frames to play
    WHILE _SNDRAWLEN(__MIDI_Player.soundHandle) < __MIDI_Player.soundBufferTime
        ' Clear the render buffer
        SetMemoryByte _OFFSET(__MIDI_SoundBuffer(0)), NULL, __MIDI_Player.soundBufferBytes

        ' Render some samples to the buffer
        __MIDI_Render __MIDI_SoundBuffer(0), __MIDI_Player.soundBufferBytes

        ' Push the samples to the sound pipe
        DIM i AS _UNSIGNED LONG: i = 0
        DO WHILE i < __MIDI_Player.soundBufferSamples
            _SNDRAW __MIDI_SoundBuffer(i), __MIDI_SoundBuffer(i + 1), __MIDI_Player.soundHandle
            i = i + __MIDI_SOUND_BUFFER_CHANNELS
        LOOP
    WEND
    $CHECKING:ON
END SUB

'$INCLUDE:'FileOps.bas'

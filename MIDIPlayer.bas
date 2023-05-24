'-----------------------------------------------------------------------------------------------------------------------
' MIDI Player Library
' Copyright (c) 2023 Samuel Gomes
'
' This uses:
' TinySoundFont from https://github.com/schellingb/TinySoundFont/blob/master/tsf.h
' TinyMidiLoader from https://github.com/schellingb/TinySoundFont/blob/master/tml.h
' opl.h from https://github.com/mattiasgustavsson/libs/blob/main/opl.h
' stb_vorbis.c from https://github.com/nothings/stb/blob/master/stb_vorbis.c
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'MIDIPlayer.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If MIDIPLAYER_BAS = UNDEFINED Then
    $Let MIDIPLAYER_BAS = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    '$Debug
    'If MIDI_Initialize(FALSE) Then
    '    If MIDI_LoadTuneFromFile(Environ$("SYSTEMROOT") + "/Media/onestop.mid") Then
    '        MIDI_Play
    '        MIDI_Loop TRUE
    '        Do
    '            MIDI_Update MIDI_SOUND_BUFFER_TIME_DEFAULT
    '            Select Case KeyHit
    '                Case 27
    '                    Exit Do
    '                Case 32
    '                    MIDI_Pause Not MIDI_IsPaused
    '            End Select
    '            Locate , 1: Print Using "Time: ########.## / ########.##   Voices: ####"; MIDI_GetCurrentTime; MIDI_GetTotalTime; MIDI_GetActiveVoices;
    '            Limit 60
    '        Loop While MIDI_IsPlaying
    '        MIDI_Stop
    '    End If
    '    MIDI_Finalize
    'End If
    'End
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
    ' This basically allocate stuff on the QB64 side and initializes the underlying C library
    Function MIDI_Initialize%% (useOPL3 As Byte)
        Shared __MIDI_Player As __MIDI_PlayerType

        ' Exit if we are already initialized
        If MIDI_IsInitialized Then
            MIDI_Initialize = TRUE
            Exit Function
        End If

        __MIDI_Player.soundBufferFrames = RoundDownToPowerOf2(_SndRate * 0.04) ' 40 ms buffer round down to power of 2
        __MIDI_Player.soundBufferBytes = __MIDI_Player.soundBufferFrames * __MIDI_SOUND_BUFFER_FRAME_SIZE ' calculate the mixer buffer size
        __MIDI_Player.soundBuffer = MemNew(__MIDI_Player.soundBufferBytes) ' allocate the mixer buffer

        If __MIDI_Player.soundBuffer.SIZE = 0 Then Exit Function ' exit if memory was not allocated

        __MIDI_Player.soundHandle = SndOpenRaw ' allocate a sound pipe

        If __MIDI_Player.soundHandle < 1 Then
            _MemFree __MIDI_Player.soundBuffer
            Exit Function
        End If

        If Not __MIDI_Initialize(SndRate, useOPL3) Then
            SndClose __MIDI_Player.soundHandle
            _MemFree __MIDI_Player.soundBuffer
            Exit Function
        End If

        MIDI_Initialize = TRUE
    End Function


    ' The closes the library and frees all resources
    Sub MIDI_Finalize
        Shared __MIDI_Player As __MIDI_PlayerType

        If MIDI_IsInitialized Then
            SndRawDone __MIDI_Player.soundHandle ' sumbit whatever is remaining in the raw buffer for playback
            SndClose __MIDI_Player.soundHandle ' close and free the QB64 sound pipe
            MemFree __MIDI_Player.soundBuffer ' free the mixer buffer
            __MIDI_Finalize ' call the C side finalizer
        End If
    End Sub


    ' Loads a MIDI file for playback from file
    Function MIDI_LoadTuneFromFile%% (fileName As String)
        MIDI_LoadTuneFromFile = __MIDI_LoadTuneFromFile(fileName + Chr$(NULL))
    End Function


    ' Loads a MIDI file for playback from memory
    Function MIDI_LoadTuneFromMemory%% (buffer As String)
        MIDI_LoadTuneFromMemory = __MIDI_LoadTuneFromMemory(buffer, Len(buffer))
    End Function


    ' Pause any MIDI playback
    Sub MIDI_Pause (state As Byte)
        Shared __MIDI_Player As __MIDI_PlayerType

        If MIDI_IsTuneLoaded Then
            __MIDI_Player.isPaused = state
        End If
    End Sub


    ' Return true if playback is paused
    Function MIDI_IsPaused%%
        Shared __MIDI_Player As __MIDI_PlayerType

        If MIDI_IsTuneLoaded Then
            MIDI_IsPaused = __MIDI_Player.isPaused
        End If
    End Function


    ' This handles playback and keeping track of the render buffer
    ' You can call this as frequenctly as you want. The routine will simply exit if nothing is to be done
    Sub MIDI_Update (bufferTime As Single)
        Shared __MIDI_Player As __MIDI_PlayerType

        ' Only render more samples if song is playing, not paused and we do not have enough samples with the sound device
        If MIDI_IsPlaying And Not __MIDI_Player.isPaused And SndRawLen(__MIDI_Player.soundHandle) < bufferTime Then
            ' Clear the render buffer
            MemFill __MIDI_Player.soundBuffer, __MIDI_Player.soundBuffer.OFFSET, __MIDI_Player.soundBufferBytes, NULL As BYTE

            ' Render some samples to the buffer
            __MIDI_Render __MIDI_Player.soundBuffer.OFFSET, __MIDI_Player.soundBufferBytes

            ' Push the samples to the sound pipe
            Dim i As Unsigned Long
            For i = 0 To __MIDI_Player.soundBufferBytes - __MIDI_SOUND_BUFFER_SAMPLE_SIZE Step __MIDI_SOUND_BUFFER_FRAME_SIZE
                SndRaw MemGet(__MIDI_Player.soundBuffer, __MIDI_Player.soundBuffer.OFFSET + i, Single), MemGet(__MIDI_Player.soundBuffer, __MIDI_Player.soundBuffer.OFFSET + i + __MIDI_SOUND_BUFFER_SAMPLE_SIZE, Single), __MIDI_Player.soundHandle
            Next
        End If
    End Sub
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------

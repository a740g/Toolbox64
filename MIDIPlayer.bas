'---------------------------------------------------------------------------------------------------------
' MIDI Player Library
' Copyright (c) 2023 Samuel Gomes
'
' This uses:
' TinySoundFont from https://github.com/schellingb/TinySoundFont/blob/master/tsf.h
' TinyMidiLoader from https://github.com/schellingb/TinySoundFont/blob/master/tml.h
' opl.h from https://github.com/mattiasgustavsson/libs/blob/main/opl.h
' stb_vorbis.c from https://github.com/nothings/stb/blob/master/stb_vorbis.c
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'MIDIPlayer.bi'
'---------------------------------------------------------------------------------------------------------

$If MIDIPLAYER_BAS = UNDEFINED Then
    $Let MIDIPLAYER_BAS = TRUE
    '-----------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-----------------------------------------------------------------------------------------------------
    '$Debug
    'If MIDI_Initialize(FALSE) Then
    '    If MIDI_LoadTuneFromFile("../midis/COLDWAVE.mid") Then
    '        MIDI_StartPlayer
    '        MIDI_SetLooping TRUE
    '        Do
    '            MIDI_UpdatePlayer
    '            Select Case KeyHit
    '                Case 27
    '                    Exit Do
    '                Case 32
    '                    MIDI_SetPause Not MIDI_IsPaused
    '            End Select
    '            Locate , 1: Print Using "Time: ########.## / ########.##   Voices: ####"; MIDI_GetCurrentTime; MIDI_GetTotalTime; MIDI_GetActiveVoices;
    '            Limit 60
    '        Loop While MIDI_IsPlaying
    '        MIDI_StopPlayer
    '    End If
    '    MIDI_Finalize
    'End If
    'End
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-----------------------------------------------------------------------------------------------------
    ' This basically allocate stuff on the QB64 side and initializes the underlying C library
    Function MIDI_Initialize& (useFM As Byte)
        Shared __MIDI_Player As __MIDI_PlayerType

        ' Exit if we are already initialized
        If MIDI_IsInitialized Then
            MIDI_Initialize = TRUE
            Exit Function
        End If

        If __MIDI_Initialize(SndRate, useFM) Then
            __MIDI_Player.soundBufferSize = (SndRate \ 40) * __MIDI_SOUND_BUFFER_FRAME_SIZE ' calculate the mixer buffer size
            __MIDI_Player.soundBuffer = MemNew(__MIDI_Player.soundBufferSize) ' allocate the mixer buffer

            ' Exit if memory was not allocated
            If __MIDI_Player.soundBuffer.SIZE = 0 Then
                __MIDI_Finalize
                Exit Function
            End If

            __MIDI_Player.soundHandle = SndOpenRaw ' allocate a sound pipe

            MIDI_Initialize = TRUE
        End If
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
    Sub MIDI_SetPause (isPaused As Byte)
        Shared __MIDI_Player As __MIDI_PlayerType

        If MIDI_IsTuneLoaded Then
            __MIDI_Player.isPaused = isPaused
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
    Sub MIDI_UpdatePlayer
        Shared __MIDI_Player As __MIDI_PlayerType

        ' Only render more samples if song is playing, not paused and we do not have enough samples with the sound device
        If MIDI_IsPlaying And Not __MIDI_Player.isPaused And SndRawLen(__MIDI_Player.soundHandle) < __MIDI_SOUND_TIME_MIN Then

            ' Clear the render buffer
            MemFill __MIDI_Player.soundBuffer, __MIDI_Player.soundBuffer.OFFSET, __MIDI_Player.soundBufferSize, NULL As BYTE

            ' Render some samples to the buffer
            __MIDI_Render __MIDI_Player.soundBuffer.OFFSET, __MIDI_Player.soundBufferSize

            ' Push the samples to the sound pipe
            Dim i As Unsigned Long
            For i = 0 To __MIDI_Player.soundBufferSize - __MIDI_SOUND_BUFFER_SAMPLE_SIZE Step __MIDI_SOUND_BUFFER_FRAME_SIZE
                SndRaw MemGet(__MIDI_Player.soundBuffer, __MIDI_Player.soundBuffer.OFFSET + i, Single), MemGet(__MIDI_Player.soundBuffer, __MIDI_Player.soundBuffer.OFFSET + i + __MIDI_SOUND_BUFFER_SAMPLE_SIZE, Single), __MIDI_Player.soundHandle
            Next
        End If
    End Sub
    '-----------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------


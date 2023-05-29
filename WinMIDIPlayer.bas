'-----------------------------------------------------------------------------------------------------------------------
' MIDI Player library using Win32 WinMM MIDI streaming API
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'FileOps.bi'
'$Include:'WinMIDIPlayer.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If WINMIDIPLAYER_BAS = UNDEFINED Then
    $Let WINMIDIPLAYER_BAS = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
    Function MIDI_PlayFromMemory%% (buffer As String)
        MIDI_PlayFromMemory = __MIDI_PlayFromMemory(buffer, Len(buffer))
    End Function

    Sub MIDI_PlayFromMemory (buffer As String)
        Dim sink As _Byte: sink = __MIDI_PlayFromMemory(buffer, Len(buffer))
    End Sub

    Function MIDI_PlayFromFile%% (fileName As String)
        MIDI_PlayFromFile = MIDI_PlayFromMemory(LoadFile(fileName))
    End Function

    Sub MIDI_PlayFromFile (fileName As String)
        MIDI_PlayFromMemory LoadFile(fileName)
    End Sub

    Function Sound_PlayFromFile%% (fileName As String, looping As _Byte)
        Sound_PlayFromFile = __Sound_PlayFromFile(fileName + Chr$(NULL), looping)
    End Function

    Sub Sound_PlayFromFile (fileName As String, looping As _Byte)
        Dim sink As _Byte: sink = __Sound_PlayFromFile(fileName + Chr$(NULL), looping)
    End Sub

    Sub Sound_PlayFromMemory (buffer As String, looping As _Byte)
        Dim sink As _Byte: sink = Sound_PlayFromMemory(buffer, looping)
    End Sub
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' MODULE FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'FileOps.bas'
'-----------------------------------------------------------------------------------------------------------------------
'-----------------------------------------------------------------------------------------------------------------------

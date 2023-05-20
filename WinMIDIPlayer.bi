'-----------------------------------------------------------------------------------------------------------------------
' MIDI Player library using Win32 WinMM MIDI streaming API
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'Common.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If WINMIDIPLAYER_BI = UNDEFINED Then
    $Let WINMIDIPLAYER_BI = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' EXTERNAL LIBRARIES
    '-------------------------------------------------------------------------------------------------------------------
    Declare Library "WinMIDIPlayer"
        Function __MIDI_PlayFromMemory%% (buffer As String, Byval bufferSize As Offset)
        Sub MIDI_Stop
        Function MIDI_IsPlaying%%
        Sub MIDI_SetLooping (ByVal loops As Long)
        Function MIDI_IsLooping%%
        Sub MIDI_Pause
        Sub MIDI_Resume
        Sub MIDI_SetVolume (ByVal volume As Single)
        Function MIDI_GetVolume!
        Function __Sound_PlayFromFile%% (fileName As String, Byval looping As Byte)
        Function Sound_PlayFromMemory%% (buffer As String, Byval looping As Byte)
        Sub Sound_Stop
    End Declare
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------


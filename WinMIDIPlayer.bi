'-----------------------------------------------------------------------------------------------------------------------
' MIDI Player library using Win32 WinMM MIDI streaming API
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'MemFile.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If WINMIDIPLAYER_BI = UNDEFINED Then
    $Let WINMIDIPLAYER_BI = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' EXTERNAL LIBRARIES
    '-------------------------------------------------------------------------------------------------------------------
    Declare Library "WinMIDIPlayer"
        Function __MIDI_PlayFromMemory%% (buffer As String, Byval bufferSize As _Offset)
        Sub MIDI_Stop
        Function MIDI_IsPlaying%%
        Sub MIDI_Loop (ByVal loops As Long)
        Function MIDI_IsLooping%%
        Sub MIDI_Pause (ByVal state As _Byte)
        Function MIDI_IsPaused%%
        Sub MIDI_SetVolume (ByVal volume As Single)
        Function MIDI_GetVolume!
        Function __Sound_PlayFromFile%% (fileName As String, Byval looping As _Byte)
        Function Sound_PlayFromMemory%% (buffer As String, Byval looping As _Byte)
        Sub Sound_Stop
    End Declare
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------

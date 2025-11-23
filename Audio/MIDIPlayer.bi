'-----------------------------------------------------------------------------------------------------------------------
' MIDI Player library using fmidi + RtMidi
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Core/Common.bi'
'$INCLUDE:'../Core/Types.bi'
'$INCLUDE:'../IO/File.bi'

DECLARE LIBRARY "MIDIPlayer"
    FUNCTION MIDI_GetErrorMessage$
    FUNCTION MIDI_GetPortCount~&
    FUNCTION MIDI_GetPortName$ (BYVAL portIndex AS _UNSIGNED LONG)
    FUNCTION MIDI_SetPort%% (BYVAL portIndex AS _UNSIGNED LONG)
    FUNCTION MIDI_GetPort~&
    FUNCTION __MIDI_PlayFromMemory%% (buffer AS STRING, BYVAL bufferSize AS _OFFSET)
    SUB MIDI_Stop
    FUNCTION MIDI_IsPlaying%%
    SUB MIDI_Loop (BYVAL loops AS LONG)
    FUNCTION MIDI_IsLooping%%
    SUB MIDI_Pause (BYVAL state AS _BYTE)
    FUNCTION MIDI_IsPaused%%
    FUNCTION MIDI_GetTotalTime#
    FUNCTION MIDI_GetCurrentTime#
    SUB MIDI_SetVolume (BYVAL volume AS SINGLE)
    FUNCTION MIDI_GetVolume!
    SUB MIDI_SeekToTime (BYVAL seekTime AS DOUBLE)
    FUNCTION MIDI_GetFormat$
END DECLARE

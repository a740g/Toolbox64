'-----------------------------------------------------------------------------------------------------------------------
' MIDI Player library using fmidi + RtMidi
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'
'$INCLUDE:'Types.bi'
'$INCLUDE:'File.bi'

DECLARE LIBRARY "MIDIPlayer"
    FUNCTION MIDI_GetErrorMessage$
    FUNCTION __MIDI_PlayFromMemory%% (buffer AS STRING, BYVAL bufferSize AS _OFFSET)
    SUB MIDI_Stop
    FUNCTION MIDI_IsPlaying%%
    SUB MIDI_Loop (BYVAL loops AS LONG)
    FUNCTION MIDI_IsLooping%%
    SUB MIDI_Pause (BYVAL state AS _BYTE)
    FUNCTION MIDI_IsPaused%%
    FUNCTION MIDI_GetTotalTime#
    FUNCTION MIDI_GetCurrentTime#
END DECLARE

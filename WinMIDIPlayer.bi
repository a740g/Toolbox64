'-----------------------------------------------------------------------------------------------------------------------
' MIDI Player library using Win32 WinMM MIDI streaming API
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF WINMIDIPLAYER_BI = UNDEFINED THEN
    $LET WINMIDIPLAYER_BI = TRUE

    '$INCLUDE:'Common.bi'
    '$INCLUDE:'Types.bi'
    '$INCLUDE:'MemFile.bi'
    '$INCLUDE:'FileOps.bi'

    DECLARE LIBRARY "WinMIDIPlayer"
        FUNCTION __MIDI_PlayFromMemory%% (buffer AS STRING, BYVAL bufferSize AS _OFFSET)
        SUB MIDI_Stop
        FUNCTION MIDI_IsPlaying%%
        SUB MIDI_Loop (BYVAL loops AS LONG)
        FUNCTION MIDI_IsLooping%%
        SUB MIDI_Pause (BYVAL state AS _BYTE)
        FUNCTION MIDI_IsPaused%%
        SUB MIDI_SetVolume (BYVAL volume AS SINGLE)
        FUNCTION MIDI_GetVolume!
        FUNCTION Sound_PlayFromMemory%% (buffer AS STRING, BYVAL looping AS _BYTE)
        SUB Sound_Stop
        SUB Sound_Beep ALIAS "Beep" (BYVAL frequency AS _UNSIGNED LONG, BYVAL duration AS _UNSIGNED LONG)
    END DECLARE

$END IF

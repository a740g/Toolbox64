'-----------------------------------------------------------------------------------------------------------------------
' MIDI Player library using fmidi + RtMidi
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'MIDIPlayer.bi'

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
$CONSOLE
IF MIDI_PlayFromFile("C:\Users\samue\OneDrive\Public\Media\Music\MIDIs\I Am Born To Make You Happy.MID") THEN
    DO
        LOCATE , 1: PRINT USING "Time: ######.### / ######.###"; MIDI_GetCurrentTime; MIDI_GetTotalTime;
        _LIMIT 60
    LOOP UNTIL _KEYHIT = 27

    MIDI_Stop
END IF
'-----------------------------------------------------------------------------------------------------------------------

FUNCTION MIDI_PlayFromMemory%% (buffer AS STRING)
    MIDI_PlayFromMemory = __MIDI_PlayFromMemory(buffer, LEN(buffer))
END FUNCTION


SUB MIDI_PlayFromMemory (buffer AS STRING)
    DIM sink AS _BYTE: sink = __MIDI_PlayFromMemory(buffer, LEN(buffer))
END SUB


FUNCTION MIDI_PlayFromFile%% (fileName AS STRING)
    MIDI_PlayFromFile = MIDI_PlayFromMemory(File_Load(fileName))
END FUNCTION


SUB MIDI_PlayFromFile (fileName AS STRING)
    MIDI_PlayFromMemory File_Load(fileName)
END SUB

'$INCLUDE:'File.bas'

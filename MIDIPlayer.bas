'-----------------------------------------------------------------------------------------------------------------------
' MIDI Player library using fmidi + RtMidi
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'MIDIPlayer.bi'

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'$CONSOLE
'$DEBUG

'DO
'    DIM fileName AS STRING: fileName = _OPENFILEDIALOG$("Open MIDI file", , "*.mid|*.midi|*.rmi|*.xmi|*.mus", "MIDI Files")
'    IF NOT _FILEEXISTS(fileName) THEN EXIT DO

'    DIM AS _BYTE pause, repeat

'    IF MIDI_PlayFromFile(fileName) THEN
'        DIM k AS LONG

'        PRINT "Playing: "; fileName

'        DO
'            k = _KEYHIT
'            SELECT CASE k
'                CASE 32
'                    pause = NOT pause
'                    MIDI_Pause pause
'                    _KEYCLEAR

'                CASE 108, 76
'                    repeat = NOT repeat
'                    MIDI_Loop repeat
'                    _KEYCLEAR
'            END SELECT

'            LOCATE , 1: PRINT USING "Time: ######.### / ######.###"; MIDI_GetCurrentTime; MIDI_GetTotalTime;

'            _LIMIT 60
'        LOOP WHILE k <> 27 _ANDALSO MIDI_IsPlaying

'        PRINT

'        MIDI_Stop
'    END IF
'LOOP

'END
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

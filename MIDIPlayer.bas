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
'DIM ports AS _UNSIGNED LONG: ports = MIDI_GetPortCount

'IF ports THEN
'    DIM i AS _UNSIGNED LONG

'    PRINT "Ports found:"; ports

'    FOR i = 1 TO ports
'        PRINT "Port"; i - 1; ": "; MIDI_GetPortName(i - 1)
'    NEXT i
'END IF

'DO
'    DIM fileName AS STRING: fileName = _OPENFILEDIALOG$("Open MIDI file", , "*.mid|*.midi|*.rmi|*.xmi|*.mus", "MIDI Files")
'    IF NOT _FILEEXISTS(fileName) THEN EXIT DO

'    DIM AS _BYTE pause, repeat

'    IF MIDI_PlayFromFile(fileName) THEN
'        REM MIDI_Loop _TRUE

'        DIM k AS LONG

'        PRINT "Port: "; MIDI_GetPortName(MIDI_GetPort)
'        PRINT "Playing ("; MIDI_GetFormat; "): "; fileName

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

'                CASE 18432
'                    MIDI_SetVolume MIDI_GetVolume + 0.01!

'                CASE 20480
'                    MIDI_SetVolume MIDI_GetVolume - 0.01!

'            END SELECT

'            LOCATE , 1: PRINT USING "Time: ######.### / ######.###, Volume ###%"; MIDI_GetCurrentTime; MIDI_GetTotalTime; MIDI_GetVolume * 100!;

'            _LIMIT 60
'        LOOP WHILE k <> 27 _ANDALSO MIDI_IsPlaying

'        PRINT

'        MIDI_Stop
'    ELSE
'        PRINT "Playback failed. Error: "; MIDI_GetErrorMessage
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

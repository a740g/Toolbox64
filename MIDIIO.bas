'-----------------------------------------------------------------------------------------------------------------------
' MIDI I/O library using RtMidi
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'MIDIIO.bi'

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
' $CONSOLE

' DIM message_types(255) AS STRING
' message_types(&H90) = "NOTE ON"
' message_types(&H80) = "NOTE OFF"
' message_types(&HB0) = "CONTROL CHANGE"
' message_types(&HC0) = "PROGRAM CHANGE"
' message_types(&HE0) = "PITCH BEND"
' message_types(&HF0) = "SYSTEM EXCLUSIVE"
' message_types(&HF7) = "END OF SYSTEM EXCLUSIVE"
' message_types(&HFF) = "META EVENT"
' message_types(&HFE) = "ACTIVE SENSING"
' message_types(&HF8) = "TIMING CLOCK"
' message_types(&HFA) = "START"
' message_types(&HFB) = "CONTINUE"
' message_types(&HFC) = "STOP"
' message_types(&HFF) = "META EVENT"
' message_types(&HF1) = "MIDI TIME CODE"
' message_types(&HF2) = "SONG POSITION POINTER"
' message_types(&HF3) = "SONG SELECT"
' message_types(&HF6) = "TUNE REQUEST"

' DIM hIn AS LONG: hIn = MIDIIO_Create(_TRUE)
' DIM hOut AS LONG: hOut = MIDIIO_Create(_FALSE)

' IF hIn > 0 THEN
'    DIM ports AS _UNSIGNED LONG: ports = MIDIIO_GetPortCount(hIn)
'    IF ports THEN
'        DIM i AS _UNSIGNED LONG
'        PRINT "Found input ports:"; ports
'        FOR i = 1 TO ports
'            PRINT "Port"; i - 1; ": "; MIDIIO_GetPortName(hIn, i - 1)
'        NEXT i
'        ports = MIDIIO_GetPortCount(hOut)
'        PRINT "Found output ports:"; ports
'        FOR i = 1 TO ports
'            PRINT "Port"; i - 1; ": "; MIDIIO_GetPortName(hOut, i - 1)
'        NEXT i
'        PRINT "Opening input port 1..."
'        IF MIDIIO_OpenPort(hIn, 1) THEN
'            PRINT "Opened output port 1:"; MIDIIO_OpenPort(hOut, 1)
'            PRINT "Listening for MIDI input. Press ESC to exit."
'            DO
'                IF MIDIIO_GetMessageCount(hIn) THEN
'                    PRINT USING "#####.### | "; MIDIIO_GetTimestamp(hIn);
'                    DIM message AS STRING: message = MIDIIO_GetMessage(hIn)
'                    DIM code AS STRING
'                    code$ = HEX$(ASC(message, 1))
'                    PRINT code$; ": ";
'                    PRINT message_types(VAL("&H" + code$));
'                    SELECT CASE code$
'                        CASE "90", "80"
'                            PRINT " NOTE #: "; _TOSTR$(ASC(message, 2));
'                            IF LEN(message) = 3 THEN
'                                PRINT " VELOCITY: "; _TOSTR$(ASC(message, 3));
'                            ELSE
'                                PRINT " VELOCITY: 0";
'                            END IF
'                        CASE "B0"
'                            IF LEN(message) = 3 THEN
'                                PRINT " CONTROLLER #: "; _TOSTR$(ASC(message, 2));
'                                PRINT " VALUE: "; _TOSTR$(ASC(message, 3));
'                            ELSE
'                                PRINT " CONTROLLER #: "; _TOSTR$(ASC(message, 2));
'                            END IF
'                        CASE "C0"
'                            PRINT " PROGRAM #: "; _TOSTR$(ASC(message, 3));
'                        CASE "E0"
'                            IF LEN(message) = 3 THEN
'                                PRINT " VALUE: "; _TOSTR$(ASC(message, 2) + ASC(message, 3) * 128);
'                            END IF
'                        CASE ELSE
'                            FOR i = 2 TO LEN(message)
'                                PRINT HEX$(ASC(message, i)); " ";
'                            NEXT i
'                    END SELECT
'                    PRINT
'                    MIDIIO_SendMessage hOut, message
'                END IF
'            LOOP UNTIL _KEYHIT = 27
'            MIDIIO_ClosePort hOut
'            MIDIIO_ClosePort hIn
'        ELSE
'            PRINT "Failed to open port 1!"
'        END IF
'    ELSE
'        PRINT "No MIDI input ports!"
'    END IF
'    MIDIIO_Delete hOut
'    MIDIIO_Delete hIn
' END IF

' END
'-----------------------------------------------------------------------------------------------------------------------

SUB MIDIIO_SendMessage (handle AS LONG, message AS STRING)
    __MIDIIO_SendMessage handle, message, LEN(message)

    EXIT SUB

    DIM sink AS LONG: sink = _SNDRATE ' This dummy call to _SNDRATE is to tell QB64-PE to link in the system audio libraries.
END SUB

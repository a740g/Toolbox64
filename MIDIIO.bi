'-----------------------------------------------------------------------------------------------------------------------
' MIDI I/O library using RtMidi
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'DIM hIn AS LONG: hIn = MIDIIO_Create(_TRUE)
'DIM hOut AS LONG: hOut = MIDIIO_Create(_FALSE)

'IF hIn > 0 THEN
'    DIM ports AS _UNSIGNED LONG: ports = MIDIIO_GetPortCount(hIn)

'    IF ports THEN
'        DIM i AS _UNSIGNED LONG

'        FOR i = 1 TO ports
'            PRINT "Port"; i - 1; ": "; MIDIIO_GetPortName(hIn, i - 1)
'        NEXT i

'        PRINT "Opening port 0..."
'        IF MIDIIO_OpenPort(hIn, 0) THEN
'            PRINT "Opened output port 0:"; MIDIIO_OpenPort(hOut, 0)

'            PRINT "Listening for MIDI input. Press ESC to exit."

'            DO
'                IF MIDIIO_GetMessageCount(hIn) THEN
'                    PRINT USING "Timestamp #####.### | Message: "; MIDIIO_GetTimestamp(hIn);

'                    DIM message AS STRING: message = MIDIIO_GetMessage(hIn)
'                    FOR i = 1 TO LEN(message)
'                        PRINT HEX$(ASC(message, i)); " ";
'                    NEXT i

'                    PRINT

'                    MIDIIO_SendMessage hOut, message, LEN(message)
'                END IF
'            LOOP UNTIL _KEYHIT = 27

'            MIDIIO_ClosePort hOut
'            MIDIIO_ClosePort hIn
'        ELSE
'            PRINT "Failed to open port 0!"
'        END IF
'    ELSE
'        PRINT "No MIDI input ports!"
'    END IF

'    MIDIIO_Delete hOut
'    MIDIIO_Delete hIn
'END IF
'-----------------------------------------------------------------------------------------------------------------------

DECLARE LIBRARY "MIDIIO"
    FUNCTION MIDIIO_Create& (BYVAL isInput AS _BYTE)
    SUB MIDIIO_Delete (BYVAL handle AS LONG)
    FUNCTION MIDIIO_GetLastErrorMessage$ (BYVAL handle AS LONG)
    FUNCTION MIDIIO_GetPortCount~& (BYVAL handle AS LONG)
    FUNCTION MIDIIO_GetPortName$ (BYVAL handle AS LONG, BYVAL portIndex AS LONG)
    FUNCTION MIDIIO_GetOpenPortNumber&& (BYVAL handle AS LONG)
    FUNCTION MIDIIO_OpenPort% (BYVAL handle AS LONG, BYVAL portIndex AS LONG)
    SUB MIDIIO_ClosePort (BYVAL handle AS LONG)
    FUNCTION MIDIIO_GetMessageCount~%& (BYVAL handle AS LONG)
    FUNCTION MIDIIO_GetMessage$ (BYVAL handle AS LONG)
    FUNCTION MIDIIO_GetTimestamp# (BYVAL handle AS LONG)
    SUB MIDIIO_IgnoreMessageTypes (BYVAL handle AS LONG, BYVAL midiSysex AS _BYTE, BYVAL midiTime AS _BYTE, BYVAL midiSense AS _BYTE)
    SUB MIDIIO_SendMessage (BYVAL handle AS LONG, message AS STRING, BYVAL messageSize AS _UNSIGNED _OFFSET)
END DECLARE

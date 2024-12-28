'-----------------------------------------------------------------------------------------------------------------------
' MIDI I/O library using RtMidi
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'MIDIIO.bi'

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'$CONSOLE
'DIM hIn AS LONG: hIn = MIDIIO_Create(_TRUE)
'DIM hOut AS LONG: hOut = MIDIIO_Create(_FALSE)

'IF hIn > 0 THEN
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

'        PRINT "Opening input port 0..."
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

'                    MIDIIO_SendMessage hOut, message
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

'END
'-----------------------------------------------------------------------------------------------------------------------

SUB MIDIIO_SendMessage (handle AS LONG, message AS STRING)
    __MIDIIO_SendMessage handle, message, LEN(message)

    EXIT SUB

    DIM sink AS LONG: sink = _SNDRATE ' This dummy call to _SNDRATE is to tell QB64-PE to link in the system audio libraries.
END SUB

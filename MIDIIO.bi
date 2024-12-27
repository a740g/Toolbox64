'-----------------------------------------------------------------------------------------------------------------------
' MIDI I/O library using RtMidi
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'

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
    ''' @brief Creates a MIDI I/O context and returns a handle to it.
    ''' @param isInput A boolean value indicating whether the context should be for input or output.
    ''' @return A handle to the MIDI I/O context.
    FUNCTION MIDIIO_Create& (BYVAL isInput AS _BYTE)

    ''' @brief Deletes a MIDI I/O context.
    ''' @param handle A handle to the MIDI I/O context.
    SUB MIDIIO_Delete (BYVAL handle AS LONG)

    ''' @brief Gets the last error message from the MIDI I/O context.
    ''' @param handle A handle to the MIDI I/O context.
    ''' @return The last error message.
    FUNCTION MIDIIO_GetLastErrorMessage$ (BYVAL handle AS LONG)
    
    ''' @brief Gets the number of MIDI ports available.
    ''' @param handle A handle to the MIDI I/O context.
    ''' @return The number of MIDI ports available.
    FUNCTION MIDIIO_GetPortCount~& (BYVAL handle AS LONG)
    
    ''' @brief Gets the name of a MIDI port.
    ''' @param handle A handle to the MIDI I/O context.
    ''' @param portIndex The index of the port.
    ''' @return The name of the MIDI port.
    FUNCTION MIDIIO_GetPortName$ (BYVAL handle AS LONG, BYVAL portIndex AS LONG)
    
    ''' @brief Gets the index of the open port.
    ''' @param handle A handle to the MIDI I/O context.
    ''' @return The index of the open port.
    FUNCTION MIDIIO_GetOpenPortNumber&& (BYVAL handle AS LONG)
    
    ''' @brief Opens a MIDI port.
    ''' @param handle A handle to the MIDI I/O context.
    ''' @param portIndex The index of the port to open.
    ''' @return A boolean value indicating whether the port was opened successfully.
    FUNCTION MIDIIO_OpenPort% (BYVAL handle AS LONG, BYVAL portIndex AS LONG)
    
    ''' @brief Closes the open port.
    ''' @param handle A handle to the MIDI I/O context.
    SUB MIDIIO_ClosePort (BYVAL handle AS LONG)

    ''' @brief Gets the number of MIDI messages available. This function must be called before MIDIIO_GetMessage and MIDIIO_GetTimestamp. It should be called repeatedly to retrieve all available messages.
    ''' @param handle A handle to the MIDI I/O context.
    ''' @return The number of MIDI messages available.
    FUNCTION MIDIIO_GetMessageCount~%& (BYVAL handle AS LONG)

    ''' @brief Gets a MIDI message.
    ''' @param handle A handle to the MIDI I/O context.
    ''' @return The MIDI message.
    FUNCTION MIDIIO_GetMessage$ (BYVAL handle AS LONG)
    
    ''' @brief Gets the timestamp of the last MIDI message.
    ''' @param handle A handle to the MIDI I/O context.
    ''' @return The timestamp of the last MIDI message.
    FUNCTION MIDIIO_GetTimestamp# (BYVAL handle AS LONG)
    
    ''' @brief Ignores specific message types.
    ''' @param handle A handle to the MIDI I/O context.
    ''' @param midiSysEx A boolean value indicating whether to ignore SysEx messages.
    ''' @param midiTime A boolean value indicating whether to ignore timing messages.
    ''' @param midiSense A boolean value indicating whether to ignore sense messages.
    SUB MIDIIO_IgnoreMessageTypes (BYVAL handle AS LONG, BYVAL midiSysEx AS _BYTE, BYVAL midiTime AS _BYTE, BYVAL midiSense AS _BYTE)
    
    ''' @brief Sends a MIDI message.
    ''' @param handle A handle to the MIDI I/O context.
    ''' @param message The MIDI message to send.
    ''' @param messageSize The size of the MIDI message.
    SUB MIDIIO_SendMessage (BYVAL handle AS LONG, message AS STRING, BYVAL messageSize AS _UNSIGNED _OFFSET)
END DECLARE

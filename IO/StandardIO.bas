'-----------------------------------------------------------------------------------------------------------------------
' Standard Input/Output functions
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'StandardIO.bi'

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'$CONSOLE:ONLY

'StandardIO_WriteChar _ASC_QUOTE
'_ECHO "Hello, world!"
'PRINT StandardIO_ReadChar

'StandardIO_WriteChar _ASC_LF

'StandardIO_WriteLine "This is going to be on it's own line."

'StandardIO_Write "1st part ["
'StandardIO_Write "] second part"

'SLEEP

'END
'-----------------------------------------------------------------------------------------------------------------------

SUB StandardIO_WriteLine (text AS STRING)
    DECLARE LIBRARY "StandardIO"
        SUB __StandardIO_WriteLine ALIAS "std::puts" (text AS STRING)
    END DECLARE

    __StandardIO_WriteLine text + _CHR_NUL
END SUB

SUB StandardIO_Write (text AS STRING)
    DECLARE LIBRARY "StandardIO"
        SUB __StandardIO_Write (text AS STRING)
    END DECLARE

    __StandardIO_Write text + _CHR_NUL
END SUB

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

'StandardIO_WriteLine CHR$(13) + CHR$(10)

'PRINT StandardIO_Read(10)

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
        SUB __StandardIO_Write ALIAS "StandardIO_Write_" (text AS STRING)
    END DECLARE

    __StandardIO_Write text + _CHR_NUL
END SUB

FUNCTION StandardIO_Read$ (maxLength AS _UNSIGNED _OFFSET)
    DECLARE LIBRARY "StandardIO"
        FUNCTION __StandardIO_Read$ ALIAS "StandardIO_Read_" (BYVAL maxLength AS _UNSIGNED _OFFSET)
    END DECLARE

    StandardIO_Read = __StandardIO_Read(maxLength)
END FUNCTION

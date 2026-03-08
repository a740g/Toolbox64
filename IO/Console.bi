'-----------------------------------------------------------------------------------------------------------------------
' Console Input/Output functions
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$LET TOOLBOX64_STRICT = TRUE
'$INCLUDE:'../Core/Common.bi'

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'$CONSOLE:ONLY

'Console_WriteChar _ASC_QUOTE
'_ECHO "Hello, world!"
'PRINT Console_ReadChar

'Console_WriteChar _ASC_LF

'Console_WriteLine "This is going to be on it's own line."

'Console_Write "1st part ["
'Console_Write "] second part"

'Console_WriteLine _STR_CRLF
'Console_WriteLine "New line"

'PRINT Console_Read(10)
'PRINT Console_Read(10)

'END
'-----------------------------------------------------------------------------------------------------------------------

DECLARE LIBRARY "Console"
    FUNCTION Console_ReadChar& ALIAS "std::getchar"
    SUB Console_WriteChar ALIAS "std::putchar" (BYVAL ch AS LONG)
END DECLARE

SUB Console_WriteLine (text AS STRING)
    DECLARE LIBRARY "Console"
        SUB __Console_WriteLine ALIAS "std::puts" (text AS STRING)
    END DECLARE

    __Console_WriteLine text + _CHR_NUL
END SUB

SUB Console_Write (text AS STRING)
    DECLARE LIBRARY "Console"
        SUB __Console_Write ALIAS "Console_Write_" (text AS STRING)
    END DECLARE

    __Console_Write text + _CHR_NUL
END SUB

FUNCTION Console_Read$ (maxLength AS _UNSIGNED _OFFSET)
    DECLARE LIBRARY "Console"
        FUNCTION __Console_Read$ ALIAS "Console_Read_" (BYVAL maxLength AS _UNSIGNED _OFFSET)
    END DECLARE

    Console_Read = __Console_Read(maxLength)
END FUNCTION

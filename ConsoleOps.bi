'-----------------------------------------------------------------------------------------------------------------------
' Standard I/O CRT functions
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF CONSOLEOPS_BI = UNDEFINED THEN
    $LET CONSOLEOPS_BI = TRUE

    '$INCLUDE:'Common.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    '$CONSOLE:ONLY
    'Console_PutCharacter 34
    '_ECHO "Hello, world!"
    'PRINT Console_GetCharacter
    'END
    '-------------------------------------------------------------------------------------------------------------------

    DECLARE LIBRARY
        FUNCTION Console_GetCharacter& ALIAS "getchar"
        SUB Console_PutCharacter ALIAS "putchar" (BYVAL ch AS LONG)
    END DECLARE

$END IF

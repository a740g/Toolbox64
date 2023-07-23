'-----------------------------------------------------------------------------------------------------------------------
' Standard I/O CRT functions
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF CONSOLEOPS_BI = UNDEFINED THEN
    $LET CONSOLEOPS_BI = TRUE

    '$INCLUDE:'Common.bi'

    DECLARE LIBRARY
        FUNCTION GetConsoleCharacter& ALIAS getchar
        SUB PutConsoleCharacter ALIAS putchar (BYVAL ch AS LONG)
    END DECLARE

$END IF

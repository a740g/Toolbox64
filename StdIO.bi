'-----------------------------------------------------------------------------------------------------------------------
' Standard I/O CRT functions
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF STDIO_BI = UNDEFINED THEN
    $LET STDIO_BI = TRUE

    '$INCLUDE:'Common.bi'

    DECLARE LIBRARY
        FUNCTION getchar&
        SUB putchar (BYVAL ch AS LONG)
    END DECLARE

$END IF

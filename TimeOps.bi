'-----------------------------------------------------------------------------------------------------------------------
' Time related routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF TIMEOPS_BI = UNDEFINED THEN
    $LET TIMEOPS_BI = TRUE

    '$INCLUDE:'Common.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    '$DEBUG

    'DO
    '    _PRINTSTRING (1, 1), "FPS:" + STR$(Time_GetHertz)

    '    _LIMIT 75
    'LOOP UNTIL _KEYHIT = KEY_ESCAPE

    'END
    '-------------------------------------------------------------------------------------------------------------------

    DECLARE LIBRARY "TimeOps"
        FUNCTION Time_GetTicks~&& ALIAS "GetTicks"
        FUNCTION Time_GetHertz~&
    END DECLARE

$END IF

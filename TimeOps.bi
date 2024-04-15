'-----------------------------------------------------------------------------------------------------------------------
' Time related routines
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'$DEBUG

'DO
'    _PRINTSTRING (1, 1), "FPS:" + STR$(Time_GetHertz)

'    _LIMIT 75
'LOOP UNTIL _KEYHIT = KEY_ESCAPE

'END
'-----------------------------------------------------------------------------------------------------------------------

DECLARE LIBRARY "TimeOps"
    FUNCTION Time_GetTicks~&& ALIAS "GetTicks"
    FUNCTION Time_GetHertz~&
END DECLARE

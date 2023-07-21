'-----------------------------------------------------------------------------------------------------------------------
' Time related routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF TIMEOPS_BI = UNDEFINED THEN
    $LET TIMEOPS_BI = TRUE

    '$INCLUDE:'Common.bi'

    DECLARE LIBRARY
        FUNCTION GetTicks~&&
    END DECLARE

$END IF

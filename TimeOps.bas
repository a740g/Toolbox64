'-----------------------------------------------------------------------------------------------------------------------
' Time related routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF TIMEOPS_BAS = UNDEFINED THEN
    $LET TIMEOPS_BAS = TRUE

    '$INCLUDE:'TimeOps.bi'

    ' Calculates and returns the FPS when repeatedly called inside a loop
    FUNCTION GetFPS~&
        STATIC AS _UNSIGNED LONG counter, finalFPS
        STATIC lastTime AS _UNSIGNED _INTEGER64

        DIM currentTime AS _UNSIGNED _INTEGER64: currentTime = GetTicks

        IF currentTime > lastTime + 1000 THEN
            lastTime = currentTime
            finalFPS = counter
            counter = 0
        END IF

        counter = counter + 1

        GetFPS = finalFPS
    END FUNCTION

$END IF

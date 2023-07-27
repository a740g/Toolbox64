'-----------------------------------------------------------------------------------------------------------------------
' QB64-PE pointer helper routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF POINTEROPS_BAS = UNDEFINED THEN
    $LET POINTEROPS_BAS = TRUE

    '$INCLUDE:'PointerOps.bi'

    ' Returns a BASIC string (bstring) from a NULL terminated C string (cstring)
    FUNCTION ToBString$ (s AS STRING)
        DIM zeroPos AS LONG: zeroPos = INSTR(s, CHR$(NULL))
        IF zeroPos > NULL THEN ToBString = LEFT$(s, zeroPos - 1) ELSE ToBString = s
    END FUNCTION


    ' Just a convenience function for use when calling external libraries
    FUNCTION ToCString$ (s AS STRING)
        ToCString = s + CHR$(NULL)
    END FUNCTION

$END IF

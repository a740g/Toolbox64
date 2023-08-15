'-----------------------------------------------------------------------------------------------------------------------
' 32-bit color constants & routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF COLOROPS_BAS = UNDEFINED THEN
    $LET COLOROPS_BAS = TRUE

    '$INCLUDE:'ColorOps.bi'

    ' Converts a web color in hex format to a 32-bit RGB color
    FUNCTION HexToRGB32~& (hexColor AS STRING)
        IF LEN(hexColor) <> 6 THEN ERROR 17
        HexToRGB32 = _RGB32(VAL("&H" + LEFT$(hexColor, 2)), VAL("&H" + MID$(hexColor, 3, 2)), VAL("&H" + RIGHT$(hexColor, 2)))
    END FUNCTION

$END IF

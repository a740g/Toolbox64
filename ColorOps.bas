'-----------------------------------------------------------------------------------------------------------------------
' 32-bit color constants & routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF COLOROPS_BAS = UNDEFINED THEN
    $LET COLOROPS_BAS = TRUE

    '$INCLUDE:'ColorOps.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    'DIM i AS _UNSIGNED LONG: i = HexToRGB32("090502")
    'PRINT HEX$(i)
    'i = ToBGRA(9, 5, 2, 255)
    'PRINT HEX$(i)
    'i = ToRGBA(9, 5, 2, 255)
    'PRINT HEX$(i)
    'PRINT HEX$(GetRedFromRGBA(i))
    'PRINT HEX$(GetGreenFromRGBA(i))
    'PRINT HEX$(GetBlueFromRGBA(i))
    'PRINT HEX$(GetRGB(i))
    'PRINT HEX$(SwapRedBlue(i))
    'END
    '-------------------------------------------------------------------------------------------------------------------

    ' Converts a web color in hex format to a 32-bit RGB color
    FUNCTION HexToRGB32~& (hexColor AS STRING)
        IF LEN(hexColor) <> 6 THEN ERROR ERROR_ILLEGAL_FUNCTION_CALL
        HexToRGB32 = _RGB32(VAL("&H" + LEFT$(hexColor, 2)), VAL("&H" + MID$(hexColor, 3, 2)), VAL("&H" + RIGHT$(hexColor, 2)))
    END FUNCTION

$END IF

'-----------------------------------------------------------------------------------------------------------------------
' Extended graphics routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF GRAPHICOPS_BI = UNDEFINED THEN
    $LET GRAPHICOPS_BI = TRUE

    '$INCLUDE:'Common.bi'

    DECLARE LIBRARY "GraphicOps"
        SUB Graphics_SetPixel (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
        FUNCTION Graphics_MakeTextColorAttribute~% (BYVAL character AS _UNSIGNED _BYTE, BYVAL fColor AS _UNSIGNED _BYTE, BYVAL bColor AS _UNSIGNED _BYTE)
        FUNCTION Graphics_MakeDefaultTextColorAttribute~% (BYVAL character AS _UNSIGNED _BYTE)
        SUB Graphics_SetForegroundColor (BYVAL fColor AS _UNSIGNED LONG)
        FUNCTION Graphics_GetForegroundColor~&
        SUB Graphics_SetBackgroundColor (BYVAL bColor AS _UNSIGNED LONG)
        FUNCTION Graphics_GetBackgroundColor~&
        SUB Graphics_DrawHorizontalLine (BYVAL lx AS LONG, BYVAL ty AS LONG, BYVAL rx AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
        SUB Graphics_DrawVerticalLine (BYVAL lx AS LONG, BYVAL ty AS LONG, BYVAL by AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
        SUB Graphics_DrawRectangle (BYVAL lx AS LONG, BYVAL ty AS LONG, BYVAL rx AS LONG, BYVAL by AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
        SUB Graphics_DrawFilledRectangle (BYVAL lx AS LONG, BYVAL ty AS LONG, BYVAL rx AS LONG, BYVAL by AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
        SUB Graphics_DrawLine (BYVAL x1 AS LONG, BYVAL y1 AS LONG, BYVAL x2 AS LONG, BYVAL y2 AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
        SUB Graphics_DrawCircle (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL radius AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
        SUB Graphics_DrawFilledCircle (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL radius AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    END DECLARE
$END IF

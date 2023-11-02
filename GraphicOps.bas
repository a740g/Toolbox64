'-----------------------------------------------------------------------------------------------------------------------
' Extended graphics routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF GRAPHICOPS_BAS = UNDEFINED THEN
    $LET GRAPHICOPS_BAS = TRUE

    '$INCLUDE:'GraphicOps.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    '$DEBUG
    '$CONSOLE

    '$RESIZE:STRETCH

    'SCREEN _NEWIMAGE(640, 480, 32)

    'SCREEN _NEWIMAGE(640, 480, 13)

    'SCREEN 0: WIDTH 160, 90: _FONT 8: _BLINK OFF

    'COLOR 17, 6
    'Graphics_SetForegroundColor 1
    'Graphics_SetBackgroundColor 14

    'PRINT Graphics_GetForegroundColor, Graphics_GetBackgroundColor
    'PRINT _DEFAULTCOLOR, _BACKGROUNDCOLOR

    'PRINT Graphics_MakeTextColorAttribute(56, 1, 14)
    'PRINT Graphics_MakeDefaultTextColorAttribute(56)

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

    'DIM t AS DOUBLE: t = TIMER

    'DIM i AS LONG: FOR i = 1 TO 1000000
    'COLOR 17, 6: _PRINTSTRING (11, 11), "8"
    'Graphics_SetPixel 10, 10, Graphics_MakeTextColorAttribute(56, 1, 14)
    'PSET (30, 30), 14
    'Graphics_SetPixel 30, 30, 14
    'PSET (30, 30), _RGB32(166, 22, 183)
    'Graphics_SetPixel 30, 30, _RGB32(166, 22, 183)

    'Graphics_DrawHorizontalLine 0, 45, 159, Graphics_MakeTextColorAttribute(56, 1, 14)
    'LINE (0, 240)-(639, 240), 14
    'Graphics_DrawHorizontalLine 0, 240, 639, 14
    'LINE (0, 240)-(639, 240), _RGB32(166, 22, 183)
    'Graphics_DrawHorizontalLine 0, 240, 639, _RGB32(166, 22, 183)

    'Graphics_DrawVerticalLine 80, 0, 89, Graphics_MakeTextColorAttribute(56, 1, 14)
    'LINE (320, 0)-(320, 479), 14
    'Graphics_DrawVerticalLine 320, 0, 479, 14
    'LINE (320, 0)-(320, 479), _RGB32(166, 22, 183)
    'Graphics_DrawVerticalLine 320, 0, 479, _RGB32(166, 22, 183)

    'Graphics_DrawLine 0, 0, 159, 89, Graphics_MakeTextColorAttribute(56, 1, 14)
    'LINE (0, 0)-(639, 479), 14
    'Graphics_DrawLine 0, 0, 639, 479, 14
    'LINE (0, 0)-(639, 479), _RGB32(166, 22, 183)
    'Graphics_DrawLine 0, 0, 639, 479, _RGB32(166, 22, 183)

    'Graphics_DrawRectangle 0, 0, 159, 89, Graphics_MakeTextColorAttribute(56, 1, 14)
    'LINE (0, 0)-(639, 479), 14, B
    'Graphics_DrawRectangle 0, 0, 639, 479, 14
    'LINE (0, 0)-(639, 479), _RGB32(166, 22, 183), B
    'Graphics_DrawRectangle 0, 0, 639, 479, _RGB32(166, 22, 183)

    'Graphics_DrawFilledRectangle 0, 0, 159, 89, Graphics_MakeTextColorAttribute(56, 1, 14)
    'LINE (0, 0)-(639, 479), 14, BF
    'Graphics_DrawFilledRectangle 0, 0, 639, 479, 14
    'LINE (0, 0)-(639, 479), _RGB32(166, 22, 183), BF
    'Graphics_DrawFilledRectangle 0, 0, 639, 479, _RGB32(166, 22, 183)

    'Graphics_DrawCircle 80, 45, 40, Graphics_MakeTextColorAttribute(56, 1, 14)
    'CIRCLE (320, 240), 200, 14
    'Graphics_DrawCircle 320, 240, 200, 14
    'CIRCLE (320, 240), 200, _RGB32(166, 22, 183)
    'Graphics_DrawCircle 320, 240, 200, _RGB32(166, 22, 183)

    'Graphics_DrawFilledCircle 80, 45, 40, Graphics_MakeTextColorAttribute(56, 1, 14)
    'Graphics_DrawFilledCircle 320, 240, 200, 14
    'Graphics_DrawFilledCircle 320, 240, 200, _RGB32(166, 22, 183)

    'Graphics_DrawEllipse 80, 45, 60, 40, Graphics_MakeTextColorAttribute(56, 1, 14)
    'Graphics_DrawEllipse 320, 240, 300, 200, 14
    'Graphics_DrawEllipse 320, 240, 300, 200, _RGB32(166, 22, 183)

    'Graphics_DrawFilledEllipse 80, 45, 60, 40, Graphics_MakeTextColorAttribute(56, 1, 14)
    'Graphics_DrawFilledEllipse 320, 240, 300, 200, 14
    'Graphics_DrawFilledEllipse 320, 240, 300, 200, _RGB32(166, 22, 183)

    'Graphics_DrawTriangle 2, 2, 14, 88, 158, 80, Graphics_MakeTextColorAttribute(56, 1, 14)
    'Graphics_DrawTriangle 20, 10, 70, 469, 629, 469, 14
    'Graphics_DrawTriangle 20, 10, 70, 469, 629, 469, _RGB32(166, 22, 183)

    'Graphics_DrawFilledTriangle 2, 2, 14, 88, 158, 80, Graphics_MakeTextColorAttribute(56, 1, 14)
    'Graphics_DrawFilledTriangle 20, 10, 70, 469, 629, 469, 14
    'Graphics_DrawFilledTriangle 20, 10, 70, 469, 629, 469, _RGB32(166, 22, 183)
    'NEXT

    'PRINT USING "###.### seconds to complete."; TIMER - t#

    '_DISPLAY
    'Graphics_DrawFilledTriangle 20, 10, 70, 469, 629, 469, _RGB32(166, 22, 183)
    'Graphics_FadeScreen -1, 60, 100
    'Graphics_DrawLine -40, -50, 639, 479, _RGB32(166, 22, 183)

    'DIM txtImg AS LONG: txtImg = _NEWIMAGE(9, 9, 0)
    'PRINT txtImg

    '_DEST txtImg: _FONT 8 ' Switch to 8x8 font
    'Graphics_DrawFilledCircle 4, 4, 4, Graphics_MakeTextColorAttribute(3, 1, 14)
    'Graphics_DrawFilledRectangle 0, 0, 9, 9, Graphics_MakeTextColorAttribute(3, 1, 14)
    '_DEST 0

    'Graphics_SetTextImageClearColor txtImg, Graphics_MakeTextColorAttribute(3, 1, 14)

    'DO
    '    DIM AS LONG x, y

    '    WHILE _MOUSEINPUT
    '        x = _MOUSEX
    '        y = _MOUSEY
    '    WEND

    '    CLS

    '    IF _PIXELSIZE = 0 THEN
    '        Graphics_PutTextImage txtImg, x - 5, y - 5
    '    ELSE
    '        Graphics_PutTextImage txtImg, x - 36, y - 36
    '    END IF

    '    _DISPLAY

    '    _LIMIT 60
    'LOOP UNTIL _KEYHIT = 27

    'END
    '-------------------------------------------------------------------------------------------------------------------

    ' Converts a web color in hex format to a 32-bit RGB color
    FUNCTION Graphics_GetBGRAFromWebColor~& (webColor AS STRING)
        IF LEN(webColor) <> 6 THEN ERROR ERROR_ILLEGAL_FUNCTION_CALL
        Graphics_GetBGRAFromWebColor = _RGB32(VAL("&H" + LEFT$(webColor, 2)), VAL("&H" + MID$(webColor, 3, 2)), VAL("&H" + RIGHT$(webColor, 2)))
    END FUNCTION


    ' Draws a thick line
    ' xs, ys - start x, y
    ' xe, ye - end x, y
    ' lineWeight - thickness
    ' c - color
    SUB Graphics_DrawThickLine (xs AS SINGLE, ys AS SINGLE, xe AS SINGLE, ye AS SINGLE, lineWeight AS _UNSIGNED INTEGER, c AS _UNSIGNED LONG)
        STATIC colorSample AS LONG ' static, so that we do not allocate an image on every call

        IF colorSample = 0 THEN colorSample = _NEWIMAGE(1, 1, 32) ' done only once

        DIM prevDest AS LONG: prevDest = _DEST
        _DEST colorSample
        PSET (0, 0), c ' set the color
        _DEST prevDest

        DIM a AS SINGLE, x0 AS SINGLE, y0 AS SINGLE
        a = _ATAN2(ye - ys, xe - xs)
        a = a + _PI(0.5!)
        x0 = 0.5! * lineWeight * COS(a)
        y0 = 0.5! * lineWeight * SIN(a)

        _MAPTRIANGLE _SEAMLESS(0, 0)-(0, 0)-(0, 0), colorSample TO(xs - x0, ys - y0)-(xs + x0, ys + y0)-(xe + x0, ye + y0), , _SMOOTH
        _MAPTRIANGLE _SEAMLESS(0, 0)-(0, 0)-(0, 0), colorSample TO(xs - x0, ys - y0)-(xe + x0, ye + y0)-(xe - x0, ye - y0), , _SMOOTH
    END SUB


    ' Fades the screen to / from black
    ' img - image to use. can be the screen or _DEST
    ' isIn - True or False. True is fade in, False is fade out
    ' fps& - speed (updates / second)
    ' stopPercent - %age when to bail out (use for partial fades)
    SUB Graphics_FadeScreen (isIn AS _BYTE, maxFPS AS _UNSIGNED INTEGER, stopPercent AS _BYTE)
        ' TOD0: Add support for palette based screen
        DIM AS LONG tmp, x, y, i
        tmp = _COPYIMAGE(_DEST)
        x = _WIDTH(tmp) - 1
        y = _HEIGHT(tmp) - 1

        FOR i = 0 TO 255
            IF stopPercent < (i * 100) \ 255 THEN EXIT FOR ' bail if < 100% we hit the limit

            _PUTIMAGE , tmp, _DISPLAY ' always stretch and blit to the screen

            IF isIn THEN
                LINE (0, 0)-(x, y), _RGBA32(0, 0, 0, 255 - i), BF
            ELSE
                LINE (0, 0)-(x, y), _RGBA32(0, 0, 0, i), BF
            END IF

            _DISPLAY

            IF maxFPS > 0 THEN _LIMIT maxFPS
        NEXT

        _FREEIMAGE tmp
    END SUB


    '  Loads an image in 8bpp or 32bpp and optionally sets a transparent color
    FUNCTION Graphics_LoadImage& (fileName AS STRING, transparentColor AS _UNSIGNED LONG, is8bpp AS _BYTE, options AS STRING)
        DIM handle AS LONG

        IF is8bpp THEN
            handle = _LOADIMAGE(fileName, 256, options)
        ELSE
            handle = _LOADIMAGE(fileName, , options)
        END IF

        IF handle < -1 THEN _CLEARCOLOR transparentColor, handle

        Graphics_LoadImage = handle
    END FUNCTION

$END IF

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

    '$RESIZE:STRETCH
    'SCREEN 12
    'SCREEN 13
    'SCREEN _NEWIMAGE(640, 480, 32)

    '_BLINK OFF
    'WIDTH 160, 90
    '_FONT 8
    'COLOR 17, 6
    'Graphics_SetForegroundColor 1
    'Graphics_SetBackgroundColor 14

    'PRINT Graphics_GetForegroundColor, Graphics_GetBackgroundColor
    'PRINT _DEFAULTCOLOR, _BACKGROUNDCOLOR

    'PRINT Graphics_MakeTextColorAttribute(56, 1, 14)
    'PRINT Graphics_MakeDefaultTextColorAttribute(56)

    'Graphics_SetPixel 1, 1, Graphics_MakeDefaultTextColorAttribute(56)
    'Graphics_SetPixel 1, 1, 14

    'Graphics_DrawHorizontalLine 0, -10, 500, 14

    'DIM t AS DOUBLE: t = TIMER

    'DIM i AS LONG: FOR i = 1 TO 1000000
    '    CIRCLE (160, 110), 80, 15
    '    CIRCLE (160, 110), 80, _RGB32(166, 22, 183)
    '    Graphics_DrawCircle 160, 110, 80, 15
    '    Graphics_DrawCircle 160, 110, 80, _RGB32(166, 22, 183)
    '    Graphics_DrawCircle 50, 35, 25, Graphics_MakeTextColorAttribute(56, 1, 14)
    '    Graphics_DrawFilledCircle 160, 100, 100, 15
    '    Graphics_DrawFilledCircle 80, 45, 40, Graphics_MakeTextColorAttribute(56, 1, 14)
    '    LINE (0, 0)-(159, 89), 14, B
    '    Graphics_DrawRectangle 0, 0, 159, 89, 14
    '    Graphics_DrawRectangle 0, 0, 159, 89, _RGB32(166, 22, 183)
    '    Graphics_DrawRectangle 0, 0, 159, 89, Graphics_MakeTextColorAttribute(56, 1, 14)
    '    LINE (0, 0)-(159, 89), 15, BF
    '    LINE (0, 0)-(159, 89), _RGB32(166, 22, 183), BF
    '    Graphics_DrawFilledRectangle 0, 0, 159, 89, 15
    '    Graphics_DrawFilledRectangle 0, 0, 159, 89, _RGB32(166, 22, 183)
    '    Graphics_DrawFilledRectangle 0, 0, 159, 89, Graphics_MakeTextColorAttribute(56, 1, 14)
    '    LINE (0, 0)-(319, 199), 15
    '    Graphics_DrawLine 0, 0, 319, 199, 15
    '    Graphics_DrawLine 0, 0, 159, 89, Graphics_MakeTextColorAttribute(56, 1, 14)
    'NEXT

    'PRINT USING "###.### seconds to complete."; TIMER - t#

    'END
    '-------------------------------------------------------------------------------------------------------------------


    ' Draws a filled ellipse
    ' cx = center x coordinate
    ' cy = center y coordinate
    ' a = semimajor axis
    ' b = semiminor axis
    ' c = fill color
    SUB EllipseFill (cx AS INTEGER, cy AS INTEGER, a AS INTEGER, b AS INTEGER, c AS _UNSIGNED LONG)
        IF a = 0 OR b = 0 THEN EXIT SUB

        DIM AS _INTEGER64 h2, w2, h2w2
        DIM AS LONG x, y

        w2 = a * a
        h2 = b * b
        h2w2 = h2 * w2
        LINE (cx - a, cy)-(cx + a, cy), c, BF
        DO WHILE y < b
            y = y + 1
            x = SQR((h2w2 - y * y * w2) \ h2)
            LINE (cx - x, cy + y)-(cx + x, cy + y), c, BF
            LINE (cx - x, cy - y)-(cx + x, cy - y), c, BF
        LOOP
    END SUB


    ' Draws a thick line
    ' xs, ys - start x, y
    ' xe, ye - end x, y
    ' lineWeight - thickness
    ' c - color
    SUB LineThick (xs AS SINGLE, ys AS SINGLE, xe AS SINGLE, ye AS SINGLE, lineWeight AS _UNSIGNED INTEGER, c AS _UNSIGNED LONG)
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
    SUB FadeScreen (img AS LONG, isIn AS _BYTE, maxFPS AS _UNSIGNED INTEGER, stopPercent AS _BYTE)
        ' TOD0: Add support for palette based screen
        DIM AS LONG tmp, x, y, i
        tmp = _COPYIMAGE(img)
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

            _LIMIT maxFPS
        NEXT

        _FREEIMAGE tmp
    END SUB


    '  Loads an image in 8bpp or 32bpp and optionally sets a transparent color
    FUNCTION LoadImageTransparent& (fileName AS STRING, transparentColor AS _UNSIGNED LONG, is8bpp AS _BYTE, options AS STRING)
        DIM handle AS LONG

        IF is8bpp THEN
            handle = _LOADIMAGE(fileName, 256, options)
        ELSE
            handle = _LOADIMAGE(fileName, , options)
        END IF

        IF handle < -1 THEN _CLEARCOLOR transparentColor, handle

        LoadImageTransparent = handle
    END FUNCTION

$END IF

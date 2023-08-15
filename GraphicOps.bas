'-----------------------------------------------------------------------------------------------------------------------
' Extended graphics routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF GRAPHICOPS_BAS = UNDEFINED THEN
    $LET GRAPHICOPS_BAS = TRUE

    '$INCLUDE:'Common.bi'

    ' Draws a filled circle
    ' cx, cy - circle center x, y
    ' r - circle radius
    ' c - color
    SUB CircleFill (cx AS LONG, cy AS LONG, r AS LONG, c AS _UNSIGNED LONG)
        DIM AS LONG radius, radiusError, x, y

        radius = ABS(r)
        radiusError = -radius
        x = radius ' Y = 0

        IF radius = 0 THEN
            PSET (cx, cy), c
            EXIT SUB
        END IF

        LINE (cx - x, cy)-(cx + x, cy), c, BF

        WHILE x > y
            radiusError = radiusError + y * 2 + 1

            IF radiusError >= 0 THEN
                IF x <> y + 1 THEN
                    LINE (cx - y, cy - x)-(cx + y, cy - x), c, BF
                    LINE (cx - y, cy + x)-(cx + y, cy + x), c, BF
                END IF
                x = x - 1
                radiusError = radiusError - x * 2
            END IF

            y = y + 1

            LINE (cx - x, cy - y)-(cx + x, cy - y), c, BF
            LINE (cx - x, cy + y)-(cx + x, cy + y), c, BF
        WEND
    END SUB


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

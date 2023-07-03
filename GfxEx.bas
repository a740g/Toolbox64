'-----------------------------------------------------------------------------------------------------------------------
' Extended graphics routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF GFXEX_BI = UNDEFINED THEN
    $LET GFXEX_BI = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' HEADER FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'CRTLib.bi'
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
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


    ' Draws a filled circle using _DEFAULTCOLOR
    ' cx, cy - circle center x, y
    ' R - circle radius
    SUB CircleFill (cx AS LONG, cy AS LONG, r AS LONG)
        DIM AS LONG radius, radiusError, X, Y

        radius = ABS(r)
        radiusError = -radius
        X = radius ' Y = 0

        IF radius = 0 THEN
            PSET (cx, cy)
            EXIT SUB
        END IF

        LINE (cx - X, cy)-(cx + X, cy), , BF

        WHILE X > Y
            radiusError = radiusError + Y * 2 + 1

            IF radiusError >= 0 THEN
                IF X <> Y + 1 THEN
                    LINE (cx - Y, cy - X)-(cx + Y, cy - X), , BF
                    LINE (cx - Y, cy + X)-(cx + Y, cy + X), , BF
                END IF
                X = X - 1
                radiusError = radiusError - X * 2
            END IF

            Y = Y + 1

            LINE (cx - X, cy - Y)-(cx + X, cy - Y), , BF
            LINE (cx - X, cy + Y)-(cx + X, cy + Y), , BF
        WEND
    END SUB


    ' Draws a thick line
    ' xs, ys - start x, y
    ' xe, ye - end x, y
    ' lineWeight - thickness
    SUB LineThick (xs AS SINGLE, ys AS SINGLE, xe AS SINGLE, ye AS SINGLE, lineWeight AS _UNSIGNED INTEGER)
        STATIC colorSample AS LONG ' static, so that we do not allocate an image on every call

        IF colorSample = 0 THEN colorSample = _NEWIMAGE(1, 1, 32) ' done only once

        DIM prevDest AS LONG: prevDest = _DEST
        _DEST colorSample
        PSET (0, 0) ' set it to _DEFAULTCOLOR
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

    ' Converts a web color in hex format to a 32-bit RGB color
    FUNCTION HexToRGB32~& (hexColor AS STRING)
        IF LEN(hexColor) <> 6 THEN ERROR 17
        HexToRGB32 = _RGB32(VAL("&H" + LEFT$(hexColor, 2)), VAL("&H" + MID$(hexColor, 3, 2)), VAL("&H" + RIGHT$(hexColor, 2)))
    END FUNCTION
    '-------------------------------------------------------------------------------------------------------------------
$END IF
'-----------------------------------------------------------------------------------------------------------------------

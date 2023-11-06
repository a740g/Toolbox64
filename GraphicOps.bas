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

    '_DISPLAY

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

    'Graphics_FadeScreen TRUE, 60, 100

    'END
    '-------------------------------------------------------------------------------------------------------------------

    ' Converts a web color in hex format to a 32-bit RGB color
    FUNCTION Graphics_GetBGRAFromWebColor~& (webColor AS STRING)
        IF LEN(webColor) <> 6 THEN ERROR ERROR_ILLEGAL_FUNCTION_CALL
        Graphics_GetBGRAFromWebColor = Graphics_MakeBGRA(VAL("&H" + LEFT$(webColor, 2)), VAL("&H" + MID$(webColor, 3, 2)), VAL("&H" + RIGHT$(webColor, 2)), 255)
    END FUNCTION


    ' This will progressively change the palette of dstImg to that of srcImg
    ' Keep calling this repeatedly until it returns true
    FUNCTION Graphics_MorphPalette%% (dstImage AS LONG, srcImage AS LONG, startIndex AS _UNSIGNED _BYTE, stopIndex AS _UNSIGNED _BYTE)
        Graphics_MorphPalette = TRUE ' Assume completed

        DIM i AS LONG: FOR i = startIndex TO stopIndex
            ' Get both src and dst colors of the current index
            DIM srcColor AS _UNSIGNED LONG: srcColor = _PALETTECOLOR(i, srcImage)
            DIM dstColor AS _UNSIGNED LONG: dstColor = _PALETTECOLOR(i, dstImage)

            ' Break down the colors into individual components
            DIM srcR AS _UNSIGNED _BYTE: srcR = _RED32(srcColor)
            DIM srcG AS _UNSIGNED _BYTE: srcG = _GREEN32(srcColor)
            DIM srcB AS _UNSIGNED _BYTE: srcB = _BLUE32(srcColor)
            DIM dstR AS _UNSIGNED _BYTE: dstR = _RED32(dstColor)
            DIM dstG AS _UNSIGNED _BYTE: dstG = _GREEN32(dstColor)
            DIM dstB AS _UNSIGNED _BYTE: dstB = _BLUE32(dstColor)

            ' Change red
            IF dstR < srcR THEN
                Graphics_MorphPalette = FALSE
                dstR = dstR + 1
            ELSEIF dstR > srcR THEN
                Graphics_MorphPalette = FALSE
                dstR = dstR - 1
            END IF

            ' Change green
            IF dstG < srcG THEN
                Graphics_MorphPalette = FALSE
                dstG = dstG + 1
            ELSEIF dstG > srcG THEN
                Graphics_MorphPalette = FALSE
                dstG = dstG - 1
            END IF

            ' Change blue
            IF dstB < srcB THEN
                Graphics_MorphPalette = FALSE
                dstB = dstB + 1
            ELSEIF dstB > srcB THEN
                Graphics_MorphPalette = FALSE
                dstB = dstB - 1
            END IF

            ' Set the palette index color
            _PALETTECOLOR i, Graphics_MakeBGRA(dstR, dstG, dstB, 255), dstImage
        NEXT i
    END FUNCTION


    ' Rotates an image palette left or right
    SUB Graphics_RotatePalette (dstImage AS LONG, isForward AS _BYTE, startIndex AS _UNSIGNED _BYTE, stopIndex AS _UNSIGNED _BYTE)
        IF stopIndex > startIndex THEN
            DIM tempColor AS _UNSIGNED LONG, i AS LONG

            IF isForward THEN
                ' Save the last color
                tempColor = _PALETTECOLOR(stopIndex, dstImage)

                ' Shift places for the remaining colors
                FOR i = stopIndex TO startIndex + 1 STEP -1
                    _PALETTECOLOR i, _PALETTECOLOR(i - 1, dstImage), dstImage
                NEXT i

                ' Set first to last
                _PALETTECOLOR startIndex, tempColor, dstImage
            ELSE
                ' Save the first color
                tempColor = _PALETTECOLOR(startIndex, dstImage)

                ' Shift places for the remaining colors
                FOR i = startIndex TO stopIndex - 1
                    _PALETTECOLOR i, _PALETTECOLOR(i + 1, dstImage), dstImage
                NEXT i

                ' Set last to first
                _PALETTECOLOR stopIndex, tempColor, dstImage
            END IF
        END IF
    END SUB


    ' Sets the complete palette to a single color
    SUB Graphics_ResetPalette (dstImage AS LONG, resetColor AS _UNSIGNED LONG)
        DIM i AS LONG: FOR i = 0 TO 255
            _PALETTECOLOR i, resetColor, dstImage
        NEXT i
    END SUB


    ' Fades the current _DEST to the screen to / from black (works on all kinds of screen)
    ' Note for paletted display the display palette will be modified
    ' img - image to use. can be the screen or _DEST
    ' isIn - True or False. True is fade in, False is fade out
    ' fps& - speed (updates / second)
    ' stopPercent - %age when to bail out (use for partial fades)
    SUB Graphics_FadeScreen (isIn AS _BYTE, maxFPS AS _UNSIGNED INTEGER, stopPercent AS _BYTE)
        DIM AS LONG dspImg, tmpImg, oldDest

        dspImg = _DISPLAY ' Get the image handle of the screen being displayed

        SELECT CASE _PIXELSIZE(dspImg)
            CASE 0, 1 ' Text mode and other index graphics screens. We'll simply fade the image palette in either direction based on isIn
                ' Make a copy of the destination image along with the palette
                tmpImg = _COPYIMAGE(_DEST)

                IF isIn THEN
                    ' If we are fading in the just reset the display image to all black
                    Graphics_ResetPalette dspImg, BGRA_BLACK
                ELSE
                    ' If we are fading out then first copy the image pallete to the display and then reset the image paletter to all black
                    _COPYPALETTE tmpImg, dspImg
                    Graphics_ResetPalette tmpImg, BGRA_BLACK
                END IF

                oldDest = _DEST ' Save the old destination
                _DEST _DISPLAY ' Set destination to the screen

                ' Stretch and blit the image to the screen just once
                IF _PIXELSIZE(dspImg) = 0 THEN
                    Graphics_PutTextImage tmpImg, 0, 0 ' _PutImage cannot blit text images
                ELSE
                    _PUTIMAGE , tmpImg, _DISPLAY
                END IF

                DO
                    ' Change the palette in small increments
                    DIM done AS _BYTE: done = Graphics_MorphPalette(dspImg, tmpImg, 0, 255)

                    _DISPLAY

                    IF maxFPS > 0 THEN _LIMIT maxFPS
                LOOP UNTIL done

                _DEST oldDest ' Restore destination

                _FREEIMAGE tmpImg
            CASE ELSE ' 32bpp BGRA graphics. We'll draw a filled rectangle over the screen with varying aplha values
                ' Make a copy of the destination image
                tmpImg = _COPYIMAGE(_DEST)

                DIM maxX AS LONG: maxX = _WIDTH(tmpImg) - 1
                DIM maxY AS LONG: maxY = _HEIGHT(tmpImg) - 1

                DIM i AS LONG: FOR i = 0 TO 255
                    IF stopPercent < (i * 100) \ 255 THEN EXIT FOR ' bail if < 100% we hit the limit

                    ' Stretch and blit the image to the screen
                    _PUTIMAGE , tmpImg, _DISPLAY

                    IF isIn THEN
                        'LINE (0, 0)-(maxX, maxY), _RGBA32(0, 0, 0, 255 - i), BF
                        Graphics_DrawFilledRectangle 0, 0, maxX, maxY, Graphics_MakeBGRA(0, 0, 0, 255 - i)
                    ELSE
                        'LINE (0, 0)-(maxX, maxY), _RGBA32(0, 0, 0, i), BF
                        Graphics_DrawFilledRectangle 0, 0, maxX, maxY, Graphics_MakeBGRA(0, 0, 0, i)
                    END IF

                    _DISPLAY

                    IF maxFPS > 0 THEN _LIMIT maxFPS
                NEXT i

                _FREEIMAGE tmpImg
        END SELECT
    END SUB


    ' Loads an image and returns and image handle
    ' fileName - filename or memory buffer of the image
    ' is8bpp - image will be loaded as an 8-bit image if this is true (not supported by hardware images)
    ' isHardware - image will be loaded as a hardware image (is8bpp must not be true for this to work)
    ' otherOptions - other image loading options like "memory", "adaptive" and the various image scalers
    ' transparentColor - if this is >= 0 then the color specified by this becomes the transparency color key
    FUNCTION Graphics_LoadImage& (fileName AS STRING, is8bpp AS _BYTE, isHardware AS _BYTE, otherOptions AS STRING, transparentColor AS _INTEGER64)
        DIM handle AS LONG

        IF is8bpp THEN
            handle = _LOADIMAGE(fileName, 256, otherOptions)
        ELSE
            handle = _LOADIMAGE(fileName, 32, otherOptions)
        END IF

        IF handle < -1 THEN
            IF transparentColor >= 0 THEN _CLEARCOLOR transparentColor, handle

            IF isHardware THEN
                DIM handleHW AS LONG: handleHW = _COPYIMAGE(handle, 33)
                _FREEIMAGE handle
                handle = handleHW
            END IF
        END IF

        Graphics_LoadImage = handle
    END FUNCTION

$END IF

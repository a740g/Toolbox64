'-----------------------------------------------------------------------------------------------------------------------
' VGA Font Library
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF VGAFONT_BAS = UNDEFINED THEN
    $LET VGAFONT_BAS = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' HEADER FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'VGAFont.bi'
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
    ' Draws a single character at x, y using the active font
    SUB DrawCharacter (cp AS _UNSIGNED _BYTE, x AS LONG, y AS LONG)
        $CHECKING:OFF
        SHARED __CurPSF AS PSFType
        DIM AS LONG uy, r, t, p, bc, pm

        r = x + __CurPSF.size.x - 1 ' calculate right just once

        bc = _BACKGROUNDCOLOR
        pm = _PRINTMODE

        ' Go through the scan line one at a time
        FOR uy = 1 TO __CurPSF.size.y
            ' Get the scan line and pepare it
            p = ASC(__CurPSF.bitmap, __CurPSF.size.y * cp + uy)
            p = 256 * (p + (256 * (p > 127)))
            ' Draw the line
            t = y + uy - 1
            IF pm = 3 THEN LINE (x, t)-(r, t), bc
            LINE (x, t)-(r, t), , , p
        NEXT
        $CHECKING:ON
    END SUB


    ' Draws a string at x, y using the active font
    SUB DrawString (text AS STRING, x AS LONG, y AS LONG)
        $CHECKING:OFF
        SHARED __CurPSF AS PSFType
        DIM AS LONG uy, l, r, t, p, cidx, bc, pm, cp

        bc = _BACKGROUNDCOLOR
        pm = _PRINTMODE

        ' We will iterate through the whole text
        FOR cidx = 1 TO LEN(text)
            cp = ASC(text, cidx) ' find the character to draw
            l = x + (cidx - 1) * __CurPSF.size.x ' calculate the starting x position for this character
            r = l + __CurPSF.size.x - 1 ' calculate right
            ' Next go through each scan line and draw those
            FOR uy = 1 TO __CurPSF.size.y
                ' Get the scan line and prepare it
                p = ASC(__CurPSF.bitmap, __CurPSF.size.y * cp + uy)
                p = 256 * (p + (256 * (p > 127)))
                ' Draw the scan line
                t = y + uy - 1
                IF pm = 3 THEN LINE (l, t)-(r, t), bc
                LINE (l, t)-(r, t), , , p
            NEXT
        NEXT
        $CHECKING:ON
    END SUB


    ' Returns the current font width
    FUNCTION GetFontWidth~%%
        $CHECKING:OFF
        SHARED __CurPSF AS PSFType
        GetFontWidth = __CurPSF.size.x
        $CHECKING:ON
    END FUNCTION


    ' Returns the current font height
    FUNCTION GetFontHeight~%%
        $CHECKING:OFF
        SHARED __CurPSF AS PSFType
        GetFontHeight = __CurPSF.size.y
        $CHECKING:ON
    END FUNCTION


    ' Return the onsreen length of a string in pixels
    FUNCTION GetDrawStringWidth& (text AS STRING)
        $CHECKING:OFF
        SHARED __CurPSF AS PSFType
        GetDrawStringWidth = LEN(text) * __CurPSF.size.x
        $CHECKING:ON
    END FUNCTION


    ' Set the active font
    SUB SetCurrentFont (psf AS PSFType)
        $CHECKING:OFF
        SHARED __CurPSF AS PSFType
        __CurPSF = psf
        $CHECKING:ON
    END SUB


    ' Loads a font file from disk
    FUNCTION ReadFont%% (sFile AS STRING, ignoreMode AS _BYTE, psf AS PSFType)
        IF _FILEEXISTS(sFile) THEN
            DIM AS LONG hFile

            ' Open the file for reading
            hFile = FREEFILE
            OPEN sFile FOR BINARY ACCESS READ AS hFile

            ' Check font magic id
            IF INPUT$(2, hFile) <> CHR$(PSF1_MAGIC0) + CHR$(PSF1_MAGIC1) THEN
                CLOSE hFile
                EXIT FUNCTION
            END IF

            DIM i AS LONG

            ' Read special mode value and ignore only if specified
            i = ASC(INPUT$(1, hFile))
            IF NOT ignoreMode AND i <> 0 THEN
                CLOSE hFile
                EXIT FUNCTION
            END IF

            ' Check font height
            i = ASC(INPUT$(1, hFile))
            IF i = 0 THEN
                CLOSE hFile
                EXIT FUNCTION
            END IF

            psf.size.x = 8 ' the width is always 8 for PSFv1
            psf.size.y = i ' change the font height
            psf.bitmap = INPUT$(256 * psf.size.y, hFile) ' the bitmap data in one go

            CLOSE hFile

            ReadFont = TRUE
        END IF
    END FUNCTION


    ' Changes the font height of the active font
    ' This will wipe out whatever bitmap the font already has
    SUB SetFontHeight (h AS _UNSIGNED _BYTE)
        SHARED __CurPSF AS PSFType
        __CurPSF.size.x = 8 ' the width is always 8 for PSFv1
        __CurPSF.size.y = h ' change the font height
        __CurPSF.bitmap = STRING$(256 * __CurPSF.size.y, NULL) ' just allocate enough space for the bitmap

        ' Load default glyphs
        DIM i AS LONG
        FOR i = 0 TO 255
            SetGlyphDefaultBitmap i
        NEXT
    END SUB


    ' Returns the entire bitmap of a glyph in a string
    FUNCTION GetGlyphBitmap$ (cp AS _UNSIGNED _BYTE)
        SHARED __CurPSF AS PSFType
        GetGlyphBitmap = MID$(__CurPSF.bitmap, 1 + __CurPSF.size.y * cp, __CurPSF.size.y)
    END FUNCTION


    ' Sets the entire bitmap of a glyph with bmp
    SUB SetGlyphBitmap (cp AS _UNSIGNED _BYTE, bmp AS STRING)
        SHARED __CurPSF AS PSFType
        MID$(__CurPSF.bitmap, 1 + __CurPSF.size.y * cp, __CurPSF.size.y) = bmp
    END SUB


    ' Set the glyph's bitmap to QB64's current font glyph
    SUB SetGlyphDefaultBitmap (cp AS _UNSIGNED _BYTE)
        SHARED __CurPSF AS PSFType

        DIM img AS LONG: img = _NEWIMAGE(_FONTWIDTH, _FONTHEIGHT, 32)
        IF img >= -1 THEN EXIT SUB ' leave if we failed to allocate the image

        DIM dst AS LONG: dst = _DEST ' save dest
        _DEST img ' set img as dest

        DIM f AS LONG: f = _FONT ' save the current font

        ' Select the best builtin font to use
        SELECT CASE __CurPSF.size.y
            CASE IS > 15
                _FONT 16

            CASE IS > 13
                _FONT 14

            CASE ELSE
                _FONT 8
        END SELECT

        _PRINTSTRING (0, 0), CHR$(cp) ' render the glyph to our image

        ' Find the starting x, y on the font bitmap where we should start to render
        DIM sx AS LONG: sx = __CurPSF.size.x \ 2 - _FONTWIDTH \ 2
        DIM sy AS LONG: sy = __CurPSF.size.y \ 2 - _FONTHEIGHT \ 2

        DIM src AS LONG: src = _SOURCE ' save the old source
        _SOURCE img ' change source to img

        ' Copy the QB64 glyph
        DIM AS LONG x, y
        FOR y = 0 TO _FONTHEIGHT - 1
            FOR x = 0 TO _FONTWIDTH - 1
                SetGlyphPixel cp, sx + x, sy + y, POINT(x, y) <> 4278190080 ' black
            NEXT
        NEXT

        _SOURCE src ' restore source
        _FONT f ' restore font
        _DEST dst
        _FREEIMAGE img ' free img
    END SUB


    ' Return true if the pixel-bit at the glyphs x, y is set
    FUNCTION GetGlyphPixel%% (cp AS _UNSIGNED _BYTE, x AS LONG, y AS LONG)
        SHARED __CurPSF AS PSFType

        IF x < 0 OR x >= __CurPSF.size.x OR y < 0 OR y >= __CurPSF.size.y THEN EXIT FUNCTION

        GetGlyphPixel = _READBIT(ASC(__CurPSF.bitmap, __CurPSF.size.y * cp + y + 1), __CurPSF.size.x - x - 1)
    END FUNCTION


    ' Sets or unsets pixel at the glyphs x, y
    SUB SetGlyphPixel (cp AS _UNSIGNED _BYTE, x AS LONG, y AS LONG, b AS _BYTE)
        SHARED __CurPSF AS PSFType

        IF x < 0 OR x >= __CurPSF.size.x OR y < 0 OR y >= __CurPSF.size.y THEN EXIT SUB

        IF NOT b THEN
            ASC(__CurPSF.bitmap, __CurPSF.size.y * cp + y + 1) = _RESETBIT(ASC(__CurPSF.bitmap, __CurPSF.size.y * cp + y + 1), __CurPSF.size.x - x - 1)
        ELSE
            ASC(__CurPSF.bitmap, __CurPSF.size.y * cp + y + 1) = _SETBIT(ASC(__CurPSF.bitmap, __CurPSF.size.y * cp + y + 1), __CurPSF.size.x - x - 1)
        END IF
    END SUB


    ' Saves the current font to disk in PSF v1 format
    ' This does not check if the file exists or whatever and will happily overwrite it
    ' It is the caller's resposibility to check this stuff
    FUNCTION WriteFont%% (sFile AS STRING)
        SHARED __CurPSF AS PSFType

        IF __CurPSF.size.x > 0 AND __CurPSF.size.y > 0 AND LEN(__CurPSF.bitmap) = 256 * __CurPSF.size.y THEN ' check if the font is valid
            DIM AS LONG hFile

            ' Open the file for writing
            hFile = FREEFILE
            OPEN sFile FOR BINARY ACCESS WRITE AS hFile

            DIM buffer AS STRING

            ' Write font id
            buffer = CHR$(PSF1_MAGIC0) + CHR$(PSF1_MAGIC1)
            PUT hFile, , buffer

            ' Write mode as zero
            buffer = CHR$(NULL)
            PUT hFile, , buffer

            ' Write font height
            buffer = CHR$(__CurPSF.size.y)
            PUT hFile, , buffer

            PUT hFile, , __CurPSF.bitmap ' write the font data

            CLOSE hFile

            WriteFont = TRUE
        END IF
    END FUNCTION
    '-------------------------------------------------------------------------------------------------------------------
$END IF
'-----------------------------------------------------------------------------------------------------------------------

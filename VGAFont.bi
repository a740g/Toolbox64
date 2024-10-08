'-----------------------------------------------------------------------------------------------------------------------
' VGA Font Library
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'
'$INCLUDE:'Types.bi'
'$INCLUDE:'File.bi'

' PSF1 file ID
CONST __PSF1_MAGIC0 = &H36
CONST __PSF1_MAGIC1 = &H04
' Fixed font metrics
CONST PSF1_FONT_WIDTH = 8

' An in-memory PSF representation
TYPE PSF1Type
    size AS Vector2LType ' this just holds the font width and height
    bitmap AS STRING ' a variable length string that holds the bitmap of all glyphs in the font
END TYPE

DIM __CurPSF AS PSF1Type ' the active font

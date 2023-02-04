'-----------------------------------------------------------------------------------------------------
'
' <name>
' Copyright (c) <year> Samuel Gomes
'
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------
'$Include:'CRTLib.bi'
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' METACOMMANDS
'-----------------------------------------------------------------------------------------------------
' For text mode programs, uncomment the lines below
$Asserts
'$Console
'$ScreenHide
' Icon and version info stuff
'$ExeIcon:'.\icon.ico'
'$VersionInfo:CompanyName=Samuel Gomes
'$VersionInfo:FileDescription=Template executable
'$VersionInfo:InternalName=template
'$VersionInfo:LegalCopyright=Copyright (c) 2022, Samuel Gomes
'$VersionInfo:LegalTrademarks=All trademarks are property of their respective owners
'$VersionInfo:OriginalFilename=template.exe
'$VersionInfo:ProductName=Template
'$VersionInfo:Web=https://github.com/a740g
'$VersionInfo:Comments=https://github.com/a740g
'$VersionInfo:FILEVERSION#=1,2,3,0
'$VersionInfo:PRODUCTVERSION#=1,2,0,0
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------
' App name
Const APP_NAME = "Template"
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' USER DEFINED TYPES
'-----------------------------------------------------------------------------------------------------
Type Vector2DType
    x As Long
    y As Long
End Type

Type Vector3DType
    x As Single
    y As Single
    z As Single
End Type

Type RectangleType
    a As Vector2DType
    b As Vector2DType
End Type

Type CircleType
    position As Vector2DType
    radius As Long
End Type

Type RGBType
    r As Unsigned Byte
    g As Unsigned Byte
    b As Unsigned Byte
End Type

Type RGBAType
    r As Unsigned Byte
    g As Unsigned Byte
    b As Unsigned Byte
    a As Unsigned Byte
End Type

Type SpriteType
    isActive As Byte ' is this sprite active / in use?
    position As Vector2DType ' (left, top) position of the sprite on the 2D plane
    size As Vector2DType ' size of the sprite
    velocity As Vector2DType ' velocity of the sprite
    boundary As RectangleType ' sprite should not leave this area
    shouldDraw As Byte ' do we need to draw the sprite?
    objSpec1 As Long ' special data 1
    objSpec2 As Long ' special data 2
End Type
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' EXTERNAL LIBRARIES
'-----------------------------------------------------------------------------------------------------
Declare CustomType Library

End Declare
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT
'-----------------------------------------------------------------------------------------------------

End
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'-----------------------------------------------------------------------------------------------------
' This works around the QB SCREEN 0 high intensity background nonsense
' c is the color (0 to 15) for paletted destinations or 32-bit RGB for true color destinations
' isBackGround can be set to true when setting the background color
Sub SetColor (c As Unsigned Long, isBackground As Long)
    If PixelSize = 0 Then ' text mode
        If isBackground Then
            Color DefaultColor Mod 16 + (-16 * (c > 7)), c Mod 8
        Else
            Color c
        End If
    Else ' graphics mode
        If isBackground Then
            Color , c
        Else
            Color c
        End If
    End If
End Sub


' This works around the QB SCREEN 0 high intensity background nonsense
' isBackGround can be set to true when getting the background color
Function GetColor~& (isBackground As Long)
    If PixelSize = 0 Then
        If isBackground Then
            GetColor = BackgroundColor + (-8 * (DefaultColor > 15))
        Else
            GetColor = DefaultColor Mod 16
        End If
    Else
        If isBackground Then
            GetColor = BackgroundColor
        Else
            GetColor = DefaultColor
        End If
    End If
End Function


' Returns the number of characters per line
Function TextScreenWidth&
    If PixelSize = 0 Then
        TextScreenWidth = Width
    Else
        TextScreenWidth = Width \ FontWidth ' this will cause a divide by zero if a variable width font is used; use fixed width fonts instead
    End If
End Function


' Returns the number of lines
Function TextScreenHeight&
    If PixelSize = 0 Then
        TextScreenHeight = Height
    Else
        TextScreenHeight = Height \ FontHeight
    End If
End Function


' Calculates and returns the FPS when repeatedly called inside a loop
Function CalculateFPS~&
    Static As Unsigned Long counter, finalFPS
    Static lastTime As Integer64
    Dim currentTime As Integer64

    counter = counter + 1

    currentTime = GetTicks
    If currentTime > lastTime + 1000 Then
        lastTime = currentTime
        finalFPS = counter
        counter = 0
    End If

    CalculateFPS = finalFPS
End Function

' Draws the sprite on the framebuffer
Sub DrawSprite (s As SpriteType)
    Line (s.position.x, s.position.y)-(s.position.x + s.size.x - 1, s.position.y + s.size.y - 1), s.objSpec1, BF
End Sub


' This moves the sprite based on the velocity and if there is a boundary specified then keeps it confined
Sub UpdateSprite (s As SpriteType)
    ' First move the sprite
    s.position.x = s.position.x + s.velocity.x
    s.position.y = s.position.y + s.velocity.y

    ' Next limit movement if boundary is specified
    If s.boundary.b.x > s.boundary.a.x Then
        If s.position.x < s.boundary.a.x Then s.position.x = s.boundary.a.x
        If s.position.x > s.boundary.b.x - s.size.x Then s.position.x = s.boundary.b.x - s.size.x
    End If
    If s.boundary.b.y > s.boundary.a.y Then
        If s.position.y < s.boundary.a.y Then s.position.y = s.boundary.a.y
        If s.position.y > s.boundary.b.y - s.size.y Then s.position.y = s.boundary.b.y - s.size.y
    End If
End Sub


'text$ is the text that we wish to transform into an image.
'font& is the handle of the font we want to use.
'fc& is the color of the font we want to use.
'bfc& is the background color of the font.
'Mode 1 is print forwards
'Mode 2 is print backwards
'Mode 3 is print from top to bottom
'Mode 4 is print from bottom up
'Mode 0 got lost somewhere, but it's OK.  We check to see if our mode is < 1 or > 4 and compensate automatically if it is to make it one (default).
Function TextToImage& (text As String, fnt As Long, fc As Unsigned Long, bc As Unsigned Long, mode As Long)
    Dim As Unsigned Long oldFC, oldBC, w, h
    Dim As Long oldDest, oldFont, oldX, oldY, i, image
    Dim tmpStr As String

    ' Save some stuff we'll need to restore later
    oldFC = DefaultColor
    oldBC = BackgroundColor
    oldDest = Dest
    oldFont = Font
    oldX = Pos(0)
    oldY = CsrLin

    If fnt <> 0 Then Font fnt

    If mode < 3 Then
        'print the text lengthwise
        w = PrintWidth(text)
        h = FontHeight
    Else
        'print the text vertically
        For i = 1 To Len(text)
            If w < PrintWidth(Mid$(text, i, 1)) Then w = PrintWidth(Mid$(text, i, 1))
        Next

        h = FontHeight * (Len(text))
    End If

    image = NewImage(w, h, 32)
    TextToImage = image

    Dest image
    If fnt <> 0 Then Font fnt

    Color fc, bc

    Select Case mode
        Case 2
            'Print text backwards
            For i = 0 To Len(text) - 1
                tmpStr = tmpStr + Mid$(text, Len(text) - i, 1)
            Next
            PrintString (0, 0), tmpStr

        Case 3
            'Print text upwards
            'first lets reverse the text, so it's easy to place
            For i = 0 To Len(text) - 1
                tmpStr = tmpStr + Mid$(text$, Len(text) - i, 1)
            Next

            'then put it where it belongs
            For i = 1 To Len(text)
                'This is to center any non-monospaced letters so they look better
                PrintString ((w - PrintWidth(Mid$(tmpStr, i, 1))) / 2 + .99, FontHeight * (i - 1)), Mid$(tmpStr, i, 1)
            Next

        Case 4
            'Print text downwards
            For i = 1 To Len(text$)
                'This is to center any non-monospaced letters so they look better
                PrintString ((w - PrintWidth(Mid$(tmpStr, i, 1))) / 2 + .99, FontHeight * (i - 1)), Mid$(tmpStr, i, 1)
            Next

        Case Else
            'Print text forward
            PrintString (0, 0), text
    End Select

    ' Restore things we have changed
    Dest oldDest
    Color oldFC, oldBC
    Font oldFont
    Locate oldY, oldX
End Function


'Image is the image handle which we use to reference our image.
'x,y is the X/Y coordinates where we want the image to be at on the screen.
'angle is the angle which we wish to rotate the image.
'mode determines HOW we place the image at point X,Y.
'Mode 0 we center the image at point X,Y
'Mode 1 we place the Top Left corner of oour image at point X,Y
'Mode 2 is Bottom Left
'Mode 3 is Top Right
'Mode 4 is Bottom Right
Sub DisplayImage (Image As Long, x As Long, y As Long, xscale As Single, yscale As Single, angle As Single, mode As Long)
    Dim As Long px(0 To 3), py(0 To 3), w, h, i
    Dim As Single x2, y2, sinr, cosr

    w = Width(Image)
    h = Height(Image)

    Select Case mode
        Case 0 'center
            px(0) = -w \ 2: py(0) = -h \ 2: px(3) = w \ 2: py(3) = -h \ 2
            px(1) = -w \ 2: py(1) = h \ 2: px(2) = w \ 2: py(2) = h \ 2
        Case 1 'top left
            px(0) = 0: py(0) = 0: px(3) = w: py(3) = 0
            px(1) = 0: py(1) = h: px(2) = w: py(2) = h
        Case 2 'bottom left
            px(0) = 0: py(0) = -h: px(3) = w: py(3) = -h
            px(1) = 0: py(1) = 0: px(2) = w: py(2) = 0
        Case 3 'top right
            px(0) = -w: py(0) = 0: px(3) = 0: py(3) = 0
            px(1) = -w: py(1) = h: px(2) = 0: py(2) = h
        Case 4 'bottom right
            px(0) = -w: py(0) = -h: px(3) = 0: py(3) = -h
            px(1) = -w: py(1) = 0: px(2) = 0: py(2) = 0
    End Select

    sinr = Sin(angle / 57.2957795131)
    cosr = Cos(angle / 57.2957795131)

    For i = 0 To 3
        x2 = xscale * (px(i) * cosr + sinr * py(i)) + x
        y2 = yscale * (py(i) * cosr - px(i) * sinr) + y
        px(i) = x2
        py(i) = y2
    Next

    MapTriangle (0, 0)-(0, h - 1)-(w - 1, h - 1), Image To(px(0), py(0))-(px(1), py(1))-(px(2), py(2))
    MapTriangle (0, 0)-(w - 1, 0)-(w - 1, h - 1), Image To(px(0), py(0))-(px(3), py(3))-(px(2), py(2))
End Sub


' This function returns the number of sound channels for a valid sound "handle"
' 2 = stereo, 1 = mono, 0 = error
Function SndChannels~%% (handle As Long)
    Dim SampleData As MEM, SampleSize As Unsigned Integer64

    SndChannels = 0 ' Assume failure

    ' Check if the sound is valid
    SampleData = MemSound(handle, 1)
    If SampleData.SIZE = 0 Then
        Exit Function
    End If

    ' Get the sample size
    SampleSize = CV(Unsigned Integer64, MK$(Offset, SampleData.ELEMENTSIZE))

    ' Check the data type and then decide if the sound is stereo or mono
    Select Case SampleData.TYPE
        Case 260 ' 32-bit floating point
            SndChannels = SampleSize \ 4

        Case 130 ' 16-bit integer
            SndChannels = SampleSize \ 2

        Case 1153 ' 8-bit unsigned integer
            SndChannels = SampleSize \ 1

        Case 0 ' This means this is an OpenAL sound handle
            Dim RightChannel As MEM
            RightChannel = MemSound(handle, 2)
            If RightChannel.SIZE > 0 Then
                SndChannels = 2
            Else
                SndChannels = 1
            End If
    End Select
End Function


' Converts an Offset to an Integer64
Function ConvertOffset~&& (value As Offset)
    $Checking:Off
    Dim m As MEM 'Define a memblock
    m = Mem(value) 'Point it to use value
    $If 64BIT Then
        ' On 64 bit OSes, an OFFSET is 8 bytes in size.  We can put it directly into an Integer64
        ConvertOffset~&& = MemGet(m, m.OFFSET, Unsigned Integer64) 'Get the contents of the memblock and put the values there directly into ConvertOffset&&
    $Else
            'However, on 32 bit OSes, an OFFSET is only 4 bytes.  We need to put it into a LONG variable first
            ConvertOffset~&& = MemGet(m, m.OFFSET, Unsigned Long)
    $End If
    MemFree m 'Free the memblock
    $Checking:On
End Function


' Draws a filled circle
' CX = center x coordinate
' CY = center y coordinate
'  R = radius
Sub CircleFill (cx As Long, cy As Long, r As Long)
    Dim As Long Radius, RadiusError, X, Y

    Radius = Abs(r)
    RadiusError = -Radius
    X = Radius
    Y = 0

    If Radius = 0 Then
        PSet (cx, cy)
        Exit Sub
    End If

    Line (cx - X, cy)-(cx + X, cy), , BF

    While X > Y
        RadiusError = RadiusError + Y * 2 + 1

        If RadiusError >= 0 Then
            If X <> Y + 1 Then
                Line (cx - Y, cy - X)-(cx + Y, cy - X), , BF
                Line (cx - Y, cy + X)-(cx + Y, cy + X), , BF
            End If
            X = X - 1
            RadiusError = RadiusError - X * 2
        End If

        Y = Y + 1

        Line (cx - X, cy - Y)-(cx + X, cy - Y), , BF
        Line (cx - X, cy + Y)-(cx + X, cy + Y), , BF
    Wend
End Sub


Sub LineThick (xs As Single, ys As Single, xe As Single, ye As Single, lineWeight As Unsigned Integer)
    Dim a As Single, x0 As Single, y0 As Single
    Dim prevDest As Long, prevColor As Unsigned Long
    Static colorSample As Long ' Static, so that we do not allocate an image on every call

    If colorSample = 0 Then ' Done only once
        colorSample = _NewImage(1, 1, 32)
    End If

    prevDest = Dest
    prevColor = DefaultColor
    Dest colorSample
    PSet (0, 0), prevColor
    Dest prevDest

    a = Atan2(ye - ys, xe - xs)
    a = a + Pi / 2
    x0 = 0.5 * lineWeight * Cos(a)
    y0 = 0.5 * lineWeight * Sin(a)

    MapTriangle Seamless(0, 0)-(0, 0)-(0, 0), colorSample To(xs - x0, ys - y0)-(xs + x0, ys + y0)-(xe + x0, ye + y0), , Smooth
    MapTriangle Seamless(0, 0)-(0, 0)-(0, 0), colorSample To(xs - x0, ys - y0)-(xe + x0, ye + y0)-(xe - x0, ye - y0), , Smooth
End Sub


' Gets a string form of the boolean value passed
Function BoolToStr$ (expression As Long, style As Unsigned Byte)
    Select Case style
        Case 1
            If expression Then BoolToStr = "On" Else BoolToStr = "Off"
        Case 2
            If expression Then BoolToStr = "Enabled" Else BoolToStr = "Disabled"
        Case 3
            If expression Then BoolToStr = "1" Else BoolToStr = "0"
        Case Else
            If expression Then BoolToStr = "True" Else BoolToStr = "False"
    End Select
End Function


' Initialized a dynamic array a with values from a data lable
' The first number in the data must be the size
Sub InitializeLongArray (a() As Long)
    Dim As Unsigned Long arraySize, i

    Read arraySize
    ReDim a(0 To arraySize - 1) As Long

    For i = 0 To arraySize - 1
        Read a(i)
    Next
End Sub


' Binary search an array to find the closest number in an array sorted in ascending order
Function GetClosestLongAscending& (arr() As Long, target As Long, nStart As Long, nEnd As Long)
    Dim As Long startPos, endPos, midPos, leftVal, rightVal

    startPos = nStart
    endPos = nEnd
    While startPos + 1 < endPos
        midPos = startPos + (endPos - startPos) / 2
        If arr(midPos) <= target Then
            startPos = midPos
        Else
            endPos = midPos
        End If
    Wend

    leftVal = Abs(arr(startPos) - target)
    rightVal = Abs(arr(endPos) - target)

    If leftVal <= rightVal Then
        GetClosestLongAscending = arr(startPos)
    Else
        GetClosestLongAscending = arr(endPos)
    End If
End Function


' Binary search an array to find the closest number in an array sorted in descending order
Function GetClosestLongDescending& (arr() As Long, target As Long, nStart As Long, nEnd As Long)
    Dim As Long startPos, endPos, midPos, leftVal, rightVal

    startPos = nStart
    endPos = nEnd
    While startPos + 1 < endPos
        midPos = startPos + (endPos - startPos) / 2
        If arr(midPos) <= target Then
            endPos = midPos
        Else
            startPos = midPos
        End If
    Wend

    rightVal = Abs(arr(startPos) - target)
    leftVal = Abs(arr(endPos) - target)

    If leftVal <= rightVal Then
        GetClosestLongDescending = arr(endPos)
    Else
        GetClosestLongDescending = arr(startPos)
    End If
End Function


' Returns a BASIC string (bstring) from a zero terminated C string (cstring) pointer
Function CStrPtrToBStr$ (cStrPtr As Offset)
    If cStrPtr <> NULL Then
        Dim bufSize As Long
        bufSize = strlen(cStrPtr)

        If bufSize > 0 Then
            Dim buf As String
            buf = String$(bufSize + 1, NULL)

            strncpy Offset(buf), cStrPtr, bufSize

            CStrPtrToBStr = Left$(buf, InStr(buf, Chr$(NULL)) - 1)
        End If
    End If
End Function


' Get the next C/C++ pointer from any pointer array (**something)
' This function is static, so don't mix/nest calls with different array pointers, always finish one array before starting the next
' No safety checks are done, so call on valid (non-NULL) pointers only to avoid crashes, rewind on first call for each new pointer
' and/or when needed, returns zero when the entire array is done
Function PtrFromPtrArray~%& (arrPtr As Offset, rewind As Byte)
    Static offs As Unsigned Integer64
    Dim ptr As Unsigned Offset

    If rewind Then offs = 0
    memcpy Offset(ptr), arrPtr + offs, Len(ptr) ' Len here will pickup the correct pointer size based on system arch
    If ptr <> NULL Then offs = offs + Len(ptr)
    PtrFromPtrArray = ptr
End Function


' Get a HEX dump string from any byte sequence, output may be grouped
' grp% = 0 (no grouping) or > 0 (separate after n bytes)
' sep$ = empty or group separator char(s)
' cap% = 0 (a-f) or -1 (A-F)
Function GetHexString$ (anyByteSeq As String, grp As Unsigned Byte, sep As String, cap As Byte)
    Dim As Long i, l
    Dim tmp As String
    Dim cnt As Unsigned Byte

    l = Len(anyByteSeq)
    For i = 1 To l
        tmp = tmp + Right$("00" + Hex$(Asc(anyByteSeq, i)), 2)
        cnt = cnt + 1
        If cnt = grp And i < l Then tmp = tmp + sep: cnt = 0
    Next
    If cap Then GetHexString = tmp Else GetHexString = LCase$(tmp)
End Function


' Copies file src to dst. Src file must exist and dst file must not
' Warning: Behavior is undefined if file size > 2 GB
Function FileCopy%% (fileSrc As String, fileDst As String)
    Dim As Long ffs, ffd
    Dim ffbc As String

    ' By default we assume failure
    FileCopy = FALSE

    ' Check if source file exists
    If FileExists(fileSrc) Then
        ' Check if dest file exists
        If FileExists(fileDst) Then
            Exit Function
        End If

        ffs = FreeFile
        Open fileSrc For Binary Access Read As ffs
        ffd = FreeFile
        Open fileDst For Binary Access Write As ffd

        ' Load the whole file into memory
        ffbc = Input$(LOF(ffs), ffs)
        ' Write the buffer to the new file
        Put ffd, , ffbc

        Close ffs
        Close ffd

        ' Success
        FileCopy = TRUE
    End If
End Function


'  Loads an image in 8bpp or 32bpp and optionally sets a transparent color
Function LoadImageTransparent& (fileName As String, transparentColor As Unsigned Long, is8bpp As Byte)
    Dim handle As Long

    If is8bpp Then handle = LoadImage(fileName, 257) Else handle = LoadImage(fileName)
    If handle < -1 Then ClearColor transparentColor, handle

    LoadImageTransparent = handle
End Function


' Calculates the bounding rectangle for a sprite given its position & size
Sub GetRectangle (p As Vector2DType, s As Vector2DType, r As RectangleType)
    r.a.x = p.x
    r.a.y = p.y
    r.b.x = p.x + s.x - 1
    r.b.y = p.y + s.y - 1
End Sub


' Collision testing routine. This is a simple bounding box collision test
Function RectanglesCollide%% (r1 As RectangleType, r2 As RectangleType)
    RectanglesCollide = Not (r1.a.x > r2.b.x Or r2.a.x > r1.b.x Or r1.a.y > r2.b.y Or r2.a.y > r1.b.y)
End Function


' Point & box collision test for mouse
Function PointCollidesWithRectangle%% (p As Vector2DType, r As RectangleType)
    PointCollidesWithRectangle = Not (p.x < r.a.x Or p.x > r.b.x Or p.y < r.a.y Or p.y > r.b.y)
End Function


' Fades the screen to / from black
' img& - image to use. can be the screen or _DEST
' isIn%% - 0 or -1. -1 is fade in, 0 is fade out
' fps& - speed (updates / second)
' stopat& - %age when to bail out (use for partial fades). -1 to ignore
Sub FadeScreen (nImg As Long, isIn As Byte, nfps As Unsigned Byte, nStopAt As Unsigned Byte)
    Dim As Long tmp, x, y, i

    tmp = _CopyImage(nImg)
    x = _Width(tmp) - 1
    y = _Height(tmp) - 1

    For i = 0 To 255
        If nStopAt > -1 And ((i * 100) \ 255) > nStopAt Then Exit For

        _PutImage (0, 0), tmp

        If isIn Then
            Line (0, 0)-(x, y), _RGBA32(0, 0, 0, 255 - i), BF
        Else
            Line (0, 0)-(x, y), _RGBA32(0, 0, 0, i), BF
        End If

        _Display

        _Limit nfps
    Next

    _FreeImage tmp
End Sub

' Centers a string on the screen
' The function calculates the correct starting column position to center the string on the screen and then draws the actual text
Sub DrawStringCenter (s As String, y As Integer)
    PrintString ((Width \ 2) - (PrintWidth(s) \ 2), y), s
End Sub


' Draw a box using box drawing characters and optionally puts a caption
Sub DrawTextBox (l As Long, t As Long, r As Long, b As Long, sCaption As String)
    Dim As Long i, inBoxWidth

    ' Calculate the "internal" box width
    inBoxWidth = r - l - 1

    ' Draw the top line
    Locate t, l: Print Chr$(218); String$(inBoxWidth, 196); Chr$(191);

    ' Draw the sides
    For i = t + 1 To b - 1
        Locate i, l: Print Chr$(179); Space$(inBoxWidth); Chr$(179);
    Next

    ' Draw the bottom line
    Locate b, l: Print Chr$(192); String$(inBoxWidth, 196); Chr$(217);

    ' Set the caption if specified
    If sCaption <> NULLSTRING Then
        Color BackgroundColor, DefaultColor
        Locate t, l + inBoxWidth \ 2 - Len(sCaption) \ 2
        Print " "; sCaption; " ";
        Color BackgroundColor, DefaultColor
    End If
End Sub


' Clears a given portion of screen without disturbing the cursor location and screen colors
Sub ClearTextCanvasArea (l As Long, t As Long, r As Long, b As Long)
    Dim As Long i, w, x, y
    Dim As Unsigned Long fc, bc

    w = 1 + r - l ' calculate width

    If w > 0 And t <= b Then ' only proceed is width is > 0 and height is > 0
        ' Save some stuff
        fc = DefaultColor
        bc = BackgroundColor
        x = Pos(0)
        y = CsrLin

        Color Black, Black ' lights out

        For i = t To b
            Locate i, l: Print Space$(w); ' fill with SPACE
        Next

        ' Restore saved stuff
        Color fc, bc
        Locate y, x
    End If
End Sub


' Sleeps until some keys or buttons are pressed
' TODO: Game controller
Sub WaitInput
    Do
        While MouseInput
            If MouseButton(1) Or MouseButton(2) Or MouseButton(3) Then Exit Do
        Wend
        Delay 0.01
    Loop While KeyHit <= NULL
End Sub


' Chear mouse and keyboard events
' TODO: Game controller
Sub ClearInput
    While MouseInput
    Wend
    KeyClear
End Sub


' Check if an argument is present in the command line
Function ArgVPresent%% (argv As String, start As Long)
    Dim argc As Long
    Dim As String a, b

    argc = start
    b = UCase$(argv)
    Do
        a = UCase$(Command$(argc))
        If Len(a) = 0 Then Exit Do

        If a = "/" + b Or a = "-" + b Then
            ArgVPresent = TRUE
            Exit Function
        End If

        argc = argc + 1
    Loop

    ArgVPresent = FALSE
End Function


' FILTER:
' Takes unwanted characters out of a string by
' comparing them with a filter string containing
' only acceptable numeric characters
' =========================================================
Function Filter$ (Txt As String, FilterString As String)
    Dim As String temp, c
    Dim As Long txtLength, i

    txtLength = Len(Txt)

    For i = 1 To txtLength ' Isolate each character in
        c = Mid$(Txt, i, 1) ' the string.

        ' If the character is in the filter string, save it:
        If InStr(FilterString, c) <> 0 Then
            temp = temp + c
        End If
    Next

    Filter = temp
End Function


' StrTok$:
'  Extracts tokens from a string. A token is a word that is surrounded
'  by separators, such as spaces or commas. Tokens are extracted and
'  analyzed when parsing sentences or commands. To use the GetToken
'  function, pass the string to be parsed on the first call, then pass
'  a null string on subsequent calls until the function returns a null
'  to indicate that the entire string has been parsed.
' Input:
'  Srce = string to search
'  Delim  = String of separators
' Output:
'  StrTok$ = next token
Function StrTok$ (Srce As String, Delim As String)
    Static Start As Long, SaveStr As String
    Dim As Long BegPos, Ln, EndPos

    ' If first call, make a copy of the string.
    If Srce <> NULLSTRING Then
        Start = 1
        SaveStr = Srce
    End If

    BegPos = Start
    Ln = Len(SaveStr)

    ' Look for start of a token (character that isn't delimiter).
    While BegPos <= Ln And InStr(Delim, Mid$(SaveStr, BegPos, 1)) <> 0
        BegPos = BegPos + 1
    Wend

    ' Test for token start found.
    If BegPos > Ln Then
        StrTok = NULLSTRING
        Exit Function
    End If

    ' Find the end of the token.
    EndPos = BegPos
    While EndPos <= Ln And InStr(Delim, Mid$(SaveStr, EndPos, 1)) = 0
        EndPos = EndPos + 1
    Wend

    StrTok = Mid$(SaveStr, BegPos, EndPos - BegPos)

    ' Set starting point for search for next token.
    Start = EndPos
End Function


' StrBrk:
'  Searches InString to find the first character from among those in
'  Separator. Returns the index of that character. This function can
'  be used to find the end of a token.
' Input:
'  InString = string to search
'  Separator = characters to search for
' Output:
'  StrBrk = index to first match in InString$ or 0 if none match
Function StrBrk& (InString As String, Separator As String)
    Dim As Long Ln, BegPos

    Ln = Len(InString)
    BegPos = 1
    StrBrk = 0

    Do While InStr(Separator, Mid$(InString, BegPos, 1)) = 0
        If BegPos > Ln Then
            Exit Function
        Else
            BegPos = BegPos + 1
        End If
    Loop

    StrBrk = BegPos
End Function


' StrSpn:
'  Searches InString to find the first character that is not one of
'  those in Separator. Returns the index of that character. This
'  function can be used to find the start of a token.
' Input:
'  InString = string to search
'  Separator = characters to search for
' Output:
'  StrSpn = index to first nonmatch in InString$ or 0 if all match
Function StrSpn& (InString As String, Separator As String)
    Dim As Long Ln, BegPos

    Ln = Len(InString)
    BegPos = 1
    StrSpn = 0

    Do While InStr(Separator, Mid$(InString, BegPos, 1)) <> 0
        If BegPos > Ln Then
            Exit Function
        Else
            BegPos = BegPos + 1
        End If
    Loop

    StrSpn = BegPos
End Function


' Gets the filename portion from a file path
Function GetFileNameFromPath$ (pathName As String)
    Dim i As Unsigned Long

    ' Retrieve the position of the first / or \ in the parameter from the
    For i = Len(pathName) To 1 Step -1
        If Asc(pathName, i) = KEY_SLASH Or Asc(pathName, i) = KEY_BACKSLASH Then Exit For
    Next

    ' Return the full string if pathsep was not found
    If i = 0 Then
        GetFileNameFromPath = pathName
    Else
        GetFileNameFromPath = Right$(pathName, Len(pathName) - i)
    End If
End Function


' This is a simple text parser that can take an input string from OpenFileDialog$ and spit out discrete filepaths in an array
' Returns the number of strings parsed
Function ParseOpenFileDialogList& (ofdList As String, ofdArray() As String)
    Dim As Long p, c
    Dim ts As String

    ReDim ofdArray(0 To 0) As String
    ts = ofdList

    Do
        p = InStr(ts, "|")

        If p = 0 Then
            ofdArray(c) = ts

            ParseOpenFileDialogList& = c + 1
            Exit Function
        End If

        ofdArray(c) = Left$(ts, p - 1)
        ts = Mid$(ts, p + 1)

        c = c + 1
        ReDim Preserve ofdArray(0 To c) As String
    Loop
End Function


' Returns a BASIC string (bstring) from zero terminated C string (cstring)
Function CStrToBStr$ (cStr As String)
    Dim zeroPos As Long

    CStrToBStr = cStr
    zeroPos = InStr(cStr, Chr$(NULL))
    If zeroPos > 0 Then CStrToBStr = Left$(cStr, zeroPos - 1)
End Function


' Generates a random number between lo & hi
Function RandomBetween& (lo As Long, hi As Long)
    RandomBetween = lo + Rnd * (hi - lo)
End Function


Function VersionToValue~& (ver As String)
    Dim v As String
    Dim As Long i, c

    For i = 1 To Len(ver)
        c = Asc(ver, i)
        If c > 47 And c < 58 Then
            v = v + Chr$(c)
        End If
    Next

    VersionToValue = Val(v)
End Function
'-----------------------------------------------------------------------------------------------------


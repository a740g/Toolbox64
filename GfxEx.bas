'-----------------------------------------------------------------------------------------------------------------------
' Extended graphics routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'CRTLib.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If GFXEX_BI = UNDEFINED Then
    $Let GFXEX_BI = TRUE
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


    ' Draws a filled circle
    ' CX = center x coordinate
    ' CY = center y coordinate
    '  R = radius
    Sub CircleFill (cx As Long, cy As Long, r As Long)
        Dim As Long radius, radiusError, X, Y

        radius = Abs(r)
        radiusError = -radius
        X = radius ' Y = 0

        If radius = 0 Then
            PSet (cx, cy)
            Exit Sub
        End If

        Line (cx - X, cy)-(cx + X, cy), , BF

        While X > Y
            radiusError = radiusError + Y * 2 + 1

            If radiusError >= 0 Then
                If X <> Y + 1 Then
                    Line (cx - Y, cy - X)-(cx + Y, cy - X), , BF
                    Line (cx - Y, cy + X)-(cx + Y, cy + X), , BF
                End If
                X = X - 1
                radiusError = radiusError - X * 2
            End If

            Y = Y + 1

            Line (cx - X, cy - Y)-(cx + X, cy - Y), , BF
            Line (cx - X, cy + Y)-(cx + X, cy + Y), , BF
        Wend
    End Sub


    ' Draws a thick line
    ' xs, ys - start x, y
    ' xe, ye - end x, y
    ' lineWeight - thickness
    Sub LineThick (xs As Single, ys As Single, xe As Single, ye As Single, lineWeight As Unsigned Integer)
        Static colorSample As Long ' static, so that we do not allocate an image on every call

        If colorSample = 0 Then colorSample = _NewImage(1, 1, 32) ' done only once

        Dim prevDest As Long: prevDest = Dest
        Dest colorSample
        PSet (0, 0) ' set it to _DEFAULTCOLOR
        Dest prevDest

        Dim a As Single, x0 As Single, y0 As Single
        a = Atan2(ye - ys, xe - xs)
        a = a + Pi(0.5)
        x0 = 0.5 * lineWeight * Cos(a)
        y0 = 0.5 * lineWeight * Sin(a)

        MapTriangle Seamless(0, 0)-(0, 0)-(0, 0), colorSample To(xs - x0, ys - y0)-(xs + x0, ys + y0)-(xe + x0, ye + y0), , Smooth
        MapTriangle Seamless(0, 0)-(0, 0)-(0, 0), colorSample To(xs - x0, ys - y0)-(xe + x0, ye + y0)-(xe - x0, ye - y0), , Smooth
    End Sub


    ' Fades the screen to / from black
    ' img& - image to use. can be the screen or _DEST
    ' isIn%% - 0 or -1. -1 is fade in, 0 is fade out
    ' fps& - speed (updates / second)
    ' stopat& - %age when to bail out (use for partial fades). -1 to ignore
    Sub FadeScreen32 (img As Long, isIn As Byte, maxFPS As Unsigned Byte, stopPercent As Unsigned Byte)
        Dim As Long tmp, x, y, i

        tmp = CopyImage(img)
        x = Width(tmp) - 1
        y = Height(tmp) - 1

        For i = 0 To 255
            If stopPercent > -1 And ((i * 100) \ 255) > stopPercent Then Exit For

            PutImage (0, 0), tmp

            If isIn Then
                Line (0, 0)-(x, y), RGBA32(0, 0, 0, 255 - i), BF
            Else
                Line (0, 0)-(x, y), RGBA32(0, 0, 0, i), BF
            End If

            Display

            Limit maxFPS
        Next

        FreeImage tmp
    End Sub
$End If
'-----------------------------------------------------------------------------------------------------------------------
'-----------------------------------------------------------------------------------------------------------------------


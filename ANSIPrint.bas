'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' QB64-PE ANSI Escape Sequence Emulator
' Copyright (c) 2023 Samuel Gomes
'
' TODO:
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#screen-colors
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#window-title
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#soft-reset
'   https://github.com/a740g/ANSIPrint/blob/master/docs/ansimtech.txt
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'./ANSIPrint.bi'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

$If ANSIPRINT_BAS = UNDEFINED Then
    $Let ANSIPRINT_BAS = TRUE
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    '$Debug
    'Screen NewImage(8 * 80, 16 * 25, 32)
    'Font 16

    'Do
    '    Dim ansFile As String: ansFile = OpenFileDialog$("Open", "", "*.ans|*.asc|*.diz|*.nfo|*.txt", "ANSI Art Files")
    '    If Not FileExists(ansFile) Then Exit Do

    '    Dim fh As Long: fh = FreeFile
    '    Open ansFile For Binary Access Read As fh
    '    Color DarkGray, Black
    '    Cls
    '    ResetANSIEmulator
    '    PrintANSI Input$(LOF(fh), fh)
    '    Close fh
    '    Title "Press any key to open another file...": Sleep 3600
    'Loop

    'End
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' Initializes library global variables and tables and then sets the init flag to true
    Sub InitializeANSIEmulator
        Shared __ANSIEmu As ANSIEmulatorType
        Shared __ANSIColorLUT() As Unsigned Long
        Shared __ANSIArg() As Long

        If __ANSIEmu.isInitialized Then Exit Sub ' leave if we have already initialized

        If PixelSize < 4 Then Error ERROR_FEATURE_UNAVAILABLE ' we only support rendering to 32bpp images

        Dim As Long c, i, r, g, b

        ' The first 16 are the standard 16 ANSI colors (VGA style)
        __ANSIColorLUT(0) = Black ' exact match
        __ANSIColorLUT(1) = RGB32(170, 0, 0) '  1 red
        __ANSIColorLUT(2) = RGB32(0, 170, 0) '  2 green
        __ANSIColorLUT(3) = RGB32(170, 85, 0) '  3 yellow (not really yellow; oh well)
        __ANSIColorLUT(4) = RGB32(0, 0, 170) '  4 blue
        __ANSIColorLUT(5) = RGB32(170, 0, 170) '  5 magenta
        __ANSIColorLUT(6) = RGB32(0, 170, 170) '  6 cyan
        __ANSIColorLUT(7) = DarkGray ' white (well VGA defines this as (170, 170, 170); darkgray is (169, 169, 169); so we are super close)
        __ANSIColorLUT(8) = RGB32(85, 85, 85) '  8 grey
        __ANSIColorLUT(9) = RGB32(255, 85, 85) '  9 bright red
        __ANSIColorLUT(10) = RGB32(85, 255, 85) ' 10 bright green
        __ANSIColorLUT(11) = RGB32(255, 255, 85) ' 11 bright yellow
        __ANSIColorLUT(12) = RGB32(85, 85, 255) ' 12 bright blue
        __ANSIColorLUT(13) = RGB32(255, 85, 255) ' 13 bright magenta
        __ANSIColorLUT(14) = RGB32(85, 255, 255) ' 14 bright cyan
        __ANSIColorLUT(15) = White ' exact match

        ' The next 216 colors (16-231) are formed by a 3bpc RGB value offset by 16, packed into a single value
        For c = 16 To 231
            i = ((c - 16) \ 36) Mod 6
            If i = 0 Then r = 0 Else r = (14135 + 10280 * i) \ 256

            i = ((c - 16) \ 6) Mod 6
            If i = 0 Then g = 0 Else g = (14135 + 10280 * i) \ 256

            i = ((c - 16) \ 1) Mod 6
            If i = 0 Then b = 0 Else b = (14135 + 10280 * i) \ 256

            __ANSIColorLUT(c) = RGB32(r, g, b)
        Next

        ' The final 24 colors (232-255) are grayscale starting from a shade slighly lighter than black, ranging up to shade slightly darker than white
        For c = 232 To 255
            g = (2056 + 2570 * (c - 232)) \ 256
            __ANSIColorLUT(c) = RGB32(g, g, g)
        Next

        ReDim __ANSIArg(1 To UBound(__ANSIArg)) As Long ' reset the CSI arg list

        __ANSIEmu.state = ANSI_STATE_TEXT ' we will start parsing regular text by default
        __ANSIEmu.argIndex = 0 ' reset argument index

        ' Reset the foreground and background color
        __ANSIEmu.fC = ANSI_DEFAULT_COLOR_FOREGROUND
        SetANSICanvasColor __ANSIEmu.fC, FALSE, TRUE
        __ANSIEmu.bC = ANSI_DEFAULT_COLOR_BACKGROUND
        SetANSICanvasColor __ANSIEmu.bC, TRUE, TRUE

        ' Reset text attributes
        __ANSIEmu.isBold = FALSE
        __ANSIEmu.isBlink = FALSE
        __ANSIEmu.isInvert = FALSE

        ' Get the current cursor position
        __ANSIEmu.posDEC.x = Pos(0)
        __ANSIEmu.posDEC.y = CsrLin
        __ANSIEmu.posSCO = __ANSIEmu.posDEC

        __ANSIEmu.CPS = 0 ' disable any speed control

        ControlChr On ' get assist from QB64's control character handling (only for tabs; we are pretty much doing the rest ourselves)

        __ANSIEmu.isInitialized = TRUE ' set to true to indicate init is done
    End Sub


    ' This simply resets the emulator to a clean state
    Sub ResetANSIEmulator
        Shared __ANSIEmu As ANSIEmulatorType

        __ANSIEmu.isInitialized = FALSE ' set the init flag to false
        InitializeANSIEmulator ' call the init routine
    End Sub


    ' Sets the emulation speed
    ' nCPS - characters / second (bigger numbers means faster; <= 0 to disable)
    Sub SetANSIEmulationSpeed (nCPS As Long)
        Shared __ANSIEmu As ANSIEmulatorType

        __ANSIEmu.CPS = nCPS
    End Sub


    ' Processes a single byte and decides what to do with it based on the current emulation state
    Function PrintANSICharacter& (ch As Unsigned Byte)
        Shared __ANSIEmu As ANSIEmulatorType
        Shared __ANSIArg() As Long

        PrintANSICharacter& = TRUE ' by default we will return true to tell the caller to keep going

        Dim As Long x, y, z ' temp variables used in many places (usually as counter / index)

        Select Case __ANSIEmu.state
            Case ANSI_STATE_TEXT ' handle normal characters (including some control characters)
                Select Case ch
                    Case ANSI_SUB ' stop processing and exit loop on EOF (usually put by SAUCE blocks)
                        __ANSIEmu.state = ANSI_STATE_END

                    Case ANSI_BEL ' handle Bell - because QB64 does not (even with ControlChr On)
                        Beep

                    Case ANSI_BS ' handle Backspace - because QB64 does not (even with ControlChr On)
                        x = Pos(0) - 1
                        If x > 0 Then Locate , x ' move to the left only if we are not on the edge

                        'Case ANSI_LF ' handle Line Feed because QB64 screws this up and moves the cursor to the beginning of the next line
                        '    x = Pos(0) ' save old x pos
                        '    Print Chr$(ch); ' use QB64 to handle the LF and then correct the mistake
                        '    Locate , x ' set the cursor to the old x pos

                    Case ANSI_FF ' handle Form Feed - because QB64 does not (even with ControlChr On)
                        Locate 1, 1

                    Case ANSI_CR ' handle Carriage Return because QB64 screws this up and moves the cursor to the beginning of the next line
                        Locate , 1

                        'Case ANSI_DEL ' TODO: Check what to do with this

                    Case ANSI_ESC ' handle escape character
                        __ANSIEmu.state = ANSI_STATE_BEGIN ' beginning a new escape sequence

                    Case Else ' print the character
                        Print Chr$(ch);
                        If __ANSIEmu.CPS > 0 Then Limit __ANSIEmu.CPS ' limit the loop speed if char/sec is a positive value

                End Select

            Case ANSI_STATE_BEGIN ' handle escape sequence
                Select Case ch
                    Case Is < ANSI_SP ' handle escaped character
                        ControlChr Off
                        Print Chr$(ch); ' print escaped ESC character
                        ControlChr On
                        If __ANSIEmu.CPS > 0 Then Limit __ANSIEmu.CPS ' limit the loop speed if char/sec is a positive value
                        __ANSIEmu.state = ANSI_STATE_TEXT

                    Case ANSI_ESC_DECSC ' Save Cursor Position in Memory
                        __ANSIEmu.posDEC.x = Pos(0)
                        __ANSIEmu.posDEC.y = CsrLin
                        __ANSIEmu.state = ANSI_STATE_TEXT

                    Case ANSI_ESC_DECSR ' Restore Cursor Position from Memory
                        Locate __ANSIEmu.posDEC.y, __ANSIEmu.posDEC.x
                        __ANSIEmu.state = ANSI_STATE_TEXT

                    Case ANSI_ESC_RI ' Reverse Index
                        y = CsrLin - 1
                        If y > 0 Then Locate y
                        __ANSIEmu.state = ANSI_STATE_TEXT

                    Case ANSI_ESC_CSI ' handle CSI
                        ReDim __ANSIArg(1 To UBound(__ANSIArg)) As Long ' reset the control sequence arguments, but don't loose the allocated memory
                        __ANSIEmu.argIndex = 0 ' reset argument index
                        'leadInPrefix = 0 ' reset lead-in prefix
                        __ANSIEmu.state = ANSI_STATE_SEQUENCE

                    Case Else ' throw an error for stuff we are not handling
                        Error ERROR_FEATURE_UNAVAILABLE

                End Select

            Case ANSI_STATE_SEQUENCE ' handle CSI sequence
                Select Case ch
                    Case ANSI_0 To ANSI_QUESTION_MARK ' argument bytes
                        If __ANSIEmu.argIndex < 1 Then __ANSIEmu.argIndex = 1 ' set the argument index to one if this is the first time

                        Select Case ch
                            Case ANSI_0 To ANSI_9 ' handle sequence numeric arguments
                                __ANSIArg(__ANSIEmu.argIndex) = __ANSIArg(__ANSIEmu.argIndex) * 10 + ch - ANSI_0

                            Case ANSI_SEMICOLON ' handle sequence argument seperators
                                __ANSIEmu.argIndex = __ANSIEmu.argIndex + 1 ' increment the argument index
                                If __ANSIEmu.argIndex > UBound(__ANSIArg) Then ReDim Preserve __ANSIArg(1 To __ANSIEmu.argIndex) As Long ' dynamically expand the argument list if needed

                            Case ANSI_EQUALS_SIGN, ANSI_GREATER_THAN_SIGN, ANSI_QUESTION_MARK ' handle lead-in prefix
                                ' NOP: leadInPrefix = ch ' just save the prefix type

                            Case Else ' throw an error for stuff we are not handling
                                Error ERROR_FEATURE_UNAVAILABLE

                        End Select

                    Case ANSI_SP To ANSI_SLASH ' intermediate bytes
                        Select Case ch
                            Case ANSI_SP ' ignore spaces
                                ' NOP

                            Case Else ' throw an error for stuff we are not handling
                                Error ERROR_FEATURE_UNAVAILABLE

                        End Select

                    Case ANSI_AT_SIGN To ANSI_TILDE ' final byte
                        Select Case ch
                            Case ANSI_ESC_CSI_SM, ANSI_ESC_CSI_RM ' Set and reset screen mode
                                If __ANSIEmu.argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                Select Case __ANSIArg(1)
                                    Case 0 To 6, 14 To 18 ' all mode changes are ignored. the screen type must be set by the caller
                                        ' NOP

                                    Case 7 ' Enable / disable line wrapping
                                        ' NOP: QB64 does line wrapping by default
                                        If ANSI_ESC_CSI_RM = ch Then ' ANSI_ESC_CSI_RM disable line wrapping unsupported
                                            Error ERROR_FEATURE_UNAVAILABLE
                                        End If

                                    Case 12 ' Text Cursor Enable / Disable Blinking
                                        ' NOP

                                    Case 25 ' make cursor visible / invisible
                                        If ANSI_ESC_CSI_SM = ch Then ' ANSI_ESC_CSI_SM make cursor visible
                                            Locate , , 1
                                        Else ' ANSI_ESC_CSI_RM make cursor invisible
                                            Locate , , 0
                                        End If

                                    Case Else ' throw an error for stuff we are not handling
                                        Error ERROR_FEATURE_UNAVAILABLE

                                End Select

                            Case ANSI_ESC_CSI_ED ' Erase in Display
                                If __ANSIEmu.argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                Select Case __ANSIArg(1)
                                    Case 0 ' clear from cursor to end of screen
                                        ClearANSICanvasArea Pos(0), CsrLin, GetANSICanvasWidth, CsrLin ' first clear till the end of the line starting from the cursor
                                        ClearANSICanvasArea 1, CsrLin + 1, GetANSICanvasWidth, GetANSICanvasHeight ' next clear the whole canvas below the cursor

                                    Case 1 ' clear from cursor to beginning of the screen
                                        ClearANSICanvasArea 1, CsrLin, Pos(0), CsrLin ' first clear from the beginning of the line till the cursor
                                        ClearANSICanvasArea 1, 1, GetANSICanvasWidth, CsrLin - 1 ' next clear the whole canvas above the cursor

                                    Case 2 ' clear entire screen (and moves cursor to upper left like ANSI.SYS)
                                        Cls

                                    Case 3 ' clear entire screen and delete all lines saved in the scrollback buffer (scrollback stuff not supported)
                                        ClearANSICanvasArea 1, 1, GetANSICanvasWidth, GetANSICanvasHeight

                                    Case Else ' throw an error for stuff we are not handling
                                        Error ERROR_FEATURE_UNAVAILABLE

                                End Select

                            Case ANSI_ESC_CSI_EL ' Erase in Line
                                If __ANSIEmu.argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                Select Case __ANSIArg(1)
                                    Case 0 ' erase from cursor to end of line
                                        ClearANSICanvasArea Pos(0), CsrLin, GetANSICanvasWidth, CsrLin

                                    Case 1 ' erase start of line to the cursor
                                        ClearANSICanvasArea 1, CsrLin, Pos(0), CsrLin

                                    Case 2 ' erase the entire line
                                        ClearANSICanvasArea 1, CsrLin, GetANSICanvasWidth, CsrLin

                                    Case Else ' throw an error for stuff we are not handling
                                        Error ERROR_FEATURE_UNAVAILABLE

                                End Select

                            Case ANSI_ESC_CSI_SGR ' Select Graphic Rendition
                                x = 1 ' start with the first argument
                                If __ANSIEmu.argIndex < 1 Then __ANSIEmu.argIndex = 1 ' this allows '[m' to be treated as [0m
                                Do While x <= __ANSIEmu.argIndex ' loop through the argument list and process each argument
                                    Select Case __ANSIArg(x)
                                        Case 0 ' reset all modes (styles and colors)
                                            __ANSIEmu.fC = ANSI_DEFAULT_COLOR_FOREGROUND
                                            __ANSIEmu.bC = ANSI_DEFAULT_COLOR_BACKGROUND
                                            __ANSIEmu.isBold = FALSE
                                            __ANSIEmu.isBlink = FALSE
                                            __ANSIEmu.isInvert = FALSE
                                            SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE
                                            SetANSICanvasColor __ANSIEmu.bC, Not __ANSIEmu.isInvert, TRUE

                                        Case 1 ' enable high intensity colors
                                            If __ANSIEmu.fC < 8 Then __ANSIEmu.fC = __ANSIEmu.fC + 8
                                            __ANSIEmu.isBold = TRUE
                                            SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE

                                        Case 2, 22 ' enable low intensity, disable high intensity colors
                                            If __ANSIEmu.fC > 7 Then __ANSIEmu.fC = __ANSIEmu.fC - 8
                                            __ANSIEmu.isBold = FALSE
                                            SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE

                                        Case 3, 4, 23, 24 ' set / reset italic & underline mode ignored
                                            ' NOP: This can be used if we load monospaced TTF fonts using 'italics', 'underline' properties

                                        Case 5, 6 ' turn blinking on
                                            If __ANSIEmu.bC < 8 Then __ANSIEmu.bC = __ANSIEmu.bC + 8
                                            __ANSIEmu.isBlink = TRUE
                                            SetANSICanvasColor __ANSIEmu.bC, Not __ANSIEmu.isInvert, TRUE

                                        Case 7 ' enable reverse video
                                            If Not __ANSIEmu.isInvert Then
                                                __ANSIEmu.isInvert = TRUE
                                                SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE
                                                SetANSICanvasColor __ANSIEmu.bC, Not __ANSIEmu.isInvert, TRUE
                                            End If

                                        Case 25 ' turn blinking off
                                            If __ANSIEmu.bC > 7 Then __ANSIEmu.bC = __ANSIEmu.bC - 8
                                            __ANSIEmu.isBlink = FALSE
                                            SetANSICanvasColor __ANSIEmu.bC, Not __ANSIEmu.isInvert, TRUE

                                        Case 27 ' disable reverse video
                                            If __ANSIEmu.isInvert Then
                                                __ANSIEmu.isInvert = FALSE
                                                SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE
                                                SetANSICanvasColor __ANSIEmu.bC, Not __ANSIEmu.isInvert, TRUE
                                            End If

                                        Case 30 To 37 ' set foreground color
                                            __ANSIEmu.fC = __ANSIArg(x) - 30
                                            If __ANSIEmu.isBold Then __ANSIEmu.fC = __ANSIEmu.fC + 8
                                            SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE

                                        Case 38 ' set 8-bit 256 or 24-bit RGB foreground color
                                            z = __ANSIEmu.argIndex - x ' get the number of arguments remaining

                                            If __ANSIArg(x + 1) = 2 And z >= 4 Then ' 32bpp color with 5 arguments
                                                __ANSIEmu.fC = RGB32(__ANSIArg(x + 2) And &HFF, __ANSIArg(x + 3) And &HFF, __ANSIArg(x + 4) And &HFF)
                                                SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, FALSE

                                                x = x + 4 ' skip to last used arg

                                            ElseIf __ANSIArg(x + 1) = 5 And z >= 2 Then ' 256 color with 3 arguments
                                                __ANSIEmu.fC = __ANSIArg(x + 2)
                                                SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE

                                                x = x + 2 ' skip to last used arg

                                            Else
                                                Error ERROR_CANNOT_CONTINUE

                                            End If

                                        Case 39 ' set default foreground color
                                            __ANSIEmu.fC = ANSI_DEFAULT_COLOR_FOREGROUND
                                            SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE

                                        Case 40 To 47 ' set background color
                                            __ANSIEmu.bC = __ANSIArg(x) - 40
                                            If __ANSIEmu.isBlink Then __ANSIEmu.bC = __ANSIEmu.bC + 8
                                            SetANSICanvasColor __ANSIEmu.bC, Not __ANSIEmu.isInvert, TRUE

                                        Case 48 ' set 8-bit 256 or 24-bit RGB background color
                                            z = __ANSIEmu.argIndex - x ' get the number of arguments remaining

                                            If __ANSIArg(x + 1) = 2 And z >= 4 Then ' 32bpp color with 5 arguments
                                                __ANSIEmu.bC = RGB32(__ANSIArg(x + 2) And &HFF, __ANSIArg(x + 3) And &HFF, __ANSIArg(x + 4) And &HFF)
                                                SetANSICanvasColor __ANSIEmu.bC, Not __ANSIEmu.isInvert, FALSE

                                                x = x + 4 ' skip to last used arg

                                            ElseIf __ANSIArg(x + 1) = 5 And z >= 2 Then ' 256 color with 3 arguments
                                                __ANSIEmu.bC = __ANSIArg(x + 2)
                                                SetANSICanvasColor __ANSIEmu.bC, Not __ANSIEmu.isInvert, TRUE

                                                x = x + 2 ' skip to last used arg

                                            Else
                                                Error ERROR_CANNOT_CONTINUE

                                            End If

                                        Case 49 ' set default background color
                                            __ANSIEmu.bC = ANSI_DEFAULT_COLOR_BACKGROUND
                                            SetANSICanvasColor __ANSIEmu.bC, Not __ANSIEmu.isInvert, TRUE

                                        Case 90 To 97 ' set high intensity foreground color
                                            __ANSIEmu.fC = 8 + __ANSIArg(x) - 90
                                            SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE

                                        Case 100 To 107 ' set high intensity background color
                                            __ANSIEmu.bC = 8 + __ANSIArg(x) - 100
                                            SetANSICanvasColor __ANSIEmu.bC, Not __ANSIEmu.isInvert, TRUE

                                        Case Else ' throw an error for stuff we are not handling
                                            Error ERROR_FEATURE_UNAVAILABLE

                                    End Select

                                    x = x + 1 ' move to the next argument
                                Loop

                            Case ANSI_ESC_CSI_SCP ' Save Current Cursor Position (SCO)
                                If __ANSIEmu.argIndex > 0 Then Error ERROR_CANNOT_CONTINUE ' was not expecting args

                                __ANSIEmu.posSCO.x = Pos(0)
                                __ANSIEmu.posSCO.y = CsrLin

                            Case ANSI_ESC_CSI_RCP ' Restore Saved Cursor Position (SCO)
                                If __ANSIEmu.argIndex > 0 Then Error ERROR_CANNOT_CONTINUE ' was not expecting args

                                Locate __ANSIEmu.posSCO.y, __ANSIEmu.posSCO.x

                            Case ANSI_ESC_CSI_PABLODRAW_24BPP ' PabloDraw 24-bit ANSI sequences
                                If __ANSIEmu.argIndex <> 4 Then Error ERROR_CANNOT_CONTINUE ' we need 4 arguments

                                SetANSICanvasColor RGB32(__ANSIArg(2) And &HFF, __ANSIArg(3) And &HFF, __ANSIArg(4) And &HFF), __ANSIArg(1) = FALSE, FALSE

                            Case ANSI_ESC_CSI_CUP, ANSI_ESC_CSI_HVP ' Cursor position or Horizontal and vertical position
                                If __ANSIEmu.argIndex > 2 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 2 args

                                y = GetANSICanvasHeight
                                If __ANSIArg(1) < 1 Then
                                    __ANSIArg(1) = 1
                                ElseIf __ANSIArg(1) > y Then
                                    __ANSIArg(1) = y
                                End If

                                x = GetANSICanvasWidth
                                If __ANSIArg(2) < 1 Then
                                    __ANSIArg(2) = 1
                                ElseIf __ANSIArg(2) > x Then
                                    __ANSIArg(2) = x
                                End If

                                Locate __ANSIArg(1), __ANSIArg(2) ' line #, column #

                            Case ANSI_ESC_CSI_CUU ' Cursor up
                                If __ANSIEmu.argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                If __ANSIArg(1) < 1 Then __ANSIArg(1) = 1
                                y = CsrLin - __ANSIArg(1)
                                If y < 1 Then __ANSIArg(1) = 1
                                Locate y

                            Case ANSI_ESC_CSI_CUD ' Cursor down
                                If __ANSIEmu.argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                If __ANSIArg(1) < 1 Then __ANSIArg(1) = 1
                                y = CsrLin + __ANSIArg(1)
                                z = GetANSICanvasHeight
                                If y > z Then y = z
                                Locate y

                            Case ANSI_ESC_CSI_CUF ' Cursor forward
                                If __ANSIEmu.argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                If __ANSIArg(1) < 1 Then __ANSIArg(1) = 1
                                x = Pos(0) + __ANSIArg(1)
                                z = GetANSICanvasWidth
                                If x > z Then x = z
                                Locate , x

                            Case ANSI_ESC_CSI_CUB ' Cursor back
                                If __ANSIEmu.argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                If __ANSIArg(1) < 1 Then __ANSIArg(1) = 1
                                x = Pos(0) - __ANSIArg(1)
                                If x < 1 Then x = 1
                                Locate , x

                            Case ANSI_ESC_CSI_CNL ' Cursor Next Line
                                If __ANSIEmu.argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                If __ANSIArg(1) < 1 Then __ANSIArg(1) = 1
                                y = CsrLin + __ANSIArg(1)
                                z = GetANSICanvasHeight
                                If y > z Then y = z
                                Locate y, 1

                            Case ANSI_ESC_CSI_CPL ' Cursor Previous Line
                                If __ANSIEmu.argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                If __ANSIArg(1) < 1 Then __ANSIArg(1) = 1
                                y = CsrLin - __ANSIArg(1)
                                If y < 1 Then y = 1
                                Locate y, 1

                            Case ANSI_ESC_CSI_CHA ' Cursor Horizontal Absolute
                                If __ANSIEmu.argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                x = GetANSICanvasWidth
                                If __ANSIArg(1) < 1 Then
                                    __ANSIArg(1) = 1
                                ElseIf __ANSIArg(1) > x Then
                                    __ANSIArg(1) = x
                                End If
                                Locate , __ANSIArg(1)

                            Case ANSI_ESC_CSI_VPA ' Vertical Line Position Absolute
                                If __ANSIEmu.argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                y = GetANSICanvasHeight
                                If __ANSIArg(1) < 1 Then
                                    __ANSIArg(1) = 1
                                ElseIf __ANSIArg(1) > y Then
                                    __ANSIArg(1) = y
                                End If
                                Locate __ANSIArg(1)

                            Case ANSI_ESC_CSI_DECSCUSR
                                If __ANSIEmu.argIndex > 1 Then Error ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                Select Case __ANSIArg(1)
                                    Case 0, 3, 4 ' Default, Blinking & Steady underline cursor shape
                                        Locate , , , 29, 31 ' this should give a nice underline cursor

                                    Case 1, 2 ' Blinking & Steady block cursor shape
                                        Locate , , , 0, 31 ' this should give a full block cursor

                                    Case 5, 6 ' Blinking & Steady bar cursor shape
                                        Locate , , , 16, 31 ' since we cannot get a bar cursor in QB64, we'll just use a half-block cursor

                                    Case Else ' throw an error for stuff we are not handling
                                        Error ERROR_FEATURE_UNAVAILABLE

                                End Select

                            Case Else ' throw an error for stuff we are not handling
                                Error ERROR_FEATURE_UNAVAILABLE

                        End Select

                        ' End of sequence
                        __ANSIEmu.state = ANSI_STATE_TEXT

                    Case Else ' throw an error for stuff we are not handling
                        Error ERROR_FEATURE_UNAVAILABLE

                End Select

            Case ANSI_STATE_END ' end of the stream has been reached
                PrintANSICharacter& = FALSE ' tell the caller the we should stop processing the rest of the stream
                Exit Function ' and then leave

            Case Else ' this should never happen
                Error ERROR_CANNOT_CONTINUE

        End Select
    End Function


    ' Processes the whole string instead of a character like PrintANSICharacter()
    ' This simply wraps PrintANSICharacter()
    Function PrintANSIString& (s As String)
        Dim As Long i

        PrintANSIString = TRUE

        For i = 1 To Len(s)
            If Not PrintANSICharacter(Asc(s, i)) Then
                PrintANSIString = FALSE ' signal end of stream
                Exit Function
            End If
        Next
    End Function


    ' A simple routine that wraps pretty much the whole library
    ' It will reset the library, do the setup and then render the whole ANSI string in one go
    ' ControlChr is properly restored
    Sub PrintANSI (sANSI As String)
        Dim As Long oldControlChr ' to save old ContolChr

        ' Save the old ControlChr state
        oldControlChr = ControlChr

        ResetANSIEmulator ' reset the emulator

        Dim dummy As Long: dummy = PrintANSIString(sANSI) ' print the ANSI string and ignore the return value

        ' Set ControlChr the way we found it
        If oldControlChr Then
            ControlChr Off
        Else
            ControlChr On
        End If
    End Sub


    ' Set the foreground or background color
    Sub SetANSICanvasColor (c As Unsigned Long, isBackground As Long, isLegacy As Long)
        Shared __ANSIColorLUT() As Unsigned Long

        Dim nRGB As Unsigned Long

        If isLegacy Then
            nRGB = __ANSIColorLUT(c)
        Else
            nRGB = c
        End If

        If isBackground Then
            ' Echo "Background color" + Str$(c) + " (" + Hex$(nRGB) + ")"
            Color , nRGB
        Else
            ' Echo "Foreground color" + Str$(c) + " (" + Hex$(nRGB) + ")"
            Color nRGB
        End If
    End Sub


    ' Returns the number of characters per line
    Function GetANSICanvasWidth&
        GetANSICanvasWidth = Width \ FontWidth ' this will cause a divide by zero if a variable width font is used; use monospaced fonts to avoid this
    End Function


    ' Returns the number of lines
    Function GetANSICanvasHeight&
        GetANSICanvasHeight = Height \ FontHeight
    End Function


    ' Clears a given portion of screen without disturbing the cursor location and colors
    Sub ClearANSICanvasArea (l As Long, t As Long, r As Long, b As Long)
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
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------------------------------------------------------------


'-----------------------------------------------------------------------------------------------------------------------
' ANSI Escape Sequence Emulator
' Copyright (c) 2023 Samuel Gomes
'
' TODO:
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#screen-colors
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#window-title
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#soft-reset
'   https://github.com/a740g/ANSIPrint/blob/master/docs/ansimtech.txt
'-----------------------------------------------------------------------------------------------------------------------

$IF ANSIPRINT_BAS = UNDEFINED THEN
    $LET ANSIPRINT_BAS = TRUE

    '$INCLUDE:'ANSIPrint.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    '$DEBUG
    'SCREEN _NEWIMAGE(8 * 80, 16 * 28, 32)
    '_FONT 16

    'DO
    '    DIM ansFile AS STRING: ansFile = _OPENFILEDIALOG$("Open", "", "*.ans|*.asc|*.diz|*.nfo|*.txt", "ANSI Art Files")
    '    IF NOT _FILEEXISTS(ansFile) THEN EXIT DO

    '    DIM fh AS LONG: fh = FREEFILE
    '    OPEN ansFile FOR BINARY ACCESS READ AS fh
    '    COLOR BGRA_DARKGRAY, BGRA_BLACK
    '    CLS
    '    ResetANSIEmulator
    '    PrintANSI INPUT$(LOF(fh), fh)
    '    CLOSE fh
    '    _TITLE "Press any key to open another file...": SLEEP 3600
    'LOOP

    'END
    '-------------------------------------------------------------------------------------------------------------------

    ' Initializes library global variables and tables and then sets the init flag to true
    SUB InitializeANSIEmulator
        SHARED __ANSIEmu AS __ANSIEmulatorType
        SHARED __ANSIColorLUT() AS _UNSIGNED LONG
        SHARED __ANSIArg() AS LONG

        IF __ANSIEmu.isInitialized THEN EXIT SUB ' leave if we have already initialized

        IF _PIXELSIZE < 4 THEN ERROR ERROR_FEATURE_UNAVAILABLE ' we only support rendering to 32bpp images

        DIM AS LONG c, i, r, g, b

        ' The first 16 are the standard 16 ANSI colors (VGA style)
        __ANSIColorLUT(0) = _RGB32(0, 0, 0) ' 0 black
        __ANSIColorLUT(1) = _RGB32(170, 0, 0) '  1 red
        __ANSIColorLUT(2) = _RGB32(0, 170, 0) '  2 green
        __ANSIColorLUT(3) = _RGB32(170, 85, 0) '  3 yellow (not really yellow; oh well)
        __ANSIColorLUT(4) = _RGB32(0, 0, 170) '  4 blue
        __ANSIColorLUT(5) = _RGB32(170, 0, 170) '  5 magenta
        __ANSIColorLUT(6) = _RGB32(0, 170, 170) '  6 cyan
        __ANSIColorLUT(7) = _RGB32(170, 170, 170) ' white
        __ANSIColorLUT(8) = _RGB32(85, 85, 85) '  8 grey
        __ANSIColorLUT(9) = _RGB32(255, 85, 85) '  9 bright red
        __ANSIColorLUT(10) = _RGB32(85, 255, 85) ' 10 bright green
        __ANSIColorLUT(11) = _RGB32(255, 255, 85) ' 11 bright yellow
        __ANSIColorLUT(12) = _RGB32(85, 85, 255) ' 12 bright blue
        __ANSIColorLUT(13) = _RGB32(255, 85, 255) ' 13 bright magenta
        __ANSIColorLUT(14) = _RGB32(85, 255, 255) ' 14 bright cyan
        __ANSIColorLUT(15) = _RGB32(255, 255, 255) ' 15 bright white

        ' The next 216 colors (16-231) are formed by a 3bpc RGB value offset by 16, packed into a single value
        FOR c = 16 TO 231
            i = ((c - 16) \ 36) MOD 6
            IF i = 0 THEN r = 0 ELSE r = (14135 + 10280 * i) \ 256

            i = ((c - 16) \ 6) MOD 6
            IF i = 0 THEN g = 0 ELSE g = (14135 + 10280 * i) \ 256

            i = ((c - 16) \ 1) MOD 6
            IF i = 0 THEN b = 0 ELSE b = (14135 + 10280 * i) \ 256

            __ANSIColorLUT(c) = _RGB32(r, g, b)
        NEXT

        ' The final 24 colors (232-255) are grayscale starting from a shade slighly lighter than black, ranging up to shade slightly darker than white
        FOR c = 232 TO 255
            g = (2056 + 2570 * (c - 232)) \ 256
            __ANSIColorLUT(c) = _RGB32(g, g, g)
        NEXT

        REDIM __ANSIArg(1 TO UBOUND(__ANSIArg)) AS LONG ' reset the CSI arg list

        __ANSIEmu.state = __ANSI_STATE_TEXT ' we will start parsing regular text by default
        __ANSIEmu.argIndex = 0 ' reset argument index

        ' Reset the foreground and background color
        __ANSIEmu.fC = __ANSI_DEFAULT_COLOR_FOREGROUND
        SetANSICanvasColor __ANSIEmu.fC, FALSE, TRUE
        __ANSIEmu.bC = __ANSI_DEFAULT_COLOR_BACKGROUND
        SetANSICanvasColor __ANSIEmu.bC, TRUE, TRUE

        ' Reset text attributes
        __ANSIEmu.isBold = FALSE
        __ANSIEmu.isBlink = FALSE
        __ANSIEmu.isInvert = FALSE

        ' Get the current cursor position
        __ANSIEmu.posDEC.x = POS(0)
        __ANSIEmu.posDEC.y = CSRLIN
        __ANSIEmu.posSCO = __ANSIEmu.posDEC

        __ANSIEmu.lastChar = NULL
        __ANSIEmu.lastCharX = NULL

        __ANSIEmu.CPS = 0 ' disable any speed control

        _CONTROLCHR ON ' get assist from QB64's control character handling (only for tabs; we are pretty much doing the rest ourselves)

        __ANSIEmu.isInitialized = TRUE ' set to true to indicate init is done
    END SUB

    ' This simply resets the emulator to a clean state
    SUB ResetANSIEmulator
        SHARED __ANSIEmu AS __ANSIEmulatorType

        __ANSIEmu.isInitialized = FALSE ' set the init flag to false
        InitializeANSIEmulator ' call the init routine
    END SUB

    ' Sets the emulation speed
    ' nCPS - characters / second (bigger numbers means faster; <= 0 to disable)
    SUB SetANSIEmulationSpeed (nCPS AS LONG)
        SHARED __ANSIEmu AS __ANSIEmulatorType

        __ANSIEmu.CPS = nCPS
    END SUB

    ' Processes a single byte and decides what to do with it based on the current emulation state
    FUNCTION PrintANSICharacter& (ch AS _UNSIGNED _BYTE)
        SHARED __ANSIEmu AS __ANSIEmulatorType
        SHARED __ANSIArg() AS LONG

        PrintANSICharacter& = TRUE ' by default we will return true to tell the caller to keep going

        DIM AS LONG x, y, z ' temp variables used in many places (usually as counter / index)

        SELECT CASE __ANSIEmu.state
            CASE __ANSI_STATE_TEXT ' handle normal characters (including some control characters)
                SELECT CASE ch
                    CASE ANSI_SUB ' stop processing and exit loop on EOF (usually put by SAUCE blocks)
                        __ANSIEmu.state = __ANSI_STATE_END

                    CASE ANSI_BEL ' handle Bell - because QB64 does not (even with ControlChr On)
                        BEEP

                    CASE ANSI_BS ' handle Backspace - because QB64 does not (even with ControlChr On)
                        x = POS(0) - 1
                        IF x > 0 THEN LOCATE , x ' move to the left only if we are not on the edge

                    CASE ANSI_LF ' handle Line Feed (including EOL CRLF special case)
                        PRINT STRING$(1 - (ANSI_CR = __ANSIEmu.lastChar AND GetANSICanvasWidth = __ANSIEmu.lastCharX), ch);

                    CASE ANSI_FF ' handle Form Feed - because QB64 does not (even with ControlChr On)
                        LOCATE 1, 1

                    CASE ANSI_CR ' handle Carriage Return because QB64 screws this up and moves the cursor to the beginning of the next line
                        LOCATE , 1

                        'Case ANSI_DEL ' TODO: Check what to do with this

                    CASE ANSI_ESC ' handle escape character
                        __ANSIEmu.state = __ANSI_STATE_BEGIN ' beginning a new escape sequence

                    CASE ANSI_RS, ANSI_US ' QB64 does non-ANSI stuff with these two when ControlChar is On
                        _CONTROLCHR OFF
                        __ANSIEmu.lastCharX = POS(0)
                        PRINT CHR$(ch); ' print escaped ESC character
                        _CONTROLCHR ON
                        IF __ANSIEmu.CPS > 0 THEN _LIMIT __ANSIEmu.CPS ' limit the loop speed if char/sec is a positive value

                    CASE ELSE ' print the character
                        __ANSIEmu.lastCharX = POS(0)
                        PRINT CHR$(ch);
                        IF __ANSIEmu.CPS > 0 THEN _LIMIT __ANSIEmu.CPS ' limit the loop speed if char/sec is a positive value

                END SELECT

            CASE __ANSI_STATE_BEGIN ' handle escape sequence
                SELECT CASE ch
                    CASE IS < ANSI_SP ' handle escaped character
                        _CONTROLCHR OFF
                        __ANSIEmu.lastCharX = POS(0)
                        PRINT CHR$(ch); ' print escaped ESC character
                        _CONTROLCHR ON
                        IF __ANSIEmu.CPS > 0 THEN _LIMIT __ANSIEmu.CPS ' limit the loop speed if char/sec is a positive value
                        __ANSIEmu.state = __ANSI_STATE_TEXT

                    CASE ANSI_ESC_DECSC ' Save Cursor Position in Memory
                        __ANSIEmu.posDEC.x = POS(0)
                        __ANSIEmu.posDEC.y = CSRLIN
                        __ANSIEmu.state = __ANSI_STATE_TEXT

                    CASE ANSI_ESC_DECSR ' Restore Cursor Position from Memory
                        LOCATE __ANSIEmu.posDEC.y, __ANSIEmu.posDEC.x
                        __ANSIEmu.state = __ANSI_STATE_TEXT

                    CASE ANSI_ESC_RI ' Reverse Index
                        y = CSRLIN - 1
                        IF y > 0 THEN LOCATE y
                        __ANSIEmu.state = __ANSI_STATE_TEXT

                    CASE ANSI_ESC_CSI ' handle CSI
                        REDIM __ANSIArg(1 TO UBOUND(__ANSIArg)) AS LONG ' reset the control sequence arguments, but don't loose the allocated memory
                        __ANSIEmu.argIndex = 0 ' reset argument index
                        'leadInPrefix = 0 ' reset lead-in prefix
                        __ANSIEmu.state = __ANSI_STATE_SEQUENCE

                    CASE ELSE ' throw an error for stuff we are not handling
                        ERROR ERROR_FEATURE_UNAVAILABLE

                END SELECT

            CASE __ANSI_STATE_SEQUENCE ' handle CSI sequence
                SELECT CASE ch
                    CASE ANSI_0 TO ANSI_QUESTION_MARK ' argument bytes
                        IF __ANSIEmu.argIndex < 1 THEN __ANSIEmu.argIndex = 1 ' set the argument index to one if this is the first time

                        SELECT CASE ch
                            CASE ANSI_0 TO ANSI_9 ' handle sequence numeric arguments
                                __ANSIArg(__ANSIEmu.argIndex) = __ANSIArg(__ANSIEmu.argIndex) * 10 + ch - ANSI_0

                            CASE ANSI_SEMICOLON ' handle sequence argument seperators
                                __ANSIEmu.argIndex = __ANSIEmu.argIndex + 1 ' increment the argument index
                                IF __ANSIEmu.argIndex > UBOUND(__ANSIArg) THEN REDIM _PRESERVE __ANSIArg(1 TO __ANSIEmu.argIndex) AS LONG ' dynamically expand the argument list if needed

                            CASE ANSI_EQUALS_SIGN, ANSI_GREATER_THAN_SIGN, ANSI_QUESTION_MARK ' handle lead-in prefix
                                ' NOP: leadInPrefix = ch ' just save the prefix type

                            CASE ELSE ' throw an error for stuff we are not handling
                                ERROR ERROR_FEATURE_UNAVAILABLE

                        END SELECT

                    CASE ANSI_SP TO ANSI_SLASH ' intermediate bytes
                        SELECT CASE ch
                            CASE ANSI_SP ' ignore spaces
                                ' NOP

                            CASE ELSE ' throw an error for stuff we are not handling
                                ERROR ERROR_FEATURE_UNAVAILABLE

                        END SELECT

                    CASE ANSI_AT_SIGN TO ANSI_TILDE ' final byte
                        SELECT CASE ch
                            CASE ANSI_ESC_CSI_SM, ANSI_ESC_CSI_RM ' Set and reset screen mode
                                IF __ANSIEmu.argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                SELECT CASE __ANSIArg(1)
                                    CASE 0 TO 6, 14 TO 18 ' all mode changes are ignored. the screen type must be set by the caller
                                        ' NOP

                                    CASE 7 ' Enable / disable line wrapping
                                        ' NOP: QB64 does line wrapping by default
                                        IF ANSI_ESC_CSI_RM = ch THEN ' ANSI_ESC_CSI_RM disable line wrapping unsupported
                                            ERROR ERROR_FEATURE_UNAVAILABLE
                                        END IF

                                    CASE 12 ' Text Cursor Enable / Disable Blinking
                                        ' NOP

                                    CASE 25 ' make cursor visible / invisible
                                        IF ANSI_ESC_CSI_SM = ch THEN ' ANSI_ESC_CSI_SM make cursor visible
                                            LOCATE , , 1
                                        ELSE ' ANSI_ESC_CSI_RM make cursor invisible
                                            LOCATE , , 0
                                        END IF

                                    CASE ELSE ' throw an error for stuff we are not handling
                                        ERROR ERROR_FEATURE_UNAVAILABLE

                                END SELECT

                            CASE ANSI_ESC_CSI_ED ' Erase in Display
                                IF __ANSIEmu.argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                SELECT CASE __ANSIArg(1)
                                    CASE 0 ' clear from cursor to end of screen
                                        ClearANSICanvasArea POS(0), CSRLIN, GetANSICanvasWidth, CSRLIN ' first clear till the end of the line starting from the cursor
                                        ClearANSICanvasArea 1, CSRLIN + 1, GetANSICanvasWidth, GetANSICanvasHeight ' next clear the whole canvas below the cursor

                                    CASE 1 ' clear from cursor to beginning of the screen
                                        ClearANSICanvasArea 1, CSRLIN, POS(0), CSRLIN ' first clear from the beginning of the line till the cursor
                                        ClearANSICanvasArea 1, 1, GetANSICanvasWidth, CSRLIN - 1 ' next clear the whole canvas above the cursor

                                    CASE 2 ' clear entire screen (and moves cursor to upper left like ANSI.SYS)
                                        CLS

                                    CASE 3 ' clear entire screen and delete all lines saved in the scrollback buffer (scrollback stuff not supported)
                                        ClearANSICanvasArea 1, 1, GetANSICanvasWidth, GetANSICanvasHeight

                                    CASE ELSE ' throw an error for stuff we are not handling
                                        ERROR ERROR_FEATURE_UNAVAILABLE

                                END SELECT

                            CASE ANSI_ESC_CSI_EL ' Erase in Line
                                IF __ANSIEmu.argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                SELECT CASE __ANSIArg(1)
                                    CASE 0 ' erase from cursor to end of line
                                        ClearANSICanvasArea POS(0), CSRLIN, GetANSICanvasWidth, CSRLIN

                                    CASE 1 ' erase start of line to the cursor
                                        ClearANSICanvasArea 1, CSRLIN, POS(0), CSRLIN

                                    CASE 2 ' erase the entire line
                                        ClearANSICanvasArea 1, CSRLIN, GetANSICanvasWidth, CSRLIN

                                    CASE ELSE ' throw an error for stuff we are not handling
                                        ERROR ERROR_FEATURE_UNAVAILABLE

                                END SELECT

                            CASE ANSI_ESC_CSI_SGR ' Select Graphic Rendition
                                x = 1 ' start with the first argument
                                IF __ANSIEmu.argIndex < 1 THEN __ANSIEmu.argIndex = 1 ' this allows '[m' to be treated as [0m
                                DO WHILE x <= __ANSIEmu.argIndex ' loop through the argument list and process each argument
                                    SELECT CASE __ANSIArg(x)
                                        CASE 0 ' reset all modes (styles and colors)
                                            __ANSIEmu.fC = __ANSI_DEFAULT_COLOR_FOREGROUND
                                            __ANSIEmu.bC = __ANSI_DEFAULT_COLOR_BACKGROUND
                                            __ANSIEmu.isBold = FALSE
                                            __ANSIEmu.isBlink = FALSE
                                            __ANSIEmu.isInvert = FALSE
                                            SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE
                                            SetANSICanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, TRUE

                                        CASE 1 ' enable high intensity colors
                                            IF __ANSIEmu.fC < 8 THEN __ANSIEmu.fC = __ANSIEmu.fC + 8
                                            __ANSIEmu.isBold = TRUE
                                            SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE

                                        CASE 2, 22 ' enable low intensity, disable high intensity colors
                                            IF __ANSIEmu.fC > 7 THEN __ANSIEmu.fC = __ANSIEmu.fC - 8
                                            __ANSIEmu.isBold = FALSE
                                            SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE

                                        CASE 3, 4, 23, 24 ' set / reset italic & underline mode ignored
                                            ' NOP: This can be used if we load monospaced TTF fonts using 'italics', 'underline' properties

                                        CASE 5, 6 ' turn blinking on
                                            IF __ANSIEmu.bC < 8 THEN __ANSIEmu.bC = __ANSIEmu.bC + 8
                                            __ANSIEmu.isBlink = TRUE
                                            SetANSICanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, TRUE

                                        CASE 7 ' enable reverse video
                                            IF NOT __ANSIEmu.isInvert THEN
                                                __ANSIEmu.isInvert = TRUE
                                                SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE
                                                SetANSICanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, TRUE
                                            END IF

                                        CASE 25 ' turn blinking off
                                            IF __ANSIEmu.bC > 7 THEN __ANSIEmu.bC = __ANSIEmu.bC - 8
                                            __ANSIEmu.isBlink = FALSE
                                            SetANSICanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, TRUE

                                        CASE 27 ' disable reverse video
                                            IF __ANSIEmu.isInvert THEN
                                                __ANSIEmu.isInvert = FALSE
                                                SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE
                                                SetANSICanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, TRUE
                                            END IF

                                        CASE 30 TO 37 ' set foreground color
                                            __ANSIEmu.fC = __ANSIArg(x) - 30
                                            IF __ANSIEmu.isBold THEN __ANSIEmu.fC = __ANSIEmu.fC + 8
                                            SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE

                                        CASE 38 ' set 8-bit 256 or 24-bit RGB foreground color
                                            z = __ANSIEmu.argIndex - x ' get the number of arguments remaining

                                            IF __ANSIArg(x + 1) = 2 AND z >= 4 THEN ' 32bpp color with 5 arguments
                                                __ANSIEmu.fC = _RGB32(__ANSIArg(x + 2) AND &HFF, __ANSIArg(x + 3) AND &HFF, __ANSIArg(x + 4) AND &HFF)
                                                SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, FALSE

                                                x = x + 4 ' skip to last used arg

                                            ELSEIF __ANSIArg(x + 1) = 5 AND z >= 2 THEN ' 256 color with 3 arguments
                                                __ANSIEmu.fC = __ANSIArg(x + 2)
                                                SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE

                                                x = x + 2 ' skip to last used arg

                                            ELSE
                                                ERROR ERROR_CANNOT_CONTINUE

                                            END IF

                                        CASE 39 ' set default foreground color
                                            __ANSIEmu.fC = __ANSI_DEFAULT_COLOR_FOREGROUND
                                            SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE

                                        CASE 40 TO 47 ' set background color
                                            __ANSIEmu.bC = __ANSIArg(x) - 40
                                            IF __ANSIEmu.isBlink THEN __ANSIEmu.bC = __ANSIEmu.bC + 8
                                            SetANSICanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, TRUE

                                        CASE 48 ' set 8-bit 256 or 24-bit RGB background color
                                            z = __ANSIEmu.argIndex - x ' get the number of arguments remaining

                                            IF __ANSIArg(x + 1) = 2 AND z >= 4 THEN ' 32bpp color with 5 arguments
                                                __ANSIEmu.bC = _RGB32(__ANSIArg(x + 2) AND &HFF, __ANSIArg(x + 3) AND &HFF, __ANSIArg(x + 4) AND &HFF)
                                                SetANSICanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, FALSE

                                                x = x + 4 ' skip to last used arg

                                            ELSEIF __ANSIArg(x + 1) = 5 AND z >= 2 THEN ' 256 color with 3 arguments
                                                __ANSIEmu.bC = __ANSIArg(x + 2)
                                                SetANSICanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, TRUE

                                                x = x + 2 ' skip to last used arg

                                            ELSE
                                                ERROR ERROR_CANNOT_CONTINUE

                                            END IF

                                        CASE 49 ' set default background color
                                            __ANSIEmu.bC = __ANSI_DEFAULT_COLOR_BACKGROUND
                                            SetANSICanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, TRUE

                                        CASE 90 TO 97 ' set high intensity foreground color
                                            __ANSIEmu.fC = 8 + __ANSIArg(x) - 90
                                            SetANSICanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, TRUE

                                        CASE 100 TO 107 ' set high intensity background color
                                            __ANSIEmu.bC = 8 + __ANSIArg(x) - 100
                                            SetANSICanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, TRUE

                                        CASE ELSE ' throw an error for stuff we are not handling
                                            ERROR ERROR_FEATURE_UNAVAILABLE

                                    END SELECT

                                    x = x + 1 ' move to the next argument
                                LOOP

                            CASE ANSI_ESC_CSI_SCP ' Save Current Cursor Position (SCO)
                                IF __ANSIEmu.argIndex > 0 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting args

                                __ANSIEmu.posSCO.x = POS(0)
                                __ANSIEmu.posSCO.y = CSRLIN

                            CASE ANSI_ESC_CSI_RCP ' Restore Saved Cursor Position (SCO)
                                IF __ANSIEmu.argIndex > 0 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting args

                                LOCATE __ANSIEmu.posSCO.y, __ANSIEmu.posSCO.x

                            CASE ANSI_ESC_CSI_PABLODRAW_24BPP ' PabloDraw 24-bit ANSI sequences
                                IF __ANSIEmu.argIndex <> 4 THEN ERROR ERROR_CANNOT_CONTINUE ' we need 4 arguments

                                SetANSICanvasColor _RGB32(__ANSIArg(2) AND &HFF, __ANSIArg(3) AND &HFF, __ANSIArg(4) AND &HFF), __ANSIArg(1) = FALSE, FALSE

                            CASE ANSI_ESC_CSI_CUP, ANSI_ESC_CSI_HVP ' Cursor position or Horizontal and vertical position
                                IF __ANSIEmu.argIndex > 2 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 2 args

                                y = GetANSICanvasHeight
                                IF __ANSIArg(1) < 1 THEN
                                    __ANSIArg(1) = 1
                                ELSEIF __ANSIArg(1) > y THEN
                                    __ANSIArg(1) = y
                                END IF

                                x = GetANSICanvasWidth
                                IF __ANSIArg(2) < 1 THEN
                                    __ANSIArg(2) = 1
                                ELSEIF __ANSIArg(2) > x THEN
                                    __ANSIArg(2) = x
                                END IF

                                LOCATE __ANSIArg(1), __ANSIArg(2) ' line #, column #

                            CASE ANSI_ESC_CSI_CUU ' Cursor up
                                IF __ANSIEmu.argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                IF __ANSIArg(1) < 1 THEN __ANSIArg(1) = 1
                                y = CSRLIN - __ANSIArg(1)
                                IF y < 1 THEN y = 1
                                LOCATE y

                            CASE ANSI_ESC_CSI_CUD ' Cursor down
                                IF __ANSIEmu.argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                IF __ANSIArg(1) < 1 THEN __ANSIArg(1) = 1
                                y = CSRLIN + __ANSIArg(1)
                                z = GetANSICanvasHeight
                                IF y > z THEN y = z
                                LOCATE y

                            CASE ANSI_ESC_CSI_CUF ' Cursor forward
                                IF __ANSIEmu.argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                IF __ANSIArg(1) < 1 THEN __ANSIArg(1) = 1
                                x = POS(0) + __ANSIArg(1)
                                z = GetANSICanvasWidth
                                IF x > z THEN x = z
                                LOCATE , x

                            CASE ANSI_ESC_CSI_CUB ' Cursor back
                                IF __ANSIEmu.argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                IF __ANSIArg(1) < 1 THEN __ANSIArg(1) = 1
                                x = POS(0) - __ANSIArg(1)
                                IF x < 1 THEN x = 1
                                LOCATE , x

                            CASE ANSI_ESC_CSI_CNL ' Cursor Next Line
                                IF __ANSIEmu.argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                IF __ANSIArg(1) < 1 THEN __ANSIArg(1) = 1
                                y = CSRLIN + __ANSIArg(1)
                                z = GetANSICanvasHeight
                                IF y > z THEN y = z
                                LOCATE y, 1

                            CASE ANSI_ESC_CSI_CPL ' Cursor Previous Line
                                IF __ANSIEmu.argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                IF __ANSIArg(1) < 1 THEN __ANSIArg(1) = 1
                                y = CSRLIN - __ANSIArg(1)
                                IF y < 1 THEN y = 1
                                LOCATE y, 1

                            CASE ANSI_ESC_CSI_CHA ' Cursor Horizontal Absolute
                                IF __ANSIEmu.argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                x = GetANSICanvasWidth
                                IF __ANSIArg(1) < 1 THEN
                                    __ANSIArg(1) = 1
                                ELSEIF __ANSIArg(1) > x THEN
                                    __ANSIArg(1) = x
                                END IF
                                LOCATE , __ANSIArg(1)

                            CASE ANSI_ESC_CSI_VPA ' Vertical Line Position Absolute
                                IF __ANSIEmu.argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                y = GetANSICanvasHeight
                                IF __ANSIArg(1) < 1 THEN
                                    __ANSIArg(1) = 1
                                ELSEIF __ANSIArg(1) > y THEN
                                    __ANSIArg(1) = y
                                END IF
                                LOCATE __ANSIArg(1)

                            CASE ANSI_ESC_CSI_DECSCUSR
                                IF __ANSIEmu.argIndex > 1 THEN ERROR ERROR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                                SELECT CASE __ANSIArg(1)
                                    CASE 0, 3, 4 ' Default, Blinking & Steady underline cursor shape
                                        LOCATE , , , 29, 31 ' this should give a nice underline cursor

                                    CASE 1, 2 ' Blinking & Steady block cursor shape
                                        LOCATE , , , 0, 31 ' this should give a full block cursor

                                    CASE 5, 6 ' Blinking & Steady bar cursor shape
                                        LOCATE , , , 16, 31 ' since we cannot get a bar cursor in QB64, we'll just use a half-block cursor

                                    CASE ELSE ' throw an error for stuff we are not handling
                                        ERROR ERROR_FEATURE_UNAVAILABLE

                                END SELECT

                            CASE ELSE ' throw an error for stuff we are not handling
                                ERROR ERROR_FEATURE_UNAVAILABLE

                        END SELECT

                        ' End of sequence
                        __ANSIEmu.state = __ANSI_STATE_TEXT

                    CASE ELSE ' throw an error for stuff we are not handling
                        ERROR ERROR_FEATURE_UNAVAILABLE

                END SELECT

            CASE __ANSI_STATE_END ' end of the stream has been reached
                PrintANSICharacter& = FALSE ' tell the caller the we should stop processing the rest of the stream
                EXIT FUNCTION ' and then leave

            CASE ELSE ' this should never happen
                ERROR ERROR_CANNOT_CONTINUE

        END SELECT

        __ANSIEmu.lastChar = ch ' save the character
    END FUNCTION

    ' Processes the whole string instead of a character like PrintANSICharacter()
    ' This simply wraps PrintANSICharacter()
    FUNCTION PrintANSIString& (s AS STRING)
        DIM AS LONG i

        PrintANSIString = TRUE

        FOR i = 1 TO LEN(s)
            IF NOT PrintANSICharacter(ASC(s, i)) THEN
                PrintANSIString = FALSE ' signal end of stream
                EXIT FUNCTION
            END IF
        NEXT
    END FUNCTION

    ' A simple routine that wraps pretty much the whole library
    ' It will reset the library, do the setup and then render the whole ANSI string in one go
    ' ControlChr is properly restored
    SUB PrintANSI (sANSI AS STRING)
        DIM AS LONG oldControlChr ' to save old ContolChr

        ' Save the old ControlChr state
        oldControlChr = _CONTROLCHR

        ResetANSIEmulator ' reset the emulator

        DIM dummy AS LONG: dummy = PrintANSIString(sANSI) ' print the ANSI string and ignore the return value

        ' Set ControlChr the way we found it
        IF oldControlChr THEN
            _CONTROLCHR OFF
        ELSE
            _CONTROLCHR ON
        END IF
    END SUB

    ' Set the foreground or background color
    SUB SetANSICanvasColor (c AS _UNSIGNED LONG, isBackground AS LONG, isLegacy AS LONG)
        SHARED __ANSIColorLUT() AS _UNSIGNED LONG

        DIM nRGB AS _UNSIGNED LONG

        IF isLegacy THEN
            nRGB = __ANSIColorLUT(c)
        ELSE
            nRGB = c
        END IF

        IF isBackground THEN
            ' Echo "Background color" + Str$(c) + " (" + Hex$(nRGB) + ")"
            COLOR , nRGB
        ELSE
            ' Echo "Foreground color" + Str$(c) + " (" + Hex$(nRGB) + ")"
            COLOR nRGB
        END IF
    END SUB

    ' Returns the number of characters per line
    FUNCTION GetANSICanvasWidth&
        GetANSICanvasWidth = _WIDTH \ _FONTWIDTH ' this will cause a divide by zero if a variable width font is used; use monospaced fonts to avoid this
    END FUNCTION

    ' Returns the number of lines
    FUNCTION GetANSICanvasHeight&
        GetANSICanvasHeight = _HEIGHT \ _FONTHEIGHT
    END FUNCTION

    ' Clears a given portion of screen without disturbing the cursor location and colors
    SUB ClearANSICanvasArea (l AS LONG, t AS LONG, r AS LONG, b AS LONG)
        DIM AS LONG i, w, x, y
        DIM AS _UNSIGNED LONG fc, bc

        w = 1 + r - l ' calculate width

        IF w > 0 AND t <= b THEN ' only proceed is width is > 0 and height is > 0
            ' Save some stuff
            fc = _DEFAULTCOLOR
            bc = _BACKGROUNDCOLOR
            x = POS(0)
            y = CSRLIN

            COLOR BGRA_BLACK, BGRA_BLACK ' lights out

            FOR i = t TO b
                LOCATE i, l: PRINT SPACE$(w); ' fill with SPACE
            NEXT

            ' Restore saved stuff
            COLOR fc, bc
            LOCATE y, x
        END IF
    END SUB

    '$INCLUDE:'ColorOps.bas'

$END IF

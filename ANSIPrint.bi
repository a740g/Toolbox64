'-----------------------------------------------------------------------------------------------------------------------
' ANSI Escape Sequence Emulator
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF ANSIPRINT_BI = UNDEFINED THEN
    $LET ANSIPRINT_BI = TRUE

    '$INCLUDE:'Common.bi'
    '$INCLUDE:'Types.bi'
    '$INCLUDE:'ColorOps.bi'

    ' ANSI constants (not an exhaustive list)
    CONST ANSI_NUL = 0 ' Null
    CONST ANSI_SOH = 1 ' Start of Heading
    CONST ANSI_STX = 2 ' Start of Text
    CONST ANSI_ETX = 3 ' End of Text
    CONST ANSI_EOT = 4 ' End of Transmission
    CONST ANSI_ENQ = 5 ' Enquiry
    CONST ANSI_ACK = 6 ' Acknowledgement
    CONST ANSI_BEL = 7 ' Bell
    CONST ANSI_BS = 8 ' Backspace
    CONST ANSI_HT = 9 ' Horizontal Tab
    CONST ANSI_LF = 10 ' Line Feed
    CONST ANSI_VT = 11 ' Vertical Tab
    CONST ANSI_FF = 12 ' Form Feed
    CONST ANSI_CR = 13 ' Carriage Return
    CONST ANSI_SO = 14 ' Shift Out
    CONST ANSI_SI = 15 ' Shift In
    CONST ANSI_DLE = 16 ' Data Link Escape
    CONST ANSI_DC1 = 17 ' Device Control 1
    CONST ANSI_DC2 = 18 ' Device Control 2
    CONST ANSI_DC3 = 19 ' Device Control 3
    CONST ANSI_DC4 = 20 ' Device Control 4
    CONST ANSI_NAK = 21 ' Negative Acknowledgement
    CONST ANSI_SYN = 22 ' Synchronous Idle
    CONST ANSI_ETB = 23 ' End of Transmission Block
    CONST ANSI_CAN = 24 ' Cancel
    CONST ANSI_EM = 25 ' End of Medium
    CONST ANSI_SUB = 26 ' Substitute
    CONST ANSI_ESC = 27 ' Escape
    CONST ANSI_FS = 28 ' File Separator
    CONST ANSI_GS = 29 ' Group Separator
    CONST ANSI_RS = 30 ' Record Separator
    CONST ANSI_US = 31 ' Unit Separator
    CONST ANSI_SP = 32 ' Space
    CONST ANSI_SLASH = 47 ' /
    CONST ANSI_0 = 48 ' 0
    CONST ANSI_ESC_DECSC = 55 ' Save Cursor Position in Memory
    CONST ANSI_ESC_DECSR = 56 ' Restore Cursor Position from Memory
    CONST ANSI_9 = 57 ' 9
    CONST ANSI_COLON = 58 ' :
    CONST ANSI_SEMICOLON = 59 ' ;
    CONST ANSI_LESS_THAN_SIGN = 60 ' <
    CONST ANSI_EQUALS_SIGN = 61 ' =
    CONST ANSI_GREATER_THAN_SIGN = 62 ' >
    CONST ANSI_QUESTION_MARK = 63 ' ?
    CONST ANSI_AT_SIGN = 64 ' @
    CONST ANSI_ESC_CSI_CUU = 65 ' Cursor Up
    CONST ANSI_ESC_CSI_CUD = 66 ' Cursor Down
    CONST ANSI_ESC_CSI_CUF = 67 ' Cursor Forward/Right
    CONST ANSI_ESC_CSI_CUB = 68 ' Cursor Back/Left
    CONST ANSI_ESC_CSI_CNL = 69 ' Cursor Next Line
    CONST ANSI_ESC_CSI_CPL = 70 ' Cursor Previous Line
    CONST ANSI_ESC_CSI_CHA = 71 ' Cursor Horizontal Absolute
    CONST ANSI_ESC_CSI_CUP = 72 ' Cursor Position
    CONST ANSI_ESC_CSI_ED = 74 ' Erase in Display
    CONST ANSI_ESC_CSI_EL = 75 ' Erase in Line
    CONST ANSI_ESC_CSI_IL = 76 ' ANSI.SYS: Insert line
    CONST ANSI_ESC_CSI_DL = 77 ' ANSI.SYS: Delete line
    CONST ANSI_ESC_RI = 77 ' Reverse Index
    CONST ANSI_ESC_SS2 = 78 ' Single Shift Two
    CONST ANSI_ESC_SS3 = 79 ' Single Shift Three
    CONST ANSI_ESC_DCS = 80 ' Device Control String
    CONST ANSI_ESC_CSI_SU = 83 ' Scroll Up
    CONST ANSI_ESC_CSI_SD = 84 ' Scroll Down
    CONST ANSI_ESC_SOS = 88 ' Start of String
    CONST ANSI_ESC_CSI = 91 ' Control Sequence Introducer
    CONST ANSI_ESC_ST = 92 ' String Terminator
    CONST ANSI_ESC_OSC = 93 ' Operating System Command
    CONST ANSI_ESC_PM = 94 ' Privacy Message
    CONST ANSI_ESC_APC = 95 ' Application Program Command
    CONST ANSI_ESC_CSI_VPA = 100 ' Vertical Line Position Absolute
    CONST ANSI_ESC_CSI_HVP = 102 ' Horizontal Vertical Position
    CONST ANSI_ESC_CSI_SM = 104 ' ANSI.SYS: Set screen mode
    CONST ANSI_ESC_CSI_RM = 108 ' ANSI.SYS: Reset screen mode
    CONST ANSI_ESC_CSI_SGR = 109 ' Select Graphic Rendition
    CONST ANSI_ESC_CSI_DSR = 110 ' Device status report
    CONST ANSI_ESC_CSI_DECSCUSR = 113 ' Cursor Shape
    CONST ANSI_ESC_CSI_SCP = 115 ' Save Current Cursor Position
    CONST ANSI_ESC_CSI_PABLODRAW_24BPP = 116 ' PabloDraw 24-bit ANSI sequences
    CONST ANSI_ESC_CSI_RCP = 117 ' Restore Saved Cursor Position
    CONST ANSI_TILDE = 126 ' ~
    CONST ANSI_DEL = 127 ' Delete
    ' Parser state
    CONST __ANSI_STATE_TEXT = 0 ' when parsing regular text & control characters
    CONST __ANSI_STATE_BEGIN = 1 ' when beginning an escape sequence
    CONST __ANSI_STATE_SEQUENCE = 2 ' when parsing a control sequence introducer
    CONST __ANSI_STATE_END = 3 ' when the end of the character stream has been reached
    ' Some defaults
    CONST __ANSI_DEFAULT_COLOR_FOREGROUND = 7
    CONST __ANSI_DEFAULT_COLOR_BACKGROUND = 0
    CONST __ANSI_ARG_COUNT = 10 ' number of argument slots that we'll start with

    TYPE __ANSIEmulatorType
        isInitialized AS LONG ' was the library initialized?
        state AS LONG ' the current parser state
        argIndex AS LONG ' the current CSI argument index & count; 0 means no arguments
        fC AS _UNSIGNED LONG ' foreground color
        bC AS _UNSIGNED LONG ' background color
        isBold AS LONG ' text attributes - high intensity bg color
        isBlink AS LONG ' text attributes - we make this high intensity as well
        isInvert AS LONG ' text attributes - inverted colors (fg <> bg)
        posDEC AS Vector2LType ' DEC saved cursor position
        posSCO AS Vector2LType ' SCO saved cursor position
        lastChar AS _UNSIGNED _BYTE ' last character rendered
        lastCharX AS LONG ' the x position of the last "printed" character
        CPS AS LONG ' characters / second
    END TYPE

    DIM __ANSIEmu AS __ANSIEmulatorType ' emulator state
    DIM __ANSIColorLUT(0 TO 255) AS _UNSIGNED LONG ' this table is used to get the RGB for legacy ANSI colors
    REDIM __ANSIArg(1 TO __ANSI_ARG_COUNT) AS LONG ' CSI dynamic argument list

$END IF

'-----------------------------------------------------------------------------------------------------------------------
' ANSI Escape Sequence Emulator
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Core/Common.bi'
'$INCLUDE:'../Core/Types.bi'
'$INCLUDE:'Graphics2D.bi'
'$INCLUDE:'../Resource/SAUCE.bi'
'$INCLUDE:'../Math/Vector2i.bi'

' ANSI constants
CONST ANSI_ESC_DECSC = 55 ' Save Cursor Position in Memory
CONST ANSI_ESC_DECSR = 56 ' Restore Cursor Position from Memory
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
    isInvert AS LONG ' text attributes - inverted colors (fg <--> bg)
    posDEC AS Vector2i ' DEC saved cursor position
    posSCO AS Vector2i ' SCO saved cursor position
    lastChar AS _UNSIGNED _BYTE ' last character rendered
    lastCharX AS LONG ' the x position of the last "printed" character
    CPS AS LONG ' characters / second
END TYPE

DIM __ANSIEmu AS __ANSIEmulatorType ' emulator state
DIM __ANSIColorLUT(0 TO 255) AS BGRAType ' this table is used to get the RGB for legacy ANSI colors
REDIM __ANSIArg(1 TO __ANSI_ARG_COUNT) AS LONG ' CSI dynamic argument list

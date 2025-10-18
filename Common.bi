'-----------------------------------------------------------------------------------------------------------------------
' Common header
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

$IF VERSION < 4.2.0 THEN
    $ERROR 'This requires the latest version of QB64-PE from https://github.com/QB64-Phoenix-Edition/QB64pe/releases/latest'
$END IF

$IF TOOLBOX64_STRICT = DEFINED AND TOOLBOX64_STRICT = TRUE THEN
    ' All identifiers must default to long (32-bits). This results in fastest code execution on x86 & x64.
    _DEFINE A-Z AS LONG

    ' Force all arrays to be defined (technically not required, since we use _EXPLICIT below).
    OPTION _EXPLICITARRAY

    ' Force all variables to be defined.
    OPTION _EXPLICIT

    ' All arrays should be static. If dynamic arrays are required, then use "REDIM".
    '$STATIC

    ' Start array lower bound from 1. If 0 is required, then use the syntax [RE]DIM (0 To {X}) AS {TYPE}.
    OPTION BASE 1
$END IF

' These constants should be move to their appropriate files later.

CONST KEY_SPACE~%% = 32~%%
CONST KEY_EXCLAMATION_MARK~%% = 33~%%, ASC_EXCLAMATION_MARK~%% = 33~%%, CHR_EXCLAMATION_MARK = CHR$(33)
CONST KEY_QUOTATION_MARK~%% = 34~%%, ASC_QUOTATION_MARK~%% = 34~%%, CHR_QUOTATION_MARK = CHR$(34)
CONST KEY_HASH~%% = 35~%%, ASC_HASH~%% = 35~%%, CHR_HASH = CHR$(35)
CONST KEY_DOLLAR~%% = 36~%%, ASC_DOLLAR~%% = 36~%%, CHR_DOLLAR = CHR$(36)
CONST KEY_PERCENT~%% = 37~%%, ASC_PERCENT~%% = 37~%%, CHR_PERCENT = CHR$(37)
CONST KEY_AMPERSAND~%% = 38~%%, ASC_AMPERSAND~%% = 38~%%, CHR_AMPERSAND = CHR$(38)
CONST KEY_APOSTROPHE~%% = 39~%%, ASC_APOSTROPHE~%% = 39~%%, CHR_APOSTROPHE = CHR$(39)
CONST KEY_OPEN_PARENTHESIS~%% = 40~%%, ASC_OPEN_PARENTHESIS~%% = 40~%%, CHR_OPEN_PARENTHESIS = CHR$(40)
CONST KEY_CLOSE_PARENTHESIS~%% = 41~%%, ASC_CLOSE_PARENTHESIS~%% = 41~%%, CHR_CLOSE_PARENTHESIS = CHR$(41)
CONST KEY_ASTERISK~%% = 42~%%, ASC_ASTERISK~%% = 42~%%, CHR_ASTERISK = CHR$(42)
CONST KEY_PLUS~%% = 43~%%, ASC_PLUS~%% = 43~%%, CHR_PLUS = CHR$(43)
CONST KEY_COMMA~%% = 44~%%, ASC_COMMA~%% = 44~%%, CHR_COMMA = CHR$(44)
CONST KEY_MINUS~%% = 45~%%, ASC_MINUS~%% = 45~%%, CHR_MINUS = CHR$(45)
CONST KEY_DOT~%% = 46~%%, ASC_DOT~%% = 46~%%, CHR_DOT = CHR$(46)
CONST KEY_SLASH~%% = 47~%%, ASC_SLASH~%% = 47~%%, CHR_SLASH = CHR$(47)
CONST KEY_0~%% = 48~%%, ASC_0~%% = 48~%%, CHR_0 = CHR$(48)
CONST KEY_1~%% = 49~%%, ASC_1~%% = 49~%%, CHR_1 = CHR$(49)
CONST KEY_2~%% = 50~%%, ASC_2~%% = 50~%%, CHR_2 = CHR$(50)
CONST KEY_3~%% = 51~%%, ASC_3~%% = 51~%%, CHR_3 = CHR$(51)
CONST KEY_4~%% = 52~%%, ASC_4~%% = 52~%%, CHR_4 = CHR$(52)
CONST KEY_5~%% = 53~%%, ASC_5~%% = 53~%%, CHR_5 = CHR$(53)
CONST KEY_6~%% = 54~%%, ASC_6~%% = 54~%%, CHR_6 = CHR$(54)
CONST KEY_7~%% = 55~%%, ASC_7~%% = 55~%%, CHR_7 = CHR$(55)
CONST KEY_8~%% = 56~%%, ASC_8~%% = 56~%%, CHR_8 = CHR$(56)
CONST KEY_9~%% = 57~%%, ASC_9~%% = 57~%%, CHR_9 = CHR$(57)
CONST KEY_COLON~%% = 58~%%, ASC_COLON~%% = 58~%%, CHR_COLON = CHR$(58)
CONST KEY_SEMICOLON~%% = 59~%%, ASC_SEMICOLON~%% = 59~%%, CHR_SEMICOLON = CHR$(59)
CONST KEY_LESS_THAN~%% = 60~%%, ASC_LESS_THAN~%% = 60~%%, CHR_LESS_THAN = CHR$(60)
CONST KEY_EQUALS~%% = 61~%%, ASC_EQUALS~%% = 61~%%, CHR_EQUALS = CHR$(61)
CONST KEY_GREATER_THAN~%% = 62~%%, ASC_GREATER_THAN~%% = 62~%%, CHR_GREATER_THAN = CHR$(62)
CONST KEY_QUESTION_MARK~%% = 63~%%, ASC_QUESTION_MARK~%% = 63~%%, CHR_QUESTION_MARK = CHR$(63)
CONST KEY_AT~%% = 64~%%, ASC_AT~%% = 64~%%, CHR_AT = CHR$(64)
CONST KEY_UPPER_A~%% = 65~%%, ASC_UPPER_A~%% = 65~%%, CHR_UPPER_A = CHR$(65)
CONST KEY_UPPER_B~%% = 66~%%, ASC_UPPER_B~%% = 66~%%, CHR_UPPER_B = CHR$(66)
CONST KEY_UPPER_C~%% = 67~%%, ASC_UPPER_C~%% = 67~%%, CHR_UPPER_C = CHR$(67)
CONST KEY_UPPER_D~%% = 68~%%, ASC_UPPER_D~%% = 68~%%, CHR_UPPER_D = CHR$(68)
CONST KEY_UPPER_E~%% = 69~%%, ASC_UPPER_E~%% = 69~%%, CHR_UPPER_E = CHR$(69)
CONST KEY_UPPER_F~%% = 70~%%, ASC_UPPER_F~%% = 70~%%, CHR_UPPER_F = CHR$(70)
CONST KEY_UPPER_G~%% = 71~%%, ASC_UPPER_G~%% = 71~%%, CHR_UPPER_G = CHR$(71)
CONST KEY_UPPER_H~%% = 72~%%, ASC_UPPER_H~%% = 72~%%, CHR_UPPER_H = CHR$(72)
CONST KEY_UPPER_I~%% = 73~%%, ASC_UPPER_I~%% = 73~%%, CHR_UPPER_I = CHR$(73)
CONST KEY_UPPER_J~%% = 74~%%, ASC_UPPER_J~%% = 74~%%, CHR_UPPER_J = CHR$(74)
CONST KEY_UPPER_K~%% = 75~%%, ASC_UPPER_K~%% = 75~%%, CHR_UPPER_K = CHR$(75)
CONST KEY_UPPER_L~%% = 76~%%, ASC_UPPER_L~%% = 76~%%, CHR_UPPER_L = CHR$(76)
CONST KEY_UPPER_M~%% = 77~%%, ASC_UPPER_M~%% = 77~%%, CHR_UPPER_M = CHR$(77)
CONST KEY_UPPER_N~%% = 78~%%, ASC_UPPER_N~%% = 78~%%, CHR_UPPER_N = CHR$(78)
CONST KEY_UPPER_O~%% = 79~%%, ASC_UPPER_O~%% = 79~%%, CHR_UPPER_O = CHR$(79)
CONST KEY_UPPER_P~%% = 80~%%, ASC_UPPER_P~%% = 80~%%, CHR_UPPER_P = CHR$(80)
CONST KEY_UPPER_Q~%% = 81~%%, ASC_UPPER_Q~%% = 81~%%, CHR_UPPER_Q = CHR$(81)
CONST KEY_UPPER_R~%% = 82~%%, ASC_UPPER_R~%% = 82~%%, CHR_UPPER_R = CHR$(82)
CONST KEY_UPPER_S~%% = 83~%%, ASC_UPPER_S~%% = 83~%%, CHR_UPPER_S = CHR$(83)
CONST KEY_UPPER_T~%% = 84~%%, ASC_UPPER_T~%% = 84~%%, CHR_UPPER_T = CHR$(84)
CONST KEY_UPPER_U~%% = 85~%%, ASC_UPPER_U~%% = 85~%%, CHR_UPPER_U = CHR$(85)
CONST KEY_UPPER_V~%% = 86~%%, ASC_UPPER_V~%% = 86~%%, CHR_UPPER_V = CHR$(86)
CONST KEY_UPPER_W~%% = 87~%%, ASC_UPPER_W~%% = 87~%%, CHR_UPPER_W = CHR$(87)
CONST KEY_UPPER_X~%% = 88~%%, ASC_UPPER_X~%% = 88~%%, CHR_UPPER_X = CHR$(88)
CONST KEY_UPPER_Y~%% = 89~%%, ASC_UPPER_Y~%% = 89~%%, CHR_UPPER_Y = CHR$(89)
CONST KEY_UPPER_Z~%% = 90~%%, ASC_UPPER_Z~%% = 90~%%, CHR_UPPER_Z = CHR$(90)
CONST KEY_OPEN_BRACKET~%% = 91~%%, ASC_OPEN_BRACKET~%% = 91~%%, CHR_OPEN_BRACKET = CHR$(91)
CONST KEY_BACKSLASH~%% = 92~%%, ASC_BACKSLASH~%% = 92~%%, CHR_BACKSLASH = CHR$(92)
CONST KEY_CLOSE_BRACKET~%% = 93~%%, ASC_CLOSE_BRACKET~%% = 93~%%, CHR_CLOSE_BRACKET = CHR$(93)
CONST KEY_CARET~%% = 94~%%, ASC_CARET~%% = 94~%%, CHR_CARET = CHR$(94)
CONST KEY_UNDERSCORE~%% = 95~%%, ASC_UNDERSCORE~%% = 95~%%, CHR_UNDERSCORE = CHR$(95)
CONST KEY_GRAVE~%% = 96~%%, ASC_GRAVE~%% = 96~%%, CHR_GRAVE = CHR$(96)
CONST KEY_LOWER_A~%% = 97~%%, ASC_LOWER_A~%% = 97~%%, CHR_LOWER_A = CHR$(97)
CONST KEY_LOWER_B~%% = 98~%%, ASC_LOWER_B~%% = 98~%%, CHR_LOWER_B = CHR$(98)
CONST KEY_LOWER_C~%% = 99~%%, ASC_LOWER_C~%% = 99~%%, CHR_LOWER_C = CHR$(99)
CONST KEY_LOWER_D~%% = 100~%%, ASC_LOWER_D~%% = 100~%%, CHR_LOWER_D = CHR$(100)
CONST KEY_LOWER_E~%% = 101~%%, ASC_LOWER_E~%% = 101~%%, CHR_LOWER_E = CHR$(101)
CONST KEY_LOWER_F~%% = 102~%%, ASC_LOWER_F~%% = 102~%%, CHR_LOWER_F = CHR$(102)
CONST KEY_LOWER_G~%% = 103~%%, ASC_LOWER_G~%% = 103~%%, CHR_LOWER_G = CHR$(103)
CONST KEY_LOWER_H~%% = 104~%%, ASC_LOWER_H~%% = 104~%%, CHR_LOWER_H = CHR$(104)
CONST KEY_LOWER_I~%% = 105~%%, ASC_LOWER_I~%% = 105~%%, CHR_LOWER_I = CHR$(105)
CONST KEY_LOWER_J~%% = 106~%%, ASC_LOWER_J~%% = 106~%%, CHR_LOWER_J = CHR$(106)
CONST KEY_LOWER_K~%% = 107~%%, ASC_LOWER_K~%% = 107~%%, CHR_LOWER_K = CHR$(107)
CONST KEY_LOWER_L~%% = 108~%%, ASC_LOWER_L~%% = 108~%%, CHR_LOWER_L = CHR$(108)
CONST KEY_LOWER_M~%% = 109~%%, ASC_LOWER_M~%% = 109~%%, CHR_LOWER_M = CHR$(109)
CONST KEY_LOWER_N~%% = 110~%%, ASC_LOWER_N~%% = 110~%%, CHR_LOWER_N = CHR$(110)
CONST KEY_LOWER_O~%% = 111~%%, ASC_LOWER_O~%% = 111~%%, CHR_LOWER_O = CHR$(111)
CONST KEY_LOWER_P~%% = 112~%%, ASC_LOWER_P~%% = 112~%%, CHR_LOWER_P = CHR$(112)
CONST KEY_LOWER_Q~%% = 113~%%, ASC_LOWER_Q~%% = 113~%%, CHR_LOWER_Q = CHR$(113)
CONST KEY_LOWER_R~%% = 114~%%, ASC_LOWER_R~%% = 114~%%, CHR_LOWER_R = CHR$(114)
CONST KEY_LOWER_S~%% = 115~%%, ASC_LOWER_S~%% = 115~%%, CHR_LOWER_S = CHR$(115)
CONST KEY_LOWER_T~%% = 116~%%, ASC_LOWER_T~%% = 116~%%, CHR_LOWER_T = CHR$(116)
CONST KEY_LOWER_U~%% = 117~%%, ASC_LOWER_U~%% = 117~%%, CHR_LOWER_U = CHR$(117)
CONST KEY_LOWER_V~%% = 118~%%, ASC_LOWER_V~%% = 118~%%, CHR_LOWER_V = CHR$(118)
CONST KEY_LOWER_W~%% = 119~%%, ASC_LOWER_W~%% = 119~%%, CHR_LOWER_W = CHR$(119)
CONST KEY_LOWER_X~%% = 120~%%, ASC_LOWER_X~%% = 120~%%, CHR_LOWER_X = CHR$(120)
CONST KEY_LOWER_Y~%% = 121~%%, ASC_LOWER_Y~%% = 121~%%, CHR_LOWER_Y = CHR$(121)
CONST KEY_LOWER_Z~%% = 122~%%, ASC_LOWER_Z~%% = 122~%%, CHR_LOWER_Z = CHR$(122)
CONST KEY_OPEN_BRACE~%% = 123~%%, ASC_OPEN_BRACE~%% = 123~%%, CHR_OPEN_BRACE = CHR$(123)
CONST KEY_VERTICAL_BAR~%% = 124~%%, ASC_VERTICAL_BAR~%% = 124~%%, CHR_VERTICAL_BAR = CHR$(124)
CONST KEY_CLOSE_BRACE~%% = 125~%%, ASC_CLOSE_BRACE~%% = 125~%%, CHR_CLOSE_BRACE = CHR$(125)
CONST KEY_TILDE~%% = 126~%%, ASC_TILDE~%% = 126~%%, CHR_TILDE = CHR$(126)

' Some of the type below do not have a "home" yet and should be moved to appropriate files later

' A simple integer 2D vector.
TYPE Vector2LType
    x AS LONG
    y AS LONG
END TYPE

' A simple integer 2D vector.
TYPE Vector3LType
    x AS LONG
    y AS LONG
    z AS LONG
END TYPE

' A simple floating-point 2D vector.
TYPE Vector3FType
    x AS SINGLE
    y AS SINGLE
    z AS SINGLE
END TYPE

DECLARE LIBRARY "Common"
    FUNCTION Compiler_GetDate$
    FUNCTION Compiler_GetTime$
    FUNCTION Compiler_GetFunctionName$
    FUNCTION Compiler_GetPrettyFunctionName$
END DECLARE

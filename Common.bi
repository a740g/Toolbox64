'-----------------------------------------------------------------------------------------------------------------------
' Common header
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF COMMON_BI = UNDEFINED THEN
    $LET COMMON_BI = TRUE

    ' Check QB64-PE compiler version and complain if it does not meet minimum version requirement
    $IF VERSION < 3.8 THEN
            $ERROR This requires the latest version of QB64-PE from https://github.com/QB64-Phoenix-Edition/QB64pe/releases/latest
    $END IF

    ' All identifiers must default to long (32-bits). This results in fastest code execution on x86 & x64
    DEFLNG A-Z

    ' Force all arrays to be defined (technically not required, since we use _EXPLICIT below)
    OPTION _EXPLICITARRAY

    ' Force all variables to be defined
    OPTION _EXPLICIT

    ' All arrays should be static. If dynamic arrays are required, then use "REDIM"
    '$STATIC

    ' Start array lower bound from 1. If 0 is required, then use the syntax [RE]DIM (0 To {X}) AS {TYPE}
    OPTION BASE 1

    ' These constants should be move to their appropriate files later

    ' Common keyboard key codes (also ASCII codes)
    CONST KEY_BACKSPACE = 8
    CONST KEY_TAB = 9
    CONST KEY_ENTER = 13
    CONST KEY_ESCAPE = 27
    CONST KEY_SPACE = 32
    CONST KEY_EXCLAMATION_MARK = 33
    CONST KEY_QUOTATION_MARK = 34
    CONST KEY_APOSTROPHE = 39
    CONST KEY_OPEN_PARENTHESIS = 40
    CONST KEY_CLOSE_PARENTHESIS = 41
    CONST KEY_ASTERISK = 42
    CONST KEY_PLUS = 43
    CONST KEY_COMMA = 44
    CONST KEY_MINUS = 45
    CONST KEY_DOT = 46
    CONST KEY_SLASH = 47
    CONST KEY_0 = 48
    CONST KEY_1 = 49
    CONST KEY_2 = 50
    CONST KEY_3 = 51
    CONST KEY_4 = 52
    CONST KEY_5 = 53
    CONST KEY_6 = 54
    CONST KEY_7 = 55
    CONST KEY_8 = 56
    CONST KEY_9 = 57
    CONST KEY_COLON = 58
    CONST KEY_SEMICOLON = 59
    CONST KEY_LESS_THAN = 60
    CONST KEY_EQUALS = 61
    CONST KEY_GREATER_THAN = 62
    CONST KEY_QUESTION_MARK = 63
    CONST KEY_UPPER_A = 65
    CONST KEY_UPPER_B = 66
    CONST KEY_UPPER_C = 67
    CONST KEY_UPPER_D = 68
    CONST KEY_UPPER_E = 69
    CONST KEY_UPPER_F = 70
    CONST KEY_UPPER_G = 71
    CONST KEY_UPPER_H = 72
    CONST KEY_UPPER_I = 73
    CONST KEY_UPPER_J = 74
    CONST KEY_UPPER_K = 75
    CONST KEY_UPPER_L = 76
    CONST KEY_UPPER_M = 77
    CONST KEY_UPPER_N = 78
    CONST KEY_UPPER_O = 79
    CONST KEY_UPPER_P = 80
    CONST KEY_UPPER_Q = 81
    CONST KEY_UPPER_R = 82
    CONST KEY_UPPER_S = 83
    CONST KEY_UPPER_T = 84
    CONST KEY_UPPER_U = 85
    CONST KEY_UPPER_V = 86
    CONST KEY_UPPER_W = 87
    CONST KEY_UPPER_X = 88
    CONST KEY_UPPER_Y = 89
    CONST KEY_UPPER_Z = 90
    CONST KEY_OPEN_BRACKET = 91
    CONST KEY_BACKSLASH = 92
    CONST KEY_CLOSE_BRACKET = 93
    CONST KEY_UNDERSCORE = 95
    CONST KEY_LOWER_A = 97
    CONST KEY_LOWER_B = 98
    CONST KEY_LOWER_C = 99
    CONST KEY_LOWER_D = 100
    CONST KEY_LOWER_E = 101
    CONST KEY_LOWER_F = 102
    CONST KEY_LOWER_G = 103
    CONST KEY_LOWER_H = 104
    CONST KEY_LOWER_I = 105
    CONST KEY_LOWER_J = 106
    CONST KEY_LOWER_K = 107
    CONST KEY_LOWER_L = 108
    CONST KEY_LOWER_M = 109
    CONST KEY_LOWER_N = 110
    CONST KEY_LOWER_O = 111
    CONST KEY_LOWER_P = 112
    CONST KEY_LOWER_Q = 113
    CONST KEY_LOWER_R = 114
    CONST KEY_LOWER_S = 115
    CONST KEY_LOWER_T = 116
    CONST KEY_LOWER_U = 117
    CONST KEY_LOWER_V = 118
    CONST KEY_LOWER_W = 119
    CONST KEY_LOWER_X = 120
    CONST KEY_LOWER_Y = 121
    CONST KEY_LOWER_Z = 122
    CONST KEY_OPEN_BRACE = 123
    CONST KEY_VERTICAL_LINE = 124
    CONST KEY_CLOSE_BRACE = 125
    CONST KEY_TILDE = 126
    CONST KEY_F1 = 15104
    CONST KEY_F2 = 15360
    CONST KEY_F3 = 15616
    CONST KEY_F4 = 15872
    CONST KEY_F5 = 16128
    CONST KEY_F6 = 16384
    CONST KEY_F7 = 16640
    CONST KEY_F8 = 16896
    CONST KEY_F9 = 17152
    CONST KEY_F10 = 17408
    CONST KEY_HOME = 18176
    CONST KEY_UP_ARROW = 18432
    CONST KEY_PAGE_UP = 18688
    CONST KEY_LEFT_ARROW = 19200
    CONST KEY_RIGHT_ARROW = 19712
    CONST KEY_END = 20224
    CONST KEY_DOWN_ARROW = 20480
    CONST KEY_PAGE_DOWN = 20736
    CONST KEY_INSERT = 20992
    CONST KEY_DELETE = 21248
    CONST KEY_F11 = 34048
    CONST KEY_F12 = 34304
    CONST KEY_RIGHT_CONTROL = 100305
    CONST KEY_LEFT_CONTROL = 100306
    CONST KEY_RIGHT_ALT = 100306
    CONST KEY_LEFT_ALT = 100308
    ' QB64 errors that we can throw if something bad happens
    CONST ERROR_SYNTAX_ERROR = 2
    CONST ERROR_ILLEGAL_FUNCTION_CALL = 5
    CONST ERROR_OVERFLOW = 6
    CONST ERROR_CANNOT_CONTINUE = 17
    CONST ERROR_INTERNAL_ERROR = 51
    CONST ERROR_FILE_NOT_FOUND = 53
    CONST ERROR_FEATURE_UNAVAILABLE = 73
    CONST ERROR_PATH_NOT_FOUND = 76
    CONST ERROR_OUT_OF_MEMORY = 257
    CONST ERROR_INVALID_HANDLE = 258
    CONST ERROR_MEMORY_REGION_OUT_OF_RANGE = 300

    ' Some of the type below do not have a "home" yet and should be moved to appropriate files later

    ' A simple integer 2D vector
    TYPE Vector2LType
        x AS LONG
        y AS LONG
    END TYPE

    ' A simple floating-point 2D vector
    TYPE Vector2FType
        x AS SINGLE
        y AS SINGLE
    END TYPE

    ' A simple integer 2D vector
    TYPE Vector3LType
        x AS LONG
        y AS LONG
        z AS LONG
    END TYPE

    ' A simple floating-point 2D vector
    TYPE Vector3FType
        x AS SINGLE
        y AS SINGLE
        z AS SINGLE
    END TYPE

$END IF

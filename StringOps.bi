'-----------------------------------------------------------------------------------------------------------------------
' String related routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF STRINGOPS_BI = UNDEFINED THEN
    $LET STRINGOPS_BI = TRUE

    '$INCLUDE:'Common.bi'
    '$INCLUDE:'Types.bi'

    DECLARE LIBRARY
        FUNCTION ToLowerCase~& ALIAS "tolower" (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION ToUpperCase~& ALIAS "toupper" (BYVAL ch AS _UNSIGNED LONG)
    END DECLARE

    DECLARE LIBRARY "StringOps"
        FUNCTION __FormatLong$ (BYVAL n AS LONG, fmt AS STRING)
        FUNCTION __FormatInteger64$ (BYVAL n AS _INTEGER64, fmt AS STRING)
        FUNCTION __FormatSingle$ (BYVAL n AS SINGLE, fmt AS STRING)
        FUNCTION __FormatDouble$ (BYVAL n AS DOUBLE, fmt AS STRING)
        FUNCTION __FormatOffset$ (BYVAL n AS _UNSIGNED _OFFSET, fmt AS STRING)
        FUNCTION FormatBoolean$ (BYVAL n AS LONG, BYVAL fmt AS _UNSIGNED LONG)
        FUNCTION IsAlphaNumeric%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION IsAlphabetic%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION IsLowerCase%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION IsUpperCase%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION IsDigit%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION IsHexadecimalDigit%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION IsControlCharacter%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION IsGraphicalCharacter%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION IsWhiteSpace%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION IsBlank%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION IsPrintable%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION IsPunctuation%% (BYVAL ch AS _UNSIGNED LONG)
        SUB ReverseMemory (BYVAL ptr AS _UNSIGNED _OFFSET, BYVAL size AS _UNSIGNED _OFFSET)
        FUNCTION __RegExCompile~%& (pattern AS STRING)
        SUB RegExFree (BYVAL regExCtx AS _UNSIGNED _OFFSET)
        FUNCTION __RegExSearchCompiled& (BYVAL pattern AS _UNSIGNED _OFFSET, text AS STRING, BYVAL startPos AS LONG, matchLength AS LONG)
        FUNCTION __RegExSearch& (pattern AS STRING, text AS STRING, BYVAL startPos AS LONG, matchLength AS LONG)
        FUNCTION __RegExMatchCompiled%% (BYVAL pattern AS _UNSIGNED _OFFSET, text AS STRING)
        FUNCTION __RegExMatch%% (pattern AS STRING, text AS STRING)
    END DECLARE

$END IF

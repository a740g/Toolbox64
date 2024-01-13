'-----------------------------------------------------------------------------------------------------------------------
' String related routines
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF STRINGOPS_BI = UNDEFINED THEN
    $LET STRINGOPS_BI = TRUE

    '$INCLUDE:'Common.bi'
    '$INCLUDE:'Types.bi'
    '$INCLUDE:'PointerOps.bi'

    CONST STRING_EMPTY = ""

    DECLARE LIBRARY "StringOps"
        FUNCTION STRING_BS$
        FUNCTION STRING_HT$
        FUNCTION STRING_LF$
        FUNCTION STRING_VT$
        FUNCTION STRING_FF$
        FUNCTION STRING_CR$
        FUNCTION STRING_ESC$
        FUNCTION STRING_QUOTE$
        FUNCTION STRING_CRLF$
        FUNCTION __String_FormatString$ (s AS STRING, fmt AS STRING)
        FUNCTION __String_FormatLong$ (BYVAL n AS LONG, fmt AS STRING)
        FUNCTION __String_FormatInteger64$ (BYVAL n AS _INTEGER64, fmt AS STRING)
        FUNCTION __String_FormatSingle$ (BYVAL n AS SINGLE, fmt AS STRING)
        FUNCTION __String_FormatDouble$ (BYVAL n AS DOUBLE, fmt AS STRING)
        FUNCTION __String_FormatOffset$ (BYVAL n AS _UNSIGNED _OFFSET, fmt AS STRING)
        FUNCTION String_FormatBoolean$ (BYVAL n AS LONG, BYVAL fmt AS _UNSIGNED LONG)
        FUNCTION String_ToLowerCase~& ALIAS "tolower" (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION String_ToUpperCase~& ALIAS "toupper" (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION String_IsAlphaNumeric%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION String_IsAlphabetic%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION String_IsLowerCase%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION String_IsUpperCase%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION String_IsDigit%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION String_IsHexadecimalDigit%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION String_IsControlCharacter%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION String_IsGraphicalCharacter%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION String_IsWhiteSpace%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION String_IsBlank%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION String_IsPrintable%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION String_IsPunctuation%% (BYVAL ch AS _UNSIGNED LONG)
        FUNCTION __String_RegExCompile~%& (pattern AS STRING)
        SUB String_RegExFree (BYVAL regExCtx AS _UNSIGNED _OFFSET)
        FUNCTION __String_RegExSearchCompiled& (BYVAL pattern AS _UNSIGNED _OFFSET, text AS STRING, BYVAL startPos AS LONG, matchLength AS LONG)
        FUNCTION __String_RegExSearch& (pattern AS STRING, text AS STRING, BYVAL startPos AS LONG, matchLength AS LONG)
        FUNCTION __String_RegExMatchCompiled%% (BYVAL pattern AS _UNSIGNED _OFFSET, text AS STRING)
        FUNCTION __String_RegExMatch%% (pattern AS STRING, text AS STRING)
    END DECLARE

$END IF

'-----------------------------------------------------------------------------------------------------------------------
' QB64-PE pointer helper routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF POINTEROPS_BI = UNDEFINED THEN
    $LET POINTEROPS_BI = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' HEADER FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'Common.bi'
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    '$DEBUG

    'DIM x AS _OFFSET: x = &HDEADBEEF

    'PRINT HEX$(CLngPtr(x))

    'DIM s AS STRING: s = "testing!" + CHR$(0)
    'PRINT CStr$(_OFFSET(s)) + "<"

    'PRINT CHR$(PeekByte(_OFFSET(s), 7))
    'PokeByte _OFFSET(s), 7, 63
    'PRINT s

    'PRINT HEX$(PeekInteger(_OFFSET(x), 0))
    'PokeInteger _OFFSET(x), 0, &HBABE
    'PRINT HEX$(CLngPtr(x))

    'PokeLong _OFFSET(x), 1, &HC001D00D
    'PRINT HEX$(CLngPtr(x))
    'PRINT HEX$(PeekLong(_OFFSET(x), 1))

    'DIM fs AS STRING * 8: fs = _MK$(_UNSIGNED _INTEGER64, &HC001D00DDEADBEEF)
    'PRINT HEX$(PeekStringInteger64(fs, 0))

    'PokeStringLong fs, 1, &HD001F001
    'PRINT HEX$(PeekStringLong(fs, 1))

    'PokeStringInteger fs, 1, &HD0D0

    'PRINT HEX$(PeekStringInteger64(fs, 0))

    'END
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' EXTERNAL LIBRARIES
    '-------------------------------------------------------------------------------------------------------------------
    DECLARE LIBRARY "PointerOps"
        $IF 32BIT THEN
            FUNCTION CLngPtr~& (BYVAL p As _UNSIGNED _OFFSET)
        $ELSE
            FUNCTION CLngPtr~&& (BYVAL p AS _UNSIGNED _OFFSET)
        $END IF
        FUNCTION CStr$ (BYVAL p AS _UNSIGNED _OFFSET)
        FUNCTION PeekByte~%% (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeByte (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _UNSIGNED _BYTE)
        FUNCTION PeekInteger~% (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeInteger (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _UNSIGNED INTEGER)
        FUNCTION PeekLong~& (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeLong (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _UNSIGNED LONG)
        FUNCTION PeekInteger64~&& (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeInteger64 (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _UNSIGNED _INTEGER64)
        FUNCTION PeekSingle! (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeSingle (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS SINGLE)
        FUNCTION PeekDouble# (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeDouble (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS DOUBLE)
        FUNCTION PeekOffset~%& (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeOffset (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _UNSIGNED _OFFSET)
        SUB PeekType (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL typeVar AS _UNSIGNED _OFFSET, BYVAL typeSize AS _UNSIGNED _OFFSET)
        SUB PokeType (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL typeVar AS _UNSIGNED _OFFSET, BYVAL typeSize AS _UNSIGNED _OFFSET)
        FUNCTION PeekStringByte~%% (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeStringByte (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _UNSIGNED _BYTE)
        FUNCTION PeekStringInteger~% (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeStringInteger (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _UNSIGNED INTEGER)
        FUNCTION PeekStringLong~& (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeStringLong (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _UNSIGNED LONG)
        FUNCTION PeekStringInteger64~&& (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeStringInteger64 (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _UNSIGNED _INTEGER64)
        FUNCTION PeekStringSingle! (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeStringSingle (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS SINGLE)
        FUNCTION PeekStringDouble# (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeStringDouble (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS DOUBLE)
        FUNCTION PeekStringOffset~%& (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeStringOffset (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _UNSIGNED _OFFSET)
        SUB PeekStringType (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL typeVar AS _UNSIGNED _OFFSET, BYVAL typeSize AS _UNSIGNED _OFFSET)
        SUB PokeStringType (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL typeVar AS _UNSIGNED _OFFSET, BYVAL typeSize AS _UNSIGNED _OFFSET)
    END DECLARE
    '-------------------------------------------------------------------------------------------------------------------
$END IF
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' QB64-PE pointer helper routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF POINTEROPS_BI = UNDEFINED THEN
    $LET POINTEROPS_BI = TRUE

    '$INCLUDE:'Common.bi'

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

    'PRINT FindMemory(_OFFSET(s), ASC("g"), LEN(s))
    'PRINT CompareMemory(_OFFSET(fs), _OFFSET(s), 2)
    'SetMemory _OFFSET(s), ASC("X"), 3
    'PRINT s
    'CopyMemory _OFFSET(s), _OFFSET(fs), 3
    'PRINT s
    'MoveMemory _OFFSET(s), _OFFSET(s) + 3, 4
    'PRINT s

    'DIM m AS _OFFSET: m = AllocateMemory(8192)
    'PRINT m
    'SetMemory m, ASC("T"), 4
    'SetMemory m + 4, 0, 1
    'PRINT CStr(m)
    'm = ReallocateMemory(m, 4096)
    'PRINT m
    'FreeMemory m

    'END
    '-------------------------------------------------------------------------------------------------------------------

    DECLARE LIBRARY "PointerOps"
        $IF 32BIT THEN
            FUNCTION  GetCStringLength~& (BYVAL str As _UNSIGNED _OFFSET)
            FUNCTION CLngPtr~& ALIAS "uintptr_t" (BYVAL p As _UNSIGNED _OFFSET)
        $ELSE
            FUNCTION GetCStringLength~&& (BYVAL str AS _UNSIGNED _OFFSET)
            FUNCTION CLngPtr~&& ALIAS "uintptr_t" (BYVAL p AS _UNSIGNED _OFFSET)
        $END IF
        FUNCTION CompareMemory& (BYVAL lhs AS _UNSIGNED _OFFSET, BYVAL rhs AS _UNSIGNED _OFFSET, BYVAL count AS _UNSIGNED _OFFSET)
        SUB SetMemory (BYVAL dst AS _UNSIGNED _OFFSET, BYVAL ch AS LONG, BYVAL count AS _UNSIGNED _OFFSET)
        SUB CopyMemory (BYVAL dst AS _UNSIGNED _OFFSET, BYVAL src AS _UNSIGNED _OFFSET, BYVAL count AS _UNSIGNED _OFFSET)
        SUB MoveMemory (BYVAL dst AS _UNSIGNED _OFFSET, BYVAL src AS _UNSIGNED _OFFSET, BYVAL count AS _UNSIGNED _OFFSET)
        FUNCTION FindMemory~%& (BYVAL ptr AS _UNSIGNED _OFFSET, BYVAL ch AS LONG, BYVAL count AS _UNSIGNED _OFFSET)
        FUNCTION AllocateMemory~%& (BYVAL size AS _UNSIGNED _OFFSET)
        FUNCTION AllocateAndClearMemory~%& (BYVAL num AS _UNSIGNED _OFFSET, BYVAL size AS _UNSIGNED _OFFSET)
        FUNCTION ReallocateMemory~%& (BYVAL ptr AS _UNSIGNED _OFFSET, BYVAL new_size AS _UNSIGNED _OFFSET)
        SUB FreeMemory (BYVAL ptr AS _UNSIGNED _OFFSET)
        FUNCTION CStr$ (BYVAL p AS _UNSIGNED _OFFSET)
        FUNCTION PeekByte%% (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeByte (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _BYTE)
        FUNCTION PeekInteger% (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeInteger (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS INTEGER)
        FUNCTION PeekLong& (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeLong (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS LONG)
        FUNCTION PeekInteger64&& (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeInteger64 (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _INTEGER64)
        FUNCTION PeekSingle! (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeSingle (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS SINGLE)
        FUNCTION PeekDouble# (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeDouble (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS DOUBLE)
        FUNCTION PeekOffset~%& (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeOffset (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _UNSIGNED _OFFSET)
        SUB PeekType (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL typeVar AS _UNSIGNED _OFFSET, BYVAL typeSize AS _UNSIGNED _OFFSET)
        SUB PokeType (BYVAL p AS _UNSIGNED _OFFSET, BYVAL o AS _UNSIGNED _OFFSET, BYVAL typeVar AS _UNSIGNED _OFFSET, BYVAL typeSize AS _UNSIGNED _OFFSET)
        FUNCTION PeekStringByte%% (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeStringByte (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _BYTE)
        FUNCTION PeekStringInteger% (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeStringInteger (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS INTEGER)
        FUNCTION PeekStringLong& (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeStringLong (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS LONG)
        FUNCTION PeekStringInteger64&& (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeStringInteger64 (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _INTEGER64)
        FUNCTION PeekStringSingle! (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeStringSingle (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS SINGLE)
        FUNCTION PeekStringDouble# (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeStringDouble (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS DOUBLE)
        FUNCTION PeekStringOffset~%& (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET)
        SUB PokeStringOffset (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL n AS _UNSIGNED _OFFSET)
        SUB PeekStringType (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL typeVar AS _UNSIGNED _OFFSET, BYVAL typeSize AS _UNSIGNED _OFFSET)
        SUB PokeStringType (s AS STRING, BYVAL o AS _UNSIGNED _OFFSET, BYVAL typeVar AS _UNSIGNED _OFFSET, BYVAL typeSize AS _UNSIGNED _OFFSET)
    END DECLARE

$END IF

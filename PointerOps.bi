'-----------------------------------------------------------------------------------------------------------------------
' QB64-PE pointer helper routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF POINTEROPS_BI = UNDEFINED THEN
    $LET POINTEROPS_BI = TRUE

    '$INCLUDE:'Common.bi'

    CONST SIZE_OF_BYTE = 1
    CONST SIZE_OF_INTEGER = 2
    CONST SIZE_OF_LONG = 4
    CONST SIZE_OF_INTEGER64 = 8
    CONST SIZE_OF_SINGLE = 4
    CONST SIZE_OF_DOUBLE = 8
    $IF 32BIT THEN
            CONST SIZE_OF_OFFSET = 4
    $ELSE
        CONST SIZE_OF_OFFSET = 8
    $END IF

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

    'END
    '-------------------------------------------------------------------------------------------------------------------

    DECLARE CUSTOMTYPE LIBRARY
        $IF 32BIT THEN
            FUNCTION  GetCStringLength~& ALIAS strlen (BYVAL str As _UNSIGNED _OFFSET)
        $ELSE
            FUNCTION GetCStringLength~&& ALIAS strlen (BYVAL str AS _UNSIGNED _OFFSET)
        $END IF
        FUNCTION CompareMemory& ALIAS memcmp (BYVAL lhs AS _UNSIGNED _OFFSET, BYVAL rhs AS _UNSIGNED _OFFSET, BYVAL count AS _UNSIGNED _OFFSET)
        SUB SetMemory ALIAS memset (BYVAL dst AS _UNSIGNED _OFFSET, BYVAL ch AS LONG, BYVAL count AS _UNSIGNED _OFFSET)
        SUB CopyMemory ALIAS memcpy (BYVAL dst AS _UNSIGNED _OFFSET, BYVAL src AS _UNSIGNED _OFFSET, BYVAL count AS _UNSIGNED _OFFSET)
        SUB MoveMemory ALIAS memmove (BYVAL dst AS _UNSIGNED _OFFSET, BYVAL src AS _UNSIGNED _OFFSET, BYVAL count AS _UNSIGNED _OFFSET)
        FUNCTION AllocateMemory~%& ALIAS malloc (BYVAL size AS _UNSIGNED _OFFSET)
        FUNCTION AllocateAndClearMemory~%& ALIAS calloc (BYVAL num AS _UNSIGNED _OFFSET, BYVAL size AS _UNSIGNED _OFFSET)
        FUNCTION ReallocateMemory~%& ALIAS realloc (BYVAL ptr AS _UNSIGNED _OFFSET, BYVAL new_size AS _UNSIGNED _OFFSET)
        SUB FreeMemory ALIAS free (BYVAL ptr AS _UNSIGNED _OFFSET)
    END DECLARE

    DECLARE LIBRARY
        FUNCTION FindMemory~%& (BYVAL ptr AS _UNSIGNED _OFFSET, BYVAL ch AS LONG, BYVAL count AS _UNSIGNED _OFFSET)
    END DECLARE

    DECLARE LIBRARY "PointerOps"
        $IF 32BIT THEN
            FUNCTION CLngPtr~& (BYVAL p As _UNSIGNED _OFFSET)
        $ELSE
            FUNCTION CLngPtr~&& (BYVAL p AS _UNSIGNED _OFFSET)
        $END IF
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
        SUB ReverseMemory (BYVAL ptr AS _UNSIGNED _OFFSET, BYVAL size AS _UNSIGNED _OFFSET)
    END DECLARE

$END IF

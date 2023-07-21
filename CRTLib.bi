'-----------------------------------------------------------------------------------------------------------------------
' C Runtime Library bindings + low level support functions
' Copyright (c) 2023 Samuel Gomes
'
' See https://en.cppreference.com/w/ for CRT documentation
'-----------------------------------------------------------------------------------------------------------------------

$IF CRTLIB_BI = UNDEFINED THEN
    $LET CRTLIB_BI = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' HEADER FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'Common.bi'
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' EXTERNAL LIBRARIES
    '-------------------------------------------------------------------------------------------------------------------
    ' This only includes CRT library functions that makes sense in QB64
    DECLARE LIBRARY
        FUNCTION isalnum& (BYVAL ch AS LONG)
        FUNCTION isalpha& (BYVAL ch AS LONG)
        FUNCTION islower& (BYVAL ch AS LONG)
        FUNCTION isupper& (BYVAL ch AS LONG)
        FUNCTION isdigit& (BYVAL ch AS LONG)
        FUNCTION isxdigit& (BYVAL ch AS LONG)
        FUNCTION iscntrl& (BYVAL ch AS LONG)
        FUNCTION isgraph& (BYVAL ch AS LONG)
        FUNCTION isspace& (BYVAL ch AS LONG)
        FUNCTION isblank& (BYVAL ch AS LONG)
        FUNCTION isprint& (BYVAL ch AS LONG)
        FUNCTION ispunct& (BYVAL ch AS LONG)
        FUNCTION tolower& (BYVAL ch AS LONG)
        FUNCTION toupper& (BYVAL ch AS LONG)
        FUNCTION rand&
        SUB srand (BYVAL seed AS _UNSIGNED LONG)
        FUNCTION getchar&
        SUB putchar (BYVAL ch AS LONG)
        FUNCTION GetTicks~&&
        FUNCTION fmaf! (BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL z AS SINGLE)
        FUNCTION fma# (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE, BYVAL z AS DOUBLE)
        FUNCTION MaxSingle! ALIAS fmaxf (BYVAL a AS SINGLE, BYVAL b AS SINGLE)
        FUNCTION MinSingle! ALIAS fminf (BYVAL a AS SINGLE, BYVAL b AS SINGLE)
        FUNCTION MaxDouble# ALIAS fmax (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE)
        FUNCTION MinDouble# ALIAS fmin (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE)
    END DECLARE

    DECLARE LIBRARY "CRTLib"
        FUNCTION ToQBBool%% (BYVAL x AS LONG)
        FUNCTION ToCBool%% (BYVAL x AS LONG)
        FUNCTION GetRandomValue& (BYVAL lo AS LONG, BYVAL hi AS LONG)
        FUNCTION IsPowerOfTwo& (BYVAL n AS _UNSIGNED LONG)
        FUNCTION RoundUpToPowerOf2~& (BYVAL n AS _UNSIGNED LONG)
        FUNCTION RoundDownToPowerOf2~& (BYVAL n AS _UNSIGNED LONG)
        FUNCTION LeftShiftOneCount~& (BYVAL n AS _UNSIGNED LONG)
        FUNCTION ReverseBitsByte~%% (BYVAL n AS _UNSIGNED _BYTE)
        FUNCTION ReverseBitsInteger~% (BYVAL n AS _UNSIGNED INTEGER)
        FUNCTION ReverseBitsLong~& (BYVAL n AS _UNSIGNED LONG)
        FUNCTION ReverseBitsInteger64~&& (BYVAL n AS _UNSIGNED _INTEGER64)
        FUNCTION ClampLong& (BYVAL n AS LONG, BYVAL lo AS LONG, BYVAL hi AS LONG)
        FUNCTION ClampInteger64&& (BYVAL n AS _INTEGER64, BYVAL lo AS _INTEGER64, BYVAL hi AS _INTEGER64)
        FUNCTION ClampSingle! (BYVAL n AS SINGLE, BYVAL lo AS SINGLE, BYVAL hi AS SINGLE)
        FUNCTION ClampDouble# (BYVAL n AS DOUBLE, BYVAL lo AS DOUBLE, BYVAL hi AS DOUBLE)
        FUNCTION GetDigitFromLong& (BYVAL n AS _UNSIGNED LONG, BYVAL p AS _UNSIGNED LONG)
        FUNCTION GetDigitFromInteger64& (BYVAL n AS _UNSIGNED _INTEGER64, BYVAL p AS _UNSIGNED LONG)
        FUNCTION AverageLong& (BYVAL x AS LONG, BYVAL y AS LONG)
        FUNCTION AverageInteger64&& (BYVAL x AS _INTEGER64, BYVAL y AS _INTEGER64)
        FUNCTION FindFirstBitSetLong& (BYVAL x AS _UNSIGNED LONG)
        FUNCTION FindFirstBitSetInteger64& (BYVAL x AS _UNSIGNED _INTEGER64)
        FUNCTION CountLeadingZerosLong& (BYVAL x AS _UNSIGNED LONG)
        FUNCTION CountLeadingZerosInteger64& (BYVAL x AS _UNSIGNED _INTEGER64)
        FUNCTION CountTrailingZerosLong& (BYVAL x AS _UNSIGNED LONG)
        FUNCTION CountTrailingZerosInteger64& (BYVAL x AS _UNSIGNED _INTEGER64)
        FUNCTION PopulationCountLong& (BYVAL x AS _UNSIGNED LONG)
        FUNCTION PopulationCountInteger64& (BYVAL x AS _UNSIGNED _INTEGER64)
        FUNCTION ByteSwapInteger~% (BYVAL x AS _UNSIGNED INTEGER)
        FUNCTION ByteSwapLong~& (BYVAL x AS _UNSIGNED LONG)
        FUNCTION ByteSwapInteger64~&& (BYVAL x AS _UNSIGNED _INTEGER64)
        FUNCTION MakeFourCC~& (BYVAL ch0 AS _UNSIGNED _BYTE, BYVAL ch1 AS _UNSIGNED _BYTE, BYVAL ch2 AS _UNSIGNED _BYTE, BYVAL ch3 AS _UNSIGNED _BYTE)
        FUNCTION MakeByte~%% (BYVAL x AS _UNSIGNED _BYTE, BYVAL y AS _UNSIGNED _BYTE)
        FUNCTION MakeInteger~% (BYVAL x AS _UNSIGNED _BYTE, BYVAL y AS _UNSIGNED _BYTE)
        FUNCTION MakeLong~& (BYVAL x AS _UNSIGNED INTEGER, BYVAL y AS _UNSIGNED INTEGER)
        FUNCTION MakeInteger64~&& (BYVAL x AS _UNSIGNED LONG, BYVAL y AS _UNSIGNED LONG)
        FUNCTION HiNibble~%% (BYVAL x AS _UNSIGNED _BYTE)
        FUNCTION LoNibble~%% (BYVAL x AS _UNSIGNED _BYTE)
        FUNCTION HiByte~%% (BYVAL x AS _UNSIGNED INTEGER)
        FUNCTION LoByte~%% (BYVAL x AS _UNSIGNED INTEGER)
        FUNCTION HiInteger~% (BYVAL x AS _UNSIGNED LONG)
        FUNCTION LoInteger~% (BYVAL x AS _UNSIGNED LONG)
        FUNCTION HiLong~& (BYVAL x AS _UNSIGNED _INTEGER64)
        FUNCTION LoLong~& (BYVAL x AS _UNSIGNED _INTEGER64)
        FUNCTION MaxLong& (BYVAL a AS LONG, BYVAL b AS LONG)
        FUNCTION MinLong& (BYVAL a AS LONG, BYVAL b AS LONG)
        FUNCTION MaxInteger64&& (BYVAL a AS _INTEGER64, BYVAL b AS _INTEGER64)
        FUNCTION MinInteger64&& (BYVAL a AS _INTEGER64, BYVAL b AS _INTEGER64)
    END DECLARE
    '-------------------------------------------------------------------------------------------------------------------
$END IF
'-----------------------------------------------------------------------------------------------------------------------

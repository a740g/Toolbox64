'-----------------------------------------------------------------------------------------------------------------------
' Bitwise operation routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF TEMPLATE_BI = UNDEFINED THEN
    $LET TEMPLATE_BI = TRUE

    '$INCLUDE:'Common.bi'

    DECLARE LIBRARY "BitwiseOps"
        FUNCTION LeftShiftOneCount~& (BYVAL n AS _UNSIGNED LONG)
        FUNCTION ReverseBitsByte~%% (BYVAL n AS _UNSIGNED _BYTE)
        FUNCTION ReverseBitsInteger~% (BYVAL n AS _UNSIGNED INTEGER)
        FUNCTION ReverseBitsLong~& (BYVAL n AS _UNSIGNED LONG)
        FUNCTION ReverseBitsInteger64~&& (BYVAL n AS _UNSIGNED _INTEGER64)
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
    END DECLARE

$END IF

'-----------------------------------------------------------------------------------------------------------------------
' Math routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF MATHOPS_BI = UNDEFINED THEN
    $LET MATHOPS_BI = TRUE

    '$INCLUDE:'Common.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    'PRINT GetRandomValue
    'PRINT GetRandomMaximum
    'PRINT MaxDouble(24.4, 645.355)
    'PRINT MaxLong(-20, 0)
    'PRINT MinLong(0, 20)
    'PRINT MinInteger64(-244334, 0)
    'END
    '-------------------------------------------------------------------------------------------------------------------

    DECLARE LIBRARY "MathOps"
        SUB SetRandomSeed (BYVAL seed AS _UNSIGNED LONG)
        FUNCTION GetRandomValue& ALIAS "rand"
        FUNCTION GetRandomBetween& (BYVAL lo AS LONG, BYVAL hi AS LONG)
        FUNCTION GetRandomMaximum~&
        FUNCTION IsLongEven%% (BYVAL n AS LONG)
        FUNCTION IsInteger64Even%% (BYVAL n AS _INTEGER64)
        FUNCTION IsLongPowerOf2%% (BYVAL n AS _UNSIGNED LONG)
        FUNCTION IsInteger64PowerOf2%% (BYVAL n AS _UNSIGNED _INTEGER64)
        FUNCTION RoundLongUpToPowerOf2~& (BYVAL n AS _UNSIGNED LONG)
        FUNCTION RoundInteger64UpToPowerOf2~&& (BYVAL n AS _UNSIGNED _INTEGER64)
        FUNCTION RoundLongDownToPowerOf2~& (BYVAL n AS _UNSIGNED LONG)
        FUNCTION RoundInteger64DownToPowerOf2~&& (BYVAL n AS _UNSIGNED _INTEGER64)
        FUNCTION GetDigitFromLong& (BYVAL n AS _UNSIGNED LONG, BYVAL p AS _UNSIGNED LONG)
        FUNCTION GetDigitFromInteger64& (BYVAL n AS _UNSIGNED _INTEGER64, BYVAL p AS _UNSIGNED LONG)
        FUNCTION AverageLong& (BYVAL x AS LONG, BYVAL y AS LONG)
        FUNCTION AverageInteger64&& (BYVAL x AS _INTEGER64, BYVAL y AS _INTEGER64)
        FUNCTION ClampLong& (BYVAL n AS LONG, BYVAL lo AS LONG, BYVAL hi AS LONG)
        FUNCTION ClampInteger64&& (BYVAL n AS _INTEGER64, BYVAL lo AS _INTEGER64, BYVAL hi AS _INTEGER64)
        FUNCTION ClampSingle! (BYVAL n AS SINGLE, BYVAL lo AS SINGLE, BYVAL hi AS SINGLE)
        FUNCTION ClampDouble# (BYVAL n AS DOUBLE, BYVAL lo AS DOUBLE, BYVAL hi AS DOUBLE)
        FUNCTION RemapLong& (BYVAL value AS LONG, BYVAL oldMin AS LONG, BYVAL oldMax AS LONG, BYVAL newMin AS LONG, BYVAL newMax AS LONG)
        FUNCTION RemapInteger64&& (BYVAL value AS _INTEGER64, BYVAL oldMin AS _INTEGER64, BYVAL oldMax AS _INTEGER64, BYVAL newMin AS _INTEGER64, BYVAL newMax AS _INTEGER64)
        FUNCTION RemapSingle! (BYVAL value AS SINGLE, BYVAL oldMin AS SINGLE, BYVAL oldMax AS SINGLE, BYVAL newMin AS SINGLE, BYVAL newMax AS SINGLE)
        FUNCTION RemapDouble# (BYVAL value AS DOUBLE, BYVAL oldMin AS DOUBLE, BYVAL oldMax AS DOUBLE, BYVAL newMin AS DOUBLE, BYVAL newMax AS DOUBLE)
        FUNCTION MaxSingle! ALIAS "fmaxf" (BYVAL a AS SINGLE, BYVAL b AS SINGLE)
        FUNCTION MinSingle! ALIAS "fminf" (BYVAL a AS SINGLE, BYVAL b AS SINGLE)
        FUNCTION MaxDouble# ALIAS "fmax" (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE)
        FUNCTION MinDouble# ALIAS "fmin" (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE)
        FUNCTION MaxLong& (BYVAL a AS LONG, BYVAL b AS LONG)
        FUNCTION MinLong& (BYVAL a AS LONG, BYVAL b AS LONG)
        FUNCTION MaxInteger64&& (BYVAL a AS _INTEGER64, BYVAL b AS _INTEGER64)
        FUNCTION MinInteger64&& (BYVAL a AS _INTEGER64, BYVAL b AS _INTEGER64)
        FUNCTION LerpSingle! (BYVAL startValue AS SINGLE, BYVAL endValue AS SINGLE, BYVAL amount AS SINGLE)
        FUNCTION LerpDouble# (BYVAL startValue AS DOUBLE, BYVAL endValue AS DOUBLE, BYVAL amount AS DOUBLE)
        FUNCTION NormalizeSingle! (BYVAL value AS SINGLE, BYVAL startValue AS SINGLE, BYVAL endValue AS SINGLE)
        FUNCTION NormalizeDouble# (BYVAL value AS DOUBLE, BYVAL startValue AS DOUBLE, BYVAL endValue AS DOUBLE)
        FUNCTION WrapSingle! (BYVAL value AS SINGLE, BYVAL startValue AS SINGLE, BYVAL endValue AS SINGLE)
        FUNCTION WrapDouble# (BYVAL value AS DOUBLE, BYVAL startValue AS DOUBLE, BYVAL endValue AS DOUBLE)
        FUNCTION SingleEquals%% (BYVAL x AS SINGLE, BYVAL y AS SINGLE)
        FUNCTION DoubleEquals%% (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE)
        FUNCTION FMASingle! ALIAS "fmaf" (BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL z AS SINGLE)
        FUNCTION FMADouble# ALIAS "fma" (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE, BYVAL z AS DOUBLE)
    END DECLARE

$END IF

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
    'PRINT FIX(2.5!), FIX(1.5!), FIX(2.1!), FIX(1.1!)
    'PRINT SingleToLong(2.5!), SingleToLong(1.5!), SingleToLong(2.1!), SingleToLong(1.1!)
    'DIM n AS SINGLE, i AS LONG
    'n = 1.5!
    'i = SingleToLong(n)
    'PRINT n, i

    'END
    '-------------------------------------------------------------------------------------------------------------------

    DECLARE LIBRARY "MathOps"
        FUNCTION Math_LongToSingle! ALIAS "float" (BYVAL x AS LONG)
        FUNCTION Math_Integer64ToSingle! ALIAS "float" (BYVAL x AS _INTEGER64)
        FUNCTION Math_LongToDouble# ALIAS "double" (BYVAL x AS LONG)
        FUNCTION Math_Integer64ToDouble# ALIAS "double" (BYVAL x AS _INTEGER64)
        FUNCTION Math_SingleToLong& ALIAS "int32_t" (BYVAL x AS SINGLE)
        FUNCTION Math_DoubleToLong& ALIAS "int32_t" (BYVAL x AS DOUBLE)
        FUNCTION Math_SingleToInteger64&& ALIAS "int64_t" (BYVAL x AS SINGLE)
        FUNCTION Math_DoubleToInteger64&& ALIAS "int64_t" (BYVAL x AS DOUBLE)
        SUB Math_SetRandomSeed (BYVAL seed AS _UNSIGNED LONG)
        FUNCTION Math_GetRandomMax~&
        FUNCTION Math_GetRandomValue& ALIAS "rand"
        FUNCTION Math_GetRandomBetween& (BYVAL lo AS LONG, BYVAL hi AS LONG)
        FUNCTION Math_IsSingleNaN! (BYVAL n AS SINGLE)
        FUNCTION Math_IsDoubleNaN# (BYVAL n AS DOUBLE)
        FUNCTION Math_IsLongEven%% (BYVAL n AS LONG)
        FUNCTION Math_IsInteger64Even%% (BYVAL n AS _INTEGER64)
        FUNCTION Math_IsLongPowerOf2%% (BYVAL n AS _UNSIGNED LONG)
        FUNCTION Math_IsInteger64PowerOf2%% (BYVAL n AS _UNSIGNED _INTEGER64)
        FUNCTION Math_RoundUpLongToPowerOf2~& (BYVAL n AS _UNSIGNED LONG)
        FUNCTION Math_RoundUpInteger64ToPowerOf2~&& (BYVAL n AS _UNSIGNED _INTEGER64)
        FUNCTION Math_RoundDownLongToPowerOf2~& (BYVAL n AS _UNSIGNED LONG)
        FUNCTION Math_RoundDownInteger64ToPowerOf2~&& (BYVAL n AS _UNSIGNED _INTEGER64)
        FUNCTION Math_GetDigitFromLong& (BYVAL n AS _UNSIGNED LONG, BYVAL p AS _UNSIGNED LONG)
        FUNCTION Math_GetDigitFromInteger64& (BYVAL n AS _UNSIGNED _INTEGER64, BYVAL p AS _UNSIGNED LONG)
        FUNCTION Math_AverageLong& (BYVAL x AS LONG, BYVAL y AS LONG)
        FUNCTION Math_AverageInteger64&& (BYVAL x AS _INTEGER64, BYVAL y AS _INTEGER64)
        FUNCTION Math_ClampLong& (BYVAL n AS LONG, BYVAL lo AS LONG, BYVAL hi AS LONG)
        FUNCTION Math_ClampInteger64&& (BYVAL n AS _INTEGER64, BYVAL lo AS _INTEGER64, BYVAL hi AS _INTEGER64)
        FUNCTION Math_ClampSingle! (BYVAL n AS SINGLE, BYVAL lo AS SINGLE, BYVAL hi AS SINGLE)
        FUNCTION Math_ClampDouble# (BYVAL n AS DOUBLE, BYVAL lo AS DOUBLE, BYVAL hi AS DOUBLE)
        FUNCTION Math_RemapLong& (BYVAL value AS LONG, BYVAL oldMin AS LONG, BYVAL oldMax AS LONG, BYVAL newMin AS LONG, BYVAL newMax AS LONG)
        FUNCTION Math_RemapInteger64&& (BYVAL value AS _INTEGER64, BYVAL oldMin AS _INTEGER64, BYVAL oldMax AS _INTEGER64, BYVAL newMin AS _INTEGER64, BYVAL newMax AS _INTEGER64)
        FUNCTION Math_RemapSingle! (BYVAL value AS SINGLE, BYVAL oldMin AS SINGLE, BYVAL oldMax AS SINGLE, BYVAL newMin AS SINGLE, BYVAL newMax AS SINGLE)
        FUNCTION Math_RemapDouble# (BYVAL value AS DOUBLE, BYVAL oldMin AS DOUBLE, BYVAL oldMax AS DOUBLE, BYVAL newMin AS DOUBLE, BYVAL newMax AS DOUBLE)
        FUNCTION Math_GetSingleMax! ALIAS "fmaxf" (BYVAL a AS SINGLE, BYVAL b AS SINGLE)
        FUNCTION Math_GetSingleMin! ALIAS "fminf" (BYVAL a AS SINGLE, BYVAL b AS SINGLE)
        FUNCTION Math_GetDoubleMax# ALIAS "fmax" (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE)
        FUNCTION Math_GetDoubleMin# ALIAS "fmin" (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE)
        FUNCTION Math_GetLongMax& (BYVAL a AS LONG, BYVAL b AS LONG)
        FUNCTION Math_GetLongMin& (BYVAL a AS LONG, BYVAL b AS LONG)
        FUNCTION Math_GetInteger64Max&& (BYVAL a AS _INTEGER64, BYVAL b AS _INTEGER64)
        FUNCTION Math_GetInteger64Min&& (BYVAL a AS _INTEGER64, BYVAL b AS _INTEGER64)
        FUNCTION Math_LerpSingle! (BYVAL startValue AS SINGLE, BYVAL endValue AS SINGLE, BYVAL amount AS SINGLE)
        FUNCTION Math_LerpDouble# (BYVAL startValue AS DOUBLE, BYVAL endValue AS DOUBLE, BYVAL amount AS DOUBLE)
        FUNCTION Math_NormalizeSingle! (BYVAL value AS SINGLE, BYVAL startValue AS SINGLE, BYVAL endValue AS SINGLE)
        FUNCTION Math_NormalizeDouble# (BYVAL value AS DOUBLE, BYVAL startValue AS DOUBLE, BYVAL endValue AS DOUBLE)
        FUNCTION Math_WrapSingle! (BYVAL value AS SINGLE, BYVAL startValue AS SINGLE, BYVAL endValue AS SINGLE)
        FUNCTION Math_WrapDouble# (BYVAL value AS DOUBLE, BYVAL startValue AS DOUBLE, BYVAL endValue AS DOUBLE)
        FUNCTION Math_IsSingleEqual%% (BYVAL x AS SINGLE, BYVAL y AS SINGLE)
        FUNCTION Math_IsDoubleEqual%% (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE)
        FUNCTION Math_FMASingle! ALIAS "fmaf" (BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL z AS SINGLE)
        FUNCTION Math_FMADouble# ALIAS "fma" (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE, BYVAL z AS DOUBLE)
        FUNCTION Math_FastIntegerPower&& (BYVAL b AS _INTEGER64, BYVAL e AS _UNSIGNED _BYTE)
        FUNCTION Math_SinglePower! ALIAS "powf" (BYVAL b AS SINGLE, BYVAL e AS SINGLE)
        FUNCTION Math_DoublePower# ALIAS "pow" (BYVAL b AS DOUBLE, BYVAL e AS DOUBLE)
        function Math_FastSquareRoot!(BYVAL n AS SINGLE)
        function Math_FastInverseSquareRoot!(BYVAL n AS SINGLE)
        FUNCTION Math_Log10Single! ALIAS "log10f" (BYVAL n AS SINGLE)
        FUNCTION Math_Log10Double# ALIAS "log10" (BYVAL n AS DOUBLE)
        FUNCTION Math_Log2Single! ALIAS "log2f" (BYVAL n AS SINGLE)
        FUNCTION Math_Log2Double# ALIAS "log2" (BYVAL n AS DOUBLE)
        FUNCTION Math_CubeRootSingle! ALIAS "cbrtf" (BYVAL n AS SINGLE)
        FUNCTION Math_CubeRootDouble# ALIAS "cbrt" (BYVAL n AS DOUBLE)
    END DECLARE

$END IF

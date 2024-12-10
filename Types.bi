'-----------------------------------------------------------------------------------------------------------------------
' Variable type support, size and limits
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'

CONST NULL~%% = 0~%%

CONST SINGLE_EPSILON! = 1.19209289550781250000000000000000000E-7
CONST DOUBLE_EPSILON# = 2.22044604925031308084726333618164062E-16

CONST CHARACTER_BITS~%% = 8~%%

' Note: QB64 does not really care about the _OFFSET being used below.
' For example, the output C code is "((int32)int32_t(20))" for "CLong(20~%%)"
DECLARE LIBRARY "Types"
    FUNCTION CBool%% ALIAS "TO_QB_BOOL" (BYVAL x AS _OFFSET)
    FUNCTION CString$ (BYVAL p AS _UNSIGNED _OFFSET)
END DECLARE

'-------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-------------------------------------------------------------------------------------------------------------------
'$DEBUG
'$CONSOLE:ONLY

'PRINT Compiler_GetDate
'PRINT Compiler_GetTime
'PRINT Compiler_GetFunctionName

'PRINT CBool(0)
'PRINT CBool(1)
'PRINT CBool(-1)
'PRINT CBool(100)
'PRINT CBool(-100)

'DIM s AS STRING: s = "testing!" + CHR$(0)
'PRINT CString(_OFFSET(s))

'END
'-------------------------------------------------------------------------------------------------------------------

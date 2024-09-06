'-----------------------------------------------------------------------------------------------------------------------
' Variable type support, size and limits
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'

CONST FALSE%% = 0%%, TRUE%% = NOT FALSE
CONST NULL~%% = 0~%%

CONST SIZE_OF_BYTE~%% = 1~%%
CONST SIZE_OF_INTEGER~%% = 2~%%
CONST SIZE_OF_LONG~%% = 4~%%
CONST SIZE_OF_INTEGER64~%% = 8~%%
CONST SIZE_OF_SINGLE~%% = 4~%%
CONST SIZE_OF_DOUBLE~%% = 8~%%
CONST SIZE_OF_FLOAT~%% = 32~%%
$IF 32BIT THEN
    CONST SIZE_OF_OFFSET~%% = 4~%%
$ELSE
    CONST SIZE_OF_OFFSET~%% = 8~%%
$END IF

CONST SINGLE_EPSILON! = 1.19209289550781250000000000000000000E-7
CONST DOUBLE_EPSILON# = 2.22044604925031308084726333618164062E-16

CONST CHARACTER_BITS~%% = 8~%%
CONST BIT_MIN` = -1`, BIT_MAX` = 0`
CONST UBIT_MIN~` = 0~`, UBIT_MAX~` = 1~`
CONST BYTE_MIN%% = -128%%, BYTE_MAX%% = 127%%
CONST UBYTE_MIN~%% = 0~%%, UBYTE_MAX~%% = 255~%%
CONST INTEGER_MIN% = -32768%, INTEGER_MAX% = 32767%
CONST UINTEGER_MIN~% = 0~%, UINTEGER_MAX~% = 65535~%
CONST LONG_MIN& = -2147483648&, LONG_MAX& = 2147483647&
CONST ULONG_MIN~& = 0~&, ULONG_MAX~& = 4294967295~&
CONST INTEGER64_MIN&& = -9223372036854775808&&, INTEGER64_MAX&& = 9223372036854775807&&
CONST UINTEGER64_MIN~&& = 0~&&, UINTEGER64_MAX~&& = 18446744073709551615~&&
CONST SINGLE_MIN! = 1.17549435082228750796873653722224568E-38, SINGLE_MAX! = 3.40282346638528859811704183484516925E+38
CONST DOUBLE_MIN# = 2.22507385850720138309023271733240406E-308, DOUBLE_MAX# = 1.79769313486231570814527423731704357E+308
CONST FLOAT_MIN## = -1.18E-4932, FLOAT_MAX## = 1.18E+4932
$IF 32BIT THEN
    CONST OFFSET_MIN& = -2147483648&, OFFSET_MAX& = 2147483647&
    CONST UOFFSET_MIN~& = 0~&, UOFFSET_MAX~& = 4294967295~&
$ELSE
    CONST OFFSET_MIN&& = -9223372036854775808&&, OFFSET_MAX&& = 9223372036854775807&&
    CONST UOFFSET_MIN~&& = 0~&&, UOFFSET_MAX~&& = 18446744073709551615~&&
$END IF

' Note: QB64 does not really care about the _OFFSET being used below.
' For example, the output C code is "((int32)int32_t(20))" for "CLong(20~%%)"
DECLARE LIBRARY "Types"
    $IF 32BIT THEN
        FUNCTION COffset~& ALIAS "uintptr_t" (BYVAL p As _UNSIGNED _OFFSET)
    $ELSE
        FUNCTION COffset~&& ALIAS "uintptr_t" (BYVAL p AS _UNSIGNED _OFFSET)
    $END IF
    FUNCTION CBool%% ALIAS "TO_QB_BOOL" (BYVAL x AS _OFFSET)
    FUNCTION CByte%% ALIAS "int8_t" (BYVAL x AS _UNSIGNED _OFFSET)
    FUNCTION CUByte~%% ALIAS "uint8_t" (BYVAL x AS _OFFSET)
    FUNCTION CInteger% ALIAS "int16_t" (BYVAL x AS _UNSIGNED _OFFSET)
    FUNCTION CUInteger~% ALIAS "uint16_t" (BYVAL x AS _OFFSET)
    FUNCTION CLong& ALIAS "int32_t" (BYVAL x AS _UNSIGNED _OFFSET)
    FUNCTION CULong~& ALIAS "uint32_t" (BYVAL x AS _OFFSET)
    FUNCTION CInteger64&& ALIAS "int64_t" (BYVAL x AS _UNSIGNED _INTEGER64)
    FUNCTION CUInteger64~&& ALIAS "uint64_t" (BYVAL x AS _INTEGER64)
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

'PRINT CLong(20~%%)
'PRINT CULong(20%%)

'DIM s AS STRING: s = "testing!" + CHR$(0)
'PRINT CString(_OFFSET(s))

'DIM ptr AS _OFFSET: ptr = _OFFSET(ptr)
'PRINT COffset(ptr)
'ptr = &HDEADBEEF
'PRINT HEX$(COffset(ptr))

'DIM b1 AS _BYTE: b1 = 255
'PRINT CUByte(b1)

'DIM b2 AS LONG: b2 = -127
'PRINT CUByte(b2)

'END
'-------------------------------------------------------------------------------------------------------------------

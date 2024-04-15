'-----------------------------------------------------------------------------------------------------------------------
' Base64 Encoder and Decoder library
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'
'$INCLUDE:'Types.bi'
'$INCLUDE:'PointerOps.bi'

DECLARE LIBRARY "Base64"
    FUNCTION __MODP_B64_Decode~%& (src AS STRING, BYVAL srcSize AS _UNSIGNED _OFFSET, dstSize AS _UNSIGNED _OFFSET)
    FUNCTION __MODP_B64_Encode~%& (src AS STRING, BYVAL srcSize AS _UNSIGNED _OFFSET, dstSize AS _UNSIGNED _OFFSET)
END DECLARE

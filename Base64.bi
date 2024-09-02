'-----------------------------------------------------------------------------------------------------------------------
' Base64 Encoder and Decoder library
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'
'$INCLUDE:'Types.bi'
'$INCLUDE:'PointerOps.bi'

DECLARE LIBRARY "Base64"
    FUNCTION __MODP_B64_Encode_Length~%& ALIAS "modp_b64_encode_len" (BYVAL srcSize AS _UNSIGNED _OFFSET)
    FUNCTION __MODP_B64_Decode_Length~%& ALIAS "modp_b64_decode_len" (BYVAL srcSize AS _UNSIGNED _OFFSET)
    FUNCTION __MODP_B64_Encode~%& ALIAS "modp_b64_encode" (dst AS STRING, src AS STRING, BYVAL srcSize AS _UNSIGNED _OFFSET)
    FUNCTION __MODP_B64_Decode~%& ALIAS "modp_b64_decode" (dst AS STRING, src AS STRING, BYVAL srcSize AS _UNSIGNED _OFFSET)
    FUNCTION __MODP_B64_Error~%& ALIAS "modp_b64_error"
END DECLARE

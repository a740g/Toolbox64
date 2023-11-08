'-----------------------------------------------------------------------------------------------------------------------
' Base64 Encoder and Decoder library
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF BASE64_BI = UNDEFINED THEN
    $LET BASE64_BI = TRUE

    '$INCLUDE:'Common.bi'
    '$INCLUDE:'Types.bi'
    '$INCLUDE:'PointerOps.bi'

    DECLARE LIBRARY "Base64"
        FUNCTION __MODP_B64_Decode~%& (src AS STRING, BYVAL src_size AS _UNSIGNED _OFFSET, dst_size AS _UNSIGNED _OFFSET)
        FUNCTION __MODP_B64_Encode~%& (src AS STRING, BYVAL src_size AS _UNSIGNED _OFFSET, dst_size AS _UNSIGNED _OFFSET)
    END DECLARE

$END IF

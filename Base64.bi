'-----------------------------------------------------------------------------------------------------------------------
' Base64 Encoder and Decoder library
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF BASE64_BI = UNDEFINED THEN
    $LET BASE64_BI = TRUE

    '$INCLUDE:'Common.bi'
    '$INCLUDE:'Types.bi'

    CONST __BASE64_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

$END IF

'-----------------------------------------------------------------------------------------------------------------------
' Base64 Encoder and Decoder library
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'Common.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If BASE64_BI = UNDEFINED Then
    $Let BASE64_BI = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' CONSTANTS
    '-------------------------------------------------------------------------------------------------------------------
    Const __BASE64_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------


'-----------------------------------------------------------------------------------------------------------------------
' _INFLATE$ compatible high-efficiency compression library for QB64-PE
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF DEFLATE_BI = UNDEFINED THEN
    $LET DEFLATE_BI = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' HEADER FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'CRTLib.bi'
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' EXTERNAL LIBRARIES
    '-------------------------------------------------------------------------------------------------------------------
    DECLARE LIBRARY "Deflate"
        SUB __Zopfli_Compress (BYVAL iterations AS _UNSIGNED _BYTE, inputBuffer AS STRING, BYVAL inputSize AS _UNSIGNED _OFFSET, outputBuffer AS _UNSIGNED _OFFSET, outputSize AS _UNSIGNED _OFFSET)
    END DECLARE
    '-------------------------------------------------------------------------------------------------------------------
$END IF
'-----------------------------------------------------------------------------------------------------------------------

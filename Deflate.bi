'-----------------------------------------------------------------------------------------------------------------------
' _INFLATE$ compatible high-efficiency compression library for QB64-PE
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'
'$INCLUDE:'Types.bi'
'$INCLUDE:'PointerOps.bi'

DECLARE LIBRARY "Deflate"
    SUB __Zopfli_Compress (BYVAL iterations AS _UNSIGNED INTEGER, inputBuffer AS STRING, BYVAL inputSize AS _UNSIGNED _OFFSET, outputBuffer AS _UNSIGNED _OFFSET, outputSize AS _UNSIGNED _OFFSET)
END DECLARE

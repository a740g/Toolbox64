'-----------------------------------------------------------------------------------------------------------------------
' Memory-only file-like object
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Common.bi'
'$INCLUDE:'../Types.bi'
'$INCLUDE:'../PointerOps.bi'

' Simplified memory-only file-like object
TYPE StringFile
    buffer AS STRING
    cursor AS _UNSIGNED LONG
END TYPE

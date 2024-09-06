'-----------------------------------------------------------------------------------------------------------------------
' File I/O like routines for memory loaded files
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'
'$INCLUDE:'Types.bi'
'$INCLUDE:'PointerOps.bi'

' Simplified QB64-only memory-file
TYPE StringFileType
    buffer AS STRING
    cursor AS _UNSIGNED LONG
END TYPE

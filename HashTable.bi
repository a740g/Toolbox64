'-----------------------------------------------------------------------------------------------------------------------
' A simple hash table for integers and QB64-PE handles
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'
'$INCLUDE:'Types.bi'

CONST __HASHTABLE_KEY_EXISTS& = -1&
CONST __HASHTABLE_KEY_UNAVAILABLE& = -2&

' Hash table entry type
' To extended supported data types, add other value types after V and then write
' wrappers around __HashTable_GetInsertIndex() & __HashTable_GetLookupIndex()
TYPE HashTableType
    U AS _BYTE ' used?
    K AS _UNSIGNED LONG ' key
    V AS LONG ' value
END TYPE

DECLARE LIBRARY "HashTable"
    FUNCTION __HashTable_GetHash~& (BYVAL k AS _UNSIGNED LONG, BYVAL l AS _UNSIGNED LONG)
END DECLARE

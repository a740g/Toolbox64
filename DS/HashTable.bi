'-----------------------------------------------------------------------------------------------------------------------
' C++17 unordered map wrapper library for QB64-PE
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Core/Common.bi'

DECLARE LIBRARY "HashTable"
    FUNCTION HashTable_Create~%&
    SUB HashTable_Destroy (BYVAL t AS _UNSIGNED _OFFSET)
    SUB HashTable_Clear (BYVAL t AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_GetSize~%& (BYVAL t AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_IsEmpty%% (BYVAL t AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_Contains%% (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    SUB HashTable_Remove (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_Remove%% (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    SUB HashTable_SetByte ALIAS "HashTable_Set<int8_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS _BYTE)
    SUB HashTable_SetInteger ALIAS "HashTable_Set<int16_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS INTEGER)
    SUB HashTable_SetLong ALIAS "HashTable_Set<int32_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS LONG)
    SUB HashTable_SetInteger64 ALIAS "HashTable_Set<int64_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS _INTEGER64)
    SUB HashTable_SetSingle ALIAS "HashTable_Set<float>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS SINGLE)
    SUB HashTable_SetDouble ALIAS "HashTable_Set<double>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS DOUBLE)
    SUB HashTable_SetOffset ALIAS "HashTable_Set<uintptr_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS _UNSIGNED _OFFSET)
    SUB HashTable_SetUDT ALIAS "HashTable_SetBlob_" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS _UNSIGNED _OFFSET, BYVAL vSize AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_GetByte%% ALIAS "HashTable_Get<int8_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_GetInteger% ALIAS "HashTable_Get<int16_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_GetLong& ALIAS "HashTable_Get<int32_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_GetInteger64&& ALIAS "HashTable_Get<int64_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_GetSingle! ALIAS "HashTable_Get<float>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_GetDouble# ALIAS "HashTable_Get<double>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_GetOffset~%& ALIAS "HashTable_Get<uintptr_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_GetUDT%% (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS _UNSIGNED _OFFSET, BYVAL vSize AS _UNSIGNED _OFFSET)
END DECLARE

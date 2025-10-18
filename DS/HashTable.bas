'-----------------------------------------------------------------------------------------------------------------------
' C++17 unordered map wrapper library for QB64-PE
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'HashTable.bi'

FUNCTION HashTable_StringContains%% (t AS _UNSIGNED _OFFSET, k AS STRING)
    DECLARE LIBRARY "HashTable"
        FUNCTION __HashTable_StringContains%% ALIAS "HashTable_StringContains_" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET)
    END DECLARE

    HashTable_StringContains = __HashTable_StringContains(t, k, LEN(k))
END FUNCTION

FUNCTION HashTable_StringRemove%% (t AS _UNSIGNED _OFFSET, k AS STRING)
    DECLARE LIBRARY "HashTable"
        FUNCTION __HashTable_StringRemove%% ALIAS "HashTable_StringRemove_" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET)
    END DECLARE

    HashTable_StringRemove = __HashTable_StringRemove(t, k, LEN(k))
END FUNCTION

SUB HashTable_StringRemove (t AS _UNSIGNED _OFFSET, k AS STRING)
    DIM ignored AS _BYTE: ignored = HashTable_StringRemove(t, k)
END SUB

SUB HashTable_SetString (t AS _UNSIGNED _OFFSET, k AS _UNSIGNED _OFFSET, v AS STRING)
    DECLARE LIBRARY "HashTable"
        SUB __HashTable_SetString ALIAS "HashTable_SetBlob_" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS _UNSIGNED _OFFSET, BYVAL vSize AS _UNSIGNED _OFFSET)
    END DECLARE

    __HashTable_SetString t, k, _OFFSET(v), LEN(v)
END SUB

SUB HashTable_StringSetByte (t AS _UNSIGNED _OFFSET, k AS STRING, v AS _BYTE)
    DECLARE LIBRARY "HashTable"
        SUB __HashTable_StringSetByte ALIAS "HashTable_StringSet_" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET, BYVAL v AS _BYTE)
    END DECLARE

    __HashTable_StringSetByte t, k, LEN(k), v
END SUB

SUB HashTable_StringSetInteger (t AS _UNSIGNED _OFFSET, k AS STRING, v AS INTEGER)
    DECLARE LIBRARY "HashTable"
        SUB __HashTable_StringSetInteger ALIAS "HashTable_StringSet_" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET, BYVAL v AS INTEGER)
    END DECLARE

    __HashTable_StringSetInteger t, k, LEN(k), v
END SUB

SUB HashTable_StringSetLong (t AS _UNSIGNED _OFFSET, k AS STRING, v AS LONG)
    DECLARE LIBRARY "HashTable"
        SUB __HashTable_StringSetLong ALIAS "HashTable_StringSet_" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET, BYVAL v AS LONG)
    END DECLARE

    __HashTable_StringSetLong t, k, LEN(k), v
END SUB

SUB HashTable_StringSetInteger64 (t AS _UNSIGNED _OFFSET, k AS STRING, v AS _INTEGER64)
    DECLARE LIBRARY "HashTable"
        SUB __HashTable_StringSetInteger64 ALIAS "HashTable_StringSet_" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET, BYVAL v AS _INTEGER64)
    END DECLARE

    __HashTable_StringSetInteger64 t, k, LEN(k), v
END SUB

SUB HashTable_StringSetSingle (t AS _UNSIGNED _OFFSET, k AS STRING, v AS SINGLE)
    DECLARE LIBRARY "HashTable"
        SUB __HashTable_StringSetSingle ALIAS "HashTable_StringSet_" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET, BYVAL v AS SINGLE)
    END DECLARE

    __HashTable_StringSetSingle t, k, LEN(k), v
END SUB

SUB HashTable_StringSetDouble (t AS _UNSIGNED _OFFSET, k AS STRING, v AS DOUBLE)
    DECLARE LIBRARY "HashTable"
        SUB __HashTable_StringSetDouble ALIAS "HashTable_StringSet_" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET, BYVAL v AS DOUBLE)
    END DECLARE

    __HashTable_StringSetDouble t, k, LEN(k), v
END SUB

SUB HashTable_StringSetOffset (t AS _UNSIGNED _OFFSET, k AS STRING, v AS _UNSIGNED _OFFSET)
    DECLARE LIBRARY "HashTable"
        SUB __HashTable_StringSetOffset ALIAS "HashTable_StringSet_" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET, BYVAL v AS _UNSIGNED _OFFSET)
    END DECLARE

    __HashTable_StringSetOffset t, k, LEN(k), v
END SUB

SUB HashTable_StringSetString (t AS _UNSIGNED _OFFSET, k AS STRING, v AS STRING)
    DECLARE LIBRARY "HashTable"
        SUB __HashTable_StringSetString ALIAS "HashTable_StringSetBlob_" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET, BYVAL v AS _UNSIGNED _OFFSET, BYVAL vSize AS _UNSIGNED _OFFSET)
    END DECLARE

    __HashTable_StringSetString t, k, LEN(k), _OFFSET(v), LEN(v)
END SUB

SUB HashTable_StringSetUDT (t AS _UNSIGNED _OFFSET, k AS STRING, v AS _UNSIGNED _OFFSET, vSize AS _UNSIGNED _OFFSET)
    DECLARE LIBRARY "HashTable"
        SUB __HashTable_StringSetUDT ALIAS "HashTable_StringSetBlob_" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET, BYVAL v AS _UNSIGNED _OFFSET, BYVAL vSize AS _UNSIGNED _OFFSET)
    END DECLARE

    __HashTable_StringSetUDT t, k, LEN(k), v, vSize
END SUB

FUNCTION HashTable_GetString$ (t AS _UNSIGNED _OFFSET, k AS _UNSIGNED _OFFSET)
    DECLARE LIBRARY "HashTable"
        FUNCTION __HashTable_GetString$ ALIAS "HashTable_GetString_" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    END DECLARE

    HashTable_GetString = __HashTable_GetString(t, k)
END FUNCTION

FUNCTION HashTable_StringGetByte%% (t AS _UNSIGNED _OFFSET, k AS STRING)
    DECLARE LIBRARY "HashTable"
        FUNCTION __HashTable_StringGetByte%% ALIAS "HashTable_StringGet_<int8_t>" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET)
    END DECLARE

    HashTable_StringGetByte = __HashTable_StringGetByte(t, k, LEN(k))
END FUNCTION

FUNCTION HashTable_StringGetInteger% (t AS _UNSIGNED _OFFSET, k AS STRING)
    DECLARE LIBRARY "HashTable"
        FUNCTION __HashTable_StringGetInteger% ALIAS "HashTable_StringGet_<int16_t>" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET)
    END DECLARE

    HashTable_StringGetInteger = __HashTable_StringGetInteger(t, k, LEN(k))
END FUNCTION

FUNCTION HashTable_StringGetLong& (t AS _UNSIGNED _OFFSET, k AS STRING)
    DECLARE LIBRARY "HashTable"
        FUNCTION __HashTable_StringGetLong& ALIAS "HashTable_StringGet_<int32_t>" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET)
    END DECLARE

    HashTable_StringGetLong = __HashTable_StringGetLong(t, k, LEN(k))
END FUNCTION

FUNCTION HashTable_StringGetSingle! (t AS _UNSIGNED _OFFSET, k AS STRING)
    DECLARE LIBRARY "HashTable"
        FUNCTION __HashTable_StringGetSingle! ALIAS "HashTable_StringGet_<float>" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET)
    END DECLARE

    HashTable_StringGetSingle = __HashTable_StringGetSingle(t, k, LEN(k))
END FUNCTION

FUNCTION HashTable_StringGetDouble# (t AS _UNSIGNED _OFFSET, k AS STRING)
    DECLARE LIBRARY "HashTable"
        FUNCTION __HashTable_StringGetDouble# ALIAS "HashTable_StringGet_<double>" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET)
    END DECLARE

    HashTable_StringGetDouble = __HashTable_StringGetDouble(t, k, LEN(k))
END FUNCTION

FUNCTION HashTable_StringGetOffset~%& (t AS _UNSIGNED _OFFSET, k AS STRING)
    DECLARE LIBRARY "HashTable"
        FUNCTION __HashTable_StringGetOffset~%& ALIAS "HashTable_StringGet_<uintptr_t>" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET)
    END DECLARE

    HashTable_StringGetOffset = __HashTable_StringGetOffset(t, k, LEN(k))
END FUNCTION

FUNCTION HashTable_StringGetString$ (t AS _UNSIGNED _OFFSET, k AS STRING)
    DECLARE LIBRARY "HashTable"
        FUNCTION __HashTable_StringGetString$ ALIAS "HashTable_StringGetString_" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET)
    END DECLARE

    HashTable_StringGetString = __HashTable_StringGetString(t, k, LEN(k))
END FUNCTION

FUNCTION HashTable_StringGetUDT%% (t AS _UNSIGNED _OFFSET, k AS STRING, v AS _UNSIGNED _OFFSET, vSize AS _UNSIGNED _OFFSET)
    DECLARE LIBRARY "HashTable"
        FUNCTION __HashTable_StringGetUDT ALIAS "HashTable_StringGetBlob_" (BYVAL t AS _UNSIGNED _OFFSET, k AS STRING, BYVAL kSize AS _UNSIGNED _OFFSET, BYVAL v AS _UNSIGNED _OFFSET, BYVAL vSize AS _UNSIGNED _OFFSET)
    END DECLARE

    HashTable_StringGetUDT = __HashTable_StringGetUDT(t, k, LEN(k), v, vSize)
END FUNCTION

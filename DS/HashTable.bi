'-----------------------------------------------------------------------------------------------------------------------
' C++ unordered map wrapper library for QB64-PE
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'
'$INCLUDE:'Types.bi'

'-----------------------------------------------------------------------------------------------------------------------
' Test code for debugging the library
'-----------------------------------------------------------------------------------------------------------------------
'DEFLNG A-Z
'OPTION _EXPLICIT

'CONST TEST_LB = 1
'CONST TEST_UB = 9999999

'WIDTH , 60
'_FONT 14

'DIM myHashTable AS _UNSIGNED _OFFSET: myHashTable = HashTable_Create
'IF myHashTable THEN
'    RANDOMIZE TIMER

'    DIM myarray(TEST_LB TO TEST_UB) AS LONG, t AS DOUBLE
'    DIM AS _UNSIGNED LONG k, i, x

'    FOR k = 1 TO 4
'        PRINT "Add element to array..."
'        t = TIMER
'        FOR i = TEST_UB TO TEST_LB STEP -1
'            myarray(i) = x
'            x = x + 1
'        NEXT
'        PRINT USING "#####.##### seconds"; TIMER - t

'        PRINT "Add element to hash table..."
'        t = TIMER
'        FOR i = TEST_UB TO TEST_LB STEP -1
'            HashTable_SetLong myHashTable, i, myarray(i)
'        NEXT
'        PRINT USING "#####.##### seconds"; TIMER - t

'        PRINT "Read element from array..."
'        t = TIMER
'        FOR i = TEST_UB TO TEST_LB STEP -1
'            x = myarray(i)
'        NEXT
'        PRINT USING "#####.##### seconds"; TIMER - t

'        PRINT "Read element from hash table..."
'        t = TIMER
'        FOR i = TEST_UB TO TEST_LB STEP -1
'            x = HashTable_GetLong(myHashTable, i)
'        NEXT
'        PRINT USING "#####.##### seconds"; TIMER - t

'        PRINT "Remove element from hash table..."
'        t = TIMER
'        FOR i = TEST_UB TO TEST_LB STEP -1
'            HashTable_Remove myHashTable, i
'        NEXT
'        PRINT USING "#####.##### seconds"; TIMER - t
'    NEXT

'    HashTable_Clear myHashTable

'    FOR i = TEST_LB TO TEST_UB
'        LOCATE , 1: PRINT "Adding key"; i; "Size:"; HashTable_Size(myHashTable);
'        HashTable_SetLong myHashTable, i, myarray(i)
'    NEXT
'    PRINT

'    FOR i = TEST_LB TO TEST_UB
'        LOCATE , 1: PRINT "Verifying key: "; i;
'        IF HashTable_GetLong(myHashTable, i) <> myarray(i) THEN
'            PRINT "[fail] ";
'            SLEEP 1
'        ELSE
'            PRINT "[pass] ";
'        END IF
'    NEXT
'    PRINT

'    FOR i = TEST_UB TO TEST_LB STEP -1
'        LOCATE , 1: PRINT "Removing key"; i; "Size:"; HashTable_Size(myHashTable); " ";
'        HashTable_Remove myHashTable, i
'    NEXT
'    PRINT

'    HashTable_SetLong myHashTable, 42, 666
'    HashTable_SetLong myHashTable, 7, 123454321
'    HashTable_SetLong myHashTable, 21, 69

'    PRINT "Value for key 42:"; HashTable_GetLong(myHashTable, 42)
'    PRINT "Value for key 7:"; HashTable_GetLong(myHashTable, 7)
'    PRINT "Value for key 21:"; HashTable_GetLong(myHashTable, 21)

'    PRINT HashTable_Contains(myHashTable, 100)

'    HashTable_Destroy myHashTable
'END IF

'END
'-----------------------------------------------------------------------------------------------------------------------

DECLARE LIBRARY "HashTable"
    FUNCTION HashTable_Create~%&
    SUB HashTable_Destroy (BYVAL table AS _UNSIGNED _OFFSET)
    SUB HashTable_Clear (BYVAL table AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_Size~%& (BYVAL table AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_IsEmpty%% (BYVAL table AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_Contains%% (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    SUB HashTable_SetByte ALIAS "HashTable_Set<int8_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS _BYTE)
    FUNCTION HashTable_GetByte%% ALIAS "HashTable_Get<int8_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    SUB HashTable_SetInteger ALIAS "HashTable_Set<int16_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS INTEGER)
    FUNCTION HashTable_GetInteger% ALIAS "HashTable_Get<int16_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    SUB HashTable_SetLong ALIAS "HashTable_Set<int32_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS LONG)
    FUNCTION HashTable_GetLong& ALIAS "HashTable_Get<int32_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    SUB HashTable_SetInteger64 ALIAS "HashTable_Set<int64_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS _INTEGER64)
    FUNCTION HashTable_GetInteger64&& ALIAS "HashTable_Get<int64_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    SUB HashTable_SetSingle ALIAS "HashTable_Set<float>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS SINGLE)
    FUNCTION HashTable_GetSingle! ALIAS "HashTable_Get<float>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    SUB HashTable_SetDouble ALIAS "HashTable_Set<double>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS DOUBLE)
    FUNCTION HashTable_GetDouble# ALIAS "HashTable_Get<double>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    SUB HashTable_SetOffset ALIAS "HashTable_Set<uintptr_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET, BYVAL v AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_GetOffset~%& ALIAS "HashTable_Get<uintptr_t>" (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    SUB HashTable_Remove (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
    FUNCTION HashTable_Remove%% (BYVAL t AS _UNSIGNED _OFFSET, BYVAL k AS _UNSIGNED _OFFSET)
END DECLARE

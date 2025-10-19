$LET TOOLBOX64_STRICT = TRUE
'$INCLUDE:'../Debug/Test.bi'
$CONSOLE:ONLY

'$INCLUDE:'../DS/HashTable.bi'
'$INCLUDE:'../FS/Pathname.bi'
'$INCLUDE:'../DS/StringFile.bi'
'$INCLUDE:'../Math/Math.bi'
'$INCLUDE:'../Math/Vector2f.bi'
'$INCLUDE:'../Math/Vector2i.bi'

TEST_BEGIN_ALL

Test_Test
Test_Hash
Test_Pathname
Test_StringFile
Test_Math
Test_Vector2f
Test_Vector2i

TEST_END_ALL

SYSTEM

SUB Test_Test
    TEST_CASE_BEGIN "Test framework"

    TEST_REQUIRE 2 * 3 = 6, "2 * 3 = 6"
    TEST_CHECK 1 + 1 = 2, "1 + 1 = 2"
    TEST_REQUIRE_FALSE 1 = 2, "1 = 2"
    TEST_CHECK_FALSE 3 = 4, "3 = 4"
    TEST_REQUIRE2 2 * 3 = 6
    TEST_CHECK2 10 / 2 = 5
    TEST_REQUIRE_FALSE2 1 = 2
    TEST_CHECK_FALSE2 3 = 4

    TEST_CASE_END
END SUB

SUB Test_Hash
    CONST TEST_LB = 0
    CONST TEST_UB = 999999

    DIM myHashTable AS _UNSIGNED _OFFSET: myHashTable = HashTable_Create

    DIM myarray(TEST_LB TO TEST_UB) AS LONG
    DIM AS _UNSIGNED LONG k, i, x

    FOR k = 1 TO 2
        TEST_CASE_BEGIN "HashTable: Add element to array performance"
        FOR i = TEST_LB TO TEST_UB
            myarray(i) = x
            x = x + 1
        NEXT
        TEST_CASE_END

        TEST_CASE_BEGIN "HashTable: Add element to hash table performance"
        FOR i = TEST_LB TO TEST_UB
            HashTable_SetLong myHashTable, i, myarray(i)
        NEXT
        TEST_CASE_END

        TEST_CASE_BEGIN "HashTable: Read element from array performance"
        FOR i = TEST_LB TO TEST_UB
            x = myarray(i)
        NEXT
        TEST_CASE_END

        TEST_CASE_BEGIN "HashTable: Read element from hash table performance"
        FOR i = TEST_LB TO TEST_UB
            x = HashTable_GetLong(myHashTable, i)
        NEXT
        TEST_CASE_END

        TEST_CASE_BEGIN "HashTable: Remove element from hash table performance"
        FOR i = TEST_LB TO TEST_UB
            HashTable_Remove myHashTable, i
        NEXT
        TEST_CASE_END
    NEXT

    HashTable_Clear myHashTable

    FOR i = TEST_LB TO TEST_UB
        HashTable_SetLong myHashTable, i, myarray(i)
    NEXT

    TEST_CASE_BEGIN "HashTable: Size"
    TEST_REQUIRE HashTable_GetSize(myHashTable) = TEST_UB + 1, "HashTable_GetSize(myHashTable) = TEST_UB + 1"
    TEST_CASE_END

    TEST_CASE_BEGIN "HashTable: Lookup test"
    DIM lookupFailed AS _BYTE
    FOR i = TEST_LB TO TEST_UB
        IF HashTable_GetLong(myHashTable, i) <> myarray(i) THEN
            lookupFailed = _TRUE
            EXIT FOR
        END IF
    NEXT
    TEST_REQUIRE NOT lookupFailed, "NOT lookupFailed"
    TEST_CASE_END

    TEST_CASE_BEGIN "HashTable: Remove and insert test"
    FOR i = TEST_UB TO TEST_LB STEP -1
        HashTable_Remove myHashTable, i
    NEXT

    HashTable_SetLong myHashTable, 42, 666
    HashTable_SetLong myHashTable, 7, 123454321
    HashTable_SetLong myHashTable, 21, 69

    TEST_CHECK HashTable_GetLong(myHashTable, 42) = 666, "HashTable_GetLong(MyHashTable(), 42) = 666"
    TEST_CHECK HashTable_GetLong(myHashTable, 7) = 123454321, "HashTable_GetLong(MyHashTable(), 7) = 123454321"
    TEST_CHECK HashTable_GetLong(myHashTable, 21) = 69, "HashTable_GetLong(MyHashTable(), 21) = 69"

    TEST_CHECK HashTable_Contains(myHashTable, 42), "HashTable_Contains(MyHashTable(), 42)"
    TEST_CHECK_FALSE HashTable_Contains(myHashTable, 100), "HashTable_Contains(MyHashTable(), 100)"
    TEST_CASE_END

    HashTable_Destroy myHashTable
END SUB

SUB Test_Pathname
    TEST_CASE_BEGIN "Pathname"

    TEST_CHECK Pathname_IsAbsolute("C:/Windows"), "Pathname_IsAbsolute('C:/Windows')"
    TEST_CHECK Pathname_IsAbsolute("/Windows"), "Pathname_IsAbsolute('/Windows')"
    TEST_CHECK_FALSE Pathname_IsAbsolute("Windows"), "Pathname_IsAbsolute('Windows')"
    TEST_CHECK_FALSE Pathname_IsAbsolute(""), "Pathname_IsAbsolute('')"

    $IF WINDOWS THEN
        TEST_CHECK Pathname_AddDirectorySeparator("Windows") = "Windows\", "Pathname_AddDirectorySeparator('Windows')"
    $ELSE
        TEST_CHECK Pathname_AddDirectorySeparator("Windows") = "Windows/", "Pathname_AddDirectorySeparator('Windows')"
    $END IF

    TEST_CHECK Pathname_AddDirectorySeparator("Windows/") = "Windows/", "Pathname_AddDirectorySeparator('Windows/')"
    TEST_CHECK Pathname_AddDirectorySeparator("") = "", "Pathname_AddDirectorySeparator('')"

    $IF WINDOWS THEN
        TEST_CHECK Pathname_FixDirectorySeparators("C:/Windows\\") = "C:\Windows\\", "Pathname_FixDirectorySeparators('C:/Windows\\')"
    $ELSE
        TEST_CHECK Pathname_FixDirectorySeparators("C:/Windows\\") = "C:/Windows//", "Pathname_FixDirectorySeparators('C:/Windows\\')"
    $END IF

    TEST_CHECK Pathname_FixDirectorySeparators("Windows") = "Windows", "Pathname_FixDirectorySeparators('Windows')"
    TEST_CHECK Pathname_FixDirectorySeparators("") = "", "Pathname_FixDirectorySeparators('')"

    TEST_CHECK Pathname_GetFileName("C:\\foo/bar.ext") = "bar.ext", "Pathname_GetFileName('C:\\foo/bar.ext')"
    TEST_CHECK Pathname_GetFileName("bar.ext") = "bar.ext", "Pathname_GetFileName('bar.ext')"
    TEST_CHECK Pathname_GetFileName("") = "", "Pathname_GetFileName('')"

    TEST_CHECK Pathname_GetPath("C:\\foo/bar.ext") = "C:\\foo/", "Pathname_GetPath('C:\\foo/bar.ext')"
    TEST_CHECK Pathname_GetPath("\\bar.ext") = "\\", "Pathname_GetPath('\\bar.ext')"
    TEST_CHECK Pathname_GetPath("") = "", "Pathname_GetPath('')"

    TEST_CHECK Pathname_HasFileExtension("C:\\foo/bar.ext"), "Pathname_HasFileExtension('C:\\foo/bar.ext')"
    TEST_CHECK_FALSE Pathname_HasFileExtension("bar.ext/"), "Pathname_HasFileExtension('bar.ext/')"
    TEST_CHECK_FALSE Pathname_HasFileExtension(""), "Pathname_HasFileExtension('')"

    TEST_CHECK Pathname_GetFileExtension("C:\\foo/bar.ext") = ".ext", "Pathname_GetFileExtension('C:\\foo/bar.ext')"
    TEST_CHECK Pathname_GetFileExtension("bar.ext/") = "", "Pathname_GetFileExtension('bar.ext/')"
    TEST_CHECK Pathname_GetFileExtension("") = "", "Pathname_GetFileExtension('')"

    TEST_CHECK Pathname_RemoveFileExtension("C:\\foo/bar.ext") = "C:\\foo/bar", "Pathname_RemoveFileExtension('C:\\foo/bar.ext')"
    TEST_CHECK Pathname_RemoveFileExtension("bar.ext/") = "bar.ext/", "Pathname_RemoveFileExtension('bar.ext/')"
    TEST_CHECK Pathname_RemoveFileExtension("") = "", "Pathname_RemoveFileExtension('')"

    TEST_CHECK Pathname_GetDriveOrScheme("https://www.github.com/") = "https:", "Pathname_GetDriveOrScheme('https://www.github.com/')"
    TEST_CHECK Pathname_GetDriveOrScheme("C:\\Windows\\") = "C:", "Pathname_GetDriveOrScheme('C:\\Windows\\')"
    TEST_CHECK Pathname_GetDriveOrScheme("") = "", "Pathname_GetDriveOrScheme('')"

    TEST_CHECK Pathname_Sanitize("<abracadabra.txt/>") = "_abracadabra.txt__", "Pathname_Sanitize('<abracadabra.txt/>')"
    TEST_CHECK Pathname_Sanitize("") = "", "Pathname_Sanitize('')"

    TEST_CASE_END
END SUB

SUB Test_StringFile
    TEST_CASE_BEGIN "StringFile: Basic Operations"

    DIM sf AS StringFile
    StringFile_Create sf, "This_is_a_test_buffer."
    TEST_CHECK LEN(sf.buffer) = 22, "LEN(sf.buffer) = 22"
    TEST_CHECK sf.cursor = 0, "sf.cursor = 0"
    TEST_CHECK StringFile_GetPosition(sf) = 0, "StringFile_GetPosition(sf) = 0"
    TEST_CHECK StringFile_GetSize(sf) = 22, "StringFile_GetSize = 22"
    TEST_CHECK StringFile_ReadString(sf, 22) = "This_is_a_test_buffer.", "StringFile_ReadString(sf, 22)"
    TEST_CHECK StringFile_GetPosition(sf) = 22, "StringFile_GetPosition(sf) = 22"
    TEST_CHECK StringFile_IsEOF(sf), "StringFile_IsEOF(sf)"
    TEST_CHECK LEN(sf.buffer) = 22, "LEN(sf.buffer) = 22"
    TEST_CHECK sf.cursor = 22, "sf.cursor = 22"
    StringFile_Seek sf, StringFile_GetPosition(sf) - 1
    StringFile_WriteString sf, "! Now adding some more text."
    TEST_CHECK StringFile_GetPosition(sf) = 49, "StringFile_GetPosition(sf) = 49"
    TEST_CHECK StringFile_IsEOF(sf), "StringFile_IsEOF(sf)"
    TEST_CHECK LEN(sf.buffer) = 49, "LEN(sf.buffer) = 49"
    TEST_CHECK sf.cursor = 49, "sf.cursor = 49"
    StringFile_Seek sf, 0
    TEST_CHECK StringFile_GetPosition(sf) = 0, "StringFile_GetPosition(sf) = 0"
    TEST_CHECK_FALSE StringFile_IsEOF(sf), "NOT StringFile_IsEOF(sf)"
    TEST_CHECK LEN(sf.buffer) = 49, "LEN(sf.buffer) = 49"
    TEST_CHECK sf.cursor = 0, "sf.cursor = 0"
    TEST_CHECK StringFile_ReadString(sf, 49) = "This_is_a_test_buffer! Now adding some more text.", "StringFile_ReadString(sf, 49)"
    TEST_CHECK StringFile_GetPosition(sf) = 49, "StringFile_GetPosition(sf) = 49"
    TEST_CHECK StringFile_IsEOF(sf), "StringFile_IsEOF(sf)"
    TEST_CHECK LEN(sf.buffer) = 49, "LEN(sf.buffer) = 49"
    TEST_CHECK sf.cursor = 49, "sf.cursor = 49"
    StringFile_Seek sf, 0
    TEST_CHECK CHR$(StringFile_ReadByte(sf)) = "T", "CHR$(StringFile_ReadByte(sf)) = T"
    TEST_CHECK LEN(sf.buffer) = 49, "LEN(sf.buffer) = 49"
    TEST_CHECK sf.cursor = 1, "sf.cursor = 1"
    StringFile_WriteString sf, "XX"
    TEST_CHECK LEN(sf.buffer) = 49, "LEN(sf.buffer) = 49"
    TEST_CHECK sf.cursor = 3, "sf.cursor = 3"
    TEST_CHECK CHR$(StringFile_ReadByte(sf)) = "s", "CHR$(StringFile_ReadByte(sf)) = s"
    StringFile_Seek sf, 0
    TEST_CHECK StringFile_ReadString(sf, 49) = "TXXs_is_a_test_buffer! Now adding some more text.", "StringFile_ReadString(sf, 49)"
    TEST_CHECK StringFile_GetPosition(sf) = 49, "StringFile_GetPosition(sf) = 49"
    TEST_CHECK StringFile_IsEOF(sf), "StringFile_IsEOF(sf)"
    TEST_CHECK LEN(sf.buffer) = 49, "LEN(sf.buffer) = 49"
    TEST_CHECK sf.cursor = 49, "sf.cursor = 49"
    StringFile_Seek sf, 0
    StringFile_WriteInteger sf, 420
    StringFile_Seek sf, 0
    TEST_CHECK StringFile_ReadInteger(sf) = 420, "StringFile_ReadInteger(sf) = 420"
    TEST_CHECK LEN(sf.buffer) = 49, "LEN(sf.buffer) = 49"
    StringFile_Seek sf, 0
    StringFile_WriteByte sf, 255
    StringFile_Seek sf, 0
    TEST_CHECK StringFile_ReadByte(sf) = 255, "StringFile_ReadByte(sf) = 255"
    TEST_CHECK LEN(sf.buffer) = 49, "LEN(sf.buffer) = 49"
    StringFile_Seek sf, 0
    StringFile_WriteLong sf, 192000
    StringFile_Seek sf, 0
    TEST_CHECK StringFile_ReadLong(sf) = 192000, "StringFile_ReadLong(sf) = 192000"
    TEST_CHECK LEN(sf.buffer) = 49, "LEN(sf.buffer) = 49"
    StringFile_Seek sf, 0
    StringFile_WriteSingle sf, 752.334
    StringFile_Seek sf, 0
    TEST_CHECK StringFile_ReadSingle(sf) = 752.334, "StringFile_ReadSingle(sf) = 752.334"
    TEST_CHECK LEN(sf.buffer) = 49, "LEN(sf.buffer) = 49"
    StringFile_Seek sf, 0
    StringFile_WriteDouble sf, 23232323.242423424#
    StringFile_Seek sf, 0
    TEST_CHECK StringFile_ReadDouble(sf) = 23232323.242423424#, "StringFile_ReadDouble(sf) = 23232323.242423424#"
    TEST_CHECK LEN(sf.buffer) = 49, "LEN(sf.buffer) = 49"
    StringFile_Seek sf, 0
    StringFile_WriteInteger64 sf, 9999999999999999&&
    StringFile_Seek sf, 0
    TEST_CHECK StringFile_ReadInteger64(sf) = 9999999999999999&&, "StringFile_ReadInteger64(sf) = 9999999999999999&&"
    TEST_CHECK LEN(sf.buffer) = 49, "LEN(sf.buffer) = 49"

    TEST_CASE_END

    TEST_CASE_BEGIN "StringFile: Resize and Boundary Tests"
    
    ' Test resize operations
    StringFile_Create sf, "Original"
    TEST_CHECK StringFile_GetSize(sf) = 8, "Initial size = 8"
    
    ' Grow buffer
    StringFile_Resize sf, 16
    TEST_CHECK StringFile_GetSize(sf) = 16, "Grown size = 16"
    TEST_CHECK LEFT$(sf.buffer, 8) = "Original", "Content preserved after grow"
    
    ' Shrink buffer
    StringFile_Resize sf, 4
    TEST_CHECK StringFile_GetSize(sf) = 4, "Shrunk size = 4"
    TEST_CHECK sf.buffer = "Orig", "Content truncated after shrink"
    
    ' Test offset operations
    DIM testOffset AS _OFFSET
    testOffset = 12345
    StringFile_Seek sf, 0
    StringFile_WriteOffset sf, testOffset
    StringFile_Seek sf, 0
    TEST_CHECK StringFile_ReadOffset(sf) = testOffset, "Offset read/write"
    
    ' Test boundary conditions
    StringFile_Create sf, "1234"
    StringFile_Seek sf, 4 ' Seek to EOF is valid
    TEST_CHECK StringFile_IsEOF(sf), "EOF at end"
    TEST_CHECK StringFile_GetPosition(sf) = 4, "Position at EOF"
    
    ' Test extreme values
    StringFile_Create sf, ""
    StringFile_Seek sf, 0
    StringFile_WriteDouble sf, 1E+308 ' Near max double
    StringFile_Seek sf, 0
    TEST_CHECK ABS(StringFile_ReadDouble(sf) - 1E+308) < 1E+298, "Large double"
    
    StringFile_Seek sf, 0
    StringFile_WriteDouble sf, 1E-308 ' Near min positive double
    StringFile_Seek sf, 0
    TEST_CHECK ABS((StringFile_ReadDouble(sf) - 1E-308) / 1E-308) < 0.000001, "Small double relative error"

    TEST_CASE_END

    TEST_CASE_BEGIN "StringFile: Boundary Conditions"
    
    ' Test boundary read conditions
    StringFile_Create sf, "123"
    StringFile_Seek sf, 3 ' Seek to EOF
    TEST_CHECK StringFile_IsEOF(sf), "EOF at end position"
    TEST_CHECK StringFile_GetPosition(sf) = 3, "Correct EOF position"
    
    ' Test partial reads at end
    StringFile_Seek sf, 2
    TEST_CHECK StringFile_ReadString(sf, 10) = "3", "Partial read at end"
    TEST_CHECK StringFile_IsEOF(sf), "EOF after partial read"
    
    ' Test boundary writes
    StringFile_Seek sf, 3
    StringFile_WriteString sf, "456" ' Write at EOF
    TEST_CHECK StringFile_GetSize(sf) = 6, "Size after EOF write"
    StringFile_Seek sf, 0
    TEST_CHECK StringFile_ReadString(sf, 6) = "123456", "Content after EOF write"

    TEST_CASE_END
END SUB

SUB Test_Math
    TEST_CASE_BEGIN "Math"

    DIM n AS LONG
    n = Math_GetRandomBetween(10, 20)
    TEST_CHECK n >= 10 AND n <= 20, "n >= 10 AND n <= 20"

    TEST_CHECK Math_IsSingleNaN(0 / 0), "Math_IsSingleNaN(0 / 0)"
    TEST_CHECK_FALSE Math_IsSingleNaN(1), "Math_IsSingleNaN(1)"

    TEST_CHECK Math_IsDoubleNaN(0 / 0), "Math_IsDoubleNaN(0 / 0)"
    TEST_CHECK_FALSE Math_IsDoubleNaN(1), "Math_IsDoubleNaN(1)"

    TEST_CHECK Math_IsLongEven(2), "Math_IsLongEven(2)"
    TEST_CHECK_FALSE Math_IsLongEven(1), "Math_IsLongEven(1)"

    TEST_CHECK Math_IsInteger64Even(2), "Math_IsInteger64Even(2)"
    TEST_CHECK_FALSE Math_IsInteger64Even(1), "Math_IsInteger64Even(1)"

    TEST_CHECK Math_IsLongPowerOf2(2), "Math_IsLongPowerOf2(2)"
    TEST_CHECK_FALSE Math_IsLongPowerOf2(3), "Math_IsLongPowerOf2(3)"

    TEST_CHECK Math_IsInteger64PowerOf2(2), "Math_IsInteger64PowerOf2(2)"
    TEST_CHECK_FALSE Math_IsInteger64PowerOf2(3), "Math_IsInteger64PowerOf2(3)"

    TEST_CHECK Math_RoundUpLongToPowerOf2(3) = 4, "Math_RoundUpLongToPowerOf2(3) = 4"
    TEST_CHECK Math_RoundUpInteger64ToPowerOf2(3) = 4, "Math_RoundUpInteger64ToPowerOf2(3) = 4"

    TEST_CHECK Math_RoundDownLongToPowerOf2(3) = 2, "Math_RoundDownLongToPowerOf2(3) = 2"
    TEST_CHECK Math_RoundDownInteger64ToPowerOf2(3) = 2, "Math_RoundDownInteger64ToPowerOf2(3) = 2"

    TEST_CHECK Math_GetDigitFromLong(123, 0) = 3, "Math_GetDigitFromLong(123, 0) = 3"
    TEST_CHECK Math_GetDigitFromLong(123, 1) = 2, "Math_GetDigitFromLong(123, 1) = 2"
    TEST_CHECK Math_GetDigitFromLong(123, 2) = 1, "Math_GetDigitFromLong(123, 2) = 1"

    TEST_CHECK Math_GetDigitFromInteger64(123, 0) = 3, "Math_GetDigitFromInteger64(123, 0) = 3"
    TEST_CHECK Math_GetDigitFromInteger64(123, 1) = 2, "Math_GetDigitFromInteger64(123, 1) = 2"
    TEST_CHECK Math_GetDigitFromInteger64(123, 2) = 1, "Math_GetDigitFromInteger64(123, 2) = 1"

    TEST_CHECK Math_AverageLong(10, 20) = 15, "Math_AverageLong(10, 20) = 15"
    TEST_CHECK Math_AverageInteger64(10, 20) = 15, "Math_AverageInteger64(10, 20) = 15"

    TEST_CHECK Math_ClampLong(5, 10, 20) = 10, "Math_ClampLong(5, 10, 20) = 10"
    TEST_CHECK Math_ClampLong(25, 10, 20) = 20, "Math_ClampLong(25, 10, 20) = 20"
    TEST_CHECK Math_ClampLong(15, 10, 20) = 15, "Math_ClampLong(15, 10, 20) = 15"

    TEST_CHECK Math_ClampInteger64(5, 10, 20) = 10, "Math_ClampInteger64(5, 10, 20) = 10"
    TEST_CHECK Math_ClampInteger64(25, 10, 20) = 20, "Math_ClampInteger64(25, 10, 20) = 20"
    TEST_CHECK Math_ClampInteger64(15, 10, 20) = 15, "Math_ClampInteger64(15, 10, 20) = 15"

    TEST_CHECK Math_ClampSingle(5, 10, 20) = 10, "Math_ClampSingle(5, 10, 20) = 10"
    TEST_CHECK Math_ClampSingle(25, 10, 20) = 20, "Math_ClampSingle(25, 10, 20) = 20"
    TEST_CHECK Math_ClampSingle(15, 10, 20) = 15, "Math_ClampSingle(15, 10, 20) = 15"

    TEST_CHECK Math_ClampDouble(5, 10, 20) = 10, "Math_ClampDouble(5, 10, 20) = 10"
    TEST_CHECK Math_ClampDouble(25, 10, 20) = 20, "Math_ClampDouble(25, 10, 20) = 20"
    TEST_CHECK Math_ClampDouble(15, 10, 20) = 15, "Math_ClampDouble(15, 10, 20) = 15"

    TEST_CHECK Math_RemapLong(5, 0, 10, 0, 100) = 50, "Math_RemapLong(5, 0, 10, 0, 100) = 50"
    TEST_CHECK Math_RemapInteger64(5, 0, 10, 0, 100) = 50, "Math_RemapInteger64(5, 0, 10, 0, 100) = 50"
    TEST_CHECK Math_RemapSingle(5, 0, 10, 0, 100) = 50, "Math_RemapSingle(5, 0, 10, 0, 100) = 50"
    TEST_CHECK Math_RemapDouble(5, 0, 10, 0, 100) = 50, "Math_RemapDouble(5, 0, 10, 0, 100) = 50"

    TEST_CHECK Math_GetMaxSingle(1, 2) = 2, "Math_GetMaxSingle(1, 2) = 2"
    TEST_CHECK Math_GetMinSingle(1, 2) = 1, "Math_GetMinSingle(1, 2) = 1"
    TEST_CHECK Math_GetMaxDouble(1, 2) = 2, "Math_GetMaxDouble(1, 2) = 2"
    TEST_CHECK Math_GetMinDouble(1, 2) = 1, "Math_GetMinDouble(1, 2) = 1"
    TEST_CHECK Math_GetMaxLong(1, 2) = 2, "Math_GetMaxLong(1, 2) = 2"
    TEST_CHECK Math_GetMinLong(1, 2) = 1, "Math_GetMinLong(1, 2) = 1"
    TEST_CHECK Math_GetMaxInteger64(1, 2) = 2, "Math_GetMaxInteger64(1, 2) = 2"
    TEST_CHECK Math_GetMinInteger64(1, 2) = 1, "Math_GetMinInteger64(1, 2) = 1"

    TEST_CHECK Math_LerpSingle(0, 10, 0.5) = 5, "Math_LerpSingle(0, 10, 0.5) = 5"
    TEST_CHECK Math_LerpDouble(0, 10, 0.5) = 5, "Math_LerpDouble(0, 10, 0.5) = 5"

    TEST_CHECK Math_NormalizeSingle(5, 0, 10) = 0.5, "Math_NormalizeSingle(5, 0, 10) = 0.5"
    TEST_CHECK Math_NormalizeDouble(5, 0, 10) = 0.5, "Math_NormalizeDouble(5, 0, 10) = 0.5"

    TEST_CHECK Math_WrapSingle(12, 0, 10) = 2, "Math_WrapSingle(12, 0, 10) = 2"
    TEST_CHECK Math_WrapDouble(12, 0, 10) = 2, "Math_WrapDouble(12, 0, 10) = 2"

    TEST_CHECK Math_IsSingleEqual(1.0, 1.0), "Math_IsSingleEqual(1.0, 1.0)"
    TEST_CHECK_FALSE Math_IsSingleEqual(1.0, 2.0), "Math_IsSingleEqual(1.0, 2.0)"

    TEST_CHECK Math_IsDoubleEqual(1.0, 1.0), "Math_IsDoubleEqual(1.0, 1.0)"
    TEST_CHECK_FALSE Math_IsDoubleEqual(1.0, 2.0), "Math_IsDoubleEqual(1.0, 2.0)"

    TEST_CHECK Math_FMASingle(2, 3, 4) = 10, "Math_FMASingle(2, 3, 4) = 10"
    TEST_CHECK Math_FMADouble(2, 3, 4) = 10, "Math_FMADouble(2, 3, 4) = 10"

    TEST_CHECK Math_PowerSingle(2, 3) = 8, "Math_PowerSingle(2, 3) = 8"
    TEST_CHECK Math_PowerDouble(2, 3) = 8, "Math_PowerDouble(2, 3) = 8"

    TEST_CHECK Math_FastPowerSingle(2, 3) = 8, "Math_FastPowerSingle(2, 3) = 8"
    TEST_CHECK Math_FastPowerDouble(2, 3) = 8, "Math_FastPowerDouble(2, 3) = 8"

    TEST_CHECK ABS(Math_FastSquareRoot(9) - 3) < 0.2, "ABS(Math_FastSquareRoot(9) - 3) < 0.2"
    TEST_CHECK ABS(Math_FastInverseSquareRoot(4) - 0.5) < 0.001, "ABS(Math_FastInverseSquareRoot(4) - 0.5) < 0.001"

    TEST_CHECK Math_Log10Single(100) = 2, "Math_Log10Single(100) = 2"
    TEST_CHECK Math_Log10Double(100) = 2, "Math_Log10Double(100) = 2"

    TEST_CHECK Math_Log2Single(8) = 3, "Math_Log2Single(8) = 3"
    TEST_CHECK Math_Log2Double(8) = 3, "Math_Log2Double(8) = 3"

    TEST_CHECK Math_CubeRootSingle(27) = 3, "Math_CubeRootSingle(27) = 3"
    TEST_CHECK Math_CubeRootDouble(27) = 3, "Math_CubeRootDouble(27) = 3"

    TEST_CHECK Math_MulDiv(10, 2, 5) = 4, "Math_MulDiv(10, 2, 5) = 4"

    TEST_CASE_END
END SUB

SUB Test_Vector2f
    TEST_CASE_BEGIN "Vector2f: Basic Operations"

    DIM v AS Vector2f, a AS Vector2f, b AS Vector2f, dst AS Vector2f
    DIM tolerance AS SINGLE: tolerance = 0.0001 ' For floating point comparisons

    ' Test Initialize and Reset
    Vector2f_Initialize 3.0!, 4.0!, v
    TEST_CHECK Math_IsSingleEqual(v.x, 3.0!), "Vector2f_Initialize x=3"
    TEST_CHECK Math_IsSingleEqual(v.y, 4.0!), "Vector2f_Initialize y=4"
    TEST_CHECK Math_IsSingleEqual(Vector2f_GetLength(v), 5.0!), "Vector2f_GetLength = 5"

    Vector2f_Reset v
    TEST_CHECK Vector2f_IsNull(v), "Vector2f_Reset nulls vector"
    TEST_CHECK Math_IsSingleEqual(v.x, 0.0!), "Vector2f_Reset x=0"
    TEST_CHECK Math_IsSingleEqual(v.y, 0.0!), "Vector2f_Reset y=0"

    TEST_CASE_END

    TEST_CASE_BEGIN "Vector2f: Arithmetic Operations"

    ' Test Add, Subtract, Multiply, Divide
    Vector2f_Initialize 1.0!, 2.0!, a
    Vector2f_Initialize 3.0!, 4.0!, b

    Vector2f_Add a, b, dst
    TEST_CHECK Math_IsSingleEqual(dst.x, 4.0!), "Vector2f_Add x=1+3=4"
    TEST_CHECK Math_IsSingleEqual(dst.y, 6.0!), "Vector2f_Add y=2+4=6"

    Vector2f_Subtract b, a, dst
    TEST_CHECK Math_IsSingleEqual(dst.x, 2.0!), "Vector2f_Subtract x=3-1=2"
    TEST_CHECK Math_IsSingleEqual(dst.y, 2.0!), "Vector2f_Subtract y=4-2=2"

    Vector2f_Multiply a, b, dst
    TEST_CHECK Math_IsSingleEqual(dst.x, 3.0!), "Vector2f_Multiply x=1*3=3"
    TEST_CHECK Math_IsSingleEqual(dst.y, 8.0!), "Vector2f_Multiply y=2*4=8"

    Vector2f_Divide b, a, dst
    TEST_CHECK Math_IsSingleEqual(dst.x, 3.0!), "Vector2f_Divide x=3/1=3"
    TEST_CHECK Math_IsSingleEqual(dst.y, 2.0!), "Vector2f_Divide y=4/2=2"

    TEST_CASE_END

    TEST_CASE_BEGIN "Vector2f: Vector Operations"

    ' Test Normalize, Length, Distance
    Vector2f_Initialize 3.0!, 4.0!, v
    Vector2f_Normalize v, dst
    TEST_CHECK ABS(dst.x - 0.6) < tolerance, "ABS(dst.x - 0.6) < tolerance"
    TEST_CHECK ABS(dst.y - 0.8) < tolerance, "ABS(dst.y - 0.8) < tolerance"
    TEST_CHECK ABS(Vector2f_GetLength(dst) - 1.0!) < tolerance, "ABS(Vector2f_GetLength(dst) - 1.0!) < tolerance"

    Vector2f_Initialize 1.0!, 1.0!, a
    Vector2f_Initialize 4.0!, 5.0!, b
    TEST_CHECK Math_IsSingleEqual(Vector2f_GetDistance(a, b), 5.0!), "Vector2f_GetDistance = 5"
    TEST_CHECK Math_IsSingleEqual(Vector2f_GetDotProduct(a, b), 9.0!), "Vector2f_GetDotProduct = 9"

    TEST_CASE_END

    TEST_CASE_BEGIN "Vector2f: Transformations"

    ' Test Rotate, Lerp, Reflect
    Vector2f_Initialize 1.0!, 0.0!, v
    Vector2f_Rotate v, 1.5708!, dst ' ~90 degrees in radians
    TEST_CHECK ABS(dst.x) < tolerance, "ABS(dst.x) < tolerance"
    TEST_CHECK ABS(dst.y - 1.0!) < tolerance, "ABS(dst.y - 1.0!) < tolerance"

    Vector2f_Initialize 0.0!, 0.0!, a
    Vector2f_Initialize 10.0!, 10.0!, b
    Vector2f_Lerp a, b, 0.5!, dst
    TEST_CHECK Math_IsSingleEqual(dst.x, 5.0!), "Vector2f_Lerp x=5"
    TEST_CHECK Math_IsSingleEqual(dst.y, 5.0!), "Vector2f_Lerp y=5"

    Vector2f_Initialize 1.0!, -1.0!, v
    Vector2f_Initialize 0.0!, 1.0!, b ' Normal vector
    Vector2f_Reflect v, b, dst
    TEST_CHECK ABS(dst.x - 1.0!) < tolerance, "ABS(dst.x - 1.0!) < tolerance"
    TEST_CHECK ABS(dst.y - 1.0!) < tolerance, "ABS(dst.y - 1.0!) < tolerance"

    TEST_CASE_END

    TEST_CASE_BEGIN "Vector2f: Special Operations"

    ' Test MoveTowards, Clamp, Invert
    Vector2f_Initialize 0.0!, 0.0!, a
    Vector2f_Initialize 10.0!, 0.0!, b
    Vector2f_MoveTowards a, b, 3.0!, dst
    TEST_CHECK Math_IsSingleEqual(dst.x, 3.0!), "Vector2f_MoveTowards x=3"
    TEST_CHECK Math_IsSingleEqual(dst.y, 0.0!), "Vector2f_MoveTowards y=0"

    Vector2f_Initialize 5.0!, 5.0!, v
    Vector2f_Initialize -1.0!, -1.0!, a ' Min
    Vector2f_Initialize 2.0!, 2.0!, b ' Max
    Vector2f_Clamp v, a, b, dst
    TEST_CHECK Math_IsSingleEqual(dst.x, 2.0!), "Vector2f_Clamp x=2"
    TEST_CHECK Math_IsSingleEqual(dst.y, 2.0!), "Vector2f_Clamp y=2"

    Vector2f_Initialize 2.0!, 3.0!, v
    Vector2f_Negate v, dst
    TEST_CHECK Math_IsSingleEqual(dst.x, -2.0!), "Vector2f_Negate x=-2"
    TEST_CHECK Math_IsSingleEqual(dst.y, -3.0!), "Vector2f_Negate y=-3"

    Vector2f_Initialize 2.0!, 4.0!, v
    Vector2f_Reciprocal v, dst
    TEST_CHECK Math_IsSingleEqual(dst.x, 0.5!), "Vector2f_Reciprocal x=1/2=0.5"
    TEST_CHECK Math_IsSingleEqual(dst.y, 0.25!), "Vector2f_Reciprocal y=1/4=0.25"

    ' TurnLeft (90 deg CCW)
    Vector2f_Initialize 1.0!, 2.0!, v
    Vector2f_TurnLeft v, dst
    TEST_CHECK Math_IsSingleEqual(dst.x, -2.0!), "Vector2f_TurnLeft x=-2"
    TEST_CHECK Math_IsSingleEqual(dst.y, 1.0!), "Vector2f_TurnLeft y=1"

    ' TurnRight (90 deg CW)
    Vector2f_TurnRight v, dst
    TEST_CHECK Math_IsSingleEqual(dst.x, 2.0!), "Vector2f_TurnRight x=2"
    TEST_CHECK Math_IsSingleEqual(dst.y, -1.0!), "Vector2f_TurnRight y=-1"

    ' FlipVertical
    Vector2f_FlipVertical v, dst
    TEST_CHECK Math_IsSingleEqual(dst.x, 1.0!), "Vector2f_FlipVertical x=1"
    TEST_CHECK Math_IsSingleEqual(dst.y, -2.0!), "Vector2f_FlipVertical y=-2"

    ' FlipHorizontal
    Vector2f_FlipHorizontal v, dst
    TEST_CHECK Math_IsSingleEqual(dst.x, -1.0!), "Vector2f_FlipHorizontal x=-1"
    TEST_CHECK Math_IsSingleEqual(dst.y, 2.0!), "Vector2f_FlipHorizontal y=2"

    ' CrossProduct
    Vector2f_Initialize 3.0!, 4.0!, a
    Vector2f_Initialize 5.0!, 6.0!, b
    TEST_CHECK Math_IsSingleEqual(Vector2f_GetCrossProduct(a, b), -2.0!), "Vector2f_GetCrossProduct = -2"

    TEST_CASE_END
END SUB

SUB Test_Vector2i
    TEST_CASE_BEGIN "Vector2i: Basic Operations"
    DIM v AS Vector2i, a AS Vector2i, b AS Vector2i, dst AS Vector2i

    Vector2i_Initialize 3, 4, v
    TEST_CHECK v.x = 3, "Vector2i_Initialize x=3"
    TEST_CHECK v.y = 4, "Vector2i_Initialize y=4"
    TEST_CHECK Vector2i_GetLength(v) = 5, "Vector2i_GetLength = 5"

    Vector2i_Reset v
    TEST_CHECK Vector2i_IsNull(v), "Vector2i_Reset nulls vector"
    TEST_CHECK v.x = 0, "Vector2i_Reset x=0"
    TEST_CHECK v.y = 0, "Vector2i_Reset y=0"
    TEST_CASE_END

    TEST_CASE_BEGIN "Vector2i: Arithmetic Operations"
    Vector2i_Initialize 1, 2, a
    Vector2i_Initialize 3, 4, b
    Vector2i_Add a, b, dst
    TEST_CHECK dst.x = 4, "Vector2i_Add x=1+3=4"
    TEST_CHECK dst.y = 6, "Vector2i_Add y=2+4=6"
    Vector2i_Subtract b, a, dst
    TEST_CHECK dst.x = 2, "Vector2i_Subtract x=3-1=2"
    TEST_CHECK dst.y = 2, "Vector2i_Subtract y=4-2=2"
    Vector2i_Multiply a, b, dst
    TEST_CHECK dst.x = 3, "Vector2i_Multiply x=1*3=3"
    TEST_CHECK dst.y = 8, "Vector2i_Multiply y=2*4=8"
    Vector2i_Divide b, a, dst
    TEST_CHECK dst.x = 3, "Vector2i_Divide x=3/1=3"
    TEST_CHECK dst.y = 2, "Vector2i_Divide y=4/2=2"
    TEST_CASE_END

    TEST_CASE_BEGIN "Vector2i: Vector Operations"
    Vector2i_Initialize 3, 4, v
    TEST_CHECK Vector2i_GetLength(v) = 5, "Vector2i_GetLength = 5"
    Vector2i_Initialize 1, 1, a
    Vector2i_Initialize 4, 5, b
    TEST_CHECK Vector2i_GetDistance(a, b) = 5, "Vector2i_GetDistance = 5"
    TEST_CHECK Vector2i_GetDotProduct(a, b) = 9, "Vector2i_GetDotProduct = 9"
    TEST_CHECK Vector2i_GetCrossProduct(a, b) = 1, "Vector2i_GetCrossProduct = 1"
    TEST_CASE_END

    TEST_CASE_BEGIN "Vector2i: Transformations"
    Vector2i_Initialize 1, 2, v
    Vector2i_TurnLeft v, dst
    TEST_CHECK dst.x = -2, "Vector2i_TurnLeft x=-2"
    TEST_CHECK dst.y = 1, "Vector2i_TurnLeft y=1"
    Vector2i_TurnRight v, dst
    TEST_CHECK dst.x = 2, "Vector2i_TurnRight x=2"
    TEST_CHECK dst.y = -1, "Vector2i_TurnRight y=-1"
    Vector2i_FlipVertical v, dst
    TEST_CHECK dst.x = 1, "Vector2i_FlipVertical x=1"
    TEST_CHECK dst.y = -2, "Vector2i_FlipVertical y=-2"
    Vector2i_FlipHorizontal v, dst
    TEST_CHECK dst.x = -1, "Vector2i_FlipHorizontal x=-1"
    TEST_CHECK dst.y = 2, "Vector2i_FlipHorizontal y=2"
    TEST_CASE_END

    TEST_CASE_BEGIN "Vector2i: Special Operations"
    Vector2i_Initialize 0, 0, a
    Vector2i_Initialize 10, 0, b
    Vector2i_MoveTowards a, b, 3, dst
    TEST_CHECK dst.x = 3, "Vector2i_MoveTowards x=3"
    TEST_CHECK dst.y = 0, "Vector2i_MoveTowards y=0"
    Vector2i_Initialize 5, 5, v
    Vector2i_Initialize -1, -1, a
    Vector2i_Initialize 2, 2, b
    Vector2i_Clamp v, a, b, dst
    TEST_CHECK dst.x = 2, "Vector2i_Clamp x=2"
    TEST_CHECK dst.y = 2, "Vector2i_Clamp y=2"
    Vector2i_Initialize 2, 3, v
    Vector2i_Negate v, dst
    TEST_CHECK dst.x = -2, "Vector2i_Negate x=-2"
    TEST_CHECK dst.y = -3, "Vector2i_Negate y=-3"
    TEST_CASE_END
END SUB

'$INCLUDE:'../DS/StringFile.bas'
'$INCLUDE:'../FS/Pathname.bas'
'$INCLUDE:'../DS/HashTable.bas'
'$INCLUDE:'../Debug/Test.bas'

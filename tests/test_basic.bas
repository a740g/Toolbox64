$LET TOOLBOX64_STRICT = TRUE
'$INCLUDE:'../Debug/Test.bi'
$CONSOLE:ONLY

'$INCLUDE:'../HashTable.bi'
'$INCLUDE:'../Pathname.bi'
'$INCLUDE:'../StringFile.bi'
'$INCLUDE:'../Math/Math.bi'

TEST_BEGIN_ALL

Test_Test
Test_Hash
Test_Pathname
Test_StringFile
Test_Math

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
    CONST TEST_UB = 9999999

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
        TEST_CHECK Pathname_FixDirectoryName("Windows") = "Windows\", "Pathname_FixDirectoryName('Windows')"
    $ELSE
        TEST_CHECK Pathname_FixDirectoryName("Windows") = "Windows/", "Pathname_FixDirectoryName('Windows')"
    $END IF

    TEST_CHECK Pathname_FixDirectoryName("Windows/") = "Windows/", "Pathname_FixDirectoryName('Windows/')"
    TEST_CHECK Pathname_FixDirectoryName("") = "", "Pathname_FixDirectoryName('')"

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

    TEST_CHECK Pathname_MakeLegalFileName("<abracadabra.txt/>") = "_abracadabra.txt__", "Pathname_MakeLegalFileName('<abracadabra.txt/>')"
    TEST_CHECK Pathname_MakeLegalFileName("") = "", "Pathname_MakeLegalFileName('')"

    TEST_CASE_END
END SUB

SUB Test_StringFile
    TEST_CASE_BEGIN "StringFile"

    DIM sf AS StringFileType
    StringFile_Create sf, "This_is_a_test_buffer."
    TEST_CHECK LEN(sf.buffer) = 22, "LEN(sf.buffer) = 22"
    TEST_CHECK sf.cursor = 0, "sf.cursor = 0"
    TEST_CHECK StringFile_GetPosition(sf) = 0, "StringFile_GetPosition(sf) = 0"
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

'$INCLUDE:'../StringFile.bas'
'$INCLUDE:'../Pathname.bas'
'$INCLUDE:'../Debug/Test.bas'

'-----------------------------------------------------------------------------------------------------------------------
' File I/O like routines for memory loaded files
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF MEMFILE_BI = UNDEFINED THEN
    $LET MEMFILE_BI = TRUE

    '$INCLUDE:'Common.bi'
    '$INCLUDE:'Types.bi'

    ' Simplified QB64-only memory-file
    TYPE StringFileType
        buffer AS STRING
        cursor AS LONG
    END TYPE

    DECLARE LIBRARY "MemFile"
        FUNCTION MemFile_Create~%& (BYVAL src AS _UNSIGNED _OFFSET, BYVAL size AS _UNSIGNED _OFFSET)
        SUB MemFile_Destroy (BYVAL memFile AS _UNSIGNED _OFFSET)
        FUNCTION MemFile_IsEOF%% (BYVAL memFile AS _UNSIGNED _OFFSET)
        $IF 32BIT THEN
            FUNCTION MemFile_GetSize~& (BYVAL memFile AS _UNSIGNED _OFFSET)
            FUNCTION MemFile_GetPosition~& (BYVAL memFile AS _UNSIGNED _OFFSET)
            FUNCTION MemFile_Read~& (BYVAL memFile AS _UNSIGNED _OFFSET, BYVAL dst AS _UNSIGNED _OFFSET, BYVAL size AS _UNSIGNED _OFFSET)
            FUNCTION MemFile_Write~& (BYVAL memFile AS _UNSIGNED _OFFSET, BYVAL src AS _UNSIGNED _OFFSET, BYVAL size AS _UNSIGNED _OFFSET)
        $ELSE
            FUNCTION MemFile_GetSize~&& (BYVAL memFile AS _UNSIGNED _OFFSET)
            FUNCTION MemFile_GetPosition~&& (BYVAL memFile AS _UNSIGNED _OFFSET)
            FUNCTION MemFile_Read~&& (BYVAL memFile AS _UNSIGNED _OFFSET, BYVAL dst AS _UNSIGNED _OFFSET, BYVAL size AS _UNSIGNED _OFFSET)
            FUNCTION MemFile_Write~&& (BYVAL memFile AS _UNSIGNED _OFFSET, BYVAL src AS _UNSIGNED _OFFSET, BYVAL size AS _UNSIGNED _OFFSET)
        $END IF
        FUNCTION MemFile_Seek%% (BYVAL memFile AS _UNSIGNED _OFFSET, BYVAL position AS _UNSIGNED _OFFSET)
        SUB MemFile_Resize (BYVAL memFile AS _UNSIGNED _OFFSET, BYVAL newSize AS _UNSIGNED _OFFSET)
        FUNCTION MemFile_ReadByte%% (BYVAL memFile AS _UNSIGNED _OFFSET, dst AS _UNSIGNED _BYTE)
        FUNCTION MemFile_WriteByte% (BYVAL memFile AS _UNSIGNED _OFFSET, BYVAL src AS _UNSIGNED _BYTE)
        FUNCTION MemFile_ReadInteger%% (BYVAL memFile AS _UNSIGNED _OFFSET, dst AS _UNSIGNED INTEGER)
        FUNCTION MemFile_WriteInteger%% (BYVAL memFile AS _UNSIGNED _OFFSET, BYVAL src AS _UNSIGNED INTEGER)
        FUNCTION MemFile_ReadLong%% (BYVAL memFile AS _UNSIGNED _OFFSET, dst AS _UNSIGNED LONG)
        FUNCTION MemFile_WriteLong%% (BYVAL memFile AS _UNSIGNED _OFFSET, BYVAL src AS _UNSIGNED LONG)
        FUNCTION MemFile_ReadSingle%% (BYVAL memFile AS _UNSIGNED _OFFSET, dst AS SINGLE)
        FUNCTION MemFile_WriteSingle%% (BYVAL memFile AS _UNSIGNED _OFFSET, BYVAL src AS SINGLE)
        FUNCTION MemFile_ReadInteger64%% (BYVAL memFile AS _UNSIGNED _OFFSET, dst AS _UNSIGNED _INTEGER64)
        FUNCTION MemFile_WriteInteger64%% (BYVAL memFile AS _UNSIGNED _OFFSET, BYVAL src AS _UNSIGNED _INTEGER64)
        FUNCTION MemFile_ReadDouble%% (BYVAL memFile AS _UNSIGNED _OFFSET, dst AS DOUBLE)
        FUNCTION MemFile_WriteDouble%% (BYVAL memFile AS _UNSIGNED _OFFSET, BYVAL src AS DOUBLE)
    END DECLARE

$END IF

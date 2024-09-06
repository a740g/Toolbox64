'-----------------------------------------------------------------------------------------------------------------------
' File I/O like routines for memory loaded files
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'MemFile.bi'

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'$DEBUG
'$CONSOLE:ONLY
'DIM sf AS _UNSIGNED _OFFSET: sf = MemFile_CreateFromString("This_is_a_test_buffer.")
'PRINT 1, MemFile_GetSize(sf), MemFile_GetPosition(sf)
'PRINT 2, MemFile_ReadString(sf, 22)
'PRINT 3, MemFile_GetPosition(sf)
'PRINT 4, MemFile_IsEOF(sf)
'PRINT 5, MemFile_GetSize(sf), MemFile_GetPosition(sf)
'MemFile_Seek sf, MemFile_GetPosition(sf) - 1
'MemFile_WriteString sf, "! Now adding some more text."
'PRINT 6, MemFile_GetPosition(sf)
'PRINT 7, MemFile_IsEOF(sf)
'PRINT 8, MemFile_GetSize(sf), MemFile_GetPosition(sf)
'MemFile_Seek sf, 0
'PRINT 9, MemFile_GetPosition(sf)
'PRINT 10, MemFile_IsEOF(sf)
'PRINT 11, MemFile_GetSize(sf), MemFile_GetPosition(sf)
'PRINT 12, MemFile_ReadString(sf, 49)
'PRINT 13, MemFile_GetPosition(sf)
'PRINT 14, MemFile_IsEOF(sf)
'PRINT 15, MemFile_GetSize(sf), MemFile_GetPosition(sf)
'MemFile_Seek sf, 0
'PRINT 16, CHR$(MemFile_ReadByte(sf))
'PRINT 17, MemFile_GetSize(sf), MemFile_GetPosition(sf)
'MemFile_WriteString sf, "XX"
'PRINT 18, MemFile_GetSize(sf), MemFile_GetPosition(sf)
'PRINT 19, CHR$(MemFile_ReadByte(sf))
'MemFile_Seek sf, 0
'PRINT 20, MemFile_ReadString(sf, 49)
'PRINT 21, MemFile_GetPosition(sf)
'PRINT 22, MemFile_IsEOF(sf)
'PRINT 23, MemFile_GetSize(sf), MemFile_GetPosition(sf)
'MemFile_Seek sf, 0
'MemFile_WriteInteger sf, 420
'MemFile_Seek sf, 0
'PRINT 24, MemFile_ReadInteger(sf)
'PRINT 25, MemFile_GetSize(sf), MemFile_GetPosition(sf)
'MemFile_Seek sf, 0
'MemFile_WriteByte sf, 255
'MemFile_Seek sf, 0
'PRINT 26, MemFile_ReadByte(sf)
'PRINT 27, MemFile_GetSize(sf), MemFile_GetPosition(sf)
'MemFile_Seek sf, 0
'MemFile_WriteLong sf, 192000
'MemFile_Seek sf, 0
'PRINT 28, MemFile_ReadLong(sf)
'PRINT 29, MemFile_GetSize(sf), MemFile_GetPosition(sf)
'MemFile_Seek sf, 0
'MemFile_WriteSingle sf, 752.334
'MemFile_Seek sf, 0
'PRINT 30, MemFile_ReadSingle(sf)
'PRINT 31, MemFile_GetSize(sf), MemFile_GetPosition(sf)
'MemFile_Seek sf, 0
'MemFile_WriteDouble sf, 23232323.242423424#
'MemFile_Seek sf, 0
'PRINT 32, MemFile_ReadDouble(sf)
'PRINT 33, MemFile_GetSize(sf), MemFile_GetPosition(sf)
'MemFile_Seek sf, 0
'MemFile_WriteInteger64 sf, 9999999999999999&&
'MemFile_Seek sf, 0
'PRINT 34, MemFile_ReadInteger64(sf)
'PRINT 35, MemFile_GetSize(sf), MemFile_GetPosition(sf)
'MemFile_Destroy sf
'END
'-----------------------------------------------------------------------------------------------------------------------

' Creates a MemFile from a string buffer
FUNCTION MemFile_CreateFromString~%& (src AS STRING)
    MemFile_CreateFromString = MemFile_Create(_OFFSET(src), LEN(src))
END FUNCTION


' Creates a MemFile from a file
FUNCTION MemFile_CreateFromFile~%& (fileName AS STRING)
    IF _FILEEXISTS(fileName) THEN
        DIM buffer AS STRING: buffer = _READFILE$(fileName)
        MemFile_CreateFromFile = MemFile_Create(_OFFSET(buffer), LEN(buffer))
    END IF
END FUNCTION


' Reads and returns a string of length size
FUNCTION MemFile_ReadString$ (memFile AS _UNSIGNED _OFFSET, size AS _UNSIGNED LONG)
    DIM dst AS STRING: dst = STRING$(size, NULL)

    DIM bytesRead AS _UNSIGNED _OFFSET: bytesRead = MemFile_Read(memFile, _OFFSET(dst), LEN(dst)) ' we'll allow partial string reads

    MemFile_ReadString = LEFT$(dst, bytesRead)
END FUNCTION


' Writes a string
SUB MemFile_WriteString (memFile AS _UNSIGNED _OFFSET, src AS STRING)
    DIM size AS _UNSIGNED LONG: size = LEN(src)

    IF MemFile_Write(memFile, _OFFSET(src), size) <> size THEN
        ERROR ERROR_ILLEGAL_FUNCTION_CALL
    END IF
END SUB


' Reads a TYPE / ARRAY
SUB MemFile_ReadType (memFile AS _UNSIGNED _OFFSET, typeOffset AS _UNSIGNED _OFFSET, typeSize AS _UNSIGNED _OFFSET)
    IF MemFile_Read(memFile, typeOffset, typeSize) <> typeSize THEN
        ERROR ERROR_ILLEGAL_FUNCTION_CALL
    END IF
END SUB


' Writes a TYPE / ARRAY
SUB MemFile_WriteType (memFile AS _UNSIGNED _OFFSET, typeOffset AS _UNSIGNED _OFFSET, typeSize AS _UNSIGNED _OFFSET)
    IF MemFile_Write(memFile, typeOffset, typeSize) <> typeSize THEN
        ERROR ERROR_ILLEGAL_FUNCTION_CALL
    END IF
END SUB


' Saves a MemFile object to a file
' This does not disturb the read / write cursor
FUNCTION MemFile_SaveToFile%% (memFile AS _UNSIGNED _OFFSET, fileName AS STRING, overwrite AS _BYTE)
    IF (NOT _FILEEXISTS(fileName) _ORELSE overwrite) _ANDALSO MemFile_GetSize(memFile) THEN
        DIM position AS _OFFSET: position = MemFile_GetPosition(memFile)
        MemFile_Seek memFile, 0
        _WRITEFILE fileName, MemFile_ReadString(memFile, MemFile_GetSize(memFile))
        MemFile_Seek memFile, position
        MemFile_SaveToFile = TRUE
    END IF
END FUNCTION

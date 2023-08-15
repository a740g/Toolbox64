'-----------------------------------------------------------------------------------------------------------------------
' File I/O like routines for memory loaded files
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF MEMFILE_BAS = UNDEFINED THEN
    $LET MEMFILE_BAS = TRUE

    '$INCLUDE:'MemFile.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    '$DEBUG
    '$CONSOLE
    'DIM g AS STRING: g = "Hello, world!"
    'DIM f AS _UNSIGNED _OFFSET: f = MemFile_CreateFromString(g)
    'DIM buf AS STRING: buf = SPACE$(MemFile_GetSize(f))
    'PRINT MemFile_ReadString(f, buf); ": "; buf
    'PRINT MemFile_WriteString(f, "Some more!")
    'PRINT MemFile_Seek(f, 0)
    'buf = SPACE$(MemFile_GetSize(f))
    'PRINT MemFile_ReadString(f, buf); ": "; buf + "EOF"
    'PRINT "EOF = "; MemFile_IsEOF(f)
    'MemFile_Destroy f
    'DIM sf AS StringFileType
    'StringFile_Create sf, "This is a test buffer."
    'PRINT LEN(sf.buffer), sf.cursor
    'PRINT StringFile_GetPosition(sf)
    'PRINT StringFile_ReadString(sf, 22)
    'PRINT StringFile_GetPosition(sf)
    'PRINT StringFile_IsEOF(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'PRINT StringFile_Seek(sf, StringFile_GetPosition(sf) - 1)
    'StringFile_WriteString sf, "! Now adding some more text."
    'PRINT StringFile_GetPosition(sf)
    'PRINT StringFile_IsEOF(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'PRINT StringFile_Seek(sf, 1)
    'PRINT StringFile_GetPosition(sf)
    'PRINT StringFile_IsEOF(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'PRINT StringFile_ReadString(sf, 60)
    'PRINT StringFile_GetPosition(sf)
    'PRINT StringFile_IsEOF(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'PRINT StringFile_Seek(sf, 1)
    'PRINT CHR$(StringFile_ReadByte(sf))
    'StringFile_WriteString sf, "XX"
    'PRINT StringFile_Seek(sf, 1)
    'PRINT StringFile_ReadString(sf, 60)
    'PRINT StringFile_GetPosition(sf)
    'PRINT StringFile_IsEOF(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'PRINT StringFile_Seek(sf, 1)
    'StringFile_WriteInteger sf, 420
    'PRINT StringFile_Seek(sf, 1)
    'PRINT StringFile_ReadInteger(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'END
    '-------------------------------------------------------------------------------------------------------------------

    ' Creates a MemFile from a string buffer
    FUNCTION MemFile_CreateFromString~%& (src AS STRING)
        MemFile_CreateFromString = MemFile_Create(_OFFSET(src), LEN(src))
    END FUNCTION


    $IF 32BIT THEN
            FUNCTION MemFile_ReadString~& (memFile AS _UNSIGNED _OFFSET, dst AS STRING)
            MemFile_ReadString = MemFile_Read(memFile, _OFFSET(dst), LEN(dst))
            END FUNCTION


            FUNCTION MemFile_WriteString~& (memFile AS _UNSIGNED _OFFSET, src AS STRING)
            MemFile_WriteString = MemFile_Write(memFile, _OFFSET(src), LEN(src))
            END FUNCTION
    $ELSE
        ' Reads a string. The string size must be set in advance using SPACE$ or similar
        ' Returns the number of bytes read
        FUNCTION MemFile_ReadString~&& (memFile AS _UNSIGNED _OFFSET, dst AS STRING)
            MemFile_ReadString = MemFile_Read(memFile, _OFFSET(dst), LEN(dst))
        END FUNCTION


        ' Writes a string
        ' Returns the number of bytes written
        FUNCTION MemFile_WriteString~&& (memFile AS _UNSIGNED _OFFSET, src AS STRING)
            MemFile_WriteString = MemFile_Write(memFile, _OFFSET(src), LEN(src))
        END FUNCTION
    $END IF


    ' Reads a TYPE
    FUNCTION MemFile_ReadType%% (memFile AS _UNSIGNED _OFFSET, typeOffset AS _UNSIGNED _OFFSET, typeSize AS _UNSIGNED _OFFSET)
        MemFile_ReadType = (MemFile_Read(memFile, typeOffset, typeSize) = typeSize)
    END FUNCTION


    ' Writes a TYPE
    FUNCTION MemFile_WriteType%% (memFile AS _UNSIGNED _OFFSET, typeOffset AS _UNSIGNED _OFFSET, typeSize AS _UNSIGNED _OFFSET)
        MemFile_WriteType = (MemFile_Write(memFile, typeOffset, typeSize) = typeSize)
    END FUNCTION


    ' Creates a new StringFile object
    ' StringFile APIs are much simpler, limited and safer than MemFile
    ' Note that unlike MemFile, StringFile is 1 based
    SUB StringFile_Create (StringFile AS StringFileType, src AS STRING)
        StringFile.buffer = src
        StringFile.cursor = 1
    END SUB


    ' Returns true if EOF is reached
    FUNCTION StringFile_IsEOF%% (StringFile AS StringFileType)
        StringFile_IsEOF = StringFile.cursor > LEN(StringFile.buffer)
    END FUNCTION


    ' Get the size of the file
    FUNCTION StringFile_GetSize& (StringFile AS StringFileType)
        StringFile_GetSize = LEN(StringFile.buffer)
    END FUNCTION


    ' Gets the current r/w cursor position
    FUNCTION StringFile_GetPosition& (StringFile AS StringFileType)
        StringFile_GetPosition = StringFile.cursor
    END FUNCTION


    ' Seeks to a position in the file
    FUNCTION StringFile_Seek%% (StringFile AS StringFileType, position AS LONG)
        IF position > 0 AND position <= LEN(StringFile.buffer) + 1 THEN ' allow seeking to EOF position
            StringFile.cursor = position
            StringFile_Seek = TRUE
        END IF
    END FUNCTION


    ' Resizes the file
    SUB StringFile_Resize (StringFile AS StringFileType, newSize AS LONG)
        DIM AS LONG curSize: curSize = LEN(StringFile.buffer)
        IF newSize > curSize THEN
            StringFile.buffer = StringFile.buffer + STRING$(newSize - curSize, NULL)
        ELSEIF newSize > 0 AND newSize < curSize THEN
            StringFile.buffer = LEFT$(StringFile.buffer, newSize)
            IF StringFile.cursor > newSize THEN StringFile.cursor = newSize + 1 ' reposition cursor to EOF position
        END IF
    END SUB


    ' Reads count bytes from the file
    FUNCTION StringFile_ReadString$ (StringFile AS StringFileType, count AS LONG)
        IF count > 0 AND StringFile.cursor <= LEN(StringFile.buffer) THEN
            DIM dst AS STRING: dst = MID$(StringFile.buffer, StringFile.cursor, count)
            StringFile.cursor = StringFile.cursor + LEN(dst) ' only increment cursor by the actual bytes read
            StringFile_ReadString = dst
        END IF
    END FUNCTION


    ' Writes a string to the file and grows the file if needed
    SUB StringFile_WriteString (StringFile AS StringFileType, src AS STRING)
        DIM srcSize AS LONG: srcSize = LEN(src)
        IF srcSize > 0 THEN
            DIM curSize AS LONG: curSize = LEN(StringFile.buffer)
            IF StringFile.cursor + srcSize - 1 > curSize THEN StringFile.buffer = StringFile.buffer + STRING$(StringFile.cursor + srcSize - 1 - curSize, NULL)
            MID$(StringFile.buffer, StringFile.cursor) = src
            StringFile.cursor = StringFile.cursor + srcSize ' this put the cursor right after the last positon written
        END IF
    END SUB


    ' Reads a byte from the file
    FUNCTION StringFile_ReadByte~% (StringFile AS StringFileType)
        DIM dst AS STRING: dst = StringFile_ReadString(StringFile, SIZE_OF_BYTE)
        IF LEN(dst) > 0 THEN StringFile_ReadByte = ASC(dst)
    END FUNCTION


    ' Write a byte to the file
    SUB StringFile_WriteByte (StringFile AS StringFileType, src AS _UNSIGNED _BYTE)
        StringFile_WriteString StringFile, CHR$(src)
    END SUB


    ' Reads an integer from the file
    FUNCTION StringFile_ReadInteger~% (StringFile AS StringFileType)
        DIM dst AS STRING: dst = StringFile_ReadString(StringFile, SIZE_OF_INTEGER)
        IF LEN(dst) > 0 THEN StringFile_ReadInteger = CVI(dst)
    END FUNCTION


    ' Writes an integer to the file
    SUB StringFile_WriteInteger (StringFile AS StringFileType, src AS _UNSIGNED INTEGER)
        StringFile_WriteString StringFile, MKI$(src)
    END SUB


    ' Reads a long from the file
    FUNCTION StringFile_ReadLong~& (StringFile AS StringFileType)
        DIM dst AS STRING: dst = StringFile_ReadString(StringFile, SIZE_OF_LONG)
        IF LEN(dst) > 0 THEN StringFile_ReadLong = CVL(dst)
    END FUNCTION


    ' Writes a long to the file
    SUB StringFile_WriteLong (StringFile AS StringFileType, src AS _UNSIGNED LONG)
        StringFile_WriteString StringFile, MKL$(src)
    END SUB


    ' Reads a single from the file
    FUNCTION StringFile_ReadSingle! (StringFile AS StringFileType)
        DIM dst AS STRING: dst = StringFile_ReadString(StringFile, SIZE_OF_SINGLE)
        IF LEN(dst) > 0 THEN StringFile_ReadSingle = CVS(dst)
    END FUNCTION


    ' Writes a single to the file
    SUB StringFile_WriteSingle (StringFile AS StringFileType, src AS SINGLE)
        StringFile_WriteString StringFile, MKS$(src)
    END SUB


    ' Reads an integer64 from the file
    FUNCTION StringFile_ReadInteger64~&& (StringFile AS StringFileType)
        DIM dst AS STRING: dst = StringFile_ReadString(StringFile, SIZE_OF_INTEGER64)
        IF LEN(dst) > 0 THEN StringFile_ReadInteger64 = _CV(_UNSIGNED _INTEGER64, dst)
    END FUNCTION


    ' Writes an integer64 to the file
    SUB StringFile_WriteInteger64 (StringFile AS StringFileType, src AS _UNSIGNED _INTEGER64)
        StringFile_WriteString StringFile, _MK$(_UNSIGNED _INTEGER64, src)
    END SUB


    ' Reads a double from the file
    FUNCTION StringFile_ReadDouble# (StringFile AS StringFileType)
        DIM dst AS STRING: dst = StringFile_ReadString(StringFile, SIZE_OF_DOUBLE)
        IF LEN(dst) > 0 THEN StringFile_ReadDouble = CVD(dst)
    END FUNCTION


    ' Writes a double to the file
    SUB StringFile_WriteDouble (StringFile AS StringFileType, src AS DOUBLE)
        StringFile_WriteString StringFile, MKD$(src)
    END SUB

$END IF

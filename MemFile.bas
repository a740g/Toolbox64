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
    'WIDTH , 80
    'DIM g AS STRING: g = "Hello, world!"
    'DIM f AS _UNSIGNED _OFFSET: f = MemFile_CreateFromString(g)
    'DIM buf AS STRING: buf = MemFile_ReadString(f, MemFile_GetSize(f))
    'PRINT buf
    'MemFile_WriteString f, "Some more!"
    'MemFile_Seek f, 0
    'buf = MemFile_ReadString(f, MemFile_GetSize(f))
    'PRINT buf + "EOF"
    'PRINT "EOF = "; MemFile_IsEOF(f)
    'MemFile_Destroy f
    'PRINT "========================"
    'DIM sf AS StringFileType
    'StringFile_Create sf, "This_is_a_test_buffer."
    'PRINT LEN(sf.buffer), sf.cursor
    'PRINT StringFile_GetPosition(sf)
    'PRINT StringFile_ReadString(sf, 22)
    'PRINT StringFile_GetPosition(sf)
    'PRINT StringFile_IsEOF(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'StringFile_Seek sf, StringFile_GetPosition(sf) - 1
    'StringFile_WriteString sf, "! Now adding some more text."
    'PRINT StringFile_GetPosition(sf)
    'PRINT StringFile_IsEOF(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'StringFile_Seek sf, 0
    'PRINT StringFile_GetPosition(sf)
    'PRINT StringFile_IsEOF(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'PRINT StringFile_ReadString(sf, 49)
    'PRINT StringFile_GetPosition(sf)
    'PRINT StringFile_IsEOF(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'StringFile_Seek sf, 0
    'PRINT CHR$(StringFile_ReadByte(sf))
    'PRINT LEN(sf.buffer), sf.cursor
    'StringFile_WriteString sf, "XX"
    'PRINT LEN(sf.buffer), sf.cursor
    'PRINT CHR$(StringFile_ReadByte(sf))
    'StringFile_Seek sf, 0
    'PRINT StringFile_ReadString(sf, 49)
    'PRINT StringFile_GetPosition(sf)
    'PRINT StringFile_IsEOF(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'StringFile_Seek sf, 0
    'StringFile_WriteInteger sf, 420
    'StringFile_Seek sf, 0
    'PRINT StringFile_ReadInteger(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'StringFile_Seek sf, 0
    'StringFile_WriteByte sf, 255
    'StringFile_Seek sf, 0
    'PRINT StringFile_ReadByte(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'StringFile_Seek sf, 0
    'StringFile_WriteLong sf, 192000
    'StringFile_Seek sf, 0
    'PRINT StringFile_ReadLong(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'StringFile_Seek sf, 0
    'StringFile_WriteSingle sf, 752.334
    'StringFile_Seek sf, 0
    'PRINT StringFile_ReadSingle(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'StringFile_Seek sf, 0
    'StringFile_WriteDouble sf, 23232323.242423424#
    'StringFile_Seek sf, 0
    'PRINT StringFile_ReadDouble(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'StringFile_Seek sf, 0
    'StringFile_WriteInteger64 sf, 9999999999999999&&
    'StringFile_Seek sf, 0
    'PRINT StringFile_ReadInteger64(sf)
    'PRINT LEN(sf.buffer), sf.cursor
    'END
    '-------------------------------------------------------------------------------------------------------------------

    ' Creates a MemFile from a string buffer
    FUNCTION MemFile_CreateFromString~%& (src AS STRING)
        MemFile_CreateFromString = MemFile_Create(_OFFSET(src), LEN(src))
    END FUNCTION


    ' Reads and returns a string of length size
    FUNCTION MemFile_ReadString$ (memFile AS _UNSIGNED _OFFSET, size AS _UNSIGNED LONG)
        DIM dst AS STRING: dst = STRING$(size, NULL)

        DIM dummy AS _UNSIGNED _OFFSET: dummy = MemFile_Read(memFile, _OFFSET(dst), LEN(dst)) ' we'll allow partial string reads

        MemFile_ReadString = dst
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


    ' Creates a new StringFile object
    ' StringFile APIs are much simpler, limited and safer than MemFile
    ' Unlike MemFile, StringFile uses a QB string as a backing buffer
    ' So, no explicit memory management (i.e. freeing) is required
    SUB StringFile_Create (StringFile AS StringFileType, src AS STRING)
        StringFile.buffer = src
        StringFile.cursor = 0
    END SUB


    ' Returns true if EOF is reached
    FUNCTION StringFile_IsEOF%% (StringFile AS StringFileType)
        StringFile_IsEOF = (StringFile.cursor >= LEN(StringFile.buffer))
    END FUNCTION


    ' Get the size of the file
    FUNCTION StringFile_GetSize~& (StringFile AS StringFileType)
        StringFile_GetSize = LEN(StringFile.buffer)
    END FUNCTION


    ' Gets the current r/w cursor position
    FUNCTION StringFile_GetPosition~& (StringFile AS StringFileType)
        StringFile_GetPosition = StringFile.cursor
    END FUNCTION


    ' Seeks to a position in the file
    SUB StringFile_Seek (StringFile AS StringFileType, position AS _UNSIGNED LONG)
        IF position <= LEN(StringFile.buffer) THEN ' allow seeking to EOF position
            StringFile.cursor = position
        ELSE
            ERROR ERROR_ILLEGAL_FUNCTION_CALL
        END IF
    END SUB


    ' Resizes the file
    SUB StringFile_Resize (StringFile AS StringFileType, newSize AS _UNSIGNED LONG)
        DIM AS _UNSIGNED LONG curSize: curSize = LEN(StringFile.buffer)

        IF newSize > curSize THEN
            StringFile.buffer = StringFile.buffer + STRING$(newSize - curSize, NULL)
        ELSEIF newSize < curSize THEN
            StringFile.buffer = LEFT$(StringFile.buffer, newSize)
            IF StringFile.cursor > newSize THEN StringFile.cursor = newSize ' reposition cursor to EOF position
        END IF
    END SUB


    ' Reads size bytes from the file
    FUNCTION StringFile_ReadString$ (StringFile AS StringFileType, size AS _UNSIGNED LONG)
        IF size > 0 THEN ' reading 0 bytes will simply do nothing
            IF StringFile.cursor < LEN(StringFile.buffer) THEN ' we'll allow partial string reads but check if we have anything to read at all
                DIM dst AS STRING: dst = MID$(StringFile.buffer, StringFile.cursor + 1, size)

                StringFile.cursor = StringFile.cursor + LEN(dst) ' increment cursor by size bytes

                StringFile_ReadString = dst
            ELSE ' not enough bytes to read
                ERROR ERROR_ILLEGAL_FUNCTION_CALL
            END IF
        END IF
    END FUNCTION


    ' Writes a string to the file and grows the file if needed
    SUB StringFile_WriteString (StringFile AS StringFileType, src AS STRING)
        DIM srcSize AS _UNSIGNED LONG: srcSize = LEN(src)

        IF srcSize > 0 THEN ' writing 0 bytes will simply do nothing
            DIM curSize AS _UNSIGNED LONG: curSize = LEN(StringFile.buffer)

            ' Grow the buffer if needed
            IF StringFile.cursor + srcSize >= curSize THEN StringFile.buffer = StringFile.buffer + STRING$(StringFile.cursor + srcSize - curSize, NULL)

            MID$(StringFile.buffer, StringFile.cursor + 1, srcSize) = src
            StringFile.cursor = StringFile.cursor + srcSize ' this put the cursor right after the last positon written
        END IF
    END SUB


    ' Reads a byte from the file
    FUNCTION StringFile_ReadByte~%% (StringFile AS StringFileType)
        IF StringFile.cursor + SIZE_OF_BYTE <= LEN(StringFile.buffer) THEN ' check if we really have the amount of bytes to read
            StringFile_ReadByte = PeekStringByte(StringFile.buffer, StringFile.cursor) ' read the data
            StringFile.cursor = StringFile.cursor + SIZE_OF_BYTE ' this puts the cursor right after the last positon read
        ELSE ' not enough bytes to read
            ERROR ERROR_ILLEGAL_FUNCTION_CALL
        END IF
    END FUNCTION


    ' Write a byte to the file
    SUB StringFile_WriteByte (StringFile AS StringFileType, src AS _UNSIGNED _BYTE)
        DIM curSize AS _UNSIGNED LONG: curSize = LEN(StringFile.buffer)

        ' Grow the buffer if needed
        IF StringFile.cursor + SIZE_OF_BYTE >= curSize THEN StringFile.buffer = StringFile.buffer + STRING$(StringFile.cursor + SIZE_OF_BYTE - curSize, NULL)

        PokeStringByte StringFile.buffer, StringFile.cursor, src ' write the data
        StringFile.cursor = StringFile.cursor + SIZE_OF_BYTE ' this puts the cursor right after the last positon written
    END SUB


    ' Reads an integer from the file
    FUNCTION StringFile_ReadInteger~% (StringFile AS StringFileType)
        IF StringFile.cursor + SIZE_OF_INTEGER <= LEN(StringFile.buffer) THEN ' check if we really have the amount of bytes to read
            StringFile_ReadInteger = CVI(MID$(StringFile.buffer, StringFile.cursor + 1, SIZE_OF_INTEGER)) ' read the data
            StringFile.cursor = StringFile.cursor + SIZE_OF_INTEGER ' this puts the cursor right after the last positon read
        ELSE ' not enough bytes to read
            ERROR ERROR_ILLEGAL_FUNCTION_CALL
        END IF
    END FUNCTION


    ' Writes an integer to the file
    SUB StringFile_WriteInteger (StringFile AS StringFileType, src AS _UNSIGNED INTEGER)
        DIM curSize AS _UNSIGNED LONG: curSize = LEN(StringFile.buffer)

        ' Grow the buffer if needed
        IF StringFile.cursor + SIZE_OF_INTEGER >= curSize THEN StringFile.buffer = StringFile.buffer + STRING$(StringFile.cursor + SIZE_OF_INTEGER - curSize, NULL)

        MID$(StringFile.buffer, StringFile.cursor + 1, SIZE_OF_INTEGER) = MKI$(src) ' write the data
        StringFile.cursor = StringFile.cursor + SIZE_OF_INTEGER ' this puts the cursor right after the last positon written
    END SUB


    ' Reads a long from the file
    FUNCTION StringFile_ReadLong~& (StringFile AS StringFileType)
        IF StringFile.cursor + SIZE_OF_LONG <= LEN(StringFile.buffer) THEN ' check if we really have the amount of bytes to read
            StringFile_ReadLong = CVL(MID$(StringFile.buffer, StringFile.cursor + 1, SIZE_OF_LONG)) ' read the data
            StringFile.cursor = StringFile.cursor + SIZE_OF_LONG ' this puts the cursor right after the last positon read
        ELSE ' not enough bytes to read
            ERROR ERROR_ILLEGAL_FUNCTION_CALL
        END IF
    END FUNCTION


    ' Writes a long to the file
    SUB StringFile_WriteLong (StringFile AS StringFileType, src AS _UNSIGNED LONG)
        DIM curSize AS _UNSIGNED LONG: curSize = LEN(StringFile.buffer)

        ' Grow the buffer if needed
        IF StringFile.cursor + SIZE_OF_LONG >= curSize THEN StringFile.buffer = StringFile.buffer + STRING$(StringFile.cursor + SIZE_OF_LONG - curSize, NULL)

        MID$(StringFile.buffer, StringFile.cursor + 1, SIZE_OF_LONG) = MKL$(src) ' write the data
        StringFile.cursor = StringFile.cursor + SIZE_OF_LONG ' this puts the cursor right after the last positon written
    END SUB


    ' Reads a single from the file
    FUNCTION StringFile_ReadSingle! (StringFile AS StringFileType)
        IF StringFile.cursor + SIZE_OF_SINGLE <= LEN(StringFile.buffer) THEN ' check if we really have the amount of bytes to read
            StringFile_ReadSingle = CVS(MID$(StringFile.buffer, StringFile.cursor + 1, SIZE_OF_SINGLE)) ' read the data
            StringFile.cursor = StringFile.cursor + SIZE_OF_SINGLE ' this puts the cursor right after the last positon read
        ELSE ' not enough bytes to read
            ERROR ERROR_ILLEGAL_FUNCTION_CALL
        END IF
    END FUNCTION


    ' Writes a single to the file
    SUB StringFile_WriteSingle (StringFile AS StringFileType, src AS SINGLE)
        DIM curSize AS _UNSIGNED LONG: curSize = LEN(StringFile.buffer)

        ' Grow the buffer if needed
        IF StringFile.cursor + SIZE_OF_SINGLE >= curSize THEN StringFile.buffer = StringFile.buffer + STRING$(StringFile.cursor + SIZE_OF_SINGLE - curSize, NULL)

        MID$(StringFile.buffer, StringFile.cursor + 1, SIZE_OF_SINGLE) = MKS$(src) ' write the data
        StringFile.cursor = StringFile.cursor + SIZE_OF_SINGLE ' this puts the cursor right after the last positon written
    END SUB


    ' Reads an integer64 from the file
    FUNCTION StringFile_ReadInteger64~&& (StringFile AS StringFileType)
        IF StringFile.cursor + SIZE_OF_INTEGER64 <= LEN(StringFile.buffer) THEN ' check if we really have the amount of bytes to read
            StringFile_ReadInteger64 = _CV(_UNSIGNED _INTEGER64, MID$(StringFile.buffer, StringFile.cursor + 1, SIZE_OF_INTEGER64)) ' read the data
            StringFile.cursor = StringFile.cursor + SIZE_OF_INTEGER64 ' this puts the cursor right after the last positon read
        ELSE ' not enough bytes to read
            ERROR ERROR_ILLEGAL_FUNCTION_CALL
        END IF
    END FUNCTION


    ' Writes an integer64 to the file
    SUB StringFile_WriteInteger64 (StringFile AS StringFileType, src AS _UNSIGNED _INTEGER64)
        DIM curSize AS _UNSIGNED LONG: curSize = LEN(StringFile.buffer)

        ' Grow the buffer if needed
        IF StringFile.cursor + SIZE_OF_INTEGER64 >= curSize THEN StringFile.buffer = StringFile.buffer + STRING$(StringFile.cursor + SIZE_OF_INTEGER64 - curSize, NULL)

        MID$(StringFile.buffer, StringFile.cursor + 1, SIZE_OF_INTEGER64) = _MK$(_UNSIGNED _INTEGER64, src) ' write the data
        StringFile.cursor = StringFile.cursor + SIZE_OF_INTEGER64 ' this puts the cursor right after the last positon written
    END SUB


    ' Reads a double from the file
    FUNCTION StringFile_ReadDouble# (StringFile AS StringFileType)
        IF StringFile.cursor + SIZE_OF_DOUBLE <= LEN(StringFile.buffer) THEN ' check if we really have the amount of bytes to read
            StringFile_ReadDouble = CVD(MID$(StringFile.buffer, StringFile.cursor + 1, SIZE_OF_DOUBLE)) ' read the data
            StringFile.cursor = StringFile.cursor + SIZE_OF_DOUBLE ' this puts the cursor right after the last positon read
        ELSE ' not enough bytes to read
            ERROR ERROR_ILLEGAL_FUNCTION_CALL
        END IF
    END FUNCTION


    ' Writes a double to the file
    SUB StringFile_WriteDouble (StringFile AS StringFileType, src AS DOUBLE)
        DIM curSize AS _UNSIGNED LONG: curSize = LEN(StringFile.buffer)

        ' Grow the buffer if needed
        IF StringFile.cursor + SIZE_OF_DOUBLE >= curSize THEN StringFile.buffer = StringFile.buffer + STRING$(StringFile.cursor + SIZE_OF_DOUBLE - curSize, NULL)

        MID$(StringFile.buffer, StringFile.cursor + 1, SIZE_OF_DOUBLE) = MKD$(src) ' write the data
        StringFile.cursor = StringFile.cursor + SIZE_OF_DOUBLE ' this puts the cursor right after the last positon written
    END SUB

$END IF

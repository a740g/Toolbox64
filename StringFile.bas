'-----------------------------------------------------------------------------------------------------------------------
' File I/O like routines for memory loaded files
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'StringFile.bi'

'-------------------------------------------------------------------------------------------------------------------
' Test code for debugging the library
'-------------------------------------------------------------------------------------------------------------------
'$DEBUG
'$CONSOLE:ONLY
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

' Creates a new StringFile object
' StringFile APIs are much simpler, limited and safer than MemFile
' Unlike MemFile, StringFile uses a QB string as a backing buffer
' So, no explicit memory management (i.e. freeing) is required
SUB StringFile_Create (stringFile AS StringFileType, src AS STRING)
    stringFile.buffer = src
    stringFile.cursor = 0
END SUB


' Returns true if EOF is reached
FUNCTION StringFile_IsEOF%% (stringFile AS StringFileType)
    StringFile_IsEOF = (stringFile.cursor >= LEN(stringFile.buffer))
END FUNCTION


' Get the size of the file
FUNCTION StringFile_GetSize~& (stringFile AS StringFileType)
    StringFile_GetSize = LEN(stringFile.buffer)
END FUNCTION


' Gets the current r/w cursor position
FUNCTION StringFile_GetPosition~& (stringFile AS StringFileType)
    StringFile_GetPosition = stringFile.cursor
END FUNCTION


' Seeks to a position in the file
SUB StringFile_Seek (stringFile AS StringFileType, position AS _UNSIGNED LONG)
    IF position <= LEN(stringFile.buffer) THEN ' allow seeking to EOF position
        stringFile.cursor = position
    ELSE
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END SUB


' Resizes the file
SUB StringFile_Resize (stringFile AS StringFileType, newSize AS _UNSIGNED LONG)
    DIM AS _UNSIGNED LONG curSize: curSize = LEN(stringFile.buffer)

    IF newSize > curSize THEN
        stringFile.buffer = stringFile.buffer + STRING$(newSize - curSize, NULL)
    ELSEIF newSize < curSize THEN
        stringFile.buffer = LEFT$(stringFile.buffer, newSize)
        IF stringFile.cursor > newSize THEN stringFile.cursor = newSize ' reposition cursor to EOF position
    END IF
END SUB


' Reads size bytes from the file
FUNCTION StringFile_ReadString$ (stringFile AS StringFileType, size AS _UNSIGNED LONG)
    IF size > 0 THEN ' reading 0 bytes will simply do nothing
        IF stringFile.cursor < LEN(stringFile.buffer) THEN ' we'll allow partial string reads but check if we have anything to read at all
            DIM dst AS STRING: dst = MID$(stringFile.buffer, stringFile.cursor + 1, size)

            stringFile.cursor = stringFile.cursor + LEN(dst) ' increment cursor by size bytes

            StringFile_ReadString = dst
        ELSE ' not enough bytes to read
            ERROR _ERR_ILLEGAL_FUNCTION_CALL
        END IF
    END IF
END FUNCTION


' Writes a string to the file and grows the file if needed
SUB StringFile_WriteString (stringFile AS StringFileType, src AS STRING)
    DIM srcSize AS _UNSIGNED LONG: srcSize = LEN(src)

    IF srcSize > 0 THEN ' writing 0 bytes will simply do nothing
        DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

        ' Grow the buffer if needed
        IF stringFile.cursor + srcSize >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + srcSize - curSize, NULL)

        MID$(stringFile.buffer, stringFile.cursor + 1, srcSize) = src
        stringFile.cursor = stringFile.cursor + srcSize ' this puts the cursor right after the last positon written
    END IF
END SUB


' Reads a byte from the file
FUNCTION StringFile_ReadByte~%% (stringFile AS StringFileType)
    IF stringFile.cursor + _SIZE_OF_BYTE <= LEN(stringFile.buffer) THEN ' check if we really have the amount of bytes to read
        StringFile_ReadByte = PeekStringByte(stringFile.buffer, stringFile.cursor) ' read the data
        stringFile.cursor = stringFile.cursor + _SIZE_OF_BYTE ' this puts the cursor right after the last positon read
    ELSE ' not enough bytes to read
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END FUNCTION


' Write a byte to the file
SUB StringFile_WriteByte (stringFile AS StringFileType, src AS _UNSIGNED _BYTE)
    DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

    ' Grow the buffer if needed
    IF stringFile.cursor + _SIZE_OF_BYTE >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + _SIZE_OF_BYTE - curSize, NULL)

    PokeStringByte stringFile.buffer, stringFile.cursor, src ' write the data
    stringFile.cursor = stringFile.cursor + _SIZE_OF_BYTE ' this puts the cursor right after the last positon written
END SUB


' Reads an integer from the file
FUNCTION StringFile_ReadInteger~% (stringFile AS StringFileType)
    IF stringFile.cursor + _SIZE_OF_INTEGER <= LEN(stringFile.buffer) THEN ' check if we really have the amount of bytes to read
        StringFile_ReadInteger = CVI(MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_INTEGER)) ' read the data
        stringFile.cursor = stringFile.cursor + _SIZE_OF_INTEGER ' this puts the cursor right after the last positon read
    ELSE ' not enough bytes to read
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END FUNCTION


' Writes an integer to the file
SUB StringFile_WriteInteger (stringFile AS StringFileType, src AS _UNSIGNED INTEGER)
    DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

    ' Grow the buffer if needed
    IF stringFile.cursor + _SIZE_OF_INTEGER >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + _SIZE_OF_INTEGER - curSize, NULL)

    MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_INTEGER) = MKI$(src) ' write the data
    stringFile.cursor = stringFile.cursor + _SIZE_OF_INTEGER ' this puts the cursor right after the last positon written
END SUB


' Reads a long from the file
FUNCTION StringFile_ReadLong~& (stringFile AS StringFileType)
    IF stringFile.cursor + _SIZE_OF_LONG <= LEN(stringFile.buffer) THEN ' check if we really have the amount of bytes to read
        StringFile_ReadLong = CVL(MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_LONG)) ' read the data
        stringFile.cursor = stringFile.cursor + _SIZE_OF_LONG ' this puts the cursor right after the last positon read
    ELSE ' not enough bytes to read
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END FUNCTION


' Writes a long to the file
SUB StringFile_WriteLong (stringFile AS StringFileType, src AS _UNSIGNED LONG)
    DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

    ' Grow the buffer if needed
    IF stringFile.cursor + _SIZE_OF_LONG >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + _SIZE_OF_LONG - curSize, NULL)

    MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_LONG) = MKL$(src) ' write the data
    stringFile.cursor = stringFile.cursor + _SIZE_OF_LONG ' this puts the cursor right after the last positon written
END SUB


' Reads a single from the file
FUNCTION StringFile_ReadSingle! (stringFile AS StringFileType)
    IF stringFile.cursor + _SIZE_OF_SINGLE <= LEN(stringFile.buffer) THEN ' check if we really have the amount of bytes to read
        StringFile_ReadSingle = CVS(MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_SINGLE)) ' read the data
        stringFile.cursor = stringFile.cursor + _SIZE_OF_SINGLE ' this puts the cursor right after the last positon read
    ELSE ' not enough bytes to read
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END FUNCTION


' Writes a single to the file
SUB StringFile_WriteSingle (stringFile AS StringFileType, src AS SINGLE)
    DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

    ' Grow the buffer if needed
    IF stringFile.cursor + _SIZE_OF_SINGLE >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + _SIZE_OF_SINGLE - curSize, NULL)

    MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_SINGLE) = MKS$(src) ' write the data
    stringFile.cursor = stringFile.cursor + _SIZE_OF_SINGLE ' this puts the cursor right after the last positon written
END SUB


' Reads an integer64 from the file
FUNCTION StringFile_ReadInteger64~&& (stringFile AS StringFileType)
    IF stringFile.cursor + _SIZE_OF_INTEGER64 <= LEN(stringFile.buffer) THEN ' check if we really have the amount of bytes to read
        StringFile_ReadInteger64 = _CV(_UNSIGNED _INTEGER64, MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_INTEGER64)) ' read the data
        stringFile.cursor = stringFile.cursor + _SIZE_OF_INTEGER64 ' this puts the cursor right after the last positon read
    ELSE ' not enough bytes to read
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END FUNCTION


' Writes an integer64 to the file
SUB StringFile_WriteInteger64 (stringFile AS StringFileType, src AS _UNSIGNED _INTEGER64)
    DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

    ' Grow the buffer if needed
    IF stringFile.cursor + _SIZE_OF_INTEGER64 >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + _SIZE_OF_INTEGER64 - curSize, NULL)

    MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_INTEGER64) = _MK$(_UNSIGNED _INTEGER64, src) ' write the data
    stringFile.cursor = stringFile.cursor + _SIZE_OF_INTEGER64 ' this puts the cursor right after the last positon written
END SUB


' Reads a double from the file
FUNCTION StringFile_ReadDouble# (stringFile AS StringFileType)
    IF stringFile.cursor + _SIZE_OF_DOUBLE <= LEN(stringFile.buffer) THEN ' check if we really have the amount of bytes to read
        StringFile_ReadDouble = CVD(MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_DOUBLE)) ' read the data
        stringFile.cursor = stringFile.cursor + _SIZE_OF_DOUBLE ' this puts the cursor right after the last positon read
    ELSE ' not enough bytes to read
        ERROR _ERR_ILLEGAL_FUNCTION_CALL
    END IF
END FUNCTION


' Writes a double to the file
SUB StringFile_WriteDouble (stringFile AS StringFileType, src AS DOUBLE)
    DIM curSize AS _UNSIGNED LONG: curSize = LEN(stringFile.buffer)

    ' Grow the buffer if needed
    IF stringFile.cursor + _SIZE_OF_DOUBLE >= curSize THEN stringFile.buffer = stringFile.buffer + STRING$(stringFile.cursor + _SIZE_OF_DOUBLE - curSize, NULL)

    MID$(stringFile.buffer, stringFile.cursor + 1, _SIZE_OF_DOUBLE) = MKD$(src) ' write the data
    stringFile.cursor = stringFile.cursor + _SIZE_OF_DOUBLE ' this puts the cursor right after the last positon written
END SUB

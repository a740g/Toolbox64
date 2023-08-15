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
    'DIM f AS _UNSIGNED _OFFSET: f = MemFile_Create(g)
    'DIM buf AS STRING: buf = SPACE$(MemFile_GetSize(f))
    'PRINT MemFile_ReadString(f, buf); ": "; buf
    'PRINT "EOF = "; MemFile_IsEOF(f)
    'MemFile_Destroy f
    'END
    '-------------------------------------------------------------------------------------------------------------------

    ' Creates a MemFile from a string buffer
    FUNCTION MemFile_Create~%& (src AS STRING)
        MemFile_Create = __MemFile_Create(src, LEN(src))
    END FUNCTION


    $IF 32BIT THEN
            FUNCTION MemFile_ReadString~& (memFile AS _UNSIGNED _OFFSET, dst AS STRING)
            MemFile_ReadString = __MemFile_Read(memFile, _OFFSET(dst), LEN(dst))
            END FUNCTION


            FUNCTION MemFile_WriteString~& (memFile AS _UNSIGNED _OFFSET, src AS STRING)
            MemFile_WriteString = __MemFile_Write(memFile, _OFFSET(src), LEN(src))
            END FUNCTION
    $ELSE
        ' Reads a string. The string size must be set in advance using SPACE$ or similar
        ' Returns the number of bytes read
        FUNCTION MemFile_ReadString~&& (memFile AS _UNSIGNED _OFFSET, dst AS STRING)
            MemFile_ReadString = __MemFile_Read(memFile, _OFFSET(dst), LEN(dst))
        END FUNCTION


        ' Writes a string
        ' Returns the number of bytes written
        FUNCTION MemFile_WriteString~&& (memFile AS _UNSIGNED _OFFSET, src AS STRING)
            MemFile_WriteString = __MemFile_Write(memFile, _OFFSET(src), LEN(src))
        END FUNCTION
    $END IF


    ' Reads a TYPE
    FUNCTION MemFile_ReadType%% (memFile AS _UNSIGNED _OFFSET, typeOffset AS _UNSIGNED _OFFSET, typeSize AS _UNSIGNED _OFFSET)
        MemFile_ReadType = (__MemFile_Read(memFile, typeOffset, typeSize) = typeSize)
    END FUNCTION


    ' Writes a TYPE
    FUNCTION MemFile_WriteType%% (memFile AS _UNSIGNED _OFFSET, typeOffset AS _UNSIGNED _OFFSET, typeSize AS _UNSIGNED _OFFSET)
        MemFile_WriteType = (__MemFile_Write(memFile, typeOffset, typeSize) = typeSize)
    END FUNCTION

$END IF

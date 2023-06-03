'-----------------------------------------------------------------------------------------------------------------------
' File I/O like routines for memory loaded files
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'MemFile.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If MEMFILE_BAS = UNDEFINED Then
    $Let MEMFILE_BAS = TRUE
    '-----------------------------------------------------------------------------------------------------
    ' Test code for debugging the library
    '-----------------------------------------------------------------------------------------------------
    '$Debug
    '$Console
    'Dim g As String: g = "Hello, world!"
    'Dim f As _Unsigned _Offset: f = MemFile_Create(g)
    'Dim buf As String: buf = Space$(MemFile_GetSize(f))
    'Print MemFile_ReadString(f, buf); ": "; buf
    'Print "EOF = "; MemFile_IsEOF(f)
    'MemFile_Destroy f
    'End
    '-----------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
    Function MemFile_Create~%& (src As String)
        MemFile_Create = __MemFile_Create(src, Len(src))
    End Function

    $If 32BIT Then
            Function MemFile_ReadString~& (memFile As _Unsigned _Offset, dst As String)
            MemFile_ReadString = __MemFile_Read(memFile, _Offset(dst), Len(dst))
            End Function

            Function MemFile_WriteString~& (memFile As _Unsigned _Offset, src As String)
            MemFile_WriteString = __MemFile_Write(memFile, _Offset(src), Len(src))
            End Function
    $Else
        ' Reads a string. The string size must be set in advance using SPACE$ or similar
        ' Returns the number of bytes read
        Function MemFile_ReadString~&& (memFile As _Unsigned _Offset, dst As String)
            MemFile_ReadString = __MemFile_Read(memFile, _Offset(dst), Len(dst))
        End Function

        ' Writes a string
        ' Returns the number of bytes written
        Function MemFile_WriteString~&& (memFile As _Unsigned _Offset, src As String)
            MemFile_WriteString = __MemFile_Write(memFile, _Offset(src), Len(src))
        End Function
    $End If

    ' Reads a TYPE
    Function MemFile_ReadType%% (memFile As _Unsigned _Offset, typeOffset As _Unsigned _Offset, typeSize As _Unsigned _Offset)
        MemFile_ReadType = (__MemFile_Read(memFile, typeOffset, typeSize) = typeSize)
    End Function

    ' Writes a TYPE
    Function MemFile_WriteType%% (memFile As _Unsigned _Offset, typeOffset As _Unsigned _Offset, typeSize As _Unsigned _Offset)
        MemFile_WriteType = (__MemFile_Write(memFile, typeOffset, typeSize) = typeSize)
    End Function
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------

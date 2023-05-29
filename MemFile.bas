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
    ' Small test code for debugging the library
    '-----------------------------------------------------------------------------------------------------
    '$Debug
    '$Console
    'Dim g As String: g = "Hello, world!"
    'Dim f As Unsigned Offset: f = MemFile_Create(g)
    'Dim buf As String: buf = Space$(MemFile_GetSize(f))
    'Print MemFile_Read(f, buf); ": "; buf
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
            Function MemFile_Read~& (memFile As _Unsigned _Offset, dst As String)
            MemFile_Read = __MemFile_Read(memFile, dst, Len(dst))
            End Function

            Function MemFile_Write~& (memFile As _Unsigned _Offset, src As String)
            MemFile_Write = __MemFile_Write(memFile, src, Len(src))
            End Function
    $Else
        Function MemFile_Read~&& (memFile As _Unsigned _Offset, dst As String)
            MemFile_Read = __MemFile_Read(memFile, dst, Len(dst))
        End Function

        Function MemFile_Write~&& (memFile As _Unsigned _Offset, src As String)
            MemFile_Write = __MemFile_Write(memFile, src, Len(src))
        End Function
    $End If
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------

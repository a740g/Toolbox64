'-----------------------------------------------------------------------------------------------------------------------
' File I/O like routines for memory loaded files
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'Common.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If MEMFILE_BI = UNDEFINED Then
    $Let MEMFILE_BI = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' EXTERNAL LIBRARIES
    '-------------------------------------------------------------------------------------------------------------------
    Declare Library "MemFile"
        Function __MemFile_Create~%& (src As String, Byval size As _Unsigned _Offset)
        Sub MemFile_Destroy (ByVal memFile As _Unsigned _Offset)
        Function MemFile_IsEOF%% (ByVal memFile As _Unsigned _Offset)
        $If 32BIT Then
            Function MemFile_GetSize~& (ByVal memFile As _Unsigned _Offset)
            Function MemFile_GetPosition~& (ByVal memFile As _Unsigned _Offset)
            Function __MemFile_Read~& (ByVal memFile As _Unsigned _Offset, Byval dst As _Unsigned _Offset, Byval size As _Unsigned _Offset)
            Function __MemFile_Write~& (ByVal memFile As _Unsigned _Offset, Byval src As _Unsigned _Offset, Byval size As _Unsigned _Offset)
        $Else
            Function MemFile_GetSize~&& (ByVal memFile As _Unsigned _Offset)
            Function MemFile_GetPosition~&& (ByVal memFile As _Unsigned _Offset)
            Function __MemFile_Read~&& (ByVal memFile As _Unsigned _Offset, Byval dst As _Unsigned _Offset, Byval size As _Unsigned _Offset)
            Function __MemFile_Write~&& (ByVal memFile As _Unsigned _Offset, Byval src As _Unsigned _Offset, Byval size As _Unsigned _Offset)
        $End If
        Function MemFile_Seek%% (ByVal memFile As _Unsigned _Offset, Byval position As _Unsigned _Offset)
        Sub MemFile_Resize (ByVal memFile As _Unsigned _Offset, Byval newSize As _Unsigned _Offset)
        Function MemFile_ReadByte%% (ByVal memFile As _Unsigned _Offset, dst As _Unsigned _Byte)
        Function MemFile_WriteByte% (ByVal memFile As _Unsigned _Offset, Byval src As _Unsigned _Byte)
        Function MemFile_ReadInteger%% (ByVal memFile As _Unsigned _Offset, dst As _Unsigned Integer)
        Function MemFile_WriteInteger%% (ByVal memFile As _Unsigned _Offset, Byval src As _Unsigned Integer)
        Function MemFile_ReadLong%% (ByVal memFile As _Unsigned _Offset, dst As _Unsigned Long)
        Function MemFile_WriteLong%% (ByVal memFile As _Unsigned _Offset, Byval src As _Unsigned Long)
        Function MemFile_ReadSingle%% (ByVal memFile As _Unsigned _Offset, dst As Single)
        Function MemFile_WriteSingle%% (ByVal memFile As _Unsigned _Offset, Byval src As Single)
        Function MemFile_ReadInteger64%% (ByVal memFile As _Unsigned _Offset, dst As _Unsigned _Integer64)
        Function MemFile_WriteInteger64%% (ByVal memFile As _Unsigned _Offset, Byval src As _Unsigned _Integer64)
        Function MemFile_ReadDouble%% (ByVal memFile As _Unsigned _Offset, dst As Double)
        Function MemFile_WriteDouble%% (ByVal memFile As _Unsigned _Offset, Byval src As Double)
    End Declare
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------

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
        Function __MemFile_Create~%& (src As String, Byval size As Unsigned Offset)
        Sub MemFile_Destroy (ByVal memFile As Unsigned Offset)
        Function MemFile_IsEOF%% (ByVal memFile As Unsigned Offset)
        $If 32BIT Then
            Function MemFile_GetSize~& (ByVal memFile As Unsigned Offset)
            Function __MemFile_Read~& (ByVal memFile As Unsigned Offset, dst As String, Byval size As Unsigned Offset)
            Function __MemFile_Write~& (ByVal memFile As Unsigned Offset, src As String, Byval size As Unsigned Offset)
        $Else
            Function MemFile_GetSize~&& (ByVal memFile As Unsigned Offset)
            Function __MemFile_Read~&& (ByVal memFile As Unsigned Offset, dst As String, Byval size As Unsigned Offset)
            Function __MemFile_Write~&& (ByVal memFile As Unsigned Offset, src As String, Byval size As Unsigned Offset)
        $End If
        Function MemFile_Seek%% (ByVal memFile As Unsigned Offset, Byval position As Unsigned Offset)
        Sub MemFile_Resize (ByVal memFile As Unsigned Offset, Byval newSize As Unsigned Offset)
        Function MemFile_ReadByte%% (ByVal memFile As Unsigned Offset, dst As Unsigned Byte)
        Function MemFile_WriteByte% (ByVal memFile As Unsigned Offset, Byval src As Unsigned Byte)
        Function MemFile_ReadInteger%% (ByVal memFile As Unsigned Offset, dst As Unsigned Integer)
        Function MemFile_WriteInteger%% (ByVal memFile As Unsigned Offset, Byval src As Unsigned Integer)
        Function MemFile_ReadLong%% (ByVal memFile As Unsigned Offset, dst As Unsigned Long)
        Function MemFile_WriteLong%% (ByVal memFile As Unsigned Offset, Byval src As Unsigned Long)
        Function MemFile_ReadSingle%% (ByVal memFile As Unsigned Offset, dst As Single)
        Function MemFile_WriteSingle%% (ByVal memFile As Unsigned Offset, Byval src As Single)
        Function MemFile_ReadInteger64%% (ByVal memFile As Unsigned Offset, dst As Unsigned Integer64)
        Function MemFile_WriteInteger64%% (ByVal memFile As Unsigned Offset, Byval src As Unsigned Integer64)
        Function MemFile_ReadDouble%% (ByVal memFile As Unsigned Offset, dst As Double)
        Function MemFile_WriteDouble%% (ByVal memFile As Unsigned Offset, Byval src As Double)
    End Declare
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------


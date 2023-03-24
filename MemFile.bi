Type MemFile
    filePathName As String
    buffer As String
    cursor As Long
    size As _Unsigned Long
End Type

declare function CreateMemFile%%(mf as MemFile, filePathName as string, size as long)
declare function LoadMemFile%%(mf as MemFile, filePathName as string)
declare function SaveMemFile%%(mf as MemFile)
declare function SeekMemFile%%(mf as MemFile, offset as long, whence as long)
declare function GetMemFilePosition&(mf as MemFile)
declare function GetMemFileSize&(mf as MemFile)
declare function ReadMemFile%%(mf as memfile, ptr as _offset, size as long)
declare function WriteMemFile%%(mf as memfile, ptr as _offset, size as long)


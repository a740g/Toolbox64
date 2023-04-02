'-----------------------------------------------------------------------------------------------------------------------
' File, path and filesystem operations
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'FileOps.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If FILEOPS_BAS = UNDEFINED Then
    $Let FILEOPS_BAS = TRUE

    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
    ' Return true if path name is an absolute path (i.e. starts from the root)
    Function IsAbsolutePath%% (pathName As String)
        $If WIN Then
            IsAbsolutePath = Asc(pathName, 1) = KEY_SLASH Or Asc(pathName, 1) = KEY_BACKSLASH Or Asc(pathName, 3) = KEY_SLASH Or Asc(pathName, 3) = KEY_BACKSLASH ' either / or \ or x:/ or x:\
        $Else
                IsAbsolutePath = Asc(pathName, 1) = KEY_SLASH ' /
        $End If
    End Function


    ' Adds a trailing / to a directory name if needed
    ' TODO: This needs to be more platform specific (i.e. \ should not be checked on non-windows platforms)
    Function FixPathDirectoryName$ (PathOrURL As String)
        If Len(PathOrURL) > 0 And (Asc(PathOrURL, Len(PathOrURL)) <> KEY_SLASH Or Asc(PathOrURL, Len(PathOrURL)) <> KEY_BACKSLASH) Then
            FixPathDirectoryName = PathOrURL + Chr$(KEY_SLASH)
        Else
            FixPathDirectoryName = PathOrURL
        End If
    End Function


    ' Gets the filename portion from a file path or URL
    ' If no part seperator is found it assumes the whole string is a filename
    Function GetFileNameFromPathOrURL$ (PathOrURL As String)
        Dim As Unsigned Long i, j: j = Len(PathOrURL)

        ' Retrieve the position of the first / or \ in the parameter from the
        For i = j To 1 Step -1
            Select Case Asc(PathOrURL, i)
                Case KEY_SLASH, KEY_BACKSLASH
                    Exit For
            End Select
        Next

        ' Return the full string if pathsep was not found
        If i = NULL Then
            GetFileNameFromPathOrURL = PathOrURL
        Else
            GetFileNameFromPathOrURL = Right$(PathOrURL, j - i)
        End If
    End Function


    ' Returns the pathname portion from a file path or URL
    ' If no path seperator is found it return an empty string
    Function GetFilePathFromPathOrURL$ (PathOrURL As String)
        Dim As Unsigned Long i, j: j = Len(PathOrURL)
        For i = j To 1 Step -1
            Select Case Asc(PathOrURL, i)
                Case KEY_SLASH, KEY_BACKSLASH
                    Exit For
            End Select
        Next

        If i <> NULL Then GetFilePathFromPathOrURL = Left$(PathOrURL, i)
    End Function


    ' Get the file extension from a path name (ex. .doc, .so etc.)
    ' Note this will return anything after a dot if the URL/path is just a directory name
    Function GetFileExtensionFromPathOrURL$ (PathOrURL As String)
        Dim fileName As String: fileName = GetFileNameFromPathOrURL(PathOrURL)
        Dim i As Unsigned Long: i = InStrRev(fileName, Chr$(KEY_DOT))

        If i <> NULL Then
            GetFileExtensionFromPathOrURL = Right$(fileName, Len(fileName) - i + 1)
        End If
    End Function


    ' Gets the drive or scheme from a path name (ex. C:, HTTPS: etc.)
    Function GetDriveOrSchemeFromPathOrURL$ (PathOrURL As String)
        Dim i As Unsigned Long: i = InStr(PathOrURL, Chr$(KEY_COLON))

        If i <> NULL Then
            GetDriveOrSchemeFromPathOrURL = Left$(PathOrURL, i)
        End If
    End Function


    ' Load a file from a file or URL
    Function LoadFile$ (PathOrURL As String)
        Select Case UCase$(GetDriveOrSchemeFromPathOrURL(PathOrURL))
            Case "HTTP:", "HTTPS:", "FTP:"
                LoadFile = LoadFileFromURL(PathOrURL)

            Case Else
                LoadFile = LoadFileFromDisk(PathOrURL)
        End Select
    End Function


    ' Loads a whole file from disk into memory
    Function LoadFileFromDisk$ (path As String)
        If FileExists(path) Then
            Dim As Long fh: fh = FreeFile

            Open path For Binary Access Read As fh

            LoadFileFromDisk = Input$(LOF(fh), fh)

            Close fh
        End If
    End Function


    ' Loads a whole file from a URL into memory
    Function LoadFileFromURL$ (url As String)
        Dim h As Long: h = OpenClient("HTTP:" + url)

        If h <> NULL Then
            Dim As String content, buffer

            While Not EOF(h)
                Limit __HTTP_UPDATES_PER_SECOND
                Get h, , buffer
                content = content + buffer
            Wend

            Close h

            LoadFileFromURL = content
        End If
    End Function


    ' Copies file src to dst. Src file must exist and dst file must not
    Function CopyFile%% (fileSrc As String, fileDst As String, overwrite As Byte)
        ' Check if source file exists
        If FileExists(fileSrc) Then
            ' Check if dest file exists
            If FileExists(fileDst) And Not overwrite Then
                Exit Function
            End If

            Dim sfh As Long: sfh = FreeFile: Open fileSrc For Binary Access Read As sfh ' open source
            Dim dfh As Long: dfh = FreeFile: Open fileDst For Binary Access Write As dfh ' open destination

            Dim buffer As String: buffer = Space$(LOF(sfh)) ' allocate buffer memory to read the file in one go

            Get sfh, , buffer ' load the whole file into memory
            Put dfh, , buffer ' write the buffer to the new file

            Close sfh, dfh ' close source and destination

            CopyFile = TRUE ' success
        End If
    End Function


    ' This is a simple text parser that can take an input string from OpenFileDialog$ and spit out discrete filepaths in an array
    ' Returns the number of strings parsed
    Function ParseOpenFileDialogList& (ofdList As String, ofdArray() As String)
        Dim As Long p, c
        Dim ts As String

        ReDim ofdArray(0 To 0) As String
        ts = ofdList

        Do
            p = InStr(ts, "|")

            If p = 0 Then
                ofdArray(c) = ts

                ParseOpenFileDialogList& = c + 1
                Exit Function
            End If

            ofdArray(c) = Left$(ts, p - 1)
            ts = Mid$(ts, p + 1)

            c = c + 1
            ReDim Preserve ofdArray(0 To c) As String
        Loop
    End Function
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------


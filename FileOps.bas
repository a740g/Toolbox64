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
    ' Small test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    '$Debug
    'Const SEARCH_URL = "https://api.modarchive.org/downloads.php?moduleid="

    'SetDownloaderProperties 0, 0

    'Dim buffer As String: buffer = LoadFileFromURL("https://modarchive.org/index.php?request=view_random")
    'Dim bufPos As Long: bufPos = InStr(buffer, SEARCH_URL)
    'If bufPos > 0 Then
    '    Print Mid$(buffer, bufPos, InStr(bufPos, buffer, Chr$(34)) - bufPos)
    'End If

    'End
    '-------------------------------------------------------------------------------------------------------------------

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
        Dim As _Unsigned Long i, j: j = Len(PathOrURL)

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
        Dim As _Unsigned Long i, j: j = Len(PathOrURL)
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
        Dim i As _Unsigned Long: i = _InStrRev(fileName, Chr$(KEY_DOT))

        If i <> NULL Then
            GetFileExtensionFromPathOrURL = Right$(fileName, Len(fileName) - i + 1)
        End If
    End Function


    ' Gets the drive or scheme from a path name (ex. C:, HTTPS: etc.)
    Function GetDriveOrSchemeFromPathOrURL$ (PathOrURL As String)
        Dim i As _Unsigned Long: i = InStr(PathOrURL, Chr$(KEY_COLON))

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
        If _FileExists(path) Then
            Dim As Long fh: fh = FreeFile

            Open path For Binary Access Read As fh

            LoadFileFromDisk = Input$(LOF(fh), fh)

            Close fh
        End If
    End Function


    ' Loads a whole file from a URL into memory
    Function LoadFileFromURL$ (url As String)
        Shared __HTTPDownloader As __HTTPDownloaderType

        ' Set default properties if this is the first time
        If Not __HTTPDownloader.initialized Then SetDownloaderProperties __HTTP_UPDATES_PER_SECOND_DEFAULT, __HTTP_TIMEOUT_DEFAULT

        Dim h As Long: h = _OpenClient("HTTP:" + url)

        If h <> NULL Then
            Dim startTick As _Unsigned _Integer64: startTick = GetTicks ' record the current tick
            Dim As String content, buffer

            While Not EOF(h)
                Get h, , buffer
                content = content + buffer
                If __HTTPDownloader.updatesPerSecond > 0 Then _Limit __HTTPDownloader.updatesPerSecond
                If __HTTPDownloader.timeoutTicks > 0 And (GetTicks - startTick) < __HTTPDownloader.timeoutTicks Then Exit While
            Wend

            Close h

            LoadFileFromURL = content
        End If
    End Function


    ' Changes the default settings for the HTTP downloader
    Sub SetDownloaderProperties (updatesPerSecond As _Unsigned Long, timeoutSeconds As _Unsigned Long)
        Shared __HTTPDownloader As __HTTPDownloaderType

        __HTTPDownloader.updatesPerSecond = updatesPerSecond
        __HTTPDownloader.timeoutTicks = 1000 * timeoutSeconds ' convert to ticks
        __HTTPDownloader.initialized = TRUE
    End Sub


    ' Copies file src to dst. Src file must exist and dst file must not
    Function CopyFile%% (fileSrc As String, fileDst As String, overwrite As _Byte)
        ' Check if source file exists
        If _FileExists(fileSrc) Then
            ' Check if dest file exists
            If _FileExists(fileDst) And Not overwrite Then
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
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------

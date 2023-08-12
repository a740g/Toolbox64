'-----------------------------------------------------------------------------------------------------------------------
' File, path and filesystem operations
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF FILEOPS_BAS = UNDEFINED THEN
    $LET FILEOPS_BAS = TRUE

    '$INCLUDE:'FileOps.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    '$DEBUG
    'CONST SEARCH_URL = "https://api.modarchive.org/downloads.php?moduleid="

    'SetDownloaderProperties 0, 0

    'DIM buffer AS STRING: buffer = LoadFileFromURL("https://modarchive.org/index.php?request=view_random")
    'DIM bufPos AS LONG: bufPos = INSTR(buffer, SEARCH_URL)
    'IF bufPos > 0 THEN
    '    PRINT MID$(buffer, bufPos, INSTR(bufPos, buffer, CHR$(34)) - bufPos)
    'END IF

    'DIM fname AS STRING: fname = "C:\Users\Samuel_Gomes\Downloads\Firmwares\image-2023-05-19-13-17-13-392.png"
    'PRINT GetFileAttributes(fname); "("; GetFileSize(fname); ")"
    'PRINT GetFileAttributes(fname) AND FILE_ATTRIBUTE_DIRECTORY
    'PRINT GetFileAttributes(fname) AND FILE_ATTRIBUTE_READOLY
    'PRINT GetFileAttributes(fname) AND FILE_ATTRIBUTE_HIDDEN
    'PRINT GetFileAttributes(fname) AND FILE_ATTRIBUTE_ARCHIVE
    'PRINT GetFileAttributes(fname) AND FILE_ATTRIBUTE_SYSTEM

    'DIM d AS STRING: d = Dir64$("C:\Users/")

    'DO WHILE d <> EMPTY_STRING
    '    PRINT d
    '    d = Dir64$(EMPTY_STRING)
    'LOOP

    'END
    '-------------------------------------------------------------------------------------------------------------------


    ' Return true if path name is an absolute path (i.e. starts from the root)
    FUNCTION IsAbsolutePath%% (pathName AS STRING)
        $IF WIN THEN
            IsAbsolutePath = ASC(pathName, 1) = KEY_SLASH OR ASC(pathName, 1) = KEY_BACKSLASH OR ASC(pathName, 3) = KEY_SLASH OR ASC(pathName, 3) = KEY_BACKSLASH ' either / or \ or x:/ or x:\
        $ELSE
                IsAbsolutePath = Asc(pathName, 1) = KEY_SLASH ' /
        $END IF
    END FUNCTION


    ' Adds a trailing / to a directory name if needed
    ' TODO: This needs to be more platform specific (i.e. \ should not be checked on non-windows platforms)
    FUNCTION FixPathDirectoryName$ (PathOrURL AS STRING)
        IF LEN(PathOrURL) > 0 AND (ASC(PathOrURL, LEN(PathOrURL)) <> KEY_SLASH OR ASC(PathOrURL, LEN(PathOrURL)) <> KEY_BACKSLASH) THEN
            FixPathDirectoryName = PathOrURL + CHR$(KEY_SLASH)
        ELSE
            FixPathDirectoryName = PathOrURL
        END IF
    END FUNCTION


    ' Gets the filename portion from a file path or URL
    ' If no part seperator is found it assumes the whole string is a filename
    FUNCTION GetFileNameFromPathOrURL$ (PathOrURL AS STRING)
        DIM AS _UNSIGNED LONG i, j: j = LEN(PathOrURL)

        ' Retrieve the position of the first / or \ in the parameter from the
        FOR i = j TO 1 STEP -1
            SELECT CASE ASC(PathOrURL, i)
                CASE KEY_SLASH, KEY_BACKSLASH
                    EXIT FOR
            END SELECT
        NEXT

        ' Return the full string if pathsep was not found
        IF i = NULL THEN
            GetFileNameFromPathOrURL = PathOrURL
        ELSE
            GetFileNameFromPathOrURL = RIGHT$(PathOrURL, j - i)
        END IF
    END FUNCTION


    ' Returns the pathname portion from a file path or URL
    ' If no path seperator is found it return an empty string
    FUNCTION GetFilePathFromPathOrURL$ (PathOrURL AS STRING)
        DIM AS _UNSIGNED LONG i, j: j = LEN(PathOrURL)
        FOR i = j TO 1 STEP -1
            SELECT CASE ASC(PathOrURL, i)
                CASE KEY_SLASH, KEY_BACKSLASH
                    EXIT FOR
            END SELECT
        NEXT

        IF i <> NULL THEN GetFilePathFromPathOrURL = LEFT$(PathOrURL, i)
    END FUNCTION


    ' Get the file extension from a path name (ex. .doc, .so etc.)
    ' Note this will return anything after a dot if the URL/path is just a directory name
    FUNCTION GetFileExtensionFromPathOrURL$ (PathOrURL AS STRING)
        DIM fileName AS STRING: fileName = GetFileNameFromPathOrURL(PathOrURL)
        DIM i AS _UNSIGNED LONG: i = _INSTRREV(fileName, CHR$(KEY_DOT))

        IF i <> NULL THEN
            GetFileExtensionFromPathOrURL = RIGHT$(fileName, LEN(fileName) - i + 1)
        END IF
    END FUNCTION


    ' Gets the drive or scheme from a path name (ex. C:, HTTPS: etc.)
    FUNCTION GetDriveOrSchemeFromPathOrURL$ (PathOrURL AS STRING)
        DIM i AS _UNSIGNED LONG: i = INSTR(PathOrURL, CHR$(KEY_COLON))

        IF i <> NULL THEN
            GetDriveOrSchemeFromPathOrURL = LEFT$(PathOrURL, i)
        END IF
    END FUNCTION


    ' Generates a filename without illegal filesystem characters
    FUNCTION GetLegalFileName$ (fileName AS STRING)
        DIM s AS STRING, c AS _UNSIGNED _BYTE

        ' Clean any unwanted characters
        DIM i AS LONG: FOR i = 1 TO LEN(fileName)
            c = ASC(fileName, i)
            SELECT CASE c
                CASE KEY_SLASH, KEY_BACKSLASH, KEY_ASTERISK, KEY_QUESTION_MARK, KEY_VERTICAL_LINE
                    s = s + "_"
                CASE KEY_COLON
                    s = s + "-"
                CASE KEY_LESS_THAN
                    s = s + "{"
                CASE KEY_GREATER_THAN
                    s = s + "}"
                CASE KEY_QUOTATION_MARK
                    s = s + "'"
                CASE ELSE
                    s = s + CHR$(c)
            END SELECT
        NEXT

        GetLegalFileName = s
    END FUNCTION


    ' Load a file from a file or URL
    FUNCTION LoadFile$ (PathOrURL AS STRING)
        SELECT CASE UCASE$(GetDriveOrSchemeFromPathOrURL(PathOrURL))
            CASE "HTTP:", "HTTPS:", "FTP:"
                LoadFile = LoadFileFromURL(PathOrURL)

            CASE ELSE
                LoadFile = LoadFileFromDisk(PathOrURL)
        END SELECT
    END FUNCTION


    ' Loads a whole file from disk into memory
    FUNCTION LoadFileFromDisk$ (path AS STRING)
        IF _FILEEXISTS(path) THEN
            DIM AS LONG fh: fh = FREEFILE

            OPEN path FOR BINARY ACCESS READ AS fh

            LoadFileFromDisk = INPUT$(LOF(fh), fh)

            CLOSE fh
        END IF
    END FUNCTION


    ' Loads a whole file from a URL into memory
    FUNCTION LoadFileFromURL$ (url AS STRING)
        SHARED __FileOps AS __FileOpsType

        ' Set default properties if this is the first time
        IF NOT __FileOps.initialized THEN SetDownloaderProperties __FILEOPS_UPDATES_PER_SECOND_DEFAULT, __FILEOPS_TIMEOUT_DEFAULT

        __FileOps.percentCompleted = 0

        DIM h AS LONG: h = _OPENCLIENT("HTTP:" + url)

        IF h <> NULL THEN
            DIM startTick AS _UNSIGNED _INTEGER64: startTick = GetTicks ' record the current tick
            DIM AS STRING content, buffer

            WHILE NOT EOF(h)
                GET h, , buffer
                content = content + buffer
                IF __FileOps.updatesPerSecond > 0 THEN _LIMIT __FileOps.updatesPerSecond
                IF __FileOps.timeoutTicks > 0 AND (GetTicks - startTick) > __FileOps.timeoutTicks THEN EXIT WHILE
                __FileOps.percentCompleted = (LEN(content) / LOF(h)) * 100!
            WEND

            CLOSE h

            LoadFileFromURL = content
        END IF
    END FUNCTION


    ' Changes the default settings for the HTTP downloader
    SUB SetDownloaderProperties (updatesPerSecond AS _UNSIGNED LONG, timeoutSeconds AS _UNSIGNED LONG)
        SHARED __FileOps AS __FileOpsType

        __FileOps.updatesPerSecond = updatesPerSecond
        __FileOps.timeoutTicks = 1000 * timeoutSeconds ' convert to ticks
        __FileOps.initialized = TRUE
    END SUB


    ' Save a buffer to a file
    FUNCTION SaveFile%% (buffer AS STRING, fileName AS STRING, overwrite AS _BYTE)
        IF _FILEEXISTS(fileName) AND NOT overwrite THEN EXIT FUNCTION

        DIM fh AS LONG: fh = FREEFILE
        OPEN fileName FOR OUTPUT AS fh ' open file in text mode to wipe out the file if it exists
        PRINT #fh, buffer; ' write the buffer to the file (works regardless of the file being opened in text mode)
        CLOSE fh

        SaveFile = TRUE
    END FUNCTION


    ' Copies file src to dst. Src file must exist and dst file must not
    FUNCTION CopyFile%% (fileSrc AS STRING, fileDst AS STRING, overwrite AS _BYTE)
        ' Check if source file exists
        IF _FILEEXISTS(fileSrc) THEN
            ' Check if dest file exists
            IF _FILEEXISTS(fileDst) AND NOT overwrite THEN EXIT FUNCTION

            DIM sfh AS LONG: sfh = FREEFILE
            OPEN fileSrc FOR BINARY ACCESS READ AS sfh ' open source
            DIM buffer AS STRING: buffer = INPUT$(LOF(sfh), sfh) ' allocate buffer memory and read the file in one go
            CLOSE sfh ' close source

            DIM dfh AS LONG: dfh = FREEFILE
            OPEN fileDst FOR OUTPUT AS dfh ' open destination in text mode to wipe out the file
            PRINT #dfh, buffer; ' write the buffer to the file (works regardless of the file being opened in text mode)
            CLOSE dfh ' close destination

            CopyFile = TRUE ' success
        END IF
    END FUNCTION


    ' Returns the size of a file
    FUNCTION GetFileSize&& (pathName AS STRING)
        GetFileSize = __GetFileSize(ToCString(pathName))
    END FUNCTION


    ' Returns the attributes of a file / directory
    ' See FILE_ATTRIBUTE_* CONSTs
    FUNCTION GetFileAttributes~& (pathName AS STRING)
        GetFileAttributes = __GetFileAttributes(ToCString(pathName))
    END FUNCTION

    ' This kinda emulates MS BASIC PDS DIR$ (well almost)
    ' First call should include the filespec and subsequent calls should pass
    ' an empty string until the function returns an empty string
    FUNCTION Dir64$ (fileSpec AS STRING)
        Dir64$ = __Dir64$(ToCString(fileSpec))
    END FUNCTION


    '$INCLUDE:'StringOps.bas'
    '$INCLUDE:'TimeOps.bas'

$END IF

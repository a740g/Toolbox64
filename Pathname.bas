'-----------------------------------------------------------------------------------------------------------------------
' Pathname utility library
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Pathname.bi'

'-----------------------------------------------------------------------------------------------------------------------
' Test code for debugging the library
'-----------------------------------------------------------------------------------------------------------------------
'_DEFINE A-Z AS LONG
'OPTION _EXPLICIT

'PRINT Pathname_IsAbsolute("C:/Windows")
'PRINT Pathname_IsAbsolute("/Windows")
'PRINT Pathname_IsAbsolute("Windows")
'PRINT Pathname_IsAbsolute("")

'PRINT Pathname_FixDirectoryName("Windows")
'PRINT Pathname_FixDirectoryName("Windows/")
'PRINT Pathname_FixDirectoryName("")

'PRINT Pathname_FixDirectorySeparators("C:/Windows\")
'PRINT Pathname_FixDirectorySeparators("Windows")
'PRINT Pathname_FixDirectorySeparators("")

'PRINT Pathname_GetFileName("C:\foo/bar.ext")
'PRINT Pathname_GetFileName("bar.ext")
'PRINT Pathname_GetFileName("")

'PRINT Pathname_GetPath("C:\foo/bar.ext")
'PRINT Pathname_GetPath("\bar.ext")
'PRINT Pathname_GetPath("")

'PRINT Pathname_HasFileExtension("C:\foo/bar.ext")
'PRINT Pathname_HasFileExtension("bar.ext/")
'PRINT Pathname_HasFileExtension("")

'PRINT Pathname_GetFileExtension("C:\foo/bar.ext")
'PRINT Pathname_GetFileExtension("bar.ext/")
'PRINT Pathname_GetFileExtension("")

'PRINT Pathname_RemoveFileExtension("C:\foo/bar.ext")
'PRINT Pathname_RemoveFileExtension("bar.ext/")
'PRINT Pathname_RemoveFileExtension("")

'PRINT Pathname_GetDriveOrScheme("https://www.github.com/")
'PRINT Pathname_GetDriveOrScheme("C:\Windows\")
'PRINT Pathname_GetDriveOrScheme("")

'PRINT Pathname_MakeLegalFileName("<abracadabra.txt/>")
'PRINT Pathname_MakeLegalFileName("")

'END
'-----------------------------------------------------------------------------------------------------------------------

' Return true if path name is an absolute path (i.e. starts from the root)
FUNCTION Pathname_IsAbsolute%% (pathName AS STRING)
    $IF WINDOWS THEN
        ' Either \ or / or x:\ or x:/
        IF LEN(pathName) > 2 THEN
            Pathname_IsAbsolute = (ASC(pathName, 1) = PATHNAME_DIR_SEPARATOR_CODE_WIN OR ASC(pathName, 1) = PATHNAME_DIR_SEPARATOR_CODE_NIX OR ASC(pathName, 3) = PATHNAME_DIR_SEPARATOR_CODE_WIN OR ASC(pathName, 3) = PATHNAME_DIR_SEPARATOR_CODE_NIX)
        ELSEIF LEN(pathName) > 0 THEN
            Pathname_IsAbsolute = (ASC(pathName, 1) = PATHNAME_DIR_SEPARATOR_CODE_WIN OR ASC(pathName, 1) = PATHNAME_DIR_SEPARATOR_CODE_NIX)
        END IF
    $ELSE
        ' /
        IF LEN(pathName) > 0 THEN
            Pathname_IsAbsolute = (ASC(pathName, 1) = PATHNAME_DIR_SEPARATOR_CODE)
        END IF
    $END IF
END FUNCTION


' Adds a trailing directory separator to a directory name if needed
FUNCTION Pathname_FixDirectoryName$ (pathName AS STRING)
    $IF WINDOWS THEN
        IF LEN(pathName) > 0 THEN
            IF ASC(pathName, LEN(pathName)) <> PATHNAME_DIR_SEPARATOR_CODE_WIN AND ASC(pathName, LEN(pathName)) <> PATHNAME_DIR_SEPARATOR_CODE_NIX THEN
                Pathname_FixDirectoryName = pathName + PATHNAME_DIR_SEPARATOR
                EXIT FUNCTION
            END IF
        END IF
    $ELSE
        IF LEN(pathName) > 0 THEN
            IF ASC(pathName, LEN(pathName)) <> PATHNAME_DIR_SEPARATOR_CODE THEN
                Pathname_FixDirectoryName = pathName + PATHNAME_DIR_SEPARATOR
                EXIT FUNCTION
            END IF
        END IF
    $END IF

    Pathname_FixDirectoryName = pathName
END FUNCTION


' Fixes the provided filename and path to use the correct path separator
FUNCTION Pathname_FixDirectorySeparators$ (pathName AS STRING)
    DIM i AS _UNSIGNED LONG, buffer AS STRING: buffer = pathName

    $IF WINDOWS THEN
        FOR i = 1 TO LEN(buffer)
            IF ASC(buffer, i) = PATHNAME_DIR_SEPARATOR_CODE_NIX THEN ASC(buffer, i) = PATHNAME_DIR_SEPARATOR_CODE_WIN
        NEXT
    $ELSE
        FOR i = 1 TO LEN(buffer)
            IF ASC(buffer, i) = PATHNAME_DIR_SEPARATOR_CODE_WIN THEN ASC(buffer, i) = PATHNAME_DIR_SEPARATOR_CODE_NIX
        NEXT
    $END IF

    Pathname_FixDirectorySeparators = buffer
END FUNCTION


' Gets the filename portion from a file path or URL
' If no part seperator is found it assumes the whole string is a filename
FUNCTION Pathname_GetFileName$ (pathOrURL AS STRING)
    DIM AS _UNSIGNED LONG i, j: j = LEN(pathOrURL)

    $IF WINDOWS THEN
        ' Retrieve the position of the first / or \ in the parameter from the
        FOR i = j TO 1 STEP -1
            SELECT CASE ASC(pathOrURL, i)
                CASE PATHNAME_DIR_SEPARATOR_CODE_WIN, PATHNAME_DIR_SEPARATOR_CODE_NIX
                    EXIT FOR
            END SELECT
        NEXT
    $ELSE
        i = _INSTRREV(pathOrURL, PATHNAME_DIR_SEPARATOR)
    $END IF

    ' Return the full string if pathsep was not found
    IF i = 0 THEN
        Pathname_GetFileName = pathOrURL
    ELSE
        Pathname_GetFileName = RIGHT$(pathOrURL, j - i)
    END IF
END FUNCTION


' Returns the pathname portion from a file path or URL
' If no path seperator is found it return an empty string
FUNCTION Pathname_GetPath$ (pathOrURL AS STRING)
    DIM i AS _UNSIGNED LONG

    $IF WINDOWS THEN
        FOR i = LEN(pathOrURL) TO 1 STEP -1
            SELECT CASE ASC(pathOrURL, i)
                CASE PATHNAME_DIR_SEPARATOR_CODE_WIN, PATHNAME_DIR_SEPARATOR_CODE_NIX
                    EXIT FOR
            END SELECT
        NEXT
    $ELSE
        i = _INSTRREV(pathOrURL, PATHNAME_DIR_SEPARATOR)
    $END IF

    IF i <> 0 THEN Pathname_GetPath = LEFT$(pathOrURL, i)
END FUNCTION


' Returns True if pathOrURL has a file extension
FUNCTION Pathname_HasFileExtension%% (pathOrURL AS STRING)
    DIM i AS _UNSIGNED LONG
    FOR i = LEN(pathOrURL) TO 1 STEP -1
        $IF WINDOWS THEN
            SELECT CASE ASC(pathOrURL, i)
                CASE PATHNAME_DIR_SEPARATOR_CODE_WIN, PATHNAME_DIR_SEPARATOR_CODE_NIX
                    EXIT FOR

                CASE PATHNAME_EXT_SEPARATOR_CODE
                    Pathname_HasFileExtension = __PATHNAME_TRUE
                    EXIT FOR
            END SELECT
        $ELSE
            SELECT CASE ASC(pathOrURL, i)
                CASE PATHNAME_DIR_SEPARATOR_CODE
                    EXIT FOR

                CASE PATHNAME_EXT_SEPARATOR_CODE
                    Pathname_HasFileExtension = __PATHNAME_TRUE
                    EXIT FOR
            END SELECT
        $END IF
    NEXT
END FUNCTION


' Get the file extension from a path name (ex. .doc, .so etc.)
' Note this will return anything after a dot if the URL/path is just a directory name
FUNCTION Pathname_GetFileExtension$ (pathOrURL AS STRING)
    DIM i AS _UNSIGNED LONG
    FOR i = LEN(pathOrURL) TO 1 STEP -1
        $IF WINDOWS THEN
            SELECT CASE ASC(pathOrURL, i)
                CASE PATHNAME_DIR_SEPARATOR_CODE_WIN, PATHNAME_DIR_SEPARATOR_CODE_NIX
                    EXIT FOR

                CASE PATHNAME_EXT_SEPARATOR_CODE
                    Pathname_GetFileExtension = RIGHT$(pathOrURL, LEN(pathOrURL) - i + 1)
                    EXIT FOR
            END SELECT
        $ELSE
            SELECT CASE ASC(pathOrURL, i)
                CASE PATHNAME_DIR_SEPARATOR_CODE
                    EXIT FOR

                CASE PATHNAME_EXT_SEPARATOR_CODE
                    Pathname_GetFileExtension = RIGHT$(pathOrURL, LEN(pathOrURL) - i + 1)
                    EXIT FOR
            END SELECT
        $END IF
    NEXT
END FUNCTION


' Returns pathOrURL without extension
FUNCTION Pathname_RemoveFileExtension$ (pathOrURL AS STRING)
    DIM i AS _UNSIGNED LONG
    FOR i = LEN(pathOrURL) TO 1 STEP -1
        $IF WINDOWS THEN
            SELECT CASE ASC(pathOrURL, i)
                CASE PATHNAME_DIR_SEPARATOR_CODE_WIN, PATHNAME_DIR_SEPARATOR_CODE_NIX
                    EXIT FOR

                CASE PATHNAME_EXT_SEPARATOR_CODE
                    Pathname_RemoveFileExtension = LEFT$(pathOrURL, i - 1)
                    EXIT FUNCTION
            END SELECT
        $ELSE
            SELECT CASE ASC(pathOrURL, i)
                CASE PATHNAME_DIR_SEPARATOR_CODE
                    EXIT FOR

                CASE PATHNAME_EXT_SEPARATOR_CODE
                    Pathname_RemoveFileExtension = LEFT$(pathOrURL, i - 1)
                    EXIT FUNCTION
            END SELECT
        $END IF
    NEXT

    Pathname_RemoveFileExtension = pathOrURL
END FUNCTION


' Gets the drive or scheme from a path name (ex. C:, HTTPS: etc.)
FUNCTION Pathname_GetDriveOrScheme$ (pathOrURL AS STRING)
    DIM i AS _UNSIGNED LONG: i = INSTR(pathOrURL, PATHNAME_SCHEME_TERMINATOR)

    IF i <> 0 THEN Pathname_GetDriveOrScheme = LEFT$(pathOrURL, i)
END FUNCTION


' Generates a filename without illegal filesystem characters
' Actually this is a lot more strict on *nix to ensure Windows & *nix interop.
FUNCTION Pathname_MakeLegalFileName$ (fileName AS STRING)
    DIM s AS STRING, c AS _UNSIGNED _BYTE

    ' Clean any unwanted characters
    DIM i AS _UNSIGNED LONG
    FOR i = 1 TO LEN(fileName)
        c = ASC(fileName, i)
        SELECT CASE c
            CASE IS < 32, PATHNAME_DIR_SEPARATOR_CODE_WIN, PATHNAME_DIR_SEPARATOR_CODE_NIX, PATHNAME_SCHEME_TERMINATOR_CODE, 34, 42, 60, 62, 63, 124
                s = s + "_"
            CASE ELSE
                s = s + CHR$(c)
        END SELECT
    NEXT

    Pathname_MakeLegalFileName = s
END FUNCTION

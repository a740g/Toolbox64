'-----------------------------------------------------------------------------------------------------------------------
' File, path and filesystem routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF FILEOPS_BI = UNDEFINED THEN
    $LET FILEOPS_BI = TRUE

    '$INCLUDE:'Common.bi'
    '$INCLUDE:'Types.bi'
    '$INCLUDE:'StringOps.bi'
    '$INCLUDE:'TimeOps.bi'

    $UNSTABLE:HTTP

    CONST __FILEOPS_UPDATES_PER_SECOND_DEFAULT = 120 ' refresh happens 120 times a second
    CONST __FILEOPS_TIMEOUT_DEFAULT = 60 * 5 ' timeout happens after 5 mins by default

    ' These must be kept in sync with FileOps.h
    CONST FILE_ATTRIBUTE_DIRECTORY = 1
    CONST FILE_ATTRIBUTE_READOLY = 2
    CONST FILE_ATTRIBUTE_HIDDEN = 4
    CONST FILE_ATTRIBUTE_ARCHIVE = 8
    CONST FILE_ATTRIBUTE_SYSTEM = 16

    ' This keeps track of the settings used by LoadFileFromURL()
    TYPE __FileOpsType
        initialized AS _BYTE
        updatesPerSecond AS _UNSIGNED LONG
        timeoutTicks AS _UNSIGNED _INTEGER64
        percentCompleted AS _UNSIGNED _BYTE
    END TYPE

    DECLARE LIBRARY "FileOps"
        FUNCTION __GetFileAttributes~& (pathName AS STRING)
        FUNCTION __GetFileSize&& (pathName AS STRING)
        FUNCTION __Dir64$ (fileSpec AS STRING)
    END DECLARE

    DIM __FileOps AS __FileOpsType

$END IF

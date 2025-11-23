'-----------------------------------------------------------------------------------------------------------------------
' File management routines
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Core/Common.bi'
'$INCLUDE:'../Core/Types.bi'
'$INCLUDE:'../String/StringOps.bi'
'$INCLUDE:'../FS/Pathname.bi'
'$INCLUDE:'../Core/TimeOps.bi'

CONST __FILE_UPDATES_PER_SECOND_DEFAULT = 120 ' refresh happens 120 times a second
CONST __FILE_TIMEOUT_DEFAULT = 60 * 5 ' timeout happens after 5 mins by default

' These must be kept in sync with FileOps.h
CONST FILE_ATTRIBUTE_DIRECTORY = &H10~&
CONST FILE_ATTRIBUTE_REGULAR_FILE = &H20~&
CONST FILE_ATTRIBUTE_READONLY = &H01~&
CONST FILE_ATTRIBUTE_HIDDEN = &H02~&
CONST FILE_ATTRIBUTE_SYSTEM = &H04~&
CONST FILE_ATTRIBUTE_ARCHIVE = &H08~&

' This keeps track of the settings used by LoadFileFromURL()
TYPE __FileType
    initialized AS _BYTE
    updatesPerSecond AS _UNSIGNED LONG
    timeoutTicks AS _UNSIGNED _INTEGER64
    percentCompleted AS _UNSIGNED _BYTE
END TYPE

DECLARE LIBRARY "File"
    FUNCTION __File_GetAttributes~& (pathName AS STRING)
    FUNCTION __File_GetSize&& (pathName AS STRING)
    FUNCTION __File_GetModifiedTime&& (pathName AS STRING)
END DECLARE

DIM __File AS __FileType

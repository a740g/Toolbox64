'-----------------------------------------------------------------------------------------------------------------------
' QB64-PE SAUCE Library
' Copyright (c) 2024 Samuel Gomes
'
' See https://github.com/radman1/sauce
'-----------------------------------------------------------------------------------------------------------------------

$IF SAUCE_BAS = UNDEFINED THEN
    $LET SAUCE_BAS = TRUE

    '$INCLUDE:'SAUCE.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' TEST CODE
    '-------------------------------------------------------------------------------------------------------------------
    'DIM buffer AS STRING: buffer = LoadFile("C:\Users\samue\source\repos\a740g\ANSI-Print-64\demos\aa-fldontcare.ans")

    'PRINT SAUCE_IsPresent(buffer)

    'DIM sauce AS SAUCEType: SAUCE_Read buffer, sauce

    'PRINT SAUCE_GetAuthor(sauce)
    'PRINT SAUCE_GetDataType(sauce)
    'PRINT SAUCE_GetFileType(sauce)
    'PRINT HEX$(SAUCE_GetTypeFlags(sauce))

    'END

    'FUNCTION LoadFile$ (path AS STRING)
    '    IF _FILEEXISTS(path) THEN
    '        DIM AS LONG fh: fh = FREEFILE
    '        OPEN path FOR BINARY ACCESS READ AS fh
    '        LoadFile = INPUT$(LOF(fh), fh)
    '        CLOSE fh
    '    END IF
    'END FUNCTION
    '-------------------------------------------------------------------------------------------------------------------

    ' Returns the position of the SAUCE record in a string buffer
    FUNCTION __SAUCE_GetRecordPosition~& (buffer AS STRING)
        IF LEN(buffer) >= __SAUCE_RECORD_SIZE THEN
            DIM position AS _UNSIGNED LONG: position = 1 + LEN(buffer) - __SAUCE_RECORD_SIZE

            IF __SAUCE_ID = MID$(buffer, position, LEN(__SAUCE_ID)) THEN
                __SAUCE_GetRecordPosition = position
            END IF
        END IF
    END FUNCTION


    ' Returns the position of the SAUCE comment block in a string buffer
    ' The SAUCE record should be read pior to calling this function!
    FUNCTION __SAUCE_GetCommentBlockPosition~& (buffer AS STRING, sauceRecord AS __SAUCERecordType)
        DIM commentBlockSize AS _UNSIGNED LONG: commentBlockSize = LEN(__SAUCE_COMMENT_ID) + sauceRecord.commentLines * __SAUCE_COMMENT_SIZE
        DIM totalRecordSize AS _UNSIGNED LONG: totalRecordSize = commentBlockSize + LEN(sauceRecord)

        IF LEN(buffer) >= totalRecordSize THEN
            DIM position AS _UNSIGNED LONG: position = 1 + LEN(buffer) - totalRecordSize

            IF __SAUCE_COMMENT_ID = MID$(buffer, position, LEN(__SAUCE_COMMENT_ID)) THEN
                __SAUCE_GetCommentBlockPosition = position
            END IF
        END IF
    END FUNCTION


    ' Detects the presence of a SAUCE record in a memory loaded file
    FUNCTION SAUCE_IsPresent%% (buffer AS STRING)
        SAUCE_IsPresent = __SAUCE_GetRecordPosition(buffer) > 0
    END FUNCTION


    ' Removes a SAUCE record from a memory loaded file if it is present
    SUB SAUCE_Remove (buffer AS STRING)
        IF __SAUCE_GetRecordPosition(buffer) > 0 THEN
            DIM sauce AS SAUCEType: SAUCE_Read buffer, sauce

            ' The total size of the SAUCE record is sizeof(EOF byte) + sizeof(comment block) + sizeof(SAUCE record)
            DIM bytesToRemove AS _UNSIGNED LONG: bytesToRemove = SIZE_OF_BYTE + LEN(sauce.record)

            ' Add the comments block if we have one
            IF LEN(sauce.comments) > 0 THEN bytesToRemove = bytesToRemove + LEN(__SAUCE_COMMENT_ID) + LEN(sauce.comments)

            IF LEN(buffer) >= bytesToRemove THEN
                buffer = LEFT$(buffer, LEN(buffer) - bytesToRemove)
            END IF
        END IF
    END SUB


    ' Initializes a sauce record (everything is cleared to defaults)
    SUB SAUCE_Initialize (sauce AS SAUCEType)
        ' Zero the underlying SAUCE record
        SetMemoryByte _OFFSET(sauce.record), NULL, LEN(sauce.record)

        ' Zap the comments
        sauce.comments = EMPTY_STRING

        ' Set the SAUCE ID
        sauce.record.id = __SAUCE_ID

        ' Set the current date
        DIM systemDate AS STRING: systemDate = DATE$
        sauce.record.date = RIGHT$(systemDate, 4) + LEFT$(systemDate, 2) + MID$(systemDate, 4, 2)
    END SUB


    ' Reads the SAUCE record from a memory loaded file
    ' Is there is none, it will simply initialize the SAUCE record
    SUB SAUCE_Read (buffer AS STRING, sauce AS SAUCEType)
        DIM position AS _UNSIGNED LONG: position = __SAUCE_GetRecordPosition(buffer)

        IF position > 0 THEN
            ' Read in the SAUCE record first
            CopyMemory _OFFSET(sauce.record), _OFFSET(buffer) + position - 1, LEN(sauce.record)

            ' Get the position a comment block
            position = __SAUCE_GetCommentBlockPosition(buffer, sauce.record)

            IF position > 0 THEN
                sauce.comments = MID$(buffer, position + LEN(__SAUCE_COMMENT_ID), sauce.record.commentLines * __SAUCE_COMMENT_SIZE) ' read comments
            ELSE
                sauce.comments = EMPTY_STRING ' no comments
            END IF

        ELSE
            SAUCE_Initialize sauce
        END IF
    END SUB


    ' Writes (attaches) the SAUCE record to a memory loaded file
    ' If the SAUCE record is not initialized then it is automatically initialized
    ' The size field in the record is automatically adjusted
    SUB SAUCE_Write (sauce AS SAUCEType, buffer AS STRING)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        ' Remove any existing record
        SAUCE_Remove buffer

        ' Update the file size
        sauce.record.fileSize = LEN(buffer)

        ' Add the EOF marker
        buffer = buffer + CHR$(__SAUCE_EOF_CHARACTER)

        ' Add the comment block if needed
        IF LEN(sauce.comments) > 0 THEN
            buffer = buffer + __SAUCE_COMMENT_ID + sauce.comments
        END IF

        ' Now add the SAUCE record
        buffer = buffer + SPACE$(LEN(sauce.record))
        CopyMemory _OFFSET(buffer) + LEN(buffer) - LEN(sauce.record), _OFFSET(sauce.record), LEN(sauce.record)
    END SUB


    ' Returns the SAUCE record version
    FUNCTION SAUCE_GetVersion~% (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetVersion = sauce.record.version
    END FUNCTION


    ' Gets the SAUCE file title
    FUNCTION SAUCE_GetTitle$ (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetTitle = sauce.record.caption
    END FUNCTION


    ' Sets the SAUCE file title
    SUB SAUCE_SetTitle (sauce AS SAUCEType, caption AS STRING)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        sauce.record.caption = caption
    END SUB


    ' Gets the SAUCE file author
    FUNCTION SAUCE_GetAuthor$ (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetAuthor = sauce.record.author
    END FUNCTION


    ' Sets the SAUCE file author
    SUB SAUCE_SetAuthor (sauce AS SAUCEType, author AS STRING)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        sauce.record.author = author
    END SUB


    ' Gets the SAUCE file group
    FUNCTION SAUCE_GetGroup$ (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetGroup = sauce.record.group
    END FUNCTION


    ' Sets the SAUCE file group
    SUB SAUCE_SetGroup (sauce AS SAUCEType, group AS STRING)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        sauce.record.group = group
    END SUB


    ' Gets the SAUCE file date in CCYYMMDD format
    FUNCTION SAUCE_GetDate$ (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetDate = sauce.record.date
    END FUNCTION


    ' Sets the SAUCE file date in CCYYMMDD format
    SUB SAUCE_SetDate (sauce AS SAUCEType, dateString AS STRING)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        ' Do some validation
        IF IsDigit(ASC(dateString, 1)) THEN
            IF IsDigit(ASC(dateString, 2)) THEN
                IF IsDigit(ASC(dateString, 3)) THEN
                    IF IsDigit(ASC(dateString, 4)) THEN
                        IF IsDigit(ASC(dateString, 5)) THEN
                            IF IsDigit(ASC(dateString, 6)) THEN
                                IF IsDigit(ASC(dateString, 7)) THEN
                                    IF IsDigit(ASC(dateString, 8)) THEN
                                        sauce.record.date = dateString
                                        EXIT SUB
                                    END IF
                                END IF
                            END IF
                        END IF
                    END IF
                END IF
            END IF
        END IF

        ERROR ERROR_ILLEGAL_FUNCTION_CALL
    END SUB


    ' Returns the original file size not including the SAUCE information
    FUNCTION SAUCE_GetFileSize~& (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetFileSize = sauce.record.fileSize
    END FUNCTION


    ' Gets the SAUCE data type
    FUNCTION SAUCE_GetDataType~& (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetDataType = sauce.record.dataType
    END FUNCTION


    ' Sets the SAUCE data type
    SUB SAUCE_SetDataType (sauce AS SAUCEType, dataType AS _UNSIGNED LONG)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        ' Do some validation
        IF dataType < __SAUCE_DATATYPE_COUNT THEN
            sauce.record.dataType = dataType
        ELSE
            ERROR ERROR_ILLEGAL_FUNCTION_CALL
        END IF
    END SUB


    ' Gets the SAUCE file type
    FUNCTION SAUCE_GetFileType~& (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetFileType = sauce.record.fileType
    END FUNCTION


    ' Sets the SAUCE file type
    SUB SAUCE_SetFileType (sauce AS SAUCEType, fileType AS _UNSIGNED LONG)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        sauce.record.fileType = fileType
    END SUB


    ' Gets the SAUCE Info1 field
    FUNCTION SAUCE_GetTypeInfoLong1~& (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetTypeInfoLong1 = sauce.record.tInfo1
    END FUNCTION


    ' Sets the SAUCE Info1 field
    SUB SAUCE_SetTypeInfoLong1 (sauce AS SAUCEType, typeInfo AS _UNSIGNED LONG)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        sauce.record.tInfo1 = typeInfo
    END SUB


    ' Gets the SAUCE Info2 field
    FUNCTION SAUCE_GetTypeInfoLong2~& (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetTypeInfoLong2 = sauce.record.tInfo2
    END FUNCTION


    ' Sets the SAUCE Info2 field
    SUB SAUCE_SetTypeInfoLong2 (sauce AS SAUCEType, typeInfo AS _UNSIGNED LONG)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        sauce.record.tInfo2 = typeInfo
    END SUB


    ' Gets the SAUCE Info3 field
    FUNCTION SAUCE_GetTypeInfoLong3~& (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetTypeInfoLong3 = sauce.record.tInfo3
    END FUNCTION


    ' Sets the SAUCE Info3 field
    SUB SAUCE_SetTypeInfoLong3 (sauce AS SAUCEType, typeInfo AS _UNSIGNED LONG)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        sauce.record.tInfo3 = typeInfo
    END SUB


    ' Gets the SAUCE Info4 field
    FUNCTION SAUCE_GetTypeInfoLong4~& (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetTypeInfoLong4 = sauce.record.tInfo4
    END FUNCTION


    ' Sets the SAUCE Info4 field
    SUB SAUCE_SetTypeInfoLong4 (sauce AS SAUCEType, typeInfo AS _UNSIGNED LONG)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        sauce.record.tInfo4 = typeInfo
    END SUB


    ' Gets the number of SAUCE comment lines
    FUNCTION SAUCE_GetCommentLines~%% (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetCommentLines = sauce.record.commentLines
    END FUNCTION


    ' Gets the SAUCE type flags
    FUNCTION SAUCE_GetTypeFlags~& (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetTypeFlags = sauce.record.tFlags
    END FUNCTION


    ' Sets the SAUCE type flags
    SUB SAUCE_SetTypeFlags (sauce AS SAUCEType, typeFlags AS _UNSIGNED LONG)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        sauce.record.tFlags = typeFlags
    END SUB


    ' Gets the SAUCE type info string
    FUNCTION SAUCE_GetTypeInfoString$ (sauce AS SAUCEType)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        SAUCE_GetTypeInfoString = ToBString(sauce.record.tInfoS)
    END FUNCTION


    ' Sets the SAUCE type info string
    SUB SAUCE_SetTypeInfoString (sauce AS SAUCEType, typeInfo AS STRING)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        sauce.record.tInfoS = LEFT$(typeInfo, LEN(sauce.record.tInfoS) - 1) + CHR$(NULL)
    END SUB


    ' Gets a SAUCE comment line
    ' commentLine can (1 - 255)
    FUNCTION SAUCE_GetComment$ (sauce AS SAUCEType, commentLine AS _UNSIGNED _BYTE)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        IF sauce.record.commentLines > 0 THEN
            SAUCE_GetComment = MID$(sauce.comments, 1 + (commentLine - 1) * __SAUCE_COMMENT_SIZE, __SAUCE_COMMENT_SIZE)
        ELSE
            ERROR ERROR_ILLEGAL_FUNCTION_CALL
        END IF
    END FUNCTION


    ' Sets a SAUCE comment line
    ' commentLine can (1 - 255)
    SUB SAUCE_SetComment (sauce AS SAUCEType, commentLine AS _UNSIGNED _BYTE, comment AS STRING)
        ' Initialze the sauce record if needed
        IF sauce.record.id <> __SAUCE_ID THEN SAUCE_Initialize sauce

        ' Calculate the total comment size based on commentLine
        DIM totalSize AS _UNSIGNED LONG: totalSize = commentLine * __SAUCE_COMMENT_SIZE

        ' Grow the comments buffer if it is less than the total size
        IF totalSize > LEN(sauce.comments) THEN
            sauce.comments = sauce.comments + SPACE$(totalSize - LEN(sauce.comments))
            sauce.record.commentLines = commentLine ' update the number of lines
        END IF

        ' Now insert the comment line
        MID$(sauce.comments, 1 + (commentLine - 1) * __SAUCE_COMMENT_SIZE, __SAUCE_COMMENT_SIZE) = LEFT$(comment, __SAUCE_COMMENT_SIZE)
    END SUB

    '$INCLUDE:'StringOps.bas'

$END IF

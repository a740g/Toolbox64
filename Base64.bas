'-----------------------------------------------------------------------------------------------------------------------
' Base64 Encoder and Decoder library
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF BASE64_BAS = UNDEFINED THEN
    $LET BASE64_BAS = TRUE

    '$INCLUDE:'Base64.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    'DIM a AS STRING: a = "The quick brown fox jumps over the lazy dog."

    'PrintStringDetails a

    'DIM b AS STRING: b = EncodeBase64(a)

    'PrintStringDetails b

    'a = DecodeBase64(b)

    'PrintStringDetails a

    'END

    'SUB PrintStringDetails (s AS STRING)
    '    PRINT "Sting: "; s
    '    PRINT "String size:"; LEN(s)
    'END SUB
    '-------------------------------------------------------------------------------------------------------------------

    ' Convert a normal string to a base64 string
    FUNCTION Base64_Encode$ (s AS STRING)
        DIM AS _UNSIGNED _OFFSET outputPtr, outputSize

        outputPtr = __MODP_B64_Encode(s, LEN(s), outputSize)

        IF outputPtr <> NULL THEN
            IF outputSize > 0 THEN
                DIM outputBuffer AS STRING: outputBuffer = STRING$(outputSize, NULL)
                CopyMemory _OFFSET(outputBuffer), outputPtr, outputSize
            END IF

            FreeMemory outputPtr

            Base64_Encode = outputBuffer
        END IF
    END FUNCTION


    ' Convert a base64 string to a normal string
    FUNCTION Base64_Decode$ (s AS STRING)
        DIM AS _UNSIGNED _OFFSET outputPtr, outputSize

        outputPtr = __MODP_B64_Decode(s, LEN(s), outputSize)

        IF outputPtr <> NULL THEN
            IF outputSize > 0 THEN
                DIM outputBuffer AS STRING: outputBuffer = STRING$(outputSize, NULL)
                CopyMemory _OFFSET(outputBuffer), outputPtr, outputSize
            END IF

            FreeMemory outputPtr

            Base64_Decode = outputBuffer
        END IF
    END FUNCTION


    ' Loads a binary file encoded with Bin2Data
    ' Usage:
    '   1. Encode the binary file with Bin2Data
    '   2. Include the file or it's contents
    '   3. Load the file like so:
    '       Restore label_generated_by_bin2data
    '       Dim buffer As String
    '       buffer = Base64_LoadResource ' buffer will now hold the contents of the file
    FUNCTION Base64_LoadResource$
        DIM AS _UNSIGNED LONG ogSize, resSize
        DIM AS _BYTE isCompressed

        READ ogSize, resSize, isCompressed ' read the header

        DIM AS STRING buffer, result

        ' Read the whole resource data
        DO WHILE LEN(result) < resSize
            READ buffer
            result = result + buffer
        LOOP

        ' Decode the data
        buffer = Base64_Decode(result)

        ' Expand the data if needed
        IF isCompressed THEN
            result = _INFLATE$(buffer, ogSize)
        ELSE
            result = buffer
        END IF

        Base64_LoadResource = result
    END FUNCTION

$END IF

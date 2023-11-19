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
    'CONST ITERATIONS = 1000000
    'CONST LOREM_IPSUM = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut " + _
    '    "labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip " + _
    '    "ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat " + _
    '    "nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

    'DIM encTxt AS STRING, decTxt AS STRING, i AS LONG, t AS DOUBLE

    'PRINT ITERATIONS; "iterations,"; LEN(LOREM_IPSUM); "bytes."

    'PRINT "Base64 encode..."

    't = TIMER
    'FOR i = 1 TO ITERATIONS
    '    encTxt = Base64_Encode(LOREM_IPSUM)
    'NEXT
    'PRINT USING "#####.##### seconds"; TIMER - t

    'PRINT "Base64 decode..."

    't = TIMER
    'FOR i = 1 TO ITERATIONS
    '    decTxt = Base64_Decode(encTxt)
    'NEXT
    'PRINT USING "#####.##### seconds"; TIMER - t

    'IF _STRCMP(decTxt, LOREM_IPSUM) = 0 THEN
    '    PRINT "Passed"
    'ELSE
    '    PRINT "Failed"
    'END IF

    'END
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


    ' This function loads a resource directly from a string variable or constant (like the ones made by Bin2Data)
    FUNCTION Base64_LoadResourceString$ (src AS STRING, ogSize AS _UNSIGNED LONG, isComp AS _BYTE)
        ' Decode the data
        DIM buffer AS STRING: buffer = Base64_Decode(src)

        ' Expand the data if needed
        IF isComp THEN buffer = _INFLATE$(buffer, ogSize)

        Base64_LoadResourceString = buffer
    END FUNCTION


    ' Loads a binary file encoded with Bin2Data
    ' Usage:
    '   1. Encode the binary file with Bin2Data
    '   2. Include the file or it's contents
    '   3. Load the file like so:
    '       Restore label_generated_by_bin2data
    '       Dim buffer As String
    '       buffer = Base64_LoadResourceData   ' buffer will now hold the contents of the file
    FUNCTION Base64_LoadResourceData$
        DIM ogSize AS _UNSIGNED LONG, resize AS _UNSIGNED LONG, isComp AS _BYTE
        READ ogSize, resize, isComp ' read the header

        DIM buffer AS STRING: buffer = SPACE$(resize) ' preallocate complete buffer

        ' Read the whole resource data
        DIM i AS _UNSIGNED LONG: DO WHILE i < resize
            DIM chunk AS STRING: READ chunk
            MID$(buffer, i + 1) = chunk
            i = i + LEN(chunk)
        LOOP

        ' Decode the data
        buffer = Base64_Decode(buffer)

        ' Expand the data if needed
        IF isComp THEN buffer = _INFLATE$(buffer, ogSize)

        Base64_LoadResourceData = buffer
    END FUNCTION

$END IF

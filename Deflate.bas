'-----------------------------------------------------------------------------------------------------------------------
' _INFLATE$ compatible high-efficiency compression library for QB64-PE
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF DEFLATE_BAS = UNDEFINED THEN
    $LET DEFLATE_BAS = TRUE

    '$INCLUDE:'Deflate.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    'DIM a AS STRING: a = "The quick brown fox jumps over the lazy dog. "
    'PRINT "Original string (a): "; a
    'DIM i AS LONG: FOR i = 1 TO 15
    '    a = a + a
    'NEXT

    'PRINT "After concatenating it into itself several times, LEN(a) ="; LEN(a)

    'DIM b AS STRING: b = DeflatePro(a, 1)
    'PRINT "After using _DEFLATE$ to compress it, LEN(b) ="; LEN(b)
    'PRINT USING "(compressed size is #.###% of the original)"; ((LEN(b) * 100) / LEN(a))
    'DIM c AS STRING: c = _INFLATE$(b, LEN(a))
    'PRINT "After using _INFLATE$ to decompress it, LEN(c) ="; LEN(c)
    'SLEEP
    'PRINT c

    'END
    '-------------------------------------------------------------------------------------------------------------------

    ' This uses Zopfli to compress the buffer using the Deflat method
    ' The buffer can then be decompressed using QB64's INFLATE$ command
    ' compressionLevel can be 0 - 255. 255 is the highest compression level and 0 used the library default setting
    FUNCTION DeflatePro$ (inputBuffer AS STRING, compressionLevel AS _UNSIGNED _BYTE)
        DIM AS _UNSIGNED _OFFSET outputPtr, outputSize

        ' Call the internal compression routine
        __Zopfli_Compress compressionLevel, inputBuffer, LEN(inputBuffer), outputPtr, outputSize

        IF outputPtr <> NULL THEN ' only if the compression succeeded
            ' Copy the compressed memory
            IF outputSize > 0 THEN
                ' Allocate memory to copy the compressed buffer
                DIM outputBuffer AS STRING: outputBuffer = STRING$(outputSize, NULL)
                CopyMemory _OFFSET(outputBuffer), outputPtr, outputSize
            END IF

            ' Free outputPtr
            FreeMemory outputPtr

            DeflatePro = outputBuffer
        END IF
    END FUNCTION

$END IF

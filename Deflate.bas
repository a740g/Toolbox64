'-----------------------------------------------------------------------------------------------------------------------
' _INFLATE$ compatible high-efficiency compression library for QB64-PE
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF DEFLATE_BAS = UNDEFINED THEN
    $LET DEFLATE_BAS = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' HEADER FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'Deflate.bi'
    '-------------------------------------------------------------------------------------------------------------------

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

    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
    FUNCTION DeflatePro$ (inputBuffer AS STRING, compressionLevel AS _UNSIGNED _BYTE)
        DIM AS _UNSIGNED _OFFSET outputPtr, outputSize

        ' Call the internal compression routine
        __Zopfli_Compress compressionLevel, inputBuffer, LEN(inputBuffer), outputPtr, outputSize

        IF outputPtr <> NULL THEN ' only if the compression succeeded
            ' Allocate memory to copy the compressed buffer
            DIM outputBuffer AS STRING: outputBuffer = STRING$(outputSize, NULL)

            ' Copy the compressed memory
            IF outputSize > 0 THEN CopyMemory _OFFSET(outputBuffer), outputPtr, outputSize

            ' Free outputPtr
            FreeMemory outputPtr

            DeflatePro$ = outputBuffer
        END IF
    END FUNCTION
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' MODULE FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'PointerOps.bas'
    '-------------------------------------------------------------------------------------------------------------------
$END IF
'-----------------------------------------------------------------------------------------------------------------------

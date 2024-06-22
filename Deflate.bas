'-----------------------------------------------------------------------------------------------------------------------
' _INFLATE$ compatible high-efficiency compression library for QB64-PE
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Deflate.bi'

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'$CONSOLE:ONLY
'DIM a AS STRING: a = "The quick brown fox jumps over the lazy dog. "
'PRINT "Original string (a): "; a
'DIM i AS LONG: FOR i = 1 TO 15
'    a = a + a
'NEXT

'PRINT "After concatenating it into itself several times, LEN(a) ="; LEN(a)

'DIM AS DOUBLE t: t = TIMER(.001)
'PRINT "_INFLATE + _DEFLATE:"
'DIM b AS STRING: b = _DEFLATE$(a)
'PRINT "After using _DEFLATE with default compression level to compress it, LEN(b) ="; LEN(b)
'PRINT USING "(compressed size is #.###% of the original)"; ((LEN(b) * 100) / LEN(a))
'DIM c AS STRING: c = _INFLATE$(b, LEN(a))
'PRINT "After using _INFLATE to decompress it, LEN(c) ="; LEN(c)
'IF a = c THEN PRINT "Passed!" ELSE PRINT "Failed!"
'PRINT USING "Time taken: ########.####"; TIMER(.001) - t
'PRINT

't = TIMER(.001)
'PRINT "DeflateZopfli + _DEFLATE:"
'b = DeflatePro(a, 0)
'PRINT "After using DeflateZopfli with default compression level to compress it, LEN(b) ="; LEN(b)
'PRINT USING "(compressed size is #.###% of the original)"; ((LEN(b) * 100) / LEN(a))
'c = _INFLATE$(b, LEN(a))
'PRINT "After using _INFLATE$ to decompress it, LEN(c) ="; LEN(c)
'IF a = c THEN PRINT "Passed!" ELSE PRINT "Failed!"
'PRINT USING "Time taken: ########.####"; TIMER(.001) - t
'PRINT

'END
'-----------------------------------------------------------------------------------------------------------------------

' This uses Zopfli to compress the buffer using the Deflate method
' The buffer can then be decompressed using QB64's INFLATE$ command
' compressionLevel can be 0 - 65535. 65535 is the highest compression level and 0 uses the library default setting
FUNCTION DeflatePro$ (inputBuffer AS STRING, compressionLevel AS _UNSIGNED INTEGER)
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

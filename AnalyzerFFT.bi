'-----------------------------------------------------------------------------------------------------------------------
' FFT routines for spectrum analyzers
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'

DECLARE LIBRARY "AnalyzerFFT"
    FUNCTION AnalyzerFFTInteger! (ana AS _UNSIGNED INTEGER, samp AS INTEGER, BYVAL inc AS LONG, BYVAL bits AS LONG)
    FUNCTION AnalyzerFFTSingle! (ana AS _UNSIGNED INTEGER, samp AS SINGLE, BYVAL inc AS LONG, BYVAL bits AS LONG)
END DECLARE

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'$DEBUG
'DIM buffer(0 TO 1023) AS INTEGER
'DIM outp(0 TO 1023) AS INTEGER

'RANDOMIZE TIMER

'DIM i AS LONG
'FOR i = 0 TO 1023
'    buffer(i) = RND * 65536 - 32768
'NEXT i

'PRINT AnalyzerFFTInteger(outp(0), buffer(0), 1, 10)

'END
'-----------------------------------------------------------------------------------------------------------------------

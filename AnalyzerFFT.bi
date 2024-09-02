'-----------------------------------------------------------------------------------------------------------------------
' FFT routines for audio spectrum analyzers
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'

DECLARE LIBRARY "AnalyzerFFT"
    FUNCTION AudioAnalyzerFFT_DoInteger! (amplitudeArray AS _UNSIGNED INTEGER, sampleDataArray AS INTEGER, BYVAL sampleIncrement AS LONG, BYVAL bitDepth AS LONG)
    FUNCTION AudioAnalyzerFFT_DoSingle! (amplitudeArray AS _UNSIGNED INTEGER, sampleDataArray AS SINGLE, BYVAL sampleIncrement AS LONG, BYVAL bitDepth AS LONG)
END DECLARE

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'$DEBUG
'DIM buffer(0 TO 1023) AS INTEGER
'DIM outp(0 TO 1023) AS INTEGER

'RANDOMIZE TIMER

'DO
'    DIM i AS LONG
'    FOR i = 0 TO 1023
'        buffer(i) = RND * 65536 - 32768
'    NEXT i

'    PRINT USING "#####.#####"; AudioAnalyzerFFT_DoInteger(outp(0), buffer(0), 1, 10)
'LOOP UNTIL _KEYHIT = 27

'END
'-----------------------------------------------------------------------------------------------------------------------

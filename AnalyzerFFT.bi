'-----------------------------------------------------------------------------------------------------------------------
' FFT routines for spectrum analyzers
' Copyright (c) 2024 Samuel Gomes
'
' Adapted from OpenCP Module Player (https://github.com/mywave82/opencubicplayer)
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'

DECLARE LIBRARY "AnalyzerFFT"
    FUNCTION AnalyzerFFTInteger! (ana AS _UNSIGNED INTEGER, samp AS INTEGER, BYVAL inc AS LONG, BYVAL bits AS LONG)
    FUNCTION AnalyzerFFTSingle! (ana AS _UNSIGNED INTEGER, samp AS SINGLE, BYVAL inc AS LONG, BYVAL bits AS LONG)
END DECLARE

'-----------------------------------------------------------------------------------------------------------------------
' Simple audio conversion and resampling library
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'
'$INCLUDE:'Types.bi'

DECLARE LIBRARY "AudioConv"
    SUB __AudioConv_ConvertU8ToS8 (buffer AS STRING, BYVAL samples AS _UNSIGNED LONG)
    SUB __AudioConv_ConvertU16ToS16 (buffer AS STRING, BYVAL samples AS _UNSIGNED LONG)
    SUB __AudioConv_ConvertS8ToF32 (src AS STRING, BYVAL samples AS _UNSIGNED LONG, dst AS STRING)
    SUB __AudioConv_ConvertS8ToS16 (src AS STRING, BYVAL samples AS _UNSIGNED LONG, dst AS STRING)
    SUB __AudioConv_ConvertS16ToF32 (src AS STRING, BYVAL samples AS _UNSIGNED LONG, dst AS STRING)
    SUB __AudioConv_ConvertALawToS16 (src AS STRING, BYVAL samples AS _UNSIGNED LONG, dst AS STRING)
    SUB __AudioConv_ConvertALawToF32 (src AS STRING, BYVAL samples AS _UNSIGNED LONG, dst AS STRING)
    SUB __AudioConv_ConvertMuLawToS16 (src AS STRING, BYVAL samples AS _UNSIGNED LONG, dst AS STRING)
    SUB __AudioConv_ConvertMuLawToF32 (src AS STRING, BYVAL samples AS _UNSIGNED LONG, dst AS STRING)
    SUB __AudioConv_ConvertADPCM4ToU8 (src AS STRING, BYVAL srcLen AS _UNSIGNED LONG, compTab AS STRING, dst AS STRING)
    FUNCTION AudioConv_ResampleS16~&& (BYVAL src AS _UNSIGNED _OFFSET, BYVAL dst AS _UNSIGNED _OFFSET, BYVAL inSampleRate AS LONG, BYVAL outSampleRate AS LONG, BYVAL inputSize AS _UNSIGNED _INTEGER64, BYVAL channels AS _UNSIGNED LONG)
    FUNCTION AudioConv_ResampleF32~&& (BYVAL src AS _UNSIGNED _OFFSET, BYVAL dst AS _UNSIGNED _OFFSET, BYVAL inSampleRate AS LONG, BYVAL outSampleRate AS LONG, BYVAL inputSize AS _UNSIGNED _INTEGER64, BYVAL channels AS _UNSIGNED LONG)
    FUNCTION AudioConv_ResampleAndConvertS8ToF32~&& (BYVAL src AS _UNSIGNED _OFFSET, BYVAL dst AS _UNSIGNED _OFFSET, BYVAL inSampleRate AS LONG, BYVAL outSampleRate AS LONG, BYVAL inputSampleFrames AS _UNSIGNED _INTEGER64, BYVAL channels AS _UNSIGNED LONG)
    FUNCTION AudioConv_ResampleAndConvertS16ToF32~&& (BYVAL src AS _UNSIGNED _OFFSET, BYVAL dst AS _UNSIGNED _OFFSET, BYVAL inSampleRate AS LONG, BYVAL outSampleRate AS LONG, BYVAL inputSampleFrames AS _UNSIGNED _INTEGER64, BYVAL channels AS _UNSIGNED LONG)
END DECLARE

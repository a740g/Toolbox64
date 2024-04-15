'-----------------------------------------------------------------------------------------------------------------------
' Simple audio conversion and resampling library
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'AudioConv.bi'

' Converts 8-bit unsigned sound data to 8-bit signed data (in-place).
SUB AudioConv_ConvertU8ToS8 (buffer AS STRING)
    __AudioConv_ConvertU8ToS8 buffer, LEN(buffer)
END SUB


' Converts 16-bit unsigned sound data to 16-bit signed data (in-place).
SUB AudioConv_ConvertU16ToS16 (buffer AS STRING)
    __AudioConv_ConvertU16ToS16 buffer, LEN(buffer) \ SIZE_OF_INTEGER
END SUB


' Converts signed 8-bit audio samples to floating point.
FUNCTION AudioConv_ConvertS8ToF32$ (buffer AS STRING)
    DIM outBuffer AS STRING: outBuffer = STRING$(LEN(buffer) * SIZE_OF_SINGLE, NULL)

    __AudioConv_ConvertS8ToF32 buffer, LEN(buffer), outBuffer

    AudioConv_ConvertS8ToF32 = outBuffer
END FUNCTION


' Converts signed 8-bit audio samples to signed 16-bit.
FUNCTION AudioConv_ConvertS8ToS16$ (buffer AS STRING)
    DIM outBuffer AS STRING: outBuffer = STRING$(LEN(buffer) * SIZE_OF_INTEGER, NULL)

    __AudioConv_ConvertS8ToS16 buffer, LEN(buffer), outBuffer

    AudioConv_ConvertS8ToS16 = outBuffer
END FUNCTION


' Converts signed 16-bit audio samples to floating point.
FUNCTION AudioConv_ConvertS16ToF32$ (buffer AS STRING)
    DIM outBuffer AS STRING: outBuffer = STRING$(LEN(buffer) * (SIZE_OF_SINGLE \ SIZE_OF_INTEGER), NULL)

    __AudioConv_ConvertS16ToF32 buffer, LEN(buffer) \ SIZE_OF_INTEGER, outBuffer

    AudioConv_ConvertS16ToF32 = outBuffer
END FUNCTION


' Converts A-Law encoded audio samples to signed 16-bit samples.
FUNCTION AudioConv_ConvertALawToS16$ (buffer AS STRING)
    DIM outBuffer AS STRING: outBuffer = STRING$(LEN(buffer) * SIZE_OF_INTEGER, NULL)

    __AudioConv_ConvertALawToS16 buffer, LEN(buffer), outBuffer

    AudioConv_ConvertALawToS16 = outBuffer
END FUNCTION


' Converts A-Law encoded audio samples to floating point samples.
FUNCTION AudioConv_ConvertALawToF32$ (buffer AS STRING)
    DIM outBuffer AS STRING: outBuffer = STRING$(LEN(buffer) * SIZE_OF_SINGLE, NULL)

    __AudioConv_ConvertALawToF32 buffer, LEN(buffer), outBuffer

    AudioConv_ConvertALawToF32 = outBuffer
END FUNCTION


' Converts mu-Law encoded audio samples to signed 16-bit samples.
FUNCTION AudioConv_ConvertMuLawToS16$ (buffer AS STRING)
    DIM outBuffer AS STRING: outBuffer = STRING$(LEN(buffer) * SIZE_OF_INTEGER, NULL)

    __AudioConv_ConvertMuLawToS16 buffer, LEN(buffer), outBuffer

    AudioConv_ConvertMuLawToS16 = outBuffer
END FUNCTION


' Converts mu-Law encoded audio samples to floating point samples.
FUNCTION AudioConv_ConvertMuLawToF32$ (buffer AS STRING)
    DIM outBuffer AS STRING: outBuffer = STRING$(LEN(buffer) * SIZE_OF_SINGLE, NULL)

    __AudioConv_ConvertMuLawToF32 buffer, LEN(buffer), outBuffer

    AudioConv_ConvertMuLawToF32 = outBuffer
END FUNCTION


' Converts 4-bit ADPCM compressed audio samples to 8-bit signed samples.
FUNCTION AudioConv_ConvertADPCM4ToS8$ (buffer AS STRING, compTab AS STRING)
    DIM outBuffer AS STRING: outBuffer = STRING$(LEN(buffer) * 2~&, NULL)

    __AudioConv_ConvertADPCM4ToS8 buffer, LEN(buffer), compTab, outBuffer

    AudioConv_ConvertADPCM4ToS8 = outBuffer
END FUNCTION


' Converts a dual mono audio buffer to a stereo interleaved audio buffer (8-bit signed; inplace).
FUNCTION AudioConv_ConvertDualMonoToStereoS8$ (buffer AS STRING)
    DIM outBuffer AS STRING: outBuffer = STRING$(LEN(buffer), NULL)

    __AudioConv_ConvertDualMonoToStereoS8 buffer, LEN(buffer), outBuffer

    AudioConv_ConvertDualMonoToStereoS8 = outBuffer
END FUNCTION


' Converts a dual mono audio buffer to a stereo interleaved audio buffer (16-bit signed; inplace).
FUNCTION AudioConv_ConvertDualMonoToStereoS16$ (buffer AS STRING)
    DIM outBuffer AS STRING: outBuffer = STRING$(LEN(buffer), NULL)

    __AudioConv_ConvertDualMonoToStereoS16 buffer, LEN(buffer) \ SIZE_OF_INTEGER, outBuffer

    AudioConv_ConvertDualMonoToStereoS16 = outBuffer
END FUNCTION


' Converts a dual mono audio buffer to a stereo interleaved audio buffer (floating point; inplace).
FUNCTION AudioConv_ConvertDualMonoToStereoF32$ (buffer AS STRING)
    DIM outBuffer AS STRING: outBuffer = STRING$(LEN(buffer), NULL)

    __AudioConv_ConvertDualMonoToStereoF32 buffer, LEN(buffer) \ SIZE_OF_SINGLE, outBuffer

    AudioConv_ConvertDualMonoToStereoF32 = outBuffer
END FUNCTION

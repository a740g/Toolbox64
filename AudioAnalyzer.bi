'-----------------------------------------------------------------------------------------------------------------------
' A simple audio analyzer library
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'
'$INCLUDE:'Types.bi'
'$INCLUDE:'PointerOps.bi'
'$INCLUDE:'BitwiseOps.bi'
'$INCLUDE:'Math/Math.bi'
'$INCLUDE:'Math/Vector2D.bi'
'$INCLUDE:'StringOps.bi'
'$INCLUDE:'GraphicOps.bi'
'$INCLUDE:'AudioAnalyzerFFT.bi'
'$INCLUDE:'AudioConv.bi'

CONST __AUDIOANALYZER_FORMAT_UNKNOWN~%% = 0~%%
CONST __AUDIOANALYZER_FORMAT_U8~%% = 1~%%
CONST __AUDIOANALYZER_FORMAT_S16~%% = 2~%%
CONST __AUDIOANALYZER_FORMAT_S32~%% = 3~%%
CONST __AUDIOANALYZER_FORMAT_F32~%% = 4~%%
CONST __AUDIOANALYZER_CLIP_BUFFER_TIME! = 0.05!
CONST __AUDIOANALYZER_FFT_SCALE_X~%% = 1~%%
CONST __AUDIOANALYZER_FFT_SCALE_Y~%% = 6~%%
CONST __AUDIOANALYZER_VU_PEAK_FALL_SPEED! = 0.001!
CONST __AUDIOANALYZER_STAR_COUNT~& = 256~&
CONST __AUDIOANALYZER_STAR_Z_DIVIDER! = 4096!
CONST __AUDIOANALYZER_STAR_SPEED_MUL! = 64!
CONST __AUDIOANALYZER_STAR_ANGLE_INC! = 0.001!
CONST __AUDIOANALYZER_CIRCLE_WAVE_COUNT~& = 16~&
CONST __AUDIOANALYZER_CIRCLE_WAVE_RADIUS_MUL! = 4!
CONST __AUDIOANALYZER_TEXT_COLOR~& = BGRA_WHITE
CONST AUDIOANALYZER_STYLE_PROGRESS~%% = 0~%%
CONST AUDIOANALYZER_STYLE_OSCILLOSCOPE1~%% = 1~%%
CONST AUDIOANALYZER_STYLE_OSCILLOSCOPE2~%% = 2~%%
CONST AUDIOANALYZER_STYLE_VU~%% = 3~%%
CONST AUDIOANALYZER_STYLE_SPECTRUM~%% = 4~%%
CONST AUDIOANALYZER_STYLE_CIRCULAR_WAVEFORM~%% = 5~%%
CONST AUDIOANALYZER_STYLE_RADIAL_SPARKS~%% = 6~%%
CONST AUDIOANALYZER_STYLE_TESLA_COIL~%% = 7~%%
CONST AUDIOANALYZER_STYLE_CIRCLE_WAVES~%% = 8~%%
CONST AUDIOANALYZER_STYLE_STARS~%% = 9~%%
CONST AUDIOANALYZER_STYLE_BUBBLE_UNIVERSE~%% = 10~%%
CONST AUDIOANALYZER_STYLE_COUNT~%% = 11~%% ' add new stuff before this and adjust values

TYPE __AudioAnalyzer_StarType
    p AS Vector3FType ' position
    a AS SINGLE ' angle
    c AS _UNSIGNED LONG ' color
END TYPE

TYPE __AudioAnalyzer_CircleWaveType
    p AS Vector2DType ' position
    v AS Vector2DType ' velocity
    r AS SINGLE ' radius
    c AS BGRAType ' color
    a AS SINGLE ' alpha (0.0 - 1.0)
    s AS SINGLE ' fade speed
END TYPE

TYPE __AudioAnalyzerType
    handle AS LONG
    buffer AS _MEM
    format AS _UNSIGNED _BYTE
    channels AS _UNSIGNED _BYTE
    currentTime AS DOUBLE
    totalTime AS DOUBLE
    currentFrame AS _UNSIGNED _INTEGER64
    totalFrames AS _UNSIGNED _INTEGER64
    isLengthQueryPending AS _BYTE
    clipBufferFrames AS _UNSIGNED LONG
    clipBufferSamples AS _UNSIGNED LONG
    fftBufferSamples AS _UNSIGNED LONG
    fftBits AS _UNSIGNED _BYTE
    fftScale AS Vector2LType
    vuPeakFallSpeed AS SINGLE
    progressTextHide AS _BYTE
    progressTextColor AS _UNSIGNED LONG
    style AS _UNSIGNED _BYTE
    viewport AS LONG
    color1 AS _UNSIGNED LONG
    color2 AS _UNSIGNED LONG
    color3 AS _UNSIGNED LONG
    currentTimeText AS STRING
    totalTimeText AS STRING
    starCount AS _UNSIGNED LONG
    starSpeedMultiplier AS SINGLE
    circleWaveCount AS _UNSIGNED LONG
    circleWaveRadiusMultiplier AS SINGLE
    bubbleUniverseNoStretch AS _BYTE
END TYPE

DIM __AudioAnalyzer AS __AudioAnalyzerType
REDIM AS SINGLE __AudioAnalyzer_ClipBuffer(0), __AudioAnalyzer_IntensityBuffer(0), __AudioAnalyzer_PeakBuffer(0)
REDIM __AudioAnalyzer_FFTBuffer(0, 0) AS _UNSIGNED INTEGER ' order should be data, channel to work with the C-side of things
REDIM __AudioAnalyzer_Stars(0, 0) AS __AudioAnalyzer_StarType, __AudioAnalyzer_CircleWaves(0, 0) AS __AudioAnalyzer_CircleWaveType

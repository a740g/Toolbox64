'-----------------------------------------------------------------------------------------------------------------------
' A simple audio visualization library
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'AudioVisualizer.bi'

'-----------------------------------------------------------------------------------------------------------------------
' Test code for debugging the library
'-----------------------------------------------------------------------------------------------------------------------
'OPTION _EXPLICIT
'$RESIZE:SMOOTH
'_DEFINE A-Z AS LONG
'OPTION _EXPLICIT

'$COLOR:32

'SCREEN _NEWIMAGE(800, 600, 32)
'_ALLOWFULLSCREEN _SQUAREPIXELS , _SMOOTH
'_FONT 16

'PRINT "Loading... ";
'DIM song AS LONG: song = _SNDOPEN(_OPENFILEDIALOG$)
'IF song < 1 THEN
'    PRINT "Failed to load song!"
'    END
'END IF
'PRINT "Done!"

'IF NOT AudioAnalyzer_Init(song) THEN
'    PRINT "Failed to access sound sample data."
'    END
'END IF

'_SNDPLAY song

'DIM style AS INTEGER: style = AUDIOANALYZER_STYLE_SPECTRUM
'AudioAnalyzer_SetStyle style
'AudioAnalyzer_SetFFTScale 1, 6

'DIM channels AS _UNSIGNED _BYTE: channels = AudioAnalyzer_GetChannels

'DIM AS _BYTE hideText, isVertical
'DIM k AS LONG

'DO
'    k = _KEYHIT

'    SELECT CASE k
'        CASE 27 ' exit
'            EXIT DO

'        CASE 19200 ' vis -
'            IF style > 0 THEN style = style - 1
'            AudioAnalyzer_SetStyle style

'        CASE 19712 ' vis +
'            IF style < AUDIOANALYZER_STYLE_COUNT - 1 THEN style = style + 1
'            AudioAnalyzer_SetStyle style

'        CASE 116, 84 ' text on / off
'            hideText = NOT hideText
'            AudioAnalyzer_SetProgressProperties hideText, BGRA_YELLOW

'        CASE 111, 79 ' toggle orientation
'            isVertical = NOT isVertical
'    END SELECT

'    AudioAnalyzer_Update

'    CLS

'    PRINT "Frame:"; AudioAnalyzer_GetCurrentFrame; "of"; AudioAnalyzer_GetTotalFrames, "Format:"; __AudioAnalyzer.format, "Channels:"; channels;
'    LOCATE 37, 1: PRINT "ESC: Exit", "<-: Vis-", "->: Vis+", "T: Text", "O: Vert";

'    IF channels < 2 _ORELSE style = AUDIOANALYZER_STYLE_PROGRESS THEN
'        COLOR &HFFFFFFFF ' text color - bright white

'        IF isVertical THEN
'            Graphics_DrawRectangle 349, 99, 451, 501, Yellow
'            AudioAnalyzer_Render 350, 100, 450, 500, 0
'        ELSE
'            Graphics_DrawRectangle 99, 249, 701, 351, Yellow
'            AudioAnalyzer_Render 100, 250, 700, 350, 0
'        END IF
'    ELSE
'        IF isVertical THEN
'            Graphics_DrawRectangle 149, 99, 251, 501, Yellow
'            AudioAnalyzer_Render 150, 100, 250, 500, 0
'            Graphics_DrawRectangle 549, 99, 651, 501, Yellow
'            AudioAnalyzer_Render 550, 100, 650, 500, 1
'        ELSE
'            Graphics_DrawRectangle 49, 249, 351, 351, Yellow
'            AudioAnalyzer_Render 50, 250, 350, 350, 0
'            Graphics_DrawRectangle 449, 249, 751, 351, Yellow
'            AudioAnalyzer_Render 450, 250, 750, 350, 1
'        END IF
'    END IF

'    _DISPLAY

'    _LIMIT 60
'LOOP WHILE _SNDPLAYING(song)

'_AUTODISPLAY
'AudioAnalyzer_Done
'_SNDCLOSE song
'END
'-----------------------------------------------------------------------------------------------------------------------

FUNCTION AudioAnalyzer_Init%% (handle AS LONG)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED AS SINGLE __AudioAnalyzer_ClipBuffer(), __AudioAnalyzer_IntensityBuffer(), __AudioAnalyzer_PeakBuffer()
    SHARED __AudioAnalyzer_FFTBuffer() AS _UNSIGNED INTEGER

    IF __AudioAnalyzer.handle = 0 THEN
        __AudioAnalyzer.handle = handle
        __AudioAnalyzer.buffer = _MEMSOUND(handle)
        __AudioAnalyzer.format = __AUDIOANALYZER_FORMAT_UNKNOWN
        __AudioAnalyzer.channels = 0

        IF __AudioAnalyzer.buffer.SIZE THEN
            ' Figure out the sound format based on https://qb64phoenix.com/qb64wiki/index.php/MEM
            ' Note: We do not support 24-bit audio yet
            IF __AudioAnalyzer.buffer.TYPE = 1153 THEN
                __AudioAnalyzer.format = __AUDIOANALYZER_FORMAT_U8
                __AudioAnalyzer.channels = __AudioAnalyzer.buffer.ELEMENTSIZE \ _SIZE_OF_BYTE
            ELSEIF __AudioAnalyzer.buffer.TYPE = 130 THEN
                __AudioAnalyzer.format = __AUDIOANALYZER_FORMAT_S16
                __AudioAnalyzer.channels = __AudioAnalyzer.buffer.ELEMENTSIZE \ _SIZE_OF_INTEGER
            ELSEIF __AudioAnalyzer.buffer.TYPE = 132 THEN
                __AudioAnalyzer.format = __AUDIOANALYZER_FORMAT_S32
                __AudioAnalyzer.channels = __AudioAnalyzer.buffer.ELEMENTSIZE \ _SIZE_OF_LONG
            ELSEIF __AudioAnalyzer.buffer.TYPE = 260 THEN
                __AudioAnalyzer.format = __AUDIOANALYZER_FORMAT_F32
                __AudioAnalyzer.channels = __AudioAnalyzer.buffer.ELEMENTSIZE \ _SIZE_OF_SINGLE
            END IF
        END IF

        __AudioAnalyzer.totalTime = _SNDLEN(handle)
        __AudioAnalyzer.totalFrames = __AudioAnalyzer.totalTime * _SNDRATE
        __AudioAnalyzer.isLengthQueryPending = _TRUE
        __AudioAnalyzer.clipBufferFrames = Math_RoundDownLongToPowerOf2(__AUDIOANALYZER_CLIP_BUFFER_TIME * _SNDRATE) ' save the clip buffer frames
        __AudioAnalyzer.clipBufferSamples = __AudioAnalyzer.clipBufferFrames * __AudioAnalyzer.channels
        __AudioAnalyzer.fftBufferSamples = __AudioAnalyzer.clipBufferFrames \ 2 ' since we get the data for positive frequencies only
        __AudioAnalyzer.style = AUDIOANALYZER_STYLE_OSCILLOSCOPE1

        AudioAnalyzer_SetFFTScale __AUDIOANALYZER_FFT_SCALE_X, __AUDIOANALYZER_FFT_SCALE_Y
        AudioAnalyzer_SetVUPeakFallSpeed __AUDIOANALYZER_VU_PEAK_FALL_SPEED
        AudioAnalyzer_SetProgressProperties _FALSE, __AUDIOANALYZER_TEXT_COLOR
        AudioAnalyzer_SetColors _RGB32(0, 255, 0), _RGB32(255, 0, 0), _RGB32(0, 0, 255)

        __AudioAnalyzer.currentTimeText = "00:00:00"
        __AudioAnalyzer.totalTimeText = __AudioAnalyzer.currentTimeText

        IF __AudioAnalyzer.clipBufferSamples THEN
            REDIM __AudioAnalyzer_ClipBuffer(0 TO __AudioAnalyzer.clipBufferSamples - 1) AS SINGLE
        END IF

        IF __AudioAnalyzer.channels THEN
            IF __AudioAnalyzer.fftBufferSamples THEN
                REDIM __AudioAnalyzer_FFTBuffer(0 TO __AudioAnalyzer.fftBufferSamples - 1, 0 TO __AudioAnalyzer.channels - 1) AS _UNSIGNED INTEGER
                __AudioAnalyzer.fftBits = LeftShiftOneCount(__AudioAnalyzer.clipBufferFrames) ' get the count of bits that the FFT routine will need
            END IF

            REDIM __AudioAnalyzer_IntensityBuffer(0 TO __AudioAnalyzer.channels - 1) AS SINGLE
            REDIM __AudioAnalyzer_PeakBuffer(0 TO __AudioAnalyzer.channels - 1) AS SINGLE

            AudioAnalyzer_SetStarCount __AUDIOANALYZER_STAR_COUNT
            AudioAnalyzer_SetCircleWaveCount __AUDIOANALYZER_CIRCLE_WAVE_COUNT
        END IF

        AudioAnalyzer_SetStarProperties __AUDIOANALYZER_STAR_SPEED_MUL
        AudioAnalyzer_SetCircleWaveProperties __AUDIOANALYZER_CIRCLE_WAVE_RADIUS_MUL

        ' Note: We'll return success even if we failed to acquire the sound buffer
        ' That's because some formats simply do not allow accessing sample data (i.e. .ogg; due to the way stb_vorbis works :()
        ' In these cases we'll force fallback to the "progress" style
        AudioAnalyzer_Init = _TRUE
    END IF
END FUNCTION


SUB AudioAnalyzer_Done
    SHARED __AudioAnalyzer AS __AudioAnalyzerType

    IF __AudioAnalyzer.handle THEN
        IF __AudioAnalyzer.viewport THEN
            _FREEIMAGE __AudioAnalyzer.viewport
            __AudioAnalyzer.viewport = 0
        END IF
        __AudioAnalyzer.handle = 0
        '_MEMFREE __AudioAnalyzer.buffer - this is not needed as _SNDCLOSE auto-frees the mem block
        __AudioAnalyzer.format = __AUDIOANALYZER_FORMAT_UNKNOWN
        __AudioAnalyzer.channels = 0
        __AudioAnalyzer.currentTime = 0#
        __AudioAnalyzer.totalTime = 0#
        __AudioAnalyzer.currentFrame = 0
        __AudioAnalyzer.totalFrames = 0
        __AudioAnalyzer.clipBufferFrames = 0
        __AudioAnalyzer.clipBufferSamples = 0
        __AudioAnalyzer.fftBufferSamples = 0
        __AudioAnalyzer.currentTimeText = _STR_EMPTY
        __AudioAnalyzer.totalTimeText = _STR_EMPTY
    END IF
END SUB


FUNCTION AudioAnalyzer_GetChannels~%%
    $CHECKING:OFF
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    IF __AudioAnalyzer.handle THEN
        AudioAnalyzer_GetChannels = __AudioAnalyzer.channels + (__AudioAnalyzer.channels = 0) * -1 ' at least 1 channel if handle is valid
    END IF
    $CHECKING:ON
END FUNCTION


FUNCTION AudioAnalyzer_GetCurrentTime#
    $CHECKING:OFF
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    AudioAnalyzer_GetCurrentTime = __AudioAnalyzer.currentTime
    $CHECKING:ON
END FUNCTION


FUNCTION AudioAnalyzer_GetTotalTime#
    $CHECKING:OFF
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    AudioAnalyzer_GetTotalTime = __AudioAnalyzer.totalTime
    $CHECKING:ON
END FUNCTION


FUNCTION AudioAnalyzer_GetCurrentFrame~&&
    $CHECKING:OFF
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    AudioAnalyzer_GetCurrentFrame = __AudioAnalyzer.currentFrame
    $CHECKING:ON
END FUNCTION


FUNCTION AudioAnalyzer_GetTotalFrames~&&
    $CHECKING:OFF
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    AudioAnalyzer_GetTotalFrames = __AudioAnalyzer.totalFrames
    $CHECKING:ON
END FUNCTION


FUNCTION AudioAnalyzer_GetIntensity! (channel AS _UNSIGNED _BYTE)
    $CHECKING:OFF
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED __AudioAnalyzer_IntensityBuffer() AS SINGLE
    IF __AudioAnalyzer.handle THEN
        AudioAnalyzer_GetIntensity = __AudioAnalyzer_IntensityBuffer(channel)
    END IF
    $CHECKING:ON
END FUNCTION


FUNCTION AudioAnalyzer_GetPeak! (channel AS _UNSIGNED _BYTE)
    $CHECKING:OFF
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED __AudioAnalyzer_PeakBuffer() AS SINGLE
    IF __AudioAnalyzer.handle THEN
        AudioAnalyzer_GetPeak = __AudioAnalyzer_PeakBuffer(channel)
    END IF
    $CHECKING:ON
END FUNCTION


FUNCTION AudioAnalyzer_GetCurrentTimeText$
    $CHECKING:OFF
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    AudioAnalyzer_GetCurrentTimeText = __AudioAnalyzer.currentTimeText
    $CHECKING:ON
END FUNCTION


FUNCTION AudioAnalyzer_GetTotalTimeText$
    $CHECKING:OFF
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    AudioAnalyzer_GetTotalTimeText = __AudioAnalyzer.totalTimeText
    $CHECKING:ON
END FUNCTION


SUB AudioAnalyzer_SetStyle (style AS _UNSIGNED _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    IF __AudioAnalyzer.handle THEN
        IF __AudioAnalyzer.format <> __AUDIOANALYZER_FORMAT_UNKNOWN THEN
            __AudioAnalyzer.style = style
        ELSE
            __AudioAnalyzer.style = AUDIOANALYZER_STYLE_PROGRESS
        END IF
    END IF
END SUB


SUB AudioAnalyzer_SetColors (color1 AS _UNSIGNED LONG, color2 AS _UNSIGNED LONG, color3 AS _UNSIGNED LONG)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    __AudioAnalyzer.color1 = color1
    __AudioAnalyzer.color2 = color2
    __AudioAnalyzer.color3 = color3
END SUB


SUB AudioAnalyzer_SetFFTScale (x AS _UNSIGNED _BYTE, y AS _UNSIGNED _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    __AudioAnalyzer.fftScale.x = 2 * x + (x = 0) * -1
    __AudioAnalyzer.fftScale.y = y
END SUB


SUB AudioAnalyzer_SetVUPeakFallSpeed (speed AS SINGLE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    IF speed > 0! THEN __AudioAnalyzer.vuPeakFallSpeed = speed
END SUB


SUB AudioAnalyzer_SetProgressProperties (hideText AS _BYTE, textColor AS _UNSIGNED LONG)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    __AudioAnalyzer.progressTextHide = hideText
    __AudioAnalyzer.progressTextColor = textColor
END SUB


SUB AudioAnalyzer_SetStarCount (count AS _UNSIGNED INTEGER)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED __AudioAnalyzer_Stars() AS __AudioAnalyzer_StarType

    __AudioAnalyzer.starCount = count
    REDIM __AudioAnalyzer_Stars(0 TO __AudioAnalyzer.channels - 1, 0 TO __AudioAnalyzer.starCount - 1) AS __AudioAnalyzer_StarType

    DIM AS _UNSIGNED LONG i, c
    WHILE i < __AudioAnalyzer.starCount
        c = 0
        WHILE c < __AudioAnalyzer.channels
            __AudioAnalyzer_Stars(c, i).p.x = -1!
            __AudioAnalyzer_Stars(c, i).p.y = -1!
            __AudioAnalyzer_Stars(c, i).p.z = __AUDIOANALYZER_STAR_Z_DIVIDER
            c = c + 1
        WEND
        i = i + 1
    WEND
END SUB


SUB AudioAnalyzer_SetCircleWaveCount (count AS _UNSIGNED INTEGER)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED __AudioAnalyzer_CircleWaves() AS __AudioAnalyzer_CircleWaveType

    __AudioAnalyzer.circleWaveCount = count
    REDIM __AudioAnalyzer_CircleWaves(0 TO __AudioAnalyzer.channels - 1, 0 TO __AudioAnalyzer.circleWaveCount - 1) AS __AudioAnalyzer_CircleWaveType

    DIM AS _UNSIGNED LONG i, c
    WHILE i < __AudioAnalyzer.circleWaveCount
        c = 0
        WHILE c < __AudioAnalyzer.channels
            __AudioAnalyzer_CircleWaves(c, i).a = 0!
            c = c + 1
        WEND
        i = i + 1
    WEND
END SUB


SUB AudioAnalyzer_SetStarProperties (mul AS SINGLE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    __AudioAnalyzer.starSpeedMultiplier = mul
END SUB


SUB AudioAnalyzer_SetCircleWaveProperties (mul AS SINGLE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    __AudioAnalyzer.circleWaveRadiusMultiplier = mul
END SUB


SUB AudioAnalyzer_StretchBubbleUniverse (state AS _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    __AudioAnalyzer.bubbleUniverseNoStretch = _NEGATE state
END SUB


SUB AudioAnalyzer_RenderSpectrum (w AS LONG, h AS LONG, channel AS _UNSIGNED _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED __AudioAnalyzer_FFTBuffer() AS _UNSIGNED INTEGER

    DIM freqMax AS _UNSIGNED LONG: freqMax = __AudioAnalyzer.fftBufferSamples \ __AudioAnalyzer.fftScale.x

    DIM AS LONG x, y

    IF h > w THEN
        DIM r AS LONG: r = w - 1

        IF channel AND 1 THEN
            WHILE y < h
                x = _SHR(__AudioAnalyzer_FFTBuffer((y * freqMax) \ h, channel), __AudioAnalyzer.fftScale.y)
                IF x > r THEN x = r

                Graphics_DrawHorizontalLine 0, y, x, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color2, x / r)

                y = y + 1
            WEND
        ELSE
            WHILE y < h
                x = _SHR(__AudioAnalyzer_FFTBuffer((y * freqMax) \ h, channel), __AudioAnalyzer.fftScale.y)
                IF x > r THEN x = r

                Graphics_DrawHorizontalLine r - x, y, r, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color2, x / r)

                y = y + 1
            WEND
        END IF
    ELSE
        DIM b AS LONG: b = h - 1

        WHILE x < w
            y = _SHR(__AudioAnalyzer_FFTBuffer((x * freqMax) \ w, channel), __AudioAnalyzer.fftScale.y)
            IF y > b THEN y = b

            Graphics_DrawVerticalLine x, b - y, b, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color2, y / b)

            x = x + 1
        WEND
    END IF
END SUB


SUB AudioAnalyzer_RenderOscilloscope1 (w AS LONG, h AS LONG, channel AS _UNSIGNED _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED __AudioAnalyzer_ClipBuffer() AS SINGLE

    DIM AS LONG x, y, lx, ly
    DIM sample AS SINGLE

    IF h > w THEN
        DIM cx AS LONG: cx = w \ 2

        WHILE y < h
            sample = __AudioAnalyzer_ClipBuffer(((y * __AudioAnalyzer.clipBufferFrames) \ h) * __AudioAnalyzer.channels + channel)
            x = cx + sample * cx

            IF y > 0 THEN
                Graphics_DrawLine lx, ly, x, y, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color2, ABS(sample))
            ELSE
                Graphics_DrawPixel x, y, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color2, ABS(sample))
            END IF

            lx = x
            ly = y

            y = y + 1
        WEND
    ELSE
        DIM cy AS LONG: cy = h \ 2

        WHILE x < w
            sample = __AudioAnalyzer_ClipBuffer(((x * __AudioAnalyzer.clipBufferFrames) \ w) * __AudioAnalyzer.channels + channel)
            y = cy + sample * cy

            IF x > 0 THEN
                Graphics_DrawLine lx, ly, x, y, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color2, ABS(sample))
            ELSE
                Graphics_DrawPixel x, y, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color2, ABS(sample))
            END IF

            lx = x
            ly = y

            x = x + 1
        WEND
    END IF
END SUB


SUB AudioAnalyzer_RenderOscilloscope2 (w AS LONG, h AS LONG, channel AS _UNSIGNED _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED __AudioAnalyzer_ClipBuffer() AS SINGLE

    DIM i AS _UNSIGNED LONG, sample AS SINGLE

    IF h > w THEN
        DIM cx AS LONG: cx = w \ 2

        WHILE i < h
            sample = __AudioAnalyzer_ClipBuffer(((i * __AudioAnalyzer.clipBufferFrames) \ h) * __AudioAnalyzer.channels + channel)

            Graphics_DrawHorizontalLine cx, i, cx + sample * cx, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color2, ABS(sample))

            i = i + 1
        WEND
    ELSE
        DIM cy AS LONG: cy = h \ 2

        WHILE i < w
            sample = __AudioAnalyzer_ClipBuffer(((i * __AudioAnalyzer.clipBufferFrames) \ w) * __AudioAnalyzer.channels + channel)

            Graphics_DrawVerticalLine i, cy - sample * cy, cy, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color2, ABS(sample))

            i = i + 1
        WEND
    END IF
END SUB


SUB AudioAnalyzer_RenderVU (w AS LONG, h AS LONG, channel AS _UNSIGNED _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED AS SINGLE __AudioAnalyzer_IntensityBuffer(), __AudioAnalyzer_PeakBuffer()

    DIM AS LONG size, peak, xp, yp

    DIM r AS LONG: r = w - 1
    DIM b AS LONG: b = h - 1

    IF h > w THEN
        size = __AudioAnalyzer_IntensityBuffer(channel) * b * 2!
        IF size > b THEN size = b

        peak = __AudioAnalyzer_PeakBuffer(channel) * b * 2!
        IF peak > b THEN peak = b

        yp = b - peak
        Graphics_DrawHorizontalLine 0, yp, r, __AudioAnalyzer.color2

        Graphics_DrawFilledRectangle 0, b - size, r, b, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color3, size / b)
    ELSE
        size = __AudioAnalyzer_IntensityBuffer(channel) * r * 2!
        IF size > r THEN size = r

        peak = __AudioAnalyzer_PeakBuffer(channel) * r * 2!
        IF peak > r THEN peak = r

        IF channel AND 1 THEN
            Graphics_DrawVerticalLine peak, 0, b, __AudioAnalyzer.color2

            Graphics_DrawFilledRectangle 0, 0, size, b, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color3, size / r)
        ELSE
            xp = r - peak
            Graphics_DrawVerticalLine xp, 0, b, __AudioAnalyzer.color2

            Graphics_DrawFilledRectangle r - size, 0, r, b, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color3, size / r)
        END IF
    END IF
END SUB


SUB AudioAnalyzer_RenderProgress (w AS LONG, h AS LONG)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType

    DIM size AS LONG, cf AS SINGLE

    DIM r AS LONG: r = w - 1
    DIM b AS LONG: b = h - 1

    IF h > w THEN
        size = (__AudioAnalyzer.currentTime / __AudioAnalyzer.totalTime) * h
        DIM y AS LONG: y = h - size
        cf = size / h
        Graphics_DrawFilledRectangle 0, 0, r, y - 1, Graphics_InterpolateColor(__AudioAnalyzer.color3, __AudioAnalyzer.color2, cf)
        Graphics_DrawFilledRectangle 0, y, r, b, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color3, cf)
    ELSE
        size = (__AudioAnalyzer.currentTime / __AudioAnalyzer.totalTime) * w
        DIM x AS LONG: x = size - 1
        cf = size / w
        Graphics_DrawFilledRectangle x + 1, 0, r, b, Graphics_InterpolateColor(__AudioAnalyzer.color3, __AudioAnalyzer.color2, cf)
        Graphics_DrawFilledRectangle 0, 0, x, b, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color3, cf)

        IF _NEGATE __AudioAnalyzer.progressTextHide THEN
            DIM text AS STRING: text = __AudioAnalyzer.currentTimeText + " / " + __AudioAnalyzer.totalTimeText
            DIM textX AS LONG: textX = w \ 2 - _PRINTWIDTH(text) \ 2
            DIM textY AS LONG: textY = h \ 2 - _UFONTHEIGHT \ 2
            _PRINTMODE _KEEPBACKGROUND
            COLOR __AudioAnalyzer.progressTextColor
            _PRINTSTRING (textX, textY), text
        END IF
    END IF
END SUB


SUB AudioAnalyzer_RenderStars (w AS LONG, h AS LONG, channel AS _UNSIGNED _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED __AudioAnalyzer_Stars() AS __AudioAnalyzer_StarType
    SHARED __AudioAnalyzer_IntensityBuffer() AS SINGLE

    DIM halfW AS LONG: halfW = w \ 2
    DIM halfH AS LONG: halfH = h \ 2
    DIM aX AS SINGLE: aX = h / w
    DIM aY AS SINGLE: aY = w / h

    DIM i AS _UNSIGNED LONG
    WHILE i < __AudioAnalyzer.starCount
        IF __AudioAnalyzer_Stars(channel, i).p.x < 0 _ORELSE __AudioAnalyzer_Stars(channel, i).p.x >= w _ORELSE __AudioAnalyzer_Stars(channel, i).p.y < 0 _ORELSE __AudioAnalyzer_Stars(channel, i).p.y >= h THEN
            __AudioAnalyzer_Stars(channel, i).p.x = Math_GetRandomBetween(0, w - 1)
            __AudioAnalyzer_Stars(channel, i).p.y = Math_GetRandomBetween(0, h - 1)
            __AudioAnalyzer_Stars(channel, i).p.z = __AUDIOANALYZER_STAR_Z_DIVIDER
            __AudioAnalyzer_Stars(channel, i).c = _RGB32(Math_GetRandomBetween(64, 255), Math_GetRandomBetween(64, 255), Math_GetRandomBetween(64, 255))
        END IF

        Graphics_DrawPixel __AudioAnalyzer_Stars(channel, i).p.x, __AudioAnalyzer_Stars(channel, i).p.y, __AudioAnalyzer_Stars(channel, i).c

        __AudioAnalyzer_Stars(channel, i).p.z = __AudioAnalyzer_Stars(channel, i).p.z + __AudioAnalyzer_IntensityBuffer(channel) * __AudioAnalyzer.starSpeedMultiplier
        __AudioAnalyzer_Stars(channel, i).a = __AudioAnalyzer_Stars(channel, i).a + __AUDIOANALYZER_STAR_ANGLE_INC
        DIM zd AS SINGLE: zd = __AudioAnalyzer_Stars(channel, i).p.z / __AUDIOANALYZER_STAR_Z_DIVIDER
        __AudioAnalyzer_Stars(channel, i).p.x = ((__AudioAnalyzer_Stars(channel, i).p.x - halfW) * zd) + halfW + COS(__AudioAnalyzer_Stars(channel, i).a * aX)
        __AudioAnalyzer_Stars(channel, i).p.y = ((__AudioAnalyzer_Stars(channel, i).p.y - halfH) * zd) + halfH + SIN(__AudioAnalyzer_Stars(channel, i).a * aY)

        i = i + 1
    WEND
END SUB


SUB AudioAnalyzer_RenderCircleWaves (w AS LONG, h AS LONG, channel AS _UNSIGNED _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED __AudioAnalyzer_CircleWaves() AS __AudioAnalyzer_CircleWaveType
    SHARED AS SINGLE __AudioAnalyzer_IntensityBuffer()

    DIM radMax AS LONG: radMax = Math_GetMinLong(w, h) \ 4
    DIM radMin AS LONG: radMin = radMax \ 8

    DIM i AS _UNSIGNED LONG
    FOR i = __AudioAnalyzer.circleWaveCount - 1 TO 0 STEP -1
        __AudioAnalyzer_CircleWaves(channel, i).a = __AudioAnalyzer_CircleWaves(channel, i).a + __AudioAnalyzer_CircleWaves(channel, i).s
        __AudioAnalyzer_CircleWaves(channel, i).r = __AudioAnalyzer_CircleWaves(channel, i).r + __AudioAnalyzer_CircleWaves(channel, i).s * 10!
        __AudioAnalyzer_CircleWaves(channel, i).p.x = __AudioAnalyzer_CircleWaves(channel, i).p.x + __AudioAnalyzer_CircleWaves(channel, i).v.x
        __AudioAnalyzer_CircleWaves(channel, i).p.y = __AudioAnalyzer_CircleWaves(channel, i).p.y + __AudioAnalyzer_CircleWaves(channel, i).v.y

        IF __AudioAnalyzer_CircleWaves(channel, i).a >= 1! THEN
            __AudioAnalyzer_CircleWaves(channel, i).s = __AudioAnalyzer_CircleWaves(channel, i).s * -1!
            __AudioAnalyzer_CircleWaves(channel, i).a = 1!
        ELSEIF __AudioAnalyzer_CircleWaves(channel, i).a <= 0! THEN
            __AudioAnalyzer_CircleWaves(channel, i).a = 0!
            __AudioAnalyzer_CircleWaves(channel, i).r = Math_GetRandomBetween(radMin, radMax)
            __AudioAnalyzer_CircleWaves(channel, i).p.x = Math_GetRandomBetween(__AudioAnalyzer_CircleWaves(channel, i).r, w - __AudioAnalyzer_CircleWaves(channel, i).r)
            __AudioAnalyzer_CircleWaves(channel, i).p.y = Math_GetRandomBetween(__AudioAnalyzer_CircleWaves(channel, i).r, h - __AudioAnalyzer_CircleWaves(channel, i).r)
            __AudioAnalyzer_CircleWaves(channel, i).v.x = (RND - RND) / 3!
            __AudioAnalyzer_CircleWaves(channel, i).v.y = (RND - RND) / 3!
            __AudioAnalyzer_CircleWaves(channel, i).s = Math_GetRandomBetween(1, 100) / 4000!
            __AudioAnalyzer_CircleWaves(channel, i).c.r = Math_GetRandomBetween(0, 128)
            __AudioAnalyzer_CircleWaves(channel, i).c.g = Math_GetRandomBetween(0, 128)
            __AudioAnalyzer_CircleWaves(channel, i).c.b = Math_GetRandomBetween(0, 128)
        END IF

        __AudioAnalyzer_CircleWaves(channel, i).c.a = 255! * __AudioAnalyzer_CircleWaves(channel, i).a

        Graphics_DrawFilledCircle __AudioAnalyzer_CircleWaves(channel, i).p.x, __AudioAnalyzer_CircleWaves(channel, i).p.y, __AudioAnalyzer_CircleWaves(channel, i).r + __AudioAnalyzer_CircleWaves(channel, i).r * __AudioAnalyzer_IntensityBuffer(channel) * __AudioAnalyzer.circleWaveRadiusMultiplier, Graphics_BGRATypeToBGRA(__AudioAnalyzer_CircleWaves(channel, i).c)
    NEXT i

    VIEW
END SUB


SUB AudioAnalyzer_RenderRadialSparks (w AS LONG, h AS LONG, channel AS _UNSIGNED _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED AS SINGLE __AudioAnalyzer_ClipBuffer()

    DIM cx AS LONG: cx = w \ 2
    DIM cy AS LONG: cy = h \ 2
    DIM maxLength AS LONG: maxLength = Math_GetMaxLong(w, h)

    DIM AS LONG angle, x2, y2
    DIM length AS SINGLE

    FOR angle = 0 TO 359 STEP 6
        DIM sample AS SINGLE: sample = __AudioAnalyzer_ClipBuffer(((angle * __AudioAnalyzer.clipBufferFrames) \ 360) * __AudioAnalyzer.channels + channel)

        length = maxLength * sample

        x2 = cx + COS(angle) * length
        y2 = cy + SIN(angle) * length

        Graphics_DrawLine cx, cy, x2, y2, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color2, sample)
    NEXT angle
END SUB


SUB AudioAnalyzer_RenderTeslaCoil (w AS LONG, h AS LONG, channel AS _UNSIGNED _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED __AudioAnalyzer_IntensityBuffer() AS SINGLE

    DIM cx AS LONG: cx = w \ 2
    DIM cy AS LONG: cy = h \ 2
    DIM maxLength AS LONG: maxLength = Math_GetMaxLong(w, h)
    DIM intensity AS SINGLE: intensity = __AudioAnalyzer_IntensityBuffer(channel) * 2!

    DIM AS LONG i, j, x2, y2
    DIM AS SINGLE angle, branchAngle, length, branchLength

    FOR i = 1 TO 12
        angle = RND * _PI(2!)
        length = RND * maxLength * intensity

        x2 = cx + COS(angle) * length
        y2 = cy + SIN(angle) * length

        Graphics_DrawLine cx, cy, x2, y2, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color3, intensity)

        FOR j = 1 TO 6
            branchAngle = angle + _PI(RND - 0.5!) / 2!
            branchLength = RND * length / 2!

            Graphics_DrawLine x2, y2, x2 + COS(branchAngle) * branchLength, y2 + SIN(branchAngle) * branchLength, Graphics_InterpolateColor(__AudioAnalyzer.color3, __AudioAnalyzer.color2, intensity)
        NEXT j
    NEXT i
END SUB


' Adapted from Bubble Universe by Paul Dunn (ZXDunny)
SUB AudioAnalyzer_RenderBubbleUniverse (w AS LONG, h AS LONG, channel AS _UNSIGNED _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED AS SINGLE __AudioAnalyzer_IntensityBuffer(), __AudioAnalyzer_PeakBuffer()

    STATIC sT AS SINGLE

    DIM cx AS LONG: cx = w \ 2
    DIM cy AS LONG: cy = h \ 2

    DIM AS LONG ax, ay

    IF __AudioAnalyzer.bubbleUniverseNoStretch THEN
        ax = Math_GetMinLong(cx, cy)
        ay = ax
    ELSE
        ax = cx
        ay = cy
    END IF

    DIM AS LONG i, j
    DIM AS SINGLE x, u, v

    FOR i = 0 TO 200
        FOR j = 0 TO 200
            u = SIN(i + v) + SIN(_PI(2! / 235!) * i + x)
            v = COS(i + v) + COS(_PI(2! / 235!) * i + x)
            x = u + sT

            Graphics_DrawPixel cx + u * ax * 0.5!, cy + v * ay * 0.5!, Graphics_MakeBGR(i, j, 255! * __AudioAnalyzer_PeakBuffer(channel))
        NEXT
    NEXT

    sT = sT + __AudioAnalyzer_IntensityBuffer(channel)
END SUB


SUB AudioAnalyzer_RenderCircularWaveform (w AS LONG, h AS LONG, channel AS _UNSIGNED _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED __AudioAnalyzer_ClipBuffer() AS SINGLE

    DIM cx AS LONG: cx = w \ 2
    DIM cy AS LONG: cy = h \ 2
    DIM radius AS LONG: radius = Math_GetMinLong(w, h) \ 3
    DIM angleStep AS SINGLE: angleStep = _PI(2!) / __AudioAnalyzer.clipBufferFrames

    DIM AS LONG i, lx, ly

    WHILE i < __AudioAnalyzer.clipBufferFrames
        DIM amplitude AS SINGLE: amplitude = __AudioAnalyzer_ClipBuffer(i * __AudioAnalyzer.channels + channel)
        DIM angle AS SINGLE: angle = i * angleStep
        DIM x AS LONG: x = cx + COS(angle) * (radius + amplitude * radius)
        DIM y AS LONG: y = cy + SIN(angle) * (radius + amplitude * radius)

        IF i > 0 THEN
            Graphics_DrawLine lx, ly, x, y, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color2, ABS(amplitude))
        ELSE
            Graphics_DrawPixel x, y, Graphics_InterpolateColor(__AudioAnalyzer.color1, __AudioAnalyzer.color2, ABS(amplitude))
        END IF

        lx = x
        ly = y

        i = i + 1
    WEND
END SUB


SUB AudioAnalyzer_Update
    SHARED __AudioAnalyzer AS __AudioAnalyzerType
    SHARED AS SINGLE __AudioAnalyzer_ClipBuffer(), __AudioAnalyzer_IntensityBuffer(), __AudioAnalyzer_PeakBuffer()
    SHARED __AudioAnalyzer_FFTBuffer() AS _UNSIGNED INTEGER

    DIM AS LONG hours, minutes, seconds

    IF __AudioAnalyzer.handle THEN
        __AudioAnalyzer.currentTime = _SNDGETPOS(__AudioAnalyzer.handle)
        __AudioAnalyzer.currentFrame = _CAST(_UNSIGNED _INTEGER64, __AudioAnalyzer.currentTime * _SNDRATE)

        hours = __AudioAnalyzer.currentTime \ 3600
        minutes = (__AudioAnalyzer.currentTime - hours * 3600) \ 60
        seconds = __AudioAnalyzer.currentTime - hours * 3600 - minutes * 60
        __AudioAnalyzer.currentTimeText = RIGHT$("0" + LTRIM$(STR$(hours)), 2) + ":" + RIGHT$("0" + LTRIM$(STR$(minutes)), 2) + ":" + RIGHT$("0" + LTRIM$(STR$(seconds)), 2)

        IF __AudioAnalyzer.isLengthQueryPending _ORELSE __AudioAnalyzer.currentFrame > __AudioAnalyzer.totalFrames THEN
            DIM totalTime AS DOUBLE: totalTime = _SNDLEN(__AudioAnalyzer.handle)
            __AudioAnalyzer.isLengthQueryPending = (totalTime <> __AudioAnalyzer.totalTime _ORELSE totalTime = 0#)
            __AudioAnalyzer.totalTime = totalTime
            __AudioAnalyzer.totalFrames = _CAST(_UNSIGNED _INTEGER64, __AudioAnalyzer.totalTime * _SNDRATE)

            hours = __AudioAnalyzer.totalTime \ 3600
            minutes = (__AudioAnalyzer.totalTime - hours * 3600) \ 60
            seconds = __AudioAnalyzer.totalTime - hours * 3600 - minutes * 60
            __AudioAnalyzer.totalTimeText = RIGHT$("0" + LTRIM$(STR$(hours)), 2) + ":" + RIGHT$("0" + LTRIM$(STR$(minutes)), 2) + ":" + RIGHT$("0" + LTRIM$(STR$(seconds)), 2)
        END IF

        DIM i AS _UNSIGNED LONG
        DIM byteOffset AS _UNSIGNED _OFFSET: byteOffset = __AudioAnalyzer.buffer.OFFSET + __AudioAnalyzer.currentFrame * __AudioAnalyzer.buffer.ELEMENTSIZE

        IF byteOffset <= __AudioAnalyzer.buffer.OFFSET + __AudioAnalyzer.buffer.SIZE - __AudioAnalyzer.clipBufferSamples * __AudioAnalyzer.buffer.ELEMENTSIZE THEN
            SELECT CASE __AudioAnalyzer.format
                CASE __AUDIOANALYZER_FORMAT_U8
                    AudioConv_ConvertU8ToF32 byteOffset, __AudioAnalyzer.clipBufferSamples, _OFFSET(__AudioAnalyzer_ClipBuffer(0))

                CASE __AUDIOANALYZER_FORMAT_S16
                    AudioConv_ConvertS16ToF32 byteOffset, __AudioAnalyzer.clipBufferSamples, _OFFSET(__AudioAnalyzer_ClipBuffer(0))

                CASE __AUDIOANALYZER_FORMAT_S32
                    AudioConv_ConvertS32ToF32 byteOffset, __AudioAnalyzer.clipBufferSamples, _OFFSET(__AudioAnalyzer_ClipBuffer(0))

                CASE __AUDIOANALYZER_FORMAT_F32
                    CopyMemory _OFFSET(__AudioAnalyzer_ClipBuffer(0)), byteOffset, __AudioAnalyzer.clipBufferSamples * _SIZE_OF_SINGLE
            END SELECT

            i = 0
            WHILE i < __AudioAnalyzer.channels
                __AudioAnalyzer_IntensityBuffer(i) = AudioAnalyzerFFT_DoSingle(__AudioAnalyzer_FFTBuffer(0, i), __AudioAnalyzer_ClipBuffer(i), __AudioAnalyzer.channels, __AudioAnalyzer.fftBits)
                IF __AudioAnalyzer_IntensityBuffer(i) > __AudioAnalyzer_PeakBuffer(i) THEN __AudioAnalyzer_PeakBuffer(i) = __AudioAnalyzer_IntensityBuffer(i)
                __AudioAnalyzer_PeakBuffer(i) = __AudioAnalyzer_PeakBuffer(i) - __AudioAnalyzer.vuPeakFallSpeed
                IF __AudioAnalyzer_PeakBuffer(i) <= 0! THEN __AudioAnalyzer_PeakBuffer(i) = 0!
                i = i + 1
            WEND
        END IF
    END IF
END SUB


SUB AudioAnalyzer_RenderDirect (w AS LONG, h AS LONG, channel AS _UNSIGNED _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType

    IF __AudioAnalyzer.handle THEN
        IF __AudioAnalyzer.format = __AUDIOANALYZER_FORMAT_UNKNOWN THEN
            AudioAnalyzer_RenderProgress w, h
        ELSE
            SELECT CASE __AudioAnalyzer.style
                CASE AUDIOANALYZER_STYLE_OSCILLOSCOPE1
                    AudioAnalyzer_RenderOscilloscope1 w, h, channel

                CASE AUDIOANALYZER_STYLE_OSCILLOSCOPE2
                    AudioAnalyzer_RenderOscilloscope2 w, h, channel

                CASE AUDIOANALYZER_STYLE_VU
                    AudioAnalyzer_RenderVU w, h, channel

                CASE AUDIOANALYZER_STYLE_SPECTRUM
                    AudioAnalyzer_RenderSpectrum w, h, channel

                CASE AUDIOANALYZER_STYLE_CIRCULAR_WAVEFORM
                    AudioAnalyzer_RenderCircularWaveform w, h, channel

                CASE AUDIOANALYZER_STYLE_RADIAL_SPARKS
                    AudioAnalyzer_RenderRadialSparks w, h, channel

                CASE AUDIOANALYZER_STYLE_TESLA_COIL
                    AudioAnalyzer_RenderTeslaCoil w, h, channel

                CASE AUDIOANALYZER_STYLE_CIRCLE_WAVES
                    AudioAnalyzer_RenderCircleWaves w, h, channel

                CASE AUDIOANALYZER_STYLE_STARS
                    AudioAnalyzer_RenderStars w, h, channel

                CASE AUDIOANALYZER_STYLE_BUBBLE_UNIVERSE
                    AudioAnalyzer_RenderBubbleUniverse w, h, channel

                CASE ELSE
                    AudioAnalyzer_RenderProgress w, h
            END SELECT
        END IF
    END IF
END SUB


SUB AudioAnalyzer_Render (l AS LONG, t AS LONG, r AS LONG, b AS LONG, channel AS _UNSIGNED _BYTE)
    SHARED __AudioAnalyzer AS __AudioAnalyzerType

    DIM w AS LONG: w = 1 + r - l
    DIM h AS LONG: h = 1 + b - t

    IF __AudioAnalyzer.viewport = 0 _ORELSE w <> _WIDTH(__AudioAnalyzer.viewport) _ORELSE h <> _HEIGHT(__AudioAnalyzer.viewport) THEN
        IF __AudioAnalyzer.viewport THEN _FREEIMAGE __AudioAnalyzer.viewport
        __AudioAnalyzer.viewport = _NEWIMAGE(w, h, 32)
    END IF

    DIM curDst AS LONG: curDst = _DEST

    _DEST __AudioAnalyzer.viewport

    CLS

    AudioAnalyzer_RenderDirect w, h, channel

    _DEST curDst

    _PUTIMAGE (l, t), __AudioAnalyzer.viewport
END SUB

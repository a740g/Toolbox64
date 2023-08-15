'-----------------------------------------------------------------------------------------------------------------------
' Simple sample-based software synthesizer
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF SOFTSYNTH_BI = UNDEFINED THEN
    $LET SOFTSYNTH_BI = TRUE

    '$INCLUDE:'Common.bi'
    '$INCLUDE:'Types.bi'
    '$INCLUDE:'MathOps.bi'
    '$INCLUDE:'PointerOps.bi'

    CONST SOFTSYNTH_VOICE_PLAY_SINGLE = 0 ' single-shot playback
    CONST SOFTSYNTH_VOICE_PLAY_LOOP = 1 ' forward-looping playback
    CONST SOFTSYNTH_VOICE_VOLUME_MAX = 1 ' this is the maximum volume of any sample
    CONST SOFTSYNTH_VOICE_PAN_LEFT = -1 ' leftmost pannning position
    CONST SOFTSYNTH_VOICE_PAN_RIGHT = 1 ' rightmost pannning position
    CONST SOFTSYNTH_GLOBAL_VOLUME_MAX = 1 ' max global volume
    CONST SOFTSYNTH_BUFFER_TIME = 0.2 ' we will check that we have this amount of time left in the playback buffer
    CONST SOFTSYNTH_DEFAULT_VOLUME_RAMP_DURATION = 0.005 ' 5 ms

    TYPE __SoftSynthType
        voices AS _UNSIGNED _BYTE ' number of mixer voices requested
        samples AS _UNSIGNED _BYTE ' number of samples slots requested
        mixerRate AS LONG ' this is always set by QB64 internal audio engine
        soundHandle AS LONG ' QB64 sound pipe that we will use to stream the mixed audio
        volume AS SINGLE ' global volume (0.0 - 1.0)
        useHQMixer AS _BYTE ' if this is set to true, then we are using linear interpolation mixing
        activeVoices AS _UNSIGNED _BYTE ' just a count of voices we really mixed
        rampFrames AS SINGLE ' the number of frames we can ramp the volume for (this can be changed by the user)
    END TYPE

    TYPE __VoiceType
        sample AS INTEGER ' sample number to be mixed. This is set to -1 once the mixer is done with the sample
        volume AS SINGLE ' voice volume we finally want to get to (0.0 - 1.0)
        rampedVolume AS SINGLE ' this will be ramped to the target volume
        panning AS SINGLE ' position -1.0 is leftmost ... 1.0 is rightmost
        pitch AS SINGLE ' the mixer uses this to step through the sample correctly
        position AS SINGLE ' sample frame position in the sample buffer (updated by pitch)
        playType AS _UNSIGNED _BYTE ' how should the sample be played
        startPosition AS SINGLE ' this can be loop start or just start depending on play type
        endPosition AS SINGLE ' this can be loop end or just end depending on play type
        rampFrame AS SINGLE ' the current frame of __SoftSynthType.rampFrames
        rampStep AS SINGLE ' the amount we need to change the volume with every mix iteration
    END TYPE

    DIM __SoftSynth AS __SoftSynthType ' holds the softsynth state
    REDIM __SampleData(0 TO 0) AS STRING ' sample data array
    REDIM __Voice(0 TO 0) AS __VoiceType ' voice info array
    REDIM __MixerBuffer(0 TO 0) AS SINGLE ' mixer buffer (stereo interleaved)

$END IF

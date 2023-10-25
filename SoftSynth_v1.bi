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

    CONST SOFTSYNTH_VOICE_PLAY_FORWARD = 0 ' single-shot forward playback
    CONST SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP = 1 ' forward-looping playback
    CONST SOFTSYNTH_VOICE_VOLUME_MAX = 1! ' this is the maximum volume of any sample
    CONST SOFTSYNTH_VOICE_PAN_LEFT = -1! ' leftmost pannning position
    CONST SOFTSYNTH_VOICE_PAN_RIGHT = 1! ' rightmost pannning position
    CONST SOFTSYNTH_GLOBAL_VOLUME_MAX = 1! ' max global volume
    CONST SOFTSYNTH_SOUND_BUFFER_CHANNELS = 2 ' 2 channels (stereo)
    CONST SOFTSYNTH_SOUND_BUFFER_SAMPLE_SIZE = SIZE_OF_SINGLE ' 4 bytes (32-bits floating point)
    CONST SOFTSYNTH_SOUND_BUFFER_FRAME_SIZE = SOFTSYNTH_SOUND_BUFFER_SAMPLE_SIZE * SOFTSYNTH_SOUND_BUFFER_CHANNELS
    CONST SOFTSYNTH_SOUND_BUFFER_TIME_DEFAULT = 0.2! ' we will check that we have this amount of time left in the playback buffer

    TYPE __SoftSynthType
        voices AS _UNSIGNED LONG ' number of mixer voices requested
        sounds AS _UNSIGNED LONG ' number of sound slots requested
        sampleRate AS _UNSIGNED LONG ' this is always set by QB64 internal audio engine
        soundHandle AS LONG ' QB64 sound pipe that we will use to stream the mixed audio
        volume AS SINGLE ' global volume (0.0 - 1.0)
        activeVoices AS _UNSIGNED LONG ' just a count of voices we really mixed
        soundBufferFrames AS _UNSIGNED LONG ' size of the render buffer in frames
        soundBufferSamples AS _UNSIGNED LONG ' size of the render buffer in samples
        soundBufferBytes AS _UNSIGNED LONG ' size of the render buffer in bytes
    END TYPE

    TYPE __VoiceType
        snd AS LONG ' sound number to be mixed. This is set to -1 once the mixer is done with the sample
        volume AS SINGLE ' voice volume we finally want to get to (0.0 - 1.0)
        balance AS SINGLE ' position -0.5 is leftmost ... 0.5 is rightmost
        pitch AS SINGLE ' the mixer uses this to step through the sample correctly
        frequency AS _UNSIGNED LONG ' the voice frequency (this is used to calculate the pitch)
        position AS SINGLE ' sample frame position in the sample buffer (updated by pitch)
        startPosition AS _UNSIGNED LONG ' this can be loop start or just start depending on play type (in frames!)
        endPosition AS _UNSIGNED LONG ' this can be loop end or just end depending on play type (in frames!)
        mode AS _UNSIGNED _BYTE ' how should the sample be played
    END TYPE

    DIM __SoftSynth AS __SoftSynthType ' holds the softsynth state
    REDIM __SampleData(0 TO 0) AS STRING ' sample data array
    REDIM __Voice(0 TO 0) AS __VoiceType ' voice info array
    REDIM __SoftSynth_SoundBuffer(0 TO 0) AS SINGLE ' mixer buffer (stereo interleaved)

$END IF

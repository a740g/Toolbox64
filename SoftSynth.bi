'-----------------------------------------------------------------------------------------------------------------------
' Simple sample-based software synthesizer
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF SOFTSYNTH_BI = UNDEFINED THEN
    $LET SOFTSYNTH_BI = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' HEADER FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'PointerOps.bi'
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' CONSTANTS
    '-------------------------------------------------------------------------------------------------------------------
    CONST SAMPLE_MIXER_VOLUME_MAX = 64 ' this is the maximum volume of any sample
    CONST SAMPLE_MIXER_PAN_LEFT = 0 ' leftmost pannning position
    CONST SAMPLE_MIXER_PAN_RIGHT = 255 ' rightmost pannning position
    CONST SAMPLE_MIXER_PAN_CENTER = (SAMPLE_MIXER_PAN_RIGHT - SAMPLE_MIXER_PAN_LEFT) / 2 ' center panning position
    CONST SAMPLE_MIXER_PLAY_SINGLE = 0 ' single-shot playback
    CONST SAMPLE_MIXER_PLAY_LOOP = 1 ' forward-looping playback
    CONST SAMPLE_MIXER_GLOBAL_VOLUME_MAX = 255 ' max global volume
    CONST SAMPLE_MIXER_SOUND_TIME_MIN = 0.2 ' we will check that we have this amount of time left in the playback buffer
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' USER DEFINED TYPES
    '-------------------------------------------------------------------------------------------------------------------
    TYPE __SoftSynthType
        voices AS _UNSIGNED _BYTE ' Number of mixer voices requested
        samples AS _UNSIGNED _BYTE ' Number of samples slots requested
        mixerRate AS LONG ' This is always set by QB64 internal audio engine
        soundHandle AS LONG ' QB64 sound pipe that we will use to stream the mixed audio
        volume AS SINGLE ' Global volume (0 - 255) (fp32)
        useHQMixer AS _BYTE ' If this is set to true, then we are using linear interpolation mixing
        activeVoices AS _UNSIGNED _BYTE ' Just a count of voices we really mixed
    END TYPE

    TYPE __VoiceType
        sample AS INTEGER ' Sample number to be mixed. This is set to -1 once the mixer is done with the sample
        volume AS SINGLE ' Voice volume (0 - 64) (fp32)
        panning AS SINGLE ' Position 0 is leftmost ... 255 is rightmost (fp32)
        pitch AS SINGLE ' Sample pitch. The mixer code uses this to step through the sample correctly (fp32)
        position AS SINGLE ' Where are we in the sample buffer (fp32)
        playType AS _UNSIGNED _BYTE ' How should the sample be played
        startPosition AS SINGLE ' Start poistion. This can be loop start or just start depending on play type
        endPosition AS SINGLE ' End position. This can be loop end or just end depending on play type
    END TYPE
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' GLOBAL VARIABLES
    '-------------------------------------------------------------------------------------------------------------------
    DIM __SoftSynth AS __SoftSynthType
    REDIM __SampleData(0 TO 0) AS STRING ' Sample data array
    REDIM __Voice(0 TO 0) AS __VoiceType ' Voice info array
    REDIM __MixerBufferL(0 TO 0) AS SINGLE ' Left channel mixer buffer
    REDIM __MixerBufferR(0 TO 0) AS SINGLE ' Right channel mixer buffer
    '-------------------------------------------------------------------------------------------------------------------
$END IF
'-----------------------------------------------------------------------------------------------------------------------

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
    CONST SOFTSYNTH_VOICE_PLAY_REVERSE = 3 ' reverse playback
    CONST SOFTSYNTH_VOICE_PLAY_REVERSE_LOOP = 4 ' reverse loop
    CONST SOFTSYNTH_VOICE_PLAY_BIDIRECTIONAL_LOOP = 5 ' BIDI loop
    CONST SOFTSYNTH_VOICE_VOLUME_MAX = 1! ' this is the maximum volume of any sample
    CONST SOFTSYNTH_VOICE_PAN_LEFT = -1! ' leftmost pannning position
    CONST SOFTSYNTH_VOICE_PAN_RIGHT = 1! ' rightmost pannning position
    CONST SOFTSYNTH_GLOBAL_VOLUME_MAX = 1! ' max global volume
    CONST SOFTSYNTH_SOUND_BUFFER_CHANNELS = 2 ' 2 channels (stereo)
    CONST SOFTSYNTH_SOUND_BUFFER_SAMPLE_SIZE = 4 ' 4 bytes (32-bits floating point)
    CONST SOFTSYNTH_SOUND_BUFFER_FRAME_SIZE = SOFTSYNTH_SOUND_BUFFER_SAMPLE_SIZE * SOFTSYNTH_SOUND_BUFFER_CHANNELS
    CONST SOFTSYNTH_SOUND_BUFFER_TIME_DEFAULT = 0.2! ' we will check that we have this amount of time left in the playback buffer

    TYPE __SoftSynthType
        soundBufferFrames AS _UNSIGNED LONG ' size of the render buffer in frames
        soundBufferSamples AS _UNSIGNED LONG ' size of the rendered buffer in samples
        soundBufferBytes AS _UNSIGNED LONG ' size of the render buffer in bytes
        soundHandle AS LONG ' QB64 sound pipe that we will use to stream the mixed audio
    END TYPE

    DECLARE LIBRARY "SoftSynth"
        FUNCTION __SoftSynth_Initialize%% (BYVAL sampleRate AS _UNSIGNED LONG)
        SUB __SoftSynth_Finalize
        FUNCTION SoftSynth_IsInitialized%%
        SUB __SoftSynth_Update (buffer AS SINGLE, BYVAL frames AS _UNSIGNED LONG)
        SUB SoftSynth_SetVoiceVolume (BYVAL voice AS LONG, BYVAL volume AS SINGLE)
        FUNCTION SoftSynth_GetVoiceVolume! (BYVAL voice AS LONG)
        SUB SoftSynth_SetVoiceBalance (BYVAL voice AS LONG, BYVAL balance AS SINGLE)
        FUNCTION SoftSynth_GetVoiceBalance! (BYVAL voice AS LONG)
        SUB SoftSynth_SetVoiceFrequency (BYVAL voice AS LONG, BYVAL frequency AS _UNSIGNED LONG)
        FUNCTION SoftSynth_GetVoiceFrequency~& (BYVAL voice AS LONG)
        SUB SoftSynth_StopVoice (BYVAL voice AS LONG)
        SUB SoftSynth_PlayVoice (BYVAL voice AS LONG, BYVAL snd AS LONG, BYVAL position AS LONG, BYVAL playMode AS LONG, BYVAL startFrame AS LONG, BYVAL endFrame AS LONG)
        SUB SoftSynth_SetGlobalVolume (BYVAL volume AS SINGLE)
        FUNCTION SoftSynth_GetGlobalVolume!
        FUNCTION SoftSynth_GetSampleRate~&
        FUNCTION SoftSynth_GetTotalSounds&
        FUNCTION SoftSynth_GetTotalVoices&
        SUB SoftSynth_SetTotalVoices (BYVAL voices AS LONG)
        FUNCTION SoftSynth_GetActiveVoices&
        SUB SoftSynth_LoadSound (BYVAL snd AS LONG, source AS STRING, BYVAL frames AS LONG, BYVAL bytesPerSample AS LONG, BYVAL channels AS LONG)
        SUB SoftSynth_PeekSoundFrameSingle (BYVAL snd AS LONG, BYVAL position AS LONG, L AS SINGLE, R AS SINGLE)
        SUB SoftSynth_PokeSoundFrameSingle (BYVAL snd AS LONG, BYVAL position AS LONG, BYVAL L AS SINGLE, BYVAL R AS SINGLE)
        SUB SoftSynth_PeekSoundFrameInteger (BYVAL snd AS LONG, BYVAL position AS LONG, L AS INTEGER, R AS INTEGER)
        SUB SoftSynth_PokeSoundFrameInteger (BYVAL snd AS LONG, BYVAL position AS LONG, BYVAL L AS INTEGER, BYVAL R AS INTEGER)
        SUB SoftSynth_PeekSoundFrameByte (BYVAL snd AS LONG, BYVAL position AS LONG, L AS _BYTE, R AS _BYTE)
        SUB SoftSynth_PokeSoundFrameByte (BYVAL snd AS LONG, BYVAL position AS LONG, BYVAL L AS _BYTE, BYVAL R AS _BYTE)
        FUNCTION SoftSynth_BytesToFrames& (BYVAL bytes AS LONG, BYVAL bytesPerSample AS LONG, BYVAL channels AS LONG)
    END DECLARE

    DIM __SoftSynth AS __SoftSynthType ' holds the softsynth state
    REDIM __SoftSynth_SoundBuffer(0 TO 0) AS SINGLE ' mixer buffer (stereo interleaved)

$END IF

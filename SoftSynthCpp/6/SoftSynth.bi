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
    CONST SOFTSYNTH_SOUND_BUFFER_SAMPLE_SIZE = SIZE_OF_SINGLE ' 4 bytes (32-bits floating point)
    CONST SOFTSYNTH_SOUND_BUFFER_FRAME_SIZE = SOFTSYNTH_SOUND_BUFFER_SAMPLE_SIZE * SOFTSYNTH_SOUND_BUFFER_CHANNELS
    CONST SOFTSYNTH_SOUND_BUFFER_TIME_DEFAULT = 0.2! ' we will check that we have this amount of time left in the playback buffer

    TYPE __SoftSynthType
        soundBufferFrames AS _UNSIGNED LONG ' size of the render buffer in frames
        soundBufferSamples AS _UNSIGNED LONG ' size of the render buffer in samples
        soundBufferBytes AS _UNSIGNED LONG ' size of the render buffer in bytes
        soundHandle AS LONG ' QB64 sound pipe that we will use to stream the mixed audio
    END TYPE

    DECLARE LIBRARY "SoftSynth"
        FUNCTION SoftSynth_BytesToFrames~& (BYVAL bytes AS _UNSIGNED LONG, BYVAL bytesPerSample AS _UNSIGNED _BYTE, BYVAL channels AS _UNSIGNED _BYTE)
        SUB __SoftSynth_ConvertU8ToS8 (buffer AS STRING, BYVAL frames AS _UNSIGNED LONG)
        FUNCTION __SoftSynth_Initialize%% (BYVAL sampleRate AS _UNSIGNED LONG)
        SUB __SoftSynth_Finalize
        FUNCTION SoftSynth_IsInitialized%%
        SUB __SoftSynth_Update (buffer AS SINGLE, BYVAL frames AS _UNSIGNED LONG)
        SUB SoftSynth_SetVoiceVolume (BYVAL voice AS _UNSIGNED LONG, BYVAL volume AS SINGLE)
        FUNCTION SoftSynth_GetVoiceVolume! (BYVAL voice AS _UNSIGNED LONG)
        SUB SoftSynth_SetVoiceBalance (BYVAL voice AS _UNSIGNED LONG, BYVAL balance AS SINGLE)
        FUNCTION SoftSynth_GetVoiceBalance! (BYVAL voice AS _UNSIGNED LONG)
        SUB SoftSynth_SetVoiceFrequency (BYVAL voice AS _UNSIGNED LONG, BYVAL frequency AS _UNSIGNED LONG)
        FUNCTION SoftSynth_GetVoiceFrequency~& (BYVAL voice AS _UNSIGNED LONG)
        SUB SoftSynth_StopVoice (BYVAL voice AS _UNSIGNED LONG)
        SUB SoftSynth_PlayVoice (BYVAL voice AS _UNSIGNED LONG, BYVAL snd AS LONG, BYVAL position AS _UNSIGNED LONG, BYVAL mode AS LONG, BYVAL startFrame AS _UNSIGNED LONG, BYVAL endFrame AS _UNSIGNED LONG)
        SUB SoftSynth_SetGlobalVolume (BYVAL volume AS SINGLE)
        FUNCTION SoftSynth_GetGlobalVolume!
        FUNCTION SoftSynth_GetSampleRate~&
        FUNCTION SoftSynth_GetTotalSounds~&
        FUNCTION SoftSynth_GetTotalVoices~&
        SUB SoftSynth_SetTotalVoices (BYVAL voices AS _UNSIGNED LONG)
        FUNCTION SoftSynth_GetActiveVoices~&
        SUB __SoftSynth_LoadSound (BYVAL snd AS LONG, buffer AS STRING, BYVAL bytes AS _UNSIGNED LONG, BYVAL bytesPerSample AS _UNSIGNED _BYTE, BYVAL channels AS _UNSIGNED _BYTE)
        FUNCTION SoftSynth_PeekSoundFrameSingle! (BYVAL snd AS LONG, BYVAL position AS _UNSIGNED LONG)
        SUB SoftSynth_PokeSoundFrameSingle (BYVAL snd AS LONG, BYVAL position AS _UNSIGNED LONG, BYVAL frame AS SINGLE)
        FUNCTION SoftSynth_PeekSoundFrameInteger% (BYVAL snd AS LONG, BYVAL position AS _UNSIGNED LONG)
        SUB SoftSynth_PokeSoundFrameInteger (BYVAL snd AS LONG, BYVAL position AS _UNSIGNED LONG, BYVAL frame AS INTEGER)
        FUNCTION SoftSynth_PeekSoundFrameByte%% (BYVAL snd AS LONG, BYVAL position AS _UNSIGNED LONG)
        SUB SoftSynth_PokeSoundFrameByte (BYVAL snd AS LONG, BYVAL position AS _UNSIGNED LONG, BYVAL frame AS _BYTE)
    END DECLARE

    DIM __SoftSynth AS __SoftSynthType ' holds the softsynth state
    REDIM __SoftSynth_SoundBuffer(0 TO 0) AS SINGLE ' mixer buffer (stereo interleaved)

$END IF

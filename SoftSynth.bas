'-----------------------------------------------------------------------------------------------------------------------
' Simple sample-based software synthesizer
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF SOFTSYNTH_BAS = UNDEFINED THEN
    $LET SOFTSYNTH_BAS = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' HEADER FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'SoftSynth.bi'
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
    ' Initialize the sample mixer
    ' This allocates all required resources
    SUB SampleMixer_Initialize (nVoices AS _UNSIGNED _BYTE)
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __Voice() AS __VoiceType

        ' Save the number of voices
        __SoftSynth.voices = nVoices

        ' Resize the voice array
        REDIM __Voice(0 TO nVoices - 1) AS __VoiceType

        ' Set the mix rate to match that of the system
        __SoftSynth.mixerRate = _SNDRATE

        ' Allocate a QB64 sound pipe
        __SoftSynth.soundHandle = _SNDOPENRAW

        ' Reset the global volume
        __SoftSynth.volume = SAMPLE_MIXER_GLOBAL_VOLUME_MAX

        DIM i AS _UNSIGNED _BYTE

        ' Set all voice defaults
        FOR i = 0 TO nVoices - 1
            __Voice(i).sample = -1
            __Voice(i).volume = SAMPLE_MIXER_VOLUME_MAX
            __Voice(i).panning = SAMPLE_MIXER_PAN_CENTER
            __Voice(i).pitch = 0
            __Voice(i).position = 0
            __Voice(i).playType = SAMPLE_MIXER_PLAY_SINGLE
            __Voice(i).startPosition = 0
            __Voice(i).endPosition = 0
        NEXT
    END SUB


    ' This initialized the sample manager
    ' All previous samples will be lost!
    SUB SampleManager_Initialize (nSamples AS _UNSIGNED _BYTE)
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __SampleData() AS STRING

        ' Save the number of samples
        __SoftSynth.samples = nSamples

        ' Resize the sample data array
        REDIM __SampleData(0 TO nSamples - 1) AS STRING
    END SUB


    ' Close the mixer - free all allocated resources
    SUB SampleMixer_Finalize
        SHARED __SoftSynth AS __SoftSynthType

        _SNDRAWDONE __SoftSynth.soundHandle ' Sumbit whatever is remaining in the raw buffer for playback
        _SNDCLOSE __SoftSynth.soundHandle ' Close QB64 sound pipe
    END SUB


    ' Returns true if more samples needs to be mixed
    FUNCTION SampleMixer_NeedsUpdate%%
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SampleMixer_NeedsUpdate = (_SNDRAWLEN(__SoftSynth.soundHandle) < SAMPLE_MIXER_SOUND_TIME_MIN)
        $CHECKING:ON
    END FUNCTION


    ' This should be called by code using the mixer at regular intervals
    ' All mixing calculations are done using floating-point math (it's 2022 :)
    SUB SampleMixer_Update (nSamples AS _UNSIGNED INTEGER)
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __SampleData() AS STRING
        SHARED __Voice() AS __VoiceType
        SHARED __MixerBufferL() AS SINGLE
        SHARED __MixerBufferR() AS SINGLE

        DIM AS LONG v, s, nSample, nPos, nPlayType, sLen
        DIM AS SINGLE fVolume, fPan, fPitch, fPos, fStartPos, fEndPos, fSam
        DIM AS _BYTE bSam1, bSam2

        ' Reallocate the mixer buffers that will hold sample data for both channels
        ' This is conveniently zeroed by QB64, so that is nice. We don't have to do it
        ' Here 0 is the left channnel and 1 is the right channel
        REDIM __MixerBufferL(0 TO nSamples - 1) AS SINGLE
        REDIM __MixerBufferR(0 TO nSamples - 1) AS SINGLE

        ' Set the active voice count to zero
        __SoftSynth.activeVoices = 0

        ' We will iterate through each channel completely rather than jumping from channel to channel
        ' We are doing this because it is easier for the CPU to access adjacent memory rather than something far away
        ' Also because we do not have to fetch stuff from multiple arrays too many times
        FOR v = 0 TO __SoftSynth.voices - 1
            nSample = __Voice(v).sample
            ' Only proceed if we have a valid sample number (>= 0)
            IF nSample >= 0 THEN
                ' Increment the active voices
                __SoftSynth.activeVoices = __SoftSynth.activeVoices + 1

                ' Get some values we need frequently during the mixing interation below
                ' Note that these do not change at all during the mixing process
                fVolume = __Voice(v).volume
                fPan = __Voice(v).panning
                fPitch = __Voice(v).pitch
                nPlayType = __Voice(v).playType
                fStartPos = __Voice(v).startPosition
                fEndPos = __Voice(v).endPosition
                sLen = LEN(__SampleData(nSample)) ' real sample length

                ' Next we go through the channel sample data and mix it to our mixerBuffer
                FOR s = 0 TO nSamples - 1
                    ' We need these too many times
                    ' And this is inside the loop because "position" changes
                    fPos = __Voice(v).position

                    ' Check if we are looping
                    IF nPlayType = SAMPLE_MIXER_PLAY_SINGLE THEN
                        ' For non-looping sample simply set the isplayed flag as false if we reached the end
                        IF fPos >= fEndPos THEN
                            SampleMixer_StopVoice v
                            ' Exit the for mixing loop as we have no more samples to mix for this channel
                            EXIT FOR
                        END IF
                    ELSE
                        ' Reset loop position if we reached the end of the loop
                        IF fPos >= fEndPos THEN
                            fPos = fStartPos
                        END IF
                    END IF

                    ' We don't want anything below 0
                    IF fPos < 0 THEN fPos = 0

                    ' Samples are stored in a string and strings are 1 based
                    IF __SoftSynth.useHQMixer AND fPos + 2 <= sLen THEN
                        ' Apply interpolation
                        nPos = FIX(fPos)
                        bSam1 = PeekStringByte(__SampleData(nSample), nPos)
                        bSam2 = PeekStringByte(__SampleData(nSample), 1 + nPos)
                        fSam = bSam1 + (bSam2 - bSam1) * (fPos - nPos)
                    ELSE
                        IF fPos + 1 <= sLen THEN
                            bSam1 = PeekStringByte(__SampleData(nSample), fPos)
                            fSam = bSam1
                        ELSE
                            fSam = 0
                        END IF
                    END IF

                    ' The following two lines mixes the sample and also does volume & stereo panning
                    ' The below expressions were simplified and rearranged to reduce the number of divisions. Divisions are slow
                    __MixerBufferL(s) = __MixerBufferL(s) + (fSam * fVolume * (SAMPLE_MIXER_PAN_RIGHT - fPan)) / (SAMPLE_MIXER_PAN_RIGHT * SAMPLE_MIXER_VOLUME_MAX)
                    __MixerBufferR(s) = __MixerBufferR(s) + (fSam * fVolume * fPan) / (SAMPLE_MIXER_PAN_RIGHT * SAMPLE_MIXER_VOLUME_MAX)

                    ' Move to the next sample position based on the pitch
                    __Voice(v).position = fPos + fPitch
                NEXT
            END IF
        NEXT

        ' Feed the samples to the QB64 sound pipe
        FOR s = 0 TO nSamples - 1
            ' Apply global volume and scale sample to FP32 sample spec.
            fSam = __SoftSynth.volume / (128 * SAMPLE_MIXER_GLOBAL_VOLUME_MAX)
            __MixerBufferL(s) = __MixerBufferL(s) * fSam
            __MixerBufferR(s) = __MixerBufferR(s) * fSam

            ' We do not clip samples anymore because miniaudio does that for us. It makes no sense to clip samples twice
            ' Obviously, this means that the quality of OpenAL version will suffer. But that's ok, it is on it's way to sunset :)

            ' Feed the samples to the QB64 sound pipe
            _SNDRAW __MixerBufferL(s), __MixerBufferR(s), __SoftSynth.soundHandle
        NEXT
        $CHECKING:ON
    END SUB


    ' Stores a sample in the sample data array. This will add some silence samples at the end
    ' If the sample is looping then it will anti-click by copying a couple of samples from the beginning to the end of the loop
    SUB SampleManager_Load (nSample AS _UNSIGNED _BYTE, sData AS STRING, isLooping AS _BYTE, nLoopStart AS LONG, nLoopEnd AS LONG)
        SHARED __SampleData() AS STRING

        DIM i AS LONG
        IF nLoopEnd >= LEN(sData) THEN i = 32 + nLoopEnd - LEN(sData) ELSE i = 32 ' We allocate 32 samples extra (minimum)
        __SampleData(nSample) = sData + STRING$(i, NULL)

        ' If the sample is looping then make it anti-click by copying a few samples from loop start to loop end
        IF isLooping THEN
            ' We'll just copy 4 samples
            FOR i = 1 TO 4
                ASC(__SampleData(nSample), nLoopEnd + i) = ASC(__SampleData(nSample), nLoopStart + i)
            NEXT
        END IF
    END SUB


    ' Get a sample value for a sample from position
    FUNCTION SampleManager_Peek%% (nSample AS _UNSIGNED _BYTE, nPosition AS LONG)
        $CHECKING:OFF
        SHARED __SampleData() AS STRING

        SampleManager_Peek = PeekStringByte(__SampleData(nSample), nPosition)
        $CHECKING:ON
    END FUNCTION


    ' Writes a sample value to a sample at position
    SUB SampleManager_Poke (nSample AS _UNSIGNED _BYTE, nPosition AS LONG, nValue AS _BYTE)
        $CHECKING:OFF
        SHARED __SampleData() AS STRING

        PokeStringByte __SampleData(nSample), nPosition, nValue
        $CHECKING:ON
    END SUB


    ' Set the volume for a voice (0 - 64)
    SUB SampleMixer_SetVoiceVolume (nVoice AS _UNSIGNED _BYTE, nVolume AS SINGLE)
        $CHECKING:OFF
        SHARED __Voice() AS __VoiceType

        IF nVolume < 0 THEN
            __Voice(nVoice).volume = 0
        ELSEIF nVolume > SAMPLE_MIXER_VOLUME_MAX THEN
            __Voice(nVoice).volume = SAMPLE_MIXER_VOLUME_MAX
        ELSE
            __Voice(nVoice).volume = nVolume
        END IF
        $CHECKING:ON
    END SUB


    ' Set panning for a voice (0 - 255)
    SUB SampleMixer_SetVoicePanning (nVoice AS _UNSIGNED _BYTE, nPanning AS SINGLE)
        $CHECKING:OFF
        SHARED __Voice() AS __VoiceType

        IF nPanning < SAMPLE_MIXER_PAN_LEFT THEN
            __Voice(nVoice).panning = SAMPLE_MIXER_PAN_LEFT
        ELSEIF nPanning > SAMPLE_MIXER_PAN_RIGHT THEN
            __Voice(nVoice).panning = SAMPLE_MIXER_PAN_RIGHT
        ELSE
            __Voice(nVoice).panning = nPanning
        END IF
        $CHECKING:ON
    END SUB


    ' Set a frequency for a voice
    ' This will be responsible for correctly setting the mixer sample pitch
    SUB SampleMixer_SetVoiceFrequency (nVoice AS _UNSIGNED _BYTE, nFrequency AS SINGLE)
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __Voice() AS __VoiceType

        __Voice(nVoice).pitch = nFrequency / __SoftSynth.mixerRate
        $CHECKING:ON
    END SUB


    ' Stops playback for a voice
    SUB SampleMixer_StopVoice (nVoice AS _UNSIGNED _BYTE)
        $CHECKING:OFF
        SHARED __Voice() AS __VoiceType

        __Voice(nVoice).sample = -1
        __Voice(nVoice).volume = SAMPLE_MIXER_VOLUME_MAX
        ' __Voice(nVoice).panning is intentionally left out to respect the pan positions set by the loader
        __Voice(nVoice).pitch = 0
        __Voice(nVoice).position = 0
        __Voice(nVoice).playType = SAMPLE_MIXER_PLAY_SINGLE
        __Voice(nVoice).startPosition = 0
        __Voice(nVoice).endPosition = 0
        $CHECKING:ON
    END SUB


    ' Starts playback of a sample
    ' This can be used to playback a sample from a particular offset or loop the sample
    SUB SampleMixer_PlayVoice (nVoice AS _UNSIGNED _BYTE, nSample AS _UNSIGNED _BYTE, nPosition AS SINGLE, nPlayType AS _UNSIGNED _BYTE, nStart AS SINGLE, nEnd AS SINGLE)
        $CHECKING:OFF
        SHARED __Voice() AS __VoiceType

        __Voice(nVoice).sample = nSample
        __Voice(nVoice).position = nPosition
        __Voice(nVoice).playType = nPlayType
        __Voice(nVoice).startPosition = nStart
        __Voice(nVoice).endPosition = nEnd
        $CHECKING:ON
    END SUB


    ' Set the global volume for a voice (0 - 255)
    SUB SampleMixer_SetGlobalVolume (nVolume AS SINGLE)
        SHARED __SoftSynth AS __SoftSynthType

        IF nVolume < 0 THEN
            __SoftSynth.volume = 0
        ELSEIF nVolume > SAMPLE_MIXER_GLOBAL_VOLUME_MAX THEN
            __SoftSynth.volume = SAMPLE_MIXER_GLOBAL_VOLUME_MAX
        ELSE
            __SoftSynth.volume = nVolume
        END IF
    END SUB


    ' Returns the global volume
    FUNCTION SampleMixer_GetGlobalVolume!
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SampleMixer_GetGlobalVolume = __SoftSynth.volume
        $CHECKING:ON
    END FUNCTION


    ' Enables or disable HQ mixer
    SUB SampleMixer_SetHighQuality (nFlag AS _BYTE)
        SHARED __SoftSynth AS __SoftSynthType

        __SoftSynth.useHQMixer = (nFlag <> FALSE) ' This will accept all kinds of garbage :)
    END SUB


    ' Returns the HQ mixer quality setting
    FUNCTION SampleMixer_IsHighQuality%%
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SampleMixer_IsHighQuality = __SoftSynth.useHQMixer
        $CHECKING:ON
    END FUNCTION


    ' Returns the total voices
    FUNCTION SampleMixer_GetTotalVoices~%%
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SampleMixer_GetTotalVoices = __SoftSynth.voices
        $CHECKING:ON
    END FUNCTION


    ' Returns the active voices
    FUNCTION SampleMixer_GetActiveVoices~%%
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SampleMixer_GetActiveVoices = __SoftSynth.activeVoices
        $CHECKING:ON
    END FUNCTION


    ' Returns the total voices
    FUNCTION SampleMixer_GetTotalSamples~%%
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SampleMixer_GetTotalSamples = __SoftSynth.samples
        $CHECKING:ON
    END FUNCTION


    ' Returns the amount of buffered sample time remaining to be played
    FUNCTION SampleMixer_GetBufferedSoundTime#
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SampleMixer_GetBufferedSoundTime = _SNDRAWLEN(__SoftSynth.soundHandle)
        $CHECKING:ON
    END FUNCTION


    ' Returns the sample rate of the sample mixer
    FUNCTION SampleMixer_GetSampleRate&
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SampleMixer_GetSampleRate = __SoftSynth.mixerRate
        $CHECKING:ON
    END FUNCTION
    '-------------------------------------------------------------------------------------------------------------------
$END IF
'-----------------------------------------------------------------------------------------------------------------------

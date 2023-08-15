'-----------------------------------------------------------------------------------------------------------------------
' Simple sample-based software synthesizer
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF SOFTSYNTH_BAS = UNDEFINED THEN
    $LET SOFTSYNTH_BAS = TRUE

    '$INCLUDE:'SoftSynth.bi'

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


    ' Initialize the sample mixer
    ' This allocates all required resources
    SUB SampleMixer_Initialize (nVoices AS _UNSIGNED _BYTE)
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __Voice() AS __VoiceType

        ' Cleanup and re-initialize if have already initialized
        IF SampleMixer_IsInitialized THEN SampleMixer_Finalize

        ' Save the number of voices
        __SoftSynth.voices = nVoices

        ' Resize the voice array
        REDIM __Voice(0 TO nVoices - 1) AS __VoiceType

        ' Set the mix rate to match that of the system
        __SoftSynth.mixerRate = _SNDRATE

        ' Allocate a QB64 sound pipe
        __SoftSynth.soundHandle = _SNDOPENRAW

        ' Reset the global volume
        __SoftSynth.volume = SOFTSYNTH_GLOBAL_VOLUME_MAX

        ' Set the default ramp frames
        __SoftSynth.rampFrames = __SoftSynth.mixerRate * SOFTSYNTH_DEFAULT_VOLUME_RAMP_DURATION

        DIM i AS _UNSIGNED _BYTE

        ' Set all voice defaults
        FOR i = 0 TO nVoices - 1
            __Voice(i).sample = -1
            __Voice(i).volume = SOFTSYNTH_VOICE_VOLUME_MAX
            __Voice(i).rampedVolume = 0
            __Voice(i).panning = 0 ' center
            __Voice(i).pitch = 0
            __Voice(i).position = 0
            __Voice(i).playType = SOFTSYNTH_VOICE_PLAY_SINGLE
            __Voice(i).startPosition = 0
            __Voice(i).endPosition = 0
            __Voice(i).rampFrame = 0
            __Voice(i).rampStep = 0 ' this is calculated once per mix frame in Update()
        NEXT
    END SUB


    ' Close the mixer - free all allocated resources
    SUB SampleMixer_Finalize
        SHARED __SoftSynth AS __SoftSynthType

        _SNDRAWDONE __SoftSynth.soundHandle ' Sumbit whatever is remaining in the raw buffer for playback
        _SNDCLOSE __SoftSynth.soundHandle ' Close QB64 sound pipe
        __SoftSynth.soundHandle = 0 ' reset the value
    END SUB


    ' Returns true if the mixer was correctly initialized
    FUNCTION SampleMixer_IsInitialized%%
        SHARED __SoftSynth AS __SoftSynthType

        SampleMixer_IsInitialized = __SoftSynth.soundHandle > 0 ' return true only if the raw sound pipe was allocated
    END FUNCTION


    ' Returns true if more samples needs to be mixed
    FUNCTION SampleMixer_NeedsUpdate%%
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SampleMixer_NeedsUpdate = _SNDRAWLEN(__SoftSynth.soundHandle) < SOFTSYNTH_BUFFER_TIME
        $CHECKING:ON
    END FUNCTION


    ' This should be called by code using the mixer at regular intervals
    ' All mixing calculations are done using floating-point math (it's 2022 :)
    SUB SampleMixer_Update (nSamples AS _UNSIGNED INTEGER)
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __SampleData() AS STRING
        SHARED __Voice() AS __VoiceType
        SHARED __MixerBuffer() AS SINGLE

        DIM AS LONG v, s, i, nSample, nPos, nPlayType, sLen
        DIM AS SINGLE fVolume, fPan, fPitch, fPos, fStartPos, fEndPos, fSamp

        ' Reallocate the mixer buffer that will hold the mixed sample data for both channels
        ' This is conveniently zeroed by QB64, so that is nice. We don't have to do it
        REDIM __MixerBuffer(0 TO nSamples * 2 - 1) AS SINGLE ' * 2 for stereo, - 1 since we are zero based

        ' Set the active voice count to zero
        __SoftSynth.activeVoices = 0

        ' We will iterate through each channel completely rather than jumping from channel to channel
        ' We are doing this because it is easier for the CPU to access adjacent memory rather than something far away
        ' Also because we do not have to fetch stuff from multiple arrays too many times
        v = 0
        DO WHILE v < __SoftSynth.voices
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
                sLen = LEN(__SampleData(nSample)) \ SIZE_OF_SINGLE ' real sample frames
                __Voice(v).rampStep = __Voice(v).volume / __SoftSynth.rampFrames ' recalculate the rampstep just in case volume has changed

                ' Next we go through the channel sample data and mix it to our mixerBuffer
                s = 0: i = 0
                DO WHILE s < nSamples
                    ' We need these too many times
                    ' And this is inside the loop because "position" changes
                    fPos = __Voice(v).position

                    ' Check if we are looping
                    IF nPlayType = SOFTSYNTH_VOICE_PLAY_SINGLE THEN
                        ' For non-looping sample simply stop playing if we reached the end
                        IF fPos >= fEndPos THEN
                            SampleMixer_StopVoice v
                            EXIT DO ' exit the mixing loop as we have no more samples to mix for this channel
                        END IF
                    ELSE
                        ' Reset loop position if we reached the end of the loop
                        IF fPos >= fEndPos THEN
                            fPos = fStartPos
                        END IF
                    END IF

                    ' We don't want anything below 0
                    IF fPos < 0 THEN fPos = 0

                    ' Fetch the sample frame that we need (optionally applying interpolation)
                    IF __SoftSynth.useHQMixer AND fPos + 1 < sLen THEN
                        ' Apply interpolation
                        nPos = FIX(fPos)
                        fSamp = PeekStringSingle(__SampleData(nSample), nPos)
                        fSamp = fSamp + (PeekStringSingle(__SampleData(nSample), 1 + nPos) - fSamp) * (fPos - nPos)
                    ELSEIF fPos < sLen THEN
                        fSamp = PeekStringSingle(__SampleData(nSample), fPos)
                    ELSE
                        fSamp = 0
                    END IF

                    ' Do volume ramping
                    IF __Voice(v).rampFrame < __SoftSynth.rampFrames THEN
                        __Voice(v).rampedVolume = __Voice(v).rampedVolume + __Voice(v).rampStep
                        __Voice(v).rampFrame = __Voice(v).rampFrame + 1 ' increment the ramp frame count
                        fVolume = __Voice(v).rampedVolume
                    END IF

                    ' Move to the next sample position based on the pitch
                    __Voice(v).position = fPos + fPitch

                    ' The following lines mixes the sample and also does volume & stereo panning
                    __MixerBuffer(i) = __MixerBuffer(i) + (fSamp * fVolume * (SOFTSYNTH_VOICE_PAN_RIGHT - fPan)) ' prevsamp = prevsamp + newsamp * vol * (1.0 - pan)
                    i = i + 1
                    __MixerBuffer(i) = __MixerBuffer(i) + (fSamp * fVolume * (SOFTSYNTH_VOICE_PAN_RIGHT + fPan)) ' prevsamp = prevsamp + newsamp * vol * (1.0 + pan)
                    i = i + 1

                    s = s + 1
                LOOP
            END IF

            v = v + 1
        LOOP

        ' Feed the samples to the QB64 sound pipe
        i = 0: s = nSamples * 2
        DO WHILE i < s
            ' Apply global volume
            __MixerBuffer(i) = __MixerBuffer(i) * __SoftSynth.volume ' left channel
            __MixerBuffer(i + 1) = __MixerBuffer(i + 1) * __SoftSynth.volume ' right channel

            ' Feed the samples to the QB64 sound pipe
            _SNDRAW __MixerBuffer(i), __MixerBuffer(i + 1), __SoftSynth.soundHandle

            i = i + 2
        LOOP
        $CHECKING:ON
    END SUB


    ' Stores a sample in the sample data array. This will add some silence samples at the end
    ' If the sample is looping then it will anti-click by copying a couple of samples from the beginning to the end of the loop
    ' The sample is always converted to 32-bit floating point format
    ' Loop start and loop end are in sample frames (not bytes)
    SUB SampleManager_Load (nSample AS _UNSIGNED _BYTE, sData AS STRING, nSampleFrameSize AS _UNSIGNED _BYTE, isLooping AS _BYTE, nLoopStart AS LONG, nLoopEnd AS LONG)
        SHARED __SampleData() AS STRING

        DIM sampleFrames AS LONG: sampleFrames = LEN(sData) \ nSampleFrameSize

        DIM i AS LONG
        IF nLoopEnd >= sampleFrames THEN i = 32 + nLoopEnd - sampleFrames ELSE i = 32 ' we'll allocate 32 samples extra (minimum)
        __SampleData(nSample) = STRING$((sampleFrames + i) * SIZE_OF_SINGLE, NULL) ' allocate memory for the to-be converted sample

        SELECT CASE nSampleFrameSize
            CASE SIZE_OF_BYTE ' 8-bit
                FOR i = 0 TO sampleFrames - 1
                    PokeStringSingle __SampleData(nSample), i, PeekStringByte(sData, i) / 128
                NEXT

            CASE SIZE_OF_INTEGER ' 16-bit
                FOR i = 0 TO sampleFrames - 1
                    PokeStringSingle __SampleData(nSample), i, PeekStringInteger(sData, i) / 32768
                NEXT

            CASE SIZE_OF_SINGLE ' 32-bit
                FOR i = 0 TO sampleFrames - 1
                    PokeStringSingle __SampleData(nSample), i, ClampSingle(PeekStringSingle(sData, i), -1, 1)
                NEXT

            CASE ELSE ' nothing else is supported
                ERROR ERROR_ILLEGAL_FUNCTION_CALL
        END SELECT

        ' If the sample is looping then make it anti-click by copying a few samples from loop start to loop end
        IF isLooping THEN
            ' We'll just copy 4 samples
            FOR i = 0 TO 3
                PokeStringSingle __SampleData(nSample), nLoopEnd + i, PeekStringSingle(__SampleData(nSample), nLoopStart + i)
            NEXT
        END IF
    END SUB


    ' Get a sample value for a sample from position (in sample frames)
    FUNCTION SampleManager_PeekByte%% (nSample AS _UNSIGNED _BYTE, nPosition AS LONG)
        $CHECKING:OFF
        SHARED __SampleData() AS STRING

        SampleManager_PeekByte = PeekStringSingle(__SampleData(nSample), nPosition) * 128
        $CHECKING:ON
    END FUNCTION


    ' Writes a sample value to a sample at position (in sample frames)
    SUB SampleManager_PokeByte (nSample AS _UNSIGNED _BYTE, nPosition AS LONG, nValue AS _BYTE)
        $CHECKING:OFF
        SHARED __SampleData() AS STRING

        PokeStringSingle __SampleData(nSample), nPosition, nValue / 128
        $CHECKING:ON
    END SUB


    ' Get a sample value for a sample from position (in sample frames)
    FUNCTION SampleManager_PeekInteger% (nSample AS _UNSIGNED _BYTE, nPosition AS LONG)
        $CHECKING:OFF
        SHARED __SampleData() AS STRING

        SampleManager_PeekInteger = PeekStringSingle(__SampleData(nSample), nPosition) * 32768
        $CHECKING:ON
    END FUNCTION


    ' Writes a sample value to a sample at position (in sample frames)
    SUB SampleManager_PokeInteger (nSample AS _UNSIGNED _BYTE, nPosition AS LONG, nValue AS INTEGER)
        $CHECKING:OFF
        SHARED __SampleData() AS STRING

        PokeStringSingle __SampleData(nSample), nPosition, nValue / 32768
        $CHECKING:ON
    END SUB


    ' Get a sample value for a sample from position (in sample frames)
    FUNCTION SampleManager_PeekSingle! (nSample AS _UNSIGNED _BYTE, nPosition AS LONG)
        $CHECKING:OFF
        SHARED __SampleData() AS STRING

        SampleManager_PeekSingle = PeekStringSingle(__SampleData(nSample), nPosition)
        $CHECKING:ON
    END FUNCTION


    ' Writes a sample value to a sample at position (in sample frames)
    SUB SampleManager_PokeSingle (nSample AS _UNSIGNED _BYTE, nPosition AS LONG, nValue AS SINGLE)
        $CHECKING:OFF
        SHARED __SampleData() AS STRING

        PokeStringSingle __SampleData(nSample), nPosition, nValue
        $CHECKING:ON
    END SUB


    ' Set the volume for a voice
    SUB SampleMixer_SetVoiceVolume (nVoice AS _UNSIGNED _BYTE, nVolume AS SINGLE)
        $CHECKING:OFF
        SHARED __Voice() AS __VoiceType

        __Voice(nVoice).volume = ClampSingle(nVolume, 0, SOFTSYNTH_VOICE_VOLUME_MAX)
        $CHECKING:ON
    END SUB


    ' Get the volume for a voice
    FUNCTION SampleMixer_GetVoiceVolume! (nVoice AS _UNSIGNED _BYTE)
        $CHECKING:OFF
        SHARED __Voice() AS __VoiceType

        SampleMixer_GetVoiceVolume = __Voice(nVoice).volume
        $CHECKING:ON
    END FUNCTION


    ' Set panning for a voice
    SUB SampleMixer_SetVoicePanning (nVoice AS _UNSIGNED _BYTE, nPanning AS SINGLE)
        $CHECKING:OFF
        SHARED __Voice() AS __VoiceType

        __Voice(nVoice).panning = ClampSingle(nPanning, SOFTSYNTH_VOICE_PAN_LEFT, SOFTSYNTH_VOICE_PAN_RIGHT)
        $CHECKING:ON
    END SUB


    ' Get panning for a voice
    FUNCTION SampleMixer_GetVoicePanning! (nVoice AS _UNSIGNED _BYTE)
        $CHECKING:OFF
        SHARED __Voice() AS __VoiceType

        SampleMixer_GetVoicePanning = __Voice(nVoice).panning
        $CHECKING:ON
    END FUNCTION


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
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __Voice() AS __VoiceType

        __Voice(nVoice).sample = -1
        __Voice(nVoice).volume = SOFTSYNTH_VOICE_VOLUME_MAX
        __Voice(nVoice).rampedVolume = 0
        ' __Voice(nVoice).panning is intentionally left out to respect the pan positions set initially by the loader
        __Voice(nVoice).pitch = 0
        __Voice(nVoice).position = 0
        __Voice(nVoice).playType = SOFTSYNTH_VOICE_PLAY_SINGLE
        __Voice(nVoice).startPosition = 0
        __Voice(nVoice).endPosition = 0
        __Voice(nVoice).rampFrame = 0
        __Voice(nVoice).rampStep = 0 ' this is calculated once per mix frame in Update()
        $CHECKING:ON
    END SUB


    ' Starts playback of a sample
    ' This can be used to playback a sample from a particular offset or loop the sample
    ' All sample position and length values are in sample frames (not bytes)
    SUB SampleMixer_PlayVoice (nVoice AS _UNSIGNED _BYTE, nSample AS _UNSIGNED _BYTE, nPosition AS SINGLE, nPlayType AS _UNSIGNED _BYTE, nStart AS SINGLE, nEnd AS SINGLE)
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __Voice() AS __VoiceType

        __Voice(nVoice).sample = nSample
        __Voice(nVoice).position = nPosition
        __Voice(nVoice).playType = nPlayType
        __Voice(nVoice).startPosition = nStart
        __Voice(nVoice).endPosition = nEnd
        __Voice(nVoice).rampedVolume = 0
        __Voice(nVoice).rampFrame = 0
        __Voice(nVoice).rampStep = 0 ' this is calculated once per mix frame in Update()
        $CHECKING:ON
    END SUB


    ' Set the global volume for a voice (0 - 255)
    SUB SampleMixer_SetGlobalVolume (nVolume AS SINGLE)
        SHARED __SoftSynth AS __SoftSynthType

        __SoftSynth.volume = ClampSingle(nVolume, 0, SOFTSYNTH_GLOBAL_VOLUME_MAX)
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

        __SoftSynth.useHQMixer = nFlag <> FALSE ' this will accept all kinds of garbage :)
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

$END IF

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
    SUB InitializeMixer (nVoices AS _UNSIGNED _BYTE)
        SHARED SoftSynth AS SoftSynthType
        SHARED Voice() AS VoiceType

        ' Save the number of voices
        SoftSynth.voices = nVoices

        ' Resize the voice array
        REDIM Voice(0 TO nVoices - 1) AS VoiceType

        ' Set the mix rate to match that of the system
        SoftSynth.mixerRate = _SNDRATE

        ' Allocate a QB64 sound pipe
        SoftSynth.soundHandle = _SNDOPENRAW

        ' Reset the global volume
        SoftSynth.volume = GLOBAL_VOLUME_MAX

        DIM i AS _UNSIGNED _BYTE

        ' Set all voice defaults
        FOR i = 0 TO nVoices - 1
            Voice(i).sample = -1
            Voice(i).volume = SAMPLE_VOLUME_MAX
            Voice(i).panning = SAMPLE_PAN_CENTER
            Voice(i).pitch = 0
            Voice(i).position = 0
            Voice(i).playType = SAMPLE_PLAY_SINGLE
            Voice(i).startPosition = 0
            Voice(i).endPosition = 0
        NEXT
    END SUB


    ' This initialized the sample manager
    ' All previous samples will be lost!
    SUB InitializeSampleManager (nSamples AS _UNSIGNED _BYTE)
        SHARED SoftSynth AS SoftSynthType
        SHARED SampleData() AS STRING

        ' Save the number of samples
        SoftSynth.samples = nSamples

        ' Resize the sample data array
        REDIM SampleData(0 TO nSamples - 1) AS STRING
    END SUB


    ' Close the mixer - free all allocated resources
    SUB FinalizeMixer
        SHARED SoftSynth AS SoftSynthType

        _SNDRAWDONE SoftSynth.soundHandle ' Sumbit whatever is remaining in the raw buffer for playback
        _SNDCLOSE SoftSynth.soundHandle ' Close QB64 sound pipe
    END SUB

    ' Returns true if more samples needs to be mixed
    FUNCTION NeedsSoundRefill%%
        $CHECKING:OFF
        SHARED SoftSynth AS SoftSynthType

        NeedsSoundRefill = (_SNDRAWLEN(SoftSynth.soundHandle) < SOUND_TIME_MIN)
        $CHECKING:ON
    END FUNCTION

    ' This should be called by code using the mixer at regular intervals
    ' All mixing calculations are done using floating-point math (it's 2022 :)
    SUB UpdateMixer (nSamples AS _UNSIGNED INTEGER)
        $CHECKING:OFF
        SHARED SoftSynth AS SoftSynthType
        SHARED SampleData() AS STRING
        SHARED Voice() AS VoiceType
        SHARED MixerBufferLeft() AS SINGLE
        SHARED MixerBufferRight() AS SINGLE

        DIM AS LONG v, s, nSample, nPos, nPlayType, sLen
        DIM AS SINGLE fVolume, fPan, fPitch, fPos, fStartPos, fEndPos, fSam
        DIM AS _BYTE bSam1, bSam2

        ' Reallocate the mixer buffers that will hold sample data for both channels
        ' This is conveniently zeroed by QB64, so that is nice. We don't have to do it
        ' Here 0 is the left channnel and 1 is the right channel
        REDIM MixerBufferLeft(0 TO nSamples - 1) AS SINGLE
        REDIM MixerBufferRight(0 TO nSamples - 1) AS SINGLE

        ' Set the active voice count to zero
        SoftSynth.activeVoices = 0

        ' We will iterate through each channel completely rather than jumping from channel to channel
        ' We are doing this because it is easier for the CPU to access adjacent memory rather than something far away
        ' Also because we do not have to fetch stuff from multiple arrays too many times
        FOR v = 0 TO SoftSynth.voices - 1
            nSample = Voice(v).sample
            ' Only proceed if we have a valid sample number (>= 0)
            IF nSample >= 0 THEN
                ' Increment the active voices
                SoftSynth.activeVoices = SoftSynth.activeVoices + 1

                ' Get some values we need frequently during the mixing interation below
                ' Note that these do not change at all during the mixing process
                fVolume = Voice(v).volume
                fPan = Voice(v).panning
                fPitch = Voice(v).pitch
                nPlayType = Voice(v).playType
                fStartPos = Voice(v).startPosition
                fEndPos = Voice(v).endPosition
                sLen = LEN(SampleData(nSample)) ' real sample length

                ' Next we go through the channel sample data and mix it to our mixerBuffer
                FOR s = 0 TO nSamples - 1
                    ' We need these too many times
                    ' And this is inside the loop because "position" changes
                    fPos = Voice(v).position

                    ' Check if we are looping
                    IF nPlayType = SAMPLE_PLAY_SINGLE THEN
                        ' For non-looping sample simply set the isplayed flag as false if we reached the end
                        IF fPos >= fEndPos THEN
                            StopVoice v
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
                    IF SoftSynth.useHQMixer AND fPos + 2 <= sLen THEN
                        ' Apply interpolation
                        nPos = FIX(fPos)
                        'bSam1 = Asc(SampleData(nSample), 1 + nPos) ' this will convert the unsigned byte (the way it is stored) to signed byte
                        bSam1 = PeekString(SampleData(nSample), nPos) ' optimization of the above
                        'bSam2 = Asc(SampleData(nSample), 2 + nPos) ' this will convert the unsigned byte (the way it is stored) to signed byte
                        bSam2 = PeekString(SampleData(nSample), 1 + nPos) ' optimization of the above
                        fSam = bSam1 + (bSam2 - bSam1) * (fPos - nPos)
                    ELSE
                        IF fPos + 1 <= sLen THEN
                            'bSam1 = Asc(SampleData(nSample), 1 + fPos) ' this will convert the unsigned byte (the way it is stored) to signed byte
                            bSam1 = PeekString(SampleData(nSample), fPos) ' optimization of the above
                            fSam = bSam1
                        ELSE
                            fSam = 0
                        END IF
                    END IF

                    ' The following two lines mixes the sample and also does volume & stereo panning
                    ' The below expressions were simplified and rearranged to reduce the number of divisions. Divisions are slow
                    MixerBufferLeft(s) = MixerBufferLeft(s) + (fSam * fVolume * (SAMPLE_PAN_RIGHT - fPan)) / (SAMPLE_PAN_RIGHT * SAMPLE_VOLUME_MAX)
                    MixerBufferRight(s) = MixerBufferRight(s) + (fSam * fVolume * fPan) / (SAMPLE_PAN_RIGHT * SAMPLE_VOLUME_MAX)

                    ' Move to the next sample position based on the pitch
                    Voice(v).position = fPos + fPitch
                NEXT
            END IF
        NEXT

        ' Feed the samples to the QB64 sound pipe
        FOR s = 0 TO nSamples - 1
            ' Apply global volume and scale sample to FP32 sample spec.
            fSam = SoftSynth.volume / (128 * GLOBAL_VOLUME_MAX)
            MixerBufferLeft(s) = MixerBufferLeft(s) * fSam
            MixerBufferRight(s) = MixerBufferRight(s) * fSam

            ' We do not clip samples anymore because miniaudio does that for us. It makes no sense to clip samples twice
            ' Obviously, this means that the quality of OpenAL version will suffer. But that's ok, it is on it's way to sunset :)

            ' Feed the samples to the QB64 sound pipe
            _SNDRAW MixerBufferLeft(s), MixerBufferRight(s), SoftSynth.soundHandle
        NEXT
        $CHECKING:ON
    END SUB


    ' Stores a sample in the sample data array. This will add some silence samples at the end
    ' If the sample is looping then it will anti-click by copying a couple of samples from the beginning to the end of the loop
    SUB LoadSample (nSample AS _UNSIGNED _BYTE, sData AS STRING, isLooping AS _BYTE, nLoopStart AS LONG, nLoopEnd AS LONG)
        SHARED SampleData() AS STRING

        DIM i AS LONG
        IF nLoopEnd >= LEN(sData) THEN i = 32 + nLoopEnd - LEN(sData) ELSE i = 32 ' We allocate 32 samples extra (minimum)
        SampleData(nSample) = sData + STRING$(i, NULL)

        ' If the sample is looping then make it anti-click by copying a few samples from loop start to loop end
        IF isLooping THEN
            ' We'll just copy 4 samples
            FOR i = 1 TO 4
                ASC(SampleData(nSample), nLoopEnd + i) = ASC(SampleData(nSample), nLoopStart + i)
            NEXT
        END IF
    END SUB


    ' Get a sample value for a sample from position
    FUNCTION PeekSample%% (nSample AS _UNSIGNED _BYTE, nPosition AS LONG)
        $CHECKING:OFF
        SHARED SampleData() AS STRING

        'PeekSample = Asc(SampleData(nSample), 1 + nPosition)
        PeekSample = PeekString(SampleData(nSample), nPosition) ' optimization of the above
        $CHECKING:ON
    END FUNCTION


    ' Writes a sample value to a sample at position
    ' Don't worry about the nValue being unsigned. Just feed signed 8-bit sample values to it
    ' It's unsigned to prevent Asc from throwing up XD
    SUB PokeSample (nSample AS _UNSIGNED _BYTE, nPosition AS LONG, nValue AS _UNSIGNED _BYTE)
        $CHECKING:OFF
        SHARED SampleData() AS STRING

        'Asc(SampleData(nSample), 1 + nPosition) = nValue
        PokeString SampleData(nSample), nPosition, nValue ' optimization of the above
        $CHECKING:ON
    END SUB


    ' Set the volume for a voice (0 - 64)
    SUB SetVoiceVolume (nVoice AS _UNSIGNED _BYTE, nVolume AS SINGLE)
        $CHECKING:OFF
        SHARED Voice() AS VoiceType

        IF nVolume < 0 THEN
            Voice(nVoice).volume = 0
        ELSEIF nVolume > SAMPLE_VOLUME_MAX THEN
            Voice(nVoice).volume = SAMPLE_VOLUME_MAX
        ELSE
            Voice(nVoice).volume = nVolume
        END IF
        $CHECKING:ON
    END SUB


    ' Set panning for a voice (0 - 255)
    SUB SetVoicePanning (nVoice AS _UNSIGNED _BYTE, nPanning AS SINGLE)
        $CHECKING:OFF
        SHARED Voice() AS VoiceType

        IF nPanning < SAMPLE_PAN_LEFT THEN
            Voice(nVoice).panning = SAMPLE_PAN_LEFT
        ELSEIF nPanning > SAMPLE_PAN_RIGHT THEN
            Voice(nVoice).panning = SAMPLE_PAN_RIGHT
        ELSE
            Voice(nVoice).panning = nPanning
        END IF
        $CHECKING:ON
    END SUB


    ' Set a frequency for a voice
    ' This will be responsible for correctly setting the mixer sample pitch
    SUB SetVoiceFrequency (nVoice AS _UNSIGNED _BYTE, nFrequency AS SINGLE)
        $CHECKING:OFF
        SHARED SoftSynth AS SoftSynthType
        SHARED Voice() AS VoiceType

        Voice(nVoice).pitch = nFrequency / SoftSynth.mixerRate
        $CHECKING:ON
    END SUB


    ' Stops playback for a voice
    SUB StopVoice (nVoice AS _UNSIGNED _BYTE)
        $CHECKING:OFF
        SHARED Voice() AS VoiceType

        Voice(nVoice).sample = -1
        Voice(nVoice).volume = SAMPLE_VOLUME_MAX
        ' Voice(nVoice).panning is intentionally left out to respect the pan positions set by the loader
        Voice(nVoice).pitch = 0
        Voice(nVoice).position = 0
        Voice(nVoice).playType = SAMPLE_PLAY_SINGLE
        Voice(nVoice).startPosition = 0
        Voice(nVoice).endPosition = 0
        $CHECKING:ON
    END SUB


    ' Starts playback of a sample
    ' This can be used to playback a sample from a particular offset or loop the sample
    SUB PlayVoice (nVoice AS _UNSIGNED _BYTE, nSample AS _UNSIGNED _BYTE, nPosition AS SINGLE, nPlayType AS _UNSIGNED _BYTE, nStart AS SINGLE, nEnd AS SINGLE)
        $CHECKING:OFF
        SHARED Voice() AS VoiceType

        Voice(nVoice).sample = nSample
        Voice(nVoice).position = nPosition
        Voice(nVoice).playType = nPlayType
        Voice(nVoice).startPosition = nStart
        Voice(nVoice).endPosition = nEnd
        $CHECKING:ON
    END SUB

    ' Set the global volume for a voice (0 - 255)
    SUB SetGlobalVolume (nVolume AS SINGLE)
        SHARED SoftSynth AS SoftSynthType

        IF nVolume < 0 THEN
            SoftSynth.volume = 0
        ELSEIF nVolume > GLOBAL_VOLUME_MAX THEN
            SoftSynth.volume = GLOBAL_VOLUME_MAX
        ELSE
            SoftSynth.volume = nVolume
        END IF
    END SUB


    ' Enables or disable HQ mixer
    SUB EnableHQMixer (nFlag AS _BYTE)
        SHARED SoftSynth AS SoftSynthType

        SoftSynth.useHQMixer = (nFlag <> FALSE) ' This will accept all kinds of garbage :)
    END SUB
    '-------------------------------------------------------------------------------------------------------------------
$END IF
'-----------------------------------------------------------------------------------------------------------------------

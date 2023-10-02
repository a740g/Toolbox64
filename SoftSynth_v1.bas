'-----------------------------------------------------------------------------------------------------------------------
' Simple sample-based software synthesizer
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF SOFTSYNTH_BAS = UNDEFINED THEN
    $LET SOFTSYNTH_BAS = TRUE

    '$INCLUDE:'SoftSynth_v1.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    'IF SoftSynth_Initialize THEN
    '    SoftSynth_SetTotalVoices 4

    '    DIM rawSound AS STRING: rawSound = LoadFile("../../../../Downloads/laser.8")
    '    DIM k AS LONG: FOR k = 1 TO LEN(rawSound)
    '        ASC(rawSound, k) = ASC(rawSound, k) XOR &H80
    '    NEXT k

    '    SoftSynth_LoadSound 0, rawSound, SoftSynth_BytesToFrames(LEN(rawSound), SIZE_OF_BYTE, 1), SIZE_OF_BYTE, 1

    '    SoftSynth_SetVoiceFrequency 1, 11025

    '    DO
    '        k = _KEYHIT

    '        IF k = 32 THEN SoftSynth_PlayVoice 1, 0, 0, SOFTSYNTH_VOICE_PLAY_FORWARD, 0, SoftSynth_BytesToFrames(LEN(rawSound), SIZE_OF_BYTE, 1) - 1
    '        IF k = 19200 THEN SoftSynth_SetVoiceBalance 1, SoftSynth_GetVoiceBalance(1) - 0.01!
    '        IF k = 19712 THEN SoftSynth_SetVoiceBalance 1, SoftSynth_GetVoiceBalance(1) + 0.01!

    '        IF SoftSynth_GetBufferedSoundTime < SOFTSYNTH_SOUND_BUFFER_TIME_DEFAULT THEN SoftSynth_Update 1024

    '        LOCATE 10, 1
    '        PRINT USING "Balance: ###.###"; SoftSynth_GetVoiceBalance(1)

    '        _LIMIT 60
    '    LOOP UNTIL k = 27

    '    SoftSynth_Finalize
    'END IF

    'END

    'FUNCTION LoadFile$ (path AS STRING)
    '    IF _FILEEXISTS(path) THEN
    '        DIM AS LONG fh: fh = FREEFILE
    '        OPEN path FOR BINARY ACCESS READ AS fh
    '        LoadFile = INPUT$(LOF(fh), fh)
    '        CLOSE fh
    '    END IF
    'END FUNCTION
    '-------------------------------------------------------------------------------------------------------------------

    FUNCTION SoftSynth_BytesToFrames~& (bytes AS _UNSIGNED LONG, bytesPerSample AS _UNSIGNED _BYTE, channels AS _UNSIGNED _BYTE)
        $CHECKING:OFF
        SoftSynth_BytesToFrames = bytes \ (bytesPerSample * channels)
        $CHECKING:ON
    END FUNCTION


    SUB SoftSynth_SetTotalVoices (voices AS _UNSIGNED LONG)
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __Voice() AS __VoiceType

        ' Save the number of voices
        __SoftSynth.voices = voices

        ' Resize the voice array
        REDIM __Voice(0 TO voices - 1) AS __VoiceType

        ' Set all voice defaults
        DIM i AS LONG: FOR i = 0 TO voices - 1
            __Voice(i).snd = -1
            __Voice(i).volume = SOFTSYNTH_VOICE_VOLUME_MAX
            __Voice(i).balance = 0! ' center
            __Voice(i).pitch = 0#
            __Voice(i).frequency = 0
            __Voice(i).position = 0#
            __Voice(i).startPosition = 0
            __Voice(i).endPosition = 0
            __Voice(i).mode = SOFTSYNTH_VOICE_PLAY_FORWARD
            __Voice(i).oldFrame = 0!
        NEXT i
    END SUB


    ' Initialize the sample mixer
    ' This allocates all required resources
    FUNCTION SoftSynth_Initialize%%
        SHARED __SoftSynth AS __SoftSynthType

        ' Cleanup and re-initialize if have already initialized
        IF SoftSynth_IsInitialized THEN
            SoftSynth_Initialize = TRUE
            EXIT FUNCTION
        END IF

        ' Save the number of voices
        __SoftSynth.voices = 0

        ' Set the mix rate to match that of the system
        __SoftSynth.sampleRate = _SNDRATE

        ' Allocate a QB64 sound pipe
        __SoftSynth.soundHandle = _SNDOPENRAW

        ' Reset the global volume
        __SoftSynth.volume = SOFTSYNTH_GLOBAL_VOLUME_MAX

        SoftSynth_Initialize = SoftSynth_IsInitialized
    END FUNCTION


    ' Close the mixer - free all allocated resources
    SUB SoftSynth_Finalize
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __SampleData() AS STRING
        SHARED __Voice() AS __VoiceType
        SHARED __SoftSynth_SoundBuffer() AS SINGLE

        _SNDRAWDONE __SoftSynth.soundHandle ' Sumbit whatever is remaining in the raw buffer for playback
        _SNDCLOSE __SoftSynth.soundHandle ' Close QB64 sound pipe
        __SoftSynth.soundHandle = 0 ' reset the value

        REDIM __SampleData(0 TO 0) AS STRING
        REDIM __Voice(0 TO 0) AS __VoiceType
        REDIM __SoftSynth_SoundBuffer(0 TO 0) AS SINGLE
    END SUB


    ' Returns true if the mixer was correctly initialized
    FUNCTION SoftSynth_IsInitialized%%
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SoftSynth_IsInitialized = __SoftSynth.soundHandle > 0 ' return true only if the raw sound pipe was allocated
        $CHECKING:ON
    END FUNCTION


    ' Stores a sample in the sample data array. The sample is always converted to 32-bit floating point format
    SUB SoftSynth_LoadSound (snd AS LONG, source AS STRING, frames AS _UNSIGNED LONG, bytesPerSample AS _UNSIGNED _BYTE, channels AS _UNSIGNED _BYTE)
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __SampleData() AS STRING

        ' Resize the sample data array if needed
        IF snd > UBOUND(__SampleData) THEN
            ' Save the number of samples
            __SoftSynth.sounds = snd + 1

            REDIM _PRESERVE __SampleData(0 TO snd) AS STRING
        END IF

        __SampleData(snd) = STRING$(frames * SIZE_OF_SINGLE, NULL) ' allocate memory for the to-be converted sample

        IF frames = NULL THEN EXIT SUB ' leave if we have no frames to load

        DIM AS _UNSIGNED LONG i, j, src, maxFrame: maxFrame = frames - 1

        SELECT CASE bytesPerSample
            CASE SIZE_OF_BYTE ' 8-bit
                FOR i = 0 TO maxFrame
                    FOR j = 1 TO channels
                        PokeStringSingle __SampleData(snd), i, PeekStringSingle(__SampleData(snd), i) + PeekStringByte(source, src) / 128!
                        src = src + 1
                    NEXT j
                NEXT i

            CASE SIZE_OF_INTEGER ' 16-bit
                FOR i = 0 TO maxFrame
                    FOR j = 1 TO channels
                        PokeStringSingle __SampleData(snd), i, PeekStringSingle(__SampleData(snd), i) + PeekStringInteger(source, src) / 32768!
                        src = src + 1
                    NEXT j
                NEXT i

            CASE SIZE_OF_SINGLE ' 32-bit
                FOR i = 0 TO maxFrame
                    FOR j = 1 TO channels
                        PokeStringSingle __SampleData(snd), i, PeekStringSingle(__SampleData(snd), i) + PeekStringSingle(source, src)
                        src = src + 1
                    NEXT j
                NEXT i

            CASE ELSE ' nothing else is supported
                ERROR ERROR_ILLEGAL_FUNCTION_CALL
        END SELECT
    END SUB


    ' This should be called by code using the mixer at regular intervals
    ' All mixing calculations are done using floating-point math (it's 2023 :)
    SUB SoftSynth_Update (frames AS _UNSIGNED LONG)
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __SampleData() AS STRING
        SHARED __Voice() AS __VoiceType
        SHARED __SoftSynth_SoundBuffer() AS SINGLE

        DIM AS _UNSIGNED LONG v, s, i
        DIM AS SINGLE tempFrame, outputFrame
        DIM position AS _INTEGER64

        ' Reallocate the mixer buffer that will hold the mixed sample data for both channels
        ' This is conveniently zeroed by QB64, so that is nice. We don't have to do it
        REDIM __SoftSynth_SoundBuffer(0 TO frames * SOFTSYNTH_SOUND_BUFFER_CHANNELS - 1) AS SINGLE ' * 2 for stereo, - 1 since we are zero based

        ' Set the active voice count to zero
        __SoftSynth.activeVoices = 0

        ' We will iterate through each channel completely rather than jumping from channel to channel
        ' We are doing this because it is easier for the CPU to access adjacent memory rather than something far away
        v = 0
        DO WHILE v < __SoftSynth.voices
            ' Only proceed if we have a valid sample number (>= 0)
            IF __Voice(v).snd >= 0 THEN
                ' Only proceed if we have something play in the sound
                IF LEN(__SampleData(__Voice(v).snd)) >= SIZE_OF_SINGLE THEN

                    ' Increment the active voices
                    __SoftSynth.activeVoices = __SoftSynth.activeVoices + 1

                    ' Next we go through the channel sample data and mix it to our mixerBuffer
                    s = 0: i = 0
                    DO WHILE s < frames
                        position = FIX(__Voice(v).position)

                        ' Check if we are looping
                        IF SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP = __Voice(v).mode AND position > __Voice(v).endPosition THEN
                            ' Reset loop position if we reached the end of the loop
                            __Voice(v).position = __Voice(v).startPosition
                            position = FIX(__Voice(v).position)
                        ELSEIF position > __Voice(v).endPosition THEN
                            ' For non-looping sample simply stop playing if we reached the end
                            __Voice(v).snd = -1 ' just invalidate the sound leaving other properties intact
                            EXIT DO ' exit the mixing loop as we have no more samples to mix for this channel
                        END IF

                        ' Fetch the sample frame that we need
                        tempFrame = PeekStringSingle(__SampleData(__Voice(v).snd), position)

                        ' Apply interpolation
                        outputFrame = tempFrame + (__Voice(v).oldFrame - tempFrame) * (__Voice(v).position - position)
                        __Voice(v).oldFrame = tempFrame

                        ' Move to the next sample position based on the pitch
                        __Voice(v).position = __Voice(v).position + __Voice(v).pitch

                        ' The following lines mixes the sample and also does volume & stereo panning
                        tempFrame = outputFrame * __Voice(v).volume ' just calculate this once
                        __SoftSynth_SoundBuffer(i) = __SoftSynth_SoundBuffer(i) + tempFrame * (0.5! - __Voice(v).balance)
                        i = i + 1
                        __SoftSynth_SoundBuffer(i) = __SoftSynth_SoundBuffer(i) + tempFrame * (0.5! + __Voice(v).balance)
                        i = i + 1

                        s = s + 1
                    LOOP
                END IF
            END IF

            v = v + 1
        LOOP

        ' Feed the samples to the QB64 sound pipe
        i = 0: s = frames * SOFTSYNTH_SOUND_BUFFER_CHANNELS
        DO WHILE i < s
            ' Apply global volume
            __SoftSynth_SoundBuffer(i) = __SoftSynth_SoundBuffer(i) * __SoftSynth.volume ' left channel
            __SoftSynth_SoundBuffer(i + 1) = __SoftSynth_SoundBuffer(i + 1) * __SoftSynth.volume ' right channel

            ' Feed the samples to the QB64 sound pipe
            _SNDRAW __SoftSynth_SoundBuffer(i), __SoftSynth_SoundBuffer(i + 1), __SoftSynth.soundHandle

            i = i + SOFTSYNTH_SOUND_BUFFER_CHANNELS
        LOOP
        $CHECKING:ON
    END SUB


    ' Get a sample value for a sample from position (in sample frames)
    FUNCTION SoftSynth_PeekSoundFrameByte%% (snd AS LONG, position AS _UNSIGNED LONG)
        $CHECKING:OFF
        SHARED __SampleData() AS STRING

        SoftSynth_PeekSoundFrameByte = PeekStringSingle(__SampleData(snd), position) * 128!
        $CHECKING:ON
    END FUNCTION


    ' Writes a sample value to a sample at position (in sample frames)
    SUB SoftSynth_PokeSoundFrameByte (snd AS LONG, position AS _UNSIGNED LONG, frame AS _BYTE)
        $CHECKING:OFF
        SHARED __SampleData() AS STRING

        PokeStringSingle __SampleData(snd), position, frame / 128!
        $CHECKING:ON
    END SUB


    ' Get a sample value for a sample from position (in sample frames)
    FUNCTION SoftSynth_PeekSoundFrameInteger% (snd AS LONG, position AS _UNSIGNED LONG)
        $CHECKING:OFF
        SHARED __SampleData() AS STRING

        SoftSynth_PeekSoundFrameInteger = PeekStringSingle(__SampleData(snd), position) * 32768!
        $CHECKING:ON
    END FUNCTION


    ' Writes a sample value to a sample at position (in sample frames)
    SUB SoftSynth_PokeSoundFrameInteger (snd AS LONG, position AS _UNSIGNED LONG, frame AS INTEGER)
        $CHECKING:OFF
        SHARED __SampleData() AS STRING

        PokeStringSingle __SampleData(snd), position, frame / 32768!
        $CHECKING:ON
    END SUB


    ' Get a sample value for a sample from position (in sample frames)
    FUNCTION SoftSynth_PeekSoundFrameSingle! (snd AS LONG, position AS _UNSIGNED LONG)
        $CHECKING:OFF
        SHARED __SampleData() AS STRING

        SoftSynth_PeekSoundFrameSingle = PeekStringSingle(__SampleData(snd), position)
        $CHECKING:ON
    END FUNCTION


    ' Writes a sample value to a sample at position (in sample frames)
    SUB SoftSynth_PokeSoundFrameSingle (snd AS LONG, position AS _UNSIGNED LONG, frame AS SINGLE)
        $CHECKING:OFF
        SHARED __SampleData() AS STRING

        PokeStringSingle __SampleData(snd), position, frame
        $CHECKING:ON
    END SUB


    ' Set the volume for a voice
    SUB SoftSynth_SetVoiceVolume (voice AS _UNSIGNED LONG, volume AS SINGLE)
        $CHECKING:OFF
        SHARED __Voice() AS __VoiceType

        __Voice(voice).volume = ClampSingle(volume, 0!, SOFTSYNTH_VOICE_VOLUME_MAX)
        $CHECKING:ON
    END SUB


    ' Get the volume for a voice
    FUNCTION SoftSynth_GetVoiceVolume! (voice AS _UNSIGNED LONG)
        $CHECKING:OFF
        SHARED __Voice() AS __VoiceType

        SoftSynth_GetVoiceVolume = __Voice(voice).volume
        $CHECKING:ON
    END FUNCTION


    ' Set panning for a voice
    SUB SoftSynth_SetVoiceBalance (voice AS _UNSIGNED LONG, balance AS SINGLE)
        $CHECKING:OFF
        SHARED __Voice() AS __VoiceType

        __Voice(voice).balance = ClampSingle(balance * 0.5!, -0.5!, 0.5!)
        $CHECKING:ON
    END SUB


    ' Get panning for a voice
    FUNCTION SoftSynth_GetVoiceBalance! (voice AS _UNSIGNED LONG)
        $CHECKING:OFF
        SHARED __Voice() AS __VoiceType

        SoftSynth_GetVoiceBalance = __Voice(voice).balance * 2.0!
        $CHECKING:ON
    END FUNCTION


    ' Set a frequency for a voice
    ' This will be responsible for correctly setting the mixer sample pitch
    SUB SoftSynth_SetVoiceFrequency (voice AS _UNSIGNED LONG, frequency AS _UNSIGNED LONG)
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __Voice() AS __VoiceType

        __Voice(voice).frequency = frequency
        __Voice(voice).pitch = frequency / __SoftSynth.sampleRate
        $CHECKING:ON
    END SUB


    ' Get the frequency of a voice
    FUNCTION SoftSynth_GetVoiceFrequency~& (voice AS _UNSIGNED LONG)
        $CHECKING:OFF
        SHARED __Voice() AS __VoiceType

        SoftSynth_GetVoiceFrequency = __Voice(voice).frequency
        $CHECKING:ON
    END FUNCTION


    ' Stops playback for a voice
    ' Resetting balance is intentionally left out to respect the pan positions set initially by the loader
    SUB SoftSynth_StopVoice (voice AS _UNSIGNED LONG)
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __Voice() AS __VoiceType

        __Voice(voice).snd = -1
        __Voice(voice).volume = SOFTSYNTH_VOICE_VOLUME_MAX
        __Voice(voice).pitch = 0#
        __Voice(voice).frequency = 0
        __Voice(voice).position = 0#
        __Voice(voice).startPosition = 0
        __Voice(voice).endPosition = 0
        __Voice(voice).mode = SOFTSYNTH_VOICE_PLAY_FORWARD
        __Voice(voice).oldFrame = 0!
        $CHECKING:ON
    END SUB


    ' Starts playback of a sample
    ' This can be used to playback a sample from a particular offset or loop the sample
    ' All sample position and length values are in sample frames (not bytes)
    SUB SoftSynth_PlayVoice (voice AS _UNSIGNED LONG, snd AS LONG, position AS _UNSIGNED LONG, mode AS LONG, startFrame AS _UNSIGNED LONG, endFrame AS _UNSIGNED LONG)
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType
        SHARED __Voice() AS __VoiceType
        SHARED __SampleData() AS STRING

        __Voice(voice).mode = mode
        IF mode > SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP THEN __Voice(voice).mode = SOFTSYNTH_VOICE_PLAY_FORWARD

        __Voice(voice).position = position

        DIM maxFrame AS _UNSIGNED LONG: maxFrame = LEN(__SampleData(snd)) - 1

        __Voice(voice).startPosition = startFrame
        IF __Voice(voice).startPosition > maxFrame THEN __Voice(voice).startPosition = maxFrame

        __Voice(voice).endPosition = endFrame
        IF __Voice(voice).endPosition > maxFrame THEN __Voice(voice).endPosition = maxFrame

        __Voice(voice).snd = snd

        $CHECKING:ON
    END SUB


    ' Set the global volume for a voice
    SUB SoftSynth_SetGlobalVolume (volume AS SINGLE)
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        __SoftSynth.volume = ClampSingle(volume, 0!, SOFTSYNTH_GLOBAL_VOLUME_MAX)
        $CHECKING:ON
    END SUB


    ' Returns the global volume
    FUNCTION SoftSynth_GetGlobalVolume!
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SoftSynth_GetGlobalVolume = __SoftSynth.volume
        $CHECKING:ON
    END FUNCTION


    ' Returns the total voices
    FUNCTION SoftSynth_GetTotalVoices~&
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SoftSynth_GetTotalVoices = __SoftSynth.voices
        $CHECKING:ON
    END FUNCTION


    ' Returns the active voices
    FUNCTION SoftSynth_GetActiveVoices~&
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SoftSynth_GetActiveVoices = __SoftSynth.activeVoices
        $CHECKING:ON
    END FUNCTION


    ' Returns the total sound slots
    FUNCTION SoftSynth_GetTotalSounds~&
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SoftSynth_GetTotalSounds = __SoftSynth.sounds
        $CHECKING:ON
    END FUNCTION


    ' Returns the amount of buffered sample time remaining to be played
    FUNCTION SoftSynth_GetBufferedSoundTime#
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SoftSynth_GetBufferedSoundTime = _SNDRAWLEN(__SoftSynth.soundHandle)
        $CHECKING:ON
    END FUNCTION


    ' Returns the sample rate of the sample mixer
    FUNCTION SoftSynth_GetSampleRate~&
        $CHECKING:OFF
        SHARED __SoftSynth AS __SoftSynthType

        SoftSynth_GetSampleRate = __SoftSynth.sampleRate
        $CHECKING:ON
    END FUNCTION

$END IF

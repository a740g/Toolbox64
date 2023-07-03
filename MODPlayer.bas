'-----------------------------------------------------------------------------------------------------------------------
' MOD Player Library
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF MODPLAYER_BAS = UNDEFINED THEN
    $LET MODPLAYER_BAS = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' HEADER FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'MemFile.bi'
    '$INCLUDE:'FileOps.bi'
    '$INCLUDE:'SoftSynth.bi'
    '$INCLUDE:'MODPlayer.bi'
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    '$Debug
    '$Asserts
    'If LoadMODFromDisk("http://ftp.modland.com/pub/modules/Protracker/Emax/digital%20bass-line.mod") Then
    '    EnableHQMixer TRUE
    '    StartMODPlayer
    '    Do
    '        UpdateMODPlayer
    '        Locate 1, 1
    '        Print Using "__Order: ### / ###    Pattern: ### / ###    Row: ## / 64    BPM: ###    Speed: ###"; __Song.orderPosition + 1; __Song.orders; __Order(__Song.orderPosition) + 1; __Song.highestPattern + 1; __Song.patternRow + 1; __Song.bpm; __Song.speed;
    '        _Limit 60
    '    Loop While _KeyHit <> 27 And __Song.isPlaying
    '    StopMODPlayer
    'End If
    'End
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
    ' Loads the MOD file into memory and prepares all required gobals
    FUNCTION LoadMODFromMemory%% (buffer AS STRING)
        SHARED __Song AS __SongType
        SHARED __Order() AS _UNSIGNED _BYTE
        SHARED __Pattern() AS __NoteType
        SHARED __Sample() AS __SampleType
        SHARED __PeriodTable() AS _UNSIGNED INTEGER

        ' Attempt to open the file
        DIM memFile AS _UNSIGNED _OFFSET: memFile = MemFile_Create(buffer)
        IF memFile = NULL THEN EXIT FUNCTION

        ' Check what kind of MOD file this is
        ' Seek to offset 1080 (438h) in the file & read in 4 bytes
        DIM i AS _UNSIGNED INTEGER, result AS LONG
        result = MemFile_Seek(memFile, 1080)
        _ASSERT result
        result = MemFile_ReadString(memFile, __Song.subtype)
        _ASSERT (result = LEN(__Song.subtype))

        ' Also, seek to the beginning of the file and get the song title
        result = MemFile_Seek(memFile, 0)
        _ASSERT result
        result = MemFile_ReadString(memFile, __Song.songName)
        _ASSERT (result = LEN(__Song.songName))

        __Song.channels = 0
        __Song.samples = 0

        SELECT CASE __Song.subtype
            CASE "FEST", "FIST", "LARD", "M!K!", "M&K!", "M.K.", "N.T.", "NSMS", "PATT"
                __Song.channels = 4
                __Song.samples = 31
            CASE "OCTA", "OKTA"
                __Song.channels = 8
                __Song.samples = 31
            CASE ELSE
                ' Parse the subtype string to check for more variants
                IF RIGHT$(__Song.subtype, 3) = "CHN" THEN
                    ' Check xCNH types
                    __Song.channels = VAL(LEFT$(__Song.subtype, 1))
                    __Song.samples = 31
                ELSEIF RIGHT$(__Song.subtype, 2) = "CH" OR RIGHT$(__Song.subtype, 2) = "CN" THEN
                    ' Check for xxCH & xxCN types
                    __Song.channels = VAL(LEFT$(__Song.subtype, 2))
                    __Song.samples = 31
                ELSEIF LEFT$(__Song.subtype, 3) = "FLT" OR LEFT$(__Song.subtype, 3) = "TDZ" OR LEFT$(__Song.subtype, 3) = "EXO" THEN
                    ' Check for FLTx, TDZx & EXOx types
                    __Song.channels = VAL(RIGHT$(__Song.subtype, 1))
                    __Song.samples = 31
                ELSEIF LEFT$(__Song.subtype, 2) = "CD" AND RIGHT$(__Song.subtype, 1) = "1" THEN
                    ' Check for CDx1 types
                    __Song.channels = VAL(MID$(__Song.subtype, 3, 1))
                    __Song.samples = 31
                ELSEIF LEFT$(__Song.subtype, 2) = "FA" THEN
                    ' Check for FAxx types
                    __Song.channels = VAL(RIGHT$(__Song.subtype, 2))
                    __Song.samples = 31
                ELSE
                    ' Extra checks for 15 sample MOD
                    FOR i = 1 TO LEN(__Song.songName)
                        IF ASC(__Song.songName, i) < KEY_SPACE_BAR AND ASC(__Song.songName, i) <> NULL THEN
                            ' This is probably not a 15 sample MOD file
                            MemFile_Destroy memFile
                            EXIT FUNCTION
                        END IF
                    NEXT
                    __Song.channels = 4
                    __Song.samples = 15
                    __Song.subtype = "MODF" ' Change subtype to reflect 15 (Fh) sample mod, otherwise it will contain garbage
                END IF
        END SELECT

        ' Sanity check
        IF (__Song.samples = 0 OR __Song.channels = 0) THEN
            MemFile_Destroy memFile
            EXIT FUNCTION
        END IF

        ' Initialize the sample manager
        REDIM __Sample(0 TO __Song.samples - 1) AS __SampleType
        DIM AS _UNSIGNED _BYTE byte1, byte2

        ' Load the sample headers
        FOR i = 0 TO __Song.samples - 1
            ' Read the sample name
            result = MemFile_ReadString(memFile, __Sample(i).sampleName)
            _ASSERT (result = LEN(__Sample(i).sampleName))

            ' Read sample length
            result = MemFile_ReadByte(memFile, byte1)
            _ASSERT result
            result = MemFile_ReadByte(memFile, byte2)
            _ASSERT result

            __Sample(i).length = (byte1 * &H100 + byte2) * 2
            IF __Sample(i).length = 2 THEN __Sample(i).length = 0 ' Sanity check

            ' Read finetune
            result = MemFile_ReadByte(memFile, __Sample(i).c2Spd)
            _ASSERT result
            __Sample(i).c2Spd = __GetC2Spd(__Sample(i).c2Spd) ' Convert finetune to c2spd

            ' Read volume
            result = MemFile_ReadByte(memFile, __Sample(i).volume)
            _ASSERT result
            IF __Sample(i).volume > SAMPLE_VOLUME_MAX THEN __Sample(i).volume = SAMPLE_VOLUME_MAX ' Sanity check

            ' Read loop start
            result = MemFile_ReadByte(memFile, byte1)
            _ASSERT result
            result = MemFile_ReadByte(memFile, byte2)
            _ASSERT result
            __Sample(i).loopStart = (byte1 * &H100 + byte2) * 2
            IF __Sample(i).loopStart >= __Sample(i).length THEN __Sample(i).loopStart = 0 ' Sanity check

            ' Read loop length
            result = MemFile_ReadByte(memFile, byte1)
            _ASSERT result
            result = MemFile_ReadByte(memFile, byte2)
            _ASSERT result
            __Sample(i).loopLength = (byte1 * &H100 + byte2) * 2
            IF __Sample(i).loopLength = 2 THEN __Sample(i).loopLength = 0 ' Sanity check

            ' Calculate repeat end
            __Sample(i).loopEnd = __Sample(i).loopStart + __Sample(i).loopLength
            IF __Sample(i).loopEnd > __Sample(i).length THEN __Sample(i).loopEnd = __Sample(i).length ' Sanity check
        NEXT

        result = MemFile_ReadByte(memFile, __Song.orders)
        _ASSERT result
        IF __Song.orders > __ORDER_TABLE_MAX + 1 THEN __Song.orders = __ORDER_TABLE_MAX + 1
        result = MemFile_ReadByte(memFile, __Song.endJumpOrder)
        _ASSERT result
        IF __Song.endJumpOrder >= __Song.orders THEN __Song.endJumpOrder = 0

        'Load the pattern table, and find the highest pattern to load.
        __Song.highestPattern = 0
        FOR i = 0 TO __ORDER_TABLE_MAX
            result = MemFile_ReadByte(memFile, __Order(i))
            _ASSERT result
            IF __Order(i) > __Song.highestPattern THEN __Song.highestPattern = __Order(i)
        NEXT

        ' Resize pattern data array
        REDIM __Pattern(0 TO __Song.highestPattern, 0 TO __PATTERN_ROW_MAX, 0 TO __Song.channels - 1) AS __NoteType

        ' Skip past the 4 byte marker if this is a 31 sample mod
        IF __Song.samples = 31 THEN
            result = MemFile_Seek(memFile, MemFile_GetPosition(memFile) + 4)
        END IF

        ' Load the period table
        RESTORE PeriodTab
        READ __Song.periodTableMax ' Read the size
        __Song.periodTableMax = __Song.periodTableMax - 1 ' Change to ubound
        REDIM __PeriodTable(0 TO __Song.periodTableMax) AS _UNSIGNED INTEGER ' Allocate size elements
        ' Now read size values
        FOR i = 0 TO __Song.periodTableMax
            READ __PeriodTable(i)
        NEXT

        DIM AS _UNSIGNED _BYTE byte3, byte4
        DIM AS _UNSIGNED INTEGER a, b, c, period

        ' Load the patterns
        ' +-------------------------------------+
        ' | Byte 0    Byte 1   Byte 2   Byte 3  |
        ' +-------------------------------------+
        ' |aaaaBBBB CCCCCCCCC DDDDeeee FFFFFFFFF|
        ' +-------------------------------------+
        ' TODO: special handling for FLT8?
        FOR i = 0 TO __Song.highestPattern
            FOR a = 0 TO __PATTERN_ROW_MAX
                FOR b = 0 TO __Song.channels - 1
                    result = MemFile_ReadByte(memFile, byte1)
                    _ASSERT result
                    result = MemFile_ReadByte(memFile, byte2)
                    _ASSERT result
                    result = MemFile_ReadByte(memFile, byte3)
                    _ASSERT result
                    result = MemFile_ReadByte(memFile, byte4)
                    _ASSERT result

                    __Pattern(i, a, b).sample = (byte1 AND &HF0) OR _SHR(byte3, 4)

                    period = _SHL(byte1 AND &HF, 8) OR byte2

                    ' Do the look up in the table against what is read in and store note
                    __Pattern(i, a, b).note = __NOTE_NONE
                    FOR c = 0 TO 107
                        IF period >= __PeriodTable(c + 24) THEN
                            __Pattern(i, a, b).note = c
                            EXIT FOR
                        END IF
                    NEXT

                    __Pattern(i, a, b).volume = __NOTE_NO_VOLUME ' MODs don't have any volume field in the pattern
                    __Pattern(i, a, b).effect = byte3 AND &HF
                    __Pattern(i, a, b).operand = byte4

                    ' Some sanity check
                    IF __Pattern(i, a, b).sample > __Song.samples THEN __Pattern(i, a, b).sample = 0 ' Sample 0 means no sample. So valid sample are 1-15/31
                NEXT
            NEXT
        NEXT

        ' Initialize the softsynth sample manager
        InitializeSampleManager __Song.samples

        DIM sampBuf AS STRING
        ' Load the samples
        FOR i = 0 TO __Song.samples - 1
            sampBuf = SPACE$(__Sample(i).length)
            result = MemFile_ReadString(memFile, sampBuf)
            ' Load sample size bytes of data and send it to our softsynth sample manager
            LoadSample i, sampBuf, __Sample(i).loopLength > 0, __Sample(i).loopStart, __Sample(i).loopEnd
        NEXT

        MemFile_Destroy memFile

        LoadMODFromMemory = TRUE

        ' Amiga period table data for 11 octaves
        PeriodTab:
        DATA 134
        DATA 27392,25856,24384,23040,21696,20480,19328,18240,17216,16256,15360,14496
        DATA 13696,12928,12192,11520,10848,10240,9664,9120,8608,8128,7680,7248
        DATA 6848,6464,6096,5760,5424,5120,4832,4560,4304,4064,3840,3624
        DATA 3424,3232,3048,2880,2712,2560,2416,2280,2152,2032,1920,1812
        DATA 1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960,906
        DATA 856,808,762,720,678,640,604,570,538,508,480,453
        DATA 428,404,381,360,339,320,302,285,269,254,240,226
        DATA 214,202,190,180,170,160,151,143,135,127,120,113
        DATA 107,101,95,90,85,80,75,71,67,63,60,56
        DATA 53,50,47,45,42,40,37,35,33,31,30,28
        DATA 26,25,23,22,21,20,18,17,16,15,15,14
        DATA 0,0
        DATA NaN
    END FUNCTION


    ' Load the MOD file from disk or a URL
    FUNCTION LoadMODFromDisk%% (fileName AS STRING)
        LoadMODFromDisk = LoadMODFromMemory(LoadFile(fileName))
    END FUNCTION


    ' Initializes the audio mixer, prepares eveything else for playback and kick starts the timer and hence song playback
    SUB StartMODPlayer
        SHARED __Song AS __SongType
        SHARED __Channel() AS __ChannelType
        SHARED __SineTable() AS _UNSIGNED _BYTE
        SHARED __InvertLoopSpeedTable() AS _UNSIGNED _BYTE
        SHARED SoftSynth AS SoftSynthType

        DIM AS _UNSIGNED INTEGER i, s

        ' Load the sine table
        RESTORE SineTab
        READ s
        REDIM __SineTable(0 TO s - 1) AS _UNSIGNED _BYTE
        FOR i = 0 TO s - 1
            READ __SineTable(i)
        NEXT

        ' Load the invert loop table
        RESTORE ILSpdTab
        READ s
        REDIM __InvertLoopSpeedTable(0 TO s - 1) AS _UNSIGNED _BYTE
        FOR i = 0 TO s - 1
            READ __InvertLoopSpeedTable(i)
        NEXT

        ' Initialize the softsynth sample mixer
        InitializeMixer __Song.channels

        ' Initialize some important stuff
        __Song.tempoTimerValue = (SoftSynth.mixerRate * __SONG_BPM_DEFAULT) \ 50
        __Song.orderPosition = 0
        __Song.patternRow = 0
        __Song.speed = __SONG_SPEED_DEFAULT
        __Song.tick = __Song.speed
        __Song.isPaused = FALSE

        ' Set default BPM
        __SetBPM __SONG_BPM_DEFAULT

        ' Setup the channel array
        REDIM __Channel(0 TO __Song.channels - 1) AS __ChannelType

        ' Setup panning for all channels per AMIGA PAULA's panning setup - LRRLLRRL...
        ' If we have < 4 channels, then 0 & 1 are set as left & right
        ' If we have > 4 channels all prefect 4 groups are set as LRRL
        ' Any channels that are left out are simply centered by the SoftSynth
        ' We will also not do hard left or hard right. ~25% of sound from each channel is blended with the other
        IF __Song.channels > 1 AND __Song.channels < 4 THEN
            ' Just setup channels 0 and 1
            ' If we have a 3rd channel it will be handle by the SoftSynth
            SetVoicePanning 0, SAMPLE_PAN_LEFT + SAMPLE_PAN_CENTER / 2
            SetVoicePanning 1, SAMPLE_PAN_RIGHT - SAMPLE_PAN_CENTER / 2
        ELSE
            FOR i = 0 TO __Song.channels - 1 - (__Song.channels MOD 4) STEP 4
                SetVoicePanning i + 0, SAMPLE_PAN_LEFT + SAMPLE_PAN_CENTER / 2
                SetVoicePanning i + 1, SAMPLE_PAN_RIGHT - SAMPLE_PAN_CENTER / 2
                SetVoicePanning i + 2, SAMPLE_PAN_RIGHT - SAMPLE_PAN_CENTER / 2
                SetVoicePanning i + 3, SAMPLE_PAN_LEFT + SAMPLE_PAN_CENTER / 2
            NEXT
        END IF

        __Song.isPlaying = TRUE

        ' Sine table data for tremolo & vibrato
        SineTab:
        DATA 32
        DATA 0,24,49,74,97,120,141,161,180,197,212,224,235,244,250,253,255,253,250,244,235,224,212,197,180,161,141,120,97,74,49,24
        DATA NaN

        ' Invert loop speed table data for EFx
        ILSpdTab:
        DATA 16
        DATA 0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128
        DATA NaN
    END SUB


    ' Frees all allocated resources, stops the timer and hence song playback
    SUB StopMODPlayer
        SHARED __Song AS __SongType

        ' Tell softsynth we are done
        FinalizeMixer

        __Song.isPlaying = FALSE
    END SUB


    ' This should be called at regular intervals to run the mod player and mixer code
    ' You can call this as frequenctly as you want. The routine will simply exit if nothing is to be done
    SUB UpdateMODPlayer
        SHARED __Song AS __SongType
        SHARED __Order() AS _UNSIGNED _BYTE

        ' Check conditions for which we should just exit and not process anything
        IF __Song.orderPosition >= __Song.orders THEN EXIT SUB

        ' Set the playing flag to true
        __Song.isPlaying = TRUE

        ' If song is paused or we already have enough samples to play then exit
        IF __Song.isPaused OR NOT NeedsSoundRefill THEN EXIT SUB

        IF __Song.tick >= __Song.speed THEN
            ' Reset song tick
            __Song.tick = 0

            ' Process pattern row if pattern delay is over
            IF __Song.patternDelay = 0 THEN

                ' Save the pattern and row for UpdateMODTick()
                ' The pattern that we are playing is always __Song.tickPattern
                __Song.tickPattern = __Order(__Song.orderPosition)
                __Song.tickPatternRow = __Song.patternRow

                ' Process the row
                __UpdateMODRow

                ' Increment the row counter
                ' Note UpdateMODTick() should pickup stuff using tickPattern & tickPatternRow
                ' This is because we are already at a new row not processed by UpdateMODRow()
                __Song.patternRow = __Song.patternRow + 1

                ' Check if we have finished the pattern and then move to the next one
                IF __Song.patternRow > __PATTERN_ROW_MAX THEN
                    __Song.orderPosition = __Song.orderPosition + 1
                    __Song.patternRow = 0

                    ' Check if we need to loop or stop
                    IF __Song.orderPosition >= __Song.orders THEN
                        IF __Song.isLooping THEN
                            __Song.orderPosition = __Song.endJumpOrder
                            __Song.speed = __SONG_SPEED_DEFAULT
                            __Song.tick = __Song.speed
                        ELSE
                            __Song.isPlaying = FALSE
                        END IF
                    END IF
                END IF
            ELSE
                __Song.patternDelay = __Song.patternDelay - 1
            END IF
        ELSE
            __UpdateMODTick
        END IF

        ' Mix the current tick
        UpdateMixer __Song.samplesPerTick

        ' Increment song tick on each update
        __Song.tick = __Song.tick + 1
    END SUB


    ' Updates a row of notes and play them out on tick 0
    SUB __UpdateMODRow
        SHARED __Song AS __SongType
        SHARED __Pattern() AS __NoteType
        SHARED __Sample() AS __SampleType
        SHARED __Channel() AS __ChannelType
        SHARED __PeriodTable() AS _UNSIGNED INTEGER

        DIM AS _UNSIGNED _BYTE nChannel, nNote, nSample, nVolume, nEffect, nOperand, nOpX, nOpY
        ' The effect flags below are set to true when a pattern jump effect and pattern break effect are triggered
        DIM AS _BYTE jumpEffectFlag, breakEffectFlag, noFrequency

        ' Set the active channel count to zero
        __Song.activeChannels = 0

        ' Process all channels
        FOR nChannel = 0 TO __Song.channels - 1
            nNote = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).note
            nSample = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).sample
            nVolume = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).volume
            nEffect = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).effect
            nOperand = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).operand
            nOpX = _SHR(nOperand, 4)
            nOpY = nOperand AND &HF
            noFrequency = FALSE

            ' Set volume. We never play if sample number is zero. Our sample array is 1 based
            ' ONLY RESET VOLUME IF THERE IS A SAMPLE NUMBER
            IF nSample > 0 THEN
                __Channel(nChannel).sample = nSample - 1
                ' Don't get the volume if delay note, set it when the delay note actually happens
                IF NOT (nEffect = &HE AND nOpX = &HD) THEN
                    __Channel(nChannel).volume = __Sample(__Channel(nChannel).sample).volume
                END IF
            END IF

            IF nNote < __NOTE_NONE THEN
                __Channel(nChannel).lastPeriod = 8363 * __PeriodTable(nNote) \ __Sample(__Channel(nChannel).sample).c2Spd
                __Channel(nChannel).note = nNote
                __Channel(nChannel).restart = TRUE
                __Channel(nChannel).startPosition = 0
                __Song.activeChannels = nChannel

                ' Retrigger tremolo and vibrato waveforms
                IF __Channel(nChannel).waveControl AND &HF < 4 THEN __Channel(nChannel).vibratoPosition = 0
                IF _SHR(__Channel(nChannel).waveControl, 4) < 4 THEN __Channel(nChannel).tremoloPosition = 0

                ' ONLY RESET FREQUENCY IF THERE IS A NOTE VALUE AND PORTA NOT SET
                IF nEffect <> &H3 AND nEffect <> &H5 THEN
                    __Channel(nChannel).period = __Channel(nChannel).lastPeriod
                END IF
            ELSE
                __Channel(nChannel).restart = FALSE
            END IF

            IF nVolume <= SAMPLE_VOLUME_MAX THEN __Channel(nChannel).volume = nVolume
            IF nNote = __NOTE_KEY_OFF THEN __Channel(nChannel).volume = 0

            ' Process tick 0 effects
            SELECT CASE nEffect
                CASE &H3 ' 3: Porta To Note
                    IF nOperand > 0 THEN __Channel(nChannel).portamentoSpeed = nOperand
                    __Channel(nChannel).portamentoTo = __Channel(nChannel).lastPeriod
                    __Channel(nChannel).restart = FALSE

                CASE &H5 ' 5: Tone Portamento + Volume Slide
                    __Channel(nChannel).portamentoTo = __Channel(nChannel).lastPeriod
                    __Channel(nChannel).restart = FALSE

                CASE &H4 ' 4: Vibrato
                    IF nOpX > 0 THEN __Channel(nChannel).vibratoSpeed = nOpX
                    IF nOpY > 0 THEN __Channel(nChannel).vibratoDepth = nOpY

                CASE &H7 ' 7: Tremolo
                    IF nOpX > 0 THEN __Channel(nChannel).tremoloSpeed = nOpX
                    IF nOpY > 0 THEN __Channel(nChannel).tremoloDepth = nOpY

                CASE &H8 ' 8: Set Panning Position
                    ' Don't care about DMP panning BS. We are doing this Fasttracker style
                    SetVoicePanning nChannel, nOperand

                CASE &H9 ' 9: Set Sample Offset
                    IF nOperand > 0 THEN __Channel(nChannel).startPosition = _SHL(nOperand, 8)

                CASE &HB ' 11: Jump To Pattern
                    __Song.orderPosition = nOperand
                    IF __Song.orderPosition >= __Song.orders THEN __Song.orderPosition = __Song.endJumpOrder
                    __Song.patternRow = -1 ' This will increment right after & we will start at 0
                    jumpEffectFlag = TRUE

                CASE &HC ' 12: Set Volume
                    __Channel(nChannel).volume = nOperand ' Operand can never be -ve cause it is unsigned. So we only clip for max below
                    IF __Channel(nChannel).volume > SAMPLE_VOLUME_MAX THEN __Channel(nChannel).volume = SAMPLE_VOLUME_MAX

                CASE &HD ' 13: Pattern Break
                    __Song.patternRow = (nOpX * 10) + nOpY - 1
                    IF __Song.patternRow > __PATTERN_ROW_MAX THEN __Song.patternRow = -1
                    IF NOT breakEffectFlag AND NOT jumpEffectFlag THEN
                        __Song.orderPosition = __Song.orderPosition + 1
                        IF __Song.orderPosition >= __Song.orders THEN __Song.orderPosition = __Song.endJumpOrder
                    END IF
                    breakEffectFlag = TRUE

                CASE &HE ' 14: Extended Effects
                    SELECT CASE nOpX
                        CASE &H0 ' 0: Set Filter
                            EnableHQMixer nOpY

                        CASE &H1 ' 1: Fine Portamento Up
                            __Channel(nChannel).period = __Channel(nChannel).period - _SHL(nOpY, 2)

                        CASE &H2 ' 2: Fine Portamento Down
                            __Channel(nChannel).period = __Channel(nChannel).period + _SHL(nOpY, 2)

                        CASE &H3 ' 3: Glissando Control
                            __Channel(nChannel).useGlissando = (nOpY <> FALSE)

                        CASE &H4 ' 4: Set Vibrato Waveform
                            __Channel(nChannel).waveControl = __Channel(nChannel).waveControl AND &HF0
                            __Channel(nChannel).waveControl = __Channel(nChannel).waveControl OR nOpY

                        CASE &H5 ' 5: Set Finetune
                            __Sample(__Channel(nChannel).sample).c2Spd = __GetC2Spd(nOpY)

                        CASE &H6 ' 6: Pattern Loop
                            IF nOpY = 0 THEN
                                __Channel(nChannel).patternLoopRow = __Song.tickPatternRow
                            ELSE
                                IF __Channel(nChannel).patternLoopRowCounter = 0 THEN
                                    __Channel(nChannel).patternLoopRowCounter = nOpY
                                ELSE
                                    __Channel(nChannel).patternLoopRowCounter = __Channel(nChannel).patternLoopRowCounter - 1
                                END IF
                                IF __Channel(nChannel).patternLoopRowCounter > 0 THEN __Song.patternRow = __Channel(nChannel).patternLoopRow - 1
                            END IF

                        CASE &H7 ' 7: Set Tremolo WaveForm
                            __Channel(nChannel).waveControl = __Channel(nChannel).waveControl AND &HF
                            __Channel(nChannel).waveControl = __Channel(nChannel).waveControl OR _SHL(nOpY, 4)

                        CASE &H8 ' 8: 16 position panning
                            IF nOpY > 15 THEN nOpY = 15
                            ' Why does this kind of stuff bother me so much. We could have just written "/ 17" XD
                            SetVoicePanning nChannel, nOpY * ((SAMPLE_PAN_RIGHT - SAMPLE_PAN_LEFT) / 15)

                        CASE &HA ' 10: Fine Volume Slide Up
                            __Channel(nChannel).volume = __Channel(nChannel).volume + nOpY
                            IF __Channel(nChannel).volume > SAMPLE_VOLUME_MAX THEN __Channel(nChannel).volume = SAMPLE_VOLUME_MAX

                        CASE &HB ' 11: Fine Volume Slide Down
                            __Channel(nChannel).volume = __Channel(nChannel).volume - nOpY
                            IF __Channel(nChannel).volume < 0 THEN __Channel(nChannel).volume = 0

                        CASE &HD ' 13: Delay Note
                            __Channel(nChannel).restart = FALSE
                            noFrequency = TRUE

                        CASE &HE ' 14: Pattern Delay
                            __Song.patternDelay = nOpY

                        CASE &HF ' 15: Invert Loop
                            __Channel(nChannel).invertLoopSpeed = nOpY
                    END SELECT

                CASE &HF ' 15: Set Speed
                    IF nOperand < 32 THEN
                        __Song.speed = nOperand
                    ELSE
                        __SetBPM nOperand
                    END IF
            END SELECT

            __DoInvertLoop nChannel ' called every tick

            IF NOT noFrequency THEN
                IF nEffect <> 7 THEN SetVoiceVolume nChannel, __Channel(nChannel).volume
                IF __Channel(nChannel).period > 0 THEN SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)
            END IF
        NEXT

        ' Now play all samples that needs to be played
        FOR nChannel = 0 TO __Song.activeChannels
            IF __Channel(nChannel).restart THEN
                IF __Sample(__Channel(nChannel).sample).loopLength > 0 THEN
                    PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition, SAMPLE_PLAY_LOOP, __Sample(__Channel(nChannel).sample).loopStart, __Sample(__Channel(nChannel).sample).loopEnd
                ELSE
                    PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition, SAMPLE_PLAY_SINGLE, 0, __Sample(__Channel(nChannel).sample).length
                END IF
            END IF
        NEXT
    END SUB


    ' Updates any tick based effects after tick 0
    SUB __UpdateMODTick
        SHARED __Song AS __SongType
        SHARED __Pattern() AS __NoteType
        SHARED __Sample() AS __SampleType
        SHARED __Channel() AS __ChannelType
        SHARED __PeriodTable() AS _UNSIGNED INTEGER

        DIM AS _UNSIGNED _BYTE nChannel, nVolume, nEffect, nOperand, nOpX, nOpY

        ' Process all channels
        FOR nChannel = 0 TO __Song.channels - 1
            ' Only process if we have a period set
            IF __Channel(nChannel).period > 0 THEN
                ' We are not processing a new row but tick 1+ effects
                ' So we pick these using tickPattern and tickPatternRow
                nVolume = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).volume
                nEffect = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).effect
                nOperand = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).operand
                nOpX = _SHR(nOperand, 4)
                nOpY = nOperand AND &HF

                __DoInvertLoop nChannel ' called every tick

                SELECT CASE nEffect
                    CASE &H0 ' 0: Arpeggio
                        IF (nOperand > 0) THEN
                            SELECT CASE __Song.tick MOD 3 'TODO: Check why 0, 1, 2 sounds wierd
                                CASE 0
                                    SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)
                                CASE 1
                                    SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__PeriodTable(__Channel(nChannel).note + nOpX))
                                CASE 2
                                    SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__PeriodTable(__Channel(nChannel).note + nOpY))
                            END SELECT
                        END IF

                    CASE &H1 ' 1: Porta Up
                        __Channel(nChannel).period = __Channel(nChannel).period - _SHL(nOperand, 2)
                        SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)
                        IF __Channel(nChannel).period < 56 THEN __Channel(nChannel).period = 56

                    CASE &H2 ' 2: Porta Down
                        __Channel(nChannel).period = __Channel(nChannel).period + _SHL(nOperand, 2)
                        SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)

                    CASE &H3 ' 3: Porta To Note
                        __DoPortamento nChannel

                    CASE &H4 ' 4: Vibrato
                        __DoVibrato nChannel

                    CASE &H5 ' 5: Tone Portamento + Volume Slide
                        __DoPortamento nChannel
                        __DoVolumeSlide nChannel, nOpX, nOpY

                    CASE &H6 ' 6: Vibrato + Volume Slide
                        __DoVibrato nChannel
                        __DoVolumeSlide nChannel, nOpX, nOpY

                    CASE &H7 ' 7: Tremolo
                        __DoTremolo nChannel

                    CASE &HA ' 10: Volume Slide
                        __DoVolumeSlide nChannel, nOpX, nOpY

                    CASE &HE ' 14: Extended Effects
                        SELECT CASE nOpX
                            CASE &H9 ' 9: Retrigger Note
                                IF nOpY <> 0 THEN
                                    IF __Song.tick MOD nOpY = 0 THEN
                                        IF __Sample(__Channel(nChannel).sample).loopLength > 0 THEN
                                            PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition, SAMPLE_PLAY_LOOP, __Sample(__Channel(nChannel).sample).loopStart, __Sample(__Channel(nChannel).sample).loopEnd
                                        ELSE
                                            PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition, SAMPLE_PLAY_SINGLE, 0, __Sample(__Channel(nChannel).sample).length
                                        END IF
                                    END IF
                                END IF

                            CASE &HC ' 12: Cut Note
                                IF __Song.tick = nOpY THEN
                                    __Channel(nChannel).volume = 0
                                    SetVoiceVolume nChannel, __Channel(nChannel).volume
                                END IF

                            CASE &HD ' 13: Delay Note
                                IF __Song.tick = nOpY THEN
                                    __Channel(nChannel).volume = __Sample(__Channel(nChannel).sample).volume
                                    IF nVolume <= SAMPLE_VOLUME_MAX THEN __Channel(nChannel).volume = nVolume
                                    SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)
                                    SetVoiceVolume nChannel, __Channel(nChannel).volume
                                    IF __Sample(__Channel(nChannel).sample).loopLength > 0 THEN
                                        PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition, SAMPLE_PLAY_LOOP, __Sample(__Channel(nChannel).sample).loopStart, __Sample(__Channel(nChannel).sample).loopEnd
                                    ELSE
                                        PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition, SAMPLE_PLAY_SINGLE, 0, __Sample(__Channel(nChannel).sample).length
                                    END IF
                                END IF
                        END SELECT
                END SELECT
            END IF
        NEXT
    END SUB


    ' We always set the global BPM using this and never directly
    SUB __SetBPM (nBPM AS _UNSIGNED _BYTE)
        SHARED __Song AS __SongType

        __Song.bpm = nBPM

        ' Calculate the number of samples we have to mix per tick
        __Song.samplesPerTick = __Song.tempoTimerValue \ nBPM
    END SUB


    ' Binary search the period table to find the closest value
    ' I hope this is the right way to do glissando. Oh well...
    FUNCTION __GetClosestPeriod& (target AS LONG)
        SHARED __Song AS __SongType
        SHARED __Channel() AS __ChannelType
        SHARED __PeriodTable() AS _UNSIGNED INTEGER

        DIM AS LONG startPos, endPos, midPos, leftVal, rightVal

        IF target > 27392 THEN
            __GetClosestPeriod = target
            EXIT FUNCTION
        ELSEIF target < 14 THEN
            __GetClosestPeriod = target
            EXIT FUNCTION
        END IF

        startPos = 0
        endPos = __Song.periodTableMax
        WHILE startPos + 1 < endPos
            midPos = startPos + (endPos - startPos) \ 2
            IF __PeriodTable(midPos) <= target THEN
                endPos = midPos
            ELSE
                startPos = midPos
            END IF
        WEND

        rightVal = ABS(__PeriodTable(startPos) - target)
        leftVal = ABS(__PeriodTable(endPos) - target)

        IF leftVal <= rightVal THEN
            __GetClosestPeriod = __PeriodTable(endPos)
        ELSE
            __GetClosestPeriod = __PeriodTable(startPos)
        END IF
    END FUNCTION


    ' Carry out a tone portamento to a certain note
    SUB __DoPortamento (chan AS _UNSIGNED _BYTE)
        SHARED __Channel() AS __ChannelType

        ' Slide up/down and clamp to destination
        IF __Channel(chan).period < __Channel(chan).portamentoTo THEN
            __Channel(chan).period = __Channel(chan).period + _SHL(__Channel(chan).portamentoSpeed, 2)
            IF __Channel(chan).period > __Channel(chan).portamentoTo THEN __Channel(chan).period = __Channel(chan).portamentoTo
        ELSEIF __Channel(chan).period > __Channel(chan).portamentoTo THEN
            __Channel(chan).period = __Channel(chan).period - _SHL(__Channel(chan).portamentoSpeed, 2)
            IF __Channel(chan).period < __Channel(chan).portamentoTo THEN __Channel(chan).period = __Channel(chan).portamentoTo
        END IF

        IF __Channel(chan).useGlissando THEN
            SetVoiceFrequency chan, __GetFrequencyFromPeriod(__GetClosestPeriod(__Channel(chan).period))
        ELSE
            SetVoiceFrequency chan, __GetFrequencyFromPeriod(__Channel(chan).period)
        END IF
    END SUB


    ' Carry out a volume slide using +x -y
    SUB __DoVolumeSlide (chan AS _UNSIGNED _BYTE, x AS _UNSIGNED _BYTE, y AS _UNSIGNED _BYTE)
        SHARED __Channel() AS __ChannelType

        __Channel(chan).volume = __Channel(chan).volume + x - y
        IF __Channel(chan).volume < 0 THEN __Channel(chan).volume = 0
        IF __Channel(chan).volume > SAMPLE_VOLUME_MAX THEN __Channel(chan).volume = SAMPLE_VOLUME_MAX

        SetVoiceVolume chan, __Channel(chan).volume
    END SUB


    ' Carry out a vibrato at a certain depth and speed
    SUB __DoVibrato (chan AS _UNSIGNED _BYTE)
        SHARED __Channel() AS __ChannelType
        SHARED __SineTable() AS _UNSIGNED _BYTE

        DIM delta AS _UNSIGNED INTEGER
        DIM temp AS _UNSIGNED _BYTE

        temp = __Channel(chan).vibratoPosition AND 31

        SELECT CASE __Channel(chan).waveControl AND 3
            CASE 0 ' Sine
                delta = __SineTable(temp)

            CASE 1 ' Saw down
                temp = _SHL(temp, 3)
                IF __Channel(chan).vibratoPosition < 0 THEN temp = 255 - temp
                delta = temp

            CASE 2 ' Square
                delta = 255

            CASE 3 ' Random
                delta = RND * 255
        END SELECT

        delta = _SHL(_SHR(delta * __Channel(chan).vibratoDepth, 7), 2)

        IF __Channel(chan).vibratoPosition >= 0 THEN
            SetVoiceFrequency chan, __GetFrequencyFromPeriod(__Channel(chan).period + delta)
        ELSE
            SetVoiceFrequency chan, __GetFrequencyFromPeriod(__Channel(chan).period - delta)
        END IF

        __Channel(chan).vibratoPosition = __Channel(chan).vibratoPosition + __Channel(chan).vibratoSpeed
        IF __Channel(chan).vibratoPosition > 31 THEN __Channel(chan).vibratoPosition = __Channel(chan).vibratoPosition - 64
    END SUB


    ' Carry out a tremolo at a certain depth and speed
    SUB __DoTremolo (chan AS _UNSIGNED _BYTE)
        SHARED __Channel() AS __ChannelType
        SHARED __SineTable() AS _UNSIGNED _BYTE

        DIM delta AS _UNSIGNED INTEGER
        DIM temp AS _UNSIGNED _BYTE

        temp = __Channel(chan).tremoloPosition AND 31

        SELECT CASE _SHR(__Channel(chan).waveControl, 4) AND 3
            CASE 0 ' Sine
                delta = __SineTable(temp)

            CASE 1 ' Saw down
                temp = _SHL(temp, 3)
                IF __Channel(chan).tremoloPosition < 0 THEN temp = 255 - temp
                delta = temp

            CASE 2 ' Square
                delta = 255

            CASE 3 ' Random
                delta = RND * 255
        END SELECT

        delta = _SHR(delta * __Channel(chan).tremoloDepth, 6)

        IF __Channel(chan).tremoloPosition >= 0 THEN
            IF __Channel(chan).volume + delta > SAMPLE_VOLUME_MAX THEN delta = SAMPLE_VOLUME_MAX - __Channel(chan).volume
            SetVoiceVolume chan, __Channel(chan).volume + delta
        ELSE
            IF __Channel(chan).volume - delta < 0 THEN delta = __Channel(chan).volume
            SetVoiceVolume chan, __Channel(chan).volume - delta
        END IF

        __Channel(chan).tremoloPosition = __Channel(chan).tremoloPosition + __Channel(chan).tremoloSpeed
        IF __Channel(chan).tremoloPosition > 31 THEN __Channel(chan).tremoloPosition = __Channel(chan).tremoloPosition - 64
    END SUB


    ' Carry out an invert loop (EFx) effect
    ' This will trash the sample managed by the SoftSynth
    SUB __DoInvertLoop (chan AS _UNSIGNED _BYTE)
        SHARED __Channel() AS __ChannelType
        SHARED __Sample() AS __SampleType
        SHARED __InvertLoopSpeedTable() AS _UNSIGNED _BYTE

        __Channel(chan).invertLoopDelay = __Channel(chan).invertLoopDelay + __InvertLoopSpeedTable(__Channel(chan).invertLoopSpeed)

        IF __Sample(__Channel(chan).sample).loopLength > 0 AND __Channel(chan).invertLoopDelay >= 128 THEN
            __Channel(chan).invertLoopDelay = 0 ' reset delay
            IF __Channel(chan).invertLoopPosition < __Sample(__Channel(chan).sample).loopStart THEN __Channel(chan).invertLoopPosition = __Sample(__Channel(chan).sample).loopStart
            __Channel(chan).invertLoopPosition = __Channel(chan).invertLoopPosition + 1 ' increment position by 1
            IF __Channel(chan).invertLoopPosition > __Sample(__Channel(chan).sample).loopEnd THEN __Channel(chan).invertLoopPosition = __Sample(__Channel(chan).sample).loopStart

            ' Yeah I know, this is weird. QB64 NOT is bitwise and not logical
            PokeSample __Channel(chan).sample, __Channel(chan).invertLoopPosition, NOT PeekSample(__Channel(chan).sample, __Channel(chan).invertLoopPosition)
        END IF
    END SUB


    ' This gives us the frequency in khz based on the period
    FUNCTION __GetFrequencyFromPeriod! (period AS LONG)
        __GetFrequencyFromPeriod = 14317056 / period
    END FUNCTION


    ' Return C2 speed for a finetune
    FUNCTION __GetC2Spd~% (ft AS _UNSIGNED _BYTE)
        SELECT CASE ft
            CASE 0
                __GetC2Spd = 8363
            CASE 1
                __GetC2Spd = 8413
            CASE 2
                __GetC2Spd = 8463
            CASE 3
                __GetC2Spd = 8529
            CASE 4
                __GetC2Spd = 8581
            CASE 5
                __GetC2Spd = 8651
            CASE 6
                __GetC2Spd = 8723
            CASE 7
                __GetC2Spd = 8757
            CASE 8
                __GetC2Spd = 7895
            CASE 9
                __GetC2Spd = 7941
            CASE 10
                __GetC2Spd = 7985
            CASE 11
                __GetC2Spd = 8046
            CASE 12
                __GetC2Spd = 8107
            CASE 13
                __GetC2Spd = 8169
            CASE 14
                __GetC2Spd = 8232
            CASE 15
                __GetC2Spd = 8280
            CASE ELSE
                __GetC2Spd = 8363
        END SELECT
    END FUNCTION
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' MODULE FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'MemFile.bas'
    '$INCLUDE:'FileOps.bas'
    '$INCLUDE:'SoftSynth.bas'
    '-------------------------------------------------------------------------------------------------------------------
$END IF
'-----------------------------------------------------------------------------------------------------------------------

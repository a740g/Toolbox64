'---------------------------------------------------------------------------------------------------------
' MOD Player Library
' Copyright (c) 2023 Samuel Gomes
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'MemFile.bi'
'$Include:'FileOps.bi'
'$Include:'MODPlayer.bi'
'---------------------------------------------------------------------------------------------------------

$If MODPLAYER_BAS = UNDEFINED Then
    $Let MODPLAYER_BAS = TRUE
    '-----------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-----------------------------------------------------------------------------------------------------
    '$Debug
    '$Asserts
    'If LoadMODFromDisk("C:\Users\samue\source\repos\a740g\QB64-MOD-Player\mods\emax-doz.mod") Then
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
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-----------------------------------------------------------------------------------------------------
    ' Loads the MOD file into memory and prepares all required gobals
    Function LoadMODFromMemory%% (buffer As String)
        Shared __Song As __SongType
        Shared __Order() As _Unsigned _Byte
        Shared __Pattern() As __NoteType
        Shared __Sample() As __SampleType
        Shared __PeriodTable() As _Unsigned Integer

        ' Attempt to open the file
        Dim memFile As _Unsigned _Offset: memFile = MemFile_Create(buffer)
        If memFile = NULL Then Exit Function

        ' Check what kind of MOD file this is
        ' Seek to offset 1080 (438h) in the file & read in 4 bytes
        Dim i As _Unsigned Integer, result As Long
        result = MemFile_Seek(memFile, 1080)
        _Assert result
        result = MemFile_ReadString(memFile, __Song.subtype)
        _Assert (result = Len(__Song.subtype))

        ' Also, seek to the beginning of the file and get the song title
        result = MemFile_Seek(memFile, 0)
        _Assert result
        result = MemFile_ReadString(memFile, __Song.songName)
        _Assert (result = Len(__Song.songName))

        __Song.channels = 0
        __Song.samples = 0

        Select Case __Song.subtype
            Case "FEST", "FIST", "LARD", "M!K!", "M&K!", "M.K.", "N.T.", "NSMS", "PATT"
                __Song.channels = 4
                __Song.samples = 31
            Case "OCTA", "OKTA"
                __Song.channels = 8
                __Song.samples = 31
            Case Else
                ' Parse the subtype string to check for more variants
                If Right$(__Song.subtype, 3) = "CHN" Then
                    ' Check xCNH types
                    __Song.channels = Val(Left$(__Song.subtype, 1))
                    __Song.samples = 31
                ElseIf Right$(__Song.subtype, 2) = "CH" Or Right$(__Song.subtype, 2) = "CN" Then
                    ' Check for xxCH & xxCN types
                    __Song.channels = Val(Left$(__Song.subtype, 2))
                    __Song.samples = 31
                ElseIf Left$(__Song.subtype, 3) = "FLT" Or Left$(__Song.subtype, 3) = "TDZ" Or Left$(__Song.subtype, 3) = "EXO" Then
                    ' Check for FLTx, TDZx & EXOx types
                    __Song.channels = Val(Right$(__Song.subtype, 1))
                    __Song.samples = 31
                ElseIf Left$(__Song.subtype, 2) = "CD" And Right$(__Song.subtype, 1) = "1" Then
                    ' Check for CDx1 types
                    __Song.channels = Val(Mid$(__Song.subtype, 3, 1))
                    __Song.samples = 31
                ElseIf Left$(__Song.subtype, 2) = "FA" Then
                    ' Check for FAxx types
                    __Song.channels = Val(Right$(__Song.subtype, 2))
                    __Song.samples = 31
                Else
                    ' Extra checks for 15 sample MOD
                    For i = 1 To Len(__Song.songName)
                        If Asc(__Song.songName, i) < KEY_SPACE_BAR And Asc(__Song.songName, i) <> NULL Then
                            ' This is probably not a 15 sample MOD file
                            MemFile_Destroy memFile
                            Exit Function
                        End If
                    Next
                    __Song.channels = 4
                    __Song.samples = 15
                    __Song.subtype = "MODF" ' Change subtype to reflect 15 (Fh) sample mod, otherwise it will contain garbage
                End If
        End Select

        ' Sanity check
        If (__Song.samples = 0 Or __Song.channels = 0) Then
            MemFile_Destroy memFile
            Exit Function
        End If

        ' Initialize the sample manager
        ReDim __Sample(0 To __Song.samples - 1) As __SampleType
        Dim As _Unsigned _Byte byte1, byte2

        ' Load the sample headers
        For i = 0 To __Song.samples - 1
            ' Read the sample name
            result = MemFile_ReadString(memFile, __Sample(i).sampleName)
            _Assert (result = Len(__Sample(i).sampleName))

            ' Read sample length
            result = MemFile_ReadByte(memFile, byte1)
            _Assert result
            result = MemFile_ReadByte(memFile, byte2)
            _Assert result

            __Sample(i).length = (byte1 * &H100 + byte2) * 2
            If __Sample(i).length = 2 Then __Sample(i).length = 0 ' Sanity check

            ' Read finetune
            result = MemFile_ReadByte(memFile, __Sample(i).c2Spd)
            _Assert result
            __Sample(i).c2Spd = __GetC2Spd(__Sample(i).c2Spd) ' Convert finetune to c2spd

            ' Read volume
            result = MemFile_ReadByte(memFile, __Sample(i).volume)
            _Assert result
            If __Sample(i).volume > SAMPLE_VOLUME_MAX Then __Sample(i).volume = SAMPLE_VOLUME_MAX ' Sanity check

            ' Read loop start
            result = MemFile_ReadByte(memFile, byte1)
            _Assert result
            result = MemFile_ReadByte(memFile, byte2)
            _Assert result
            __Sample(i).loopStart = (byte1 * &H100 + byte2) * 2
            If __Sample(i).loopStart >= __Sample(i).length Then __Sample(i).loopStart = 0 ' Sanity check

            ' Read loop length
            result = MemFile_ReadByte(memFile, byte1)
            _Assert result
            result = MemFile_ReadByte(memFile, byte2)
            _Assert result
            __Sample(i).loopLength = (byte1 * &H100 + byte2) * 2
            If __Sample(i).loopLength = 2 Then __Sample(i).loopLength = 0 ' Sanity check

            ' Calculate repeat end
            __Sample(i).loopEnd = __Sample(i).loopStart + __Sample(i).loopLength
            If __Sample(i).loopEnd > __Sample(i).length Then __Sample(i).loopEnd = __Sample(i).length ' Sanity check
        Next

        result = MemFile_ReadByte(memFile, __Song.orders)
        _Assert result
        If __Song.orders > __ORDER_TABLE_MAX + 1 Then __Song.orders = __ORDER_TABLE_MAX + 1
        result = MemFile_ReadByte(memFile, __Song.endJumpOrder)
        _Assert result
        If __Song.endJumpOrder >= __Song.orders Then __Song.endJumpOrder = 0

        'Load the pattern table, and find the highest pattern to load.
        __Song.highestPattern = 0
        For i = 0 To __ORDER_TABLE_MAX
            result = MemFile_ReadByte(memFile, __Order(i))
            _Assert result
            If __Order(i) > __Song.highestPattern Then __Song.highestPattern = __Order(i)
        Next

        ' Resize pattern data array
        ReDim __Pattern(0 To __Song.highestPattern, 0 To __PATTERN_ROW_MAX, 0 To __Song.channels - 1) As __NoteType

        ' Skip past the 4 byte marker if this is a 31 sample mod
        If __Song.samples = 31 Then
            result = MemFile_Seek(memFile, MemFile_GetPosition(memFile) + 4)
        End If

        ' Load the period table
        Restore PeriodTab
        Read __Song.periodTableMax ' Read the size
        __Song.periodTableMax = __Song.periodTableMax - 1 ' Change to ubound
        ReDim __PeriodTable(0 To __Song.periodTableMax) As _Unsigned Integer ' Allocate size elements
        ' Now read size values
        For i = 0 To __Song.periodTableMax
            Read __PeriodTable(i)
        Next

        Dim As _Unsigned _Byte byte3, byte4
        Dim As _Unsigned Integer a, b, c, period

        ' Load the patterns
        ' +-------------------------------------+
        ' | Byte 0    Byte 1   Byte 2   Byte 3  |
        ' +-------------------------------------+
        ' |aaaaBBBB CCCCCCCCC DDDDeeee FFFFFFFFF|
        ' +-------------------------------------+
        ' TODO: special handling for FLT8?
        For i = 0 To __Song.highestPattern
            For a = 0 To __PATTERN_ROW_MAX
                For b = 0 To __Song.channels - 1
                    result = MemFile_ReadByte(memFile, byte1)
                    _Assert result
                    result = MemFile_ReadByte(memFile, byte2)
                    _Assert result
                    result = MemFile_ReadByte(memFile, byte3)
                    _Assert result
                    result = MemFile_ReadByte(memFile, byte4)
                    _Assert result

                    __Pattern(i, a, b).sample = (byte1 And &HF0) Or _ShR(byte3, 4)

                    period = _ShL(byte1 And &HF, 8) Or byte2

                    ' Do the look up in the table against what is read in and store note
                    __Pattern(i, a, b).note = __NOTE_NONE
                    For c = 0 To 107
                        If period >= __PeriodTable(c + 24) Then
                            __Pattern(i, a, b).note = c
                            Exit For
                        End If
                    Next

                    __Pattern(i, a, b).volume = __NOTE_NO_VOLUME ' MODs don't have any volume field in the pattern
                    __Pattern(i, a, b).effect = byte3 And &HF
                    __Pattern(i, a, b).operand = byte4

                    ' Some sanity check
                    If __Pattern(i, a, b).sample > __Song.samples Then __Pattern(i, a, b).sample = 0 ' Sample 0 means no sample. So valid sample are 1-15/31
                Next
            Next
        Next

        ' Initialize the softsynth sample manager
        InitializeSampleManager __Song.samples

        Dim sampBuf As String
        ' Load the samples
        For i = 0 To __Song.samples - 1
            sampBuf = Space$(__Sample(i).length)
            result = MemFile_ReadString(memFile, sampBuf)
            ' Load sample size bytes of data and send it to our softsynth sample manager
            LoadSample i, sampBuf, __Sample(i).loopLength > 0, __Sample(i).loopStart, __Sample(i).loopEnd
        Next

        MemFile_Destroy memFile

        LoadMODFromMemory = TRUE

        ' Amiga period table data for 11 octaves
        PeriodTab:
        Data 134
        Data 27392,25856,24384,23040,21696,20480,19328,18240,17216,16256,15360,14496
        Data 13696,12928,12192,11520,10848,10240,9664,9120,8608,8128,7680,7248
        Data 6848,6464,6096,5760,5424,5120,4832,4560,4304,4064,3840,3624
        Data 3424,3232,3048,2880,2712,2560,2416,2280,2152,2032,1920,1812
        Data 1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960,906
        Data 856,808,762,720,678,640,604,570,538,508,480,453
        Data 428,404,381,360,339,320,302,285,269,254,240,226
        Data 214,202,190,180,170,160,151,143,135,127,120,113
        Data 107,101,95,90,85,80,75,71,67,63,60,56
        Data 53,50,47,45,42,40,37,35,33,31,30,28
        Data 26,25,23,22,21,20,18,17,16,15,15,14
        Data 0,0
        Data NaN
    End Function


    ' Load the MOD file from disk or a URL
    Function LoadMODFromDisk%% (fileName As String)
        LoadMODFromDisk = LoadMODFromMemory(LoadFile(fileName))
    End Function


    ' Initializes the audio mixer, prepares eveything else for playback and kick starts the timer and hence song playback
    Sub StartMODPlayer
        Shared __Song As __SongType
        Shared __Channel() As __ChannelType
        Shared __SineTable() As _Unsigned _Byte
        Shared __InvertLoopSpeedTable() As _Unsigned _Byte
        Shared SoftSynth As SoftSynthType

        Dim As _Unsigned Integer i, s

        ' Load the sine table
        Restore SineTab
        Read s
        ReDim __SineTable(0 To s - 1) As _Unsigned _Byte
        For i = 0 To s - 1
            Read __SineTable(i)
        Next

        ' Load the invert loop table
        Restore ILSpdTab
        Read s
        ReDim __InvertLoopSpeedTable(0 To s - 1) As _Unsigned _Byte
        For i = 0 To s - 1
            Read __InvertLoopSpeedTable(i)
        Next

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
        ReDim __Channel(0 To __Song.channels - 1) As __ChannelType

        ' Setup panning for all channels per AMIGA PAULA's panning setup - LRRLLRRL...
        ' If we have < 4 channels, then 0 & 1 are set as left & right
        ' If we have > 4 channels all prefect 4 groups are set as LRRL
        ' Any channels that are left out are simply centered by the SoftSynth
        ' We will also not do hard left or hard right. ~25% of sound from each channel is blended with the other
        If __Song.channels > 1 And __Song.channels < 4 Then
            ' Just setup channels 0 and 1
            ' If we have a 3rd channel it will be handle by the SoftSynth
            SetVoicePanning 0, SAMPLE_PAN_LEFT + SAMPLE_PAN_CENTER / 2
            SetVoicePanning 1, SAMPLE_PAN_RIGHT - SAMPLE_PAN_CENTER / 2
        Else
            For i = 0 To __Song.channels - 1 - (__Song.channels Mod 4) Step 4
                SetVoicePanning i + 0, SAMPLE_PAN_LEFT + SAMPLE_PAN_CENTER / 2
                SetVoicePanning i + 1, SAMPLE_PAN_RIGHT - SAMPLE_PAN_CENTER / 2
                SetVoicePanning i + 2, SAMPLE_PAN_RIGHT - SAMPLE_PAN_CENTER / 2
                SetVoicePanning i + 3, SAMPLE_PAN_LEFT + SAMPLE_PAN_CENTER / 2
            Next
        End If

        __Song.isPlaying = TRUE

        ' Sine table data for tremolo & vibrato
        SineTab:
        Data 32
        Data 0,24,49,74,97,120,141,161,180,197,212,224,235,244,250,253,255,253,250,244,235,224,212,197,180,161,141,120,97,74,49,24
        Data NaN

        ' Invert loop speed table data for EFx
        ILSpdTab:
        Data 16
        Data 0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128
        Data NaN
    End Sub


    ' Frees all allocated resources, stops the timer and hence song playback
    Sub StopMODPlayer
        Shared __Song As __SongType

        ' Tell softsynth we are done
        FinalizeMixer

        __Song.isPlaying = FALSE
    End Sub


    ' This should be called at regular intervals to run the mod player and mixer code
    ' You can call this as frequenctly as you want. The routine will simply exit if nothing is to be done
    Sub UpdateMODPlayer
        Shared __Song As __SongType
        Shared __Order() As _Unsigned _Byte

        ' Check conditions for which we should just exit and not process anything
        If __Song.orderPosition >= __Song.orders Then Exit Sub

        ' Set the playing flag to true
        __Song.isPlaying = TRUE

        ' If song is paused or we already have enough samples to play then exit
        If __Song.isPaused Or Not NeedsSoundRefill Then Exit Sub

        If __Song.tick >= __Song.speed Then
            ' Reset song tick
            __Song.tick = 0

            ' Process pattern row if pattern delay is over
            If __Song.patternDelay = 0 Then

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
                If __Song.patternRow > __PATTERN_ROW_MAX Then
                    __Song.orderPosition = __Song.orderPosition + 1
                    __Song.patternRow = 0

                    ' Check if we need to loop or stop
                    If __Song.orderPosition >= __Song.orders Then
                        If __Song.isLooping Then
                            __Song.orderPosition = __Song.endJumpOrder
                            __Song.speed = __SONG_SPEED_DEFAULT
                            __Song.tick = __Song.speed
                        Else
                            __Song.isPlaying = FALSE
                        End If
                    End If
                End If
            Else
                __Song.patternDelay = __Song.patternDelay - 1
            End If
        Else
            __UpdateMODTick
        End If

        ' Mix the current tick
        UpdateMixer __Song.samplesPerTick

        ' Increment song tick on each update
        __Song.tick = __Song.tick + 1
    End Sub


    ' Updates a row of notes and play them out on tick 0
    Sub __UpdateMODRow
        Shared __Song As __SongType
        Shared __Pattern() As __NoteType
        Shared __Sample() As __SampleType
        Shared __Channel() As __ChannelType
        Shared __PeriodTable() As _Unsigned Integer

        Dim As _Unsigned _Byte nChannel, nNote, nSample, nVolume, nEffect, nOperand, nOpX, nOpY
        ' The effect flags below are set to true when a pattern jump effect and pattern break effect are triggered
        Dim As _Byte jumpEffectFlag, breakEffectFlag, noFrequency

        ' Set the active channel count to zero
        __Song.activeChannels = 0

        ' Process all channels
        For nChannel = 0 To __Song.channels - 1
            nNote = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).note
            nSample = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).sample
            nVolume = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).volume
            nEffect = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).effect
            nOperand = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).operand
            nOpX = _ShR(nOperand, 4)
            nOpY = nOperand And &HF
            noFrequency = FALSE

            ' Set volume. We never play if sample number is zero. Our sample array is 1 based
            ' ONLY RESET VOLUME IF THERE IS A SAMPLE NUMBER
            If nSample > 0 Then
                __Channel(nChannel).sample = nSample - 1
                ' Don't get the volume if delay note, set it when the delay note actually happens
                If Not (nEffect = &HE And nOpX = &HD) Then
                    __Channel(nChannel).volume = __Sample(__Channel(nChannel).sample).volume
                End If
            End If

            If nNote < __NOTE_NONE Then
                __Channel(nChannel).lastPeriod = 8363 * __PeriodTable(nNote) \ __Sample(__Channel(nChannel).sample).c2Spd
                __Channel(nChannel).note = nNote
                __Channel(nChannel).restart = TRUE
                __Channel(nChannel).startPosition = 0
                __Song.activeChannels = nChannel

                ' Retrigger tremolo and vibrato waveforms
                If __Channel(nChannel).waveControl And &HF < 4 Then __Channel(nChannel).vibratoPosition = 0
                If _ShR(__Channel(nChannel).waveControl, 4) < 4 Then __Channel(nChannel).tremoloPosition = 0

                ' ONLY RESET FREQUENCY IF THERE IS A NOTE VALUE AND PORTA NOT SET
                If nEffect <> &H3 And nEffect <> &H5 Then
                    __Channel(nChannel).period = __Channel(nChannel).lastPeriod
                End If
            Else
                __Channel(nChannel).restart = FALSE
            End If

            If nVolume <= SAMPLE_VOLUME_MAX Then __Channel(nChannel).volume = nVolume
            If nNote = __NOTE_KEY_OFF Then __Channel(nChannel).volume = 0

            ' Process tick 0 effects
            Select Case nEffect
                Case &H3 ' 3: Porta To Note
                    If nOperand > 0 Then __Channel(nChannel).portamentoSpeed = nOperand
                    __Channel(nChannel).portamentoTo = __Channel(nChannel).lastPeriod
                    __Channel(nChannel).restart = FALSE

                Case &H5 ' 5: Tone Portamento + Volume Slide
                    __Channel(nChannel).portamentoTo = __Channel(nChannel).lastPeriod
                    __Channel(nChannel).restart = FALSE

                Case &H4 ' 4: Vibrato
                    If nOpX > 0 Then __Channel(nChannel).vibratoSpeed = nOpX
                    If nOpY > 0 Then __Channel(nChannel).vibratoDepth = nOpY

                Case &H7 ' 7: Tremolo
                    If nOpX > 0 Then __Channel(nChannel).tremoloSpeed = nOpX
                    If nOpY > 0 Then __Channel(nChannel).tremoloDepth = nOpY

                Case &H8 ' 8: Set Panning Position
                    ' Don't care about DMP panning BS. We are doing this Fasttracker style
                    SetVoicePanning nChannel, nOperand

                Case &H9 ' 9: Set Sample Offset
                    If nOperand > 0 Then __Channel(nChannel).startPosition = _ShL(nOperand, 8)

                Case &HB ' 11: Jump To Pattern
                    __Song.orderPosition = nOperand
                    If __Song.orderPosition >= __Song.orders Then __Song.orderPosition = __Song.endJumpOrder
                    __Song.patternRow = -1 ' This will increment right after & we will start at 0
                    jumpEffectFlag = TRUE

                Case &HC ' 12: Set Volume
                    __Channel(nChannel).volume = nOperand ' Operand can never be -ve cause it is unsigned. So we only clip for max below
                    If __Channel(nChannel).volume > SAMPLE_VOLUME_MAX Then __Channel(nChannel).volume = SAMPLE_VOLUME_MAX

                Case &HD ' 13: Pattern Break
                    __Song.patternRow = (nOpX * 10) + nOpY - 1
                    If __Song.patternRow > __PATTERN_ROW_MAX Then __Song.patternRow = -1
                    If Not breakEffectFlag And Not jumpEffectFlag Then
                        __Song.orderPosition = __Song.orderPosition + 1
                        If __Song.orderPosition >= __Song.orders Then __Song.orderPosition = __Song.endJumpOrder
                    End If
                    breakEffectFlag = TRUE

                Case &HE ' 14: Extended Effects
                    Select Case nOpX
                        Case &H0 ' 0: Set Filter
                            EnableHQMixer nOpY

                        Case &H1 ' 1: Fine Portamento Up
                            __Channel(nChannel).period = __Channel(nChannel).period - _ShL(nOpY, 2)

                        Case &H2 ' 2: Fine Portamento Down
                            __Channel(nChannel).period = __Channel(nChannel).period + _ShL(nOpY, 2)

                        Case &H3 ' 3: Glissando Control
                            __Channel(nChannel).useGlissando = (nOpY <> FALSE)

                        Case &H4 ' 4: Set Vibrato Waveform
                            __Channel(nChannel).waveControl = __Channel(nChannel).waveControl And &HF0
                            __Channel(nChannel).waveControl = __Channel(nChannel).waveControl Or nOpY

                        Case &H5 ' 5: Set Finetune
                            __Sample(__Channel(nChannel).sample).c2Spd = __GetC2Spd(nOpY)

                        Case &H6 ' 6: Pattern Loop
                            If nOpY = 0 Then
                                __Channel(nChannel).patternLoopRow = __Song.tickPatternRow
                            Else
                                If __Channel(nChannel).patternLoopRowCounter = 0 Then
                                    __Channel(nChannel).patternLoopRowCounter = nOpY
                                Else
                                    __Channel(nChannel).patternLoopRowCounter = __Channel(nChannel).patternLoopRowCounter - 1
                                End If
                                If __Channel(nChannel).patternLoopRowCounter > 0 Then __Song.patternRow = __Channel(nChannel).patternLoopRow - 1
                            End If

                        Case &H7 ' 7: Set Tremolo WaveForm
                            __Channel(nChannel).waveControl = __Channel(nChannel).waveControl And &HF
                            __Channel(nChannel).waveControl = __Channel(nChannel).waveControl Or _ShL(nOpY, 4)

                        Case &H8 ' 8: 16 position panning
                            If nOpY > 15 Then nOpY = 15
                            ' Why does this kind of stuff bother me so much. We could have just written "/ 17" XD
                            SetVoicePanning nChannel, nOpY * ((SAMPLE_PAN_RIGHT - SAMPLE_PAN_LEFT) / 15)

                        Case &HA ' 10: Fine Volume Slide Up
                            __Channel(nChannel).volume = __Channel(nChannel).volume + nOpY
                            If __Channel(nChannel).volume > SAMPLE_VOLUME_MAX Then __Channel(nChannel).volume = SAMPLE_VOLUME_MAX

                        Case &HB ' 11: Fine Volume Slide Down
                            __Channel(nChannel).volume = __Channel(nChannel).volume - nOpY
                            If __Channel(nChannel).volume < 0 Then __Channel(nChannel).volume = 0

                        Case &HD ' 13: Delay Note
                            __Channel(nChannel).restart = FALSE
                            noFrequency = TRUE

                        Case &HE ' 14: Pattern Delay
                            __Song.patternDelay = nOpY

                        Case &HF ' 15: Invert Loop
                            __Channel(nChannel).invertLoopSpeed = nOpY
                    End Select

                Case &HF ' 15: Set Speed
                    If nOperand < 32 Then
                        __Song.speed = nOperand
                    Else
                        __SetBPM nOperand
                    End If
            End Select

            __DoInvertLoop nChannel ' called every tick

            If Not noFrequency Then
                If nEffect <> 7 Then SetVoiceVolume nChannel, __Channel(nChannel).volume
                If __Channel(nChannel).period > 0 Then SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)
            End If
        Next

        ' Now play all samples that needs to be played
        For nChannel = 0 To __Song.activeChannels
            If __Channel(nChannel).restart Then
                If __Sample(__Channel(nChannel).sample).loopLength > 0 Then
                    PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition, SAMPLE_PLAY_LOOP, __Sample(__Channel(nChannel).sample).loopStart, __Sample(__Channel(nChannel).sample).loopEnd
                Else
                    PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition, SAMPLE_PLAY_SINGLE, 0, __Sample(__Channel(nChannel).sample).length
                End If
            End If
        Next
    End Sub


    ' Updates any tick based effects after tick 0
    Sub __UpdateMODTick
        Shared __Song As __SongType
        Shared __Pattern() As __NoteType
        Shared __Sample() As __SampleType
        Shared __Channel() As __ChannelType
        Shared __PeriodTable() As _Unsigned Integer

        Dim As _Unsigned _Byte nChannel, nVolume, nEffect, nOperand, nOpX, nOpY

        ' Process all channels
        For nChannel = 0 To __Song.channels - 1
            ' Only process if we have a period set
            If __Channel(nChannel).period > 0 Then
                ' We are not processing a new row but tick 1+ effects
                ' So we pick these using tickPattern and tickPatternRow
                nVolume = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).volume
                nEffect = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).effect
                nOperand = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).operand
                nOpX = _ShR(nOperand, 4)
                nOpY = nOperand And &HF

                __DoInvertLoop nChannel ' called every tick

                Select Case nEffect
                    Case &H0 ' 0: Arpeggio
                        If (nOperand > 0) Then
                            Select Case __Song.tick Mod 3 'TODO: Check why 0, 1, 2 sounds wierd
                                Case 0
                                    SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)
                                Case 1
                                    SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__PeriodTable(__Channel(nChannel).note + nOpX))
                                Case 2
                                    SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__PeriodTable(__Channel(nChannel).note + nOpY))
                            End Select
                        End If

                    Case &H1 ' 1: Porta Up
                        __Channel(nChannel).period = __Channel(nChannel).period - _ShL(nOperand, 2)
                        SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)
                        If __Channel(nChannel).period < 56 Then __Channel(nChannel).period = 56

                    Case &H2 ' 2: Porta Down
                        __Channel(nChannel).period = __Channel(nChannel).period + _ShL(nOperand, 2)
                        SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)

                    Case &H3 ' 3: Porta To Note
                        __DoPortamento nChannel

                    Case &H4 ' 4: Vibrato
                        __DoVibrato nChannel

                    Case &H5 ' 5: Tone Portamento + Volume Slide
                        __DoPortamento nChannel
                        __DoVolumeSlide nChannel, nOpX, nOpY

                    Case &H6 ' 6: Vibrato + Volume Slide
                        __DoVibrato nChannel
                        __DoVolumeSlide nChannel, nOpX, nOpY

                    Case &H7 ' 7: Tremolo
                        __DoTremolo nChannel

                    Case &HA ' 10: Volume Slide
                        __DoVolumeSlide nChannel, nOpX, nOpY

                    Case &HE ' 14: Extended Effects
                        Select Case nOpX
                            Case &H9 ' 9: Retrigger Note
                                If nOpY <> 0 Then
                                    If __Song.tick Mod nOpY = 0 Then
                                        If __Sample(__Channel(nChannel).sample).loopLength > 0 Then
                                            PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition, SAMPLE_PLAY_LOOP, __Sample(__Channel(nChannel).sample).loopStart, __Sample(__Channel(nChannel).sample).loopEnd
                                        Else
                                            PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition, SAMPLE_PLAY_SINGLE, 0, __Sample(__Channel(nChannel).sample).length
                                        End If
                                    End If
                                End If

                            Case &HC ' 12: Cut Note
                                If __Song.tick = nOpY Then
                                    __Channel(nChannel).volume = 0
                                    SetVoiceVolume nChannel, __Channel(nChannel).volume
                                End If

                            Case &HD ' 13: Delay Note
                                If __Song.tick = nOpY Then
                                    __Channel(nChannel).volume = __Sample(__Channel(nChannel).sample).volume
                                    If nVolume <= SAMPLE_VOLUME_MAX Then __Channel(nChannel).volume = nVolume
                                    SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)
                                    SetVoiceVolume nChannel, __Channel(nChannel).volume
                                    If __Sample(__Channel(nChannel).sample).loopLength > 0 Then
                                        PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition, SAMPLE_PLAY_LOOP, __Sample(__Channel(nChannel).sample).loopStart, __Sample(__Channel(nChannel).sample).loopEnd
                                    Else
                                        PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition, SAMPLE_PLAY_SINGLE, 0, __Sample(__Channel(nChannel).sample).length
                                    End If
                                End If
                        End Select
                End Select
            End If
        Next
    End Sub


    ' We always set the global BPM using this and never directly
    Sub __SetBPM (nBPM As _Unsigned _Byte)
        Shared __Song As __SongType

        __Song.bpm = nBPM

        ' Calculate the number of samples we have to mix per tick
        __Song.samplesPerTick = __Song.tempoTimerValue \ nBPM
    End Sub


    ' Binary search the period table to find the closest value
    ' I hope this is the right way to do glissando. Oh well...
    Function __GetClosestPeriod& (target As Long)
        Shared __Song As __SongType
        Shared __Channel() As __ChannelType
        Shared __PeriodTable() As _Unsigned Integer

        Dim As Long startPos, endPos, midPos, leftVal, rightVal

        If target > 27392 Then
            __GetClosestPeriod = target
            Exit Function
        ElseIf target < 14 Then
            __GetClosestPeriod = target
            Exit Function
        End If

        startPos = 0
        endPos = __Song.periodTableMax
        While startPos + 1 < endPos
            midPos = startPos + (endPos - startPos) \ 2
            If __PeriodTable(midPos) <= target Then
                endPos = midPos
            Else
                startPos = midPos
            End If
        Wend

        rightVal = Abs(__PeriodTable(startPos) - target)
        leftVal = Abs(__PeriodTable(endPos) - target)

        If leftVal <= rightVal Then
            __GetClosestPeriod = __PeriodTable(endPos)
        Else
            __GetClosestPeriod = __PeriodTable(startPos)
        End If
    End Function


    ' Carry out a tone portamento to a certain note
    Sub __DoPortamento (chan As _Unsigned _Byte)
        Shared __Channel() As __ChannelType

        ' Slide up/down and clamp to destination
        If __Channel(chan).period < __Channel(chan).portamentoTo Then
            __Channel(chan).period = __Channel(chan).period + _ShL(__Channel(chan).portamentoSpeed, 2)
            If __Channel(chan).period > __Channel(chan).portamentoTo Then __Channel(chan).period = __Channel(chan).portamentoTo
        ElseIf __Channel(chan).period > __Channel(chan).portamentoTo Then
            __Channel(chan).period = __Channel(chan).period - _ShL(__Channel(chan).portamentoSpeed, 2)
            If __Channel(chan).period < __Channel(chan).portamentoTo Then __Channel(chan).period = __Channel(chan).portamentoTo
        End If

        If __Channel(chan).useGlissando Then
            SetVoiceFrequency chan, __GetFrequencyFromPeriod(__GetClosestPeriod(__Channel(chan).period))
        Else
            SetVoiceFrequency chan, __GetFrequencyFromPeriod(__Channel(chan).period)
        End If
    End Sub


    ' Carry out a volume slide using +x -y
    Sub __DoVolumeSlide (chan As _Unsigned _Byte, x As _Unsigned _Byte, y As _Unsigned _Byte)
        Shared __Channel() As __ChannelType

        __Channel(chan).volume = __Channel(chan).volume + x - y
        If __Channel(chan).volume < 0 Then __Channel(chan).volume = 0
        If __Channel(chan).volume > SAMPLE_VOLUME_MAX Then __Channel(chan).volume = SAMPLE_VOLUME_MAX

        SetVoiceVolume chan, __Channel(chan).volume
    End Sub


    ' Carry out a vibrato at a certain depth and speed
    Sub __DoVibrato (chan As _Unsigned _Byte)
        Shared __Channel() As __ChannelType
        Shared __SineTable() As _Unsigned _Byte

        Dim delta As _Unsigned Integer
        Dim temp As _Unsigned _Byte

        temp = __Channel(chan).vibratoPosition And 31

        Select Case __Channel(chan).waveControl And 3
            Case 0 ' Sine
                delta = __SineTable(temp)

            Case 1 ' Saw down
                temp = _ShL(temp, 3)
                If __Channel(chan).vibratoPosition < 0 Then temp = 255 - temp
                delta = temp

            Case 2 ' Square
                delta = 255

            Case 3 ' Random
                delta = Rnd * 255
        End Select

        delta = _ShL(_ShR(delta * __Channel(chan).vibratoDepth, 7), 2)

        If __Channel(chan).vibratoPosition >= 0 Then
            SetVoiceFrequency chan, __GetFrequencyFromPeriod(__Channel(chan).period + delta)
        Else
            SetVoiceFrequency chan, __GetFrequencyFromPeriod(__Channel(chan).period - delta)
        End If

        __Channel(chan).vibratoPosition = __Channel(chan).vibratoPosition + __Channel(chan).vibratoSpeed
        If __Channel(chan).vibratoPosition > 31 Then __Channel(chan).vibratoPosition = __Channel(chan).vibratoPosition - 64
    End Sub


    ' Carry out a tremolo at a certain depth and speed
    Sub __DoTremolo (chan As _Unsigned _Byte)
        Shared __Channel() As __ChannelType
        Shared __SineTable() As _Unsigned _Byte

        Dim delta As _Unsigned Integer
        Dim temp As _Unsigned _Byte

        temp = __Channel(chan).tremoloPosition And 31

        Select Case _ShR(__Channel(chan).waveControl, 4) And 3
            Case 0 ' Sine
                delta = __SineTable(temp)

            Case 1 ' Saw down
                temp = _ShL(temp, 3)
                If __Channel(chan).tremoloPosition < 0 Then temp = 255 - temp
                delta = temp

            Case 2 ' Square
                delta = 255

            Case 3 ' Random
                delta = Rnd * 255
        End Select

        delta = _ShR(delta * __Channel(chan).tremoloDepth, 6)

        If __Channel(chan).tremoloPosition >= 0 Then
            If __Channel(chan).volume + delta > SAMPLE_VOLUME_MAX Then delta = SAMPLE_VOLUME_MAX - __Channel(chan).volume
            SetVoiceVolume chan, __Channel(chan).volume + delta
        Else
            If __Channel(chan).volume - delta < 0 Then delta = __Channel(chan).volume
            SetVoiceVolume chan, __Channel(chan).volume - delta
        End If

        __Channel(chan).tremoloPosition = __Channel(chan).tremoloPosition + __Channel(chan).tremoloSpeed
        If __Channel(chan).tremoloPosition > 31 Then __Channel(chan).tremoloPosition = __Channel(chan).tremoloPosition - 64
    End Sub


    ' Carry out an invert loop (EFx) effect
    ' This will trash the sample managed by the SoftSynth
    Sub __DoInvertLoop (chan As _Unsigned _Byte)
        Shared __Channel() As __ChannelType
        Shared __Sample() As __SampleType
        Shared __InvertLoopSpeedTable() As _Unsigned _Byte

        __Channel(chan).invertLoopDelay = __Channel(chan).invertLoopDelay + __InvertLoopSpeedTable(__Channel(chan).invertLoopSpeed)

        If __Sample(__Channel(chan).sample).loopLength > 0 And __Channel(chan).invertLoopDelay >= 128 Then
            __Channel(chan).invertLoopDelay = 0 ' reset delay
            If __Channel(chan).invertLoopPosition < __Sample(__Channel(chan).sample).loopStart Then __Channel(chan).invertLoopPosition = __Sample(__Channel(chan).sample).loopStart
            __Channel(chan).invertLoopPosition = __Channel(chan).invertLoopPosition + 1 ' increment position by 1
            If __Channel(chan).invertLoopPosition > __Sample(__Channel(chan).sample).loopEnd Then __Channel(chan).invertLoopPosition = __Sample(__Channel(chan).sample).loopStart

            ' Yeah I know, this is weird. QB64 NOT is bitwise and not logical
            PokeSample __Channel(chan).sample, __Channel(chan).invertLoopPosition, Not PeekSample(__Channel(chan).sample, __Channel(chan).invertLoopPosition)
        End If
    End Sub


    ' This gives us the frequency in khz based on the period
    Function __GetFrequencyFromPeriod! (period As Long)
        __GetFrequencyFromPeriod = 14317056 / period
    End Function


    ' Return C2 speed for a finetune
    Function __GetC2Spd~% (ft As _Unsigned _Byte)
        Select Case ft
            Case 0
                __GetC2Spd = 8363
            Case 1
                __GetC2Spd = 8413
            Case 2
                __GetC2Spd = 8463
            Case 3
                __GetC2Spd = 8529
            Case 4
                __GetC2Spd = 8581
            Case 5
                __GetC2Spd = 8651
            Case 6
                __GetC2Spd = 8723
            Case 7
                __GetC2Spd = 8757
            Case 8
                __GetC2Spd = 7895
            Case 9
                __GetC2Spd = 7941
            Case 10
                __GetC2Spd = 7985
            Case 11
                __GetC2Spd = 8046
            Case 12
                __GetC2Spd = 8107
            Case 13
                __GetC2Spd = 8169
            Case 14
                __GetC2Spd = 8232
            Case 15
                __GetC2Spd = 8280
            Case Else
                __GetC2Spd = 8363
        End Select
    End Function
    '-----------------------------------------------------------------------------------------------------
$End If

'---------------------------------------------------------------------------------------------------------
' MODULE FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'MemFile.bas'
'$Include:'FileOps.bas'
'$Include:'SoftSynth.bas'
'---------------------------------------------------------------------------------------------------------
'---------------------------------------------------------------------------------------------------------

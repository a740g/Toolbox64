'-----------------------------------------------------------------------------------------------------------------------
' MOD Player Library
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF MODPLAYER_BAS = UNDEFINED THEN
    $LET MODPLAYER_BAS = TRUE

    '$INCLUDE:'MODPlayer.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    '$DEBUG
    '$CONSOLE
    '$ASSERTS
    'IF MODPlayer_LoadFromDisk("http://ftp.modland.com/pub/modules/Protracker/4-Mat/true%20faith.mod") THEN
    '    SampleMixer_SetHighQuality TRUE
    '    MODPlayer_Play
    '    DO WHILE _KEYHIT <> 27 AND MODPlayer_IsPlaying
    '        MODPlayer_Update
    '        LOCATE 1, 1
    '        PRINT USING "Order: ### / ###    Pattern: ### / ###    Row: ## / 63    BPM: ###    Speed: ###"; MODPlayer_GetPosition; MODPlayer_GetOrders - 1; __Order(__Song.orderPosition); __Song.patterns - 1; __Song.patternRow; __Song.bpm; __Song.speed;
    '        _LIMIT 60
    '    LOOP
    '    MODPlayer_Stop
    'END IF
    'END
    '-------------------------------------------------------------------------------------------------------------------

    ' Loads all required LUTs from DATA
    SUB __LoadTables
        SHARED __Song AS __SongType
        SHARED __PeriodTable() AS _UNSIGNED INTEGER
        SHARED __SineTable() AS _UNSIGNED _BYTE
        SHARED __InvertLoopSpeedTable() AS _UNSIGNED _BYTE

        ' Load the period table
        RESTORE PeriodTab
        READ __Song.periodTableMax ' read the size
        __Song.periodTableMax = __Song.periodTableMax - 1 ' Change to ubound
        REDIM __PeriodTable(0 TO __Song.periodTableMax) AS _UNSIGNED INTEGER ' allocate size elements
        ' Now read size values
        DIM i AS LONG: FOR i = 0 TO __Song.periodTableMax
            READ __PeriodTable(i)
        NEXT

        ' Load the sine table
        RESTORE SineTab
        DIM s AS LONG: READ s
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


    ' Loads an MTM file into memory and prepairs all required globals
    FUNCTION __LoadMTMFromMemory%% (buffer AS STRING)
        SHARED __Song AS __SongType
        SHARED __Order() AS _UNSIGNED INTEGER
        SHARED __Pattern() AS __NoteType
        SHARED __Sample() AS __SampleType
        SHARED __Channel() AS __ChannelType

        __Song.isPlaying = FALSE ' just in case something is playing

        ' Open the buffer as a StringFile
        DIM memFile AS StringFileType
        StringFile_Create memFile, buffer

        ' Read the file signature
        __Song.subtype = StringFile_ReadString(memFile, 4) ' read 4 bytes. Last byte is the version

        ' Check if this is really an MTM file
        IF LEFT$(__Song.subtype, 3) <> "MTM" THEN EXIT FUNCTION

        ' Change the FourCC so that it is completely printable
        MID$(__Song.subtype, 4, 1) = HEX$(ASC(__Song.subtype, 4) - 15)

        ' Read the MTM song title (20 bytes)
        __Song.songName = StringFile_ReadString(memFile, 20) ' we'll leave the name untouched (these sometimes contain interesting stuff)

        ' Read the number of tracks saved
        DIM numTracks AS _UNSIGNED INTEGER: numTracks = StringFile_ReadInteger(memFile)

        ' Read the highest pattern number saved
        DIM byte1 AS _UNSIGNED _BYTE: byte1 = StringFile_ReadByte(memFile)
        __Song.patterns = byte1 + 1 ' convert to count / length

        ' Read the last order to play
        byte1 = StringFile_ReadByte(memFile)
        __Song.orders = byte1 + 1 ' convert to count / length

        ' Read length of the extra comment field
        DIM commentLen AS _UNSIGNED INTEGER: commentLen = StringFile_ReadInteger(memFile)

        ' Read the number of samples
        __Song.samples = StringFile_ReadByte(memFile)

        ' Read the attribute byte and discard it
        byte1 = StringFile_ReadByte(memFile)

        ' Read the beats per track (row count)
        __Song.rows = StringFile_ReadByte(memFile)

        ' Read the number of channels
        __Song.channels = StringFile_ReadByte(memFile)

        ' Sanity check
        IF numTracks = 0 OR __Song.samples = 0 OR __Song.rows = 0 OR __Song.channels = 0 THEN EXIT FUNCTION

        ' Resize the channel array
        REDIM __Channel(0 TO __Song.channels - 1) AS __ChannelType

        ' Initialize the softsynth sample mixer
        SampleMixer_Initialize __Song.channels ' this will re-initialize the mixer if it is already initialized

        ' Read the panning positions
        DIM i AS LONG: FOR i = 0 TO __MTM_CHANNELS - 1
            byte1 = StringFile_ReadByte(memFile) ' read the raw value

            ' Adjust and save the values per out mixer requirements
            IF byte1 < 16 AND i < __Song.channels THEN SampleMixer_SetVoicePanning i, (byte1 / 15) * 2 - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = (x / 15) * 2 - 1
        NEXT

        ' Resize the sample array
        REDIM __Sample(0 TO __Song.samples - 1) AS __SampleType

        ' Read the sample information
        FOR i = 0 TO __Song.samples - 1
            ' Read the sample name
            __Sample(i).sampleName = StringFile_ReadString(memFile, 22) ' MTM sample names are 22 bytes long. We'll leave the string untouched

            ' Read sample length
            __Sample(i).length = StringFile_ReadLong(memFile)

            ' Read loop start
            __Sample(i).loopStart = StringFile_ReadLong(memFile)
            IF __Sample(i).loopStart >= __Sample(i).length THEN __Sample(i).loopStart = 0 ' sanity check

            ' Read loop end
            __Sample(i).loopEnd = StringFile_ReadLong(memFile)
            IF __Sample(i).loopEnd > __Sample(i).length THEN __Sample(i).loopEnd = __Sample(i).length ' sanity check
            __Sample(i).loopLength = __Sample(i).loopEnd - __Sample(i).loopStart ' calculate loop length

            ' Read finetune
            __Sample(i).c2Spd = __GetC2Spd(StringFile_ReadByte(memFile)) ' convert finetune to c2spd

            ' Read volume
            __Sample(i).volume = StringFile_ReadByte(memFile)
            IF __Sample(i).volume > __MOD_SAMPLE_VOLUME_MAX THEN __Sample(i).volume = __MOD_SAMPLE_VOLUME_MAX ' MTM uses MOD volume specs.

            ' Read attribute
            byte1 = StringFile_ReadByte(memFile)
            __Sample(i).frameSize = SIZE_OF_BYTE + SIZE_OF_BYTE * (byte1 AND &H1) ' 1 if 8-bit else 2 if 16-bit
        NEXT

        ' Resize the order array (MTMs like MODs always have a 128 byte long order table)
        REDIM __Order(0 TO __MOD_ORDERS - 1) AS _UNSIGNED INTEGER

        ' Read order list
        FOR i = 0 TO __MOD_ORDERS - 1 ' MTMs like MODs always have a 128 byte long order table
            __Order(i) = StringFile_ReadByte(memFile)
        NEXT

        ' Read and convert track data
        DIM mtmTrack(0 TO numTracks - 1, 0 TO __Song.rows - 1) AS __NoteType, j AS LONG
        DIM AS _UNSIGNED _BYTE byte2, byte3
        FOR i = 0 TO numTracks - 1
            FOR j = 0 TO __Song.rows - 1
                ' Read 3 bytes
                byte1 = StringFile_ReadByte(memFile)
                byte2 = StringFile_ReadByte(memFile)
                byte3 = StringFile_ReadByte(memFile)

                ' +----------+----------+----------+
                ' |  BYTE 0  |  BYTE 1  |  BYTE 2  |
                ' | ppppppii | iiiieeee | aaaaaaaa |
                ' +----------+----------+----------+
                ' p = pitch value (0 = no pitch stated)
                ' i = instrument number (0 = no instrument number)
                ' e = effect number
                ' a = effect argument
                mtmTrack(i, j).note = _SHR(byte1, 2)
                IF mtmTrack(i, j).note = 0 THEN
                    mtmTrack(i, j).note = __NOTE_NONE
                ELSE
                    mtmTrack(i, j).note = mtmTrack(i, j).note + 24
                END IF

                mtmTrack(i, j).sample = _SHL(byte1 AND &H3, 4) OR _SHR(byte2, 4)
                IF mtmTrack(i, j).sample > __Song.samples THEN mtmTrack(i, j).sample = 0 ' sanity check

                mtmTrack(i, j).effect = byte2 AND &HF
                mtmTrack(i, j).operand = byte3
                mtmTrack(i, j).volume = __NOTE_NO_VOLUME

                ' MTM fix: when the effect is volume-slide, slide-up always overrides slide-down
                IF mtmTrack(i, j).effect = &HA AND (mtmTrack(i, j).operand AND &HF0) <> 0 THEN
                    mtmTrack(i, j).operand = mtmTrack(i, j).operand AND &HF0
                END IF
            NEXT
        NEXT

        ' Resize the pattern data array
        REDIM __Pattern(0 TO __Song.patterns - 1, 0 TO __Song.rows - 1, 0 TO __Song.channels - 1) AS __NoteType

        ' Read track sequencing data and assemble that to our pattern data
        DIM k AS LONG, w AS _UNSIGNED INTEGER
        FOR i = 0 TO __Song.patterns - 1
            FOR j = 0 TO __MTM_CHANNELS - 1 ' MTM files stores data for 32 channels irrespective of the actual channels used
                ' Read the data
                w = StringFile_ReadInteger(memFile)

                IF j >= __Song.channels THEN _CONTINUE ' ignore excess channel information

                IF w > 0 THEN
                    FOR k = 0 TO __Song.rows - 1
                        __Pattern(i, k, j) = mtmTrack(w - 1, k)
                    NEXT
                ELSE
                    ' Populate empty channel
                    FOR k = 0 TO __Song.rows - 1
                        __Pattern(i, k, j).note = __NOTE_NONE
                        __Pattern(i, k, j).sample = 0
                        __Pattern(i, k, j).effect = 0
                        __Pattern(i, k, j).operand = 0
                        __Pattern(i, k, j).volume = __NOTE_NO_VOLUME
                    NEXT
                END IF
            NEXT
        NEXT

        ' Read the tune comment
        __Song.comment = StringFile_ReadString(memFile, commentLen) ' read the comment and leave it untouched

        ' Initialize the softsynth sample manager
        SampleManager_Initialize __Song.samples

        ' Load the samples
        DIM sampBuf AS STRING
        FOR i = 0 TO __Song.samples - 1
            sampBuf = StringFile_ReadString(memFile, __Sample(i).length)

            ' Convert 8-bit unsigned samples to 8-bit signed
            IF __Sample(i).frameSize = SIZE_OF_BYTE THEN
                FOR j = 1 TO LEN(sampBuf)
                    ASC(sampBuf, j) = ASC(sampBuf, j) XOR &H80
                NEXT
            END IF

            ' Load sample size bytes of data and send it to our softsynth sample manager
            SampleManager_Load i, sampBuf, __Sample(i).frameSize, __Sample(i).loopLength > 0, __Sample(i).loopStart \ __Sample(i).frameSize, __Sample(i).loopEnd \ __Sample(i).frameSize
        NEXT

        ' Load all needed LUTs
        __LoadTables

        __LoadMTMFromMemory = TRUE
    END FUNCTION


    ' Loads the MOD file into memory and prepares all required globals
    FUNCTION __LoadMODFromMemory%% (buffer AS STRING)
        SHARED __Song AS __SongType
        SHARED __Order() AS _UNSIGNED INTEGER
        SHARED __Pattern() AS __NoteType
        SHARED __Sample() AS __SampleType
        SHARED __Channel() AS __ChannelType
        SHARED __PeriodTable() AS _UNSIGNED INTEGER

        __Song.isPlaying = FALSE ' just in case something is playing

        ' Attempt to open the file
        DIM i AS LONG, memFile AS StringFileType
        StringFile_Create memFile, buffer

        ' Seek to offset 1080 (438h) in the file & read in 4 bytes
        IF NOT StringFile_Seek(memFile, 1081) THEN EXIT FUNCTION ' 1081 because StringFile is 1 based

        ' Check what kind of MOD file this is
        __Song.subtype = StringFile_ReadString(memFile, 4) ' read 4 bytes

        ' Also, seek to the beginning of the file and get the song title
        IF NOT StringFile_Seek(memFile, 1) THEN EXIT FUNCTION ' 1 because StringFile is 1 based

        __Song.songName = StringFile_ReadString(memFile, 20) ' MOD song title is 20 bytes long

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
                        IF ASC(__Song.songName, i) < KEY_SPACE AND ASC(__Song.songName, i) <> NULL THEN EXIT FUNCTION ' this is probably not a 15 sample MOD file
                    NEXT
                    __Song.channels = 4
                    __Song.samples = 15
                    __Song.subtype = "MODF" ' change subtype to reflect 15 (Fh) sample mod, otherwise it will contain garbage
                END IF
        END SELECT

        ' Sanity check
        IF __Song.samples = 0 OR __Song.channels = 0 THEN EXIT FUNCTION

        ' Resize the sample array
        REDIM __Sample(0 TO __Song.samples - 1) AS __SampleType
        DIM AS _UNSIGNED _BYTE byte1, byte2

        ' Load the sample headers
        FOR i = 0 TO __Song.samples - 1
            ' Read the sample name
            __Sample(i).sampleName = StringFile_ReadString(memFile, 22) ' MOD sample names are 22 bytes long

            ' Read sample length
            byte1 = StringFile_ReadByte(memFile)
            byte2 = StringFile_ReadByte(memFile)
            __Sample(i).length = (byte1 * &H100 + byte2) * 2
            IF __Sample(i).length = 2 THEN __Sample(i).length = 0 ' Sanity check

            ' Read finetune
            __Sample(i).c2Spd = __GetC2Spd(StringFile_ReadByte(memFile)) ' convert finetune to c2spd

            ' Read volume
            __Sample(i).volume = StringFile_ReadByte(memFile)
            IF __Sample(i).volume > __MOD_SAMPLE_VOLUME_MAX THEN __Sample(i).volume = __MOD_SAMPLE_VOLUME_MAX ' Sanity check

            ' Read loop start
            byte1 = StringFile_ReadByte(memFile)
            byte2 = StringFile_ReadByte(memFile)
            __Sample(i).loopStart = (byte1 * &H100 + byte2) * 2
            IF __Sample(i).loopStart >= __Sample(i).length THEN __Sample(i).loopStart = 0 ' Sanity check

            ' Read loop length
            byte1 = StringFile_ReadByte(memFile)
            byte2 = StringFile_ReadByte(memFile)
            __Sample(i).loopLength = (byte1 * &H100 + byte2) * 2
            IF __Sample(i).loopLength = 2 THEN __Sample(i).loopLength = 0 ' sanity check
            __Sample(i).loopEnd = __Sample(i).loopStart + __Sample(i).loopLength ' calculate repeat end
            IF __Sample(i).loopEnd > __Sample(i).length THEN __Sample(i).loopEnd = __Sample(i).length ' Sanity check

            ' Set sample frame size as 1 since MODs always use 8-bit mono samples
            __Sample(i).frameSize = SIZE_OF_BYTE
        NEXT

        __Song.orders = StringFile_ReadByte(memFile)
        IF __Song.orders > __MOD_ORDERS THEN __Song.orders = __MOD_ORDERS ' clamp to MOD specific max

        __Song.endJumpOrder = StringFile_ReadByte(memFile)
        IF __Song.endJumpOrder >= __Song.orders THEN __Song.endJumpOrder = 0

        ' Resize the order array (MODs always have a 128 byte long order table)
        REDIM __Order(0 TO __MOD_ORDERS - 1) AS _UNSIGNED INTEGER

        ' Load the pattern table, and find the highest pattern to load
        __Song.patterns = 0
        FOR i = 0 TO __MOD_ORDERS - 1 ' MODs always have a 128 byte long order table
            __Order(i) = StringFile_ReadByte(memFile)
            IF __Order(i) > __Song.patterns THEN __Song.patterns = __Order(i)
        NEXT
        __Song.patterns = __Song.patterns + 1 ' change to count

        __Song.rows = __MOD_ROWS ' MOD specific value

        ' Resize the pattern data array
        REDIM __Pattern(0 TO __Song.patterns - 1, 0 TO __Song.rows - 1, 0 TO __Song.channels - 1) AS __NoteType

        ' Skip past the 4 byte marker if this is a 31 sample mod
        IF __Song.samples = 31 THEN
            IF NOT StringFile_Seek(memFile, StringFile_GetPosition(memFile) + 4) THEN EXIT FUNCTION
        END IF

        __LoadTables ' load all needed LUTs

        DIM AS _UNSIGNED _BYTE byte3, byte4
        DIM AS _UNSIGNED INTEGER a, b, c, period

        ' Load the patterns
        ' +----------+-----------+----------+-----------+
        ' | Byte 0   | Byte 1    | Byte 2   | Byte 3    |
        ' | aaaaBBBB | CCCCCCCCC | DDDDeeee | FFFFFFFFF |
        ' +----------+-----------+----------+-----------+
        ' TODO: special handling for FLT8?
        FOR i = 0 TO __Song.patterns - 1
            FOR a = 0 TO __Song.rows - 1
                FOR b = 0 TO __Song.channels - 1
                    byte1 = StringFile_ReadByte(memFile)
                    byte2 = StringFile_ReadByte(memFile)
                    byte3 = StringFile_ReadByte(memFile)
                    byte4 = StringFile_ReadByte(memFile)

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
        SampleManager_Initialize __Song.samples

        DIM sampBuf AS STRING
        ' Load the samples
        FOR i = 0 TO __Song.samples - 1
            sampBuf = StringFile_ReadString(memFile, __Sample(i).length)
            ' Load sample size bytes of data and send it to our softsynth sample manager
            SampleManager_Load i, sampBuf, __Sample(i).frameSize, __Sample(i).loopLength > 0, __Sample(i).loopStart \ __Sample(i).frameSize, __Sample(i).loopEnd \ __Sample(i).frameSize
        NEXT

        ' Setup the channel array
        REDIM __Channel(0 TO __Song.channels - 1) AS __ChannelType

        ' Initialize the softsynth sample mixer
        SampleMixer_Initialize __Song.channels ' this will re-initialize the mixer if it is already initialized

        ' Setup panning for all channels per AMIGA PAULA's panning setup - LRRLLRRL...
        ' If we have < 4 channels, then 0 & 1 are set as left & right
        ' If we have > 4 channels all prefect 4 groups are set as LRRL
        ' Any channels that are left out are simply centered by the SoftSynth
        ' We will also not do hard left or hard right. ~25% of sound from each channel is blended with the other
        IF __Song.channels > 1 AND __Song.channels < 4 THEN
            ' Just setup channels 0 and 1
            ' If we have a 3rd channel it will be handle by the SoftSynth
            SampleMixer_SetVoicePanning 0, SOFTSYNTH_VOICE_PAN_LEFT + SOFTSYNTH_VOICE_PAN_RIGHT / 4 ' -1.0 + 1.0 / 4.0
            SampleMixer_SetVoicePanning 1, SOFTSYNTH_VOICE_PAN_RIGHT - SOFTSYNTH_VOICE_PAN_RIGHT / 4 ' 1.0 - 1.0 / 4.0
        ELSE
            FOR i = 0 TO __Song.channels - 1 - (__Song.channels MOD 4) STEP 4
                SampleMixer_SetVoicePanning i + 0, SOFTSYNTH_VOICE_PAN_LEFT + SOFTSYNTH_VOICE_PAN_RIGHT / 4
                SampleMixer_SetVoicePanning i + 1, SOFTSYNTH_VOICE_PAN_RIGHT - SOFTSYNTH_VOICE_PAN_RIGHT / 4
                SampleMixer_SetVoicePanning i + 2, SOFTSYNTH_VOICE_PAN_RIGHT - SOFTSYNTH_VOICE_PAN_RIGHT / 4
                SampleMixer_SetVoicePanning i + 3, SOFTSYNTH_VOICE_PAN_LEFT + SOFTSYNTH_VOICE_PAN_RIGHT / 4
            NEXT
        END IF

        __LoadMODFromMemory = TRUE
    END FUNCTION


    ' This basically calls the loaders in a certain order that makes sense
    ' It returns TRUE if a loader is successful
    FUNCTION MODPlayer_LoadFromMemory%% (buffer AS STRING)
        IF __LoadMTMFromMemory(buffer) THEN
            MODPlayer_LoadFromMemory = TRUE
            EXIT FUNCTION
        ELSEIF __LoadMODFromMemory(buffer) THEN
            MODPlayer_LoadFromMemory = TRUE
            EXIT FUNCTION
        END IF
    END FUNCTION


    ' Load the MOD file from disk or a URL
    FUNCTION MODPlayer_LoadFromDisk%% (fileName AS STRING)
        MODPlayer_LoadFromDisk = MODPlayer_LoadFromMemory(LoadFile(fileName))
    END FUNCTION


    ' Initializes the audio mixer, prepares eveything else for playback and kick starts the timer and hence song playback
    SUB MODPlayer_Play
        SHARED __Song AS __SongType

        ' Initialize some important stuff
        __Song.tempoTimerValue = (SampleMixer_GetSampleRate * __SONG_BPM_DEFAULT) \ 50
        __Song.orderPosition = 0
        __Song.patternRow = 0
        __Song.speed = __SONG_SPEED_DEFAULT
        __Song.tick = __Song.speed
        __Song.isPaused = FALSE

        ' Set default BPM
        __SetBPM __SONG_BPM_DEFAULT

        __Song.isPlaying = TRUE
    END SUB


    ' Frees all allocated resources, stops the timer and hence song playback
    SUB MODPlayer_Stop
        SHARED __Song AS __SongType

        ' Tell softsynth we are done
        SampleMixer_Finalize

        __Song.isPlaying = FALSE
    END SUB


    ' This should be called at regular intervals to run the mod player and mixer code
    ' You can call this as frequenctly as you want. The routine will simply exit if nothing is to be done
    SUB MODPlayer_Update
        SHARED __Song AS __SongType
        SHARED __Order() AS _UNSIGNED INTEGER

        ' Check conditions for which we should just exit and not process anything
        IF __Song.orderPosition >= __Song.orders THEN EXIT SUB

        ' Set the playing flag to true
        __Song.isPlaying = TRUE

        ' If song is paused or we already have enough samples to play then exit
        IF __Song.isPaused OR NOT SampleMixer_NeedsUpdate THEN EXIT SUB

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
                IF __Song.patternRow >= __Song.rows THEN
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
        SampleMixer_Update __Song.samplesPerTick

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

            IF nVolume <= __MOD_SAMPLE_VOLUME_MAX THEN __Channel(nChannel).volume = nVolume
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
                    SampleMixer_SetVoicePanning nChannel, (nOperand / 255) * 2 - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = ((x / 255) * 2) - 1

                CASE &H9 ' 9: Set Sample Offset
                    IF nOperand > 0 THEN __Channel(nChannel).startPosition = _SHL(nOperand, 8)

                CASE &HB ' 11: Jump To Pattern
                    __Song.orderPosition = nOperand
                    IF __Song.orderPosition >= __Song.orders THEN __Song.orderPosition = __Song.endJumpOrder
                    __Song.patternRow = -1 ' This will increment right after & we will start at 0
                    jumpEffectFlag = TRUE

                CASE &HC ' 12: Set Volume
                    __Channel(nChannel).volume = nOperand ' Operand can never be -ve cause it is unsigned. So we only clip for max below
                    IF __Channel(nChannel).volume > __MOD_SAMPLE_VOLUME_MAX THEN __Channel(nChannel).volume = __MOD_SAMPLE_VOLUME_MAX

                CASE &HD ' 13: Pattern Break
                    __Song.patternRow = (nOpX * 10) + nOpY - 1
                    IF __Song.patternRow >= __Song.rows THEN __Song.patternRow = -1
                    IF NOT breakEffectFlag AND NOT jumpEffectFlag THEN
                        __Song.orderPosition = __Song.orderPosition + 1
                        IF __Song.orderPosition >= __Song.orders THEN __Song.orderPosition = __Song.endJumpOrder
                    END IF
                    breakEffectFlag = TRUE

                CASE &HE ' 14: Extended Effects
                    SELECT CASE nOpX
                        CASE &H0 ' 0: Set Filter
                            SampleMixer_SetHighQuality nOpY

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
                            SampleMixer_SetVoicePanning nChannel, (nOpY / 15) * 2 - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = (x / 15) * 2 - 1

                        CASE &HA ' 10: Fine Volume Slide Up
                            __Channel(nChannel).volume = __Channel(nChannel).volume + nOpY
                            IF __Channel(nChannel).volume > __MOD_SAMPLE_VOLUME_MAX THEN __Channel(nChannel).volume = __MOD_SAMPLE_VOLUME_MAX

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
                IF nEffect <> 7 THEN SampleMixer_SetVoiceVolume nChannel, __Channel(nChannel).volume / __MOD_SAMPLE_VOLUME_MAX
                IF __Channel(nChannel).period > 0 THEN SampleMixer_SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)
            END IF
        NEXT

        ' Now play all samples that needs to be played
        FOR nChannel = 0 TO __Song.activeChannels
            IF __Channel(nChannel).restart THEN
                IF __Sample(__Channel(nChannel).sample).loopLength > 0 THEN
                    SampleMixer_PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition \ __Sample(__Channel(nChannel).sample).frameSize, SOFTSYNTH_VOICE_PLAY_LOOP, __Sample(__Channel(nChannel).sample).loopStart \ __Sample(__Channel(nChannel).sample).frameSize, __Sample(__Channel(nChannel).sample).loopEnd \ __Sample(__Channel(nChannel).sample).frameSize
                ELSE
                    SampleMixer_PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition \ __Sample(__Channel(nChannel).sample).frameSize, SOFTSYNTH_VOICE_PLAY_SINGLE, 0, __Sample(__Channel(nChannel).sample).length \ __Sample(__Channel(nChannel).sample).frameSize
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
                                    SampleMixer_SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)
                                CASE 1
                                    SampleMixer_SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__PeriodTable(__Channel(nChannel).note + nOpX))
                                CASE 2
                                    SampleMixer_SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__PeriodTable(__Channel(nChannel).note + nOpY))
                            END SELECT
                        END IF

                    CASE &H1 ' 1: Porta Up
                        __Channel(nChannel).period = __Channel(nChannel).period - _SHL(nOperand, 2)
                        SampleMixer_SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)
                        IF __Channel(nChannel).period < 56 THEN __Channel(nChannel).period = 56

                    CASE &H2 ' 2: Porta Down
                        __Channel(nChannel).period = __Channel(nChannel).period + _SHL(nOperand, 2)
                        SampleMixer_SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)

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
                                            SampleMixer_PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition \ __Sample(__Channel(nChannel).sample).frameSize, SOFTSYNTH_VOICE_PLAY_LOOP, __Sample(__Channel(nChannel).sample).loopStart \ __Sample(__Channel(nChannel).sample).frameSize, __Sample(__Channel(nChannel).sample).loopEnd \ __Sample(__Channel(nChannel).sample).frameSize
                                        ELSE
                                            SampleMixer_PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition \ __Sample(__Channel(nChannel).sample).frameSize, SOFTSYNTH_VOICE_PLAY_SINGLE, 0, __Sample(__Channel(nChannel).sample).length \ __Sample(__Channel(nChannel).sample).frameSize
                                        END IF
                                    END IF
                                END IF

                            CASE &HC ' 12: Cut Note
                                IF __Song.tick = nOpY THEN
                                    __Channel(nChannel).volume = 0
                                    SampleMixer_SetVoiceVolume nChannel, __Channel(nChannel).volume / __MOD_SAMPLE_VOLUME_MAX
                                END IF

                            CASE &HD ' 13: Delay Note
                                IF __Song.tick = nOpY THEN
                                    __Channel(nChannel).volume = __Sample(__Channel(nChannel).sample).volume
                                    IF nVolume <= __MOD_SAMPLE_VOLUME_MAX THEN __Channel(nChannel).volume = nVolume
                                    SampleMixer_SetVoiceFrequency nChannel, __GetFrequencyFromPeriod(__Channel(nChannel).period)
                                    SampleMixer_SetVoiceVolume nChannel, __Channel(nChannel).volume / __MOD_SAMPLE_VOLUME_MAX
                                    IF __Sample(__Channel(nChannel).sample).loopLength > 0 THEN
                                        SampleMixer_PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition \ __Sample(__Channel(nChannel).sample).frameSize, SOFTSYNTH_VOICE_PLAY_LOOP, __Sample(__Channel(nChannel).sample).loopStart \ __Sample(__Channel(nChannel).sample).frameSize, __Sample(__Channel(nChannel).sample).loopEnd \ __Sample(__Channel(nChannel).sample).frameSize
                                    ELSE
                                        SampleMixer_PlayVoice nChannel, __Channel(nChannel).sample, __Channel(nChannel).startPosition \ __Sample(__Channel(nChannel).sample).frameSize, SOFTSYNTH_VOICE_PLAY_SINGLE, 0, __Sample(__Channel(nChannel).sample).length \ __Sample(__Channel(nChannel).sample).frameSize
                                    END IF
                                END IF
                        END SELECT
                END SELECT
            END IF
        NEXT
    END SUB


    ' We always set the global BPM using this and never directly
    SUB __SetBPM (nBPM AS _UNSIGNED _BYTE)
        $CHECKING:OFF
        SHARED __Song AS __SongType

        __Song.bpm = nBPM

        ' Calculate the number of samples we have to mix per tick
        __Song.samplesPerTick = __Song.tempoTimerValue \ nBPM
        $CHECKING:ON
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
            SampleMixer_SetVoiceFrequency chan, __GetFrequencyFromPeriod(__GetClosestPeriod(__Channel(chan).period))
        ELSE
            SampleMixer_SetVoiceFrequency chan, __GetFrequencyFromPeriod(__Channel(chan).period)
        END IF
    END SUB


    ' Carry out a volume slide using +x -y
    SUB __DoVolumeSlide (chan AS _UNSIGNED _BYTE, x AS _UNSIGNED _BYTE, y AS _UNSIGNED _BYTE)
        SHARED __Channel() AS __ChannelType

        __Channel(chan).volume = __Channel(chan).volume + x - y
        IF __Channel(chan).volume < 0 THEN __Channel(chan).volume = 0
        IF __Channel(chan).volume > __MOD_SAMPLE_VOLUME_MAX THEN __Channel(chan).volume = __MOD_SAMPLE_VOLUME_MAX

        SampleMixer_SetVoiceVolume chan, __Channel(chan).volume / __MOD_SAMPLE_VOLUME_MAX
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
            SampleMixer_SetVoiceFrequency chan, __GetFrequencyFromPeriod(__Channel(chan).period + delta)
        ELSE
            SampleMixer_SetVoiceFrequency chan, __GetFrequencyFromPeriod(__Channel(chan).period - delta)
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
            IF __Channel(chan).volume + delta > __MOD_SAMPLE_VOLUME_MAX THEN delta = __MOD_SAMPLE_VOLUME_MAX - __Channel(chan).volume
            SampleMixer_SetVoiceVolume chan, (__Channel(chan).volume + delta) / __MOD_SAMPLE_VOLUME_MAX
        ELSE
            IF __Channel(chan).volume - delta < 0 THEN delta = __Channel(chan).volume
            SampleMixer_SetVoiceVolume chan, (__Channel(chan).volume - delta) / __MOD_SAMPLE_VOLUME_MAX
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

        DIM sampleNumber AS _UNSIGNED _BYTE: sampleNumber = __Channel(chan).sample ' cache the sample number case we'll use this often below

        IF __Sample(sampleNumber).loopLength > 0 AND __Channel(chan).invertLoopDelay >= 128 THEN
            __Channel(chan).invertLoopDelay = 0 ' reset delay
            IF __Channel(chan).invertLoopPosition < __Sample(sampleNumber).loopStart THEN __Channel(chan).invertLoopPosition = __Sample(sampleNumber).loopStart
            __Channel(chan).invertLoopPosition = __Channel(chan).invertLoopPosition + 1 ' increment position by 1
            IF __Channel(chan).invertLoopPosition > __Sample(sampleNumber).loopEnd THEN __Channel(chan).invertLoopPosition = __Sample(sampleNumber).loopStart

            ' Yeah I know, this is weird. QB64 NOT is bitwise and not logical
            SampleManager_PokeByte sampleNumber, __Channel(chan).invertLoopPosition \ __Sample(sampleNumber).frameSize, NOT SampleManager_PeekByte(sampleNumber, __Channel(chan).invertLoopPosition) \ __Sample(sampleNumber).frameSize
        END IF
    END SUB


    ' This gives us the frequency in khz based on the period
    FUNCTION __GetFrequencyFromPeriod! (period AS LONG)
        $CHECKING:OFF
        __GetFrequencyFromPeriod = 14317056 / period
        $CHECKING:ON
    END FUNCTION


    ' Return C2 speed for a finetune
    FUNCTION __GetC2Spd~% (ft AS _UNSIGNED _BYTE)
        $CHECKING:OFF
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
        $CHECKING:ON
    END FUNCTION


    ' Returns the tune title
    FUNCTION MODPlayer_GetName$
        $CHECKING:OFF
        SHARED __Song AS __SongType

        MODPlayer_GetName = __Song.songName
        $CHECKING:ON
    END FUNCTION


    ' Returns the tune type
    FUNCTION MODPlayer_GetType$
        $CHECKING:OFF
        SHARED __Song AS __SongType

        MODPlayer_GetType = __Song.subtype
        $CHECKING:ON
    END FUNCTION


    ' Returns true if a song is playing
    FUNCTION MODPlayer_IsPlaying%%
        $CHECKING:OFF
        SHARED __Song AS __SongType

        MODPlayer_IsPlaying = __Song.isPlaying
        $CHECKING:ON
    END FUNCTION


    ' Pauses or unpauses playback
    SUB MODPlayer_Pause (state AS _BYTE)
        SHARED __Song AS __SongType
        __Song.isPaused = state
    END SUB


    FUNCTION MODPlayer_IsPaused%%
        $CHECKING:OFF
        SHARED __Song AS __SongType

        MODPlayer_IsPaused = __Song.isPaused
        $CHECKING:ON
    END FUNCTION


    SUB MODPlayer_Loop (state AS _BYTE)
        SHARED __Song AS __SongType
        __Song.isLooping = state
    END SUB


    ' Returns true if a song is looping
    FUNCTION MODPlayer_IsLooping%%
        $CHECKING:OFF
        SHARED __Song AS __SongType

        MODPlayer_IsLooping = __Song.isLooping
        $CHECKING:ON
    END FUNCTION


    ' Moves to the next order positions and wrap if it reaches the end
    SUB MODPlayer_GoToNextPosition
        SHARED __Song AS __SongType

        IF __Song.isLooping THEN ' if we are looping
            __Song.orderPosition = __Song.orderPosition + 1 ' move to the next order
            IF __Song.orderPosition >= __Song.orders THEN __Song.orderPosition = 0 ' wrap to first order if we have reached the end
            __Song.patternRow = 0 ' reset row position
        ELSEIF __Song.orderPosition < __Song.orders - 1 THEN ' else only if have not reached the last order
            __Song.orderPosition = __Song.orderPosition + 1
            __Song.patternRow = 0 ' reset row position
        END IF
    END SUB


    ' Moves to the previous order position and wraps if it reaches the beginning
    SUB MODPlayer_GoToPreviousPosition
        SHARED __Song AS __SongType

        IF __Song.isLooping THEN ' if we are looping
            __Song.orderPosition = __Song.orderPosition - 1 ' move to the previous order
            IF __Song.orderPosition < 0 THEN __Song.orderPosition = __Song.orders - 1 ' wrap to the last order if we have crossed the beginning
            __Song.patternRow = 0 ' reset row position
        ELSEIF __Song.orderPosition > 0 THEN ' else only if have not reached the first order
            __Song.orderPosition = __Song.orderPosition - 1 ' move to the previous order
            __Song.patternRow = 0 ' reset row position
        END IF
    END SUB


    ' Moves to a specific order postion
    SUB MODPlayer_SetPosition (position AS INTEGER)
        SHARED __Song AS __SongType

        IF position >= 0 AND position < __Song.orders THEN
            __Song.orderPosition = position
            __Song.patternRow = 0
        END IF
    END SUB


    ' Moves to a specific order postion
    FUNCTION MODPlayer_GetPosition%
        $CHECKING:OFF
        SHARED __Song AS __SongType

        MODPlayer_GetPosition = __Song.orderPosition
        $CHECKING:ON
    END FUNCTION


    ' Moves to a specific order postion
    FUNCTION MODPlayer_GetOrders%
        $CHECKING:OFF
        SHARED __Song AS __SongType

        MODPlayer_GetOrders = __Song.orders
        $CHECKING:ON
    END FUNCTION

    '$INCLUDE:'MemFile.bas'
    '$INCLUDE:'FileOps.bas'
    '$INCLUDE:'SoftSynth.bas'

$END IF

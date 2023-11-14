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
    $CONSOLE
    DO
        DIM fileName AS STRING: fileName = _OPENFILEDIALOG$("Open", "", "*.mod|*.MOD|*.mtm|*.MTM", "Music Module Files")
        IF NOT _FILEEXISTS(fileName) THEN EXIT DO

        IF MODPlayer_LoadFromDisk(fileName) THEN
            MODPlayer_Play
            DIM k AS LONG: k = 0
            DO WHILE k <> 27 AND MODPlayer_IsPlaying
                MODPlayer_Update SOFTSYNTH_SOUND_BUFFER_TIME_DEFAULT
                LOCATE 1, 1
                PRINT USING "Order: ### / ###    Pattern: ### / ###    Row: ## / 63    BPM: ###    Speed: ###"; MODPlayer_GetPosition; MODPlayer_GetOrders - 1; __Order(__Song.orderPosition); __Song.patterns - 1; __Song.patternRow; __Song.BPM; __Song.speed;
                LOCATE 2, 1:
                PRINT USING "Buffer Time: #####ms"; SoftSynth_GetBufferedSoundTime * 1000;
                _LIMIT 60
                k = _KEYHIT
                IF k = 32 THEN SLEEP: _KEYCLEAR
            LOOP
            MODPlayer_Stop
        END IF
    LOOP

    END

    PRINT __MODPlayer_LoadS3M(LoadFile("C:\Users\samue\source\repos\a740g\QB64-MOD-Player\mods\''exuding titleness''.s3m"))
    '-------------------------------------------------------------------------------------------------------------------

    ' Loads all required LUTs from DATA
    SUB __MODPlayer_LoadTables
        SHARED __Song AS __SongType
        SHARED __PeriodTable() AS _UNSIGNED INTEGER
        SHARED __SineTable() AS _UNSIGNED _BYTE
        SHARED __InvertLoopSpeedTable() AS _UNSIGNED _BYTE

        ' Load the period table
        RESTORE PeriodTab
        READ __Song.periodTableMax ' read the size
        __Song.periodTableMax = __Song.periodTableMax - 1 ' change to ubound
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
        DATA 0,24,49,74,97,120,141,161,180,197,212,224,235,244,250,253
        DATA 255,253,250,244,235,224,212,197,180,161,141,120,97,74,49,24
        DATA NaN

        ' Invert loop speed table data for EFx
        ILSpdTab:
        DATA 16
        DATA 0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128
        DATA NaN
    END SUB


    ' Cleans any text retrieved from a music module file and makes it printable
    FUNCTION __MODPlayer_SanitizeText$ (text AS STRING)
        DIM buffer AS STRING: buffer = SPACE$(LEN(text))

        DIM i AS LONG: FOR i = 1 TO LEN(text)
            IF ASC(text, i) > KEY_SPACE THEN ASC(buffer, i) = ASC(text, i)
        NEXT i

        __MODPlayer_SanitizeText = buffer
    END FUNCTION


    ' This resets all song properties to defaults
    ' We do this so that every tune load begins is a known consistent state
    SUB __MODPlayer_InitializeSong
        SHARED __Song AS __SongType

        __Song.caption = EMPTY_STRING
        __Song.subtype = EMPTY_STRING
        __Song.comment = EMPTY_STRING
        __Song.channels = NULL
        __Song.instruments = NULL
        __Song.orders = NULL
        __Song.rows = NULL
        __Song.endJumpOrder = NULL
        __Song.patterns = NULL
        __Song.orderPosition = NULL
        __Song.patternRow = NULL
        __Song.tickPattern = NULL
        __Song.tickPatternRow = NULL
        __Song.isLooping = FALSE
        __Song.isPlaying = FALSE
        __Song.isPaused = FALSE
        __Song.patternDelay = NULL
        __Song.periodTableMax = NULL
        __Song.speed = NULL
        __Song.BPM = NULL
        __Song.defaultSpeed = __SONG_SPEED_DEFAULT ' set this to default MOD speed
        __Song.defaultBPM = __SONG_BPM_DEFAULT ' set this to default MOD BPM
        __Song.tick = NULL
        __Song.tempoTimerValue = NULL
        __Song.framesPerTick = NULL
        __Song.activeChannels = NULL
        __Song.useAmigaLPF = FALSE
        __Song.useST2Vibrato = FALSE
        __Song.useST2Tempo = FALSE
        __Song.useAmigaSlides = FALSE
        __Song.useVolumeOptimization = FALSE
        __Song.useAmigaLimits = FALSE
        __Song.useFilterSFX = FALSE
        __Song.useST300VolumeSlides = FALSE
        __Song.hasSpecialCustomData = FALSE
    END SUB


    ' Loads an S3M file into memory and prepares all required globals
    FUNCTION __MODPlayer_LoadS3M%% (buffer AS STRING)
        SHARED __Song AS __SongType
        SHARED __Order() AS _UNSIGNED INTEGER
        SHARED __Pattern() AS __NoteType
        SHARED __Instrument() AS __InstrumentType
        SHARED __Channel() AS __ChannelType

        ' Initialize the softsynth sample mixer
        IF NOT SoftSynth_Initialize THEN EXIT FUNCTION

        __MODPlayer_InitializeSong ' just in case something is playing

        ' Open the buffer as a StringFile
        DIM memFile AS StringFileType
        StringFile_Create memFile, buffer

        ' Seek to offset 44 (2Ch) in the file & read the file signature
        StringFile_Seek memFile, 44
        __Song.subtype = StringFile_ReadString(memFile, 4) ' signature is 4 bytes

        ' Check if this is really an S3M file
        IF __Song.subtype <> "SCRM" THEN EXIT FUNCTION
        _ECHO "Type: " + __Song.subtype

        ' Seek to the beginning of the file and get the song title
        StringFile_Seek memFile, 0
        __Song.caption = __MODPlayer_SanitizeText(StringFile_ReadString(memFile, 28)) ' S3M song title is 28 bytes long
        _ECHO "Name: " + __Song.caption

        ' Read and discard DOS EOF marker
        DIM byte1 AS _UNSIGNED _BYTE: byte1 = StringFile_ReadByte(memFile) ' TODO: check if we should just use Seek here

        ' Read and discard the file type byte (TODO: check if we really need to be strict and compare this to 16)
        byte1 = StringFile_ReadByte(memFile)
        _ECHO "File type = " + STR$(byte1)

        ' Read and discard the expansion / reserved word (2 bytes)
        DIM word1 AS _UNSIGNED INTEGER: word1 = StringFile_ReadInteger(memFile) ' TODO: check if we should just use Seek here
        _ECHO "Reserved = " + _BIN$(word1)

        ' Read the song orders (note that this count includes 254 & 255 marker orders)
        __Song.orders = StringFile_ReadInteger(memFile)
        _ECHO "Orders:" + STR$(__Song.orders)

        ' Read the number of instruments
        __Song.instruments = StringFile_ReadInteger(memFile)
        _ECHO "Instruments:" + STR$(__Song.instruments)

        ' Read the number of patterns
        __Song.patterns = StringFile_ReadInteger(memFile) ' TODO: more fixes needed
        _ECHO "Patterns:" + STR$(__Song.patterns)

        ' Read the 16-bit flags
        word1 = StringFile_ReadInteger(memFile)
        _ECHO "Flags = " + _BIN$(word1)

        ' Set individual flags
        __Song.useST2Vibrato = _READBIT(word1, 0)
        __Song.useST2Tempo = _READBIT(word1, 1)
        __Song.useAmigaSlides = _READBIT(word1, 2)
        __Song.useVolumeOptimization = _READBIT(word1, 3)
        __Song.useAmigaLimits = _READBIT(word1, 4)
        __Song.useFilterSFX = _READBIT(word1, 5)
        __Song.useST300VolumeSlides = _READBIT(word1, 6)
        __Song.hasSpecialCustomData = _READBIT(word1, 7)

        _ECHO "useST2Vibrato =" + STR$(__Song.useST2Vibrato)
        _ECHO "useST2Tempo =" + STR$(__Song.useST2Tempo)
        _ECHO "useAmigaSlides =" + STR$(__Song.useAmigaSlides)
        _ECHO "useVolumeOptimization =" + STR$(__Song.useVolumeOptimization)
        _ECHO "useAmigaLimits =" + STR$(__Song.useAmigaLimits)
        _ECHO "useFilterSFX =" + STR$(__Song.useFilterSFX)
        _ECHO "useST300VolumeSlides =" + STR$(__Song.useST300VolumeSlides)
        _ECHO "hasSpecialCustomData =" + STR$(__Song.hasSpecialCustomData)

        ' Read "Created with tracker / version" info
        word1 = StringFile_ReadInteger(memFile)
        _ECHO "CWT/V = " + HEX$(word1)

        ' ST3.00 does volumeslides on EVERY tick. So we'll update the flag
        __Song.useST300VolumeSlides = __Song.useST300VolumeSlides OR (word1 = &H1300)
        _ECHO "useST300VolumeSlides =" + STR$(__Song.useST300VolumeSlides)

        ' Read the sample format type
        word1 = StringFile_ReadInteger(memFile)
        _ECHO "Sample Format = " + STR$(word1)
        DIM isSignedFormat AS _BYTE: isSignedFormat = (word1 = 1)
        _ECHO "isSignedFormat =" + STR$(isSignedFormat)

        ' Skip the 4 byte signature
        StringFile_Seek memFile, StringFile_GetPosition(memFile) + 4

        ' Read and set the global volume
        byte1 = StringFile_ReadByte(memFile)
        _ECHO "Global volume =" + STR$(byte1)
        SoftSynth_SetGlobalVolume byte1 / __S3M_GLOBAL_VOLUME_MAX
        _ECHO "SoftSynth global volume =" + STR$(SoftSynth_GetGlobalVolume)

        ' Read the initial speed value
        __Song.defaultSpeed = StringFile_ReadByte(memFile)
        IF __Song.defaultSpeed = 0 OR __Song.defaultSpeed = 255 THEN __Song.defaultSpeed = __SONG_SPEED_DEFAULT
        _ECHO "Initial speed =" + STR$(__Song.defaultSpeed)

        ' Read the initial BPM
        __Song.defaultBPM = StringFile_ReadByte(memFile)
        IF __Song.defaultBPM < 33 THEN __Song.defaultBPM = __SONG_BPM_DEFAULT
        _ECHO "Initial BPM =" + STR$(__Song.defaultBPM)

        ' Read SoundBlaster master volume crap and check if the stereo frag is set
        byte1 = StringFile_ReadByte(memFile)
        _ECHO "SoundBlaster master volume =" + STR$(byte1)
        DIM isStereo AS _BYTE: isStereo = _READBIT(byte1, 7)
        _ECHO "isStereo =" + STR$(isStereo)

        ' Read and ignore Ultrasound ultra-click removal crap
        ' TODO: check if we should use this somehow or just Seek and skip past
        byte1 = StringFile_ReadByte(memFile)
        _ECHO "Ultrasound ultra-click removal =" + STR$(byte1)

        ' Read and store if we have to load default pan values later
        byte1 = StringFile_ReadByte(memFile)
        _ECHO "Default panning =" + STR$(byte1)
        DIM useDefaultPanning AS _BYTE: useDefaultPanning = (byte1 = 252)
        _ECHO "useDefaultPanning =" + STR$(useDefaultPanning)

        ' Skip 8 reserved bytes
        StringFile_Seek memFile, StringFile_GetPosition(memFile) + 8

        ' Read and ignore the "special custom data" parapointer
        word1 = StringFile_ReadInteger(memFile)
        _ECHO "Special parapointer = " + STR$(word1)

        ' Load channel info and count total channels
        DIM channelInfo(0 TO __MTM_S3M_CHANNEL_MAX) AS _UNSIGNED _BYTE ' channel info that we'll use later

        __Song.channels = 0 ' I know this is set to zero above but safety first

        DIM i AS LONG: FOR i = 0 TO __MTM_S3M_CHANNEL_MAX
            channelInfo(i) = StringFile_ReadByte(memFile)

            ' Check if the channel is enabled
            ' 0 <= x <= 7: Left PCM channel 1-8 (Lx)
            ' 8 <= x <= 15: Right PCM channel 1-8 (Rx)
            ' 16 <= x <= 24: Adlib/OPL2 #1 melody (Ax)
            ' 25 <= x <= 29: Adlib/OPL2 #1 drums (Ax)
            IF channelInfo(i) <= 29 THEN __Song.channels = i + 1 ' bump channel count to max enabled channel + 1

            _ECHO "Channel info" + STR$(i) + " =" + STR$(channelInfo(i))
        NEXT i

        IF __Song.channels < 1 THEN __Song.channels = 1

        _ECHO "Channels =" + STR$(__Song.channels)

        ' Resize the channel array
        REDIM __Channel(0 TO __Song.channels - 1) AS __ChannelType

        ' Allocate the number of SoftSynth voices we need
        SoftSynth_SetTotalVoices __Song.channels

        ' Set voice panning positions
        FOR i = 0 TO __Song.channels - 1
            ' 0 <= x <= 7: Left PCM channel 1-8 (Lx)
            ' 8 <= x <= 15: Right PCM channel 1-8 (Rx)
            ' 16 <= x <= 24: Adlib/OPL2 #1 melody (Ax)
            ' 25 <= x <= 29: Adlib/OPL2 #1 drums (Ax)
            SELECT CASE channelInfo(i)
                CASE 0 TO 7
                    SoftSynth_SetVoiceBalance i, -__CHANNEL_STEREO_SEPARATION ' pan to the left
                    __Channel(i).subtype = __CHANNEL_PCM

                CASE 8 TO 15
                    SoftSynth_SetVoiceBalance i, __CHANNEL_STEREO_SEPARATION ' pan it to the right
                    __Channel(i).subtype = __CHANNEL_PCM

                CASE 16 TO 24
                    __Channel(i).subtype = __CHANNEL_FM_MELODY ' FM melody channel

                CASE 25 TO 29
                    __Channel(i).subtype = __CHANNEL_FM_DRUM ' FM drums channel
            END SELECT

            _ECHO "Channel " + STR$(i) + " panning =" + STR$(SoftSynth_GetVoiceBalance(i)) + " , subtype =" + STR$(__Channel(i).subtype)
        NEXT i

        ' Resize the order array
        REDIM __Order(0 TO __Song.orders - 1) AS _UNSIGNED INTEGER

        ' Read order list
        ' Note: We'll need to handle 254 & 255 marker orders correctly in the player
        FOR i = 0 TO __Song.orders - 1
            __Order(i) = StringFile_ReadByte(memFile)
            _ECHO "Order" + STR$(i) + " =" + STR$(__Order(i))
        NEXT i

        ' Load and convert instrument parapointers
        DIM instrumentPointer(0 TO __Song.instruments - 1) AS _UNSIGNED LONG

        FOR i = 0 TO __Song.instruments - 1
            instrumentPointer(i) = _SHL(StringFile_ReadInteger(memFile), 4) ' convert to real file offset (x 16)
            _ECHO "Instrument" + STR$(i) + " is at" + STR$(instrumentPointer(i))
        NEXT i

        ' Load and convert pattern parapointers
        DIM patternPointer(0 TO __Song.patterns - 1) AS _UNSIGNED LONG

        FOR i = 0 TO __Song.patterns - 1
            patternPointer(i) = _SHL(StringFile_ReadInteger(memFile), 4) ' convert to real file offset (x 16)
            _ECHO "Pattern" + STR$(i) + " is at" + STR$(patternPointer(i))
        NEXT i

        ' Load the panning table if it is present
        IF useDefaultPanning THEN
            ' We have a total of 32 pan positions in the file
            FOR i = 0 TO __MTM_S3M_CHANNEL_MAX
                byte1 = StringFile_ReadByte(memFile)

                ' Only set the pan position if the channel is there
                IF i < __Song.channels THEN
                    ' WTF! Ewww!
                    IF _READBIT(byte1, 4) THEN ' if bit 4 is set - byte1 AND &H10
                        SoftSynth_SetVoiceBalance i, (byte1 AND 15) / 15! * 2! - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = (x / 15) * 2 - 1
                        _ECHO "Channel " + STR$(i) + " panning =" + STR$(SoftSynth_GetVoiceBalance(i))
                    END IF
                END IF
            NEXT i
        END IF

        ' Set everything to mono if stereo flag is not set. This is so retarded! Sigh!
        IF NOT isStereo THEN
            FOR i = 0 TO __Song.channels - 1
                SoftSynth_SetVoiceBalance i, 0!
                _ECHO "Channel " + STR$(i) + " panning =" + STR$(SoftSynth_GetVoiceBalance(i))
            NEXT i
        END IF

        ' Resize the instruments array
        REDIM __Instrument(0 TO __Song.instruments - 1) AS __InstrumentType

        ' Go through the instrument data and load whatever we need
        FOR i = 0 TO __Song.instruments - 1
            ' Seek to the correct position in the file to read the instrument info
            StringFile_Seek memFile, instrumentPointer(i)

            ' Read the instrument type
            __Instrument(i).subtype = StringFile_ReadByte(memFile)

            ' Read the instrument file name. We'll replace it with the title later on if needed
            __Instrument(i).caption = __MODPlayer_SanitizeText(StringFile_ReadString(memFile, 13))

            ' Read and convert the actual address to the instrument PCM / FM data
            ' Convert this to a long. Eww! WTF!
            byte1 = StringFile_ReadByte(memFile)
            word1 = StringFile_ReadInteger(memFile)
            instrumentPointer(i) = _SHL(byte1, 16) + word1 ' we'll re-use instrumentPointer array for this

            ' Read the length
            __Instrument(i).length = StringFile_ReadLong(memFile)

            ' Read loop start
            __Instrument(i).loopStart = StringFile_ReadLong(memFile)

            ' Read loop end
            __Instrument(i).loopEnd = StringFile_ReadLong(memFile)

            ' Read volume
            __Instrument(i).volume = StringFile_ReadByte(memFile)
            IF __Instrument(i).volume > __INSTRUMENT_VOLUME_MAX THEN __Instrument(i).volume = __INSTRUMENT_VOLUME_MAX

            ' Skip 1 reserved byte
            StringFile_Seek memFile, StringFile_GetPosition(memFile) + 1

            ' Skip pack flag (1 byte). TODO: Do we really skip or implement an ADPCM unpacker?
            ' So 0 = PCM, 1 = DP30ADPCM, 3 = ADPCM
            StringFile_Seek memFile, StringFile_GetPosition(memFile) + 1

            ' bits: 0 = loop, 1 = stereo (chans not interleaved!), 2 = 16-bit samples (little endian)
            byte1 = StringFile_ReadByte(memFile)

            IF _READBIT(byte1, 0) THEN
                __Instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
            ELSE
                __Instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
            END IF

            IF _READBIT(byte1, 1) THEN
                __Instrument(i).channels = 2
            ELSE
                __Instrument(i).channels = 1
            END IF

            IF _READBIT(byte1, 2) THEN
                __Instrument(i).bytesPerSample = SIZE_OF_INTEGER
            ELSE
                __Instrument(i).bytesPerSample = SIZE_OF_BYTE
            END IF

            ' Read C2SPD (only the low word is used)
            __Instrument(i).c2Spd = StringFile_ReadLong(memFile) AND &HFFFF

            ' Store the instrument name if it is not empty
            DIM instrumentName AS STRING: instrumentName = __MODPlayer_SanitizeText(StringFile_ReadString(memFile, 28))
            IF LEN(_TRIM$(instrumentName)) <> NULL THEN __Instrument(i).caption = instrumentName

            ' Skip the 'SCRS' label. TODO: Check if we need to be strict with this one
            StringFile_Seek memFile, StringFile_GetPosition(memFile) + 4
        NEXT i

        ' What a fucked up format!
        __MODPlayer_LoadS3M = TRUE
    END FUNCTION


    ' Loads an MTM file into memory and prepairs all required globals
    FUNCTION __MODPlayer_LoadMTM%% (buffer AS STRING)
        SHARED __Song AS __SongType
        SHARED __Order() AS _UNSIGNED INTEGER
        SHARED __Pattern() AS __NoteType
        SHARED __Instrument() AS __InstrumentType
        SHARED __Channel() AS __ChannelType

        ' Initialize the softsynth sample mixer
        IF NOT SoftSynth_Initialize THEN EXIT FUNCTION

        __MODPlayer_InitializeSong ' just in case something is playing

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
        __Song.caption = __MODPlayer_SanitizeText(StringFile_ReadString(memFile, 20)) ' MTM song name is 20 bytes

        ' Read the number of tracks saved
        DIM numTracks AS _UNSIGNED INTEGER: numTracks = StringFile_ReadInteger(memFile)

        ' Read the highest pattern number saved
        __Song.patterns = StringFile_ReadByte(memFile) + 1 ' convert to count / length

        ' Read the last order to play
        __Song.orders = StringFile_ReadByte(memFile) + 1 ' convert to count / length

        ' Read length of the extra comment field
        DIM commentLen AS _UNSIGNED INTEGER: commentLen = StringFile_ReadInteger(memFile)

        ' Read the number of instruments
        __Song.instruments = StringFile_ReadByte(memFile)

        ' Read the attribute byte and discard it
        DIM byte1 AS _UNSIGNED _BYTE: byte1 = StringFile_ReadByte(memFile)

        ' Read the beats per track (row count)
        __Song.rows = StringFile_ReadByte(memFile)

        ' Read the number of channels
        __Song.channels = StringFile_ReadByte(memFile)

        ' Sanity check
        IF numTracks = 0 OR __Song.instruments = 0 OR __Song.rows = 0 OR __Song.channels = 0 THEN EXIT FUNCTION

        ' Resize the channel array
        REDIM __Channel(0 TO __Song.channels - 1) AS __ChannelType

        ' Allocate the number of softsynth voices we need
        SoftSynth_SetTotalVoices __Song.channels

        ' Read the panning positions
        DIM i AS LONG: FOR i = 0 TO __MTM_S3M_CHANNEL_MAX
            byte1 = StringFile_ReadByte(memFile) ' read the raw value

            ' Adjust and save the values per our mixer requirements
            IF i < __Song.channels AND byte1 < 16 THEN
                ' __CHANNEL_PCM = 0 so all MTM channels are by default PCM
                SoftSynth_SetVoiceBalance i, (byte1 / 15!) * 2! - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = (x / 15) * 2 - 1
            END IF
        NEXT i

        ' Resize the instruments array
        REDIM __Instrument(0 TO __Song.instruments - 1) AS __InstrumentType

        ' Read the instruments information
        FOR i = 0 TO __Song.instruments - 1
            ' Read the sample name
            __Instrument(i).caption = __MODPlayer_SanitizeText(StringFile_ReadString(memFile, 22)) ' MTM sample names are 22 bytes long

            ' Read sample length
            __Instrument(i).length = StringFile_ReadLong(memFile)

            ' Read loop start
            __Instrument(i).loopStart = StringFile_ReadLong(memFile)
            IF __Instrument(i).loopStart < 0 OR __Instrument(i).loopStart >= __Instrument(i).length THEN __Instrument(i).loopStart = 0 ' sanity check

            ' Read loop end
            __Instrument(i).loopEnd = StringFile_ReadLong(memFile)
            IF __Instrument(i).loopEnd < 0 OR __Instrument(i).loopEnd >= __Instrument(i).length THEN
                __Instrument(i).loopEnd = __Instrument(i).length ' sanity check
            END IF

            ' Set sound to looping and fix loop points if needed
            IF __Instrument(i).loopEnd - __Instrument(i).loopStart > 1 THEN ' we need 2 frames minimum to mark the sound as looping (TODO: check if this is normal)
                __Instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
            ELSE
                __Instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
                __Instrument(i).loopStart = 0
                __Instrument(i).loopEnd = __Instrument(i).length
            END IF

            ' Read finetune
            __Instrument(i).c2Spd = __MODPlayer_GetC2Spd(StringFile_ReadByte(memFile)) ' convert finetune to c2spd

            ' Read volume
            __Instrument(i).volume = StringFile_ReadByte(memFile)
            IF __Instrument(i).volume > __INSTRUMENT_VOLUME_MAX THEN __Instrument(i).volume = __INSTRUMENT_VOLUME_MAX ' MTM uses MOD volume specs.

            ' Read attribute
            byte1 = StringFile_ReadByte(memFile)
            __Instrument(i).bytesPerSample = SIZE_OF_BYTE + SIZE_OF_BYTE * (byte1 AND &H1) ' 1 if 8-bit else 2 if 16-bit
            __Instrument(i).channels = 1 ' all MTM sounds are mono
        NEXT i

        ' Resize the order array (MTMs like MODs always have a 128 byte long order table)
        REDIM __Order(0 TO __MOD_MTM_ORDER_MAX) AS _UNSIGNED INTEGER

        ' Read order list
        FOR i = 0 TO __MOD_MTM_ORDER_MAX ' MTMs like MODs always have a 128 byte long order table
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

                mtmTrack(i, j).instrument = _SHL(byte1 AND &H3, 4) OR _SHR(byte2, 4)
                IF mtmTrack(i, j).instrument > __Song.instruments THEN mtmTrack(i, j).instrument = 0 ' sanity check

                mtmTrack(i, j).effect = byte2 AND &HF
                mtmTrack(i, j).operand = byte3
                mtmTrack(i, j).volume = __NOTE_NO_VOLUME

                ' MTM fix: when the effect is volume-slide, slide-up always overrides slide-down
                IF mtmTrack(i, j).effect = &HA AND (mtmTrack(i, j).operand AND &HF0) <> 0 THEN
                    mtmTrack(i, j).operand = mtmTrack(i, j).operand AND &HF0
                END IF
            NEXT j
        NEXT i

        ' Resize the pattern data array
        REDIM __Pattern(0 TO __Song.patterns - 1, 0 TO __Song.rows - 1, 0 TO __Song.channels - 1) AS __NoteType

        ' Read track sequencing data and assemble that to our pattern data
        DIM k AS LONG, w AS _UNSIGNED INTEGER
        FOR i = 0 TO __Song.patterns - 1
            FOR j = 0 TO __MTM_S3M_CHANNEL_MAX ' MTM files stores data for 32 channels irrespective of the actual channels used
                ' Read the data
                w = StringFile_ReadInteger(memFile)

                IF j >= __Song.channels THEN _CONTINUE ' ignore excess channel information

                IF w > 0 THEN
                    FOR k = 0 TO __Song.rows - 1
                        __Pattern(i, k, j) = mtmTrack(w - 1, k)
                    NEXT k
                ELSE
                    ' Populate empty channel
                    FOR k = 0 TO __Song.rows - 1
                        __Pattern(i, k, j).note = __NOTE_NONE
                        __Pattern(i, k, j).instrument = 0
                        __Pattern(i, k, j).effect = 0
                        __Pattern(i, k, j).operand = 0
                        __Pattern(i, k, j).volume = __NOTE_NO_VOLUME
                    NEXT k
                END IF
            NEXT j
        NEXT i

        ' Read the tune comment
        __Song.comment = StringFile_ReadString(memFile, commentLen) ' read the comment and leave it untouched

        ' Load the instruments
        DIM sampBuf AS STRING
        FOR i = 0 TO __Song.instruments - 1
            sampBuf = StringFile_ReadString(memFile, __Instrument(i).length)

            ' Convert 8-bit unsigned samples to 8-bit signed
            IF __Instrument(i).bytesPerSample = SIZE_OF_BYTE THEN SoftSynth_ConvertU8ToS8 sampBuf

            ' Load sample size bytes of data and send it to our softsynth sample manager
            SoftSynth_LoadSound i, sampBuf, __Instrument(i).bytesPerSample, __Instrument(i).channels
        NEXT i

        ' Load all needed LUTs
        __MODPlayer_LoadTables

        __MODPlayer_LoadMTM = TRUE
    END FUNCTION


    ' Loads the MOD file into memory and prepares all required globals
    FUNCTION __MODPlayer_LoadMOD%% (buffer AS STRING)
        SHARED __Song AS __SongType
        SHARED __Order() AS _UNSIGNED INTEGER
        SHARED __Pattern() AS __NoteType
        SHARED __Instrument() AS __InstrumentType
        SHARED __Channel() AS __ChannelType
        SHARED __PeriodTable() AS _UNSIGNED INTEGER

        ' Initialize the softsynth sample mixer
        IF NOT SoftSynth_Initialize THEN EXIT FUNCTION

        __MODPlayer_InitializeSong ' just in case something is playing

        ' Attempt to open the file
        DIM i AS LONG, memFile AS StringFileType
        StringFile_Create memFile, buffer

        ' Seek to offset 1080 (438h) in the file and read the file signature
        StringFile_Seek memFile, 1080
        __Song.subtype = StringFile_ReadString(memFile, 4) ' signature is 4 bytes

        ' Also, seek to the beginning of the file and get the song title
        StringFile_Seek memFile, 0
        __Song.caption = __MODPlayer_SanitizeText(StringFile_ReadString(memFile, 20)) ' MOD song title is 20 bytes long

        __Song.channels = 0
        __Song.instruments = 0

        SELECT CASE __Song.subtype
            CASE "FEST", "FIST", "LARD", "M!K!", "M&K!", "M.K.", "N.T.", "NSMS", "PATT"
                __Song.channels = 4
                __Song.instruments = 31
            CASE "OCTA", "OKTA"
                __Song.channels = 8
                __Song.instruments = 31
            CASE ELSE
                ' Parse the subtype string to check for more variants
                IF RIGHT$(__Song.subtype, 3) = "CHN" THEN
                    ' Check xCNH types
                    __Song.channels = VAL(LEFT$(__Song.subtype, 1))
                    __Song.instruments = 31
                ELSEIF RIGHT$(__Song.subtype, 2) = "CH" OR RIGHT$(__Song.subtype, 2) = "CN" THEN
                    ' Check for xxCH & xxCN types
                    __Song.channels = VAL(LEFT$(__Song.subtype, 2))
                    __Song.instruments = 31
                ELSEIF LEFT$(__Song.subtype, 3) = "FLT" OR LEFT$(__Song.subtype, 3) = "TDZ" OR LEFT$(__Song.subtype, 3) = "EXO" THEN
                    ' Check for FLTx, TDZx & EXOx types
                    __Song.channels = VAL(RIGHT$(__Song.subtype, 1))
                    __Song.instruments = 31
                ELSEIF LEFT$(__Song.subtype, 2) = "CD" AND RIGHT$(__Song.subtype, 1) = "1" THEN
                    ' Check for CDx1 types
                    __Song.channels = VAL(MID$(__Song.subtype, 3, 1))
                    __Song.instruments = 31
                ELSEIF LEFT$(__Song.subtype, 2) = "FA" THEN
                    ' Check for FAxx types
                    __Song.channels = VAL(RIGHT$(__Song.subtype, 2))
                    __Song.instruments = 31
                ELSE
                    ' Extra checks for 15 sample MOD
                    FOR i = 1 TO LEN(__Song.caption)
                        IF ASC(__Song.caption, i) < KEY_SPACE AND ASC(__Song.caption, i) <> NULL THEN EXIT FUNCTION ' this is probably not a 15 sample MOD file
                    NEXT
                    __Song.channels = 4
                    __Song.instruments = 15
                    __Song.subtype = "MODF" ' change subtype to reflect 15 (Fh) sample mod, otherwise it will contain garbage
                END IF
        END SELECT

        ' Sanity check
        IF __Song.instruments = 0 OR __Song.channels = 0 THEN EXIT FUNCTION

        ' Resize the instruments array
        REDIM __Instrument(0 TO __Song.instruments - 1) AS __InstrumentType
        DIM AS _UNSIGNED _BYTE byte1, byte2

        ' Load the instruments headers
        FOR i = 0 TO __Song.instruments - 1
            ' Read the sample name
            __Instrument(i).caption = __MODPlayer_SanitizeText(StringFile_ReadString(memFile, 22)) ' MOD sample names are 22 bytes long

            ' Read sample length
            byte1 = StringFile_ReadByte(memFile)
            byte2 = StringFile_ReadByte(memFile)
            __Instrument(i).length = (byte1 * &H100 + byte2) * 2

            ' Read finetune
            __Instrument(i).c2Spd = __MODPlayer_GetC2Spd(StringFile_ReadByte(memFile)) ' convert finetune to c2spd

            ' Read volume
            __Instrument(i).volume = StringFile_ReadByte(memFile)
            IF __Instrument(i).volume > __INSTRUMENT_VOLUME_MAX THEN __Instrument(i).volume = __INSTRUMENT_VOLUME_MAX ' Sanity check

            ' Read loop start
            byte1 = StringFile_ReadByte(memFile)
            byte2 = StringFile_ReadByte(memFile)
            __Instrument(i).loopStart = (byte1 * &H100 + byte2) * 2

            ' Read loop length
            byte1 = StringFile_ReadByte(memFile)
            byte2 = StringFile_ReadByte(memFile)
            DIM loopLength AS _UNSIGNED LONG: loopLength = (byte1 * &H100 + byte2) * 2

            ' Some MOD file loop points are truly fucked
            ' These checks are taken directly from OpenMPT's MOD loader which seem to do a decent job dealing with messed up MODs
            ' See if loop start is incorrect as words, but correct as bytes (like in Soundtracker modules)
            IF loopLength > 2 AND __Instrument(i).loopStart + loopLength > __Instrument(i).length AND __Instrument(i).loopStart \ 2 + loopLength <= __Instrument(i).length THEN
                __Instrument(i).loopStart = __Instrument(i).loopStart \ 2
            END IF

            IF __Instrument(i).length = 2 THEN __Instrument(i).length = 0

            IF __Instrument(i).length > 0 THEN
                __Instrument(i).loopEnd = __Instrument(i).loopStart + loopLength

                IF __Instrument(i).loopStart >= __Instrument(i).length THEN __Instrument(i).loopStart = __Instrument(i).length - 1

                IF __Instrument(i).loopStart > __Instrument(i).loopEnd OR __Instrument(i).loopEnd < 4 OR __Instrument(i).loopEnd - __Instrument(i).loopStart < 4 THEN
                    __Instrument(i).loopStart = 0
                    __Instrument(i).loopEnd = 0
                END IF

                ' Fix for most likely broken sample loops. This fixes super_sufm_-_new_life.mod (M.K.) which has a long sample which is looped from 0 to 4.
                ' This module also has notes outside of the Amiga frequency range, so we cannot say that it should be played using ProTracker one-shot loops.
                ' On the other hand, "Crew Generation" by Necros (6CHN) has a sample with a similar loop, which is supposed to be played.
                ' To be able to correctly play both modules, we will draw a somewhat arbitrary line here and trust the loop points in MODs with more than
                ' 4 channels, even if they are tiny and at the very beginning of the sample.
                IF __Instrument(i).loopEnd <= 8 AND __Instrument(i).loopStart = 0 AND __Instrument(i).length > __Instrument(i).loopEnd AND __Song.channels = 4 THEN
                    __Instrument(i).loopEnd = 0
                END IF

                IF __Instrument(i).loopEnd > __Instrument(i).loopStart THEN
                    __Instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP
                ELSE
                    __Instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
                    __Instrument(i).loopStart = 0
                    __Instrument(i).loopEnd = __Instrument(i).length
                END IF
            ELSE
                __Instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD
                __Instrument(i).loopStart = 0
                __Instrument(i).loopEnd = 0
            END IF

            ' Set sample frame size as 1 since MODs always use 8-bit mono samples
            __Instrument(i).bytesPerSample = SIZE_OF_BYTE
            __Instrument(i).channels = 1
        NEXT

        __Song.orders = StringFile_ReadByte(memFile)
        IF __Song.orders >= __MOD_MTM_ORDER_MAX THEN __Song.orders = __MOD_MTM_ORDER_MAX + 1 ' clamp to MOD specific max

        __Song.endJumpOrder = StringFile_ReadByte(memFile)
        IF __Song.endJumpOrder >= __Song.orders THEN __Song.endJumpOrder = 0

        ' Resize the order array (MODs always have a 128 byte long order table)
        REDIM __Order(0 TO __MOD_MTM_ORDER_MAX) AS _UNSIGNED INTEGER

        ' Load the pattern table, and find the highest pattern to load
        __Song.patterns = 0
        FOR i = 0 TO __MOD_MTM_ORDER_MAX ' MODs always have a 128 byte long order table
            __Order(i) = StringFile_ReadByte(memFile)
            IF __Order(i) > __Song.patterns THEN __Song.patterns = __Order(i)
        NEXT
        __Song.patterns = __Song.patterns + 1 ' change to count

        __Song.rows = __MOD_ROWS ' MOD specific value

        ' Resize the pattern data array
        REDIM __Pattern(0 TO __Song.patterns - 1, 0 TO __Song.rows - 1, 0 TO __Song.channels - 1) AS __NoteType

        ' Skip past the 4 byte signature if this is a 31 sample mod
        IF __Song.instruments = 31 THEN StringFile_Seek memFile, StringFile_GetPosition(memFile) + 4

        __MODPlayer_LoadTables ' load all needed LUTs

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

                    __Pattern(i, a, b).instrument = (byte1 AND &HF0) OR _SHR(byte3, 4)

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
                    IF __Pattern(i, a, b).instrument > __Song.instruments THEN __Pattern(i, a, b).instrument = 0 ' instrument 0 means no instrument. So valid sample are 1-15/31
                NEXT
            NEXT
        NEXT

        DIM sampBuf AS STRING
        ' Load the instruments
        FOR i = 0 TO __Song.instruments - 1
            sampBuf = StringFile_ReadString(memFile, __Instrument(i).length)
            ' Load sample size bytes of data and send it to our softsynth sample manager
            SoftSynth_LoadSound i, sampBuf, __Instrument(i).bytesPerSample, __Instrument(i).channels
        NEXT

        ' Setup the channel array
        ' __CHANNEL_PCM = 0 so all MOD channels are by default PCM
        REDIM __Channel(0 TO __Song.channels - 1) AS __ChannelType

        ' Allocate the number of softsynth voices we need
        SoftSynth_SetTotalVoices __Song.channels

        ' Setup panning for all channels per AMIGA PAULA's panning setup - LRRLLRRL...
        ' opencp uses this: for (int i = 0; i < 8; i++) int panpos = ((i * 3) & 2) ? 0xFF : 0x00;
        ' But ours is better:
        ' If we have < 4 channels, then 0 & 1 are set as left & right
        ' If we have > 4 channels, then all prefect 4 groups are set as LRRL
        ' Any channels that are left out are simply centered by the SoftSynth
        ' We will also not do hard left or hard right. Some amount of sound from each channel is allowed to blend with the other
        IF __Song.channels > 1 AND __Song.channels < 4 THEN
            ' Just setup channels 0 and 1. If we have a 3rd channel it will be handle by the SoftSynth
            SoftSynth_SetVoiceBalance 0, -__CHANNEL_STEREO_SEPARATION
            SoftSynth_SetVoiceBalance 1, __CHANNEL_STEREO_SEPARATION
        ELSE
            FOR i = 0 TO __Song.channels - 1 - (__Song.channels MOD 4) STEP 4
                SoftSynth_SetVoiceBalance i + 0, -__CHANNEL_STEREO_SEPARATION
                SoftSynth_SetVoiceBalance i + 1, __CHANNEL_STEREO_SEPARATION
                SoftSynth_SetVoiceBalance i + 2, __CHANNEL_STEREO_SEPARATION
                SoftSynth_SetVoiceBalance i + 3, -__CHANNEL_STEREO_SEPARATION
            NEXT
        END IF

        __MODPlayer_LoadMOD = TRUE
    END FUNCTION


    ' This basically calls the loaders in a certain order that makes sense
    ' It returns TRUE if a loader is successful
    FUNCTION MODPlayer_LoadFromMemory%% (buffer AS STRING)
        IF __MODPlayer_LoadMTM(buffer) THEN
            MODPlayer_LoadFromMemory = TRUE
            EXIT FUNCTION
        ELSEIF __MODPlayer_LoadMOD(buffer) THEN
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
        __Song.tempoTimerValue = (SoftSynth_GetSampleRate * __Song.defaultBPM) \ 50
        __Song.orderPosition = NULL
        __Song.patternRow = NULL
        __Song.speed = __Song.defaultSpeed
        __Song.tick = __Song.speed
        __Song.isPaused = FALSE

        ' Set default BPM
        __MODPlayer_SetBPM __Song.defaultBPM

        __Song.isPlaying = TRUE
    END SUB


    ' Frees all allocated resources, stops the timer and hence song playback
    SUB MODPlayer_Stop
        SHARED __Song AS __SongType

        ' Tell softsynth we are done
        SoftSynth_Finalize

        __Song.isPlaying = FALSE
    END SUB


    ' This should be called at regular intervals to run the mod player and mixer code
    ' You can call this as frequently as you want. The routine will simply exit if nothing is to be done
    SUB MODPlayer_Update (bufferTimeSecs AS SINGLE)
        SHARED __Song AS __SongType
        SHARED __Order() AS _UNSIGNED INTEGER

        ' Keep feeding the buffer until it is filled to our specified upper limit
        DO WHILE SoftSynth_GetBufferedSoundTime < bufferTimeSecs
            ' Check conditions for which we should just exit and not process anything
            IF __Song.orderPosition >= __Song.orders THEN EXIT SUB

            ' Set the playing flag to true
            __Song.isPlaying = TRUE

            ' If song is paused then exit
            IF __Song.isPaused THEN EXIT SUB

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
                    __MODPlayer_UpdateRow

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
                                __Song.speed = __Song.defaultSpeed
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
                __MODPlayer_UpdateTick
            END IF

            ' Mix the current tick
            SoftSynth_Update __Song.framesPerTick

            ' Increment song tick on each update
            __Song.tick = __Song.tick + 1
        LOOP
    END SUB


    ' Updates a row of notes and play them out on tick 0
    SUB __MODPlayer_UpdateRow
        SHARED __Song AS __SongType
        SHARED __Pattern() AS __NoteType
        SHARED __Instrument() AS __InstrumentType
        SHARED __Channel() AS __ChannelType
        SHARED __PeriodTable() AS _UNSIGNED INTEGER

        DIM AS _UNSIGNED _BYTE nChannel, nNote, nInstrument, nVolume, nEffect, nOperand, nOpX, nOpY
        ' The effect flags below are set to true when a pattern jump effect and pattern break effect are triggered
        DIM AS _BYTE jumpEffectFlag, breakEffectFlag, noFrequency

        ' Set the active channel count to zero
        __Song.activeChannels = 0

        ' Process all channels
        FOR nChannel = 0 TO __Song.channels - 1
            nNote = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).note
            nInstrument = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).instrument
            nVolume = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).volume
            nEffect = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).effect
            nOperand = __Pattern(__Song.tickPattern, __Song.tickPatternRow, nChannel).operand
            nOpX = _SHR(nOperand, 4)
            nOpY = nOperand AND &HF
            noFrequency = FALSE

            ' Set volume. We never play if sample number is zero. Our sample array is 1 based
            ' ONLY RESET VOLUME IF THERE IS A SAMPLE NUMBER
            IF nInstrument > 0 THEN
                __Channel(nChannel).instrument = nInstrument - 1
                __Channel(nChannel).startPosition = 0 ' reset sample offset if sample changes
                ' Don't get the volume if delay note, set it when the delay note actually happens
                IF NOT (nEffect = &HE AND nOpX = &HD) THEN
                    __Channel(nChannel).volume = __Instrument(__Channel(nChannel).instrument).volume
                END IF
            END IF

            IF nNote < __NOTE_NONE THEN
                __Channel(nChannel).lastPeriod = (8363 * __PeriodTable(nNote)) \ __Instrument(__Channel(nChannel).instrument).c2Spd
                __Channel(nChannel).note = nNote
                __Channel(nChannel).restart = TRUE
                __Song.activeChannels = nChannel

                ' Retrigger tremolo and vibrato waveforms
                IF __Channel(nChannel).waveControl AND &HF < 4 THEN __Channel(nChannel).vibratoPosition = 0
                IF _SHR(__Channel(nChannel).waveControl, 4) < 4 THEN __Channel(nChannel).tremoloPosition = 0

                ' ONLY RESET FREQUENCY IF THERE IS A NOTE VALUE AND PORTA NOT SET
                IF nEffect <> &H3 AND nEffect <> &H5 AND nEffect <> &H16 THEN
                    __Channel(nChannel).period = __Channel(nChannel).lastPeriod
                END IF
            ELSE
                __Channel(nChannel).restart = FALSE
            END IF

            IF nVolume <= __INSTRUMENT_VOLUME_MAX THEN __Channel(nChannel).volume = nVolume
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
                    SoftSynth_SetVoiceBalance nChannel, (nOperand / 255!) * 2! - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = ((x / 255) * 2) - 1

                CASE &H9 ' 9: Set Sample Offset
                    __Channel(nChannel).startPosition = _SHL(nOperand, 8)
                    IF __Channel(nChannel).startPosition > __Instrument(__Channel(nChannel).instrument).length THEN
                        __Channel(nChannel).startPosition = __Instrument(__Channel(nChannel).instrument).length
                    END IF

                CASE &HB ' 11: Jump To Pattern
                    __Song.orderPosition = nOperand
                    IF __Song.orderPosition >= __Song.orders THEN __Song.orderPosition = __Song.endJumpOrder
                    __Song.patternRow = -1 ' This will increment right after & we will start at 0
                    jumpEffectFlag = TRUE

                CASE &HC ' 12: Set Volume
                    __Channel(nChannel).volume = nOperand ' Operand can never be -ve cause it is unsigned. So we only clip for max below
                    IF __Channel(nChannel).volume > __INSTRUMENT_VOLUME_MAX THEN __Channel(nChannel).volume = __INSTRUMENT_VOLUME_MAX

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
                            __Song.useAmigaLPF = (nOpY <> FALSE)

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
                            __Instrument(__Channel(nChannel).instrument).c2Spd = __MODPlayer_GetC2Spd(nOpY)

                        CASE &H6 ' 6: Pattern Loop
                            IF nOpY = 0 THEN
                                __Channel(nChannel).patternLoopRow = __Song.tickPatternRow
                            ELSE
                                IF __Channel(nChannel).patternLoopRowCounter = 0 THEN
                                    __Channel(nChannel).patternLoopRowCounter = nOpY
                                ELSE
                                    __Channel(nChannel).patternLoopRowCounter = __Channel(nChannel).patternLoopRowCounter - 1
                                END IF
                                IF __Channel(nChannel).patternLoopRowCounter > 0 THEN
                                    __Song.patternRow = __Channel(nChannel).patternLoopRow - 1
                                END IF
                            END IF

                        CASE &H7 ' 7: Set Tremolo WaveForm
                            __Channel(nChannel).waveControl = __Channel(nChannel).waveControl AND &HF
                            __Channel(nChannel).waveControl = __Channel(nChannel).waveControl OR _SHL(nOpY, 4)

                        CASE &H8 ' 8: 16 position panning
                            IF nOpY > 15 THEN nOpY = 15
                            SoftSynth_SetVoiceBalance nChannel, (nOpY / 15!) * 2! - SOFTSYNTH_VOICE_PAN_RIGHT ' pan = (x / 15) * 2 - 1

                        CASE &HA ' 10: Fine Volume Slide Up
                            __Channel(nChannel).volume = __Channel(nChannel).volume + nOpY
                            IF __Channel(nChannel).volume > __INSTRUMENT_VOLUME_MAX THEN __Channel(nChannel).volume = __INSTRUMENT_VOLUME_MAX

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
                        __MODPlayer_SetBPM nOperand
                    END IF
            END SELECT

            __MODPlayer_DoInvertLoop nChannel ' called every tick

            IF NOT noFrequency THEN
                IF nEffect <> 7 THEN
                    SoftSynth_SetVoiceVolume nChannel, __Channel(nChannel).volume / __INSTRUMENT_VOLUME_MAX
                END IF
                IF __Channel(nChannel).period > 0 THEN
                    SoftSynth_SetVoiceFrequency nChannel, __MODPlayer_GetFrequencyFromPeriod(__Channel(nChannel).period)
                END IF
            END IF
        NEXT

        ' Now play all samples that needs to be played
        FOR nChannel = 0 TO __Song.activeChannels
            IF __Channel(nChannel).restart THEN
                SoftSynth_PlayVoice nChannel, __Channel(nChannel).instrument, SoftSynth_BytesToFrames(__Channel(nChannel).startPosition, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels), __Instrument(__Channel(nChannel).instrument).playMode, SoftSynth_BytesToFrames(__Instrument(__Channel(nChannel).instrument).loopStart, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels), SoftSynth_BytesToFrames(__Instrument(__Channel(nChannel).instrument).loopEnd, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels)
            END IF
        NEXT
    END SUB


    ' Updates any tick based effects after tick 0
    SUB __MODPlayer_UpdateTick
        SHARED __Song AS __SongType
        SHARED __Pattern() AS __NoteType
        SHARED __Instrument() AS __InstrumentType
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

                __MODPlayer_DoInvertLoop nChannel ' called every tick

                SELECT CASE nEffect
                    CASE &H0 ' 0: Arpeggio
                        IF (nOperand > 0) THEN
                            SELECT CASE __Song.tick MOD 3
                                CASE 0
                                    SoftSynth_SetVoiceFrequency nChannel, __MODPlayer_GetFrequencyFromPeriod(__Channel(nChannel).period)
                                CASE 1
                                    SoftSynth_SetVoiceFrequency nChannel, __MODPlayer_GetFrequencyFromPeriod(__PeriodTable(__Channel(nChannel).note + nOpX))
                                CASE 2
                                    SoftSynth_SetVoiceFrequency nChannel, __MODPlayer_GetFrequencyFromPeriod(__PeriodTable(__Channel(nChannel).note + nOpY))
                            END SELECT
                        END IF

                    CASE &H1 ' 1: Porta Up
                        __Channel(nChannel).period = __Channel(nChannel).period - _SHL(nOperand, 2)
                        IF __Channel(nChannel).period < 1 THEN __Channel(nChannel).period = 1 ' clamp to avoid division by zero
                        SoftSynth_SetVoiceFrequency nChannel, __MODPlayer_GetFrequencyFromPeriod(__Channel(nChannel).period)

                    CASE &H2 ' 2: Porta Down
                        __Channel(nChannel).period = __Channel(nChannel).period + _SHL(nOperand, 2)
                        SoftSynth_SetVoiceFrequency nChannel, __MODPlayer_GetFrequencyFromPeriod(__Channel(nChannel).period)

                    CASE &H3 ' 3: Porta To Note
                        __MODPlayer_DoPortamento nChannel

                    CASE &H4 ' 4: Vibrato
                        __MODPlayer_DoVibrato nChannel

                    CASE &H5 ' 5: Tone Portamento + Volume Slide
                        __MODPlayer_DoPortamento nChannel
                        __MODPlayer_DoVolumeSlide nChannel, nOpX, nOpY

                    CASE &H6 ' 6: Vibrato + Volume Slide
                        __MODPlayer_DoVibrato nChannel
                        __MODPlayer_DoVolumeSlide nChannel, nOpX, nOpY

                    CASE &H7 ' 7: Tremolo
                        __MODPlayer_DoTremolo nChannel

                    CASE &HA ' 10: Volume Slide
                        __MODPlayer_DoVolumeSlide nChannel, nOpX, nOpY

                    CASE &HE ' 14: Extended Effects
                        SELECT CASE nOpX
                            CASE &H9 ' 9: Retrigger Note
                                IF nOpY <> 0 THEN
                                    IF __Song.tick MOD nOpY = 0 THEN
                                        SoftSynth_PlayVoice nChannel, __Channel(nChannel).instrument, SoftSynth_BytesToFrames(__Channel(nChannel).startPosition, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels), __Instrument(__Channel(nChannel).instrument).playMode, SoftSynth_BytesToFrames(__Instrument(__Channel(nChannel).instrument).loopStart, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels), SoftSynth_BytesToFrames(__Instrument(__Channel(nChannel).instrument).loopEnd, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels)
                                    END IF
                                END IF

                            CASE &HC ' 12: Cut Note
                                IF __Song.tick = nOpY THEN
                                    __Channel(nChannel).volume = 0
                                    SoftSynth_SetVoiceVolume nChannel, __Channel(nChannel).volume / __INSTRUMENT_VOLUME_MAX
                                END IF

                            CASE &HD ' 13: Delay Note
                                IF __Song.tick = nOpY THEN
                                    __Channel(nChannel).volume = __Instrument(__Channel(nChannel).instrument).volume
                                    IF nVolume <= __INSTRUMENT_VOLUME_MAX THEN __Channel(nChannel).volume = nVolume
                                    SoftSynth_SetVoiceFrequency nChannel, __MODPlayer_GetFrequencyFromPeriod(__Channel(nChannel).period)
                                    SoftSynth_SetVoiceVolume nChannel, __Channel(nChannel).volume / __INSTRUMENT_VOLUME_MAX
                                    SoftSynth_PlayVoice nChannel, __Channel(nChannel).instrument, SoftSynth_BytesToFrames(__Channel(nChannel).startPosition, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels), __Instrument(__Channel(nChannel).instrument).playMode, SoftSynth_BytesToFrames(__Instrument(__Channel(nChannel).instrument).loopStart, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels), SoftSynth_BytesToFrames(__Instrument(__Channel(nChannel).instrument).loopEnd, __Instrument(__Channel(nChannel).instrument).bytesPerSample, __Instrument(__Channel(nChannel).instrument).channels)
                                END IF
                        END SELECT
                END SELECT
            END IF
        NEXT
    END SUB


    ' We always set the global BPM using this and never directly
    SUB __MODPlayer_SetBPM (nBPM AS _UNSIGNED _BYTE)
        $CHECKING:OFF
        SHARED __Song AS __SongType

        __Song.BPM = nBPM

        ' Calculate the number of samples we have to mix per tick
        __Song.framesPerTick = __Song.tempoTimerValue \ nBPM
        $CHECKING:ON
    END SUB


    ' Binary search the period table to find the closest value
    ' I hope this is the right way to do glissando. Oh well...
    FUNCTION __MODPlayer_GetClosestPeriod& (target AS LONG)
        SHARED __Song AS __SongType
        SHARED __Channel() AS __ChannelType
        SHARED __PeriodTable() AS _UNSIGNED INTEGER

        DIM AS LONG startPos, endPos, midPos, leftVal, rightVal

        IF target > 27392 THEN
            __MODPlayer_GetClosestPeriod = target
            EXIT FUNCTION
        ELSEIF target < 14 THEN
            __MODPlayer_GetClosestPeriod = target
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
            __MODPlayer_GetClosestPeriod = __PeriodTable(endPos)
        ELSE
            __MODPlayer_GetClosestPeriod = __PeriodTable(startPos)
        END IF
    END FUNCTION


    ' Carry out a tone portamento to a certain note
    SUB __MODPlayer_DoPortamento (chan AS _UNSIGNED _BYTE)
        SHARED __Channel() AS __ChannelType

        ' Slide up/down and clamp to destination
        IF __Channel(chan).period < __Channel(chan).portamentoTo THEN
            __Channel(chan).period = __Channel(chan).period + _SHL(__Channel(chan).portamentoSpeed, 2)
            IF __Channel(chan).period > __Channel(chan).portamentoTo THEN
                __Channel(chan).period = __Channel(chan).portamentoTo
            END IF
        ELSEIF __Channel(chan).period > __Channel(chan).portamentoTo THEN
            __Channel(chan).period = __Channel(chan).period - _SHL(__Channel(chan).portamentoSpeed, 2)
            IF __Channel(chan).period < __Channel(chan).portamentoTo THEN
                __Channel(chan).period = __Channel(chan).portamentoTo
            END IF
        END IF

        IF __Channel(chan).useGlissando THEN
            SoftSynth_SetVoiceFrequency chan, __MODPlayer_GetFrequencyFromPeriod(__MODPlayer_GetClosestPeriod(__Channel(chan).period))
        ELSE
            SoftSynth_SetVoiceFrequency chan, __MODPlayer_GetFrequencyFromPeriod(__Channel(chan).period)
        END IF
    END SUB


    ' Carry out a volume slide using +x -y
    SUB __MODPlayer_DoVolumeSlide (chan AS _UNSIGNED _BYTE, x AS _UNSIGNED _BYTE, y AS _UNSIGNED _BYTE)
        SHARED __Channel() AS __ChannelType

        __Channel(chan).volume = __Channel(chan).volume + x - y
        IF __Channel(chan).volume < 0 THEN __Channel(chan).volume = 0
        IF __Channel(chan).volume > __INSTRUMENT_VOLUME_MAX THEN __Channel(chan).volume = __INSTRUMENT_VOLUME_MAX

        SoftSynth_SetVoiceVolume chan, __Channel(chan).volume / __INSTRUMENT_VOLUME_MAX
    END SUB


    ' Carry out a vibrato at a certain depth and speed
    SUB __MODPlayer_DoVibrato (chan AS _UNSIGNED _BYTE)
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
                delta = RND * 255!
        END SELECT

        delta = _SHL(_SHR(delta * __Channel(chan).vibratoDepth, 7), 2)

        IF __Channel(chan).vibratoPosition >= 0 THEN
            SoftSynth_SetVoiceFrequency chan, __MODPlayer_GetFrequencyFromPeriod(__Channel(chan).period + delta)
        ELSE
            SoftSynth_SetVoiceFrequency chan, __MODPlayer_GetFrequencyFromPeriod(__Channel(chan).period - delta)
        END IF

        __Channel(chan).vibratoPosition = __Channel(chan).vibratoPosition + __Channel(chan).vibratoSpeed
        IF __Channel(chan).vibratoPosition > 31 THEN
            __Channel(chan).vibratoPosition = __Channel(chan).vibratoPosition - 64
        END IF
    END SUB


    ' Carry out a tremolo at a certain depth and speed
    SUB __MODPlayer_DoTremolo (chan AS _UNSIGNED _BYTE)
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
                delta = RND * 255!
        END SELECT

        delta = _SHR(delta * __Channel(chan).tremoloDepth, 6)

        IF __Channel(chan).tremoloPosition >= 0 THEN
            IF __Channel(chan).volume + delta > __INSTRUMENT_VOLUME_MAX THEN delta = __INSTRUMENT_VOLUME_MAX - __Channel(chan).volume
            SoftSynth_SetVoiceVolume chan, (__Channel(chan).volume + delta) / __INSTRUMENT_VOLUME_MAX
        ELSE
            IF __Channel(chan).volume - delta < 0 THEN delta = __Channel(chan).volume
            SoftSynth_SetVoiceVolume chan, (__Channel(chan).volume - delta) / __INSTRUMENT_VOLUME_MAX
        END IF

        __Channel(chan).tremoloPosition = __Channel(chan).tremoloPosition + __Channel(chan).tremoloSpeed
        IF __Channel(chan).tremoloPosition > 31 THEN __Channel(chan).tremoloPosition = __Channel(chan).tremoloPosition - 64
    END SUB


    ' Carry out an invert loop (EFx) effect
    ' This will trash the sample managed by the SoftSynth
    SUB __MODPlayer_DoInvertLoop (chan AS _UNSIGNED _BYTE)
        SHARED __Channel() AS __ChannelType
        SHARED __Instrument() AS __InstrumentType
        SHARED __InvertLoopSpeedTable() AS _UNSIGNED _BYTE

        __Channel(chan).invertLoopDelay = __Channel(chan).invertLoopDelay + __InvertLoopSpeedTable(__Channel(chan).invertLoopSpeed)

        DIM sampleNumber AS _UNSIGNED _BYTE: sampleNumber = __Channel(chan).instrument ' cache the sample number case we'll use this often below

        IF __Channel(chan).invertLoopDelay >= 128 AND SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP = __Instrument(sampleNumber).playMode THEN
            __Channel(chan).invertLoopDelay = 0 ' reset delay
            IF __Channel(chan).invertLoopPosition < __Instrument(sampleNumber).loopStart THEN
                __Channel(chan).invertLoopPosition = __Instrument(sampleNumber).loopStart
            END IF
            __Channel(chan).invertLoopPosition = __Channel(chan).invertLoopPosition + 1 ' increment position by 1
            IF __Channel(chan).invertLoopPosition >= __Instrument(sampleNumber).loopEnd THEN
                __Channel(chan).invertLoopPosition = __Instrument(sampleNumber).loopStart
            END IF

            ' Yeah I know, this is weird. QB64 NOT is bitwise and not logical
            DIM p AS _UNSIGNED LONG: p = SoftSynth_BytesToFrames(__Channel(chan).invertLoopPosition, __Instrument(sampleNumber).bytesPerSample, __Instrument(sampleNumber).channels)
            SoftSynth_PokeSoundFrameByte sampleNumber, p, NOT SoftSynth_PeekSoundFrameByte(sampleNumber, p)
        END IF
    END SUB


    ' This gives us the frequency in khz based on the period
    FUNCTION __MODPlayer_GetFrequencyFromPeriod~& (period AS LONG)
        $CHECKING:OFF
        __MODPlayer_GetFrequencyFromPeriod = 14317056 \ period
        $CHECKING:ON
    END FUNCTION


    ' Return C2 speed for a finetune
    FUNCTION __MODPlayer_GetC2Spd~% (ft AS _UNSIGNED _BYTE)
        $CHECKING:OFF
        SELECT CASE ft
            CASE 0
                __MODPlayer_GetC2Spd = 8363
            CASE 1
                __MODPlayer_GetC2Spd = 8413
            CASE 2
                __MODPlayer_GetC2Spd = 8463
            CASE 3
                __MODPlayer_GetC2Spd = 8529
            CASE 4
                __MODPlayer_GetC2Spd = 8581
            CASE 5
                __MODPlayer_GetC2Spd = 8651
            CASE 6
                __MODPlayer_GetC2Spd = 8723
            CASE 7
                __MODPlayer_GetC2Spd = 8757
            CASE 8
                __MODPlayer_GetC2Spd = 7895
            CASE 9
                __MODPlayer_GetC2Spd = 7941
            CASE 10
                __MODPlayer_GetC2Spd = 7985
            CASE 11
                __MODPlayer_GetC2Spd = 8046
            CASE 12
                __MODPlayer_GetC2Spd = 8107
            CASE 13
                __MODPlayer_GetC2Spd = 8169
            CASE 14
                __MODPlayer_GetC2Spd = 8232
            CASE 15
                __MODPlayer_GetC2Spd = 8280
            CASE ELSE
                __MODPlayer_GetC2Spd = 8363
        END SELECT
        $CHECKING:ON
    END FUNCTION


    ' Returns the tune title
    FUNCTION MODPlayer_GetName$
        $CHECKING:OFF
        SHARED __Song AS __SongType

        MODPlayer_GetName = __Song.caption
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

        __Song.isPaused = ToQBBool(state)
    END SUB


    ' Rerturns true if the tune if paused
    FUNCTION MODPlayer_IsPaused%%
        $CHECKING:OFF
        SHARED __Song AS __SongType

        MODPlayer_IsPaused = __Song.isPaused
        $CHECKING:ON
    END FUNCTION


    ' Sets the tune to loop if state is true
    SUB MODPlayer_Loop (state AS _BYTE)
        SHARED __Song AS __SongType

        __Song.isLooping = ToQBBool(state)
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
    SUB MODPlayer_SetPosition (position AS _UNSIGNED INTEGER)
        SHARED __Song AS __SongType

        IF position < __Song.orders THEN
            __Song.orderPosition = position
            __Song.patternRow = 0
        END IF
    END SUB


    ' Get the current tune order position
    FUNCTION MODPlayer_GetPosition&
        $CHECKING:OFF
        SHARED __Song AS __SongType

        MODPlayer_GetPosition = __Song.orderPosition
        $CHECKING:ON
    END FUNCTION


    ' Gets the number of orders in the tune
    FUNCTION MODPlayer_GetOrders~%
        $CHECKING:OFF
        SHARED __Song AS __SongType

        MODPlayer_GetOrders = __Song.orders
        $CHECKING:ON
    END FUNCTION

    '$INCLUDE:'SoftSynth.bas'
    '$INCLUDE:'MemFile.bas'
    '$INCLUDE:'FileOps.bas'

$END IF

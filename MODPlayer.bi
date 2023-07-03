'-----------------------------------------------------------------------------------------------------------------------
' MOD Player Library
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF MODPLAYER_BI = UNDEFINED THEN
    $LET MODPLAYER_BI = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' HEADER FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'Common.bi'
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' CONSTANTS
    '-------------------------------------------------------------------------------------------------------------------
    CONST __PATTERN_ROW_MAX = 63 ' Max row number in a pattern
    CONST __NOTE_NONE = 132 ' Note will be set to this when there is nothing
    CONST __NOTE_KEY_OFF = 133 ' We'll use this in a future version
    CONST __NOTE_NO_VOLUME = 255 ' When a note has no volume, then it will be set to this
    CONST __ORDER_TABLE_MAX = 127 ' Max position in the order table
    CONST __SONG_SPEED_DEFAULT = 6 ' This is the default speed for song where it is not specified
    CONST __SONG_BPM_DEFAULT = 125 ' Default song BPM
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' USER DEFINED TYPES
    '-------------------------------------------------------------------------------------------------------------------
    TYPE __NoteType
        note AS _UNSIGNED _BYTE ' Contains info on 1 note
        sample AS _UNSIGNED _BYTE ' Sample number to play
        volume AS _UNSIGNED _BYTE ' Volume value. Not used for MODs. 255 = no volume
        effect AS _UNSIGNED _BYTE ' Effect number
        operand AS _UNSIGNED _BYTE ' Effect parameters
    END TYPE

    TYPE __SampleType
        sampleName AS STRING * 22 ' Sample name or message
        length AS LONG ' Sample length in bytes
        c2Spd AS _UNSIGNED INTEGER ' Sample finetune is converted to c2spd
        volume AS _UNSIGNED _BYTE ' Volume: 0 - 64
        loopStart AS LONG ' Loop start in bytes
        loopLength AS LONG ' Loop length in bytes
        loopEnd AS LONG ' Loop end in bytes
    END TYPE

    TYPE __ChannelType
        sample AS _UNSIGNED _BYTE ' Sample number to be mixed
        volume AS INTEGER ' Channel volume. This is a signed int because we need -ve values & to clip properly
        restart AS _BYTE ' Set this to true to retrigger the sample
        note AS _UNSIGNED _BYTE ' Last note set in channel
        period AS LONG ' This is the period of the playing sample used by various effects
        lastPeriod AS LONG ' Last period set in channel
        startPosition AS LONG ' This is starting position of the sample. Usually zero else value from sample offset effect
        patternLoopRow AS INTEGER ' This (signed) is the beginning of the loop in the pattern for effect E6x
        patternLoopRowCounter AS _UNSIGNED _BYTE ' This is a loop counter for effect E6x
        portamentoTo AS LONG ' Frequency to porta to value for E3x
        portamentoSpeed AS _UNSIGNED _BYTE ' Porta speed for E3x
        vibratoPosition AS _BYTE ' Vibrato position in the sine table for E4x (signed)
        vibratoSpeed AS _UNSIGNED _BYTE ' Vibrato speed
        vibratoDepth AS _UNSIGNED _BYTE ' Vibrato depth
        tremoloPosition AS _BYTE ' Tremolo position in the sine table (signed)
        tremoloSpeed AS _UNSIGNED _BYTE ' Tremolo speed
        tremoloDepth AS _UNSIGNED _BYTE ' Tremolo depth
        waveControl AS _UNSIGNED _BYTE ' Waveform type for vibrato and tremolo (4 bits each)
        useGlissando AS _BYTE ' Flag to enable glissando (E3x) for subsequent porta-to-note effect
        invertLoopSpeed AS _UNSIGNED _BYTE ' Invert loop speed for EFx
        invertLoopDelay AS _UNSIGNED INTEGER ' Invert loop delay for EFx
        invertLoopPosition AS LONG ' Position in the sample where we are for the invert loop effect
    END TYPE

    TYPE __SongType
        songName AS STRING * 20 ' Song name
        subtype AS STRING * 4 ' 4 char MOD type - use this to find out what tracker was used
        channels AS _UNSIGNED _BYTE ' Number of channels in the song - can be any number depending on the MOD file
        samples AS _UNSIGNED _BYTE ' Number of samples in the song - can be 15 or 31 depending on the MOD file
        orders AS _UNSIGNED _BYTE ' Song length in orders
        endJumpOrder AS _UNSIGNED _BYTE ' This is used for jumping to an order if global looping is on
        highestPattern AS _UNSIGNED _BYTE ' The highest pattern number read from the MOD file
        orderPosition AS INTEGER ' The position in the order list. Signed so that we can properly wrap
        patternRow AS INTEGER ' Points to the pattern row to be played. This is signed because sometimes we need to set it to -1
        tickPattern AS _UNSIGNED _BYTE ' Pattern number for UpdateMODRow() & UpdateMODTick()
        tickPatternRow AS INTEGER ' Pattern row number for UpdateMODRow() & UpdateMODTick() (signed)
        isLooping AS _BYTE ' Set this to true to loop the song once we reach the max order specified in the song
        isPlaying AS _BYTE ' This is set to true as long as the song is playing
        isPaused AS _BYTE ' Set this to true to pause playback
        patternDelay AS _UNSIGNED _BYTE ' Number of times to delay pattern for effect EE
        periodTableMax AS _UNSIGNED _BYTE ' We need this for searching through the period table for E3x
        speed AS _UNSIGNED _BYTE ' Current song speed
        bpm AS _UNSIGNED _BYTE ' Current song BPM
        tick AS _UNSIGNED _BYTE ' Current song tick
        tempoTimerValue AS _UNSIGNED LONG ' (mixer_sample_rate * default_bpm) / 50
        samplesPerTick AS _UNSIGNED LONG ' This is the amount of samples we have to mix per tick based on mixerRate & bpm
        activeChannels AS _UNSIGNED _BYTE ' Just a count of channels that are "active"
    END TYPE
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' GLOBAL VARIABLES
    '-------------------------------------------------------------------------------------------------------------------
    DIM __Song AS __SongType
    DIM __Order(0 TO __ORDER_TABLE_MAX) AS _UNSIGNED _BYTE ' Order list
    REDIM __Pattern(0 TO 0, 0 TO 0, 0 TO 0) AS __NoteType ' Pattern data strored as (pattern, row, channel)
    REDIM __Sample(0 TO 0) AS __SampleType ' Sample info array
    REDIM __Channel(0 TO 0) AS __ChannelType ' Channel info array
    REDIM __PeriodTable(0 TO 0) AS _UNSIGNED INTEGER ' Amiga period table
    REDIM __SineTable(0 TO 0) AS _UNSIGNED _BYTE ' Sine table used for effects
    REDIM __InvertLoopSpeedTable(0 TO 0) AS _UNSIGNED _BYTE ' Invert loop speed table for EFx
    '-------------------------------------------------------------------------------------------------------------------
$END IF
'-----------------------------------------------------------------------------------------------------------------------

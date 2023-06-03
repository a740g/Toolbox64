'-----------------------------------------------------------------------------------------------------------------------
' MOD Player Library
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$include:'SoftSynth.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If MODPLAYER_BI = UNDEFINED Then
    $Let MODPLAYER_BI = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' CONSTANTS
    '-------------------------------------------------------------------------------------------------------------------
    Const __PATTERN_ROW_MAX = 63 ' Max row number in a pattern
    Const __NOTE_NONE = 132 ' Note will be set to this when there is nothing
    Const __NOTE_KEY_OFF = 133 ' We'll use this in a future version
    Const __NOTE_NO_VOLUME = 255 ' When a note has no volume, then it will be set to this
    Const __ORDER_TABLE_MAX = 127 ' Max position in the order table
    Const __SONG_SPEED_DEFAULT = 6 ' This is the default speed for song where it is not specified
    Const __SONG_BPM_DEFAULT = 125 ' Default song BPM
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' USER DEFINED TYPES
    '-------------------------------------------------------------------------------------------------------------------
    Type __NoteType
        note As _Unsigned _Byte ' Contains info on 1 note
        sample As _Unsigned _Byte ' Sample number to play
        volume As _Unsigned _Byte ' Volume value. Not used for MODs. 255 = no volume
        effect As _Unsigned _Byte ' Effect number
        operand As _Unsigned _Byte ' Effect parameters
    End Type

    Type __SampleType
        sampleName As String * 22 ' Sample name or message
        length As Long ' Sample length in bytes
        c2Spd As _Unsigned Integer ' Sample finetune is converted to c2spd
        volume As _Unsigned _Byte ' Volume: 0 - 64
        loopStart As Long ' Loop start in bytes
        loopLength As Long ' Loop length in bytes
        loopEnd As Long ' Loop end in bytes
    End Type

    Type __ChannelType
        sample As _Unsigned _Byte ' Sample number to be mixed
        volume As Integer ' Channel volume. This is a signed int because we need -ve values & to clip properly
        restart As _Byte ' Set this to true to retrigger the sample
        note As _Unsigned _Byte ' Last note set in channel
        period As Long ' This is the period of the playing sample used by various effects
        lastPeriod As Long ' Last period set in channel
        startPosition As Long ' This is starting position of the sample. Usually zero else value from sample offset effect
        patternLoopRow As Integer ' This (signed) is the beginning of the loop in the pattern for effect E6x
        patternLoopRowCounter As _Unsigned _Byte ' This is a loop counter for effect E6x
        portamentoTo As Long ' Frequency to porta to value for E3x
        portamentoSpeed As _Unsigned _Byte ' Porta speed for E3x
        vibratoPosition As _Byte ' Vibrato position in the sine table for E4x (signed)
        vibratoSpeed As _Unsigned _Byte ' Vibrato speed
        vibratoDepth As _Unsigned _Byte ' Vibrato depth
        tremoloPosition As _Byte ' Tremolo position in the sine table (signed)
        tremoloSpeed As _Unsigned _Byte ' Tremolo speed
        tremoloDepth As _Unsigned _Byte ' Tremolo depth
        waveControl As _Unsigned _Byte ' Waveform type for vibrato and tremolo (4 bits each)
        useGlissando As _Byte ' Flag to enable glissando (E3x) for subsequent porta-to-note effect
        invertLoopSpeed As _Unsigned _Byte ' Invert loop speed for EFx
        invertLoopDelay As _Unsigned Integer ' Invert loop delay for EFx
        invertLoopPosition As Long ' Position in the sample where we are for the invert loop effect
    End Type

    Type __SongType
        songName As String * 20 ' Song name
        subtype As String * 4 ' 4 char MOD type - use this to find out what tracker was used
        channels As _Unsigned _Byte ' Number of channels in the song - can be any number depending on the MOD file
        samples As _Unsigned _Byte ' Number of samples in the song - can be 15 or 31 depending on the MOD file
        orders As _Unsigned _Byte ' Song length in orders
        endJumpOrder As _Unsigned _Byte ' This is used for jumping to an order if global looping is on
        highestPattern As _Unsigned _Byte ' The highest pattern number read from the MOD file
        orderPosition As Integer ' The position in the order list. Signed so that we can properly wrap
        patternRow As Integer ' Points to the pattern row to be played. This is signed because sometimes we need to set it to -1
        tickPattern As _Unsigned _Byte ' Pattern number for UpdateMODRow() & UpdateMODTick()
        tickPatternRow As Integer ' Pattern row number for UpdateMODRow() & UpdateMODTick() (signed)
        isLooping As _Byte ' Set this to true to loop the song once we reach the max order specified in the song
        isPlaying As _Byte ' This is set to true as long as the song is playing
        isPaused As _Byte ' Set this to true to pause playback
        patternDelay As _Unsigned _Byte ' Number of times to delay pattern for effect EE
        periodTableMax As _Unsigned _Byte ' We need this for searching through the period table for E3x
        speed As _Unsigned _Byte ' Current song speed
        bpm As _Unsigned _Byte ' Current song BPM
        tick As _Unsigned _Byte ' Current song tick
        tempoTimerValue As _Unsigned Long ' (mixer_sample_rate * default_bpm) / 50
        samplesPerTick As _Unsigned Long ' This is the amount of samples we have to mix per tick based on mixerRate & bpm
        activeChannels As _Unsigned _Byte ' Just a count of channels that are "active"
    End Type
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' GLOBAL VARIABLES
    '-------------------------------------------------------------------------------------------------------------------
    Dim __Song As __SongType
    Dim __Order(0 To __ORDER_TABLE_MAX) As _Unsigned _Byte ' Order list
    ReDim __Pattern(0 To 0, 0 To 0, 0 To 0) As __NoteType ' Pattern data strored as (pattern, row, channel)
    ReDim __Sample(0 To 0) As __SampleType ' Sample info array
    ReDim __Channel(0 To 0) As __ChannelType ' Channel info array
    ReDim __PeriodTable(0 To 0) As _Unsigned Integer ' Amiga period table
    ReDim __SineTable(0 To 0) As _Unsigned _Byte ' Sine table used for effects
    ReDim __InvertLoopSpeedTable(0 To 0) As _Unsigned _Byte ' Invert loop speed table for EFx
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------

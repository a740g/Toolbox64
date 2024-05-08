'-----------------------------------------------------------------------------------------------------------------------
' MOD Player Library
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'
'$INCLUDE:'Types.bi'
'$INCLUDE:'SoftSynth.bi'
'$INCLUDE:'AudioConv.bi'
'$INCLUDE:'MemFile.bi'
'$INCLUDE:'FileOps.bi'

CONST __NOTE_NONE~%% = 132~%% ' Note will be set to this when there is nothing
CONST __NOTE_KEY_OFF~%% = 133~%% ' We'll use this in a future version
CONST __NOTE_NO_VOLUME~%% = 255~%% ' When a note has no volume, then it will be set to this
CONST __MOD_S3M_ROWS~%% = 64~%% ' number of rows in a MOD / S3M pattern
CONST __MOD_MTM_ORDER_MAX~%% = 127~%% ' maximum position in a MOD / MTM order table
CONST __INSTRUMENT_VOLUME_MAX~%% = 64~%% ' this is the maximum volume of any MOD instrument
CONST __INSTRUMENT_NONE~%% = 0~%% ' no instrument
CONST __INSTRUMENT_PCM~%% = 1~%% ' good old digital PCM instrument
CONST __INSTRUMENT_FM_MELODY~%% = 2~%% ' FM melody instrument
CONST __INSTRUMENT_FM_BASSDRUM~%% = 3~%% ' FM bass drum instrument
CONST __INSTRUMENT_FM_SNAREDRUM~%% = 4~%% ' FM snare instrument
CONST __INSTRUMENT_FM_TOMTOM~%% = 5~%% ' FM tom-tom instrument
CONST __INSTRUMENT_FM_CYMBAL~%% = 6~%% ' FM cymbal instrument
CONST __INSTRUMENT_FM_HIHAT~%% = 7~%% ' FM hi-hat instrument
CONST __PATTERN_MARKER~%% = 254~%% ' S3M marker pattern
CONST __PATTERN_END~%% = 255~%% ' S3M end-of-song
CONST __CHANNEL_STEREO_SEPARATION! = 0.5! ' 100% stereo separation sounds bad on headphones
CONST __MTM_S3M_CHANNEL_MAX~%% = 31~%% ' maximum channel number supported by MTM / S3M
CONST __S3M_GLOBAL_VOLUME_MAX~%% = 64~%% ' S3M global volume maximum value
CONST __SONG_SPEED_DEFAULT~%% = 6~%% ' This is the default speed for song where it is not specified
CONST __SONG_BPM_DEFAULT~%% = 125~%% ' Default song BPM when it is not specified
' These are the effects support by the player (basically these are Protracker effects + extras)
CONST __MOD_FX_ARPEGGIO~%% = 0~%%
CONST __MOD_FX_PORTAMENTO_UP~%% = 1~%%
CONST __MOD_FX_PORTAMENTO_DOWN~%% = 2~%%
CONST __MOD_FX_PORTAMENTO~%% = 3~%%
CONST __MOD_FX_VIBRATO~%% = 4~%%
CONST __MOD_FX_PORTAMETO_VOLUME_SLIDE~%% = 5~%%
CONST __MOD_FX_VIBRATO_VOLUME_SLIDE~%% = 6~%%
CONST __MOD_FX_TREMOLO~%% = 7~%%
CONST __MOD_FX_PANNING_8~%% = 8~%%
CONST __MOD_FX_SAMPLE_OFFSET~%% = 9~%%
CONST __MOD_FX_VOLUME_SLIDE~%% = 10~%%
CONST __MOD_FX_POSITION_JUMP~%% = 11~%%
CONST __MOD_FX_VOLUME~%% = 12~%%
CONST __MOD_FX_PATTERN_BREAK~%% = 13~%%
CONST __MOD_FX_EXTENDED~%% = 14~%%
CONST __MOD_FX_EXTENDED_FILTER~%% = 0~%%
CONST __MOD_FX_EXTENDED_PORTAMENTO_FINE_UP~%% = 1~%%
CONST __MOD_FX_EXTENDED_PORTAMENTO_FINE_DOWN~%% = 2~%%
CONST __MOD_FX_EXTENDED_GLISSANDO_CONTROL~%% = 3~%%
CONST __MOD_FX_EXTENDED_VIBRATO_WAVEFORM~%% = 4~%%
CONST __MOD_FX_EXTENDED_FINETUNE~%% = 5~%%
CONST __MOD_FX_EXTENDED_PATTERN_LOOP~%% = 6~%%
CONST __MOD_FX_EXTENDED_TREMOLO_WAVEFORM~%% = 7~%%
CONST __MOD_FX_EXTENDED_PANNING_4~%% = 8~%%
CONST __MOD_FX_EXTENDED_NOTE_RETRIGGER~%% = 9~%%
CONST __MOD_FX_EXTENDED_VOLUME_FINE_SLIDE_UP~%% = 10~%%
CONST __MOD_FX_EXTENDED_VOLUME_FINE_SLIDE_DOWN~%% = 11~%%
CONST __MOD_FX_EXTENDED_NOTE_CUT~%% = 12~%%
CONST __MOD_FX_EXTENDED_NOTE_DELAY~%% = 13~%%
CONST __MOD_FX_EXTENDED_PATTERN_DELAY~%% = 14~%%
CONST __MOD_FX_EXTENDED_INVERT_LOOP~%% = 15~%%
CONST __MOD_FX_SPEED_TEMPO~%% = 15~%%
CONST __MOD_FX_SPEED~%% = 16~%%
CONST __MOD_FX_VOLUME_FINE_SLIDE~%% = 17~%%
CONST __MOD_FX_PORTAMENTO_EXTRA_FINE_DOWN~%% = 18~%%
CONST __MOD_FX_PORTAMENTO_EXTRA_FINE_UP~%% = 19~%%
CONST __MOD_FX_TREMOR~%% = 20~%%
CONST __MOD_FX_VIBRATO_VOLUME_FINE_SLIDE~%% = 21~%%
CONST __MOD_FX_PORTAMETO_VOLUME_FINE_SLIDE~%% = 22~%%
CONST __MOD_FX_CHANNEL_VOLUME~%% = 23~%%
CONST __MOD_FX_CHANNEL_VOLUME_SLIDE~%% = 24~%%
CONST __MOD_FX_PANNING_FINE_SLIDE~%% = 25~%%
CONST __MOD_FX_NOTE_RETRIGGER_VOLUME_SLIDE~%% = 26~%%
CONST __MOD_FX_PANBRELLO_WAVEFORM~%% = 27~%%
CONST __MOD_FX_PATTERN_FINE_DELAY~%% = 28~%%
CONST __MOD_FX_SOUND_CONTROL~%% = 29~%%
CONST __MOD_FX_HIGH_OFFSET~%% = 30~%%
CONST __MOD_FX_TEMPO~%% = 31~%%
CONST __MOD_FX_VIBRATO_FINE~%% = 32~%%
CONST __MOD_FX_GLOBAL_VOLUME~%% = 33~%%
CONST __MOD_FX_GLOBAL_VOLUME_SLIDE~%% = 34~%%
CONST __MOD_FX_PANBRELLO~%% = 35~%%
CONST __MOD_FX_MIDI_MACRO~%% = 36~%%

TYPE __NoteType
    note AS _UNSIGNED _BYTE ' contains info on 1 note
    instrument AS _UNSIGNED _BYTE ' instrument number to play
    volume AS _UNSIGNED _BYTE ' volume value. Not used for MODs. 255 = no volume
    effect AS _UNSIGNED _BYTE ' effect number
    operand AS _UNSIGNED _BYTE ' effect parameters
END TYPE

TYPE __InstrumentType
    caption AS STRING ' instrument name or message
    subtype AS _UNSIGNED _BYTE ' what kind of instrument is this? (PCM, FM melody, FM drum, etc.)
    length AS _UNSIGNED LONG ' sample length in bytes
    c2Spd AS _UNSIGNED INTEGER ' sample finetune is converted to c2spd
    volume AS _UNSIGNED _BYTE ' volume: 0 - 64
    loopStart AS _UNSIGNED LONG ' loop start (or just start; usually 0) in bytes
    loopEnd AS _UNSIGNED LONG ' loop end (or just end; usually length) in bytes
    playMode AS LONG ' the playack mode (supported by SoftSynth)
    bytesPerSample AS _UNSIGNED _BYTE ' 1 for 8-bit, 2 for 16-bit, 4 for 32-bit etc. (SoftSynth will convert sounds to 32-bit floating point)
    channels AS _UNSIGNED _BYTE ' number of channels per frame (SoftSynth will flatten sounds to mono)
END TYPE

TYPE __ChannelType
    instrument AS _UNSIGNED _BYTE ' instrument number to be mixed
    subtype AS _UNSIGNED _BYTE ' what kind of channel is this? (PCM, FM melody, FM drum, etc.) TODO: Do we really need this?
    volume AS INTEGER ' channel volume. This is a signed int because we need -ve values & to clip properly
    restart AS _BYTE ' set this to true to retrigger the sample
    note AS _UNSIGNED _BYTE ' last note set in channel
    period AS LONG ' this is the period of the playing sample used by various effects
    lastPeriod AS LONG ' last period set in channel
    startPosition AS _UNSIGNED LONG ' this is starting position of the sample. Usually zero else value from sample offset effect
    patternLoopRow AS INTEGER ' this (signed) is the beginning of the loop in the pattern for effect E6x
    patternLoopRowCounter AS _UNSIGNED _BYTE ' this is a loop counter for effect E6x
    portamentoTo AS LONG ' frequency to porta to value for E3x
    portamentoSpeed AS _UNSIGNED _BYTE ' porta speed for E3x
    vibratoPosition AS _BYTE ' vibrato position in the sine table for E4x (signed)
    vibratoSpeed AS _UNSIGNED _BYTE ' vibrato speed
    vibratoDepth AS _UNSIGNED _BYTE ' vibrato depth
    tremoloPosition AS _BYTE ' tremolo position in the sine table (signed)
    tremoloSpeed AS _UNSIGNED _BYTE ' tremolo speed
    tremoloDepth AS _UNSIGNED _BYTE ' tremolo depth
    waveControl AS _UNSIGNED _BYTE ' waveform type for vibrato and tremolo (4 bits each)
    useGlissando AS _BYTE ' flag to enable glissando (E3x) for subsequent porta-to-note effect
    invertLoopSpeed AS _UNSIGNED _BYTE ' invert loop speed for EFx
    invertLoopDelay AS _UNSIGNED INTEGER ' invert loop delay for EFx
    invertLoopPosition AS _UNSIGNED LONG ' position in the sample where we are for the invert loop effect
    lastVolumeSlide AS _UNSIGNED _BYTE ' last S3M volume slide value
    lastPortamento AS _UNSIGNED _BYTE ' last S3M portamento up or down value
    tremorPosition AS _UNSIGNED _BYTE ' tremor position
    tremorParameters AS _UNSIGNED _BYTE ' tremor parameters
    retriggerVolumeSlide AS _UNSIGNED _BYTE ' last retrigger volume slide
    retriggerTickCount AS _UNSIGNED _BYTE ' last retrigger tick count
END TYPE

TYPE __SongType
    caption AS STRING ' song name
    subtype AS STRING * 4 ' 4 char MOD type - use this to find out what tracker was used
    comment AS STRING ' song comment / message (if any)
    channels AS _UNSIGNED LONG ' number of channels in the song
    instruments AS _UNSIGNED LONG ' number of instruments in the song
    orders AS _UNSIGNED INTEGER ' song length in orders
    rows AS _UNSIGNED _BYTE ' number of rows in each pattern
    endJumpOrder AS _UNSIGNED _BYTE ' this is used for jumping to an order if global looping is on
    patterns AS _UNSIGNED INTEGER ' number of patterns in the song
    orderPosition AS LONG ' the position in the order list. Signed so that we can properly wrap
    patternRow AS INTEGER ' points to the pattern row to be played. This is signed because sometimes we need to set it to -1
    tickPattern AS _UNSIGNED INTEGER ' pattern number for UpdateMODRow() & UpdateMODTick()
    tickPatternRow AS INTEGER ' pattern row number for UpdateMODRow() & UpdateMODTick() (signed)
    isLooping AS _BYTE ' set this to true to loop the song once we reach the max order specified in the song
    isPlaying AS _BYTE ' this is set to true as long as the song is playing
    isPaused AS _BYTE ' set this to true to pause playback
    patternDelay AS _UNSIGNED _BYTE ' number of times to delay pattern for effect EE
    periodTableMax AS _UNSIGNED _BYTE ' we need this for searching through the period table for E3x
    speed AS _UNSIGNED _BYTE ' current song speed
    BPM AS _UNSIGNED _BYTE ' current song BPM
    defaultSpeed AS _UNSIGNED _BYTE ' default song speed
    defaultBPM AS _UNSIGNED _BYTE ' default song BPM
    tick AS _UNSIGNED _BYTE ' current song tick
    tempoTimerValue AS _UNSIGNED LONG ' (mixer_sample_rate * default_bpm) / 50
    framesPerTick AS _UNSIGNED LONG ' this is the amount of sample frames we have to mix per tick based on mixerRate & bpm
    activeChannels AS _UNSIGNED LONG ' just a count of channels that are "active"
    useAmigaLPF AS _BYTE ' use Amiga 12 dB/oct Butterworth low-pass filter
    useST2Vibrato AS _BYTE ' use Scream Tracker 2 vibrato
    useST2Tempo AS _BYTE ' use Scream Tracker 2 tempo behavior
    useAmigaSlides AS _BYTE ' use volume slides similar to Amiga hardware
    useVolumeOptimization AS _BYTE ' turn off looping notes which have a zero volume for more than 2 rows
    useAmigaLimits AS _BYTE ' use Amiga limits (limit periods to confine to 113 <= x <= 856)
    useFilterSFX AS _BYTE ' enable filter / sfx with SB
    useST300VolumeSlides AS _BYTE ' ST3.00 volume slides (automatically enabled if tracker version is <= 0x1300) - if enabled, all volume slides occur every tick
    hasSpecialCustomData AS _BYTE ' special custom data in file (uses "Special" field)
END TYPE

DIM __Song AS __SongType ' tune specific data
REDIM __Order(0 TO 0) AS _UNSIGNED INTEGER ' order list
REDIM __Pattern(0 TO 0, 0 TO 0, 0 TO 0) AS __NoteType ' pattern data strored as (pattern, row, channel)
REDIM __Instrument(0 TO 0) AS __InstrumentType ' instrument info array
REDIM __Channel(0 TO 0) AS __ChannelType ' channel info array
REDIM __PeriodTable(0 TO 0) AS _UNSIGNED INTEGER ' Amiga period table
REDIM __SineTable(0 TO 0) AS _UNSIGNED _BYTE ' sine table used for effects
REDIM __InvertLoopSpeedTable(0 TO 0) AS _UNSIGNED _BYTE ' invert loop speed table for EFx

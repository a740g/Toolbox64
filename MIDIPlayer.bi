'---------------------------------------------------------------------------------------------------------
' QB64 MIDI Player Library
' Copyright (c) 2022 Samuel Gomes
'
' This uses TinySoundFont + TinyMidiLoader libraries from https://github.com/schellingb/TinySoundFont
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'./Common.bi'
'---------------------------------------------------------------------------------------------------------

$If MIDIPLAYER_BI = UNDEFINED Then
    $Let MIDIPLAYER_BI = TRUE
    '-----------------------------------------------------------------------------------------------------
    ' CONSTANTS
    '-----------------------------------------------------------------------------------------------------
    Const TSF_SOUND_BUFFER_CHANNELS = 2 ' 2 channels (stereo)
    Const TSF_SOUND_BUFFER_SAMPLE_SIZE = 4 ' 4 bytes (32-bits floating point)
    Const TSF_SOUND_BUFFER_FRAME_SIZE = TSF_SOUND_BUFFER_SAMPLE_SIZE * TSF_SOUND_BUFFER_CHANNELS
    Const TSF_SOUND_TIME_MIN = 0.2 ' We will check that we have this amount of time left in the QB64 sound pipe

    Const TSF_VOLUME_MAX = 100 ' Max volume in percentage
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' USER DEFINED TYPES
    '-----------------------------------------------------------------------------------------------------
    ' QB64 specific stuff
    Type TSFPlayerType
        isPaused As Byte ' Set to true if tune is paused
        soundBuffer As MEM ' This is the buffer that holds the rendered samples from TSF
        soundBufferSize As Unsigned Long ' Size of the render buffer
        soundHandle As Long ' The sound pipe that we wll use to play the rendered samples
    End Type
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' EXTERNAL LIBRARIES
    '-----------------------------------------------------------------------------------------------------
    ' Anything with a '__' prefix is not supposed to be called directly
    ' There are QB64 wrappers for these functions
    Declare CustomType Library "./MIDIPlayer"
        Function __TSFInitialize& (ByVal nSampleRate As Long)
        Function TSFIsInitialized&
        Sub __TSFFinalize
        Function __TSFLoadFile& (sFilename As String)
        Function TSFIsFileLoaded&
        Sub TSFStartPlayer
        Function TSFIsPlaying&
        Function TSFGetIsLooping&
        Sub TSFSetIsLooping (ByVal nLooping As Long)
        Sub TSFStopPlayer
        Function TSFGetVolume&
        Sub TSFSetVolume (ByVal nVolume As Long)
        Function TSFGetTotalTime#
        Function TSFGetCurrentTime#
        Function TSFGetActiveVoices&
        Sub __TSFRender (ByVal oBuffer As Offset, Byval nSize As Long)
    End Declare
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' GLOBAL VARIABLES
    '-----------------------------------------------------------------------------------------------------
    Dim TSFPlayer As TSFPlayerType
    '-----------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------


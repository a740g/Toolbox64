'---------------------------------------------------------------------------------------------------------
' MIDI Player Library
' Copyright (c) 2023 Samuel Gomes
'
' This uses:
' TinySoundFont from https://github.com/schellingb/TinySoundFont/blob/master/tsf.h
' TinyMidiLoader from https://github.com/schellingb/TinySoundFont/blob/master/tml.h
' opl.h from https://github.com/mattiasgustavsson/libs/blob/main/opl.h
' stb_vorbis.c from https://github.com/nothings/stb/blob/master/stb_vorbis.c
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'Common.bi'
'---------------------------------------------------------------------------------------------------------

$If MIDIPLAYER_BI = UNDEFINED Then
    $Let MIDIPLAYER_BI = TRUE
    '-----------------------------------------------------------------------------------------------------
    ' CONSTANTS
    '-----------------------------------------------------------------------------------------------------
    Const __MIDI_SOUND_BUFFER_CHANNELS = 2 ' 2 channels (stereo)
    Const __MIDI_SOUND_BUFFER_SAMPLE_SIZE = 4 ' 4 bytes (32-bits floating point)
    Const __MIDI_SOUND_BUFFER_FRAME_SIZE = __MIDI_SOUND_BUFFER_SAMPLE_SIZE * __MIDI_SOUND_BUFFER_CHANNELS

    Const MIDI_VOLUME_MAX = 1 ' max volume
    Const MIDI_VOLUME_MIN = 0 ' min volume
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' USER DEFINED TYPES
    '-----------------------------------------------------------------------------------------------------
    ' QB64 specific stuff
    Type __MIDI_PlayerType
        isPaused As Byte ' set to true if tune is paused
        soundBuffer As MEM ' this is the buffer that holds the rendered samples from the library
        soundBufferSize As Unsigned Long ' size of the render buffer
        soundHandle As Long ' the sound pipe that we wll use to play the rendered samples
    End Type
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' EXTERNAL LIBRARIES
    '-----------------------------------------------------------------------------------------------------
    ' Anything with a '__' prefix is not supposed to be called directly
    ' There are QB64 wrappers for these functions
    Declare CustomType Library "MIDIPlayer"
        Function __MIDI_Initialize& (ByVal sampleRate As Unsigned Long, Byval useOPL3 As Long)
        Function MIDI_IsInitialized&
        Sub __MIDI_Finalize
        Function __MIDI_LoadTuneFromFile& (sFilename As String)
        Function __MIDI_LoadTuneFromMemory& (buffer As String, Byval bufferSize As Unsigned Long)
        Function MIDI_IsTuneLoaded&
        Sub MIDI_StartPlayer
        Sub MIDI_StopPlayer
        Function MIDI_IsPlaying&
        Sub MIDI_SetLooping (ByVal isLooping As Long)
        Function MIDI_IsLooping&
        Function MIDI_GetVolume!
        Sub MIDI_SetVolume (ByVal volume As Single)
        Function MIDI_GetTotalTime#
        Function MIDI_GetCurrentTime#
        Function MIDI_GetActiveVoices~&
        Function MIDI_IsFMSynthesis&
        Sub __MIDI_Render (ByVal buffer As Offset, Byval size As Unsigned Long)
    End Declare
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' GLOBAL VARIABLES
    '-----------------------------------------------------------------------------------------------------
    Dim __MIDI_Player As __MIDI_PlayerType
    '-----------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------


'-----------------------------------------------------------------------------------------------------------------------
' MIDI Player Library
' Copyright (c) 2023 Samuel Gomes
'
' This uses:
' TinySoundFont from https://github.com/schellingb/TinySoundFont/blob/master/tsf.h
' TinyMidiLoader from https://github.com/schellingb/TinySoundFont/blob/master/tml.h
' opl.h from https://github.com/mattiasgustavsson/libs/blob/main/opl.h
' stb_vorbis.c from https://github.com/nothings/stb/blob/master/stb_vorbis.c
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'CRTLib.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If MIDIPLAYER_BI = UNDEFINED Then
    $Let MIDIPLAYER_BI = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' CONSTANTS
    '-------------------------------------------------------------------------------------------------------------------
    Const __MIDI_SOUND_BUFFER_CHANNELS = 2 ' 2 channels (stereo)
    Const __MIDI_SOUND_BUFFER_SAMPLE_SIZE = 4 ' 4 bytes (32-bits floating point)
    Const __MIDI_SOUND_BUFFER_FRAME_SIZE = __MIDI_SOUND_BUFFER_SAMPLE_SIZE * __MIDI_SOUND_BUFFER_CHANNELS

    Const MIDI_SOUND_BUFFER_TIME_DEFAULT = 0.2 ' we will check that we have this amount of time left in the QB64 sound pipe

    Const MIDI_VOLUME_MAX = 1 ' max volume
    Const MIDI_VOLUME_MIN = 0 ' min volume
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' USER DEFINED TYPES
    '-------------------------------------------------------------------------------------------------------------------
    ' QB64 specific stuff
    Type __MIDI_PlayerType
        isPaused As _Byte ' set to true if tune is paused
        soundBuffer As _MEM ' this is the buffer that holds the rendered samples from the library
        soundBufferFrames As _Unsigned Long ' size of the render buffer in frames
        soundBufferBytes As _Unsigned Long ' size of the render buffer in bytes
        soundHandle As Long ' the sound pipe that we wll use to play the rendered samples
    End Type
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' EXTERNAL LIBRARIES
    '-------------------------------------------------------------------------------------------------------------------
    ' Anything with a '__' prefix is not supposed to be called directly
    ' There are QB64 wrappers for these functions
    Declare CustomType Library "MIDIPlayer"
        Function __MIDI_Initialize%% (ByVal sampleRate As _Unsigned Long, Byval useOPL3 As _Byte)
        Function MIDI_IsInitialized%%
        Sub __MIDI_Finalize
        Function __MIDI_LoadTuneFromFile%% (filename As String)
        Function __MIDI_LoadTuneFromMemory%% (buffer As String, Byval size As _Unsigned Long)
        Function MIDI_IsTuneLoaded%%
        Sub MIDI_Play
        Sub MIDI_Stop
        Function MIDI_IsPlaying%%
        Sub MIDI_Loop (ByVal isLooping As _Byte)
        Function MIDI_IsLooping%%
        Function MIDI_GetVolume!
        Sub MIDI_SetVolume (ByVal volume As Single)
        Function MIDI_GetTotalTime#
        Function MIDI_GetCurrentTime#
        Function MIDI_GetActiveVoices~&
        Function MIDI_IsFMSynthesis%%
        Sub __MIDI_Render (ByVal buffer As _Offset, Byval size As _Unsigned Long)
    End Declare
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' GLOBAL VARIABLES
    '-------------------------------------------------------------------------------------------------------------------
    Dim __MIDI_Player As __MIDI_PlayerType
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------

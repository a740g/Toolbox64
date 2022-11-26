'---------------------------------------------------------------------------------------------------------
' MIDI Player library using Win32 WinMM MIDI streaming API
' Copyright (c) 2022 Samuel Gomes
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'./Common.bi'
'---------------------------------------------------------------------------------------------------------

$If LIBNATIVEMIDI_BI = UNDEFINED Then
    $Let LIBNATIVEMIDI_BI = TRUE
    '-----------------------------------------------------------------------------------------------------
    ' EXTERNAL LIBRARIES
    '-----------------------------------------------------------------------------------------------------
    Declare Library "./LibNativeMIDI"
        ' <summary>
        ' This loads and starts playing a MIDI file.
        ' Specifying a new file while another one is playing will stop the previous file and then start playing the new one.
        ' The playback can be looped. The playback can be seemingly looped forever by specifying an absudly large value for 'loops'.
        ' Passing null as the filename will shutdown MIDI playback and free allocated resources.
        ' Always null terminate filename since these routines are written in C!
        ' </summary>
        ' <param name="fileName">An SMF path file name</param>
        ' <param name="loops">The number of times the playback should loop</param>
        ' <returns>True if the call succeeded. False otherwise</returns>
        Function MIDI_Play%% (fileName As String, Byval loops As Long)

        ' <summary>
        ' Checks if a MIDI song is playing
        ' </summary>
        ' <returns>True if playing. False otherwise</returns>
        Function MIDI_IsPlaying%%

        ' <summary>
        ' Pauses MIDI playback
        ' </summary>
        Sub MIDI_Pause

        ' <summary>
        ' Resumes MIDI playback
        ' </summary>
        Sub MIDI_Resume

        ' <summary>
        ' Set the MIDI playback volume
        ' </summary>
        ' <param name="volume">A floating point value (0.0 to 1.0)</param>
        Sub MIDI_SetVolume (ByVal volume As Single)

        ' <summary>
        ' Returns the current MIDI volume
        ' </summary>
        ' <returns>A floating point value (0.0 to 1.0)</returns>
        Function MIDI_GetVolume!

        ' <summary>
        ' This is a quick and dirty function to play simple single sounds asynchronously and can be great for playing looping music.
        ' This can playback WAV files that use compressed audio using Windows ACM codecs!
        ' Specifying a new file while another one is playing will stop the previous file and then start playing the new one.
        ' Specifying an empty string will stop all sound playback. The playback can be looped.
        ' Always null terminate filename since these routines are written in C!
        ' </summary>
        ' <param name="fileName">A WAV path file name</param>
        ' <param name="looping">If this is true the sound loops forever until it is stopped</param>
        ' <returns>True if the call succeeded. False otherwise</returns>
        Function Sound_Play%% (fileName As String, Byval looping As Byte)
    End Declare
    '-----------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------


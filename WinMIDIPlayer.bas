'-----------------------------------------------------------------------------------------------------------------------
' MIDI Player library using Win32 WinMM MIDI streaming API
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF WINMIDIPLAYER_BAS = UNDEFINED THEN
    $LET WINMIDIPLAYER_BAS = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' HEADER FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'WinMIDIPlayer.bi'
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
    FUNCTION MIDI_PlayFromMemory%% (buffer AS STRING)
        MIDI_PlayFromMemory = __MIDI_PlayFromMemory(buffer, LEN(buffer))
    END FUNCTION

    SUB MIDI_PlayFromMemory (buffer AS STRING)
        DIM sink AS _BYTE: sink = __MIDI_PlayFromMemory(buffer, LEN(buffer))
    END SUB

    FUNCTION MIDI_PlayFromFile%% (fileName AS STRING)
        MIDI_PlayFromFile = MIDI_PlayFromMemory(LoadFile(fileName))
    END FUNCTION

    SUB MIDI_PlayFromFile (fileName AS STRING)
        MIDI_PlayFromMemory LoadFile(fileName)
    END SUB

    FUNCTION Sound_PlayFromFile%% (fileName AS STRING, looping AS _BYTE)
        Sound_PlayFromFile = __Sound_PlayFromFile(fileName + CHR$(NULL), looping)
    END FUNCTION

    SUB Sound_PlayFromFile (fileName AS STRING, looping AS _BYTE)
        DIM sink AS _BYTE: sink = __Sound_PlayFromFile(fileName + CHR$(NULL), looping)
    END SUB

    SUB Sound_PlayFromMemory (buffer AS STRING, looping AS _BYTE)
        DIM sink AS _BYTE: sink = Sound_PlayFromMemory(buffer, looping)
    END SUB
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' MODULE FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'MemFile.bas'
    '$INCLUDE:'FileOps.bas'
    '-------------------------------------------------------------------------------------------------------------------
$END IF
'-----------------------------------------------------------------------------------------------------------------------

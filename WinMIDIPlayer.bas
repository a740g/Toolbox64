'-----------------------------------------------------------------------------------------------------------------------
' MIDI Player library using Win32 WinMM MIDI streaming API
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF WINMIDIPLAYER_BAS = UNDEFINED THEN
    $LET WINMIDIPLAYER_BAS = TRUE

    '$INCLUDE:'WinMIDIPlayer.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    'Sound_Beep 750, 300

    'Sound_PlayFromFile ENVIRON$("SYSTEMROOT") + "\Media\Ring05.wav", TRUE

    'END
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
        Sound_PlayFromFile = Sound_PlayFromMemory(LoadFile(fileName), looping)
    END FUNCTION


    SUB Sound_PlayFromFile (fileName AS STRING, looping AS _BYTE)
        DIM sink AS _BYTE: sink = Sound_PlayFromMemory(LoadFile(fileName), looping)
    END SUB


    SUB Sound_PlayFromMemory (buffer AS STRING, looping AS _BYTE)
        DIM sink AS _BYTE: sink = Sound_PlayFromMemory(buffer, looping)
    END SUB

    '$INCLUDE:'MemFile.bas'
    '$INCLUDE:'FileOps.bas'

$END IF

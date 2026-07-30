'-----------------------------------------------------------------------------------------------------------------------
' OPL3 emulation for QB64-PE using Opal
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Core/Common.bi'

DECLARE LIBRARY "OPL3X"
    FUNCTION OPL3X_CreateEx~%& (BYVAL chipCount AS _UNSIGNED LONG, BYVAL sampleRate AS _UNSIGNED LONG)
    SUB OPL3X_Destroy (BYVAL emulator AS _UNSIGNED _OFFSET)
    SUB OPL3X_Reset (BYVAL emulator AS _UNSIGNED _OFFSET)
    FUNCTION OPL3X_GetSampleRate~& (BYVAL emulator AS _UNSIGNED _OFFSET)
    FUNCTION OPL3X_GetChipCount~& (BYVAL emulator AS _UNSIGNED _OFFSET)
    FUNCTION OPL3X_WriteChipRegister%% (BYVAL emulator AS _UNSIGNED _OFFSET, BYVAL chipIndex AS _UNSIGNED LONG, BYVAL address AS _UNSIGNED INTEGER, BYVAL value AS _UNSIGNED _BYTE)
    FUNCTION OPL3X_WriteRegister%% (BYVAL emulator AS _UNSIGNED _OFFSET, BYVAL address AS _UNSIGNED INTEGER, BYVAL value AS _UNSIGNED _BYTE)
    SUB OPL3X_WriteChipRegister (BYVAL emulator AS _UNSIGNED _OFFSET, BYVAL chipIndex AS _UNSIGNED LONG, BYVAL address AS _UNSIGNED INTEGER, BYVAL value AS _UNSIGNED _BYTE)
    SUB OPL3X_WriteRegister (BYVAL emulator AS _UNSIGNED _OFFSET, BYVAL address AS _UNSIGNED INTEGER, BYVAL value AS _UNSIGNED _BYTE)
    SUB OPL3X_GetFrame (BYVAL emulator AS _UNSIGNED _OFFSET, leftSample AS SINGLE, rightSample AS SINGLE)
    SUB OPL3X_GetFrames (BYVAL emulator AS _UNSIGNED _OFFSET, buffer AS SINGLE, BYVAL frames AS _UNSIGNED LONG)
    SUB OPL3X_MixFrames (BYVAL emulator AS _UNSIGNED _OFFSET, buffer AS SINGLE, BYVAL frames AS _UNSIGNED LONG)
END DECLARE

FUNCTION OPL3X_Create~%& (chipCount AS _UNSIGNED LONG)
    OPL3X_Create = OPL3X_CreateEx(chipCount, _SNDRATE)
END FUNCTION

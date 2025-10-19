'-----------------------------------------------------------------------------------------------------------------------
' Standard Input/Output functions
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

DECLARE LIBRARY "StandardIO"
    FUNCTION StandardIO_ReadChar& ALIAS "std::getchar"
    SUB StandardIO_WriteChar ALIAS "std::putchar" (BYVAL ch AS LONG)
END DECLARE

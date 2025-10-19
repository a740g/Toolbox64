'-----------------------------------------------------------------------------------------------------------------------
' 2D Vector (integer) routines
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

TYPE Vector2i
    x AS LONG
    y AS LONG
END TYPE

DECLARE LIBRARY "Vector2i"
    SUB Vector2f_Reset (dst AS Vector2i)
END DECLARE
'-----------------------------------------------------------------------------------------------------------------------
' 2D Vector routines
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

TYPE Vector2D
    x AS SINGLE
    y AS SINGLE
END TYPE

DECLARE LIBRARY "Vector2D"
    SUB Vector2D_Reset (dst AS Vector2D)
    SUB Vector2D_Initialize (BYVAL x AS SINGLE, BYVAL y AS SINGLE, dst AS Vector2D)
    SUB Vector2D_Assign (src AS Vector2D, dst AS Vector2D)
    FUNCTION Vector2D_IsNull%% (src AS Vector2D)
    SUB Vector2D_Add (src1 AS Vector2D, src2 AS Vector2D, dst AS Vector2D)
    SUB Vector2D_AddValue (src AS Vector2D, BYVAL value AS SINGLE, dst AS Vector2D)
    SUB Vector2D_AddXY (src AS Vector2D, BYVAL x AS SINGLE, BYVAL y AS SINGLE, dst AS Vector2D)
    SUB Vector2D_Subtract (src1 AS Vector2D, src2 AS Vector2D, dst AS Vector2D)
    SUB Vector2D_SubtractValue (src AS Vector2D, BYVAL value AS SINGLE, dst AS Vector2D)
    SUB Vector2D_SubtractXY (src AS Vector2D, BYVAL x AS SINGLE, BYVAL y AS SINGLE, dst AS Vector2D)
    SUB Vector2D_Multiply (src1 AS Vector2D, src2 AS Vector2D, dst AS Vector2D)
    SUB Vector2D_MultiplyValue (src AS Vector2D, BYVAL value AS SINGLE, dst AS Vector2D)
    SUB Vector2D_MultiplyXY (src AS Vector2D, BYVAL x AS SINGLE, BYVAL y AS SINGLE, dst AS Vector2D)
    SUB Vector2D_Divide (src1 AS Vector2D, src2 AS Vector2D, dst AS Vector2D)
    SUB Vector2D_DivideValue (src AS Vector2D, BYVAL value AS SINGLE, dst AS Vector2D)
    SUB Vector2D_DivideXY (src AS Vector2D, BYVAL x AS SINGLE, BYVAL y AS SINGLE, dst AS Vector2D)
    SUB Vector2D_Negate (src AS Vector2D, dst AS Vector2D)
    FUNCTION Vector2D_GetLengthSquared! (src AS Vector2D)
    FUNCTION Vector2D_GetLength! (src AS Vector2D)
    FUNCTION Vector2D_GetDistanceSquared! (src1 AS Vector2D, src2 AS Vector2D)
    FUNCTION Vector2D_GetDistance! (src1 AS Vector2D, src2 AS Vector2D)
    SUB Vector2D_GetSizeVector (src1 AS Vector2D, src2 AS Vector2D, dst AS Vector2D)
    FUNCTION Vector2D_GetArea! (src AS Vector2D)
    FUNCTION Vector2D_GetPerimeter! (src AS Vector2D)
    FUNCTION Vector2D_GetDotProduct! (src1 AS Vector2D, src2 AS Vector2D)
    FUNCTION Vector2D_GetAngle! (src1 AS Vector2D, src2 AS Vector2D)
    FUNCTION Vector2D_GetLineAngle! (src1 AS Vector2D, src2 AS Vector2D)
    SUB Vector2D_Normalize (src AS Vector2D, dst AS Vector2D)
    SUB Vector2D_Lerp (src1 AS Vector2D, src2 AS Vector2D, BYVAL t AS SINGLE, dst AS Vector2D)
    SUB Vector2D_Reflect (src AS Vector2D, normal AS Vector2D, dst AS Vector2D)
    SUB Vector2D_Rotate (src AS Vector2D, BYVAL angle AS SINGLE, dst AS Vector2D)
    SUB Vector2D_MoveTowards (src AS Vector2D, target AS Vector2D, BYVAL maxDistance AS SINGLE, dst AS Vector2D)
    SUB Vector2D_Invert (src AS Vector2D, dst AS Vector2D)
    SUB Vector2D_Reciprocal (src AS Vector2D, dst AS Vector2D)
    SUB Vector2D_Clamp (src AS Vector2D, min AS Vector2D, max AS Vector2D, dst AS Vector2D)
    SUB Vector2D_ClampValue (src AS Vector2D, BYVAL min AS SINGLE, BYVAL max AS SINGLE, dst AS Vector2D)
END DECLARE

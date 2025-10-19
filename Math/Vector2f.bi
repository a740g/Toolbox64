'-----------------------------------------------------------------------------------------------------------------------
' 2D Vector (floating point) routines
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

TYPE Vector2f
    x AS SINGLE
    y AS SINGLE
END TYPE

DECLARE LIBRARY "Vector2f"
    SUB Vector2f_Reset (dst AS Vector2f)
    SUB Vector2f_Initialize (BYVAL x AS SINGLE, BYVAL y AS SINGLE, dst AS Vector2f)
    SUB Vector2f_Assign (src AS Vector2f, dst AS Vector2f)
    FUNCTION Vector2f_IsNull%% (src AS Vector2f)
    SUB Vector2f_Add (src1 AS Vector2f, src2 AS Vector2f, dst AS Vector2f)
    SUB Vector2f_AddValue (src AS Vector2f, BYVAL value AS SINGLE, dst AS Vector2f)
    SUB Vector2f_AddXY (src AS Vector2f, BYVAL x AS SINGLE, BYVAL y AS SINGLE, dst AS Vector2f)
    SUB Vector2f_Subtract (src1 AS Vector2f, src2 AS Vector2f, dst AS Vector2f)
    SUB Vector2f_SubtractValue (src AS Vector2f, BYVAL value AS SINGLE, dst AS Vector2f)
    SUB Vector2f_SubtractXY (src AS Vector2f, BYVAL x AS SINGLE, BYVAL y AS SINGLE, dst AS Vector2f)
    SUB Vector2f_Multiply (src1 AS Vector2f, src2 AS Vector2f, dst AS Vector2f)
    SUB Vector2f_MultiplyValue (src AS Vector2f, BYVAL value AS SINGLE, dst AS Vector2f)
    SUB Vector2f_MultiplyXY (src AS Vector2f, BYVAL x AS SINGLE, BYVAL y AS SINGLE, dst AS Vector2f)
    SUB Vector2f_Divide (src1 AS Vector2f, src2 AS Vector2f, dst AS Vector2f)
    SUB Vector2f_DivideValue (src AS Vector2f, BYVAL value AS SINGLE, dst AS Vector2f)
    SUB Vector2f_DivideXY (src AS Vector2f, BYVAL x AS SINGLE, BYVAL y AS SINGLE, dst AS Vector2f)
    SUB Vector2f_Negate (src AS Vector2f, dst AS Vector2f)
    FUNCTION Vector2f_GetLengthSquared! (src AS Vector2f)
    FUNCTION Vector2f_GetLength! (src AS Vector2f)
    FUNCTION Vector2f_GetDistanceSquared! (src1 AS Vector2f, src2 AS Vector2f)
    FUNCTION Vector2f_GetDistance! (src1 AS Vector2f, src2 AS Vector2f)
    SUB Vector2f_GetSizeVector (src1 AS Vector2f, src2 AS Vector2f, dst AS Vector2f)
    FUNCTION Vector2f_GetArea! (src AS Vector2f)
    FUNCTION Vector2f_GetPerimeter! (src AS Vector2f)
    FUNCTION Vector2f_GetDotProduct! (src1 AS Vector2f, src2 AS Vector2f)
    FUNCTION Vector2f_GetCrossProduct! (src1 AS Vector2f, src2 AS Vector2f)
    FUNCTION Vector2f_GetAngle! (src1 AS Vector2f, src2 AS Vector2f)
    FUNCTION Vector2f_GetLineAngle! (src1 AS Vector2f, src2 AS Vector2f)
    SUB Vector2f_Normalize (src AS Vector2f, dst AS Vector2f)
    SUB Vector2f_Lerp (src1 AS Vector2f, src2 AS Vector2f, BYVAL t AS SINGLE, dst AS Vector2f)
    SUB Vector2f_Reflect (src AS Vector2f, normal AS Vector2f, dst AS Vector2f)
    SUB Vector2f_Rotate (src AS Vector2f, BYVAL angle AS SINGLE, dst AS Vector2f)
    SUB Vector2f_MoveTowards (src AS Vector2f, target AS Vector2f, BYVAL maxDistance AS SINGLE, dst AS Vector2f)
    SUB Vector2f_TurnLeft (src AS Vector2f, dst AS Vector2f)
    SUB Vector2f_TurnRight (src AS Vector2f, dst AS Vector2f)
    SUB Vector2f_FlipVertical (src AS Vector2f, dst AS Vector2f)
    SUB Vector2f_FlipHorizontal (src AS Vector2f, dst AS Vector2f)
    SUB Vector2f_Reciprocal (src AS Vector2f, dst AS Vector2f)
    SUB Vector2f_Clamp (src AS Vector2f, min AS Vector2f, max AS Vector2f, dst AS Vector2f)
    SUB Vector2f_ClampValue (src AS Vector2f, BYVAL min AS SINGLE, BYVAL max AS SINGLE, dst AS Vector2f)
END DECLARE

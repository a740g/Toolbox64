' Written by Omer B. Hijazi (github: omerhijazi404)
' You may do whatever you want with it with only one exception: keep this comment and the one above it intact

Option _Explicit
Option Base 0

Dim Shared FPS As Integer
FPS = 30

' A coordinate containing an X and Y
Type Coordinate
    X As Integer
    Y As Integer
End Type

' The Sprites of an object
Type Sprite
    Image As Long
    Color As Long
    Center As Coordinate
    A As Coordinate
    B As Coordinate
    C As Coordinate
    D As Coordinate
    E As Coordinate
    Points As Integer
End Type

' The objects to be used in the game
Type Object
    Name As String
    Scale As Coordinate
    Sprite As Sprite
    Empty As Integer
End Type

ReDim Shared Objects(0) As Object

Dim Shared True As Integer
Dim Shared False As Integer
True = -1
False = 0

Dim Shared CollisionsEnabled As Integer
CollisionsEnabled = True

Dim Shared Background As Long

Background = _NewImage(800, 600, 32)
Screen Background

EmptyObjects



Do
    Cls
    If CollisionsEnabled Then CheckCollisions
    DisplayObjects
    _Limit FPS
Loop

' SUBS AND FUNCTIONS

Function OnCollide (object1 As Object, object2 As Object)
    Print "Collision!"
End Function

Sub DisplayObjects
    Cls
    Dim i%
    For i% = 0 To UBound(objects)
        If Objects(i%).Empty Then GoTo nexti
        If Objects(i%).Sprite.Image = 0 Then
            Select Case Objects(i%).Sprite.Points
                Case 1:
                    PSet (Objects(i%).Sprite.A.X, Objects(i%).Sprite.A.Y), Objects(i%).Sprite.Color
                Case 2:
                    Line (Objects(i%).Sprite.A.X, Objects(i%).Sprite.A.Y)-(Objects(i%).Sprite.B.X, Objects(i%).Sprite.B.Y), Objects(i%).Sprite.Color
                Case 3:
                    Line (Objects(i%).Sprite.A.X, Objects(i%).Sprite.A.Y)-(Objects(i%).Sprite.B.X, Objects(i%).Sprite.B.Y), Objects(i%).Sprite.Color
                    Line (Objects(i%).Sprite.B.X, Objects(i%).Sprite.B.Y)-(Objects(i%).Sprite.C.X, Objects(i%).Sprite.C.Y), Objects(i%).Sprite.Color
                    Line (Objects(i%).Sprite.C.X, Objects(i%).Sprite.C.Y)-(Objects(i%).Sprite.A.X, Objects(i%).Sprite.A.Y), Objects(i%).Sprite.Color
            End Select
        Else
            _PutImage (Objects(i%).Sprite.Center.X, Objects(i%).Sprite.Center.Y), Objects(i%).Sprite.Image
        End If
        nexti:
    Next i%
End Sub

Sub EmptyObjects
    Dim i As Integer
    For i = 0 To UBound(objects)
    Next i
End Sub

Sub EmptyObject (ObjectNumber As Integer)
    Dim FreeObject As Object
    FreeObject.Empty = True
    Objects(ObjectNumber) = FreeObject
End Sub

Sub CheckCollisions
End Sub

Function AddObject% (obj As Object)
    ReDim _Preserve Objects(UBound(Objects) + 1) As Object
    Objects(UBound(Objects)) = obj
End Function

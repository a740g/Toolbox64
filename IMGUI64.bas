'---------------------------------------------------------------------------------------------------------
' QB64-PE Immediate mode GUI Library
'
' This is very loosely based on Terry Ritchie's GLINPUT & RQBL
' The library has an input manager, tabbed focus and implements text box and push button widgets (so far)
' This is an immediate mode UI. Which means all UI rendering is destructive
' The framebuffer needs to be redrawn every frame and nothing the widgets drawn over is preserved
' This was born because I needed a small, fast and intuitive GUI libary for games and graphic applications
' This is a work in progress
'
' Copyright (c) 2022 Samuel Gomes
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'./IMGUI64.bi'
'---------------------------------------------------------------------------------------------------------

$If IMGUI64_BAS = UNDEFINED Then
    $Let IMGUI64_BAS = TRUE

    '-----------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-----------------------------------------------------------------------------------------------------

    ' Calculates the bounding rectangle for a object given its position & size
    Sub RectangleCreate (p As Vector2DType, s As Vector2DType, r As RectangleType)
        r.a.x = p.x
        r.a.y = p.y
        r.b.x = p.x + s.x - 1
        r.b.y = p.y + s.y - 1
    End Sub


    ' Does big contain small?
    Function RectangleContainsRectangle%% (big As RectangleType, small As RectangleType)
        RectangleContainsRectangle = PointCollidesWithRectangle(small.a, big) And PointCollidesWithRectangle(small.b, big)
    End Function


    ' Point & box collision test
    Function PointCollidesWithRectangle%% (p As Vector2DType, r As RectangleType)
        PointCollidesWithRectangle = Not (p.x < r.a.x Or p.x > r.b.x Or p.y < r.a.y Or p.y > r.b.y)
    End Function


    ' Draws a basic 3D box
    ' This can be improved ... a lot XD
    ' Also all colors are hardcoded
    Sub WidgetDrawBox3D (r As RectangleType, depressed As Byte)
        If depressed Then ' sunken
            Line (r.a.x, r.a.y)-(r.b.x - 1, r.a.y), DimGray
            Line (r.a.x, r.a.y)-(r.a.x, r.b.y - 1), DimGray
            Line (r.a.x, r.b.y)-(r.b.x, r.b.y), LightGray
            Line (r.b.x, r.a.y)-(r.b.x, r.b.y - 1), LightGray
        Else ' raised
            Line (r.a.x, r.a.y)-(r.b.x - 1, r.a.y), LightGray
            Line (r.a.x, r.a.y)-(r.a.x, r.b.y - 1), LightGray
            Line (r.a.x, r.b.y)-(r.b.x, r.b.y), DimGray
            Line (r.b.x, r.a.y)-(r.b.x, r.b.y - 1), DimGray
        End If

        Line (r.a.x + 1, r.a.y + 1)-(r.b.x - 1, r.b.y - 1), Gray, BF
    End Sub


    ' This routine ties the whole update system and makes everything go
    Sub WidgetUpdate
        Static blinkTick As Integer64 ' stores the last blink tick (oooh!)
        Shared Widget() As WidgetType
        Shared WidgetManager As WidgetManagerType
        Shared InputManager As InputManagerType
        Dim h As Long, r As RectangleType, currentTick As Integer64

        InputManagerUpdate ' We will gather input even if there are no widgets

        If UBound(Widget) = NULL Then Exit Sub ' Exit if there is nothing to do

        ' Blinky stuff
        currentTick = GetTicks
        If currentTick > blinkTick + WIDGET_BLINK_INTERVAL Then
            blinkTick = currentTick
            WidgetManager.focusBlink = Not WidgetManager.focusBlink
        End If

        ' Manage widget focus stuff
        If WidgetManager.current = NULL Then WidgetManager.current = 1 ' if this is first time set current widget to 1

        ' Shift focus if it was requested
        If WidgetManager.forced <> NULL Then ' being forced to a widget
            If WidgetManager.forced = -1 Then ' yes, to the next one?
                h = WidgetManager.current ' set scanner to current widget
                Do ' start scanning
                    h = h + 1 ' move scanner to next handle number
                    If h > UBound(Widget) Then h = 1 ' return to start of widget array if limit reached
                    If Widget(h).inUse And Widget(h).visible And Not Widget(h).disabled Then WidgetManager.current = h ' set current widget if in use
                Loop Until WidgetManager.current = h ' leave scanner when a widget in use is found
                WidgetManager.forced = NULL ' reset force indicator
            Else ' yes, to a specific input field
                If Widget(WidgetManager.forced).inUse And Widget(WidgetManager.forced).visible And Not Widget(WidgetManager.forced).disabled Then
                    WidgetManager.current = WidgetManager.forced ' set the current widget
                End If
                WidgetManager.forced = NULL ' reset force indicator
            End If
        End If

        ' Check for user input requesting focus change
        If InputManager.keyCode = KEY_TAB Then
            WidgetManager.forced = -1 ' Move to the next widget
            InputManager.keyCode = NULL ' consume the key
        End If

        ' Check if the user is trying to click on something to change focus
        For h = 1 To UBound(Widget)
            If Widget(h).inUse And Widget(h).visible And Not Widget(h).disabled And h <> WidgetManager.current Then

                ' Find the bounding box
                RectangleCreate Widget(h).position, Widget(h).size, r

                If InputManager.mouseLeftClicked Then
                    If RectangleContainsRectangle(r, InputManager.mouseLeftButtonClickedRectangle) Then
                        WidgetManager.forced = h ' Move to the specific widget
                    End If
                End If

                If InputManager.mouseRightClicked Then
                    If RectangleContainsRectangle(r, InputManager.mouseRightButtonClickedRectangle) Then
                        WidgetManager.forced = h ' Move to the specific widget
                    End If
                End If
            End If
        Next


        ' Run update for the widget that has focus
        If Widget(WidgetManager.current).inUse And Widget(WidgetManager.current).visible And Not Widget(WidgetManager.current).disabled Then
            Select Case Widget(WidgetManager.current).class
                Case WIDGET_PUSH_BUTTON
                    __PushButtonUpdate
                Case WIDGET_TEXT_BOX
                    __TextBoxUpdate
            End Select
        End If

        ' Now draw all the widget to the framebuffer
        For h = 1 To UBound(Widget)
            If Widget(h).inUse And Widget(h).visible Then
                Select Case Widget(h).class
                    Case WIDGET_PUSH_BUTTON
                        __PushButtonDraw h
                    Case WIDGET_TEXT_BOX
                        __TextBoxDraw h
                End Select
            End If
        Next
    End Sub


    Sub InputManagerUpdate
        Shared InputManager As InputManagerType
        Static As Byte mouseLeftButtonDown, mouseRightButtonDown ' keeps track if the mouse buttons were held down

        ' Collect mouse input
        Do While MouseInput
            InputManager.mousePosition.x = MouseX
            InputManager.mousePosition.y = MouseY

            InputManager.mouseLeftButton = MouseButton(1)
            InputManager.mouseRightButton = MouseButton(2)

            ' Check if the left button were previously held down and update the up position if released
            If Not InputManager.mouseLeftButton And mouseLeftButtonDown Then
                mouseLeftButtonDown = FALSE
                InputManager.mouseLeftButtonClickedRectangle.b = InputManager.mousePosition
                InputManager.mouseLeftClicked = TRUE
            End If

            ' Check if the button were previously held down and update the up position if released
            If Not InputManager.mouseRightButton And mouseRightButtonDown Then
                mouseRightButtonDown = FALSE
                InputManager.mouseRightButtonClickedRectangle.b = InputManager.mousePosition
                InputManager.mouseRightClicked = TRUE
            End If

            ' Check if the mouse button was pressed and update the down position
            If InputManager.mouseLeftButton And Not mouseLeftButtonDown Then
                mouseLeftButtonDown = TRUE
                InputManager.mouseLeftButtonClickedRectangle.a = InputManager.mousePosition
                InputManager.mouseLeftClicked = FALSE
            End If

            ' Check if the mouse button was pressed and update the down position
            If InputManager.mouseRightButton And Not mouseRightButtonDown Then
                mouseRightButtonDown = TRUE
                InputManager.mouseRightButtonClickedRectangle.a = InputManager.mousePosition
                InputManager.mouseRightClicked = FALSE
            End If
        Loop

        ' Get keyboard input from the keyboard buffer
        InputManager.keyCode = KeyHit
    End Sub


    ' This gets the current keyboard input
    Function InputManagerKey&
        Shared InputManager As InputManagerType

        InputManagerKey = InputManager.keyCode
    End Function


    ' Get the mouse X position
    Function InputManagerMouseX&
        Shared InputManager As InputManagerType

        InputManagerMouseX = InputManager.mousePosition.x
    End Function


    ' Get the mouse Y position
    Function InputManagerMouseY&
        Shared InputManager As InputManagerType

        InputManagerMouseY = InputManager.mousePosition.y
    End Function


    ' Is the left mouse button down?
    Function InputManagerMouseLeftButton%%
        Shared InputManager As InputManagerType

        InputManagerMouseLeftButton = InputManager.mouseLeftButton
    End Function


    ' Is the right mouse button down?
    Function InputManagerMouseRightButton%%
        Shared InputManager As InputManagerType

        InputManagerMouseRightButton = InputManager.mouseRightButton
    End Function


    ' Returns the handle number of the widget that has focus
    ' The function will return 0 if there are no active widgets
    Function WidgetCurrent&
        Shared Widget() As WidgetType
        Shared WidgetManager As WidgetManagerType

        If UBound(Widget) = NULL Then Exit Function

        WidgetCurrent = WidgetManager.current
    End Function


    ' This set the focus on the widget handle that is passed
    ' The focus changes on the next update
    ' -1 = move to next widget
    ' >0 = move to a specific widget
    Sub WidgetCurrent (handle As Long)
        Shared Widget() As WidgetType
        Shared WidgetManager As WidgetManagerType

        If UBound(Widget) = NULL Then Exit Sub ' Leave if nothing is active

        If handle < -1 Or handle = NULL Or handle > UBound(Widget) Then ' is handle valid?
            Error ERROR_INVALID_HANDLE
        End If

        WidgetManager.forced = handle ' inform WidgetUpdate to change the focus
    End Sub


    ' Closes a specific widget
    Sub WidgetFree (handle As Long)
        Shared Widget() As WidgetType
        Shared WidgetManager As WidgetManagerType

        If UBound(Widget) = NULL Then Exit Sub ' leave if nothing is active

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then ' is handle valid?
            Error ERROR_INVALID_HANDLE
        End If

        ' We will not bother resizing the widget array so that subsequent allocations will be faster
        ' So just set the 'inUse' member to false
        Widget(handle).inUse = FALSE
        If handle = WidgetManager.current Then WidgetManager.forced = -1 ' Set focus on the next widget if it is current
    End Sub


    ' Closes all widgets
    Sub WidgetFreeAll
        Shared Widget() As WidgetType
        Shared WidgetManager As WidgetManagerType

        If UBound(Widget) = NULL Then Exit Sub ' leave if nothing is active

        ReDim Widget(NULL To NULL) As WidgetType ' reset the widget array
        WidgetManager.current = NULL
        WidgetManager.forced = NULL
    End Sub


    ' Retrieves the text from a specific widget
    Function WidgetText$ (handle As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Function

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        WidgetText = Widget(handle).text
    End Function


    ' Sets the text of a specific widget
    Sub WidgetText (handle As Long, text As String)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Sub

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        Widget(handle).text = text
        Widget(handle).changed = TRUE
    End Sub


    ' Reports true if the ENTER key has been pressed on the input box
    Function TextBoxEntered%% (handle As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Function ' leave if nothing is active

        If handle < 1 Or handle > UBound(Widget) Or Widget(handle).class <> WIDGET_TEXT_BOX Then ' is handle valid?
            Error ERROR_INVALID_HANDLE
        End If

        TextBoxEntered = Widget(handle).txt.entered
    End Function


    ' Returns true if the text field of a text box has changed
    Function TextBoxChanged%% (handle As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Function ' leave if nothing is active

        If handle < 1 Or handle > UBound(Widget) Or Widget(handle).class <> WIDGET_TEXT_BOX Then ' is handle valid?
            Error ERROR_INVALID_HANDLE
        End If

        TextBoxChanged = Widget(handle).changed
    End Function


    ' Sets up a widget and returns a handle value that points to that widget
    Function __WidgetNew& (class As Long)
        Shared Widget() As WidgetType
        Shared WidgetManager As WidgetManagerType

        If class < NULL Or class > WIDGET_CLASS_COUNT Then
            Error ERROR_FEATURE_UNAVAILABLE
        End If

        If UBound(Widget) = NULL Then ' Reallocate the widget array if this the first time
            ReDim Widget(1 To 1) As WidgetType
            Widget(1).inUse = FALSE
        End If

        Dim h As Long ' the new handle number

        Do ' find available handle
            h = h + 1
        Loop Until Not Widget(h).inUse Or h = UBound(Widget)

        If Widget(h).inUse Then ' last one in use?
            h = h + 1 ' use next handle
            ReDim Preserve Widget(1 To h) As WidgetType ' increase array size
        End If

        Dim temp As WidgetType
        Widget(h) = temp ' ensure everything is wiped

        Widget(h).inUse = TRUE
        Widget(h).class = class ' set the class

        __WidgetNew = h ' return the handle
    End Function


    ' Duplicates a widget from a designated handle
    ' Returns handle value greater than 0 indicating the new widgets handle
    Function WidgetCopy& (handle As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Function

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        Dim nh As Long
        nh = __WidgetNew(NULL) ' creat a new widget of class 0. Whatever that is, is not important
        Widget(nh) = Widget(handle) ' copy all properties

        WidgetCopy = nh ' return new handle
    End Function


    ' Creates a new button
    Function PushButtonNew& (text As String, x As Long, y As Long, w As Unsigned Long, h As Unsigned Long, toggleButton As Byte)
        Shared Widget() As WidgetType
        Dim b As Long

        b = __WidgetNew(WIDGET_PUSH_BUTTON)

        Widget(b).text = text
        Widget(b).position.x = x
        Widget(b).position.y = y
        Widget(b).size.x = w
        Widget(b).size.y = h
        Widget(b).visible = TRUE

        ' Set class specific stuff
        Widget(b).flags = toggleButton

        PushButtonNew = b
    End Function


    ' Create a new input box
    Function TextBoxNew& (text As String, x As Long, y As Long, w As Unsigned Long, h As Unsigned Long, flags As Unsigned Long)
        Shared Widget() As WidgetType

        Dim t As Long ' the new handle number

        t = __WidgetNew(WIDGET_TEXT_BOX)

        Widget(t).text = text
        Widget(t).position.x = x
        Widget(t).position.y = y
        Widget(t).size.x = w
        Widget(t).size.y = h
        Widget(t).visible = TRUE

        ' Set class specific stuff
        Widget(t).flags = flags ' store the flags
        Widget(t).txt.textPosition = 1 ' set the cursor at the beginning of the input line
        Widget(t).txt.boxPosition = 1
        Widget(t).txt.boxTextLength = (w - PrintWidth("W") * 2) \ PrintWidth("W") ' calculate the number of character we can show at a time
        Widget(t).txt.boxStartCharacter = 1
        Widget(t).txt.insertMode = TRUE ' initial insert mode to insert

        TextBoxNew = t
    End Function


    ' Hides / shows a widget on screen
    Sub WidgetVisible (handle As Long, visible As Byte)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Sub

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        Widget(handle).visible = visible
    End Sub


    ' Returns if a widget is hidden or shown
    Function WidgetVisible%% (handle As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Function

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        WidgetVisible = Widget(handle).visible
    End Function


    ' Sets all active widget to visible or invisible
    Sub WidgetVisibleAll (visible As Byte)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Sub ' leave if nothing is active

        Dim h As Long

        For h = 1 To UBound(Widget)
            If Widget(h).inUse Then Widget(h).visible = visible
        Next
    End Sub


    ' Hides / shows a widget on screen
    Sub WidgetDisabled (handle As Long, disabled As Byte)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Sub

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        Widget(handle).disabled = disabled
    End Sub


    ' Returns if a widget is hidden or shown
    Function WidgetDisabled%% (handle As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Function

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        WidgetDisabled = Widget(handle).disabled
    End Function


    Sub WidgetPositionX (handle As Long, x As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Sub

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        Widget(handle).position.x = x
    End Sub


    Function WidgetPositionX& (handle As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Function

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        WidgetPositionX = Widget(handle).position.x
    End Function


    Sub WidgetPositionY (handle As Long, y As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Sub

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        Widget(handle).position.y = y
    End Sub


    Function WidgetPositionY& (handle As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Function

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        WidgetPositionY = Widget(handle).position.y
    End Function


    Sub WidgetSizeX (handle As Long, x As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Sub

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        Widget(handle).size.x = x
    End Sub


    Function WidgetSizeX& (handle As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Function

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        WidgetSizeX = Widget(handle).size.x
    End Function


    Sub WidgetSizeY (handle As Long, y As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Sub

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        Widget(handle).size.y = y
    End Sub


    Function WidgetSizeY& (handle As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Function

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        WidgetSizeY = Widget(handle).size.y
    End Function


    Function WidgetClicked%% (handle As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Function

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Then
            Error ERROR_INVALID_HANDLE
        End If

        WidgetClicked = Widget(handle).clicked
    End Function


    Sub PushButtonDepressed (handle As Long, depressed As Byte)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Sub

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Or Widget(handle).class <> WIDGET_PUSH_BUTTON Then
            Error ERROR_INVALID_HANDLE
        End If

        Widget(handle).cmd.depressed = depressed
    End Sub


    Function PushButtonDepressed%% (handle As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Function

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Or Widget(handle).class <> WIDGET_PUSH_BUTTON Then
            Error ERROR_INVALID_HANDLE
        End If

        PushButtonDepressed = Widget(handle).cmd.depressed
    End Function


    ' Toggles the button specified between pressed/depressed
    Sub PushButtonToggleDepressed (handle As Long)
        Shared Widget() As WidgetType

        If UBound(Widget) = NULL Then Exit Sub

        If handle < 1 Or handle > UBound(Widget) Or Not Widget(handle).inUse Or Widget(handle).class <> WIDGET_PUSH_BUTTON Then
            Error ERROR_INVALID_HANDLE
        End If

        Widget(handle).cmd.depressed = Not Widget(handle).cmd.depressed
    End Sub


    ' This will update the status of a button (state & clicked etc.) based on user input
    ' The calling function must ensure that this is called only for visible, enabled and the correct widget with focus
    Sub __PushButtonUpdate
        Shared Widget() As WidgetType
        Shared WidgetManager As WidgetManagerType
        Shared InputManager As InputManagerType
        Dim r As RectangleType, clicked As Byte

        ' Find the bounding box
        RectangleCreate Widget(WidgetManager.current).position, Widget(WidgetManager.current).size, r

        If InputManager.mouseLeftClicked Then
            If RectangleContainsRectangle(r, InputManager.mouseLeftButtonClickedRectangle) Then
                clicked = TRUE
                InputManager.mouseLeftClicked = FALSE ' consume mouse click
            End If
        End If

        If InputManager.mouseRightClicked Then
            If RectangleContainsRectangle(r, InputManager.mouseRightButtonClickedRectangle) Then
                clicked = TRUE
                InputManager.mouseRightClicked = FALSE ' consume mouse click
            End If
        End If

        If InputManager.keyCode = KEY_ENTER Or InputManager.keyCode = KEY_SPACE_BAR Then
            clicked = TRUE
            InputManager.keyCode = NULL ' consume keystroke
        End If

        Widget(WidgetManager.current).clicked = clicked

        ' Toggle if this is a toggle button
        If clicked And Widget(WidgetManager.current).flags Then
            Widget(WidgetManager.current).cmd.depressed = Not Widget(WidgetManager.current).cmd.depressed
        End If
    End Sub


    ' This will update the state of text box based on user input
    ' The calling function must ensure that this is called only for visible, enabled and the correct widget with focus
    Sub __TextBoxUpdate
        Shared Widget() As WidgetType
        Shared WidgetManager As WidgetManagerType
        Shared InputManager As InputManagerType

        Widget(WidgetManager.current).changed = FALSE ' Set this to false
        Widget(WidgetManager.current).txt.entered = FALSE ' Set this to false too

        ' First process any pressed keys
        Select Case InputManager.keyCode ' which key was hit?
            Case KEY_INSERT
                Widget(WidgetManager.current).txt.insertMode = Not Widget(WidgetManager.current).txt.insertMode

                InputManager.keyCode = NULL ' consume the key

            Case KEY_RIGHT_ARROW
                Widget(WidgetManager.current).txt.textPosition = Widget(WidgetManager.current).txt.textPosition + 1 ' increment the cursor position
                If Widget(WidgetManager.current).txt.textPosition > Len(Widget(WidgetManager.current).text) + 1 Then ' will this take the cursor too far?
                    Widget(WidgetManager.current).txt.textPosition = Len(Widget(WidgetManager.current).text) + 1 ' yes, keep the cursor at the end of the line
                End If

                ' Box cursor movement
                Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.boxPosition + 1

                If Widget(WidgetManager.current).txt.boxPosition > Widget(WidgetManager.current).txt.textPosition Then
                    Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.textPosition
                End If

                If Widget(WidgetManager.current).txt.boxPosition > Widget(WidgetManager.current).txt.boxTextLength + 1 Then
                    Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.boxTextLength + 1

                    Widget(WidgetManager.current).txt.boxStartCharacter = 1 + Len(Widget(WidgetManager.current).text) - Widget(WidgetManager.current).txt.boxTextLength
                End If

                InputManager.keyCode = NULL ' consume the key

            Case KEY_LEFT_ARROW
                Widget(WidgetManager.current).txt.textPosition = Widget(WidgetManager.current).txt.textPosition - 1 ' decrement the cursor position
                If Widget(WidgetManager.current).txt.textPosition < 1 Then ' did cursor go beyone beginning of line?
                    Widget(WidgetManager.current).txt.textPosition = 1 ' yes, keep the cursor at the beginning of the line
                End If

                ' Box cursor movement
                Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.boxPosition - 1
                If Widget(WidgetManager.current).txt.boxPosition < 1 Then
                    Widget(WidgetManager.current).txt.boxPosition = 1
                    If Widget(WidgetManager.current).txt.boxStartCharacter > 1 Then
                        Widget(WidgetManager.current).txt.boxStartCharacter = Widget(WidgetManager.current).txt.boxStartCharacter - 1
                    End If
                End If

                InputManager.keyCode = NULL ' consume the key

            Case KEY_BACKSPACE
                If Widget(WidgetManager.current).txt.textPosition > 1 Then ' is the cursor at the beginning of the line?
                    Widget(WidgetManager.current).text = Left$(Widget(WidgetManager.current).text, Widget(WidgetManager.current).txt.textPosition - 2) + Right$(Widget(WidgetManager.current).text, Len(Widget(WidgetManager.current).text) - Widget(WidgetManager.current).txt.textPosition + 1) ' no, delete character
                    Widget(WidgetManager.current).txt.textPosition = Widget(WidgetManager.current).txt.textPosition - 1 ' decrement the cursor position
                End If

                ' Box cursor movement
                Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.boxPosition - 1
                If Widget(WidgetManager.current).txt.boxPosition < 1 Then
                    Widget(WidgetManager.current).txt.boxPosition = 1
                    If Widget(WidgetManager.current).txt.boxStartCharacter > 1 Then
                        Widget(WidgetManager.current).txt.boxStartCharacter = Widget(WidgetManager.current).txt.boxStartCharacter - 1
                    End If
                End If

                InputManager.keyCode = NULL ' consume the key
                Widget(WidgetManager.current).changed = TRUE ' something changed

            Case KEY_HOME
                Widget(WidgetManager.current).txt.textPosition = 1 ' move the cursor to the beginning of the line

                ' Box cursor movement
                Widget(WidgetManager.current).txt.boxPosition = 1
                Widget(WidgetManager.current).txt.boxStartCharacter = 1

                InputManager.keyCode = NULL ' consume the key

            Case KEY_END
                Widget(WidgetManager.current).txt.textPosition = Len(Widget(WidgetManager.current).text) + 1 ' move the cursor to the end of the line

                ' Box cursor movement
                Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.boxTextLength + 1
                If Widget(WidgetManager.current).txt.boxPosition > Widget(WidgetManager.current).txt.textPosition Then
                    Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.textPosition
                End If
                Widget(WidgetManager.current).txt.boxStartCharacter = 1 + Len(Widget(WidgetManager.current).text) - Widget(WidgetManager.current).txt.boxTextLength
                If Widget(WidgetManager.current).txt.boxStartCharacter < 1 Then
                    Widget(WidgetManager.current).txt.boxStartCharacter = 1
                End If

                InputManager.keyCode = NULL ' consume the key

            Case KEY_DELETE
                If Widget(WidgetManager.current).txt.textPosition < Len(Widget(WidgetManager.current).text) + 1 Then ' is the cursor at the end of the line?
                    Widget(WidgetManager.current).text = Left$(Widget(WidgetManager.current).text, Widget(WidgetManager.current).txt.textPosition - 1) + Right$(Widget(WidgetManager.current).text, Len(Widget(WidgetManager.current).text) - Widget(WidgetManager.current).txt.textPosition) ' no, delete character
                End If

                InputManager.keyCode = NULL ' consume the key
                Widget(WidgetManager.current).changed = TRUE ' something changed

            Case KEY_ENTER
                Widget(WidgetManager.current).txt.entered = TRUE ' if enter key was pressed remember it (TRUE)
                Widget(WidgetManager.current).changed = TRUE ' something changed
                WidgetManager.forced = -1 ' Move to the next widget

                InputManager.keyCode = NULL ' consume the key

            Case Else ' a character key was pressed
                If InputManager.keyCode > 31 And InputManager.keyCode < 256 Then ' is it a valid ASCII displayable character?
                    Dim K As String ' yes, initialize key holder variable

                    Select Case InputManager.keyCode ' which alphanumeric key was pressed?
                        Case KEY_SPACE_BAR
                            K = Chr$(InputManager.keyCode) ' save the keystroke

                        Case 40 To 41 ' PARENTHESIS key was pressed
                            If (Widget(WidgetManager.current).flags And TEXT_BOX_SYMBOLS) Or (Widget(WidgetManager.current).flags And TEXT_BOX_PAREN) Then
                                K = Chr$(InputManager.keyCode) ' if it's allowed then save the keystroke
                            End If

                        Case 45 ' DASH (minus -) key was pressed
                            If Widget(WidgetManager.current).flags And TEXT_BOX_DASH Then ' are dashes allowed?
                                K = Chr$(InputManager.keyCode) ' yes, save the keystroke
                            End If

                        Case 46 ' DOT
                            If Widget(WidgetManager.current).flags And TEXT_BOX_DOT Then ' are dashes allowed?
                                K = Chr$(InputManager.keyCode) ' yes, save the keystroke
                            End If

                        Case KEY_0 To KEY_9
                            If Widget(WidgetManager.current).flags And TEXT_BOX_NUMERIC Then ' are numbers allowed?
                                K = Chr$(InputManager.keyCode) ' yes, save the keystroke
                            End If

                        Case 33 To 47, 58 To 64, 91 To 96, 123 To 255 ' SYMBOL key was pressed
                            If Widget(WidgetManager.current).flags And TEXT_BOX_SYMBOLS Then ' are symbols allowed?
                                K = Chr$(InputManager.keyCode) ' yes, save the keystroke
                            End If

                        Case KEY_LOWER_A To KEY_LOWER_Z, KEY_UPPER_A To KEY_UPPER_Z
                            If Widget(WidgetManager.current).flags And TEXT_BOX_ALPHA Then ' are alpha keys allowed?
                                K = Chr$(InputManager.keyCode) ' yes, save the keystroke
                            End If
                    End Select

                    If K <> NULLSTRING Then ' was an allowed keystroke saved?
                        If Widget(WidgetManager.current).flags And TEXT_BOX_LOWER Then ' should it be forced to lower case?
                            K = LCase$(K) ' yes, force the keystroke to lower case
                        End If

                        If Widget(WidgetManager.current).flags And TEXT_BOX_UPPER Then ' should it be forced to upper case?
                            K = UCase$(K) ' yes, force the keystroke to upper case
                        End If

                        If Widget(WidgetManager.current).txt.textPosition = Len(Widget(WidgetManager.current).text) + 1 Then ' is the cursor at the end of the line?
                            Widget(WidgetManager.current).text = Widget(WidgetManager.current).text + K ' yes, simply add the keystroke to input text
                            Widget(WidgetManager.current).txt.textPosition = Widget(WidgetManager.current).txt.textPosition + 1 ' increment the cursor position
                        ElseIf Widget(WidgetManager.current).txt.insertMode Then ' no, are we in INSERT mode?
                            Widget(WidgetManager.current).text = Left$(Widget(WidgetManager.current).text, Widget(WidgetManager.current).txt.textPosition - 1) + K + Right$(Widget(WidgetManager.current).text, Len(Widget(WidgetManager.current).text) - Widget(WidgetManager.current).txt.textPosition + 1) ' yes, insert the character
                            Widget(WidgetManager.current).txt.textPosition = Widget(WidgetManager.current).txt.textPosition + 1 ' increment the cursor position
                        Else ' no, we are in OVERWRITE mode
                            Widget(WidgetManager.current).text = Left$(Widget(WidgetManager.current).text, Widget(WidgetManager.current).txt.textPosition - 1) + K + Right$(Widget(WidgetManager.current).text, Len(Widget(WidgetManager.current).text) - Widget(WidgetManager.current).txt.textPosition) ' overwrite with new character
                            Widget(WidgetManager.current).txt.textPosition = Widget(WidgetManager.current).txt.textPosition + 1 ' increment the cursor position
                        End If

                        ' Box cursor movement
                        Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.boxPosition + 1
                        If Widget(WidgetManager.current).txt.boxPosition > Widget(WidgetManager.current).txt.boxTextLength + 1 Then
                            Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.boxTextLength + 1
                            Widget(WidgetManager.current).txt.boxStartCharacter = 1 + Len(Widget(WidgetManager.current).text) - Widget(WidgetManager.current).txt.boxTextLength
                        End If

                        InputManager.keyCode = NULL ' consume the key
                        Widget(WidgetManager.current).changed = TRUE ' something changed
                    End If
                End If
        End Select
    End Sub


    ' Draws a push button widget
    ' Again, colors are hardcoded here
    ' The calling function must ensure that this is called only for active, visible, enabled and the correct widget class
    Sub __PushButtonDraw (handle As Long)
        Shared Widget() As WidgetType
        Shared WidgetManager As WidgetManagerType
        Shared InputManager As InputManagerType
        Dim r As RectangleType, depressed As Byte, textColor As Unsigned Long

        ' Create the bounding box for the widget
        RectangleCreate Widget(handle).position, Widget(handle).size, r

        If Widget(handle).disabled Then ' Draw a widget with dull colors and disregard any user interaction
            textColor = DarkGray
            depressed = Widget(handle).cmd.depressed
        Else
            textColor = Black

            ' Flip depressed state if mouse was clicked and is being held inside the bounding box
            If (InputManager.mouseLeftButton Or InputManager.mouseRightButton) And PointCollidesWithRectangle(InputManager.mousePosition, r) And (PointCollidesWithRectangle(InputManager.mouseLeftButtonClickedRectangle.a, r) Or PointCollidesWithRectangle(InputManager.mouseRightButtonClickedRectangle.a, r)) Then
                depressed = Not Widget(handle).cmd.depressed
            Else
                depressed = Widget(handle).cmd.depressed
            End If
        End If

        ' Draw now
        WidgetDrawBox3D r, depressed
        Color textColor, Gray ' disabled text color
        If depressed Then
            PrintString (1 + Widget(handle).position.x + Widget(handle).size.x \ 2 - PrintWidth(Widget(handle).text) \ 2, 1 + Widget(handle).position.y + Widget(handle).size.y \ 2 - FontHeight \ 2), Widget(handle).text
        Else
            PrintString (Widget(handle).position.x + Widget(handle).size.x \ 2 - PrintWidth(Widget(handle).text) \ 2, Widget(handle).position.y + Widget(handle).size.y \ 2 - FontHeight \ 2), Widget(handle).text
        End If

        ' Draw a decorated box inside the bounding box if the button is focused
        If handle = WidgetManager.current And WidgetManager.focusBlink Then Line (r.a.x + 4, r.a.y + 4)-(r.b.x - 4, r.b.y - 4), Black, B , &B1100110011001100
    End Sub


    ' Draw a text box widget
    ' Again, colors are hardcoded here
    ' The calling function must ensure that this is called only for active, visible, enabled and the correct widget with focus
    Sub __TextBoxDraw (handle As Long)
        Shared Widget() As WidgetType
        Shared WidgetManager As WidgetManagerType
        Dim visibleText As String, r As RectangleType, textColor As Unsigned Long, textY As Long

        RectangleCreate Widget(handle).position, Widget(handle).size, r ' create the bounding box for the widget

        ' Draw a widget with dull colors if disabled
        If Widget(handle).disabled Then
            textColor = DarkGray
        Else
            textColor = Black
        End If

        ' Draw the depressed box first
        WidgetDrawBox3D r, TRUE

        ' Next figure out what part of the text we need to draw
        visibleText = Mid$(Widget(handle).text, Widget(handle).txt.boxStartCharacter, Widget(handle).txt.boxTextLength)

        ' Calculate the Y position of the text in the box
        textY = 2 + Widget(handle).position.y + (Widget(handle).size.y - 4) \ 2 - FontHeight \ 2

        ' Draw the text over the box
        Color textColor, Gray
        If Widget(handle).flags And TEXT_BOX_PASSWORD Then
            PrintString (2 + Widget(handle).position.x, textY), String$(Widget(handle).txt.boxTextLength, Chr$(7))
        Else
            PrintString (2 + Widget(handle).position.x, textY), visibleText
        End If

        ' Draw the cursor only if below conditions are met
        If handle = WidgetManager.current And WidgetManager.focusBlink And Not Widget(handle).disabled Then
            Dim charHeight As Long, charWidth As Long, curPosX As Long

            charHeight = FontHeight ' get the font height
            charWidth = FontWidth
            If charWidth = 0 Then charWidth = PrintWidth("X")

            curPosX = 2 + Widget(handle).position.x + (charWidth * (Widget(handle).txt.boxPosition - 1))
            If Widget(handle).txt.insertMode Then
                Line (curPosX, textY + charHeight - 4)-(curPosX + charWidth - 1, textY + charHeight - 1), Black, BF
            Else
                Line (curPosX, textY)-(curPosX + charWidth - 1, textY + charHeight - 1), Black, BF
            End If
        End If
    End Sub

    '-----------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------

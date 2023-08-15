'-----------------------------------------------------------------------------------------------------------------------
' Immediate mode GUI library
' Copyright (c) 2023 Samuel Gomes
'
' This is very loosely based on Terry Ritchie's GLINPUT & RQBL
' The library has an input manager, tabbed focus and implements text box and push button widgets (so far)
' This is an immediate mode UI. Which means all UI rendering is destructive
' The framebuffer needs to be redrawn every frame and nothing the widgets drawn over is preserved
' This was born because I needed a small, fast and intuitive GUI libary for games and graphic applications
' This is a work in progress
'-----------------------------------------------------------------------------------------------------------------------

$IF IMGUI_BAS = UNDEFINED THEN
    $LET IMGUI_BAS = TRUE

    '$INCLUDE:'ImGUI.bi'

    ' Calculates the bounding rectangle for a object given its position & size
    SUB RectangleCreate (p AS Vector2LType, s AS Vector2LType, r AS RectangleType)
        r.a.x = p.x
        r.a.y = p.y
        r.b.x = p.x + s.x - 1
        r.b.y = p.y + s.y - 1
    END SUB


    ' Does big contain small?
    FUNCTION RectangleContainsRectangle%% (big AS RectangleType, small AS RectangleType)
        RectangleContainsRectangle = PointCollidesWithRectangle(small.a, big) AND PointCollidesWithRectangle(small.b, big)
    END FUNCTION


    ' Point & box collision test
    FUNCTION PointCollidesWithRectangle%% (p AS Vector2LType, r AS RectangleType)
        PointCollidesWithRectangle = NOT (p.x < r.a.x OR p.x > r.b.x OR p.y < r.a.y OR p.y > r.b.y)
    END FUNCTION


    ' Draws a basic 3D box
    ' This can be improved ... a lot XD
    ' Also all colors are hardcoded
    SUB WidgetDrawBox3D (r AS RectangleType, depressed AS _BYTE)
        IF depressed THEN ' sunken
            LINE (r.a.x, r.a.y)-(r.b.x - 1, r.a.y), &HFF696969
            LINE (r.a.x, r.a.y)-(r.a.x, r.b.y - 1), &HFF696969
            LINE (r.a.x, r.b.y)-(r.b.x, r.b.y), &HFFD3D3D3
            LINE (r.b.x, r.a.y)-(r.b.x, r.b.y - 1), &HFFD3D3D3
        ELSE ' raised
            LINE (r.a.x, r.a.y)-(r.b.x - 1, r.a.y), &HFFD3D3D3
            LINE (r.a.x, r.a.y)-(r.a.x, r.b.y - 1), &HFFD3D3D3
            LINE (r.a.x, r.b.y)-(r.b.x, r.b.y), &HFF696969
            LINE (r.b.x, r.a.y)-(r.b.x, r.b.y - 1), &HFF696969
        END IF

        LINE (r.a.x + 1, r.a.y + 1)-(r.b.x - 1, r.b.y - 1), &HFF808080, BF
    END SUB


    ' This routine ties the whole update system and makes everything go
    SUB WidgetUpdate
        STATIC blinkTick AS _INTEGER64 ' stores the last blink tick (oooh!)
        SHARED Widget() AS WidgetType
        SHARED WidgetManager AS WidgetManagerType
        SHARED InputManager AS InputManagerType
        DIM h AS LONG, r AS RectangleType, currentTick AS _INTEGER64

        InputManagerUpdate ' We will gather input even if there are no widgets

        IF UBOUND(Widget) = NULL THEN EXIT SUB ' Exit if there is nothing to do

        ' Blinky stuff
        currentTick = GetTicks
        IF currentTick > blinkTick + WIDGET_BLINK_INTERVAL THEN
            blinkTick = currentTick
            WidgetManager.focusBlink = NOT WidgetManager.focusBlink
        END IF

        ' Manage widget focus stuff
        IF WidgetManager.current = NULL THEN WidgetManager.current = 1 ' if this is first time set current widget to 1

        ' Shift focus if it was requested
        IF WidgetManager.forced <> NULL THEN ' being forced to a widget
            IF WidgetManager.forced = -1 THEN ' yes, to the next one?
                h = WidgetManager.current ' set scanner to current widget
                DO ' start scanning
                    h = h + 1 ' move scanner to next handle number
                    IF h > UBOUND(Widget) THEN h = 1 ' return to start of widget array if limit reached
                    IF Widget(h).inUse AND Widget(h).visible AND NOT Widget(h).disabled THEN WidgetManager.current = h ' set current widget if in use
                LOOP UNTIL WidgetManager.current = h ' leave scanner when a widget in use is found
                WidgetManager.forced = NULL ' reset force indicator
            ELSE ' yes, to a specific input field
                IF Widget(WidgetManager.forced).inUse AND Widget(WidgetManager.forced).visible AND NOT Widget(WidgetManager.forced).disabled THEN
                    WidgetManager.current = WidgetManager.forced ' set the current widget
                END IF
                WidgetManager.forced = NULL ' reset force indicator
            END IF
        END IF

        ' Check for user input requesting focus change
        IF InputManager.keyCode = KEY_TAB THEN
            WidgetManager.forced = -1 ' Move to the next widget
            InputManager.keyCode = NULL ' consume the key
        END IF

        ' Check if the user is trying to click on something to change focus
        FOR h = 1 TO UBOUND(Widget)
            ' Reset some stuff that the user should have handled last time
            Widget(h).clicked = FALSE
            Widget(h).txt.entered = FALSE

            IF Widget(h).inUse AND Widget(h).visible AND NOT Widget(h).disabled AND h <> WidgetManager.current THEN

                ' Find the bounding box
                RectangleCreate Widget(h).position, Widget(h).size, r

                IF InputManager.mouseLeftClicked THEN
                    IF RectangleContainsRectangle(r, InputManager.mouseLeftButtonClickedRectangle) THEN
                        WidgetManager.forced = h ' Move to the specific widget
                    END IF
                END IF

                IF InputManager.mouseRightClicked THEN
                    IF RectangleContainsRectangle(r, InputManager.mouseRightButtonClickedRectangle) THEN
                        WidgetManager.forced = h ' Move to the specific widget
                    END IF
                END IF
            END IF
        NEXT


        ' Run update for the widget that has focus
        IF Widget(WidgetManager.current).inUse AND Widget(WidgetManager.current).visible AND NOT Widget(WidgetManager.current).disabled THEN
            SELECT CASE Widget(WidgetManager.current).class
                CASE WIDGET_PUSH_BUTTON
                    __PushButtonUpdate
                CASE WIDGET_TEXT_BOX
                    __TextBoxUpdate
            END SELECT
        END IF

        ' Now draw all the widget to the framebuffer
        FOR h = 1 TO UBOUND(Widget)
            IF Widget(h).inUse AND Widget(h).visible THEN
                SELECT CASE Widget(h).class
                    CASE WIDGET_PUSH_BUTTON
                        __PushButtonDraw h
                    CASE WIDGET_TEXT_BOX
                        __TextBoxDraw h
                END SELECT
            END IF
        NEXT
    END SUB


    SUB InputManagerUpdate
        SHARED InputManager AS InputManagerType
        STATIC AS _BYTE mouseLeftButtonDown, mouseRightButtonDown ' keeps track if the mouse buttons were held down

        ' Collect mouse input
        DO WHILE _MOUSEINPUT
            InputManager.mousePosition.x = _MOUSEX
            InputManager.mousePosition.y = _MOUSEY

            InputManager.mouseLeftButton = _MOUSEBUTTON(1)
            InputManager.mouseRightButton = _MOUSEBUTTON(2)

            ' Check if the left button were previously held down and update the up position if released
            IF NOT InputManager.mouseLeftButton AND mouseLeftButtonDown THEN
                mouseLeftButtonDown = FALSE
                InputManager.mouseLeftButtonClickedRectangle.b = InputManager.mousePosition
                InputManager.mouseLeftClicked = TRUE
            END IF

            ' Check if the button were previously held down and update the up position if released
            IF NOT InputManager.mouseRightButton AND mouseRightButtonDown THEN
                mouseRightButtonDown = FALSE
                InputManager.mouseRightButtonClickedRectangle.b = InputManager.mousePosition
                InputManager.mouseRightClicked = TRUE
            END IF

            ' Check if the mouse button was pressed and update the down position
            IF InputManager.mouseLeftButton AND NOT mouseLeftButtonDown THEN
                mouseLeftButtonDown = TRUE
                InputManager.mouseLeftButtonClickedRectangle.a = InputManager.mousePosition
                InputManager.mouseLeftClicked = FALSE
            END IF

            ' Check if the mouse button was pressed and update the down position
            IF InputManager.mouseRightButton AND NOT mouseRightButtonDown THEN
                mouseRightButtonDown = TRUE
                InputManager.mouseRightButtonClickedRectangle.a = InputManager.mousePosition
                InputManager.mouseRightClicked = FALSE
            END IF
        LOOP

        ' Get keyboard input from the keyboard buffer
        InputManager.keyCode = _KEYHIT
    END SUB


    ' This gets the current keyboard input
    FUNCTION InputManagerKey&
        SHARED InputManager AS InputManagerType

        InputManagerKey = InputManager.keyCode
    END FUNCTION


    ' Get the mouse X position
    FUNCTION InputManagerMouseX&
        SHARED InputManager AS InputManagerType

        InputManagerMouseX = InputManager.mousePosition.x
    END FUNCTION


    ' Get the mouse Y position
    FUNCTION InputManagerMouseY&
        SHARED InputManager AS InputManagerType

        InputManagerMouseY = InputManager.mousePosition.y
    END FUNCTION


    ' Is the left mouse button down?
    FUNCTION InputManagerMouseLeftButton%%
        SHARED InputManager AS InputManagerType

        InputManagerMouseLeftButton = InputManager.mouseLeftButton
    END FUNCTION


    ' Is the right mouse button down?
    FUNCTION InputManagerMouseRightButton%%
        SHARED InputManager AS InputManagerType

        InputManagerMouseRightButton = InputManager.mouseRightButton
    END FUNCTION


    ' Returns the handle number of the widget that has focus
    ' The function will return 0 if there are no active widgets
    FUNCTION WidgetCurrent&
        SHARED Widget() AS WidgetType
        SHARED WidgetManager AS WidgetManagerType

        IF UBOUND(Widget) = NULL THEN EXIT FUNCTION

        WidgetCurrent = WidgetManager.current
    END FUNCTION


    ' This set the focus on the widget handle that is passed
    ' The focus changes on the next update
    ' -1 = move to next widget
    ' >0 = move to a specific widget
    SUB WidgetCurrent (handle AS LONG)
        SHARED Widget() AS WidgetType
        SHARED WidgetManager AS WidgetManagerType

        IF UBOUND(Widget) = NULL THEN EXIT SUB ' Leave if nothing is active

        IF handle < -1 OR handle = NULL OR handle > UBOUND(Widget) THEN ' is handle valid?
            ERROR ERROR_INVALID_HANDLE
        END IF

        WidgetManager.forced = handle ' inform WidgetUpdate to change the focus
    END SUB


    ' Closes a specific widget
    SUB WidgetFree (handle AS LONG)
        SHARED Widget() AS WidgetType
        SHARED WidgetManager AS WidgetManagerType

        IF UBOUND(Widget) = NULL THEN EXIT SUB ' leave if nothing is active

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN ' is handle valid?
            ERROR ERROR_INVALID_HANDLE
        END IF

        ' We will not bother resizing the widget array so that subsequent allocations will be faster
        ' So just set the 'inUse' member to false
        Widget(handle).inUse = FALSE
        IF handle = WidgetManager.current THEN WidgetManager.forced = -1 ' Set focus on the next widget if it is current
    END SUB


    ' Closes all widgets
    SUB WidgetFreeAll
        SHARED Widget() AS WidgetType
        SHARED WidgetManager AS WidgetManagerType

        IF UBOUND(Widget) = NULL THEN EXIT SUB ' leave if nothing is active

        REDIM Widget(NULL TO NULL) AS WidgetType ' reset the widget array
        WidgetManager.current = NULL
        WidgetManager.forced = NULL
    END SUB


    ' Retrieves the text from a specific widget
    FUNCTION WidgetText$ (handle AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT FUNCTION

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        WidgetText = Widget(handle).text
    END FUNCTION


    ' Sets the text of a specific widget
    SUB WidgetText (handle AS LONG, text AS STRING)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT SUB

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        Widget(handle).text = text
        Widget(handle).changed = TRUE
    END SUB


    ' Reports true if the ENTER key has been pressed on the input box
    FUNCTION TextBoxEntered%% (handle AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT FUNCTION ' leave if nothing is active

        IF handle < 1 OR handle > UBOUND(Widget) OR Widget(handle).class <> WIDGET_TEXT_BOX THEN ' is handle valid?
            ERROR ERROR_INVALID_HANDLE
        END IF

        TextBoxEntered = Widget(handle).txt.entered
    END FUNCTION


    ' Returns true if the text field of a text box has changed
    FUNCTION TextBoxChanged%% (handle AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT FUNCTION ' leave if nothing is active

        IF handle < 1 OR handle > UBOUND(Widget) OR Widget(handle).class <> WIDGET_TEXT_BOX THEN ' is handle valid?
            ERROR ERROR_INVALID_HANDLE
        END IF

        TextBoxChanged = Widget(handle).changed
    END FUNCTION


    ' Sets up a widget and returns a handle value that points to that widget
    FUNCTION __WidgetNew& (class AS LONG)
        SHARED Widget() AS WidgetType
        SHARED WidgetManager AS WidgetManagerType

        IF class < NULL OR class > WIDGET_CLASS_COUNT THEN
            ERROR ERROR_FEATURE_UNAVAILABLE
        END IF

        IF UBOUND(Widget) = NULL THEN ' Reallocate the widget array if this the first time
            REDIM Widget(1 TO 1) AS WidgetType
            Widget(1).inUse = FALSE
        END IF

        DIM h AS LONG ' the new handle number

        DO ' find available handle
            h = h + 1
        LOOP UNTIL NOT Widget(h).inUse OR h = UBOUND(Widget)

        IF Widget(h).inUse THEN ' last one in use?
            h = h + 1 ' use next handle
            REDIM _PRESERVE Widget(1 TO h) AS WidgetType ' increase array size
        END IF

        DIM temp AS WidgetType
        Widget(h) = temp ' ensure everything is wiped

        Widget(h).inUse = TRUE
        Widget(h).class = class ' set the class

        __WidgetNew = h ' return the handle
    END FUNCTION


    ' Duplicates a widget from a designated handle
    ' Returns handle value greater than 0 indicating the new widgets handle
    FUNCTION WidgetCopy& (handle AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT FUNCTION

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        DIM nh AS LONG
        nh = __WidgetNew(NULL) ' creat a new widget of class 0. Whatever that is, is not important
        Widget(nh) = Widget(handle) ' copy all properties

        WidgetCopy = nh ' return new handle
    END FUNCTION


    ' Creates a new button
    FUNCTION PushButtonNew& (text AS STRING, x AS LONG, y AS LONG, w AS _UNSIGNED LONG, h AS _UNSIGNED LONG, toggleButton AS _BYTE)
        SHARED Widget() AS WidgetType
        DIM b AS LONG

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
    END FUNCTION


    ' Create a new input box
    FUNCTION TextBoxNew& (text AS STRING, x AS LONG, y AS LONG, w AS _UNSIGNED LONG, h AS _UNSIGNED LONG, flags AS _UNSIGNED LONG)
        SHARED Widget() AS WidgetType

        DIM t AS LONG ' the new handle number

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
        Widget(t).txt.boxTextLength = (w - _PRINTWIDTH("W") * 2) \ _PRINTWIDTH("W") ' calculate the number of character we can show at a time
        Widget(t).txt.boxStartCharacter = 1
        Widget(t).txt.insertMode = TRUE ' initial insert mode to insert

        TextBoxNew = t
    END FUNCTION


    ' Hides / shows a widget on screen
    SUB WidgetVisible (handle AS LONG, visible AS _BYTE)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT SUB

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        Widget(handle).visible = visible
    END SUB


    ' Returns if a widget is hidden or shown
    FUNCTION WidgetVisible%% (handle AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT FUNCTION

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        WidgetVisible = Widget(handle).visible
    END FUNCTION


    ' Sets all active widget to visible or invisible
    SUB WidgetVisibleAll (visible AS _BYTE)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT SUB ' leave if nothing is active

        DIM h AS LONG

        FOR h = 1 TO UBOUND(Widget)
            IF Widget(h).inUse THEN Widget(h).visible = visible
        NEXT
    END SUB


    ' Hides / shows a widget on screen
    SUB WidgetDisabled (handle AS LONG, disabled AS _BYTE)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT SUB

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        Widget(handle).disabled = disabled
    END SUB


    ' Returns if a widget is hidden or shown
    FUNCTION WidgetDisabled%% (handle AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT FUNCTION

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        WidgetDisabled = Widget(handle).disabled
    END FUNCTION


    SUB WidgetPositionX (handle AS LONG, x AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT SUB

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        Widget(handle).position.x = x
    END SUB


    FUNCTION WidgetPositionX& (handle AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT FUNCTION

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        WidgetPositionX = Widget(handle).position.x
    END FUNCTION


    SUB WidgetPositionY (handle AS LONG, y AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT SUB

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        Widget(handle).position.y = y
    END SUB


    FUNCTION WidgetPositionY& (handle AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT FUNCTION

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        WidgetPositionY = Widget(handle).position.y
    END FUNCTION


    SUB WidgetSizeX (handle AS LONG, x AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT SUB

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        Widget(handle).size.x = x
    END SUB


    FUNCTION WidgetSizeX& (handle AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT FUNCTION

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        WidgetSizeX = Widget(handle).size.x
    END FUNCTION


    SUB WidgetSizeY (handle AS LONG, y AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT SUB

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        Widget(handle).size.y = y
    END SUB


    FUNCTION WidgetSizeY& (handle AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT FUNCTION

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        WidgetSizeY = Widget(handle).size.y
    END FUNCTION


    FUNCTION WidgetClicked%% (handle AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT FUNCTION

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        WidgetClicked = Widget(handle).clicked
    END FUNCTION


    SUB PushButtonDepressed (handle AS LONG, depressed AS _BYTE)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT SUB

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse OR Widget(handle).class <> WIDGET_PUSH_BUTTON THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        Widget(handle).cmd.depressed = depressed
    END SUB


    FUNCTION PushButtonDepressed%% (handle AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT FUNCTION

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse OR Widget(handle).class <> WIDGET_PUSH_BUTTON THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        PushButtonDepressed = Widget(handle).cmd.depressed
    END FUNCTION


    ' Toggles the button specified between pressed/depressed
    SUB PushButtonToggleDepressed (handle AS LONG)
        SHARED Widget() AS WidgetType

        IF UBOUND(Widget) = NULL THEN EXIT SUB

        IF handle < 1 OR handle > UBOUND(Widget) OR NOT Widget(handle).inUse OR Widget(handle).class <> WIDGET_PUSH_BUTTON THEN
            ERROR ERROR_INVALID_HANDLE
        END IF

        Widget(handle).cmd.depressed = NOT Widget(handle).cmd.depressed
    END SUB


    ' This will update the status of a button (state & clicked etc.) based on user input
    ' The calling function must ensure that this is called only for visible, enabled and the correct widget with focus
    SUB __PushButtonUpdate
        SHARED Widget() AS WidgetType
        SHARED WidgetManager AS WidgetManagerType
        SHARED InputManager AS InputManagerType
        DIM r AS RectangleType, clicked AS _BYTE

        ' Find the bounding box
        RectangleCreate Widget(WidgetManager.current).position, Widget(WidgetManager.current).size, r

        IF InputManager.mouseLeftClicked THEN
            IF RectangleContainsRectangle(r, InputManager.mouseLeftButtonClickedRectangle) THEN
                clicked = TRUE
                InputManager.mouseLeftClicked = FALSE ' consume mouse click
            END IF
        END IF

        IF InputManager.mouseRightClicked THEN
            IF RectangleContainsRectangle(r, InputManager.mouseRightButtonClickedRectangle) THEN
                clicked = TRUE
                InputManager.mouseRightClicked = FALSE ' consume mouse click
            END IF
        END IF

        IF InputManager.keyCode = KEY_ENTER OR InputManager.keyCode = KEY_SPACE THEN
            clicked = TRUE
            InputManager.keyCode = NULL ' consume keystroke
        END IF

        Widget(WidgetManager.current).clicked = clicked

        ' Toggle if this is a toggle button
        IF clicked AND Widget(WidgetManager.current).flags THEN
            Widget(WidgetManager.current).cmd.depressed = NOT Widget(WidgetManager.current).cmd.depressed
        END IF
    END SUB


    ' This will update the state of text box based on user input
    ' The calling function must ensure that this is called only for visible, enabled and the correct widget with focus
    SUB __TextBoxUpdate
        SHARED Widget() AS WidgetType
        SHARED WidgetManager AS WidgetManagerType
        SHARED InputManager AS InputManagerType

        Widget(WidgetManager.current).changed = FALSE ' Set this to false
        Widget(WidgetManager.current).txt.entered = FALSE ' Set this to false too

        ' First process any pressed keys
        SELECT CASE InputManager.keyCode ' which key was hit?
            CASE KEY_INSERT
                Widget(WidgetManager.current).txt.insertMode = NOT Widget(WidgetManager.current).txt.insertMode

                InputManager.keyCode = NULL ' consume the key

            CASE KEY_RIGHT_ARROW
                Widget(WidgetManager.current).txt.textPosition = Widget(WidgetManager.current).txt.textPosition + 1 ' increment the cursor position
                IF Widget(WidgetManager.current).txt.textPosition > LEN(Widget(WidgetManager.current).text) + 1 THEN ' will this take the cursor too far?
                    Widget(WidgetManager.current).txt.textPosition = LEN(Widget(WidgetManager.current).text) + 1 ' yes, keep the cursor at the end of the line
                END IF

                ' Box cursor movement
                Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.boxPosition + 1

                IF Widget(WidgetManager.current).txt.boxPosition > Widget(WidgetManager.current).txt.textPosition THEN
                    Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.textPosition
                END IF

                IF Widget(WidgetManager.current).txt.boxPosition > Widget(WidgetManager.current).txt.boxTextLength + 1 THEN
                    Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.boxTextLength + 1

                    Widget(WidgetManager.current).txt.boxStartCharacter = 1 + LEN(Widget(WidgetManager.current).text) - Widget(WidgetManager.current).txt.boxTextLength
                END IF

                InputManager.keyCode = NULL ' consume the key

            CASE KEY_LEFT_ARROW
                Widget(WidgetManager.current).txt.textPosition = Widget(WidgetManager.current).txt.textPosition - 1 ' decrement the cursor position
                IF Widget(WidgetManager.current).txt.textPosition < 1 THEN ' did cursor go beyone beginning of line?
                    Widget(WidgetManager.current).txt.textPosition = 1 ' yes, keep the cursor at the beginning of the line
                END IF

                ' Box cursor movement
                Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.boxPosition - 1
                IF Widget(WidgetManager.current).txt.boxPosition < 1 THEN
                    Widget(WidgetManager.current).txt.boxPosition = 1
                    IF Widget(WidgetManager.current).txt.boxStartCharacter > 1 THEN
                        Widget(WidgetManager.current).txt.boxStartCharacter = Widget(WidgetManager.current).txt.boxStartCharacter - 1
                    END IF
                END IF

                InputManager.keyCode = NULL ' consume the key

            CASE KEY_BACKSPACE
                IF Widget(WidgetManager.current).txt.textPosition > 1 THEN ' is the cursor at the beginning of the line?
                    Widget(WidgetManager.current).text = LEFT$(Widget(WidgetManager.current).text, Widget(WidgetManager.current).txt.textPosition - 2) + RIGHT$(Widget(WidgetManager.current).text, LEN(Widget(WidgetManager.current).text) - Widget(WidgetManager.current).txt.textPosition + 1) ' no, delete character
                    Widget(WidgetManager.current).txt.textPosition = Widget(WidgetManager.current).txt.textPosition - 1 ' decrement the cursor position
                END IF

                ' Box cursor movement
                Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.boxPosition - 1
                IF Widget(WidgetManager.current).txt.boxPosition < 1 THEN
                    Widget(WidgetManager.current).txt.boxPosition = 1
                    IF Widget(WidgetManager.current).txt.boxStartCharacter > 1 THEN
                        Widget(WidgetManager.current).txt.boxStartCharacter = Widget(WidgetManager.current).txt.boxStartCharacter - 1
                    END IF
                END IF

                InputManager.keyCode = NULL ' consume the key
                Widget(WidgetManager.current).changed = TRUE ' something changed

            CASE KEY_HOME
                Widget(WidgetManager.current).txt.textPosition = 1 ' move the cursor to the beginning of the line

                ' Box cursor movement
                Widget(WidgetManager.current).txt.boxPosition = 1
                Widget(WidgetManager.current).txt.boxStartCharacter = 1

                InputManager.keyCode = NULL ' consume the key

            CASE KEY_END
                Widget(WidgetManager.current).txt.textPosition = LEN(Widget(WidgetManager.current).text) + 1 ' move the cursor to the end of the line

                ' Box cursor movement
                Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.boxTextLength + 1
                IF Widget(WidgetManager.current).txt.boxPosition > Widget(WidgetManager.current).txt.textPosition THEN
                    Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.textPosition
                END IF
                Widget(WidgetManager.current).txt.boxStartCharacter = 1 + LEN(Widget(WidgetManager.current).text) - Widget(WidgetManager.current).txt.boxTextLength
                IF Widget(WidgetManager.current).txt.boxStartCharacter < 1 THEN
                    Widget(WidgetManager.current).txt.boxStartCharacter = 1
                END IF

                InputManager.keyCode = NULL ' consume the key

            CASE KEY_DELETE
                IF Widget(WidgetManager.current).txt.textPosition < LEN(Widget(WidgetManager.current).text) + 1 THEN ' is the cursor at the end of the line?
                    Widget(WidgetManager.current).text = LEFT$(Widget(WidgetManager.current).text, Widget(WidgetManager.current).txt.textPosition - 1) + RIGHT$(Widget(WidgetManager.current).text, LEN(Widget(WidgetManager.current).text) - Widget(WidgetManager.current).txt.textPosition) ' no, delete character
                END IF

                InputManager.keyCode = NULL ' consume the key
                Widget(WidgetManager.current).changed = TRUE ' something changed

            CASE KEY_ENTER
                Widget(WidgetManager.current).txt.entered = TRUE ' if enter key was pressed remember it (TRUE)
                Widget(WidgetManager.current).changed = TRUE ' something changed
                WidgetManager.forced = -1 ' Move to the next widget

                InputManager.keyCode = NULL ' consume the key

            CASE ELSE ' a character key was pressed
                IF InputManager.keyCode > 31 AND InputManager.keyCode < 256 THEN ' is it a valid ASCII displayable character?
                    DIM K AS STRING ' yes, initialize key holder variable

                    SELECT CASE InputManager.keyCode ' which alphanumeric key was pressed?
                        CASE KEY_SPACE
                            K = CHR$(InputManager.keyCode) ' save the keystroke

                        CASE 40 TO 41 ' PARENTHESIS key was pressed
                            IF (Widget(WidgetManager.current).flags AND TEXT_BOX_SYMBOLS) OR (Widget(WidgetManager.current).flags AND TEXT_BOX_PAREN) THEN
                                K = CHR$(InputManager.keyCode) ' if it's allowed then save the keystroke
                            END IF

                        CASE 45 ' DASH (minus -) key was pressed
                            IF Widget(WidgetManager.current).flags AND TEXT_BOX_DASH THEN ' are dashes allowed?
                                K = CHR$(InputManager.keyCode) ' yes, save the keystroke
                            END IF

                        CASE 46 ' DOT
                            IF Widget(WidgetManager.current).flags AND TEXT_BOX_DOT THEN ' are dashes allowed?
                                K = CHR$(InputManager.keyCode) ' yes, save the keystroke
                            END IF

                        CASE KEY_0 TO KEY_9
                            IF Widget(WidgetManager.current).flags AND TEXT_BOX_NUMERIC THEN ' are numbers allowed?
                                K = CHR$(InputManager.keyCode) ' yes, save the keystroke
                            END IF

                        CASE 33 TO 47, 58 TO 64, 91 TO 96, 123 TO 255 ' SYMBOL key was pressed
                            IF Widget(WidgetManager.current).flags AND TEXT_BOX_SYMBOLS THEN ' are symbols allowed?
                                K = CHR$(InputManager.keyCode) ' yes, save the keystroke
                            END IF

                        CASE KEY_LOWER_A TO KEY_LOWER_Z, KEY_UPPER_A TO KEY_UPPER_Z
                            IF Widget(WidgetManager.current).flags AND TEXT_BOX_ALPHA THEN ' are alpha keys allowed?
                                K = CHR$(InputManager.keyCode) ' yes, save the keystroke
                            END IF
                    END SELECT

                    IF K <> EMPTY_STRING THEN ' was an allowed keystroke saved?
                        IF Widget(WidgetManager.current).flags AND TEXT_BOX_LOWER THEN ' should it be forced to lower case?
                            K = LCASE$(K) ' yes, force the keystroke to lower case
                        END IF

                        IF Widget(WidgetManager.current).flags AND TEXT_BOX_UPPER THEN ' should it be forced to upper case?
                            K = UCASE$(K) ' yes, force the keystroke to upper case
                        END IF

                        IF Widget(WidgetManager.current).txt.textPosition = LEN(Widget(WidgetManager.current).text) + 1 THEN ' is the cursor at the end of the line?
                            Widget(WidgetManager.current).text = Widget(WidgetManager.current).text + K ' yes, simply add the keystroke to input text
                            Widget(WidgetManager.current).txt.textPosition = Widget(WidgetManager.current).txt.textPosition + 1 ' increment the cursor position
                        ELSEIF Widget(WidgetManager.current).txt.insertMode THEN ' no, are we in INSERT mode?
                            Widget(WidgetManager.current).text = LEFT$(Widget(WidgetManager.current).text, Widget(WidgetManager.current).txt.textPosition - 1) + K + RIGHT$(Widget(WidgetManager.current).text, LEN(Widget(WidgetManager.current).text) - Widget(WidgetManager.current).txt.textPosition + 1) ' yes, insert the character
                            Widget(WidgetManager.current).txt.textPosition = Widget(WidgetManager.current).txt.textPosition + 1 ' increment the cursor position
                        ELSE ' no, we are in OVERWRITE mode
                            Widget(WidgetManager.current).text = LEFT$(Widget(WidgetManager.current).text, Widget(WidgetManager.current).txt.textPosition - 1) + K + RIGHT$(Widget(WidgetManager.current).text, LEN(Widget(WidgetManager.current).text) - Widget(WidgetManager.current).txt.textPosition) ' overwrite with new character
                            Widget(WidgetManager.current).txt.textPosition = Widget(WidgetManager.current).txt.textPosition + 1 ' increment the cursor position
                        END IF

                        ' Box cursor movement
                        Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.boxPosition + 1
                        IF Widget(WidgetManager.current).txt.boxPosition > Widget(WidgetManager.current).txt.boxTextLength + 1 THEN
                            Widget(WidgetManager.current).txt.boxPosition = Widget(WidgetManager.current).txt.boxTextLength + 1
                            Widget(WidgetManager.current).txt.boxStartCharacter = 1 + LEN(Widget(WidgetManager.current).text) - Widget(WidgetManager.current).txt.boxTextLength
                        END IF

                        InputManager.keyCode = NULL ' consume the key
                        Widget(WidgetManager.current).changed = TRUE ' something changed
                    END IF
                END IF
        END SELECT
    END SUB


    ' Draws a push button widget
    ' Again, colors are hardcoded here
    ' The calling function must ensure that this is called only for active, visible, enabled and the correct widget class
    SUB __PushButtonDraw (handle AS LONG)
        SHARED Widget() AS WidgetType
        SHARED WidgetManager AS WidgetManagerType
        SHARED InputManager AS InputManagerType
        DIM r AS RectangleType, depressed AS _BYTE, textColor AS _UNSIGNED LONG

        ' Create the bounding box for the widget
        RectangleCreate Widget(handle).position, Widget(handle).size, r

        IF Widget(handle).disabled THEN ' Draw a widget with dull colors and disregard any user interaction
            textColor = &HFFA9A9A9
            depressed = Widget(handle).cmd.depressed
        ELSE
            textColor = &HFF000000

            ' Flip depressed state if mouse was clicked and is being held inside the bounding box
            IF (InputManager.mouseLeftButton OR InputManager.mouseRightButton) AND PointCollidesWithRectangle(InputManager.mousePosition, r) AND (PointCollidesWithRectangle(InputManager.mouseLeftButtonClickedRectangle.a, r) OR PointCollidesWithRectangle(InputManager.mouseRightButtonClickedRectangle.a, r)) THEN
                depressed = NOT Widget(handle).cmd.depressed
            ELSE
                depressed = Widget(handle).cmd.depressed
            END IF
        END IF

        ' Draw now
        WidgetDrawBox3D r, depressed
        COLOR textColor, &HFF808080 ' disabled text color
        IF depressed THEN
            _PRINTSTRING (1 + Widget(handle).position.x + Widget(handle).size.x \ 2 - _PRINTWIDTH(Widget(handle).text) \ 2, 1 + Widget(handle).position.y + Widget(handle).size.y \ 2 - _FONTHEIGHT \ 2), Widget(handle).text
        ELSE
            _PRINTSTRING (Widget(handle).position.x + Widget(handle).size.x \ 2 - _PRINTWIDTH(Widget(handle).text) \ 2, Widget(handle).position.y + Widget(handle).size.y \ 2 - _FONTHEIGHT \ 2), Widget(handle).text
        END IF

        ' Draw a decorated box inside the bounding box if the button is focused
        IF handle = WidgetManager.current AND WidgetManager.focusBlink THEN LINE (r.a.x + 4, r.a.y + 4)-(r.b.x - 4, r.b.y - 4), &HFF000000, B , &B1100110011001100
    END SUB


    ' Draw a text box widget
    ' Again, colors are hardcoded here
    ' The calling function must ensure that this is called only for active, visible, enabled and the correct widget with focus
    SUB __TextBoxDraw (handle AS LONG)
        SHARED Widget() AS WidgetType
        SHARED WidgetManager AS WidgetManagerType
        DIM visibleText AS STRING, r AS RectangleType, textColor AS _UNSIGNED LONG, textY AS LONG

        RectangleCreate Widget(handle).position, Widget(handle).size, r ' create the bounding box for the widget

        ' Draw a widget with dull colors if disabled
        IF Widget(handle).disabled THEN
            textColor = &HFFA9A9A9
        ELSE
            textColor = &HFF000000
        END IF

        ' Draw the depressed box first
        WidgetDrawBox3D r, TRUE

        ' Next figure out what part of the text we need to draw
        visibleText = MID$(Widget(handle).text, Widget(handle).txt.boxStartCharacter, Widget(handle).txt.boxTextLength)

        ' Calculate the Y position of the text in the box
        textY = 2 + Widget(handle).position.y + (Widget(handle).size.y - 4) \ 2 - _FONTHEIGHT \ 2

        ' Draw the text over the box
        COLOR textColor, &HFF808080
        IF Widget(handle).flags AND TEXT_BOX_PASSWORD THEN
            _PRINTSTRING (2 + Widget(handle).position.x, textY), STRING$(Widget(handle).txt.boxTextLength, CHR$(7))
        ELSE
            _PRINTSTRING (2 + Widget(handle).position.x, textY), visibleText
        END IF

        ' Draw the cursor only if below conditions are met
        IF handle = WidgetManager.current AND WidgetManager.focusBlink AND NOT Widget(handle).disabled THEN
            DIM charHeight AS LONG, charWidth AS LONG, curPosX AS LONG

            charHeight = _FONTHEIGHT ' get the font height
            charWidth = _FONTWIDTH
            IF charWidth = 0 THEN charWidth = _PRINTWIDTH("X")

            curPosX = 2 + Widget(handle).position.x + (charWidth * (Widget(handle).txt.boxPosition - 1))
            IF Widget(handle).txt.insertMode THEN
                LINE (curPosX, textY + charHeight - 4)-(curPosX + charWidth - 1, textY + charHeight - 1), &HFF000000, BF
            ELSE
                LINE (curPosX, textY)-(curPosX + charWidth - 1, textY + charHeight - 1), &HFF000000, BF
            END IF
        END IF
    END SUB

    '$INCLUDE:'ColorOps.bas'
    '$INCLUDE:'TimeOps.bas'

$END IF

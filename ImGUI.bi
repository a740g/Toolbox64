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

$IF IMGUI_BI = UNDEFINED THEN
    $LET IMGUI_BI = TRUE

    '$INCLUDE:'Common.bi'
    '$INCLUDE:'Types.bi'
    '$INCLUDE:'ColorOps.bi'
    '$INCLUDE:'TimeOps.bi'

    ' These are flags that can be used by the text box widget
    CONST TEXT_BOX_ALPHA = 1 ' alphabetic input allowed
    CONST TEXT_BOX_NUMERIC = 2 ' numeric input allowed
    CONST TEXT_BOX_SYMBOLS = 4 ' all symbols allowed
    CONST TEXT_BOX_DASH = 8 ' dash (-) symbol allowed
    CONST TEXT_BOX_DOT = 16 ' dot allowed
    CONST TEXT_BOX_PAREN = 32 ' parenthesis allowed
    CONST TEXT_BOX_EVERYTHING = TEXT_BOX_ALPHA OR TEXT_BOX_NUMERIC OR TEXT_BOX_SYMBOLS OR TEXT_BOX_DASH OR TEXT_BOX_PAREN
    CONST TEXT_BOX_LOWER = 64 ' lower case only
    CONST TEXT_BOX_UPPER = 128 ' upper case only
    CONST TEXT_BOX_PASSWORD = 256 ' password * only

    ' Widget types (add constants here for new types)
    CONST WIDGET_PUSH_BUTTON = 1
    CONST WIDGET_TEXT_BOX = 2
    CONST WIDGET_CLASS_COUNT = 2 ' this is the total number of widgets

    CONST WIDGET_BLINK_INTERVAL = 500 ' number of ticks to wait for next blink

    TYPE RectangleType ' a 2D rectangle
        a AS Vector2LType
        b AS Vector2LType
    END TYPE

    TYPE InputManagerType ' simple input manager
        keyCode AS LONG ' buffer keyboard input
        mousePosition AS Vector2LType ' mouse position
        mouseLeftButton AS _BYTE ' mouse left button down
        mouseRightButton AS _BYTE ' mouse right button down
        mouseLeftClicked AS _BYTE ' If this true mouseLeftButtonClickedRectangle is the rectangle where the click happened
        mouseLeftButtonClickedRectangle AS RectangleType ' the rectangle where the mouse left button was clicked
        mouseRightClicked AS _BYTE ' If this true mouseRightButtonClickedRectangle is the rectangle where the click happened
        mouseRightButtonClickedRectangle AS RectangleType ' the rectangle where the mouse left button was clicked
    END TYPE

    TYPE WidgetManagerType ' widget state information
        forced AS LONG ' widget that is forced to get focus
        current AS LONG ' current widget that has focus
        focusBlink AS _BYTE ' should the focused widget "blink"
    END TYPE

    TYPE TextBoxType ' text box specific stuff
        textPosition AS LONG ' current cursor position within input field text
        boxPosition AS LONG ' cursor character position in the box
        boxTextLength AS LONG ' how much charcters will be visible in the box
        boxStartCharacter AS LONG ' starting visible character
        insertMode AS _BYTE ' current cursor insert mode (-1 = INSERT, 0 = OVERWRITE)
        entered AS _BYTE ' ENTER has been pressed on this input field (T/F)
    END TYPE

    TYPE PushButtonType ' push button specific stuff
        depressed AS _BYTE ' state of button (down or up)
    END TYPE

    TYPE WidgetType
        inUse AS _BYTE ' is this widget in use?
        visible AS _BYTE ' is this widget visible on screen?
        disabled AS _BYTE ' is the widget disabled?
        position AS Vector2LType ' position of the widget on the screen
        size AS Vector2LType ' size of the widget on the screen
        text AS STRING ' text associated with the widget
        changed AS _BYTE ' true if the text was changed somehow
        clicked AS _BYTE ' was the widget pressed / clicked?
        flags AS LONG ' widget flags
        ' Type of widget
        class AS LONG
        ' Type specific stuff (add new widget stuff here)
        cmd AS PushButtonType
        txt AS TextBoxType
    END TYPE

    DIM InputManager AS InputManagerType 'input manager global variable. Use this to check for input
    DIM WidgetManager AS WidgetManagerType ' widget manager global variable. This contains top level widget state
    REDIM Widget(NULL TO NULL) AS WidgetType ' this is the widget array and contains info for all widgets used by the program

$END IF

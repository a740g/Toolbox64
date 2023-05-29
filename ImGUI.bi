'---------------------------------------------------------------------------------------------------------
' Immediate mode GUI library
' Copyright (c) 2023 Samuel Gomes
'
' This is very loosely based on Terry Ritchie's GLINPUT & RQBL
' The library has an input manager, tabbed focus and implements text box and push button widgets (so far)
' This is an immediate mode UI. Which means all UI rendering is destructive
' The framebuffer needs to be redrawn every frame and nothing the widgets drawn over is preserved
' This was born because I needed a small, fast and intuitive GUI libary for games and graphic applications
' This is a work in progress
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------
'$Include:'CRTLib.bi'
'---------------------------------------------------------------------------------------------------------

$If IMGUI_BI = UNDEFINED Then
    $Let IMGUI_BI = TRUE

    '-----------------------------------------------------------------------------------------------------
    ' CONSTANTS
    '-----------------------------------------------------------------------------------------------------
    ' These are flags that can be used by the text box widget
    Const TEXT_BOX_ALPHA = 1 ' alphabetic input allowed
    Const TEXT_BOX_NUMERIC = 2 ' numeric input allowed
    Const TEXT_BOX_SYMBOLS = 4 ' all symbols allowed
    Const TEXT_BOX_DASH = 8 ' dash (-) symbol allowed
    Const TEXT_BOX_DOT = 16 ' dot allowed
    Const TEXT_BOX_PAREN = 32 ' parenthesis allowed
    Const TEXT_BOX_EVERYTHING = TEXT_BOX_ALPHA Or TEXT_BOX_NUMERIC Or TEXT_BOX_SYMBOLS Or TEXT_BOX_DASH Or TEXT_BOX_PAREN
    Const TEXT_BOX_LOWER = 64 ' lower case only
    Const TEXT_BOX_UPPER = 128 ' upper case only
    Const TEXT_BOX_PASSWORD = 256 ' password * only

    ' Widget types (add constants here for new types)
    Const WIDGET_PUSH_BUTTON = 1
    Const WIDGET_TEXT_BOX = 2
    Const WIDGET_CLASS_COUNT = 2 ' this is the total number of widgets

    Const WIDGET_BLINK_INTERVAL = 500 ' number of ticks to wait for next blink
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' USER DEFINED TYPES
    '-----------------------------------------------------------------------------------------------------
    Type RectangleType ' a 2D rectangle
        a As Vector2DType
        b As Vector2DType
    End Type

    Type InputManagerType ' simple input manager
        keyCode As Long ' buffer keyboard input
        mousePosition As Vector2DType ' mouse position
        mouseLeftButton As _Byte ' mouse left button down
        mouseRightButton As _Byte ' mouse right button down
        mouseLeftClicked As _Byte ' If this true mouseLeftButtonClickedRectangle is the rectangle where the click happened
        mouseLeftButtonClickedRectangle As RectangleType ' the rectangle where the mouse left button was clicked
        mouseRightClicked As _Byte ' If this true mouseRightButtonClickedRectangle is the rectangle where the click happened
        mouseRightButtonClickedRectangle As RectangleType ' the rectangle where the mouse left button was clicked
    End Type

    Type WidgetManagerType ' widget state information
        forced As Long ' widget that is forced to get focus
        current As Long ' current widget that has focus
        focusBlink As _Byte ' should the focused widget "blink"
    End Type

    Type TextBoxType ' text box specific stuff
        textPosition As Long ' current cursor position within input field text
        boxPosition As Long ' cursor character position in the box
        boxTextLength As Long ' how much charcters will be visible in the box
        boxStartCharacter As Long ' starting visible character
        insertMode As _Byte ' current cursor insert mode (-1 = INSERT, 0 = OVERWRITE)
        entered As _Byte ' ENTER has been pressed on this input field (T/F)
    End Type

    Type PushButtonType ' push button specific stuff
        depressed As _Byte ' state of button (down or up)
    End Type

    Type WidgetType
        inUse As _Byte ' is this widget in use?
        visible As _Byte ' is this widget visible on screen?
        disabled As _Byte ' is the widget disabled?
        position As Vector2DType ' position of the widget on the screen
        size As Vector2DType ' size of the widget on the screen
        text As String ' text associated with the widget
        changed As _Byte ' true if the text was changed somehow
        clicked As _Byte ' was the widget pressed / clicked?
        flags As Long ' widget flags
        ' Type of widget
        class As Long
        ' Type specific stuff (add new widget stuff here)
        cmd As PushButtonType
        txt As TextBoxType
    End Type
    '-----------------------------------------------------------------------------------------------------

    '-----------------------------------------------------------------------------------------------------
    ' SHARED VARIABLES
    '-----------------------------------------------------------------------------------------------------
    Dim InputManager As InputManagerType 'input manager global variable. Use this to check for input
    Dim WidgetManager As WidgetManagerType ' widget manager global variable. This contains top level widget state
    ReDim Widget(NULL To NULL) As WidgetType ' this is the widget array and contains info for all widgets used by the program
    '-----------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------


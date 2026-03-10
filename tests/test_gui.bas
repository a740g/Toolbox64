'-----------------------------------------------------------------------------------------------------------------------
' GUI Test Application
'-----------------------------------------------------------------------------------------------------------------------

OPTION _EXPLICIT

$RESIZE:ON

'$INCLUDE:'../Graphics/GUI.bi'

' Global handles for widgets
DIM SHARED btn1 AS LONG, btn2 AS LONG, btn3 AS LONG, btnToggle AS LONG
DIM SHARED txt1 AS LONG, txt2 AS LONG, txt3 AS LONG
DIM SHARED lastAction AS STRING

' Main program setup
SCREEN _NEWIMAGE(800, 600, 32)
_TITLE "Toolbox64 GUI Test"

' Create some widgets
btn1 = PushButtonNew("Click Me!", 50, 50, 150, 40, _FALSE)
btn2 = PushButtonNew("Disabled Button", 50, 100, 150, 40, _FALSE)
WidgetDisabled btn2, _TRUE

btnToggle = PushButtonNew("Toggle Me", 50, 150, 150, 40, _TRUE)

txt1 = TextBoxNew("Initial Text", 250, 50, 300, 40, TEXT_BOX_EVERYTHING)
txt2 = TextBoxNew("", 250, 100, 300, 40, TEXT_BOX_NUMERIC)
txt3 = TextBoxNew("Password", 250, 150, 300, 40, TEXT_BOX_PASSWORD)

btn3 = PushButtonNew("Exit", 50, 500, 100, 40, _FALSE)

lastAction = "Ready."

' Main loop
DO
    InputManager_Update

    ' Standard window close check
    IF InputManager_WindowShouldClose THEN EXIT DO

    ' Update logic
    UpdateGUI

    ' Drawing logic
    CLS
    COLOR &HFFFFFFFF, &HFF000000
    _PRINTSTRING (50, 20), "GUI Library Test - Separation of Update and Draw"
    _PRINTSTRING (50, 250), "Last Action: " + lastAction
    _PRINTSTRING (50, 280), "Toggle State: " + STR$(PushButtonDepressed(btnToggle))
    _PRINTSTRING (250, 30), "Alphanumeric Textbox:"
    _PRINTSTRING (250, 85), "Numeric Only Textbox:"
    _PRINTSTRING (250, 135), "Password Textbox:"

    WidgetDraw

    _DISPLAY
    _LIMIT 60
LOOP

SYSTEM

SUB UpdateGUI
    WidgetUpdate

    ' React to widget events
    IF WidgetClicked(btn1) THEN
        lastAction = "Button 1 clicked at " + TIME$
    END IF

    IF WidgetClicked(btnToggle) THEN
        lastAction = "Toggle button changed to: " + STR$(PushButtonDepressed(btnToggle))
    END IF

    IF TextBoxEntered(txt1) THEN
        lastAction = "Text 1 entered: " + WidgetText(txt1)
    END IF

    IF TextBoxEntered(txt2) THEN
        lastAction = "Numeric text entered: " + WidgetText(txt2)
    END IF

    IF WidgetClicked(btn3) THEN
        SYSTEM
    END IF
END SUB

'-----------------------------------------------------------------------------------------------------------------------
' An Input Manager system for QB64-PE
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'InputManager.bi'

' Simple test code
'$RESIZE:ON

'DO UNTIL InputManager_WindowShouldClose
'    DO
'        InputManager_Update

'        IF InputManager_HasKeyboardEvent THEN
'            LOCATE 1, 1
'            PRINT "Keyboard key:"; InputManager_GetKeyboardKey;
'        ELSEIF InputManager_HasMouseEvent THEN
'            LOCATE 2, 1
'            PRINT "Mouse position: ("; InputManager_GetMousePositionX; ","; InputManager_GetMousePositionY; ")";
'        ELSEIF InputManager_HasWindowEvent THEN
'            LOCATE 3, 1
'            IF InputManager_WindowShouldClose THEN
'                PRINT "Window closed by user"
'                EXIT DO
'            ELSEIF InputManager_WasWindowResized THEN
'                WIDTH InputManager_GetWindowResizeWidth \ 8, InputManager_GetWindowResizeHeight \ 16
'                _FONT 16
'                PRINT "Window resized: ("; InputManager_GetWindowResizeWidth; ","; InputManager_GetWindowResizeHeight; ")";
'            END IF
'        ELSEIF InputManager_HasGamepadEvent THEN
'            LOCATE 4, 1
'            PRINT "Gamepad event";
'        END IF
'    LOOP WHILE InputManager_HasEvent

'    _LIMIT 60
'LOOP

'END

FUNCTION __InputManager_GetNormalizeGamepadAxis! (rawValue AS LONG)
    __InputManager_GetNormalizeGamepadAxis = Math_ClampSingle((rawValue - 127.5!) / 126.5!, -1!, 1!)
END FUNCTION

''' @brief Updates the input manager internals and collects events and inputs by polling various functions.
''' Run this once in the main loop and then use the other APIs to react to events.
SUB InputManager_Update
    SHARED __InputManager AS __InputManager
    STATIC AS _BYTE mouseLeftButtonDown, mouseCenterButtonDown, mouseRightButtonDown ' keeps track if the mouse buttons were held down

    ' Get keyboard input from the keyboard buffer
    __InputManager.kbdKeyCode = _KEYHIT

    ' Clear some flags and previous states
    __InputManager.isMouseEvent = _FALSE
    __InputManager.mse.scrollWheelValue = 0
    __InputManager.isWindowEvent = _FALSE
    __InputManager.win.shouldClose = _FALSE
    __InputManager.win.resized = _FALSE
    __InputManager.isGamepad1Event = _FALSE
    __InputManager.isGamepad2Event = _FALSE

    ' Collect mouse input
    DO WHILE _MOUSEINPUT
        ' Flag mouse event
        __InputManager.isMouseEvent = _TRUE

        ' Save the mouse position
        Vector2i_Initialize _MOUSEX, _MOUSEY, __InputManager.mse.position

        ' Save all three button status
        __InputManager.mse.leftButtonDown = _MOUSEBUTTON(1)
        __InputManager.mse.rightButtonDown = _MOUSEBUTTON(2)
        __InputManager.mse.centerButtonDown = _MOUSEBUTTON(3)

        ' Calculate the net displacement of the scroll wheel
        __InputManager.mse.scrollWheelValue = __InputManager.mse.scrollWheelValue + _MOUSEWHEEL

        ' Check if the left mouse button was previously held down and update the up position if released
        IF NOT __InputManager.mse.leftButtonDown _ANDALSO mouseLeftButtonDown THEN
            mouseLeftButtonDown = _FALSE
            __InputManager.mse.leftButtonClickedBounds.rb = __InputManager.mse.position
            Bounds2i_Sanitize __InputManager.mse.leftButtonClickedBounds
            __InputManager.mse.leftButtonClicked = _TRUE
        END IF

        ' Check if the right mouse button was previously held down and update the up position if released
        IF NOT __InputManager.mse.rightButtonDown _ANDALSO mouseRightButtonDown THEN
            mouseRightButtonDown = _FALSE
            __InputManager.mse.rightButtonClickedBounds.rb = __InputManager.mse.position
            Bounds2i_Sanitize __InputManager.mse.rightButtonClickedBounds
            __InputManager.mse.rightButtonClicked = _TRUE
        END IF

        ' Check if the center mouse button was previously held down and update the up position if released
        IF NOT __InputManager.mse.centerButtonDown _ANDALSO mouseCenterButtonDown THEN
            mouseCenterButtonDown = _FALSE
            __InputManager.mse.centerButtonClickedBounds.rb = __InputManager.mse.position
            Bounds2i_Sanitize __InputManager.mse.centerButtonClickedBounds
            __InputManager.mse.centerButtonClicked = _TRUE
        END IF

        ' Exit if we have any button up event for the system to process it
        IF __InputManager.mse.leftButtonClicked _ORELSE __InputManager.mse.rightButtonClicked _ORELSE __InputManager.mse.centerButtonClicked THEN
            EXIT DO
        END IF

        ' Check if the left mouse button was pressed and update the down position
        IF __InputManager.mse.leftButtonDown _ANDALSO NOT mouseLeftButtonDown THEN
            mouseLeftButtonDown = _TRUE
            __InputManager.mse.leftButtonClickedBounds.lt = __InputManager.mse.position
            __InputManager.mse.leftButtonClicked = _FALSE
        END IF

        ' Check if the right mouse button was pressed and update the down position
        IF __InputManager.mse.rightButtonDown _ANDALSO NOT mouseRightButtonDown THEN
            mouseRightButtonDown = _TRUE
            __InputManager.mse.rightButtonClickedBounds.lt = __InputManager.mse.position
            __InputManager.mse.rightButtonClicked = _FALSE
        END IF

        ' Check if the center mouse button was pressed and update the down position
        IF __InputManager.mse.centerButtonDown _ANDALSO NOT mouseCenterButtonDown THEN
            mouseCenterButtonDown = _TRUE
            __InputManager.mse.centerButtonClickedBounds.lt = __InputManager.mse.position
            __InputManager.mse.centerButtonClicked = _FALSE
        END IF

        ' Exit if we have any button down event for the system to process it
        IF mouseLeftButtonDown _ORELSE mouseRightButtonDown _ORELSE mouseCenterButtonDown THEN
            EXIT DO
        END IF
    LOOP

    ' Gather window events
    IF _RESIZE THEN
        __InputManager.isWindowEvent = _TRUE
        __InputManager.win.resized = _TRUE
        Vector2i_Initialize _RESIZEWIDTH, _RESIZEHEIGHT, __InputManager.win.size
    END IF

    IF _EXIT THEN
        __InputManager.isWindowEvent = _TRUE
        __InputManager.win.shouldClose = _TRUE
    END IF
END SUB

''' @brief Returns true if the input manager has any event waiting to be processed.
''' @return True if the input manager has any event waiting to be processed.
FUNCTION InputManager_HasEvent%%
    SHARED __InputManager AS __InputManager
    InputManager_HasEvent = __InputManager.kbdKeyCode <> _ASC_NUL _ORELSE __InputManager.isMouseEvent _ORELSE __InputManager.isWindowEvent _ORELSE __InputManager.isGamepad1Event _ORELSE __InputManager.isGamepad2Event
END FUNCTION

''' @brief Returns true if a keyboard event is waiting to be processed.
''' @return True if a keyboard event is waiting to be processed.
FUNCTION InputManager_HasKeyboardEvent%%
    SHARED __InputManager AS __InputManager
    InputManager_HasKeyboardEvent = __InputManager.kbdKeyCode <> _ASC_NUL
END FUNCTION

''' @brief Returns the last key read by the input manager. But does not consume the key.
''' @return The last key read by the input manager. Or 0 is no key was read.
FUNCTION InputManager_PeekKeyboardKey&
    SHARED __InputManager AS __InputManager
    InputManager_PeekKeyboardKey = __InputManager.kbdKeyCode
END FUNCTION

''' @brief Returns the last key read by the input manager and consumes the key.
''' @return The last key read by the input manager. Or 0 is no key was read.
FUNCTION InputManager_GetKeyboardKey&
    SHARED __InputManager AS __InputManager
    InputManager_GetKeyboardKey = __InputManager.kbdKeyCode
    __InputManager.kbdKeyCode = _ASC_NUL
END FUNCTION

''' @brief Returns true if a mouse event is waiting to be processed.
''' @return True if a mouse event is waiting to be processed.
FUNCTION InputManager_HasMouseEvent%%
    SHARED __InputManager AS __InputManager
    InputManager_HasMouseEvent = __InputManager.isMouseEvent
END FUNCTION

''' @brief Returns the mouse X position.
''' @return The mouse X position.
FUNCTION InputManager_GetMousePositionX&
    SHARED __InputManager AS __InputManager
    InputManager_GetMousePositionX = __InputManager.mse.position.x
END FUNCTION

''' @brief Returns the mouse Y position.
''' @return The mouse Y position.
FUNCTION InputManager_GetMousePositionY&
    SHARED __InputManager AS __InputManager
    InputManager_GetMousePositionY = __InputManager.mse.position.y
END FUNCTION

''' @brief Returns the mouse position.
''' @param position The x and y position in a Vector2i.
SUB InputManager_GetMousePosition (position AS Vector2i)
    SHARED __InputManager AS __InputManager
    position = __InputManager.mse.position
END SUB

''' @brief Returns true if the left mouse button is down. But does not consume the button.
''' @return True if the left mouse button is down.
FUNCTION InputManager_IsMouseLeftButtonDown%%
    SHARED __InputManager AS __InputManager
    InputManager_IsMouseLeftButtonDown = __InputManager.mse.leftButtonDown
END FUNCTION

''' @brief Returns true if the right mouse button is down. But does not consume the button.
''' @return True if the right mouse button is down.
FUNCTION InputManager_IsMouseRightButtonDown%%
    SHARED __InputManager AS __InputManager
    InputManager_IsMouseRightButtonDown = __InputManager.mse.rightButtonDown
END FUNCTION

''' @brief Returns true if the center mouse button is down. But does not consume the button.
''' @return True if the center mouse button is down.
FUNCTION InputManager_IsMouseCenterButtonDown%%
    SHARED __InputManager AS __InputManager
    InputManager_IsMouseCenterButtonDown = __InputManager.mse.centerButtonDown
END FUNCTION

''' @brief Returns the mouse scroll wheel value.
''' @return The mouse scroll wheel value.
FUNCTION InputManager_GetMouseScrollWheelValue&
    SHARED __InputManager AS __InputManager
    InputManager_GetMouseScrollWheelValue = __InputManager.mse.scrollWheelValue
END FUNCTION

''' @brief Return true if the left mouse button was pressed and released.
''' @return True if the left mouse button was pressed and released.
FUNCTION InputManager_IsMouseLeftButtonClicked%%
    SHARED __InputManager AS __InputManager
    InputManager_IsMouseLeftButtonClicked = __InputManager.mse.leftButtonClicked
END FUNCTION

''' @brief Gets the bounding box where the left mouse button was pressed and released.
''' @param bounds The bounding box where the left mouse button was pressed and released.
SUB InputManager_GetMouseLeftClickBounds (bounds AS Bounds2i)
    SHARED __InputManager AS __InputManager
    bounds = __InputManager.mse.leftButtonClickedBounds
END SUB

''' @brief Return true if the right mouse button was pressed and released.
''' @return True if the right mouse button was pressed and released.
FUNCTION InputManager_IsMouseRightButtonClicked%%
    SHARED __InputManager AS __InputManager
    InputManager_IsMouseRightButtonClicked = __InputManager.mse.rightButtonClicked
END FUNCTION

''' @brief Gets the bounding box where the right mouse button was pressed and released.
''' @param bounds The bounding box where the right mouse button was pressed and released.
SUB InputManager_GetMouseRightClickBounds (bounds AS Bounds2i)
    SHARED __InputManager AS __InputManager
    bounds = __InputManager.mse.rightButtonClickedBounds
END SUB

''' @brief Return true if the center mouse button was pressed and released.
''' @return True if the center mouse button was pressed and released.
FUNCTION InputManager_IsMouseCenterButtonClicked%%
    SHARED __InputManager AS __InputManager
    InputManager_IsMouseCenterButtonClicked = __InputManager.mse.centerButtonClicked
END FUNCTION

''' @brief Gets the bounding box where the center mouse button was pressed and released.
''' @param bounds The bounding box where the center mouse button was pressed and released.
SUB InputManager_GetMouseCenterClickBounds (bounds AS Bounds2i)
    SHARED __InputManager AS __InputManager
    bounds = __InputManager.mse.centerButtonClickedBounds
END SUB

''' @brief Returns true if a window event is waiting to be processed.
''' @return True if a window event is waiting to be processed.
FUNCTION InputManager_HasWindowEvent%%
    SHARED __InputManager AS __InputManager
    InputManager_HasWindowEvent = __InputManager.isWindowEvent
END FUNCTION

''' @brief Returns true if the window should close.
''' @return True if the window should close.
FUNCTION InputManager_WindowShouldClose%%
    SHARED __InputManager AS __InputManager
    InputManager_WindowShouldClose = __InputManager.win.shouldClose
END FUNCTION

''' @brief Sets the window should close flag.
''' @param shouldClose True if the window should close.
SUB InputManager_SetWindowShouldClose (shouldClose AS _BYTE)
    SHARED __InputManager AS __InputManager
    __InputManager.win.shouldClose = shouldClose
END SUB

''' @brief Returns true if the window was resized.
''' @return True if the window was resized.
FUNCTION InputManager_WasWindowResized%%
    SHARED __InputManager AS __InputManager
    InputManager_WasWindowResized = __InputManager.win.resized
END FUNCTION

''' @brief Return the new window width.
''' @return The new window width.
FUNCTION InputManager_GetWindowResizeWidth&
    SHARED __InputManager AS __InputManager
    InputManager_GetWindowResizeWidth = __InputManager.win.size.x
END FUNCTION

''' @brief Return the new window height.
''' @return The new window height.
FUNCTION InputManager_GetWindowResizeHeight&
    SHARED __InputManager AS __InputManager
    InputManager_GetWindowResizeHeight = __InputManager.win.size.y
END FUNCTION

''' @brief Gets the window size.
''' @param size The window size.
SUB InputManager_GetWindowResizeSize (size AS Vector2i)
    SHARED __InputManager AS __InputManager
    size = __InputManager.win.size
END SUB

''' @brief Returns true if a gamepad event is waiting to be processed.
''' @return True if a gamepad event is waiting to be processed.
FUNCTION InputManager_HasGamepadEvent%%
    SHARED __InputManager AS __InputManager
    InputManager_HasGamepadEvent = __InputManager.isGamepad1Event _ORELSE __InputManager.isGamepad2Event
END FUNCTION

''' @brief Returns true if a gamepad 1 event is waiting to be processed.
''' @return True if a gamepad 1 event is waiting to be processed.
FUNCTION InputManager_HasGamepad1Event%%
    SHARED __InputManager AS __InputManager
    InputManager_HasGamepad1Event = __InputManager.isGamepad1Event
END FUNCTION

''' @brief Returns true if a gamepad 2 event is waiting to be processed.
''' @return True if a gamepad 2 event is waiting to be processed.
FUNCTION InputManager_HasGamepad2Event%%
    SHARED __InputManager AS __InputManager
    InputManager_HasGamepad2Event = __InputManager.isGamepad2Event
END FUNCTION

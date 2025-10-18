$INCLUDEONCE

'$INCLUDE:'InputManager.bi'

''' @brief Updates the input manager internals and collects events and inputs by polling various functions.
''' Run this once in the main loop and then use the other API to react to events.
SUB InputManager_Update
    SHARED __InputManager AS __InputManagerType
    STATIC AS _BYTE mouseLeftButtonDown, mouseCenterButtonDown, mouseRightButtonDown ' keeps track if the mouse buttons were held down

    ' Clear some flags and previous states
    __InputManager.isWindowEvent = _FALSE
    __InputManager.isMouseEvent = _FALSE
    __InputManager.mouseScrollWheel = 0

    ' Get keyboard input from the keyboard buffer
    __InputManager.keyboardKeyCode = _KEYHIT

    ' Collect mouse input
    DO WHILE _MOUSEINPUT
        __InputManager.isMouseEvent = _TRUE

        __InputManager.mousePosition.x = _MOUSEX
        __InputManager.mousePosition.y = _MOUSEY

        __InputManager.mouseLeftButtonDown = _MOUSEBUTTON(1)
        __InputManager.mouseRightButtonDown = _MOUSEBUTTON(2)
        __InputManager.mouseCenterButtonDown = _MOUSEBUTTON(3)

        ' Just calculate the net displacement
        __InputManager.mouseScrollWheel = __InputManager.mouseScrollWheel + _MOUSEWHEEL

        ' Check if the left mouse button was previously held down and update the up position if released
        IF NOT __InputManager.mouseLeftButtonDown _ANDALSO mouseLeftButtonDown THEN
            mouseLeftButtonDown = _FALSE
            __InputManager.mouseLeftButtonClickedRectangle.b = __InputManager.mousePosition
            __InputManager.mouseLeftButtonClicked = _TRUE
        END IF

        ' Check if the right mouse button was previously held down and update the up position if released
        IF NOT __InputManager.mouseRightButtonDown _ANDALSO mouseRightButtonDown THEN
            mouseRightButtonDown = _FALSE
            __InputManager.mouseRightButtonClickedRectangle.b = __InputManager.mousePosition
            __InputManager.mouseRightButtonClicked = _TRUE
        END IF

        ' Check if the center mouse button was previously held down and update the up position if released
        IF NOT __InputManager.mouseCenterButtonDown _ANDALSO mouseCenterButtonDown THEN
            mouseCenterButtonDown = _FALSE
            __InputManager.mouseCenterButtonClickedRectangle.b = __InputManager.mousePosition
            __InputManager.mouseCenterButtonClicked = _TRUE
        END IF

        ' Exit if we have any button up event for the system to process it
        IF __InputManager.mouseLeftButtonClicked _ORELSE __InputManager.mouseRightButtonClicked _ORELSE __InputManager.mouseCenterButtonClicked THEN
            EXIT DO
        END IF

        ' Check if the left mouse button was pressed and update the down position
        IF __InputManager.mouseLeftButtonDown _ANDALSO NOT mouseLeftButtonDown THEN
            mouseLeftButtonDown = _TRUE
            __InputManager.mouseLeftButtonClickedRectangle.a = __InputManager.mousePosition
            __InputManager.mouseLeftButtonClicked = _FALSE
        END IF

        ' Check if the right mouse button was pressed and update the down position
        IF __InputManager.mouseRightButtonDown _ANDALSO NOT mouseRightButtonDown THEN
            mouseRightButtonDown = _TRUE
            __InputManager.mouseRightButtonClickedRectangle.a = __InputManager.mousePosition
            __InputManager.mouseRightButtonClicked = _FALSE
        END IF

        ' Check if the center mouse button was pressed and update the down position
        IF __InputManager.mouseCenterButtonDown _ANDALSO NOT mouseCenterButtonDown THEN
            mouseCenterButtonDown = _TRUE
            __InputManager.mouseCenterButtonClickedRectangle.a = __InputManager.mousePosition
            __InputManager.mouseCenterButtonClicked = _FALSE
        END IF

        ' Exit if we have any button down event for the system to process it
        IF mouseLeftButtonDown _ORELSE mouseRightButtonDown _ORELSE mouseCenterButtonDown THEN
            EXIT DO
        END IF
    LOOP

    ' Gather window events
    IF _RESIZE THEN
        __InputManager.isWindowEvent = _TRUE
        __InputManager.windowResized = _TRUE
        __InputManager.windowSize.x = _RESIZEWIDTH
        __InputManager.windowSize.y = _RESIZEHEIGHT
    END IF

    IF _EXIT THEN
        __InputManager.isWindowEvent = _TRUE
        __InputManager.windowCloseRequested = _TRUE
    END IF
END SUB

''' @brief Returns true if a keyboard event is waiting to be processed.
''' @return True if a keyboard event is waiting to be processed.
FUNCTION InputManager_IsKeyboardEvent%%
    SHARED __InputManager AS __InputManagerType

    InputManager_IsKeyboardEvent = __InputManager.keyboardKeyCode <> _ASC_NUL
END FUNCTION

''' @brief Returns true if a mouse event is waiting to be processed.
''' @return True if a mouse event is waiting to be processed.
FUNCTION InputManager_IsMouseEvent%%
    SHARED __InputManager AS __InputManagerType

    InputManager_IsMouseEvent = __InputManager.isMouseEvent
END FUNCTION

''' @brief Returns true if a window event is waiting to be processed.
''' @return True if a window event is waiting to be processed.
FUNCTION InputManager_IsWindowEvent%%
    SHARED __InputManager AS __InputManagerType

    InputManager_IsWindowEvent = __InputManager.isWindowEvent
END FUNCTION

''' @brief Returns the last key read by the input manager. But does not consume the key.
''' @return The last key read by the input manager. Or 0 is no key was read.
FUNCTION InputManager_PeekKeyboardKey&
    SHARED __InputManager AS __InputManagerType

    InputManager_PeekKeyboardKey = __InputManager.keyboardKeyCode
END FUNCTION

''' @brief Returns the last key read by the input manager and consumes the key.
''' @return The last key read by the input manager. Or 0 is no key was read.
FUNCTION InputManager_GetKeyboardKey&
    SHARED __InputManager AS __InputManagerType

    InputManager_GetKeyboardKey = __InputManager.keyboardKeyCode
    __InputManager.keyboardKeyCode = _ASC_NUL
END FUNCTION

''' @brief Returns the mouse X position.
''' @return The mouse X position.
FUNCTION InputManager_GetMousePositionX&
    SHARED __InputManager AS __InputManagerType

    InputManager_GetMousePositionX = __InputManager.mousePosition.x
END FUNCTION

''' @brief Returns the mouse Y position.
''' @return The mouse Y position.
FUNCTION InputManager_GetMousePositionY&
    SHARED __InputManager AS __InputManagerType

    InputManager_GetMousePositionY = __InputManager.mousePosition.y
END FUNCTION

''' @brief Returns the mouse position.
''' @param position The x and y position in a Vector2D.
SUB InputManager_GetMousePosition (position AS InputManager_Vector2DType)
    SHARED __InputManager AS __InputManagerType

    position = __InputManager.mousePosition
END SUB

''' @brief Returns true if the left mouse button is down. But does not consume the button.
''' @return True if the left mouse button is down.
FUNCTION InputManager_IsMouseLeftButtonDown%%
    SHARED __InputManager AS __InputManagerType

    InputManager_IsMouseLeftButtonDown = __InputManager.mouseLeftButtonDown
END FUNCTION

''' @brief Returns true if the right mouse button is down. But does not consume the button.
''' @return True if the right mouse button is down.
FUNCTION InputManager_IsMouseRightButtonDown%%
    SHARED __InputManager AS __InputManagerType

    InputManager_IsMouseRightButtonDown = __InputManager.mouseRightButtonDown
END FUNCTION

''' @brief Returns true if the center mouse button is down. But does not consume the button.
''' @return True if the center mouse button is down.
FUNCTION InputManager_IsMouseCenterButtonDown%%
    SHARED __InputManager AS __InputManagerType

    InputManager_IsMouseCenterButtonDown = __InputManager.mouseCenterButtonDown
END FUNCTION

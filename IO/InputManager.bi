$INCLUDEONCE

OPTION _EXPLICIT

TYPE InputManager_Vector2DType
    x AS LONG
    y AS LONG
END TYPE

TYPE InputManager_Rectangle2DType
    a AS InputManager_Vector2DType
    b AS InputManager_Vector2DType
END TYPE

TYPE __InputManagerType
    keyboardKeyCode AS LONG
    isMouseEvent AS _BYTE
    mousePosition AS InputManager_Vector2DType
    mouseLeftButtonDown AS _BYTE
    mouseRightButtonDown AS _BYTE
    mouseCenterButtonDown AS _BYTE
    mouseScrollWheel AS LONG
    mouseLeftButtonClicked AS _BYTE
    mouseLeftButtonClickedRectangle AS InputManager_Rectangle2DType
    mouseRightButtonClicked AS _BYTE
    mouseRightButtonClickedRectangle AS InputManager_Rectangle2DType
    mouseCenterButtonClicked AS _BYTE
    mouseCenterButtonClickedRectangle AS InputManager_Rectangle2DType
    isWindowEvent AS _BYTE
    windowCloseRequested AS _BYTE
    windowResized AS _BYTE
    windowSize AS InputManager_Vector2DType
END TYPE

DIM __InputManager AS __InputManagerType

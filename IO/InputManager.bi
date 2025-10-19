$INCLUDEONCE

OPTION _EXPLICIT

'$INCLUDE:'../Math/Vector2i.bi'


TYPE InputManager_Rectangle2DType
    a AS Vector2i
    b AS Vector2i
END TYPE

TYPE __InputManagerType
    keyboardKeyCode AS LONG
    isMouseEvent AS _BYTE
    mousePosition AS Vector2i
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
    windowSize AS Vector2i
END TYPE

DIM __InputManager AS __InputManagerType

'-----------------------------------------------------------------------------------------------------------------------
' C Runtime Library bindings + low level support functions
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'CRTLib.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If CRTLIB_BAS = UNDEFINED Then
    $Let CRTLIB_BAS = TRUE

    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
    ' Returns a BASIC string (bstring) from a NULL terminated C string (cstring) pointer
    Function CStrPtrToBStr$ (cStrPtr As _Offset)
        If cStrPtr <> NULL Then
            Dim bufferSize As Long: bufferSize = StrLen(cStrPtr)

            If bufferSize > 0 Then
                Dim buffer As String: buffer = String$(bufferSize + 1, NULL)

                StrNCpy _Offset(buffer), cStrPtr, bufferSize

                CStrPtrToBStr = Left$(buffer, bufferSize)
            End If
        End If
    End Function


    ' Returns a BASIC string (bstring) from NULL terminated C string (cstring)
    Function CStrToBStr$ (cStr As String)
        Dim zeroPos As Long: zeroPos = InStr(cStr, Chr$(NULL))
        If zeroPos > 0 Then CStrToBStr = Left$(cStr, zeroPos - 1) Else CStrToBStr = cStr
    End Function


    ' Just a convenience function for use when calling external libraries
    Function BStrToCStr$ (bStr As String)
        BStrToCStr = bStr + Chr$(NULL)
    End Function
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------

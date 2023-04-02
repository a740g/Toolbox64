'-----------------------------------------------------------------------------------------------------------------------
' Program arguments parsing library
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'Common.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If PROGRAMARGUMENTS_BAS = UNDEFINED Then
    $Let PROGRAMARGUMENTS_BAS = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' Small test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    '$Debug
    'Print "Program executable path name is:"
    'Print GetProgramExecutablePathName
    'Print

    'Dim As Long argName, argIndex: argIndex = 1 ' start with the first argument

    'Do
    '    argName = GetProgramArgument("whbsx", argIndex)

    '    Select Case argName
    '        Case -1
    '            Exit Do

    '        Case KEY_LOWER_W
    '            argIndex = argIndex + 1 ' value at next index
    '            Print "width = "; Command$(argIndex)

    '        Case KEY_LOWER_H
    '            argIndex = argIndex + 1 ' value at next index
    '            Print "height = "; Command$(argIndex)

    '        Case KEY_LOWER_B
    '            argIndex = argIndex + 1 ' value at next index
    '            Print "bpp = "; Command$(argIndex)

    '        Case KEY_LOWER_S
    '            Print "Silent operation"

    '        Case KEY_LOWER_X
    '            Print "Secret x argument found!"

    '        Case Else
    '            Print "Handle "; Command$(argIndex)
    '    End Select

    '    argIndex = argIndex + 1 ' move to the next index
    'Loop Until argName = -1

    'argIndex = GetProgramArgumentIndex(KEY_LOWER_X)

    'If argIndex > 0 Then
    '    Print "Secret x argument found!"
    'End If

    'End
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
    ' This works like a really simple version of getopt
    ' arguments is a string containing a list of valid arguments (e.g. "gensda") where each character is a argument name
    ' argumentIndex is the index where the function should check
    ' Returns the ASCII value of the argument name found at index. 0 if something else was found. -1 if end of list was reached
    Function GetProgramArgument% (arguments As String, argumentIndex As Long)
        Dim currentArgument As String, argument As Unsigned Byte

        If argumentIndex > CommandCount Then ' we've reached the end
            GetProgramArgument = -1 ' signal end of arguments
            Exit Function
        End If

        currentArgument = Command$(argumentIndex) ' get the argument at index

        If Len(currentArgument) = 2 Then ' proceed only if we have 2 characters at index
            argument = Asc(currentArgument, 2)

            If (KEY_SLASH = Asc(currentArgument, 1) Or KEY_MINUS = Asc(currentArgument, 1)) And Not FileExists(currentArgument) And Not DirExists(currentArgument) And InStr(arguments, Chr$(argument)) > 0 Then
                GetProgramArgument = argument ' return the argument name
                Exit Function ' avoid "unknown" path below
            End If
        End If

        GetProgramArgument = NULL ' signal we have something unknown
    End Function


    ' Checks if a parameter is present in the command line
    ' Returns the position of the argument or -1 if it was not found
    Function GetProgramArgumentIndex& (argument As Unsigned Byte)
        Dim i As Long, currentArgument As String

        For i = 1 To CommandCount
            currentArgument = Command$(i)

            If Len(currentArgument) = 2 Then ' proceed only if we have 2 characters at index

                If (KEY_SLASH = Asc(currentArgument, 1) Or KEY_MINUS = Asc(currentArgument, 1)) And Not FileExists(currentArgument) And Not DirExists(currentArgument) And Asc(currentArgument, 2) = argument Then
                    GetProgramArgumentIndex = i
                    Exit Function
                End If
            End If
        Next

        GetProgramArgumentIndex = -1 ' return invalid index
    End Function


    ' Returns the running executable's path name
    Function GetProgramExecutablePathName$
        GetProgramExecutablePathName = Command$(NULL)
    End Function
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------


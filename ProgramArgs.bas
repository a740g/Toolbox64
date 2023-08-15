'-----------------------------------------------------------------------------------------------------------------------
' Program arguments parsing library
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF PROGRAMARGS_BAS = UNDEFINED THEN
    $LET PROGRAMARGS_BAS = TRUE

    '$INCLUDE:'Common.bi'
    '$INCLUDE:'Types.bi'

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

    ' This works like a really simple version of getopt
    ' arguments is a string containing a list of valid arguments (e.g. "gensda") where each character is an argument name
    ' argumentIndex is the index where the function should check
    ' Returns the ASCII value of the argument name found at index. 0 if something else was found. -1 if end of list was reached
    FUNCTION GetProgramArgument% (arguments AS STRING, argumentIndex AS LONG)
        DIM currentArgument AS STRING, argument AS _UNSIGNED _BYTE

        IF argumentIndex > _COMMANDCOUNT THEN ' we've reached the end
            GetProgramArgument = -1 ' signal end of arguments
            EXIT FUNCTION
        END IF

        currentArgument = COMMAND$(argumentIndex) ' get the argument at index

        IF LEN(currentArgument) = 2 THEN ' proceed only if we have 2 characters at index
            argument = ASC(currentArgument, 2)

            IF (KEY_SLASH = ASC(currentArgument, 1) OR KEY_MINUS = ASC(currentArgument, 1)) AND NOT _FILEEXISTS(currentArgument) AND NOT _DIREXISTS(currentArgument) AND INSTR(arguments, CHR$(argument)) > 0 THEN
                GetProgramArgument = argument ' return the argument name
                EXIT FUNCTION ' avoid "unknown" path below
            END IF
        END IF

        GetProgramArgument = NULL ' signal we have something unknown
    END FUNCTION


    ' Checks if a parameter is present in the command line
    ' Returns the position of the argument or -1 if it was not found
    FUNCTION GetProgramArgumentIndex& (argument AS _UNSIGNED _BYTE)
        DIM i AS LONG, currentArgument AS STRING

        FOR i = 1 TO _COMMANDCOUNT
            currentArgument = COMMAND$(i)

            IF LEN(currentArgument) = 2 THEN ' proceed only if we have 2 characters at index

                IF (KEY_SLASH = ASC(currentArgument, 1) OR KEY_MINUS = ASC(currentArgument, 1)) AND NOT _FILEEXISTS(currentArgument) AND NOT _DIREXISTS(currentArgument) AND ASC(currentArgument, 2) = argument THEN
                    GetProgramArgumentIndex = i
                    EXIT FUNCTION
                END IF
            END IF
        NEXT

        GetProgramArgumentIndex = -1 ' return invalid index
    END FUNCTION


    ' Returns the running executable's path name
    FUNCTION GetProgramExecutablePathName$
        GetProgramExecutablePathName = COMMAND$(NULL)
    END FUNCTION

$END IF

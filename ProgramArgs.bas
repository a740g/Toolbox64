'-----------------------------------------------------------------------------------------------------------------------
' Program arguments parsing library
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'
'$INCLUDE:'Types.bi'

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'$DEBUG
'PRINT "Program executable path name is:"
'PRINT GetProgramExecutablePathName
'PRINT

'DIM AS LONG argName, argIndex: argIndex = 1 ' start with the first argument

'DO
'    argName = GetProgramArgument("whbsx", argIndex)

'    SELECT CASE argName
'        CASE -1
'            EXIT DO

'        CASE KEY_LOWER_W
'            argIndex = argIndex + 1 ' value at next index
'            PRINT "width = "; COMMAND$(argIndex)

'        CASE KEY_LOWER_H
'            argIndex = argIndex + 1 ' value at next index
'            PRINT "height = "; COMMAND$(argIndex)

'        CASE KEY_LOWER_B
'            argIndex = argIndex + 1 ' value at next index
'            PRINT "bpp = "; COMMAND$(argIndex)

'        CASE KEY_LOWER_S
'            PRINT "Silent operation"

'        CASE KEY_LOWER_X
'            PRINT "Secret x argument found!"

'        CASE ELSE
'            PRINT "Handle "; COMMAND$(argIndex)
'    END SELECT

'    argIndex = argIndex + 1 ' move to the next index
'LOOP UNTIL argName = -1

'argIndex = GetProgramArgumentIndex(KEY_LOWER_X)

'IF argIndex > 0 THEN
'    PRINT "Secret x argument found!"
'END IF

'END
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

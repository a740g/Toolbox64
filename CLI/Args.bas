'-----------------------------------------------------------------------------------------------------------------------
' Program arguments parsing library
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Common.bi'

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'OPTION _EXPLICIT
'PRINT "Program executable path name is:"
'PRINT Args_GetExecutablePathName$
'PRINT

'DIM argName AS STRING
'DIM AS LONG argIndex: argIndex = 1 ' start with the first argument

'DO
'    argName = Args_GetArgumentName("w|width|h|height|b|bpp|s|silent|x", argIndex)
'    SELECT CASE argName
'        CASE _STR_EMPTY
'            EXIT DO

'        CASE "w", "width"
'            argIndex = argIndex + 1 ' value at next index
'            PRINT "width = "; COMMAND$(argIndex)

'        CASE "h", "height"
'            argIndex = argIndex + 1 ' value at next index
'            PRINT "height = "; COMMAND$(argIndex)

'        CASE "b", "bpp"
'            argIndex = argIndex + 1 ' value at next index
'            PRINT "bpp = "; COMMAND$(argIndex)

'        CASE "s", "silent"
'            PRINT "Silent operation"

'        CASE "x"
'            PRINT "Secret x argument found!"

'        CASE ELSE
'            PRINT "Handle "; COMMAND$(argIndex)
'    END SELECT

'    argIndex = argIndex + 1 ' move to the next index
'LOOP WHILE LEN(argName)

'argIndex = Args_GetArgumentIndex("x")

'IF argIndex > 0 THEN
'    PRINT "Secret x argument found!"
'END IF

'END
'-------------------------------------------------------------------------------------------------------------------

''' @brief Extracts the argument name from a raw argument string.
''' @param rawArg The raw argument string (e.g., "-width", "/h", "--silent").
''' @return The extracted argument name in lowercase (e.g., "width", "h", "silent").
'''         Returns an empty string if the argument does not have a valid name prefix
'''         or if it corresponds to an existing file or directory.
FUNCTION __Args_ExtractName$ (rawArg AS STRING)
    DIM n AS _UNSIGNED LONG: n = LEN(rawArg)
    IF n THEN
        IF _FILEEXISTS(rawArg) _ORELSE _DIREXISTS(rawArg) THEN
            EXIT FUNCTION
        END IF

        DIM pfx AS _UNSIGNED LONG

        SELECT CASE ASC(rawArg, 1)
            CASE _ASC_MINUS
                IF n >= 2 _ANDALSO ASC(rawArg, 2) = _ASC_MINUS THEN
                    pfx = 2
                ELSE
                    pfx = 1
                END IF

            CASE _ASC_FORWARDSLASH
                pfx = 1
        END SELECT

        IF pfx THEN
            DIM startPos AS LONG: startPos = pfx + 1
            IF startPos > n THEN
                EXIT FUNCTION
            END IF

            DIM rest AS STRING: rest = LCASE$(_TRIM$(MID$(rawArg, startPos)))

            __Args_ExtractName = rest
        END IF
    END IF
END FUNCTION

''' @brief Checks if an argument name is allowed.
''' @param allowedList A pipe-separated list of allowed argument names (e.g., "w|width|h|height").
''' @param argName The argument name to check.
''' @return _TRUE if the argument name is in the allowed list; otherwise, _FALSE.
FUNCTION __Args_IsAllowed%% (allowedList AS STRING, argName AS STRING)
    IF LEN(argName) THEN
        __Args_IsAllowed = INSTR("|" + LCASE$(allowedList) + "|", "|" + LCASE$(argName) + "|") > 0
    END IF
END FUNCTION

''' @brief Returns the argument name at argIndex if valid and present in allowedList.
''' @param allowedList A pipe-separated list of allowed argument names (e.g., "w|width|h|height").
''' @param argIndex The index of the argument to retrieve.
''' @return The argument name if valid and allowed; otherwise, the raw argument or an empty string if the end has been reached.
FUNCTION Args_GetArgumentName$ (allowedList AS STRING, argIndex AS LONG)
    IF argIndex <= _COMMANDCOUNT THEN
        DIM rawArg AS STRING: rawArg = COMMAND$(argIndex)
        DIM argName AS STRING: argName = __Args_ExtractName$(rawArg)

        Args_GetArgumentName = _IIF(LEN(argName) _ANDALSO __Args_IsAllowed(allowedList, argName), argName, rawArg)
    END IF
END FUNCTION

''' @brief Returns the index of the argument with the specified name.
''' @param argName The name of the argument to search for.
''' @return The index of the argument if found; otherwise, -1.
FUNCTION Args_GetArgumentIndex& (argName AS STRING)
    DIM needle AS STRING: needle = LCASE$(argName)
    IF LEN(needle) THEN
        DIM AS STRING rawArg, n
        DIM i AS LONG
        FOR i = 1 TO _COMMANDCOUNT
            rawArg = COMMAND$(i)
            n = __Args_ExtractName(rawArg)
            IF LEN(n) _ANDALSO LCASE$(n) = needle THEN
                Args_GetArgumentIndex = i
                EXIT FUNCTION
            END IF
        NEXT
    END IF

    Args_GetArgumentIndex = -1
END FUNCTION

''' @brief Returns the running executable's path name.
''' @return The executable's path name.
FUNCTION Args_GetExecutablePathName$
    Args_GetExecutablePathName = COMMAND$(0)
END FUNCTION

'-----------------------------------------------------------------------------------------------------------------------
' String related routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF STRINGOPS_BAS = UNDEFINED THEN
    $LET STRINGOPS_BAS = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' HEADER FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'StringOps.bi'
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' Test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    'DIM AS STRING myStr1, myStr2

    'myStr1 = "Toolbox64"
    'myStr2 = "Shadow Warrior"

    'PRINT ReverseString(myStr1)
    'ReverseString myStr2
    'PRINT myStr2
    'PRINT myStr1

    'PRINT FormatBoolean(TRUE, 8)
    'PRINT FormatBoolean(FALSE, 8)
    'PRINT FormatLong(&HBE, "%.4X")
    'PRINT FormatInteger64(&HBE, "%.10llu")
    'PRINT FormatSingle(25.78, "%f")
    'PRINT FormatDouble(18.4455, "%f")
    'PRINT FormatOffset(&HDEADBEEFBEEFDEAD, "%p")

    'END
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
    ' Tokenizes a string to a dynamic string array
    ' text - is the input string
    ' delims - is a list of delimiters (multiple delimiters can be specified)
    ' quoteChars - is the string containing the opening and closing "quote" characters. Should be 2 chars only or nothing
    ' returnDelims - if True, then the routine will also return the delimiters in the correct position in the tokens array
    ' tokens() - is the array that will hold the tokens
    ' Returns: the number of tokens parsed
    FUNCTION TokenizeString& (text AS STRING, delims AS STRING, quoteChars AS STRING, returnDelims AS _BYTE, tokens() AS STRING)
        DIM sLen AS LONG: sLen = LEN(text)

        IF sLen = NULL THEN EXIT FUNCTION ' nothing to be done

        DIM arrIdx AS LONG: arrIdx = LBOUND(tokens) ' we'll always start from the array lower bound - whatever it is
        DIM insideQuote AS _BYTE ' flag to track if currently inside a quote

        DIM token AS STRING ' holds a token until it is ready to be added to the array
        DIM char AS STRING * 1 ' this is a single char from text we are iterating through
        DIM AS LONG i, count

        ' Iterate through the characters in the text string
        FOR i = 1 TO sLen
            char = CHR$(ASC(text, i))
            IF insideQuote THEN
                IF char = RIGHT$(quoteChars, 1) THEN
                    ' Closing quote char encountered, resume delimiting
                    insideQuote = FALSE
                    GOSUB add_token ' add the token to the array
                    IF returnDelims THEN GOSUB add_delim ' add the closing quote char as delimiter if required
                ELSE
                    token = token + char ' add the character to the current token
                END IF
            ELSE
                IF char = LEFT$(quoteChars, 1) THEN
                    ' Opening quote char encountered, temporarily stop delimiting
                    insideQuote = TRUE
                    GOSUB add_token ' add the token to the array
                    IF returnDelims THEN GOSUB add_delim ' add the opening quote char as delimiter if required
                ELSEIF INSTR(delims, char) = NULL THEN
                    token = token + char ' add the character to the current token
                ELSE
                    GOSUB add_token ' found a delimiter, add the token to the array
                    IF returnDelims THEN GOSUB add_delim ' found a delimiter, add it to the array if required
                END IF
            END IF
        NEXT

        GOSUB add_token ' add the final token if there is any

        IF count > NULL THEN REDIM _PRESERVE tokens(LBOUND(tokens) TO arrIdx - 1) AS STRING ' resize the array to the exact size

        TokenizeString = count

        EXIT FUNCTION

        ' Add the token to the array if there is any
        add_token:
        IF LEN(token) > NULL THEN
            tokens(arrIdx) = token ' add the token to the token array
            token = EMPTY_STRING ' clear the current token
            GOSUB increment_counters_and_resize_array
        END IF
        RETURN

        ' Add delimiter to array if required
        add_delim:
        tokens(arrIdx) = char ' add delimiter to array
        GOSUB increment_counters_and_resize_array
        RETURN

        ' Increment the count and array index and resize the array if needed
        increment_counters_and_resize_array:
        count = count + 1 ' increment the token count
        arrIdx = arrIdx + 1 ' move to next position
        IF arrIdx > UBOUND(tokens) THEN REDIM _PRESERVE tokens(LBOUND(tokens) TO UBOUND(tokens) + 512) AS STRING ' resize in 512 chunks
        RETURN
    END FUNCTION


    ' Reverses and returns the characters of a string
    FUNCTION ReverseString$ (s AS STRING)
        DIM tmp AS STRING: tmp = s
        ReverseBytes _OFFSET(tmp), LEN(tmp)
        ReverseString = tmp
    END FUNCTION


    ' Reverses the characters of a string in-place
    SUB ReverseString (s AS STRING)
        ReverseBytes _OFFSET(s), LEN(s)
    END SUB


    ' Gets a string form of the boolean value passed
    FUNCTION FormatBoolean$ (n AS LONG, fmt AS LONG)
        SELECT CASE fmt
            CASE 1
                IF n THEN FormatBoolean = "1" ELSE FormatBoolean = "0"
            CASE 2
                IF n THEN FormatBoolean = "-1" ELSE FormatBoolean = "0"
            CASE 3
                IF n THEN FormatBoolean = "On" ELSE FormatBoolean = "Off"
            CASE 4
                IF n THEN FormatBoolean = "Enabled" ELSE FormatBoolean = "Disabled"
            CASE 5
                IF n THEN FormatBoolean = "Enable" ELSE FormatBoolean = "Disable"
            CASE 6
                IF n THEN FormatBoolean = "High" ELSE FormatBoolean = "Low"
            CASE 7
                IF n THEN FormatBoolean = "Opened" ELSE FormatBoolean = "Closed"
            CASE 8
                IF n THEN FormatBoolean = "Open" ELSE FormatBoolean = "Close"
            CASE 9
                IF n THEN FormatBoolean = "Active" ELSE FormatBoolean = "Inactive"
            CASE 10
                IF n THEN FormatBoolean = "Present" ELSE FormatBoolean = "Absent"
            CASE 11
                IF n THEN FormatBoolean = "Engaged" ELSE FormatBoolean = "Disengaged"
            CASE 12
                IF n THEN FormatBoolean = "Engage" ELSE FormatBoolean = "Disengage"
            CASE 13
                IF n THEN FormatBoolean = "Connected" ELSE FormatBoolean = "Disconnected"
            CASE 14
                IF n THEN FormatBoolean = "Connect" ELSE FormatBoolean = "Disconnect"
            CASE 15
                IF n THEN FormatBoolean = "Valid" ELSE FormatBoolean = "Invalid"
            CASE 16
                IF n THEN FormatBoolean = "Up" ELSE FormatBoolean = "Down"
            CASE 17
                IF n THEN FormatBoolean = "Started" ELSE FormatBoolean = "Stopped"
            CASE 18
                IF n THEN FormatBoolean = "Start" ELSE FormatBoolean = "Stop"
            CASE 19
                IF n THEN FormatBoolean = "Available" ELSE FormatBoolean = "Unavailable"
            CASE 20
                IF n THEN FormatBoolean = "In" ELSE FormatBoolean = "Out"
            CASE ELSE
                IF n THEN FormatBoolean = "True" ELSE FormatBoolean = "False"
        END SELECT
    END FUNCTION


    FUNCTION FormatLong$ (n AS LONG, fmt AS STRING)
        FormatLong = __FormatLong(n, ToCString(fmt))
    END FUNCTION


    FUNCTION FormatInteger64$ (n AS _INTEGER64, fmt AS STRING)
        FormatInteger64 = __FormatInteger64(n, ToCString(fmt))
    END FUNCTION


    FUNCTION FormatSingle$ (n AS SINGLE, fmt AS STRING)
        FormatSingle = __FormatSingle(n, ToCString(fmt))
    END FUNCTION


    FUNCTION FormatDouble$ (n AS DOUBLE, fmt AS STRING)
        FormatDouble = __FormatDouble(n, ToCString(fmt))
    END FUNCTION


    FUNCTION FormatOffset$ (n AS _UNSIGNED _OFFSET, fmt AS STRING)
        FormatOffset = __FormatOffset(n, ToCString(fmt))
    END FUNCTION
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' MODULE FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'CRTLib.bas'
    '-------------------------------------------------------------------------------------------------------------------
$END IF
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' String related routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF STRINGOPS_BAS = UNDEFINED THEN
    $LET STRINGOPS_BAS = TRUE
    '-------------------------------------------------------------------------------------------------------------------
    ' HEADER FILES
    '-------------------------------------------------------------------------------------------------------------------
    '$INCLUDE:'CRTLib.bi'
    '-------------------------------------------------------------------------------------------------------------------

    '-------------------------------------------------------------------------------------------------------------------
    ' Test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    'Dim As String myStr1, myStr2

    'myStr1 = "Toolbox64"
    'myStr2 = "Shadow Warrior"

    'Print ReverseString(myStr1)
    'ReverseString myStr2
    'Print myStr2
    'Print myStr1

    'End
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


    ' Gets a string form of the boolean value passed
    FUNCTION BoolToStr$ (expression AS LONG, style AS _UNSIGNED _BYTE)
        SELECT CASE style
            CASE 1
                IF expression THEN BoolToStr = "On" ELSE BoolToStr = "Off"
            CASE 2
                IF expression THEN BoolToStr = "Enabled" ELSE BoolToStr = "Disabled"
            CASE 3
                IF expression THEN BoolToStr = "1" ELSE BoolToStr = "0"
            CASE ELSE
                IF expression THEN BoolToStr = "True" ELSE BoolToStr = "False"
        END SELECT
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
    '-------------------------------------------------------------------------------------------------------------------

$END IF
'-----------------------------------------------------------------------------------------------------------------------

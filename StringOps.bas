'-----------------------------------------------------------------------------------------------------------------------
' String related routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$IF STRINGOPS_BAS = UNDEFINED THEN
    $LET STRINGOPS_BAS = TRUE

    '$INCLUDE:'StringOps.bi'

    '-------------------------------------------------------------------------------------------------------------------
    ' Test code for debugging the library
    '-------------------------------------------------------------------------------------------------------------------
    '$DEBUG
    '$CONSOLE:ONLY
    'DIM AS STRING myStr1, myStr2

    'myStr1 = "Toolbox64"
    'myStr2 = "Shadow Warrior"

    'PRINT ReverseString(myStr1)
    'ReverseString myStr2
    'PRINT myStr2
    'PRINT myStr1

    'PRINT FormatBoolean(TRUE, 20)
    'PRINT FormatBoolean(FALSE, 20)
    'PRINT FormatLong(&HBE, "%.4X")
    'PRINT FormatInteger64(&HBE, "%.10llu")
    'PRINT FormatSingle(25.78, "%f")
    'PRINT FormatDouble(18.4455, "%f")
    'PRINT FormatOffset(&HDEADBEEFBEEFDEAD, "%p")

    'PRINT IsAlphaNumeric(ASC("9"))
    'PRINT IsAlphabetic(ASC("x"))
    'PRINT IsLowerCase(ASC("x"))
    'PRINT IsUpperCase(ASC("X"))
    'PRINT IsDigit(ASC("1"))
    'PRINT IsHexadecimalDigit(ASC("f"))
    'PRINT IsControlCharacter(13)
    'PRINT IsGraphicalCharacter(126)
    'PRINT IsWhiteSpace(9)
    'PRINT IsBlank(9)
    'PRINT IsPrintable(32)
    'PRINT IsPunctuation(ASC("!"))

    'DIM r AS _UNSIGNED _OFFSET: r = RegExCompile("[Hh]ello [Ww]orld\s*[!]?")
    'DIM AS LONG l, n: n = RegExSearchCompiled(r, "ahem.. 'hello world !' ..", 1, l)

    'IF n > 0 THEN
    '    PRINT "Match at"; n; ","; l; "chars long"
    'END IF

    'RegExFree r

    'n = 1
    'DO
    '    n = RegExSearch("b[aeiou]b", "bub bob bib bab", n, l)
    '    IF n > 0 THEN
    '        PRINT "Match at"; n; ","; l; "chars long"
    '        n = n + l
    '    END IF
    'LOOP UNTIL n = 0

    'END
    '-------------------------------------------------------------------------------------------------------------------

    ' Returns a BASIC string (bstring) from a NULL terminated C string (cstring)
    FUNCTION ToBString$ (s AS STRING)
        $CHECKING:OFF
        DIM zeroPos AS LONG: zeroPos = INSTR(s, CHR$(NULL))
        IF zeroPos > NULL THEN ToBString = LEFT$(s, zeroPos - 1) ELSE ToBString = s
        $CHECKING:ON
    END FUNCTION


    ' Just a convenience function for use when calling external libraries
    FUNCTION ToCString$ (s AS STRING)
        $CHECKING:OFF
        ToCString = s + CHR$(NULL)
        $CHECKING:ON
    END FUNCTION


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
        $CHECKING:OFF
        DIM tmp AS STRING: tmp = s
        ReverseMemory _OFFSET(tmp), LEN(tmp)
        ReverseString = tmp
        $CHECKING:ON
    END FUNCTION


    ' Reverses the characters of a string in-place
    SUB ReverseString (s AS STRING)
        $CHECKING:OFF
        ReverseMemory _OFFSET(s), LEN(s)
        $CHECKING:ON
    END SUB


    ' Formats a long using C's printf() format specifier
    FUNCTION FormatLong$ (n AS LONG, fmt AS STRING)
        $CHECKING:OFF
        FormatLong = __FormatLong(n, ToCString(fmt))
        $CHECKING:ON
    END FUNCTION


    ' Formats an integer64 using C's printf() format specifier
    FUNCTION FormatInteger64$ (n AS _INTEGER64, fmt AS STRING)
        $CHECKING:OFF
        FormatInteger64 = __FormatInteger64(n, ToCString(fmt))
        $CHECKING:ON
    END FUNCTION


    ' Formats a single using C's printf() format specifier
    FUNCTION FormatSingle$ (n AS SINGLE, fmt AS STRING)
        $CHECKING:OFF
        FormatSingle = __FormatSingle(n, ToCString(fmt))
        $CHECKING:ON
    END FUNCTION


    ' Formats a double using C's printf() format specifier
    FUNCTION FormatDouble$ (n AS DOUBLE, fmt AS STRING)
        $CHECKING:OFF
        FormatDouble = __FormatDouble(n, ToCString(fmt))
        $CHECKING:ON
    END FUNCTION


    ' Formats an offset using C's printf() format specifier
    FUNCTION FormatOffset$ (n AS _UNSIGNED _OFFSET, fmt AS STRING)
        $CHECKING:OFF
        FormatOffset = __FormatOffset(n, ToCString(fmt))
        $CHECKING:ON
    END FUNCTION


    ' Compiles a regex for quick usage with different stings via RegExMatchCompiled()
    FUNCTION RegExCompile~%& (pattern AS STRING)
        $CHECKING:OFF
        RegExCompile = __RegExCompile(ToCString(pattern))
        $CHECKING:ON
    END FUNCTION


    ' Does a regex search for a string using a compiled pattern
    FUNCTION RegExSearchCompiled& (pattern AS _UNSIGNED _OFFSET, text AS STRING, startPos AS LONG, matchLength AS LONG)
        $CHECKING:OFF
        IF startPos > 0 AND startPos <= LEN(text) THEN
            DIM i AS LONG: i = __RegExSearchCompiled(pattern, ToCString(text), startPos, matchLength)
            IF i > -1 THEN RegExSearchCompiled = i + startPos ELSE RegExSearchCompiled = i
        END IF
        $CHECKING:ON
    END FUNCTION


    ' Does a regex search for a string using a pattern string
    FUNCTION RegExSearch& (pattern AS STRING, text AS STRING, startPos AS LONG, matchLength AS LONG)
        $CHECKING:OFF
        IF startPos > 0 AND startPos <= LEN(text) THEN
            DIM i AS LONG: i = __RegExSearch(ToCString(pattern), ToCString(text), startPos, matchLength)
            IF i > -1 THEN RegExSearch = i + startPos ELSE RegExSearch = i
        END IF
        $CHECKING:ON
    END FUNCTION


    ' Checks if `text` is a RegEx match using a compiled pattern
    FUNCTION RegExMatchCompiled%% (pattern AS _UNSIGNED _OFFSET, text AS STRING)
        $CHECKING:OFF
        RegExMatchCompiled = __RegExMatchCompiled(pattern, ToCString(text))
        $CHECKING:ON
    END FUNCTION


    ' Checks if `text` is a RegEx match using a pattern string
    FUNCTION RegExMatch%% (pattern AS STRING, text AS STRING)
        $CHECKING:OFF
        RegExMatch = __RegExMatch(ToCString(pattern), ToCString(text))
        $CHECKING:ON
    END FUNCTION

$END IF

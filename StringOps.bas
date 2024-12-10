'-----------------------------------------------------------------------------------------------------------------------
' String related routines
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'StringOps.bi'

'-----------------------------------------------------------------------------------------------------------------------
' Test code for debugging the library
'-----------------------------------------------------------------------------------------------------------------------
'$DEBUG
'$CONSOLE:ONLY

'PRINT STRING_NULL

'PRINT String_ToCStr("abcd") + "<END", LEN(String_ToCStr("abcd"))

'PRINT String_Filter("Hello, -234.234world!", "+-01234567890.", FALSE) + "<END"
'PRINT String_Filter("Hello,-234.234 world!", "+-01234567890.", TRUE) + "<END"

'PRINT String_FormatBoolean(TRUE, 20)
'PRINT String_FormatBoolean(FALSE, 20)
'PRINT String_FormatLong(&HBE, "%.4X")
'PRINT String_FormatInteger64(&HBE, "%.10llu")
'PRINT String_FormatSingle(25.78, "%f")
'PRINT String_FormatDouble(18.4455, "%f")
'PRINT String_FormatOffset(&HDEADBEEFBEEFDEAD, "%p")
'PRINT String_FormatString("hello", "----%s----")
'PRINT String_FormatLong(0, "%.4X")

'PRINT String_RemoveEnclosingPair("(hello + (2 * 5) - world)", "()")

'PRINT STRING_QUOTE + "Hello, world" + STRING_QUOTE + STRING_LF + "Greetings!"

'DIM AS STRING myStr1, myStr2

'myStr1 = "Toolbox64"
'myStr2 = "Shadow Warrior"

'PRINT String_Reverse(myStr1)
'String_Reverse myStr2
'PRINT myStr2
'PRINT myStr1

'PRINT String_IsAlphaNumeric(ASC("9"))
'PRINT String_IsAlphabetic(ASC("x"))
'PRINT String_IsLowerCase(ASC("x"))
'PRINT String_IsUpperCase(ASC("X"))
'PRINT String_IsDigit(ASC("1"))
'PRINT String_IsHexadecimalDigit(ASC("f"))
'PRINT String_IsControlCharacter(13)
'PRINT String_IsGraphicalCharacter(126)
'PRINT String_IsWhiteSpace(9)
'PRINT String_IsBlank(9)
'PRINT String_IsPrintable(32)
'PRINT String_IsPunctuation(ASC("!"))

'DIM r AS _UNSIGNED _OFFSET: r = String_RegExCompile("[Hh]ello [Ww]orld\s*[!]?")
'DIM AS LONG l, n: n = String_RegExSearchCompiled(r, "ahem.. 'hello world !' ..", 1, l)

'IF n > 0 THEN
'    PRINT "Match at"; n; ","; l; "chars long"
'END IF

'String_RegExFree r

'n = 1
'DO
'    n = String_RegExSearch("b[aeiou]b", "bub bob bib bab", n, l)
'    IF n > 0 THEN
'        PRINT "Match at"; n; ","; l; "chars long"
'        n = n + l
'    END IF
'LOOP UNTIL n = 0

'myStr1 = String_GetToken("x = sin(0.9) + cos(0.5)", " ")

'DO
'    PRINT myStr1
'    myStr1 = String_GetToken(STRING_EMPTY, " ")
'LOOP UNTIL LEN(myStr1) = NULL

'END
'-----------------------------------------------------------------------------------------------------------------------

' Returns a BASIC string (bstring) from a NULL terminated C string (cstring)
FUNCTION String_ToBStr$ (s AS STRING)
    $CHECKING:OFF
    DIM zeroPos AS LONG: zeroPos = INSTR(s, CHR$(NULL))
    IF zeroPos > NULL THEN String_ToBStr = LEFT$(s, zeroPos - 1) ELSE String_ToBStr = s
    $CHECKING:ON
END FUNCTION


' Just a convenience function for use when calling external libraries
FUNCTION String_ToCStr$ (s AS STRING)
    $CHECKING:OFF
    String_ToCStr = s + CHR$(NULL)
    $CHECKING:ON
END FUNCTION


' Cleans text of control characters and makes it printable
FUNCTION String_MakePrintable$ (text AS STRING)
    DIM buffer AS STRING: buffer = SPACE$(LEN(text))

    $CHECKING:OFF
    DIM i AS _UNSIGNED LONG: WHILE i < LEN(text)
        DIM c AS _UNSIGNED _BYTE: c = PeekStringByte(text, i)

        IF c > KEY_SPACE THEN PokeStringByte buffer, i, c

        i = i + 1
    WEND
    $CHECKING:ON

    String_MakePrintable = buffer
END FUNCTION


' Returns true if text has a certain enclosing pair like 'hello'
FUNCTION String_HasEnclosingPair%% (text AS STRING, pair AS STRING)
    $CHECKING:OFF
    IF LEN(text) > 1 AND LEN(pair) > 1 THEN
        String_HasEnclosingPair = (PeekStringByte(pair, 0) = PeekStringByte(text, 0) AND PeekStringByte(pair, 1) = PeekStringByte(text, LEN(text) - 1))
    END IF
    $CHECKING:ON
END FUNCTION


' Removes a string's enclosing pair if it is found. So, 'hello world' can be returned as just hello world
' pair - is the enclosing pair. E.g. "''", "()", "[]" etc.
FUNCTION String_RemoveEnclosingPair$ (text AS STRING, pair AS STRING)
    IF String_HasEnclosingPair(text, pair) THEN
        String_RemoveEnclosingPair = MID$(text, 2, LEN(text) - 2)
    ELSE
        String_RemoveEnclosingPair = text
    END IF
END FUNCTION


' Tokenizes a string to a dynamic string array
' text - is the input string
' delims - is a list of delimiters (multiple delimiters can be specified)
' quoteChars - is the string containing the opening and closing "quote" characters. Should be 2 chars only or nothing
' returnDelims - if True, then the routine will also return the delimiters in the correct position in the tokens array
' tokens() - is the array that will hold the tokens
' Returns: the number of tokens parsed
FUNCTION String_Tokenize& (text AS STRING, delims AS STRING, quoteChars AS STRING, returnDelims AS _BYTE, tokens() AS STRING)
    IF LEN(text) = NULL THEN EXIT FUNCTION ' nothing to be done

    DIM arrIdx AS LONG: arrIdx = LBOUND(tokens) ' we'll always start from the array lower bound - whatever it is
    DIM insideQuote AS _BYTE ' flag to track if currently inside a quote

    DIM token AS STRING ' holds a token until it is ready to be added to the array
    DIM char AS STRING * 1 ' this is a single char from text we are iterating through
    DIM AS LONG i, count

    ' Iterate through the characters in the text string
    FOR i = 1 TO LEN(text)
        char = CHR$(ASC(text, i))
        IF insideQuote THEN
            IF char = RIGHT$(quoteChars, 1) THEN
                ' Closing quote char encountered, resume delimiting
                insideQuote = _FALSE
                GOSUB add_token ' add the token to the array
                IF returnDelims THEN GOSUB add_delim ' add the closing quote char as delimiter if required
            ELSE
                token = token + char ' add the character to the current token
            END IF
        ELSE
            IF char = LEFT$(quoteChars, 1) THEN
                ' Opening quote char encountered, temporarily stop delimiting
                insideQuote = _TRUE
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

    String_Tokenize = count

    EXIT FUNCTION

    ' Add the token to the array if there is any
    add_token:
    IF LEN(token) > NULL THEN
        tokens(arrIdx) = token ' add the token to the token array
        token = _STR_EMPTY ' clear the current token
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


'  Extracts tokens from a string. A token is a word that is surrounded
'  by separators, such as spaces or commas. Tokens are extracted and
'  analyzed when parsing sentences or commands. To use the String_GetNextToken
'  function, pass the string to be parsed on the first call, then pass
'  a null string on subsequent calls until the function returns a null
'  to indicate that the entire string has been parsed.
FUNCTION String_GetToken$ (sourceString AS STRING, delimiters AS STRING)
    STATIC startPosition AS _UNSIGNED LONG, originalString AS STRING

    ' If it's the first call, make a copy of the string
    IF LEN(sourceString) <> NULL THEN
        startPosition = 1
        originalString = sourceString
    END IF

    DIM currentPosition AS _UNSIGNED LONG: currentPosition = startPosition

    ' Find the start of the next token (character that isn't a delimiter)
    WHILE currentPosition <= LEN(originalString) AND INSTR(delimiters, CHR$(ASC(originalString, currentPosition))) <> NULL
        currentPosition = currentPosition + 1
    WEND

    ' Check if the token start is found
    IF currentPosition > LEN(originalString) THEN
        String_GetToken = _STR_EMPTY ' no more tokens, return an empty string
        EXIT FUNCTION
    END IF

    ' Find the end of the token
    DIM tokenStart AS _UNSIGNED LONG: tokenStart = currentPosition
    WHILE tokenStart <= LEN(originalString) AND INSTR(delimiters, CHR$(ASC(originalString, tokenStart))) = NULL
        tokenStart = tokenStart + 1
    WEND

    DIM tokenEnd AS _UNSIGNED LONG: tokenEnd = tokenStart
    String_GetToken = MID$(originalString, currentPosition, tokenEnd - currentPosition)

    ' Set the starting point for the search for the next token
    startPosition = tokenEnd
END FUNCTION


' Takes unwanted characters out of a string by comparing them with a filter string containing only acceptable characters
FUNCTION String_Filter$ (txtToFilter AS STRING, filter AS STRING, inclusiveFilter AS _BYTE)
    DIM result AS STRING: result = SPACE$(LEN(txtToFilter)) ' pre-allocate memory for the result string

    $CHECKING:OFF
    DIM i AS _UNSIGNED LONG: WHILE i < LEN(txtToFilter)
        DIM resultIndex AS _UNSIGNED LONG ' index to track the result string length
        DIM c AS _UNSIGNED _BYTE: c = PeekStringByte(txtToFilter, i)

        IF inclusiveFilter THEN
            ' Inclusive filtering (keep characters in the filter).
            IF INSTR(filter, CHR$(c)) <> NULL THEN
                PokeStringByte result, resultIndex, c
                resultIndex = resultIndex + 1
            END IF
        ELSE
            ' Exclusive filtering (exclude characters in the filter).
            IF INSTR(filter, CHR$(c)) = NULL THEN
                PokeStringByte result, resultIndex, c
                resultIndex = resultIndex + 1
            END IF
        END IF

        i = i + 1
    WEND
    $CHECKING:ON

    ' Trim the extra spaces from the result string.
    String_Filter = LEFT$(result, resultIndex)
END FUNCTION


' Replaces occurences of substringToFind in originalString with replacement
FUNCTION String_Replace$ (originalString AS STRING, substringToFind AS STRING, replacement AS STRING, startPosition AS _UNSIGNED LONG, replaceCount AS LONG)
    ' Ensure a valid starting position
    DIM position AS _UNSIGNED LONG: position = startPosition
    IF position < 1 THEN position = 1

    ' Initialize the result string
    DIM resultString AS STRING: resultString = originalString

    ' Loop until the specified count is reached or all occurrences are replaced
    DO
        DIM occurrencesReplaced AS _UNSIGNED LONG
        DIM findPosition AS _UNSIGNED LONG: findPosition = INSTR(position, resultString, substringToFind)

        ' Check if the specified count is reached or no more occurrences are found
        IF findPosition = NULL OR (replaceCount > NULL AND occurrencesReplaced >= replaceCount) THEN EXIT DO

        ' Replace the found occurrence with the new substring
        resultString = LEFT$(resultString, findPosition - 1) + replacement + MID$(resultString, findPosition + LEN(substringToFind))

        ' Move the starting position and increment the replace count
        position = findPosition + LEN(replacement)
        occurrencesReplaced = occurrencesReplaced + 1
    LOOP

    String_Replace = resultString
END FUNCTION


' Joins a bunch of strings in sourceArray using delimiter
FUNCTION String_Join$ (sourceArray() AS STRING, delimiter AS STRING)
    DIM LB AS _UNSIGNED LONG: LB = LBOUND(sourceArray)
    DIM UB AS _UNSIGNED LONG: UB = UBOUND(sourceArray)

    ' Ensure the array is not empty.
    IF UB < LB THEN EXIT FUNCTION ' does this really happen?

    ' Initialize the result string with the first element.
    DIM resultString AS STRING: resultString = sourceArray(LB)

    ' Concatenate the remaining elements with the delimiter.
    LB = LB + 1
    DIM i AS _UNSIGNED LONG: FOR i = LB TO UB
        resultString = resultString + delimiter + sourceArray(i)
    NEXT

    String_Join = resultString
END FUNCTION


''' @brief Sorts a string array
''' @param strArr The string array to sort
''' @param l The lower index
''' @param u The upper index
SUB String_SortArray (strArr() AS STRING, l AS _UNSIGNED LONG, u AS _UNSIGNED LONG)
    DIM i AS _UNSIGNED LONG: i = l
    DIM j AS _UNSIGNED LONG: j = u
    DIM pivot AS STRING: pivot = strArr((l + u) \ 2)

    WHILE i <= j
        WHILE _STRCMP(strArr(i), pivot) < 0
            i = i + 1
        WEND

        WHILE _STRCMP(strArr(j), pivot) > 0
            j = j - 1
        WEND

        IF i <= j THEN
            SWAP strArr(i), strArr(j)
            i = i + 1
            j = j - 1
        END IF
    WEND

    ' Recursively sort the partitions
    IF l < j THEN String_SortArray strArr(), l, j
    IF i < u THEN String_SortArray strArr(), i, u
END SUB


' Reverses and returns the characters of a string
FUNCTION String_Reverse$ (s AS STRING)
    $CHECKING:OFF
    DIM tmp AS STRING: tmp = s
    ReverseMemory _OFFSET(tmp), LEN(tmp)
    String_Reverse = tmp
    $CHECKING:ON
END FUNCTION


' Reverses the characters of a string in-place
SUB String_Reverse (s AS STRING)
    $CHECKING:OFF
    ReverseMemory _OFFSET(s), LEN(s)
    $CHECKING:ON
END SUB


' Formats a string using C's printf() format specifier
FUNCTION String_FormatString$ (s AS STRING, fmt AS STRING)
    $CHECKING:OFF
    String_FormatString = __String_FormatString(String_ToCStr(s), String_ToCStr(fmt))
    $CHECKING:ON
END FUNCTION


' Formats a long using C's printf() format specifier
FUNCTION String_FormatLong$ (n AS LONG, fmt AS STRING)
    $CHECKING:OFF
    String_FormatLong = __String_FormatLong(n, String_ToCStr(fmt))
    $CHECKING:ON
END FUNCTION


' Formats an integer64 using C's printf() format specifier
FUNCTION String_FormatInteger64$ (n AS _INTEGER64, fmt AS STRING)
    $CHECKING:OFF
    String_FormatInteger64 = __String_FormatInteger64(n, String_ToCStr(fmt))
    $CHECKING:ON
END FUNCTION


' Formats a single using C's printf() format specifier
FUNCTION String_FormatSingle$ (n AS SINGLE, fmt AS STRING)
    $CHECKING:OFF
    String_FormatSingle = __String_FormatSingle(n, String_ToCStr(fmt))
    $CHECKING:ON
END FUNCTION


' Formats a double using C's printf() format specifier
FUNCTION String_FormatDouble$ (n AS DOUBLE, fmt AS STRING)
    $CHECKING:OFF
    String_FormatDouble = __String_FormatDouble(n, String_ToCStr(fmt))
    $CHECKING:ON
END FUNCTION


' Formats an offset using C's printf() format specifier
FUNCTION String_FormatOffset$ (n AS _UNSIGNED _OFFSET, fmt AS STRING)
    $CHECKING:OFF
    String_FormatOffset = __String_FormatOffset(n, String_ToCStr(fmt))
    $CHECKING:ON
END FUNCTION


' Compiles a regex for quick usage with different stings via RegExMatchCompiled()
FUNCTION String_RegExCompile~%& (pattern AS STRING)
    $CHECKING:OFF
    String_RegExCompile = __String_RegExCompile(String_ToCStr(pattern))
    $CHECKING:ON
END FUNCTION


' Does a regex search for a string using a compiled pattern
FUNCTION String_RegExSearchCompiled& (pattern AS _UNSIGNED _OFFSET, text AS STRING, startPos AS LONG, matchLength AS LONG)
    $CHECKING:OFF
    IF startPos > 0 AND startPos <= LEN(text) THEN
        DIM i AS LONG: i = __String_RegExSearchCompiled(pattern, String_ToCStr(text), startPos, matchLength)
        IF i > -1 THEN String_RegExSearchCompiled = i + startPos ELSE String_RegExSearchCompiled = i
    END IF
    $CHECKING:ON
END FUNCTION


' Does a regex search for a string using a pattern string
FUNCTION String_RegExSearch& (pattern AS STRING, text AS STRING, startPos AS LONG, matchLength AS LONG)
    $CHECKING:OFF
    IF startPos > 0 AND startPos <= LEN(text) THEN
        DIM i AS LONG: i = __String_RegExSearch(String_ToCStr(pattern), String_ToCStr(text), startPos, matchLength)
        IF i > -1 THEN String_RegExSearch = i + startPos ELSE String_RegExSearch = i
    END IF
    $CHECKING:ON
END FUNCTION


' Checks if `text` is a RegEx match using a compiled pattern
FUNCTION String_RegExMatchCompiled%% (pattern AS _UNSIGNED _OFFSET, text AS STRING)
    $CHECKING:OFF
    String_RegExMatchCompiled = __String_RegExMatchCompiled(pattern, String_ToCStr(text))
    $CHECKING:ON
END FUNCTION


' Checks if `text` is a RegEx match using a pattern string
FUNCTION String_RegExMatch%% (pattern AS STRING, text AS STRING)
    $CHECKING:OFF
    String_RegExMatch = __String_RegExMatch(String_ToCStr(pattern), String_ToCStr(text))
    $CHECKING:ON
END FUNCTION

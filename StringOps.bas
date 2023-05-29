'-----------------------------------------------------------------------------------------------------------------------
' String related routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'Common.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If STRINGOPS_BAS = UNDEFINED Then
    $Let STRINGOPS_BAS = TRUE

    '-------------------------------------------------------------------------------------------------------------------
    ' FUNCTIONS & SUBROUTINES
    '-------------------------------------------------------------------------------------------------------------------
    ' Tokenizes a string to a dynamic string array
    ' text - is the input string
    ' delims - is a list of delimiters (multiple delimiters can be specified)
    ' tokens() - is the array that will hold the tokens
    ' returnDelims - if True, then the routine will also return the delimiters in the correct position in the tokens array
    ' quoteChars - is the string containing the opening and closing "quote" characters. Should be 2 chars only or nothing
    ' Returns: the number of tokens parsed
    Function TokenizeString& (text As String, delims As String, returnDelims As _Byte, quoteChars As String, tokens() As String)
        Dim sLen As Long: sLen = Len(text)

        If sLen = NULL Then Exit Function ' nothing to be done

        Dim arrIdx As Long: arrIdx = LBound(tokens) ' we'll always start from the array lower bound - whatever it is
        Dim insideQuote As _Byte ' flag to track if currently inside a quote

        Dim token As String ' holds a token until it is ready to be added to the array
        Dim char As String * 1 ' this is a single char from text we are iterating through
        Dim As Long i, count

        ' Iterate through the characters in the text string
        For i = 1 To sLen
            char = Chr$(Asc(text, i))
            If insideQuote Then
                If char = Right$(quoteChars, 1) Then
                    ' Closing quote char encountered, resume delimiting
                    insideQuote = FALSE
                    GoSub add_token ' add the token to the array
                    If returnDelims Then GoSub add_delim ' add the closing quote char as delimiter if required
                Else
                    token = token + char ' add the character to the current token
                End If
            Else
                If char = Left$(quoteChars, 1) Then
                    ' Opening quote char encountered, temporarily stop delimiting
                    insideQuote = TRUE
                    GoSub add_token ' add the token to the array
                    If returnDelims Then GoSub add_delim ' add the opening quote char as delimiter if required
                ElseIf InStr(delims, char) = NULL Then
                    token = token + char ' add the character to the current token
                Else
                    GoSub add_token ' found a delimiter, add the token to the array
                    If returnDelims Then GoSub add_delim ' found a delimiter, add it to the array if required
                End If
            End If
        Next

        GoSub add_token ' add the final token if there is any

        If count > NULL Then ReDim _Preserve tokens(LBound(tokens) To arrIdx - 1) As String ' resize the array to the exact size

        TokenizeString = count

        Exit Function

        ' Add the token to the array if there is any
        add_token:
        If Len(token) > NULL Then
            tokens(arrIdx) = token ' add the token to the token array
            token = NULLSTRING ' clear the current token
            GoSub increment_counters_and_resize_array
        End If
        Return

        ' Add delimiter to array if required
        add_delim:
        tokens(arrIdx) = char ' add delimiter to array
        GoSub increment_counters_and_resize_array
        Return

        ' Increment the count and array index and resize the array if needed
        increment_counters_and_resize_array:
        count = count + 1 ' increment the token count
        arrIdx = arrIdx + 1 ' move to next position
        If arrIdx > UBound(tokens) Then ReDim _Preserve tokens(LBound(tokens) To UBound(tokens) + 512) As String ' resize in 512 chunks
        Return
    End Function


    ' Gets a string form of the boolean value passed
    Function BoolToStr$ (expression As Long, style As _Unsigned _Byte)
        Select Case style
            Case 1
                If expression Then BoolToStr = "On" Else BoolToStr = "Off"
            Case 2
                If expression Then BoolToStr = "Enabled" Else BoolToStr = "Disabled"
            Case 3
                If expression Then BoolToStr = "1" Else BoolToStr = "0"
            Case Else
                If expression Then BoolToStr = "True" Else BoolToStr = "False"
        End Select
    End Function
    '-------------------------------------------------------------------------------------------------------------------

$End If
'-----------------------------------------------------------------------------------------------------------------------

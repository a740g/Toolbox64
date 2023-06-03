'-----------------------------------------------------------------------------------------------------------------------
' String related routines
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'CRTLib.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If STRINGOPS_BAS = UNDEFINED Then
    $Let STRINGOPS_BAS = TRUE
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
    Function TokenizeString& (text As String, delims As String, quoteChars As String, returnDelims As _Byte, tokens() As String)
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


    ' Reverses and returns the characters of a string
    Function ReverseString$ (s As String)
        Dim tmp As String: tmp = s
        ReverseBytes _Offset(tmp), Len(tmp)
        ReverseString = tmp
    End Function


    ' Reverses the characters of a string in-place
    Sub ReverseString (s As String)
        ReverseBytes _Offset(s), Len(s)
    End Sub
    '-------------------------------------------------------------------------------------------------------------------

$End If
'-----------------------------------------------------------------------------------------------------------------------

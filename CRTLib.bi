'-----------------------------------------------------------------------------------------------------------------------
' C Runtime Library bindings + low level support functions
' Copyright (c) 2023 Samuel Gomes
'
' See https://en.cppreference.com/w/ for CRT documentation
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'Common.bi'
'-----------------------------------------------------------------------------------------------------------------------

$If CRTLIB_BI = UNDEFINED Then
    $Let CRTLIB_BI = TRUE

    '-------------------------------------------------------------------------------------------------------------------
    ' EXTERNAL LIBRARIES
    '-------------------------------------------------------------------------------------------------------------------
    ' This only includes CRT library functions that makes sense in QB64
    Declare CustomType Library
        Function IsAlNum& Alias isalnum (ByVal ch As Long)
        Function IsAlpha& Alias isalpha (ByVal ch As Long)
        Function IsLower& Alias islower (ByVal ch As Long)
        Function IsUpper& Alias isupper (ByVal ch As Long)
        Function IsDigit& Alias isdigit (ByVal ch As Long)
        Function IsXDigit& Alias isxdigit (ByVal ch As Long)
        Function IsCntrl& Alias iscntrl (ByVal ch As Long)
        Function IsGraph& Alias isgraph (ByVal ch As Long)
        Function IsSpace& Alias isspace (ByVal ch As Long)
        Function IsBlank& Alias isblank (ByVal ch As Long)
        Function IsPrint& Alias isprint (ByVal ch As Long)
        Function IsPunct& Alias ispunct (ByVal ch As Long)
        Function ToLower& Alias tolower (ByVal ch As Long)
        Function ToUpper& Alias toupper (ByVal ch As Long)
        Function StrLen~& Alias strlen (ByVal str As _Unsigned _Offset)
        Sub StrNCpy Alias strncpy (ByVal dst As _Unsigned _Offset, Byval src As _Unsigned _Offset, Byval count As _Unsigned _Offset)
        Function MemChr%& Alias memchr (ByVal ptr As _Unsigned _Offset, Byval ch As Long, Byval count As _Unsigned _Offset)
        Function MemCmp& Alias memcmp (ByVal lhs As _Unsigned _Offset, Byval rhs As _Unsigned _Offset, Byval count As _Unsigned _Offset)
        Sub MemSet Alias memset (ByVal dst As _Unsigned _Offset, Byval ch As Long, Byval count As _Unsigned _Offset)
        Sub MemCpy Alias memcpy (ByVal dst As _Unsigned _Offset, Byval src As _Unsigned _Offset, Byval count As _Unsigned _Offset)
        Sub MemMove Alias memmove (ByVal dst As _Unsigned _Offset, Byval src As _Unsigned _Offset, Byval count As _Unsigned _Offset)
        Sub MemCCpy Alias memccpy (ByVal dst As _Unsigned _Offset, Byval src As _Unsigned _Offset, Byval c As Long, Byval count As _Unsigned _Offset)
        Function Rand& Alias rand
        Sub SRand Alias srand (ByVal seed As _Unsigned Long)
        Function GetChar& Alias getchar
        Sub PutChar Alias putchar (ByVal ch As Long)
        Function GetTicks~&&
    End Declare

    Declare CustomType Library "CRTLib"
        $If 32BIT Then
            Function CLngPtr~& (ByVal p As _Unsigned _Offset)
        $Else
            Function CLngPtr~&& (ByVal p As _Unsigned _Offset)
        $End If
        Function ToQBBool%% (ByVal x As Long)
        Function ToCBool%% (ByVal x As Long)
        Function PeekByteAtOffset~%% (ByVal p As _Unsigned _Offset, Byval o As _Unsigned _Offset)
        Sub PokeByteAtOffset (ByVal p As _Unsigned _Offset, Byval o As _Unsigned _Offset, Byval n As _Unsigned _Byte)
        Function PeekIntegerAtOffset~% (ByVal p As _Unsigned _Offset, Byval o As _Unsigned _Offset)
        Sub PokeIntegerAtOffset (ByVal p As _Unsigned _Offset, Byval o As _Unsigned _Offset, Byval n As _Unsigned Integer)
        Function PeekLongAtOffset~& (ByVal p As _Unsigned _Offset, Byval o As _Unsigned _Offset)
        Sub PokeLongAtOffset (ByVal p As _Unsigned _Offset, Byval o As _Unsigned _Offset, Byval n As _Unsigned Long)
        Function PeekInteger64AtOffset~&& (ByVal p As _Unsigned _Offset, Byval o As _Unsigned _Offset)
        Sub PokeInteger64AtOffset (ByVal p As _Unsigned _Offset, Byval o As _Unsigned _Offset, Byval n As _Unsigned _Integer64)
        Function PeekSingleAtOffset! (ByVal p As _Unsigned _Offset, Byval o As _Unsigned _Offset)
        Sub PokeSingleAtOffset (ByVal p As _Unsigned _Offset, Byval o As _Unsigned _Offset, Byval n As Single)
        Function PeekDoubleAtOffset# (ByVal p As _Unsigned _Offset, Byval o As _Unsigned _Offset)
        Sub PokeDoubleAtOffset (ByVal p As _Unsigned _Offset, Byval o As _Unsigned _Offset, Byval n As Double)
        Function PeekOffsetAtOffset%& (ByVal p As _Unsigned _Offset, Byval o As _Unsigned _Offset)
        Sub PokeOffsetAtOffset (ByVal p As _Unsigned _Offset, Byval o As _Unsigned _Offset, Byval n As _Unsigned _Offset)
        Function PeekString~%% (s As String, Byval o As _Unsigned _Offset)
        Sub PokeString (s As String, Byval o As _Unsigned _Offset, Byval n As _Unsigned _Byte)
        Function RandomBetween& (ByVal lo As Long, Byval hi As Long)
        Function IsPowerOfTwo& (ByVal n As _Unsigned Long)
        Function RoundUpToPowerOf2~& (ByVal n As _Unsigned Long)
        Function RoundDownToPowerOf2~& (ByVal n As _Unsigned Long)
        Function LeftShiftOneCount~& (ByVal n As _Unsigned Long)
        Function ReverseBitsLong~& (ByVal n As _Unsigned Long)
        Function ReverseBitsInteger64~&& (ByVal n As _Unsigned _Integer64)
        Function ClampLong& (ByVal n As Long, Byval lo As Long, Byval hi As Long)
        Function ClampInteger64&& (ByVal n As _Integer64, Byval lo As _Integer64, Byval hi As _Integer64)
        Function ClampSingle! (ByVal n As Single, Byval lo As Single, Byval hi As Single)
        Function ClampDouble# (ByVal n As Double, Byval lo As Double, Byval hi As Double)
        Function GetDigitFromLong& (ByVal n As _Unsigned Long, Byval p As _Unsigned Long)
        Function GetDigitFromInteger64& (ByVal n As _Unsigned _Integer64, Byval p As _Unsigned Long)
        Function AverageLong& (ByVal x As Long, Byval y As Long)
        Function AverageInteger64&& (ByVal x As _Integer64, Byval y As _Integer64)
        Function FindFirstBitSetLong& (ByVal x As _Unsigned Long)
        Function FindFirstBitSetInteger64& (ByVal x As _Unsigned _Integer64)
        Function CountLeadingZerosLong& (ByVal x As _Unsigned Long)
        Function CountLeadingZerosInteger64& (ByVal x As _Unsigned _Integer64)
        Function CountTrailingZerosLong& (ByVal x As _Unsigned Long)
        Function CountTrailingZerosInteger64& (ByVal x As _Unsigned _Integer64)
        Function PopulationCountLong& (ByVal x As _Unsigned Long)
        Function PopulationCountInteger64& (ByVal x As _Unsigned _Integer64)
        Function ByteSwapInteger~% (ByVal x As _Unsigned Integer)
        Function ByteSwapLong~& (ByVal x As _Unsigned Long)
        Function ByteSwapInteger64~&& (ByVal x As _Unsigned _Integer64)
        Function MakeFourCC~& (ByVal ch0 As _Unsigned _Byte, Byval ch1 As _Unsigned _Byte, Byval ch2 As _Unsigned _Byte, Byval ch3 As _Unsigned _Byte)
        Function MakeByte~%% (ByVal x As _Unsigned _Byte, Byval y As _Unsigned _Byte)
        Function MakeInteger~% (ByVal x As _Unsigned _Byte, Byval y As _Unsigned _Byte)
        Function MakeLong~& (ByVal x As _Unsigned Integer, Byval y As _Unsigned Integer)
        Function MakeInteger64~&& (ByVal x As _Unsigned Long, Byval y As _Unsigned Long)
        Function HiNibble~%% (ByVal x As _Unsigned _Byte)
        Function LoNibble~%% (ByVal x As _Unsigned _Byte)
        Function HiByte~%% (ByVal x As _Unsigned Integer)
        Function LoByte~%% (ByVal x As _Unsigned Integer)
        Function HiInteger~% (ByVal x As _Unsigned Long)
        Function LoInteger~% (ByVal x As _Unsigned Long)
        Function HiLong~& (ByVal x As _Unsigned _Integer64)
        Function LoLong~& (ByVal x As _Unsigned _Integer64)
        Function MaxLong& (ByVal a As Long, Byval b As Long)
        Function MinLong& (ByVal a As Long, Byval b As Long)
        Function MaxInteger64&& (ByVal a As _Integer64, Byval b As _Integer64)
        Function MinInteger64&& (ByVal a As _Integer64, Byval b As _Integer64)
        Function MaxSingle! (ByVal a As Single, Byval b As Single)
        Function MinSingle! (ByVal a As Single, Byval b As Single)
        Function MaxDouble# (ByVal a As Double, Byval b As Double)
        Function MinDouble# (ByVal a As Double, Byval b As Double)
    End Declare
    '-------------------------------------------------------------------------------------------------------------------
$End If
'-----------------------------------------------------------------------------------------------------------------------

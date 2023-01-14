'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' C Runtime Library bindings
' Copyright (c) 2022 Samuel Gomes
'
' See https://en.cppreference.com/w/ for documentation
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'---------------------------------------------------------------------------------------------------------------------------------------------------------------
'$Include:'Common.bi'
'---------------------------------------------------------------------------------------------------------------------------------------------------------------

$If CRTLIB_BI = UNDEFINED Then
    $Let CRTLIB_BI = TRUE

    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    ' EXTERNAL LIBRARIES
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
    Declare CustomType Library
        ' This only includes CRT library functions that makes sense in BASIC
        Function isalnum& (ByVal ch As Long)
        Function isalpha& (ByVal ch As Long)
        Function islower& (ByVal ch As Long)
        Function isupper& (ByVal ch As Long)
        Function isdigit& (ByVal ch As Long)
        Function isxdigit& (ByVal ch As Long)
        Function iscntrl& (ByVal ch As Long)
        Function isgraph& (ByVal ch As Long)
        Function isspace& (ByVal ch As Long)
        Function isblank& (ByVal ch As Long)
        Function isprint& (ByVal ch As Long)
        Function ispunct& (ByVal ch As Long)
        Function tolower& (ByVal ch As Long)
        Function toupper& (ByVal ch As Long)
        Function rand&
        Sub srand (ByVal seed As Unsigned Long)
        Sub strncpy (dst As String, src As String, Byval count As Unsigned Long)
        Sub strncpy_s (dst As String, Byval destsz As Unsigned Long, src As String, Byval count As Unsigned Long)
        Function strlen~& (ByVal str As Offset)
        Function strnlen_s~& (ByVal str As Offset, Byval strsz As Unsigned Long)
        Function strncmp& (lhs As String, rhs As String, Byval count As Unsigned Long)
        Function memchr%& (ByVal ptr As Offset, Byval ch As Long, Byval count As Unsigned Long)
        Function memcmp& (ByVal lhs As Offset, Byval rhs As Offset, Byval count As Unsigned Long)
        Sub memset (ByVal dst As Offset, Byval ch As Long, Byval count As Unsigned Long)
        Sub memset_s (ByVal dst As Offset, Byval destsz As Unsigned Long, Byval ch As Long, Byval count As Unsigned Long)
        Sub memcpy (ByVal dst As Offset, Byval src As Offset, Byval count As Unsigned Long)
        Sub memcpy_s (ByVal dst As Offset, Byval destsz As Unsigned Long, Byval src As Offset, Byval count As Unsigned Long)
        Sub memmove (ByVal dst As Offset, Byval src As Offset, Byval count As Unsigned Long)
        Sub memmove_s (ByVal dst As Offset, Byval destsz As Unsigned Long, Byval src As Offset, Byval count As Unsigned Long)
        Sub memccpy (ByVal dst As Offset, Byval src As Offset, Byval c As Long, Byval count As Unsigned Long)
        Function GetTicks~&&
    End Declare

    Declare CustomType Library "./CRTLib"
        $If 32BIT Then
            Function randmax&
            Function ofstonum~& (ByVal p As Offset)
            Function numtoofs%& (ByVal n As Unsigned Long)
            Function peekbyte~%% (ByVal p As Offset, Byval o As Unsigned Long)
            Function peekinteger~% (ByVal p As Offset, Byval o As Unsigned Long)
            Function peeklong~& (ByVal p As Offset, Byval o As Unsigned Long)
            Function peekinteger64~&& (ByVal p As Offset, Byval o As Unsigned Long)
            Function peekstring~%% (s As String, Byval o As Unsigned Long)
            Sub pokebyte (ByVal p As Offset, Byval o As Unsigned Long, Byval n As Unsigned Byte)
            Sub pokeinteger (ByVal p As Offset, Byval o As Unsigned Long, Byval n As Unsigned Integer)
            Sub pokelong (ByVal p As Offset, Byval o As Unsigned Long, Byval n As Unsigned Long)
            Sub pokeinteger64 (ByVal p As Offset, Byval o As Unsigned Long, Byval n As Unsigned Integer64)
            Sub pokestring (s As String, Byval o As Unsigned Long, Byval n As Unsigned Byte)
        $Else
            Function randmax&&
            Function ofstonum~&& (ByVal p As Offset)
            Function numtoofs%& (ByVal n As Unsigned Integer64)
            Function peekbyte~%% (ByVal p As Offset, Byval o As Unsigned Integer64)
            Function peekinteger~% (ByVal p As Offset, Byval o As Unsigned Integer64)
            Function peeklong~& (ByVal p As Offset, Byval o As Unsigned Integer64)
            Function peekinteger64~&& (ByVal p As Offset, Byval o As Unsigned Integer64)
            Function peekstring~%% (s As String, Byval o As Unsigned Integer64)
            Sub pokebyte (ByVal p As Offset, Byval o As Unsigned Integer64, Byval n As Unsigned Byte)
            Sub pokeinteger (ByVal p As Offset, Byval o As Unsigned Integer64, Byval n As Unsigned Integer)
            Sub pokelong (ByVal p As Offset, Byval o As Unsigned Integer64, Byval n As Unsigned Long)
            Sub pokeinteger64 (ByVal p As Offset, Byval o As Unsigned Integer64, Byval n As Unsigned Integer64)
            Sub pokestring (s As String, Byval o As Unsigned Integer64, Byval n As Unsigned Byte)
        $End If
        Function ofstostr$ (ByVal p As Offset)
        Function ofsatofs%& (ByVal p As Offset)
        Function floatcastint! (ByVal n As Long)
        Function intcastfloat& (ByVal n As Single)
    End Declare
    '-----------------------------------------------------------------------------------------------------------------------------------------------------------
$End If
'---------------------------------------------------------------------------------------------------------------------------------------------------------------


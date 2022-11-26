'$include:'Common.bi'

'MessageBox Constant values as defined by Microsoft (MBType)
Const MB_OK = 0 'OK button only
Const MB_OKCANCEL = 1 'OK & Cancel
Const MB_ABORTRETRYIGNORE = 2 'Abort, Retry & Ignore
Const MB_YESNOCANCEL = 3 'Yes, No & Cancel
Const MB_YESNO = 4 'Yes & No
Const MB_RETRYCANCEL = 5 'Retry & Cancel
Const MB_CANCELTRYCONTINUE = 6 'Cancel, Try Again & Continue
Const MB_ICONSTOP = 16 'Error stop sign icon
Const MB_ICONQUESTION = 32 'Question-mark icon
Const MB_ICONEXCLAMATION = 48 'Exclamation-point icon
Const MB_ICONINFORMATION = 64 'Letter i in a circle icon
Const MB_DEFBUTTON1 = 0 '1st button default(left)
Const MB_DEFBUTTON2 = 256 '2nd button default
Const MB_DEFBUTTON3 = 512 '3rd button default(right)
Const MB_APPLMODAL = 0 'Message box applies to application only
Const MB_SYSTEMMODAL = 4096 'Message box on top of all other windows
Const MB_SETFOCUS = 65536 'Set message box as focus

' Return values from MessageBox
Const ID_OK = 1 'OK button pressed
Const ID_CANCEL = 2 'Cancel button pressed
Const ID_ABORT = 3 'Abort button pressed
Const ID_RETRY = 4 'Retry button pressed
Const ID_IGNORE = 5 'Ignore button pressed
Const ID_YES = 6 'Yes button pressed
Const ID_NO = 7 'No button pressed
Const ID_TRYAGAIN = 10 'Try again button pressed
Const ID_CONTINUE = 1 'Continue button pressed

' Dialog flag constants (use + or OR to use more than 1 flag value)
Const OFN_ALLOWMULTISELECT = &H200 ' Allows the user to select more than one file, not recommended!
Const OFN_CREATEPROMPT = &H2000 ' Prompts if a file not found should be created(GetOpenFileName only).
Const OFN_EXTENSIONDIFFERENT = &H400 ' Allows user to specify file extension other than default extension.
Const OFN_FILEMUSTEXIST = &H1000 ' Chechs File name exists(GetOpenFileName only).
Const OFN_HIDEREADONLY = &H4 ' Hides read-only checkbox(GetOpenFileName only)
Const OFN_NOCHANGEDIR = &H8 ' Restores the current directory to original value if user changed
Const OFN_NODEREFERENCELINKS = &H100000 ' Returns path and file name of selected shortcut(.LNK) file instead of file referenced.
Const OFN_NONETWORKBUTTON = &H20000 ' Hides and disables the Network button.
Const OFN_NOREADONLYRETURN = &H8000 ' Prevents selection of read-only files, or files in read-only subdirectory.
Const OFN_NOVALIDATE = &H100 ' Allows invalid file name characters.
Const OFN_OVERWRITEPROMPT = &H2 ' Prompts if file already exists(GetSaveFileName only)
Const OFN_PATHMUSTEXIST = &H800 ' Checks Path name exists (set with OFN_FILEMUSTEXIST).
Const OFN_READONLY = &H1 ' Checks read-only checkbox. Returns if checkbox is checked
Const OFN_SHAREAWARE = &H4000 ' Ignores sharing violations in networking
Const OFN_SHOWHELP = &H10 ' Shows the help button (useless!)

' SHBrowseForFolder constants
Const MAX_PATH = &HFFFF
Const BIF_RETURNONLYFSDIRS = &H1 ' For finding a folder to start document searching
Const BIF_DONTGOBELOWDOMAIN = &H2 ' For starting the Find Computer
Const BIF_STATUSTEXT = &H4
Const BIF_RETURNFSANCESTORS = &H8
Const BIF_EDITBOX = &H10
Const BIF_VALIDATE = &H20 ' insist on valid result (or CANCEL)
Const BIF_BROWSEFORCOMPUTER = &H1000 ' Browsing for Computers.
Const BIF_BROWSEFORPRINTER = &H2000 ' Browsing for Printers
Const BIF_BROWSEINCLUDEFILES = &H4000 ' Browsing for Everything

' Color Dialog flag constants (use + or OR to use more than 1 flag)
Const CC_RGBINIT = &H1& '           Sets the initial color (don't know how to set it)
Const CC_FULLOPEN = &H2& '          Opens all dialog sections such as the custom color selector
Const CC_PREVENTFULLOPEN = &H4& '   Prevents the user from opening the custom color selector
Const CC_SHOWHELP = &H8& '          Shows the help button (USELESS!)
'----------------------------------------------------------------------------------------

' Constants assigned to Flags. A LONG numerical suffix defines those constants as LONG
Const CF_APPLY = &H200& '             Displays Apply button
Const CF_ANSIONLY = &H400& '          list ANSI fonts only
Const CF_BOTH = &H3& '                list both Screen and Printer fonts
Const CF_EFFECTS = &H100& '          Display Underline and Strike Through boxes
Const CF_ENABLEHOOK = &H8& '          set hook to custom template
Const CF_ENABLETEMPLATE = &H10& '     enable custom template
Const CF_ENABLETEMPLATEHANDLE = &H20&
Const CF_FIXEDPITCHONLY = &H4000& '  list only fixed-pitch fonts
Const CF_FORCEFONTEXIST = &H10000& '  indicate error when font not listed is chosen
Const CF_INACTIVEFONTS = &H2000000& ' display hidden fonts in Win 7 only
Const CF_INITTOLOGFONTSTRUCT = &H40& 'use the structure pointed to by the lpLogFont member
Const CF_LIMITSIZE = &H2000& '        select font sizes only within nSizeMin and nSizeMax members
Const CF_NOOEMFONTS = &H800& '        should not allow vector font selections
Const CF_NOFACESEL = &H80000& '       prevent displaying initial selection in font name combo box.
Const CF_NOSCRIPTSEL = &H800000& '    Disables the Script combo box
Const CF_NOSIMULATIONS = &H1000& '    Disables selection of font simulations
Const CF_NOSIZESEL = &H200000& '     Disables Point Size selection
Const CF_NOSTYLESEL = &H100000& '     Disables Style selection
Const CF_NOVECTORFONTS = &H800&
Const CF_NOVERTFONTS = &H1000000&
Const CF_OEMTEXT = &H7&
Const CF_PRINTERFONTS = &H2& '        list fonts only supported by printer associated with the device
Const CF_SCALABLEONLY = &H20000& '    select only vector fonts, scalable printer fonts, and TrueType fonts
Const CF_SCREENFONTS = &H1& '        lists only the screen fonts supported by system
Const CF_SCRIPTSONLY = &H400& '       lists all non-OEM, Symbol and ANSI sets only
Const CF_SELECTSCRIPT = &H400000& '  can only use set specified in the Scripts combo box
Const CF_SHOWHELP = &H4& '           displays Help button reference
Const CF_TTONLY = &H40000& '         True Type only
Const CF_USESTYLE = &H80& '           copies style data for the user's selection to lpszStyle buffer
Const CF_WYSIWYG = &H8000& '          only list fonts available on both the printer and display
' Font Types returned by nFontType
Const BOLD_FONTTYPE = &H100&
Const ITALIC_FONTTYPE = &H200&
Const PRINTER_FONTTYPE = &H4000&
Const REGULAR_FONTTYPE = &H400&
Const SCREEN_FONTTYPE = &H2000&
Const SIMULATED_FONTTYPE = &H8000&
' Font Weights assigned to lfWeight
Const FW_DONTCARE = 0
Const FW_THIN = 100
Const FW_ULTRALIGHT = 200
Const FW_LIGHT = 300
Const FW_REGULAR = 400
Const FW_MEDIUM = 500
Const FW_SEMIBOLD = 600
Const FW_BOLD = 700
Const FW_ULTRABOLD = 800
Const FW_HEAVY = 900

Const DEFAULT_CHARSET = 1
Const LF_DEFAULT = 0
Const FF_ROMAN = 16
Const LF_FACESIZE = 32
Const GMEM_MOVEABLE = &H2
Const GMEM_ZEROINIT = &H40

'public domain, 2012 feb, michael calkins

Const NIM_ADD = 0
Const NIM_MODIFY = 1
Const NIM_DELETE = 2

Const NIF_ICON = 2
Const NIF_TIP = 4
Const NIF_INFO = &H10

Const NIIF_NONE = 0
Const NIIF_INFO = 1
Const NIIF_WARNING = 2
Const NIIF_ERROR = 3
Const NIIF_USER = 4

Const IDI_APPLICATION = 32512
Const IDI_HAND = 32513
Const IDI_QUESTION = 32514
Const IDI_EXCLAMATION = 32515
Const IDI_ASTERISK = 32516

'-------------------------------------------------------------------------------------------

Type NOTIFYICONDATA
    cbSize As _Unsigned Long
    hWnd As _Offset
    uID As _Unsigned Long
    uFlags As _Unsigned Long
    uCallbackMessage As _Unsigned Long
    hIcon As _Offset
    szTip As String * 128
    dwState As _Unsigned Long
    dwStateMask As _Unsigned Long
    szInfo As String * 256
    uTimeout As _Unsigned Long
    szInfoTitle As String * 64
    dwInfoFlags As _Unsigned Long
End Type

Type COLORDIALOGTYPE
    lStructSize As _Integer64 '   Length of this TYPE structure
    hwndOwner As _Integer64 '     Dialog owner's handle
    hInstance As _Integer64 '     ?
    rgbResult As _Integer64 '     The RGB color the user selected
    lpCustColors As _Offset '     Pointer to an array of 16 custom colors (will be changed by user)
    flags As _Integer64 '         Dialog flags
    lCustData As _Integer64 '     Custom data
    lpfnHook As _Integer64 '      Hook
    lpTemplateName As _Offset '   Custom template
End Type

Type FileDialogType
    lStructSize As Offset '      For the DLL call
    hwndOwner As Offset '        Dialog will hide behind window when not set correctly
    hInstance As Offset '        Handle to a module that contains a dialog box template.
    lpstrFilter As Offset '      Pointer of the string of file filters
    lpstrCustFilter As Long
    nMaxCustFilter As Long
    nFilterIndex As Integer64 '  One based starting filter index to use when dialog is called
    lpstrFile As Offset '        String full of 0's for the selected file name
    nMaxFile As Offset '         Maximum length of the string stuffed with 0's minus 1
    lpstrFileTitle As Offset '   Same as lpstrFile
    nMaxFileTitle As Offset '    Same as nMaxFile
    lpstrInitialDir As Offset '  Starting directory
    lpstrTitle As Offset '       Dialog title
    flags As Integer64 '         Dialog flags
    nFileOffset As Integer64 '   Zero-based offset from path beginning to file name string pointed to by lpstrFile
    nFileExtension As Integer64 'Zero-based offset from path beginning to file extension string pointed to by lpstrFile.
    lpstrDefExt As Offset '      Default/selected file extension
    lCustData As Integer64
    lpfnHook As Integer64
    lpTemplateName As Offset
End Type

Type BrowseForDialogType
    hwndOwner As Offset
    pidlRoot As Offset
    pszDisplayName As Offset
    lpszTitle As Offset
    ulFlags As Unsigned Long
    lpfnCallback As Offset
    lParam As Offset
    iImage As Long
End Type

Type CHOOSEFONT
    lStructSize As _Unsigned Long
    hwndOwner As _Offset
    HDC As _Offset
    lpLogFont As _Offset
    iPointSize As Long
    Flags As Long
    rgbColors As _Unsigned Long
    lCustData As _Offset
    lpfnHook As _Offset
    lpTemplateName As _Offset
    hInstance As _Offset
    lpszStyle As _Offset
    nFontType As Long '  if used as Unsigned Integer add Integer padder below
    'padder AS INTEGER ' use only when nFontType is designated as Unsigned Integer
    nSizeMin As Long
    nSizeMax As Long
End Type

Type LOGFONT
    lfHeight As Long
    lfWidth As Long
    lfEscapement As Long
    lfOrientation As Long
    lfWeight As Long
    lfItalic As _Byte '    not 0 when user selected
    lfUnderline As _Byte ' not 0 when user selected
    lfStrikeOut As _Byte ' not 0 when user selected
    lfCharSet As _Byte
    lfOutPrecision As _Byte
    lfClipPrecision As _Byte
    lfQuality As _Byte
    lfPitchAndFamily As _Byte
    lfFaceName As String * 32 'contains name listed in dialog
End Type


Declare Dynamic Library "kernel32"
    Function GetLastError~& ()
End Declare

Declare Dynamic Library "user32"
    Function FindWindowA%& (ByVal ClassName As _Offset, Byval WindowName As _Offset)
    Function LoadIconA%& (ByVal hInstance%&, Byval lpIconName%&)
    Function __MessasgeBox~& Alias MessageBox (ByVal hwnd As _Offset, sMessage As String, sTitle As String, Byval nType As Unsigned Long)
End Declare

Declare Dynamic Library "comdlg32"
    Function GetOpenFileNameA& (DialogParams As FileDialogType)
    Function GetSaveFileNameA& (DialogParams As FileDialogType)
    Function ChooseColorA& (DIALOGPARAMS As COLORDIALOGTYPE) '    Yet the also famous color dialog box
    Function ChooseFontA& (ByVal lpcf As _Offset)
    Function CommDlgExtendedError& () '                'dialog box error checking procedure
End Declare

Declare Dynamic Library "shell32"
    Function SHBrowseForFolderA%& (x As BrowseForDialogType)
    Function SHGetPathFromIDListA& (ByVal lpItem As Offset, pszPath As String)
    Function Shell_NotifyIconA& (ByVal dwMessage~&, Byval lpdata%&)
End Declare

Declare Dynamic Library "ole32"
    Sub CoTaskMemFree (ByVal pv As Offset)
End Declare


' Returns a BASIC string (bstring) from zero terminated C string (cstring)
Function CStrToBStr$ (cStr As String)
    Dim zeroPos As Long

    CStrToBStr = cStr
    zeroPos = InStr(cStr, Chr$(NULL))
    If zeroPos > 0 Then CStrToBStr = Left$(cStr, zeroPos - 1)
End Function


' Shows a message box based on type and returns what button was pressed
Function MsgBox& (sMessage As String, sTitle As String, BoxType As Long)
    MsgBox = __MessasgeBox(WindowHandle, sMessage + Chr$(NULL), sTitle + Chr$(NULL), BoxType)
End Function


' Shows an information message box
Sub MsgBox (sMessage As String, sTitle As String)
    Dim ignore As Unsigned Long
    ignore = __MessasgeBox(WindowHandle, sMessage + Chr$(NULL), sTitle + Chr$(NULL), MB_OK + MB_ICONINFORMATION)
End Sub


'  sTitle       - The dialog title.
'  sInitialDir  - If this left blank, it will use the directory where the last opened file is located. Specify ".\" if you want to always use the current directory.
'  sFilter      - File filters separated by pipes (|) in the same format as VB6 common dialogs.
'  lFilterIndex - The initial file filter to use. Will be altered by user during the call.
'  llFlags      - Dialog flags. Will be altered by the user during the call.
'
' Returns: Blank when cancel is clicked, otherwise the file name selected by the user.
' lFilterIndex and llFlags will be changed depending on the user's selections.
Function GetFileNameDialog$ (isSave As Byte, sTitle As String, sInitialDir As String, sFilter As String, lFilterIndex As Integer64, llFlags As Integer64)
    Dim OSFN As FileDialogType

    ' Set the struct size
    OSFN.lStructSize = Len(OSFN)

    ' Set the parent window
    OSFN.hwndOwner = WindowHandle

    ' Set the file filters
    Dim fFilter As String
    If sFilter <> NULLSTRING Then
        fFilter = sFilter + Chr$(NULL)
        ' Replace the pipes with character zero and then zero terminate filter string
        Dim r As Unsigned Long
        For r = 1 To Len(fFilter)
            If 124 = Asc(fFilter, r) Then Asc(fFilter, r) = NULL
        Next
        OSFN.lpstrFilter = Offset(fFilter)
    End If

    ' Set the filter index
    OSFN.nFilterIndex = lFilterIndex

    ' Allocate space for returned file name
    Dim lpstrFile As String
    lpstrFile = String$(MAX_PATH, NULL)
    OSFN.lpstrFile = Offset(lpstrFile)
    OSFN.nMaxFile = Len(lpstrFile) - 1

    OSFN.lpstrFileTitle = OSFN.lpstrFile
    OSFN.nMaxFileTitle = OSFN.nMaxFile

    ' Set the initial directory
    Dim fInitialDir As String
    If sInitialDir <> NULLSTRING Then
        fInitialDir = sInitialDir + Chr$(NULL)
        OSFN.lpstrInitialDir = Offset(fInitialDir)
    End If

    ' Zero terminate the title
    Dim dTitle As String
    If sTitle <> NULLSTRING Then
        dTitle = sTitle + Chr$(NULL)
        OSFN.lpstrTitle = Offset(dTitle)
    End If

    ' Extension will not be added when this is not specified
    Dim lpstrDefExt As String
    lpstrDefExt = String$(MAX_PATH, NULL)
    OSFN.lpstrDefExt = Offset(lpstrDefExt)

    OSFN.flags = llFlags

    ' Call the dialog fuction
    Dim result As Long
    If isSave Then
        result = GetSaveFileNameA(OSFN)
    Else
        result = GetOpenFileNameA(OSFN)
    End If

    If result Then
        ' Trim the remaining zeros
        GetFileNameDialog = CStrToBStr(lpstrFile)
        llFlags = OSFN.flags
        lFilterIndex = OSFN.nFilterIndex
    End If
End Function


Function BrowseForFolderDialog$ (sTitle As String, bShowFiles As Byte, bShowEditBox As Byte)
    Dim tBrowseInfo As BrowseForDialogType

    ' Set the parent Window
    tBrowseInfo.hwndOwner = WindowHandle

    ' Only set title if title is not null
    Dim lpszTitle As String
    If sTitle <> NULLSTRING Then
        lpszTitle = sTitle + Chr$(NULL)
        tBrowseInfo.lpszTitle = Offset(lpszTitle)
    End If

    ' Setup the flags
    tBrowseInfo.ulFlags = BIF_RETURNONLYFSDIRS Or BIF_DONTGOBELOWDOMAIN
    If bShowFiles Then
        tBrowseInfo.ulFlags = tBrowseInfo.ulFlags Or BIF_BROWSEINCLUDEFILES
    End If
    If bShowEditBox Then
        tBrowseInfo.ulFlags = tBrowseInfo.ulFlags Or BIF_EDITBOX
    End If

    ' Call the dialog fuction
    Dim lpIDList As Offset
    lpIDList = SHBrowseForFolderA(tBrowseInfo)

    ' Get the path if call succeeded
    Dim sBuffer As String
    If lpIDList Then
        'Allocate a large enough buffer
        sBuffer = String$(MAX_PATH, NULL)
        If SHGetPathFromIDListA(lpIDList, sBuffer) <> 0 Then
            BrowseForFolderDialog = CStrToBStr(sBuffer)
        End If
        CoTaskMemFree lpIDList
    End If
End Function


Function ChooseColor& (InitialColor&, CustomColors$, Cancel, Flags&, hWnd&)
    ' Parameters:
    '  InitialColor&  - The initial color used, will take effect if CC_RGBINIT flag is specified
    '  CustomColors$  - A 64-byte string where the user's custom colors will be stored (4 bytes per color in RGB0 format).
    '  Cancel         - Variable where the cancel flag will be stored.
    '  Flags&         - Dialog flags
    '  hWnd&          - Your program's window handle that should be aquired by the FindWindow function.

    Dim ColorCall As COLORDIALOGTYPE, result As Long, rgbResult As Long

    ColorCall.rgbResult = _RGB32(_Blue32(InitialColor&), _Green32(InitialColor&), _Red32(InitialColor&))
    ColorCall.lStructSize = Len(ColorCall)
    ColorCall.hwndOwner = hWnd&
    ColorCall.flags = Flags&
    ColorCall.lpCustColors = _Offset(CustomColors$)

    ' Do dialog call
    result = ChooseColorA(ColorCall)
    If result Then
        rgbResult& = ColorCall.rgbResult
        ' Swap RED and BLUE color intensity values using _RGB
        ChooseColor& = _RGB(_Blue32(rgbResult&), _Green32(rgbResult&), _Red32(rgbResult&))
    Else
        Cancel = -1
    End If
End Function






Function ShowFont$ (hWnd As _Offset)
    Dim cf As CHOOSEFONT
    Dim lfont As LOGFONT
SHARED FontColor&, FontType$, FontEff$, PointSize AS LONG 'shared with main program
lfont.lfHeight = LF_DEFAULT ' determine default height '       set dailog box defaults
lfont.lfWidth = LF_DEFAULT ' determine default width
lfont.lfEscapement = LF_DEFAULT ' angle between baseline and escapement vector
lfont.lfOrientation = LF_DEFAULT ' angle between baseline and orientation vector
lfont.lfWeight = FW_REGULAR ' normal weight i.e. not bold
lfont.lfCharSet = DEFAULT_CHARSET ' use default character set
lfont.lfOutPrecision = LF_DEFAULT ' default precision mapping
lfont.lfClipPrecision = LF_DEFAULT ' default clipping precision
lfont.lfQuality = LF_DEFAULT ' default quality setting
lfont.lfPitchAndFamily = LF_DEFAULT OR FF_ROMAN ' default pitch, proportional with serifs
lfont.lfFaceName = "Times New Roman" + CHR$(0) ' string must be null-terminated
cf.lStructSize = LEN(cf) ' size of structure
cf.hwndOwner = hWnd ' window opening the dialog box
'cf.HDC = Printer.hDC ' device context of default printer (using VB's mechanism)
cf.lpLogFont = _OFFSET(lfont)
cf.iPointSize = 120 ' 12 point font (in units of 1/10 point)
cf.Flags = CF_BOTH OR CF_EFFECTS OR CF_FORCEFONTEXIST OR CF_INITTOLOGFONTSTRUCT OR CF_LIMITSIZE
cf.rgbColors = _RGB(0, 0, 0) ' black
cf.nFontType = REGULAR_FONTTYPE ' regular font type i.e. not bold or anything
cf.nSizeMin = 10 ' minimum point size
cf.nSizeMax = 72 ' maximum point size

IF ChooseFontA&(_OFFSET(cf)) <> 0 THEN '    'Initiate Dialog and Read user selections
  ShowFont = LEFT$(lfont.lfFaceName, INSTR(lfont.lfFaceName, CHR$(0)) - 1)
  'returns closest color attribute or 32 bit value and swaps red and blue color values
  FontColor& = _RGB(_BLUE32(cf.rgbColors), _GREEN32(cf.rgbColors), _RED32(cf.rgbColors))
  IF cf.nFontType AND BOLD_FONTTYPE THEN FontType$ = "Bold"
  IF cf.nFontType AND ITALIC_FONTTYPE THEN FontType$ = FontType$ + "Italic"
  IF cf.nFontType AND REGULAR_FONTTYPE THEN FontType$ = "Regular"
  IF lfont.lfUnderline THEN FontEff$ = "Underline"
  IF lfont.lfStrikeOut THEN FontEff$ = FontStyle$ + "Strikeout"
  PointSize = cf.iPointSize \ 10
ELSE
  IF CommDlgExtendedError& THEN
    PRINT "ChooseFontA failed. Error: 0x"; LCASE$(HEX$(CommDlgExtendedError&))
  ELSE: PRINT "Entry was cancelled!"
  END IF
END IF
END FUNCTION





DIM hWnd AS _OFFSET
DIM hIcon AS _OFFSET
DIM t AS STRING
DIM notifydata AS NOTIFYICONDATA
notifydata.cbSize = LEN(notifydata)

t = "qb64 notification test"
_TITLE t
t = t + CHR$(0)
hWnd = _WINDOWHANDLE 'FindWindowA(0, _OFFSET(t)) 'find window ID
IF hWnd = 0 THEN
 PRINT "FindWindowA failed. Error: 0x" + LCASE$(HEX$(GetLastError))
 END
END IF

hIcon = LoadIconA(0, IDI_ASTERISK)
IF hIcon = 0 THEN
 PRINT "LoadIconA failed. Error: 0x" + LCASE$(HEX$(GetLastError))
END IF
'first notification
notifydata.hWnd = hWnd
notifydata.uID = 0
notifydata.uFlags = NIF_ICON OR NIF_TIP OR NIF_INFO
notifydata.hIcon = hIcon
notifydata.szTip = "Connect charger!" + CHR$(0) 'tool tip
notifydata.szInfo = "Recharge" + CHR$(0) 'information
notifydata.uTimeout = 10000 'milliseconds
notifydata.szInfoTitle = "Low Battery" + CHR$(0) 'balloon title FALSE LOW BATTERY warning
notifydata.dwInfoFlags = NIIF_INFO

IF 0 = Shell_NotifyIconA(NIM_ADD, _OFFSET(notifydata)) THEN
 PRINT "Shell_NotifyIconA failed. Error: 0x" + LCASE$(HEX$(GetLastError))
 END
END IF

PRINT "Press any key to modify it."
SLEEP: DO WHILE LEN(INKEY$): LOOP

hIcon = LoadIconA(0, IDI_HAND)
IF hIcon = 0 THEN
 PRINT "LoadIconA failed. Error: 0x" + LCASE$(HEX$(GetLastError))
END IF
'second notification
notifydata.uFlags = NIF_ICON OR NIF_TIP OR NIF_INFO
notifydata.hIcon = hIcon
notifydata.szTip = "hahaha" + CHR$(0)
notifydata.szInfo = ":-)" + CHR$(0)
notifydata.uTimeout = 10000 'milliseconds
notifydata.szInfoTitle = "Howdy." + CHR$(0)
notifydata.dwInfoFlags = NIIF_WARNING

IF 0 = Shell_NotifyIconA(NIM_MODIFY, _OFFSET(notifydata)) THEN
 PRINT "Shell_NotifyIconA failed. Error: 0x" + LCASE$(HEX$(GetLastError))
 END
END IF


PRINT "Press any key to delete the notification icon."
SLEEP: DO WHILE LEN(INKEY$): LOOP

IF 0 = Shell_NotifyIconA(NIM_DELETE, _OFFSET(notifydata)) THEN
 PRINT "Shell_NotifyIconA failed. Error: 0x" + LCASE$(HEX$(GetLastError))
 END
END IF

END


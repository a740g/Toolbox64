'***
' FORMAT.BI - Include file for Format functions
'
'       Copyright <C> 1989 Microsoft Corporation
'
' Purpose - This file is included in user's Basic program to declare
'           Format functions that are in Add-On libraries.
'
'***********************************************************************

DECLARE FUNCTION FormatI$ (a as integer, b as string)
DECLARE FUNCTION FormatL$ (a as long, b as string)
DECLARE FUNCTION FormatS$ (a as single, b as string)
DECLARE FUNCTION FormatD$ (a as double, b as string)
DECLARE FUNCTION FormatF$ (a as _float, b as string)
DECLARE SUB SetFormatCC (byval a%)

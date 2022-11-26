' Include file for the Financial Functions ToolKit routines.
'
' This file should be included in any application
' using the Financial functions routines.
' It contains declarations for all of the
' user-accessible routines. 
'
' Copyright (C) 1982-1992 Microsoft Corporation
'

DECLARE FUNCTION DDB# (ByVal cost#, ByVal salvage#, ByVal life#, ByVal period#,Status%)
DECLARE FUNCTION FV# (ByVal ratee#, ByVal nperr#, ByVal pmtt#, ByVal pvv#, ByVal tpe%,Status%)
DECLARE FUNCTION IPmt# (ByVal ratee#, ByVal per#, ByVal nperr#, ByVal pvv#, ByVal fvv#, ByVal tpe%,Status%)
DECLARE FUNCTION IRR# (values#(), ByVal cvalues%, ByVal guess#,Status%)
DECLARE FUNCTION MIRR# (values#(), ByVal cvalues%, ByVal finance#, ByVal reinvest#,Status%)
DECLARE FUNCTION NPer# (ByVal ratee#, ByVal pmtt#, ByVal pvv#, ByVal fvv#, ByVal tpe%,Status%)
DECLARE FUNCTION NPV# (ByVal ratee#, values#(), ByVal cvalues%,Status%)
DECLARE FUNCTION Pmt# (ByVal ratee#, ByVal nperr#, ByVal pvv#, ByVal fvv#, ByVal tpe%,Status%)
DECLARE FUNCTION PPmt# (ByVal ratee#, ByVal per#, ByVal nperr#, ByVal pvv#, ByVal fvv#, ByVal tpe%,Status%)
DECLARE FUNCTION PV# (ByVal ratee#, ByVal nperr#, ByVal pmtt#, ByVal fvv#, ByVal tpe%,Status%)
DECLARE FUNCTION Rate# (ByVal nperr#, ByVal pmtt#, ByVal pvv#, ByVal fvv#, ByVal tpe%, ByVal guess#,Status%)
DECLARE FUNCTION SLN# (ByVal cost#, ByVal salvage#, ByVal life#,Status%)
DECLARE FUNCTION SYD# (ByVal cost#, ByVal salvage#, ByVal life#, ByVal per#,Status%)

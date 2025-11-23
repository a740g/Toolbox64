' ==============================================================================
' qbCatch: Minimalistic test framework library for QB64-PE
' Copyright (c) 2025, Samuel Gomes
' ------------------------------------------------------------------------------
' Usage:
'   TEST_BEGIN_ALL
'       TEST_CASE_BEGIN "Name"
'           ... assertions ...
'       TEST_CASE_END
'   TEST_END_ALL
'
' API:
'   TEST_REQUIRE(cond, "expr")
'   TEST_REQUIRE2(cond)
'   TEST_REQUIRE_FALSE(cond, "expr")
'   TEST_REQUIRE_FALSE2(cond)
'   TEST_CHECK(cond, "expr")
'   TEST_CHECK2(cond)
'   TEST_CHECK_FALSE(cond, "expr")
'   TEST_CHECK_FALSE2(cond)
'   TEST_ABORTED() ' returns _TRUE when current test has been marked to abort
'   TEST_ENABLE_COLOR(enable) ' _TRUE to enable (default), _FALSE to disable
' ==============================================================================

$INCLUDEONCE

'$INCLUDE:'../Core/Common.bi'
'$INCLUDE:'../IO/StandardIO.bi'

$CONSOLE

CONST __TEST_COLOR_HEADER = 36 ' light cyan
CONST __TEST_COLOR_PASS = 32 ' light green
CONST __TEST_COLOR_FAIL = 31 ' light red
CONST __TEST_COLOR_SKIP = 33 ' yellow
CONST __TEST_COLOR_NOTE = 90 ' dark gray
CONST __TEST_COLOR_NAME = 97 ' white
CONST __TEST_COLOR_ARROW = 94 ' light blue
CONST __TEST_COLOR_KIND = 35 ' magenta
CONST __TEST_SEPARATOR_WIDTH = 60

TYPE __TestState
    testsRun AS LONG
    assertions AS LONG
    failures AS LONG
    currentTestName AS STRING
    currentTestChecks AS LONG
    currentTestFails AS LONG
    abortCurrentTest AS _BYTE
    skipCurrentTest AS _BYTE
    testStart AS _UNSIGNED _INTEGER64
    filter AS STRING
    colorEnabled AS _BYTE
END TYPE

DIM __TestState AS __TestState

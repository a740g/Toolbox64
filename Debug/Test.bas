'-----------------------------------------------------------------------------------------------------------------------
' Minimalistic test framework library
' Copyright (c) 2025, Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Test.bi'

SUB TEST_BEGIN_ALL
    SHARED __TestState AS __TestState

    __TestState.colorEnabled = _TRUE
    __TestState.testsRun = 0
    __TestState.assertions = 0
    __TestState.failures = 0

    __TestState.filter = _TRIM$(COMMAND$)

    __TestSetColor __TEST_COLOR_HEADER: StandardIO_WriteLine "Minimalistic test framework library for QB64-PE"
    __TestSetColor __TEST_COLOR_NOTE: StandardIO_WriteLine STRING$(__TEST_SEPARATOR_WIDTH, "-")

    IF LEN(__TestState.filter) THEN
        __TestSetColor __TEST_COLOR_NOTE: StandardIO_WriteLine "Filter: " + _CHR_QUOTE + __TestState.filter + _CHR_QUOTE
    END IF

    __TestResetColor
END SUB

SUB TEST_END_ALL
    SHARED __TestState AS __TestState

    __TestSetColor __TEST_COLOR_NOTE: StandardIO_WriteLine STRING$(__TEST_SEPARATOR_WIDTH, "-")
    __TestSetColor __TEST_COLOR_NOTE: StandardIO_Write "Tests run :": __TestSetColor __TEST_COLOR_NAME: StandardIO_WriteLine STR$(__TestState.testsRun)
    __TestSetColor __TEST_COLOR_NOTE: StandardIO_Write "Asserts   :": __TestSetColor __TEST_COLOR_NAME: StandardIO_WriteLine STR$(__TestState.assertions)
    __TestSetColor __TEST_COLOR_NOTE: StandardIO_Write "Failures  :": __TestSetColor __TEST_COLOR_NAME: StandardIO_WriteLine STR$(__TestState.failures)

    IF __TestState.failures THEN
        __TestSetColor __TEST_COLOR_FAIL: StandardIO_WriteLine "RESULT    : FAILURE"
    ELSE
        __TestSetColor __TEST_COLOR_PASS: StandardIO_WriteLine "RESULT    : SUCCESS"
    END IF

    __TestResetColor
END SUB

SUB TEST_CASE_BEGIN (testName AS STRING)
    DECLARE LIBRARY
        FUNCTION __Test_GetTicks~&& ALIAS "GetTicks"
    END DECLARE

    SHARED __TestState AS __TestState

    __TestState.currentTestName = testName
    __TestState.currentTestChecks = 0
    __TestState.currentTestFails = 0
    __TestState.abortCurrentTest = _FALSE
    __TestState.skipCurrentTest = _FALSE
    __TestState.testsRun = __TestState.testsRun + 1
    __TestState.testStart = __Test_GetTicks

    IF LEN(__TestState.filter) THEN
        IF INSTR(UCASE$(testName), UCASE$(__TestState.filter)) = 0 THEN
            __TestState.skipCurrentTest = _TRUE
            __TestState.abortCurrentTest = _TRUE
        END IF
    END IF

    __TestSetColor __TEST_COLOR_ARROW: StandardIO_Write "->": __TestResetColor: StandardIO_WriteChar _ASC_SPACE
    __TestSetColor __TEST_COLOR_NAME: StandardIO_Write testName
    IF __TestState.skipCurrentTest THEN
        StandardIO_WriteChar _ASC_SPACE
        __TestPrintTag "SKIP", __TEST_COLOR_SKIP
    END IF
    StandardIO_WriteLine _STR_EMPTY

    __TestResetColor
END SUB

SUB TEST_CASE_END
    SHARED __TestState AS __TestState

    DIM durMs AS _UNSIGNED _INTEGER64: durMs = __Test_GetTicks - __TestState.testStart

    StandardIO_Write "  "
    IF __TestState.skipCurrentTest THEN
        __TestPrintTag "SKIP", __TEST_COLOR_SKIP
        __TestSetColor __TEST_COLOR_NOTE: StandardIO_WriteLine "(0 asserts, 0 fails," + STR$(durMs) + " ms)"
    ELSEIF __TestState.currentTestFails = 0 THEN
        __TestPrintTag "OK", __TEST_COLOR_PASS
        __TestSetColor __TEST_COLOR_NOTE: StandardIO_WriteLine "(" + _TOSTR$(__TestState.currentTestChecks) + " asserts, 0 fails," + STR$(durMs) + " ms)"
    ELSE
        __TestPrintTag "FAIL", __TEST_COLOR_FAIL
        __TestSetColor __TEST_COLOR_NOTE: StandardIO_WriteLine "(" + _TOSTR$(__TestState.currentTestChecks) + " asserts," + STR$(__TestState.currentTestFails) + " fails," + STR$(durMs) + " ms)"
    END IF

    __TestResetColor
END SUB

SUB TEST_CHECK (cond AS _INTEGER64, expr AS STRING)
    SHARED __TestState AS __TestState

    IF __TestState.abortCurrentTest THEN EXIT SUB

    __TestState.assertions = __TestState.assertions + 1
    __TestState.currentTestChecks = __TestState.currentTestChecks + 1

    IF cond THEN EXIT SUB

    __TestState.failures = __TestState.failures + 1
    __TestState.currentTestFails = __TestState.currentTestFails + 1
    __TestPrintFailure "TEST_CHECK", expr
END SUB

SUB TEST_CHECK2 (cond AS _INTEGER64)
    TEST_CHECK cond, _STR_EMPTY
END SUB

SUB TEST_CHECK_FALSE (cond AS _INTEGER64, expr AS STRING)
    SHARED __TestState AS __TestState

    IF __TestState.abortCurrentTest THEN EXIT SUB

    __TestState.assertions = __TestState.assertions + 1
    __TestState.currentTestChecks = __TestState.currentTestChecks + 1

    IF _NEGATE cond THEN EXIT SUB

    __TestState.failures = __TestState.failures + 1
    __TestState.currentTestFails = __TestState.currentTestFails + 1
    __TestPrintFailure "TEST_CHECK_FALSE", expr
END SUB

SUB TEST_CHECK_FALSE2 (cond AS _INTEGER64)
    TEST_CHECK_FALSE cond, _STR_EMPTY
END SUB

SUB TEST_REQUIRE (cond AS _INTEGER64, expr AS STRING)
    SHARED __TestState AS __TestState

    IF __TestState.abortCurrentTest THEN EXIT SUB

    __TestState.assertions = __TestState.assertions + 1
    __TestState.currentTestChecks = __TestState.currentTestChecks + 1

    IF cond THEN EXIT SUB

    __TestState.failures = __TestState.failures + 1
    __TestState.currentTestFails = __TestState.currentTestFails + 1
    __TestPrintFailure "TEST_REQUIRE", expr
    __TestState.abortCurrentTest = _TRUE
END SUB

SUB TEST_REQUIRE2 (cond AS _INTEGER64)
    TEST_REQUIRE cond, _STR_EMPTY
END SUB

SUB TEST_REQUIRE_FALSE (cond AS _INTEGER64, expr AS STRING)
    SHARED __TestState AS __TestState

    IF __TestState.abortCurrentTest THEN EXIT SUB

    __TestState.assertions = __TestState.assertions + 1
    __TestState.currentTestChecks = __TestState.currentTestChecks + 1

    IF _NEGATE cond THEN EXIT SUB

    __TestState.failures = __TestState.failures + 1
    __TestState.currentTestFails = __TestState.currentTestFails + 1
    __TestPrintFailure "TEST_REQUIRE_FALSE", expr
    __TestState.abortCurrentTest = _TRUE
END SUB

SUB TEST_REQUIRE_FALSE2 (cond AS _INTEGER64)
    TEST_REQUIRE_FALSE cond, _STR_EMPTY
END SUB

FUNCTION TEST_ABORTED%%
    SHARED __TestState AS __TestState
    TEST_ABORTED = __TestState.abortCurrentTest
END FUNCTION

SUB TEST_ENABLE_COLOR (enable AS _INTEGER64)
    SHARED __TestState AS __TestState
    __TestState.colorEnabled = (enable <> _FALSE)
END SUB

SUB __TestSetColor (fg AS _UNSIGNED _BYTE)
    SHARED __TestState AS __TestState
    IF __TestState.colorEnabled THEN StandardIO_Write _CHR_ESC + "[" + _TOSTR$(fg) + "m"
END SUB

SUB __TestResetColor
    SHARED __TestState AS __TestState
    IF __TestState.colorEnabled THEN StandardIO_Write _CHR_ESC + "[0m"
END SUB

SUB __TestPrintTag (tag AS STRING, fg AS _UNSIGNED _BYTE)
    __TestSetColor fg: StandardIO_Write "[" + tag + "] "
    __TestResetColor
END SUB

SUB __TestPrintFailure (kind AS STRING, expr AS STRING)
    __TestSetColor __TEST_COLOR_FAIL: StandardIO_Write "    "
    __TestPrintTag "FAIL", __TEST_COLOR_FAIL
    IF LEN(expr) THEN
        __TestSetColor __TEST_COLOR_KIND: StandardIO_Write kind + ": "
        __TestSetColor __TEST_COLOR_NAME: StandardIO_WriteLine expr
    ELSE
        __TestSetColor __TEST_COLOR_KIND: StandardIO_WriteLine kind
    END IF

    __TestResetColor
END SUB

'$INCLUDE:'../IO/StandardIO.bas'

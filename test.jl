# test.jl: Used to run integration tests on jlox

struct IntegTest
    path::String
    expected_res::String
end

integration_tests = [
    IntegTest("empty_file.lox", ""),
    IntegTest("precedence.lox", """14
    8
    4
    0
    true
    true
    true
    true
    0
    0
    0
    0
    4
    """),
    IntegTest("unexpected_character.lox", "[line 3] Error: Unexpected character '|'\n"),
    IntegTest("assignment/associativity.lox","""c
    c
    c
    """),
    IntegTest("assignment/global.lox", """before
    after
    arg
    arg
    """),
    IntegTest("assignment/grouping.lox", "[line 2] Error: Error at '=': Invalid assignment target.\n"),
    IntegTest("assignment/infix_operator.lox", "[line 3] Error: Error at '=': Invalid assignment target.")
]

if size(ARGS)[1] != 1
    println("Usage: test.jl <test folder>")
else
    test_folder = ARGS[1]
    for test in integration_tests
        result = read(ignorestatus(`julia jlox.jl $test_folder/$(test.path)`), String)
        if result == test.expected_res
            println("$(test.path): OK")
        else
            println("$(test.path): KO")
        end
    end
end


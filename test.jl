# test.jl: Used to run integration tests on jlox

struct IntegTest
    path::String
    expected_res::String
end

integration_tests = [
    
]

if size(ARGS)[1] != 1
    println("Usage: test.jl <test folder>")
else
    test_folder = ARGS[1]
    for test in integration_tests
        result = read(`julia jlox $test_folder/$path`, String)
        if result == expected
            println("$path: OK")
        else
            println("$path: KO")
        end
    end
end


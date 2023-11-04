include("scanner.jl")
include("parser.jl")


function execute_file(file)
    tokens = run(readlines(file))
    println(tokens)
end

function repl()
    
end

function run(code)
    tokens = scan(code)
    parse(tokens)
end


if size(ARGS)[1] == 0
    repl()
elseif size(ARGS)[1] == 1
    execute_file(ARGS[1])
else
    println("Usage: ")
    println("jlox [script.lox]")
    exit(64)
end
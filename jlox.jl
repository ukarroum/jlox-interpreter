include("scanner.jl")
include("parser.jl")
include("interpreter.jl")


function execute_file(file)
    result = run(read(file, String))
    println(result)
end

function repl()
    
end

function run(code)
    tokens = scan(code)
    ast = parse_tokens(tokens)
    interpret(ast)
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
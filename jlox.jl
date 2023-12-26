include("scanner.jl")
include("parser.jl")
include("interpreter.jl")


function execute_file(file)
    run(read(file, String))
end

function repl()
    while true
        print(">> ")
        line = readline()
        if line == ""
            break
        end
        
        run(line)
    end
end

function run(code)
    tokens = scan(code)
    ast::Vector{Stmt} = parse_tokens(tokens)
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
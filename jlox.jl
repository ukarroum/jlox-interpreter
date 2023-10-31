include("tokens.jl")

function execute_file(file)
    run(readlines(file))
end

function repl()
    
end


function run(code)
    tokens = Token[]

    for line in code
        for c in line
            print(c)
        end
    end
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
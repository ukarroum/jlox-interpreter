include("scanner.jl")
include("parser.jl")

struct Env
    vars
    enclosing
end

struct LoxCallable
    arity::Int
    call
end

struct ReturnEx <: Exception
    val
end

struct Closure
    fct::Function
    env::Env
end


function get_var(env, var_name)
    if haskey(env.vars, var_name)
        env.vars[var_name]
    elseif !isnothing(env.enclosing)
        get_var(env.enclosing, var_name)
    else
        Base.error("Undefined variable $var_name")
    end
end

function set_var(env, var_name, val)
    if haskey(env.vars, var_name)
        env.vars[var_name] = val
    elseif !isnothing(env.enclosing)
        set_var(env.enclosing, var_name, val)
    else
        Base.error("Undefined variable $var_name")
    end
end

function interpret(stmts)
    env = Env(Dict(), nothing)

    env.vars["clock"] = LoxCallable(0, time)

    for stmt in stmts
        evaluate(stmt, env)
    end
end

function evaluate(expr::Literal, env)
    expr.value
end

function evaluate(expr::Grouping, env)
    evaluate(expr.expression, env)
end

function evaluate(expr::Unary, env)
    right = evaluate(expr.right, env)

    if expr.operator.type == MINUS
        return -right
    elseif expr.operator.type == BANG
        # unfortunetly julia doesn't support a form of "istruthy", we'll need to reimplement it ourselves
        if right isa Number
            right != 0
        end
    end
end

function evaluate(expr::Binary, env)
    bin_ops = Dict(
        BANG_EQUAL => !=,
        EQUAL_EQUAL => ==,
        GREATER => >,
        GREATER_EQUAL => >=,
        LESS => <,
        LESS_EQUAL => <=,
        MINUS => -,
        PLUS => +,
        SLASH => /,
        STAR => *
    )
    left = evaluate(expr.left, env)
    right = evaluate(expr.right, env)

    # special case for string concat
    if left isa String && right isa String
        if expr.operator.type == STAR
            Base.error("Operation * not permited on strings")
        end

        if expr.operator.type == PLUS
            return left * right
        end
    end

    bin_ops[expr.operator.type](left, right)
end

function evaluate(expr::Stmt, env)
    evaluate(expr.expr, env)
    return
end

function evaluate(expr::Print, env)
    println(evaluate(expr.expr, env))
end

function evaluate(expr::Var, env)
    env.vars[expr.name.lexeme] = !isnothing(expr.val) ? evaluate(expr.val, env) : nothing
    return
end

function evaluate(expr::Variable, env)
    get_var(env, expr.name)
end

function evaluate(expr::Assign, env)
    set_var(env, expr.name, evaluate(expr.val, env))
end

function evaluate(expr::Block, env)
    local_env = Env(Dict(), env)

    execute_block(expr, local_env)
end

function execute_block(expr::Block, env)
    for stmt in expr.stmts
        evaluate(stmt, env)
    end
end

function evaluate(expr::IfStmt, env)
    if evaluate(expr.condition, env)
        evaluate(expr.thenBr, env)
    elseif !isnothing(expr.elseBr)
        evaluate(expr.elseBr, env)
    end

    return
end

function evaluate(expr::Logical, env)
    left = evaluate(expr.left, env)

    if expr.operator.type == OR
        if left
            return left
        end
    else !left
        return left
    end
    
    evaluate(expr.right, env)
end

function evaluate(expr::While, env)
    while evaluate(expr.condition, env)
        evaluate(expr.body, env)
    end

    return
end

function evaluate(expr::Call, env)
    arguments = []

    for arg in expr.args
        push!(arguments, evaluate(arg, env))
    end

    call(get_var(env, expr.callee.name), arguments)
end

function evaluate(expr::Function, env)
    env.vars[expr.name.lexeme] = Closure(expr, env)
end

function evaluate(expr::Return, env)
    ret = nothing

    if !isnothing(expr)
        ret = evaluate(expr.val, env)
    end

    throw(ReturnEx(ret))
end

function call(closure::Closure, args)
    fct_env = Env(Dict(), closure.env)

    for i = 1:size(args)[1]
        fct_env.vars[closure.fct.params[i]] = args[i]
    end

    try
        execute_block(Block(closure.fct.body), fct_env)
    catch e
        if e isa ReturnEx
            return e.val
        else
            rethrow(e)
        end
    end
end
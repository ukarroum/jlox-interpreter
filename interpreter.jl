include("scanner.jl")
include("parser.jl")
include("resolver.jl")

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

function interpret(stmts::Vector{Stmt})
    env = Env(Dict(), nothing)
    locals = Dict()

    env.vars["clock"] = LoxCallable(0, time)

    resolve(stmts, [], locals)

    for stmt in stmts
        evaluate(stmt, env, locals)
    end
end

function evaluate(expr::Literal, env, locals)
    expr.value
end

function evaluate(expr::Grouping, env, locals)
    evaluate(expr.expression, env, locals)
end

function evaluate(expr::Unary, env, locals)
    right = evaluate(expr.right, env, locals)

    if expr.operator.type == MINUS
        return -right
    elseif expr.operator.type == BANG
        # unfortunetly julia doesn't support a form of "istruthy", we'll need to reimplement it ourselves
        if right isa Number
            right != 0
        end
    end
end

function evaluate(expr::Binary, env, locals)
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
    left = evaluate(expr.left, env, locals)
    right = evaluate(expr.right, env, locals)

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

function evaluate(expr::Stmt, env, locals)
    evaluate(expr.expr, env, locals)
    return
end

function evaluate(expr::Print, env, locals)
    println(evaluate(expr.expr, env, locals))
end

function evaluate(expr::Var, env, locals)
    env.vars[expr.name.lexeme] = !isnothing(expr.val) ? evaluate(expr.val, env, locals) : nothing
    return
end

function evaluate(expr::Variable, env, locals)
    lookup_var(expr.name, expr, env, locals)
end

function lookup_var(name, expr, env, locals)
    new_env = env
    if haskey(locals, expr)
        i = locals[expr]
        while i > 0
            new_env = env.enclosing
            i -= 1
        end
    else
        while !isnothing(new_env.enclosing)
            new_env = env.enclosing
        end
    end

    new_env.vars[name]
end

function evaluate(expr::Assign, env, locals)
    new_env = env
    if haskety(locals, name)
        for i in 1:locals[name]
            new_env = env.enclosing
        end
    else
        while !isnothing(new_env.enclosing)
            new_env = env.enclosing
        end
    end

    new_env.vars[expr.name] = evaluate(expr.val, env, locals)
end

function evaluate(expr::Block, env, locals)
    local_env = Env(Dict(), env)

    execute_block(expr, local_env, locals)
end

function execute_block(expr::Block, env, locals)
    for stmt in expr.stmts
        evaluate(stmt, env, locals)
    end
end

function evaluate(expr::IfStmt, env, locals)
    if evaluate(expr.condition, env, locals)
        evaluate(expr.thenBr, env, locals)
    elseif !isnothing(expr.elseBr)
        evaluate(expr.elseBr, env, locals)
    end

    return
end

function evaluate(expr::Logical, env, locals)
    left = evaluate(expr.left, env, locals)

    if expr.operator.type == OR
        if left
            return left
        end
    else !left
        return left
    end
    
    evaluate(expr.right, env, locals)
end

function evaluate(expr::While, env, locals)
    while evaluate(expr.condition, env, locals)
        evaluate(expr.body, env, locals)
    end

    return
end

function evaluate(expr::Call, env, locals)
    arguments = []

    for arg in expr.args
        push!(arguments, evaluate(arg, env, locals))
    end

    call(get_var(env, expr.callee.name), arguments, locals)
end

function evaluate(expr::Function, env, locals)
    env.vars[expr.name.lexeme] = Closure(expr, env)
end

function evaluate(expr::Return, env, locals)
    ret = nothing

    if !isnothing(expr)
        ret = evaluate(expr.val, env, locals)
    end

    throw(ReturnEx(ret))
end

function call(closure::Closure, args, locals)
    fct_env = Env(Dict(), closure.env)

    for i = 1:size(args)[1]
        fct_env.vars[closure.fct.params[i]] = args[i]
    end

    try
        execute_block(Block(closure.fct.body), fct_env, locals)
    catch e
        if e isa ReturnEx
            return e.val
        else
            rethrow(e)
        end
    end
end
include("scanner.jl")
include("parser.jl")

struct Env
    vars
    enclosing
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
    env.vars[expr.name.lexeme] = evaluate(expr.val, env)
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
    while expr.condition
        evaluate(expr.body, env)
    end

    return
end
include("parser.jl")

function resolve(expr::Block, scopes, locals)
    begin_scope(scopes)
    resolve(expr.stmts, scopes, locals)
    end_scope(scopes)
end

function resolve(expr::Vector{Stmt}, scopes, locals)
    for stmt in expr
        resolve(stmt, scopes, locals)
    end
end

function resolve(expr::Stmt, scopes, locals)
    resolve(expr.expr, scopes, locals)
end

function begin_scope(scopes)
    push!(scopes, Dict())
end

function end_scope(scopes)
    pop!(scopes)
end

function resolve(expr::Var, scopes, locals)
    declare(expr.name.lexeme, scopes)
    if !isnothing(expr.val)
        resolve(expr.val, scopes, locals)
    end
    define(expr.name.lexeme, scopes)
end

function declare(name, scopes)
    if !isempty(scopes)
        if haskey(scopes[end], name)
            Base.error("Variable already declared with the same name at this local scope")
        end
        scopes[end][name] = false
    end
end

function define(name, scopes)
    if !isempty(scopes)
        scopes[end][name] = true
    end
end

function resolve(expr::Variable, scopes, locals)
    if !isempty(scopes) && get(scopes[end], expr.name, nothing) == false
        Base.error("Cannot use a variable in its own definition")
    end

    resolve_local(expr, expr.name, scopes, locals)
end

function resolve(expr::This, scopes, locals)
    resolve_local(expr, expr.keyword.lexeme, scopes, locals)
end

function resolve_local(expr, name, scopes, locals)
    for i in reverse(eachindex(scopes))
        if haskey(scopes[i], name)
            locals[expr] = size(scopes)[1] - i
            return
        end
    end
end

function resolve(expr::Assign, scopes, locals)
    resolve(expr.val, scopes, locals)
    resolve_local(expr, expr.name, scopes, locals)
end

function resolve(expr::Function, scopes, locals)
    declare(expr.name.lexeme, scopes)
    define(expr.name.lexeme, scopes)

    resolve_function(expr, scopes, locals)
end

function resolve_function(fct::Function, scopes, locals)
    begin_scope(scopes)

    for param in fct.params
        declare(param, scopes)
        define(param, scopes)
    end

    resolve(fct.body, scopes, locals)
    end_scope(scopes)
end

function resolve(expr::IfStmt, scopes, locals)
    resolve(expr.condition, scopes, locals)
    resolve(expr.thenBr, scopes, locals)
    if !isnothing(expr.elseBr)
        resolve(expr.elseBr, scopes, locals)
    end
end

function resolve(expr::Print, scopes, locals)
    resolve(expr.expr, scopes, locals)
end

function resolve(expr::Return, scopes, locals)
    if !isnothing(expr.val)
        resolve(expr.val, scopes, locals)
    end
end

function resolve(expr::While, scopes, locals)
    resolve(expr.condition, scopes, locals)
    resolve(expr.body, scopes, locals)
end

function resolve(expr::Binary, scopes, locals)
    resolve(expr.left, scopes, locals)
    resolve(expr.right, scopes, locals)
end

function resolve(expr::Call, scopes, locals)
    resolve(expr.callee, scopes, locals)

    for arg in expr.args
        resolve(arg, scopes, locals)
    end
end

function resolve(expr::Grouping, scopes, locals)
    resolve(expr.expression, scopes, locals)
end

function resolve(expr::Literal, scopes, locals) end

function resolve(expr::Logical, scopes, locals)
    resolve(expr.left, scopes, locals)
    resolve(expr.right, scopes, locals)
end

function resolve(expr::Unary, scopes, locals)
    resolve(expr.right, scopes, locals)
end

function resolve(expr::Class, scopes, locals)
    declare(expr.name, scopes)
    define(expr.name, scopes)

    if !isnothing(expr.superclass)
        if expr.superclass.name == expr.name.lexeme
            Base.error("Cannot inherit from own class")
        end
        resolve(expr.superclass, scopes, locals)
    end

    if !isnothing(expr.superclass)
        begin_scope(scopes)
        scopes[end]["super"] = true
    end

    begin_scope(scopes)
    scopes[end]["this"] = true

    for method in expr.methods
        resolve_function(method, scopes, locals)
    end

    if !isnothing(expr.superclass)
        end_scope(scopes)
    end

    end_scope(scopes)
end

function resolve(expr::Super, scopes, locals)
    resolve_local(expr, expr.keyword.lexeme, scopes, locals)
end

function resolve(expr::Get, scopes, locals)
    resolve(expr.obj, scopes, locals)
end

function resolve(expr::Set, scopes, locals)
    resolve(expr.obj, scopes, locals)
    resolve(expr.val, scopes, locals)
end
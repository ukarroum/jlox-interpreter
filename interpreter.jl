include("scanner.jl")
include("parser.jl")

function interpret(stmts)
    for stmt in stmts
        evaluate(stmt)
    end
end

function evaluate(expr::Literal)
    expr.value
end

function evaluate(expr::Grouping)
    evaluate(expr.expression)
end

function evaluate(expr::Unary)
    right = evaluate(expr.right)

    if expr.operator.type == MINUS
        return -right
    elseif expr.operator.type == BANG
        # unfortunetly julia doesn't support a form of "istruthy", we'll need to reimplement it ourselves
        if right isa Number
            right != 0
        end
    end
end

function evaluate(expr::Binary)
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
    left = evaluate(expr.left)
    right = evaluate(expr.right)

    bin_ops[expr.operator.type](left, right)
end

function evaluate(expr::Stmt)
    evaluate(expr.expr)
    return
end

function evaluate(expr::Print)
    println(evaluate(expr.expr))
end

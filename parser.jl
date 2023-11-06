include("tokens.jl")

abstract type Expr end
abstract type Stmt end

struct Binary <: Expr
    left::Expr
    operator::Token
    right::Expr
end

struct Grouping <: Expr
    expression::Expr
end

struct Literal <: Expr
    value
end

struct Unary <: Expr
    operator::Token
    right::Expr
end

struct ExprStmt <: Stmt
    expr::Expr
end

struct Print <: Stmt
    expr::Expr
end


function match(tokens, token_types...)
    if isempty(tokens)
        return tokens, nothing
    end
    

    for token_type in token_types
        if tokens[1].type == token_type  
            return tokens[2:end], tokens[1]
        end
    end

    return tokens, nothing
end


function statement(tokens)
    if tokens[1].type == PRINT
        printexpr(tokens[2:end])
    else
        exprstmt(tokens)
    end
end

function exprstmt(tokens)
    tokens, expr = expression(tokens)

    tokens, token = match(tokens, SEMICOLON)

    if isnothing(token)
        Base.error("Parsing issue, missing ';'")
    end

    return tokens, ExprStmt(expr)
end

function printexpr(tokens)
    tokens, expr = expression(tokens)

    tokens, token = match(tokens, SEMICOLON)

    if isnothing(token)
        Base.error("Parssing issue, missing ';'")
    end

    return tokens, Print(expr)
end

function expression(tokens)
    equality(tokens)
end


function equality(tokens)
    tokens, expr = comparison(tokens)

    tokens, operator = match(tokens, BANG_EQUAL, EQUAL_EQUAL)
    while !isnothing(operator)
        tokens, right = comparison(tokens)
        expr = Binary(expr, operator, right)

        tokens, operator = match(tokens, BANG_EQUAL, EQUAL_EQUAL)
    end

    tokens, expr
end

function comparison(tokens)
    tokens, expr = term(tokens)

    tokens, operator = match(tokens, GREATER, GREATER_EQUAL, LESS, LESS_EQUAL)
    while !isnothing(operator)
        tokens, right = term(tokens)
        expr = Binary(expr, operator, right)

        tokens, operator = match(tokens, GREATER, GREATER_EQUAL, LESS, LESS_EQUAL)
    end

    tokens, expr
end

function term(tokens)
    tokens, expr = factor(tokens)

    tokens, operator = match(tokens, MINUS, PLUS)
    while !isnothing(operator)
        tokens, right = factor(tokens)
        expr = Binary(expr, operator, right)

        tokens, operator = match(tokens, MINUS, PLUS)
    end

    tokens, expr
end

function factor(tokens)
    tokens, expr = unary(tokens)

    tokens, operator = match(tokens, SLASH, STAR)
    while !isnothing(operator)
        tokens, right = unary(tokens)
        expr = Binary(expr, operator, right)

        tokens, operator = match(tokens, SLASH, STAR)
    end

    tokens, expr
end

function unary(tokens)
    tokens, operator = match(tokens, BANG, MINUS)

    if !isnothing(operator)
        tokens, expr = unary(tokens)
        return tokens, Unary(operator, expr)
    end
    
    primary(tokens)
end

function primary(tokens)
    tokens, token = match(tokens, NUMBER, STRING, TRUE, FALSE, NIL)

    if !isnothing(token)
        return tokens, Literal(token.literal)
    else
        tokens, token = match(tokens, RIGHT_PAREN)
        if !isnothing(token)
            tokens, expr = expression(tokens)
            tokens, token = match(tokens, LEFT_PAREN)
            if !isnothing(token)
                return tokens, Grouping(expr)
            end
        end
    end
end


function parse_tokens(tokens)
    ast = []

    while(tokens[1].type != EOF)
        tokens, stmt = statement(tokens)
        push!(ast, stmt)
    end

    ast
end
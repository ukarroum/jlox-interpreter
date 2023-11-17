include("tokens.jl")

abstract type Expr end
abstract type Stmt end

struct Binary <: Expr
    left::Expr
    operator::Token
    right::Expr
end

struct Call <: Expr
    callee::Expr
    args::Vector{Expr}
end

struct Grouping <: Expr
    expression::Expr
end

struct Literal <: Expr
    value
end

struct Logical <: Expr
    left::Expr
    operator::Token
    right::Expr
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

struct Var <: Stmt
    name::Token
    val::Union{Expr, Nothing}
end

struct Variable <: Expr
    name::String
end

struct Assign <: Expr
    name::String
    val::Expr
end

struct Block <: Stmt
    stmts::Vector{Stmt}
end

struct Function <: Expr
    name::Token
    params::Vector{String}
    body::Vector{Stmt}
end

struct IfStmt <: Stmt
    condition::Expr
    thenBr::Stmt
    elseBr::Union{Stmt, Nothing}
end

struct While <: Stmt
    condition::Expr
    body::Stmt
end

struct Return <: Stmt
    val::Expr
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

function declaration(tokens)
    if tokens[1].type == VAR
        var_declaration(tokens[2:end])
    elseif tokens[1].type == FUN
        function_declaration(tokens[2:end])
    else
        statement(tokens)
    end
end

function function_declaration(tokens)
    tokens, name = match(tokens, IDENTIFIER)
    if isnothing(name)
        Base.error("Expected a valid identifier after fun")
    end

    tokens, token = match(tokens, LEFT_PAREN)

    if !isnothing(token)
        arguments = []

        tokens, token = match(tokens, RIGHT_PAREN)
        while isnothing(token) || token.type != RIGHT_PAREN
            tokens, arg = expression(tokens)
            push!(arguments, arg.name)

            if size(arguments)[1] >= 255
                Base.error("Exceded 255 arguments")
            end

            tokens, token = match(tokens, COMMA, RIGHT_PAREN)
        end

        tokens, token = match(tokens, LEFT_BRACE)
        if isnothing(token)
            Base.error("Expected '{'")
        end
        tokens, f_block = block(tokens)
        tokens, Function(name, arguments, f_block.stmts)
    else
        Base.error("Expected '('")
    end
end


function var_declaration(tokens)
    tokens, identifier = match(tokens, IDENTIFIER)

    if isnothing(identifier)
        Base.error("Parsing issue missing identifier after 'var'")
    end

    tokens, token = match(tokens, EQUAL)

    if isnothing(token)
        val = nothing
    else
        tokens, val = expression(tokens)
    end

    tokens, token = match(tokens, SEMICOLON)

    if isnothing(token)
        Base.error("Parsing issue, missing ';'")
    end

    tokens, Var(identifier, val)
end


function statement(tokens)
    if tokens[1].type == FOR
        forstmt(tokens[2:end])
    elseif tokens[1].type == IF
        ifstmt(tokens[2:end])
    elseif tokens[1].type == PRINT
        printexpr(tokens[2:end])
    elseif tokens[1].type == RETURN
        returnStmt(tokens[2:end])    
    elseif tokens[1].type == WHILE
        while_stmt(tokens[2:end])
    elseif tokens[1].type == LEFT_BRACE
        block(tokens[2:end])
    else
        exprstmt(tokens)
    end
end

function returnStmt(tokens)
    val = nothing

    tokens, token = match(tokens, SEMICOLON)
    if isnothing(token)
        tokens, val = expression(tokens)
        tokens, token = match(tokens, SEMICOLON)
        if isnothing(token)
            Base.error("Expected ';'")
        end
    end

    tokens, Return(val)
end

function forstmt(tokens)
    tokens, token = match(tokens, LEFT_PAREN)
    if isnothing(token)
        Base.error("Missing '(' after for")
    end

    tokens, token = match(tokens, SEMICOLON, VAR)

    if !isnothing(token) && token.type == SEMICOLON
        initializer = nothing
    elseif !isnothing(token) && token.type == VAR
        tokens, initializer = var_declaration(tokens)
    else
        tokens, initializer = exprstmt(tokens)
    end

    tokens, token = match(tokens, SEMICOLON)

    if !isnothing(token)
        condition = nothing
    else
        tokens, condition = expression(tokens)
    end

    tokens, token = match(tokens, SEMICOLON)
    if isnothing(token)
        Base.error("Expected ';'")
    end

    tokens, token = match(tokens, RIGHT_PAREN)
    if !isnothing(token)
        incr = nothing
    else
        tokens, incr = expression(tokens)
    end

    tokens, token = match(tokens, RIGHT_PAREN)
    if isnothing(token)
        Base.error("Missing ')' after for")
    end

    tokens, body = statement(tokens)

    if !isnothing(incr)
        body = Block([body, ExprStmt(incr)])
    end

    if isnothing(condition)
        condition = Literal(true)
    end

    body = While(condition, body)

    if !isnothing(initializer)
        body = Block([initializer, body])
    end

    tokens, body
end

function while_stmt(tokens)
    tokens, token = match(tokens, RIGHT_PAREN)
    if isnothing(token)
        Base.error("Missing '(' after while")
    end

    tokens, condition = expression(tokens)

    tokens, token = match(token, LEFT_PAREN)
    if isnothing(token)
        Base.error("Missing ')' after while")
    end

    tokens, stmt = statement(tokens)
    tokens, While(condition, stmt)
end

function ifstmt(tokens)
    tokens, token = match(tokens, LEFT_PAREN)
    if isnothing(token)
        Base.error("Missing '(' after if")
    end
    
    tokens, condition = expression(tokens)

    tokens, token = match(tokens, RIGHT_PAREN)
    if isnothing(token)
        Base.error("Missing ')' after if")
    end

    tokens, thenBr = statement(tokens)

    tokens, token = match(tokens, ELSE)
    if !isnothing(token)
        elseBr = statement(tokens)
    else
        elseBr = nothing
    end
    
    tokens, IfStmt(condition, thenBr, elseBr)
end

function block(tokens)
    statements = []

    tokens, token = match(tokens, RIGHT_BRACE)

    while !isempty(tokens) && isnothing(token)
        tokens, stmt = declaration(tokens)
        push!(statements, stmt)

        tokens, token = match(tokens, RIGHT_BRACE)
    end

    if isempty(tokens)
        Base.error("Missing '}'")
    end
    
    tokens, Block(statements)
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
    assignement(tokens)
end

function assignement(tokens)
    tokens, expr = or(tokens)

    tokens, token = match(tokens, EQUAL)

    if !isnothing(token)
    
        tokens, val = assignement(tokens)

        if expr isa Variable
            return tokens, Assign(expr.name, val)
        else
            Base.error("Expected r-expression")
        end
    end
    tokens, expr
end

function or(tokens)
    tokens, left = and(tokens)

    tokens, op = match(tokens, OR)

    if !isnothing(op)
        tokens, right = and(tokens)
        tokens, Logical(left, op, right)
    else
        tokens, left
    end
end

function and(tokens)
    tokens, left = equality(tokens)

    tokens, op = match(tokens, AND)

    if !isnothing(op)
        tokens, right = equality(tokens)
        tokens, Logical(left, op, right)
    else
        tokens, left
    end
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
    
    callexpr(tokens)
end

function callexpr(tokens)
    tokens, callee = primary(tokens)

    tokens, token = match(tokens, LEFT_PAREN)

    if !isnothing(token)
        arguments = []

        tokens, token = match(tokens, RIGHT_PAREN)
        while isnothing(token) || token.type != RIGHT_PAREN
            tokens, arg = expression(tokens)
            push!(arguments, arg)

            if size(arguments)[1] >= 255
                Base.error("Exceded 255 arguments")
            end

            tokens, token = match(tokens, COMMA, RIGHT_PAREN)
        end

        tokens, Call(callee, arguments)
    else
        tokens, callee
    end
end

function primary(tokens)
    tokens, token = match(tokens, NUMBER, STRING, TRUE, FALSE, NIL, IDENTIFIER)

    if !isnothing(token)
        if token.type == IDENTIFIER
            tokens, Variable(token.lexeme)
        else
            tokens, Literal(token.literal)
        end
    else
        tokens, token = match(tokens, RIGHT_PAREN)
        if !isnothing(token)
            tokens, expr = expression(tokens)
            tokens, token = match(tokens, LEFT_PAREN)
            if !isnothing(token)
                tokens, Grouping(expr)
            else
                Base.error("Missing ')'")
            end
        end
    end
end


function parse_tokens(tokens)
    ast = []

    while(tokens[1].type != EOF)
        tokens, stmt = declaration(tokens)
        push!(ast, stmt)
    end

    ast
end
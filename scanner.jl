include("tokens.jl")


function peek_ahead(line, i)
    if i == length(line)
        return
    end
    
    line[i + 1]
end


function error(line, msg)
    println("[line $line] Error: $msg")
    exit(1)
end


function scan(code)
    keywords = Dict(
        "and" => AND,
        "class" => CLASS,
        "else" => ELSE,
        "false" => FALSE,
        "for" => FOR,
        "fun" => FUN,
        "if" => IF,
        "nil" => NIL,
        "or" => OR,
        "print" => PRINT,
        "return" => RETURN,
        "super" => SUPER,
        "this" => THIS,
        "true" => TRUE,
        "var" => VAR,
        "while" => WHILE
    )
    tokens = Token[]

    line_nb = 1
    i = 1

    while i <= length(code)
        c = code[i]

        if c == '('
            push!(tokens, Token(type=LEFT_PAREN, line=line_nb))
        elseif c == ')'
            push!(tokens, Token(type=RIGHT_PAREN, line=line_nb))
        elseif c == '{'
            push!(tokens, Token(type=LEFT_BRACE, line=line_nb))
        elseif c == '}'
            push!(tokens, Token(type=RIGHT_BRACE, line=line_nb))
        elseif c == ','
            push!(tokens, Token(type=COMMA, line=line_nb))
        elseif c == '.'
            push!(tokens, Token(type=DOT, line=line_nb))
        elseif c == '-'
            push!(tokens, Token(type=MINUS, line=line_nb))
        elseif c == '+'
            push!(tokens, Token(type=PLUS, line=line_nb))
        elseif c == ';'
            push!(tokens, Token(type=SEMICOLON, line=line_nb))
        elseif c == '*'
            push!(tokens, Token(type=STAR, line=line_nb))
        elseif c == '!'
            if peek_ahead(code, i) == '='
                push!(tokens, Token(type=BANG_EQUAL, line=line_nb))
                i += 1
            else
                push!(tokens, Token(type=BANG, line=line_nb))
            end
        elseif c == '='
            if peek_ahead(code, i) == '='
                push!(tokens, Token(type=EQUAL_EQUAL, line=line_nb))
                i += 1
            else
                push!(tokens, Token(type=EQUAL, line=line_nb))
            end
        elseif c == '<'
            if peek_ahead(code, i) == '='
                push!(tokens, Token(type=LESS_EQUAL, line=line_nb))
                i += 1
            else
                push!(tokens, Token(type=LESS, line=line_nb))
            end
        elseif c == '>'
            if peek_ahead(code, i) == '='
                push!(tokens, Token(type=GREATER_EQUAL, line=line_nb))
                i += 1
            else
                push!(tokens, Token(type=GREATER, line=line_nb))
            end
        elseif c == '/'
            if peek_ahead(code, i) == '/'
                while(i <= length(code) && code[i] != '\n')
                    i += 1
                end
                line_nb += 1
            elseif peek_ahead(code, i) == '*'
                i += 2
                while(i + 1 <= length(code) && (code[i] != '*' || code[i + 1] != '/'))
                    if(code[i] == '\n')
                        line_nb += 1
                    end
                    i += 1
                end
            else
                push!(tokens, Token(type=SLASH, line=line_nb))
            end
        elseif c == ' ' || c == '\r' || c == '\t' || c == '\n'
            i += 1
            if c == '\n'
                line_nb += 1
            end
            continue
        elseif c == '"'
            j = i + 1
            while j <= length(code) && code[j] != '"'
                if code[j] == '\n'
                    line_nb += 1
                end
                j += 1
            end
            if j > length(code)
                error(line_nb, "Unclosed string")
            else
                push!(tokens, Token(type=STRING, lexeme=code[i + 1:j - 1], literal=code[i + 1:j - 1], line=line_nb))
                i = j
            end
        elseif isnumeric(c)
            j = i + 1
            while j <= length(code) && isnumeric(code[j])
                j += 1
            end

            if j <= length(code) && code[j] == '.'
                j += 1
                while j <= length(code) && isnumeric(code[j])
                    j += 1
                end
            end
            push!(tokens, Token(type=NUMBER, lexeme=code[i:j - 1], literal=parse('.' in code[i:j - 1] ? Float64 : Int64 , code[i:j - 1]), line=line_nb))
            i = j - 1
        elseif isletter(c)
            j = i + 1
            while j <= length(code) && (isnumeric(code[j]) || isletter(code[j]))
                j += 1
            end
            lexeme = code[i:j - 1]

            if haskey(keywords, lexeme)
                if lexeme == "true"
                    literal = true
                elseif lexeme == "false"
                    literal = false
                else
                    literal = nothing
                end

                push!(tokens, Token(type=keywords[lexeme], lexeme=lexeme, literal=literal, line=line_nb))
            else
                push!(tokens, Token(type=IDENTIFIER, lexeme=lexeme, line=line_nb))
            end
            i = j - 1
        else
            error(line_nb, "Unexpected character '$c'")
        end
        i += 1
    end

    push!(tokens, Token(type=EOF, line=line_nb))

    tokens
end
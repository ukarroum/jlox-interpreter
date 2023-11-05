include("tokens.jl")


function peek_ahead(line, i)
    if i == length(line)
        return
    end
    
    line[i + 1]
end


function error(line, msg)
    println("[ERROR] Scanner: line $line - $msg")
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
    for line in code
        i = 1
        while i <= length(line)
            c = line[i]

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
                if peek_ahead(line, i) == '='
                    push!(tokens, Token(type=BANG_EQUAL, line=line_nb))
                    i += 1
                else
                    push!(tokens, Token(type=BANG, line=line_nb))
                end
            elseif c == '='
                if peek_ahead(line, i) == '='
                    push!(tokens, Token(type=EQUAL_EQUAL, line=line_nb))
                    i += 1
                else
                    push!(tokens, Token(type=EQUAL, line=line_nb))
                end
            elseif c == '<'
                if peek_ahead(line, i) == '='
                    push!(tokens, Token(type=LESS_EQUAL, line=line_nb))
                    i += 1
                else
                    push!(tokens, Token(type=LESS, line=line_nb))
                end
            elseif c == '>'
                if peek_ahead(line, i) == '='
                    push!(tokens, Token(type=GREATER_EQUAL, line=line_nb))
                    i += 1
                else
                    push!(tokens, Token(type=GREATER, line=line_nb))
                end
            elseif c == '/'
                if peek_ahead(line, i) == '/'
                    break
                else
                    push!(tokens, Token(typee=SLASH, line=line_nb))
                end
            elseif c == ' ' || c == '\r' || c == '\t' || c == '\n'
                i += 1
                continue
            elseif c == '"'
                j = i + 1
                while j <= length(line) && line[j] != '"'
                    j += 1
                end
                if j > length(line)
                    error(line_nb, "Unclosed string")
                else
                    push!(tokens, Token(type=STRING, lexeme=line[i + 1:j - 1], literal=line[i + 1:j - 1], line=line_nb))
                    i = j
                end
            elseif isnumeric(c)
                j = i + 1
                while j <= length(line) && isnumeric(line[j])
                    j += 1
                end

                if j <= length(line) && line[j] == '.'
                    j += 1
                    while j <= length(line) && isnumeric(line[j])
                        j += 1
                    end
                end
                push!(tokens, Token(type=NUMBER, lexeme=line[i:j - 1], literal=parse('.' in line[i:j - 1] ? Float64 : Int64 , line[i:j - 1]), line=line_nb))
                i = j
            elseif isletter(c)
                j = i + 1
                while j <= length(line) && (isnumeric(line[j]) || isletter(line[j]))
                    j += 1
                end
                lexeme = line[i:j - 1]

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
                i = j
            end
        i += 1
        end
        line_nb += 1
    end

    tokens
end
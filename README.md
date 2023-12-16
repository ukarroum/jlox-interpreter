# Jlox Interpreter

## Overview

_jlox_ is a _julia_ based tree walk interpreter implementation for the [Lox](https://craftinginterpreters.com/the-lox-language.html) language.

## Getting Started

Using jlox is as simple as:

```
julia jlox.jl <filepath>
```

## Syntax and Features

Jlox supports all the lox language, in that sense it provides:
- Variables
- Conditions
- Loops
- Functions
- Object oriented programming

## Known Issues and Limitations

There are a lot of areas that are missing:
- Testing: Not a lot of tests
- Error handling is kinda weak.
- No standard library (yet)
- No repl

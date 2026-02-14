#!/usr/bin/env python3

import asyncio
import sys

from src.interpreter import Environment, Null, evaluate
from src.lexer import Lexer
from src.parser import Parser

def main():
    if len(sys.argv) < 2:
        print("Usage: nyx <file.ny>")
        return 1

    filepath = sys.argv[1]
    try:
        with open(filepath, "r") as f:
            source = f.read()
    except FileNotFoundError:
        print(f"Error: File not found at {filepath}")
        return 1

    lexer = Lexer(source)
    parser = Parser(lexer)
    program = parser.parse_program()
    env = Environment()
    
    if parser.errors:
        for error in parser.errors:
            print(f"Parser error: {error}")
        return 1

    result = asyncio.run(evaluate(program, env))
    if result is not None and hasattr(result, 'inspect'):
        if not isinstance(result, Null):
            print(result.inspect())
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

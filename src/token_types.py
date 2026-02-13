from enum import Enum, auto
from dataclasses import dataclass

class TokenType(Enum):
    ILLEGAL = auto()
    EOF = auto()

    # Identifiers + literals
    IDENT = auto()
    INT = auto()
    FLOAT = auto()
    STRING = auto()
    BINARY = auto()
    OCTAL = auto()
    HEX = auto()

    # Operators
    ASSIGN = auto()
    PLUS = auto()
    MINUS = auto()
    BANG = auto()
    ASTERISK = auto()
    SLASH = auto()
    POWER = auto()
    MODULO = auto()
    FLOOR_DIVIDE = auto()
    BITWISE_AND = auto()
    BITWISE_OR = auto()
    BITWISE_XOR = auto()
    BITWISE_NOT = auto()
    LEFT_SHIFT = auto()
    RIGHT_SHIFT = auto()

    PLUS_ASSIGN = auto()
    MINUS_ASSIGN = auto()
    ASTERISK_ASSIGN = auto()
    SLASH_ASSIGN = auto()
    MODULO_ASSIGN = auto()
    FLOOR_DIVIDE_ASSIGN = auto()


    LT = auto()
    GT = auto()
    LE = auto()
    GE = auto()
    EQ = auto()
    NOT_EQ = auto()

    # Delimiters
    COMMA = auto()
    SEMICOLON = auto()
    COLON = auto()
    DOT = auto()
    AT = auto()

    LPAREN = auto()
    RPAREN = auto()
    LBRACE = auto()
    RBRACE = auto()
    LBRACKET = auto()
    RBRACKET = auto()

    # Keywords
    FUNCTION = auto()
    LET = auto()
    TRUE = auto()
    FALSE = auto()
    IF = auto()
    ELSE = auto()
    RETURN = auto()
    WHILE = auto()
    FOR = auto()
    IN = auto()
    BREAK = auto()
    CONTINUE = auto()
    CLASS = auto()
    SUPER = auto()
    SELF = auto()
    NEW = auto()
    IMPORT = auto()
    FROM = auto()
    AS = auto()
    TRY = auto()
    EXCEPT = auto()
    FINALLY = auto()
    RAISE = auto()
    ASSERT = auto()
    WITH = auto()
    YIELD = auto()
    ASYNC = auto()
    AWAIT = auto()
    PASS = auto()
    NULL = auto()


@dataclass
class Token:
    type: TokenType
    literal: str
    line: int
    column: int

keywords = {
    "fn": TokenType.FUNCTION,
    "let": TokenType.LET,
    "true": TokenType.TRUE,
    "false": TokenType.FALSE,
    "if": TokenType.IF,
    "else": TokenType.ELSE,
    "return": TokenType.RETURN,
    "while": TokenType.WHILE,
    "for": TokenType.FOR,
    "in": TokenType.IN,
    "break": TokenType.BREAK,
    "continue": TokenType.CONTINUE,
    "class": TokenType.CLASS,
    "super": TokenType.SUPER,
    "self": TokenType.SELF,
    "new": TokenType.NEW,
    "import": TokenType.IMPORT,
    "from": TokenType.FROM,
    "as": TokenType.AS,
    "try": TokenType.TRY,
    "except": TokenType.EXCEPT,
    "finally": TokenType.FINALLY,
    "raise": TokenType.RAISE,
    "assert": TokenType.ASSERT,
    "with": TokenType.WITH,
    "yield": TokenType.YIELD,
    "async": TokenType.ASYNC,
    "await": TokenType.AWAIT,
    "pass": TokenType.PASS,
    "null": TokenType.NULL,
}

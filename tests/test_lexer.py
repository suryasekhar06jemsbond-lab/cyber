import unittest
from src.lexer import Lexer
from src.token_types import TokenType

class TestLexer(unittest.TestCase):
    def test_all_tokens(self):
        source = """
            let five = 5;
            let ten = 10.5;
            let add = fn(x, y) {
                x + y;
            };
            let result = add(five, ten);

            # Operators
            = + - * / % ** //
            < > <= >= == !=
            & | ^ ~ << >>
            += -= *= /= %= //=

            # Delimiters
            , ; : . @ ( ) { } [ ]

            # Keywords
            fn let true false if else return while for in
            break continue class super self new import from as
            try except finally raise assert with yield async await pass null

            # Numbers
            0b1010 0o777 0xFF

            "hello world"
            'hello world'
        """
        lexer = Lexer(source)
        
        expected_tokens = [
            (TokenType.LET, "let"), (TokenType.IDENT, "five"), (TokenType.ASSIGN, "="), (TokenType.INT, "5"), (TokenType.SEMICOLON, ";"),
            (TokenType.LET, "let"), (TokenType.IDENT, "ten"), (TokenType.ASSIGN, "="), (TokenType.FLOAT, "10.5"), (TokenType.SEMICOLON, ";"),
            (TokenType.LET, "let"), (TokenType.IDENT, "add"), (TokenType.ASSIGN, "="), (TokenType.FUNCTION, "fn"),
            (TokenType.LPAREN, "("), (TokenType.IDENT, "x"), (TokenType.COMMA, ","), (TokenType.IDENT, "y"), (TokenType.RPAREN, ")"),
            (TokenType.LBRACE, "{"), (TokenType.IDENT, "x"), (TokenType.PLUS, "+"), (TokenType.IDENT, "y"), (TokenType.SEMICOLON, ";"), (TokenType.RBRACE, "}"),
            (TokenType.SEMICOLON, ";"),
            (TokenType.LET, "let"), (TokenType.IDENT, "result"), (TokenType.ASSIGN, "="), (TokenType.IDENT, "add"),
            (TokenType.LPAREN, "("), (TokenType.IDENT, "five"), (TokenType.COMMA, ","), (TokenType.IDENT, "ten"), (TokenType.RPAREN, ")"),
            (TokenType.SEMICOLON, ";"),

            # Operators
            (TokenType.ASSIGN, "="), (TokenType.PLUS, "+"), (TokenType.MINUS, "-"), (TokenType.ASTERISK, "*"),
            (TokenType.SLASH, "/"), (TokenType.MODULO, "%"), (TokenType.POWER, "**"), (TokenType.FLOOR_DIVIDE, "//"),
            (TokenType.LT, "<"), (TokenType.GT, ">"), (TokenType.LE, "<="), (TokenType.GE, ">="),
            (TokenType.EQ, "=="), (TokenType.NOT_EQ, "!="),
            (TokenType.BITWISE_AND, "&"), (TokenType.BITWISE_OR, "|"), (TokenType.BITWISE_XOR, "^"),
            (TokenType.BITWISE_NOT, "~"), (TokenType.LEFT_SHIFT, "<<"), (TokenType.RIGHT_SHIFT, ">>"),
            (TokenType.PLUS_ASSIGN, "+="), (TokenType.MINUS_ASSIGN, "-="), (TokenType.ASTERISK_ASSIGN, "*="),
            (TokenType.SLASH_ASSIGN, "/="), (TokenType.MODULO_ASSIGN, "%="), (TokenType.FLOOR_DIVIDE_ASSIGN, "//="),

            # Delimiters
            (TokenType.COMMA, ","), (TokenType.SEMICOLON, ";"), (TokenType.COLON, ":"), (TokenType.DOT, "."),
            (TokenType.AT, "@"), (TokenType.LPAREN, "("), (TokenType.RPAREN, ")"), (TokenType.LBRACE, "{"),
            (TokenType.RBRACE, "}"), (TokenType.LBRACKET, "["), (TokenType.RBRACKET, "]"),

            # Keywords
            (TokenType.FUNCTION, "fn"), (TokenType.LET, "let"), (TokenType.TRUE, "true"), (TokenType.FALSE, "false"),
            (TokenType.IF, "if"), (TokenType.ELSE, "else"), (TokenType.RETURN, "return"), (TokenType.WHILE, "while"),
            (TokenType.FOR, "for"), (TokenType.IN, "in"), (TokenType.BREAK, "break"), (TokenType.CONTINUE, "continue"),
            (TokenType.CLASS, "class"), (TokenType.SUPER, "super"), (TokenType.SELF, "self"), (TokenType.NEW, "new"),
            (TokenType.IMPORT, "import"), (TokenType.FROM, "from"), (TokenType.AS, "as"), (TokenType.TRY, "try"),
            (TokenType.EXCEPT, "except"), (TokenType.FINALLY, "finally"), (TokenType.RAISE, "raise"),
            (TokenType.ASSERT, "assert"), (TokenType.WITH, "with"), (TokenType.YIELD, "yield"), (TokenType.ASYNC, "async"),
            (TokenType.AWAIT, "await"), (TokenType.PASS, "pass"), (TokenType.NULL, "null"),

            # Numbers
            (TokenType.BINARY, "1010"), (TokenType.OCTAL, "777"), (TokenType.HEX, "FF"),

            (TokenType.STRING, "hello world"),
            (TokenType.STRING, "hello world"),
            
            (TokenType.EOF, ""),
        ]

        tokens = []
        while True:
            tok = lexer.next_token()
            tokens.append(tok)
            if tok.type == TokenType.EOF:
                break
        
        self.assertEqual(len(tokens), len(expected_tokens), "Wrong number of tokens")

        for i, (tok_type, literal) in enumerate(expected_tokens):
            self.assertEqual(tokens[i].type, tok_type)
            self.assertEqual(tokens[i].literal, literal)

if __name__ == '__main__':
    unittest.main()
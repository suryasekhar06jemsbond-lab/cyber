from src.token_types import Token, TokenType, keywords

class Lexer:
    def __init__(self, source: str):
        self.source = source
        self.position = 0
        self.read_position = 0
        self.ch = ''
        self.line = 1
        self.column = 0
        self._read_char()

    def _read_char(self):
        if self.read_position >= len(self.source):
            self.ch = ''  # EOF
        else:
            self.ch = self.source[self.read_position]
        self.position = self.read_position
        self.read_position += 1
        self.column += 1

    def _peek_char(self):
        if self.read_position >= len(self.source):
            return ''
        return self.source[self.read_position]

    def _skip_whitespace(self):
        while self.ch.isspace():
            if self.ch == '\n':
                self.line += 1
                self.column = 0
            self._read_char()

    def _skip_comment(self):
        if self.ch == '#':
            while self.ch != '\n' and self.ch != '':
                self._read_char()

    def _read_identifier(self):
        start_pos = self.position
        while self.ch.isalnum() or self.ch == '_':
            self._read_char()
        return self.source[start_pos:self.position]

    def _read_number(self):
        start_pos = self.position
        if self.ch == '0':
            peek = self._peek_char().lower()
            if peek == 'b':
                self._read_char()
                self._read_char()
                start_pos = self.position
                while self.ch in '01':
                    self._read_char()
                return self.source[start_pos:self.position], TokenType.BINARY
            elif peek == 'o':
                self._read_char()
                self._read_char()
                start_pos = self.position
                while self.ch in '01234567':
                    self._read_char()
                return self.source[start_pos:self.position], TokenType.OCTAL
            elif peek == 'x':
                self._read_char()
                self._read_char()
                start_pos = self.position
                while self.ch in '0123456789abcdefABCDEF':
                    self._read_char()
                return self.source[start_pos:self.position], TokenType.HEX
        
        is_float = False
        while self.ch.isdigit():
            self._read_char()
        if self.ch == '.':
            is_float = True
            self._read_char()
            while self.ch.isdigit():
                self._read_char()
        
        token_type = TokenType.FLOAT if is_float else TokenType.INT
        return self.source[start_pos:self.position], token_type

    def _read_string(self, quote_char):
        start_pos = self.position + 1
        while True:
            self._read_char()
            if self.ch == quote_char or self.ch == '':
                break
        return self.source[start_pos:self.position]

    def next_token(self) -> Token:
        self._skip_whitespace()
        self._skip_comment()
        self._skip_whitespace()


        tok = Token(TokenType.ILLEGAL, self.ch, self.line, self.column)
        start_col = self.column

        if self.ch == '/':
            if self._peek_char() == '/': # // or //=
                self._read_char() # consume first /
                if self._peek_char() == '=': # //=
                    self._read_char() # consume second /
                    self._read_char() # consume =
                    return Token(TokenType.FLOOR_DIVIDE_ASSIGN, '//=', self.line, start_col)
                else: # it was just //
                    self._read_char() # consume second /
                    return Token(TokenType.FLOOR_DIVIDE, '//', self.line, start_col)
            elif self._peek_char() == '=': # /=
                self._read_char()
                self._read_char()
                return Token(TokenType.SLASH_ASSIGN, '/=', self.line, start_col)
            else: # /
                self._read_char()
                return Token(TokenType.SLASH, '/', self.line, start_col)

        if self.ch.isalpha() or self.ch == '_':
            literal = self._read_identifier()
            token_type = keywords.get(literal, TokenType.IDENT)
            return Token(token_type, literal, self.line, self.column - len(literal))

        if self.ch.isdigit():
            literal, token_type = self._read_number()
            return Token(token_type, literal, self.line, self.column - len(literal))

        if self.ch == '"' or self.ch == "'":
            start_col = self.column
            literal = self._read_string(self.ch)
            self._read_char() # consume closing quote
            return Token(TokenType.STRING, literal, self.line, start_col)

        char_map = {
            '=': (TokenType.EQ, '==') if self._peek_char() == '=' else (TokenType.ASSIGN, '='),
            '+': (TokenType.PLUS_ASSIGN, '+=') if self._peek_char() == '=' else (TokenType.PLUS, '+'),
            '-': (TokenType.MINUS_ASSIGN, '-=') if self._peek_char() == '=' else (TokenType.MINUS, '-'),
            '*': (TokenType.ASTERISK_ASSIGN, '*=') if self._peek_char() == '=' else (TokenType.POWER, '**') if self._peek_char() == '*' else (TokenType.ASTERISK, '*'),
            '%': (TokenType.MODULO_ASSIGN, '%=') if self._peek_char() == '=' else (TokenType.MODULO, '%'),
            '<': (TokenType.LE, '<=') if self._peek_char() == '=' else (TokenType.LEFT_SHIFT, '<<') if self._peek_char() == '<' else (TokenType.LT, '<'),
            '>': (TokenType.GE, '>=') if self._peek_char() == '=' else (TokenType.RIGHT_SHIFT, '>>') if self._peek_char() == '>' else (TokenType.GT, '>'),
            '!': (TokenType.NOT_EQ, '!=') if self._peek_char() == '=' else (TokenType.BANG, '!'),
            '&': (TokenType.BITWISE_AND, '&'),
            '|': (TokenType.BITWISE_OR, '|'),
            '^': (TokenType.BITWISE_XOR, '^'),
            '~': (TokenType.BITWISE_NOT, '~'),
            '(': (TokenType.LPAREN, '('),
            ')': (TokenType.RPAREN, ')'),
            '{': (TokenType.LBRACE, '{'),
            '}': (TokenType.RBRACE, '}'),
            '[': (TokenType.LBRACKET, '['),
            ']': (TokenType.RBRACKET, ']'),
            ',': (TokenType.COMMA, ','),
            ';': (TokenType.SEMICOLON, ';'),
            ':': (TokenType.COLON, ':'),
            '.': (TokenType.DOT, '.'),
            '@': (TokenType.AT, '@'),
        }

        if self.ch in char_map:
            token_type, literal = char_map[self.ch]
            if len(literal) > 1:
                self._read_char()
            self._read_char()
            return Token(token_type, literal, self.line, self.column - len(literal))

        if self.ch == '':
            return Token(TokenType.EOF, '', self.line, self.column)

        self._read_char()
        return tok
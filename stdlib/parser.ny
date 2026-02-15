# ============================================================
# Nyx Standard Library - Parser Module
# ============================================================
# Comprehensive parser combinator framework providing tools
# for building recursive descent parsers, lexer generators,
# and language parsers.

# ============================================================
# Constants
# ============================================================

let VERSION = "1.0.0";

# Parser result types
let PARSE_SUCCESS = "success";
let PARSE_FAILURE = "failure";
let PARSE_EMPTY = "empty";

# Parser error types
let ERR_UNEXPECTED_TOKEN = "unexpected_token";
let ERR_UNEXPECTED_END = "unexpected_end";
let ERR_EXPECTED_TOKEN = "expected_token";
let ERR_CUSTOM = "custom";

# ============================================================
# Position and Location
# ============================================================

class Position {
    init(line, column, index) {
        self.line = line;
        self.column = column;
        self.index = index;
    }

    advance(columnDelta, indexDelta) {
        return Position(self.line + columnDelta, self.column + indexDelta, self.index + indexDelta);
    }

    toString() {
        return str(self.line) + ":" + str(self.column);
    }
}

class Location {
    init(start, end) {
        self.start = start;
        self.end = end;
    }

    toString() {
        return self.start.toString() + " - " + self.end.toString();
    }
}

# ============================================================
# Parse Result
# ============================================================

class ParseResult {
    init(success, value, error, position, expected) {
        self.success = success;
        self.value = value;
        self.error = error;
        self.position = position;
        self.expected = expected ?? [];
    }

    isSuccess() {
        return self.success;
    }

    isFailure() {
        return not self.success;
    }

    getValue() {
        return self.value;
    }

    getError() {
        return self.error;
    }

    getPosition() {
        return self.position;
    }

    map(fn) {
        if self.success {
            return ParseResult(true, fn(self.value), null, self.position, self.expected);
        }
        return self;
    }

    flatMap(fn) {
        if self.success {
            return fn(self.value);
        }
        return self;
    }

    orElse(defaultValue) {
        if self.success {
            return self.value;
        }
        return defaultValue;
    }

    toString() {
        if self.success {
            return "ParseSuccess(" + str(self.value) + ")";
        }
        return "ParseFailure(" + str(self.error) + " at " + str(self.position) + ")";
    }
}

# ============================================================
# Parse Error
# ============================================================

class ParseError {
    init(message, position, expected, got) {
        self.message = message;
        self.position = position;
        self.expected = expected ?? [];
        self.got = got;
    }

    toString() {
        let msg = "Parse error at " + str(self.position) + ": " + self.message;
        if self.got != null {
            msg = msg + ", got: " + str(self.got);
        }
        if len(self.expected) > 0 {
            msg = msg + ", expected one of: " + json.stringify(self.expected);
        }
        return msg;
    }
}

# ============================================================
# Input Stream
# ============================================================

class InputStream {
    init(input) {
        self.input = input;
        self.position = 0;
        self.line = 1;
        self.column = 1;
    }

    peek(offset) {
        let pos = self.position + offset;
        if pos >= len(self.input) {
            return null;
        }
        return self.input[pos];
    }

    peekChar() {
        return self.peek(0);
    }

    next() {
        if self.position >= len(self.input) {
            return null;
        }
        let char = self.input[self.position];
        self.position = self.position + 1;
        
        if char == "\n" {
            self.line = self.line + 1;
            self.column = 1;
        } else {
            self.column = self.column + 1;
        }
        
        return char;
    }

    read(count) {
        let result = "";
        for i in range(count) {
            let char = self.next();
            if char == null {
                break;
            }
            result = result + char;
        }
        return result;
    }

    readWhile(predicate) {
        let result = "";
        while true {
            let char = self.peekChar();
            if char == null or not predicate(char) {
                break;
            }
            result = result + self.next();
        }
        return result;
    }

    readUntil(predicate) {
        let result = "";
        while true {
            let char = self.peekChar();
            if char == null or predicate(char) {
                break;
            }
            result = result + self.next();
        }
        return result;
    }

    isEnd() {
        return self.position >= len(self.input);
    }

    getPosition() {
        return Position(self.line, self.column, self.position);
    }

    getLocation() {
        return Location(self.getPosition(), self.getPosition());
    }

    mark() {
        return {
            "position": self.position,
            "line": self.line,
            "column": self.column
        };
    }

    reset(marker) {
        self.position = marker["position"];
        self.line = marker["line"];
        self.column = marker["column"];
    }

    substring(start, end) {
        return self.input[start:end];
    }

    length() {
        return len(self.input);
    }
}

# ============================================================
# Parser Base Class
# ============================================================

class Parser {
    init(name) {
        self.name = name ?? "anonymous";
    }

    parse(input) {
        if type(input) == "string" {
            input = InputStream(input);
        }
        return self._parse(input);
    }

    _parse(input) {
        return ParseResult(false, null, "Not implemented", input.getPosition(), []);
    }

    parseValue(value) {
        return self.parse(value);
    }

    tryParse(input) {
        if type(input) == "string" {
            input = InputStream(input);
        }
        
        let marker = input.mark();
        let result = self._parse(input);
        
        if result.isFailure() {
            input.reset(marker);
        }
        
        return result;
    }

    map(fn) {
        let parser = self;
        let mapped = Parser(self.name + "_mapped");
        
        mapped._parse = fn(input) {
            let result = parser._parse(input);
            if result.isSuccess() {
                return ParseResult(true, fn(result.value), null, result.position, result.expected);
            }
            return result;
        };
        
        return mapped;
    }

    flatMap(fn) {
        let parser = self;
        let mapped = Parser(self.name + "_flatmapped");
        
        mapped._parse = fn(input) {
            let result = parser._parse(input);
            if result.isSuccess() {
                let nextParser = fn(result.value);
                return nextParser._parse(input);
            }
            return result;
        };
        
        return mapped;
    }

    then(parser) {
        return SequenceParser([self, parser]);
    }

    or(parser) {
        return ChoiceParser([self, parser]);
    }

    optional() {
        return OptionalParser(self);
    }

    many() {
        return ManyParser(self);
    }

    many1() {
        return Many1Parser(self);
    }

    between(left, right) {
        return BetweenParser(left, self, right);
    }

    sepBy(separator) {
        return SepByParser(self, separator);
    }

    sepBy1(separator) {
        return SepBy1Parser(self, separator);
    }

    skipMany() {
        return SkipManyParser(self);
    }

    skipMany1() {
        return SkipMany1Parser(self);
    }

    label(label) {
        return LabeledParser(self, label);
    }

    trace(label) {
        return TracedParser(self, label);
    }

    not() {
        return NotParser(self);
    }

    lookahead() {
        return LookaheadParser(self);
    }

    desc(description) {
        return self.label(description);
    }
}

# ============================================================
# Primitive Parsers
# ============================================================

class PureParser < Parser {
    init(value) {
        super("pure");
        self.value = value;
    }

    _parse(input) {
        return ParseResult(true, self.value, null, input.getPosition(), []);
    }
}

class FailParser < Parser {
    init(message) {
        super("fail");
        self.message = message;
    }

    _parse(input) {
        return ParseResult(false, null, ParseError(self.message, input.getPosition(), [], null), input.getPosition(), []);
    }
}

class EmptyParser < Parser {
    init() {
        super("empty");
    }

    _parse(input) {
        return ParseResult(true, null, null, input.getPosition(), []);
    }
}

class AnyCharParser < Parser {
    init() {
        super("anyChar");
    }

    _parse(input) {
        let char = input.next();
        if char == null {
            return ParseResult(false, null, 
                ParseError("Unexpected end of input", input.getPosition(), ["any character"], null),
                input.getPosition(), ["any character"]);
        }
        return ParseResult(true, char, null, input.getPosition(), []);
    }
}

class CharParser < Parser {
    init(expected) {
        super("char");
        self.expected = expected;
    }

    _parse(input) {
        let char = input.peekChar();
        if char == null {
            return ParseResult(false, null,
                ParseError("Unexpected end of input", input.getPosition(), [self.expected], null),
                input.getPosition(), [self.expected]);
        }
        
        if char == self.expected {
            input.next();
            return ParseResult(true, char, null, input.getPosition(), []);
        }
        
        return ParseResult(false, null,
            ParseError("Expected '" + self.expected + "'", input.getPosition(), [self.expected], char),
            input.getPosition(), [self.expected]);
    }
}

class CharNotParser < Parser {
    init(notExpected) {
        super("charNot");
        self.notExpected = notExpected;
    }

    _parse(input) {
        let char = input.peekChar();
        if char == null {
            return ParseResult(false, null,
                ParseError("Unexpected end of input", input.getPosition(), ["any character except '" + self.notExpected + "'"], null),
                input.getPosition(), ["any character except '" + self.notExpected + "'"]);
        }
        
        if char != self.notExpected {
            input.next();
            return ParseResult(true, char, null, input.getPosition(), []);
        }
        
        return ParseResult(false, null,
            ParseError("Unexpected '" + self.notExpected + "'", input.getPosition(), ["any character except '" + self.notExpected + "'"], char),
            input.getPosition(), ["any character except '" + self.notExpected + "'"]);
    }
}

class OneOfParser < Parser {
    init(chars) {
        super("oneOf");
        self.chars = chars;
    }

    _parse(input) {
        let char = input.peekChar();
        if char == null {
            return ParseResult(false, null,
                ParseError("Unexpected end of input", input.getPosition(), self.chars, null),
                input.getPosition(), self.chars);
        }
        
        if char in self.chars {
            input.next();
            return ParseResult(true, char, null, input.getPosition(), []);
        }
        
        return ParseResult(false, null,
            ParseError("Expected one of: " + json.stringify(self.chars), input.getPosition(), self.chars, char),
            input.getPosition(), self.chars);
    }
}

class NoneOfParser < Parser {
    init(chars) {
        super("noneOf");
        self.chars = chars;
    }

    _parse(input) {
        let char = input.peekChar();
        if char == null {
            return ParseResult(false, null,
                ParseError("Unexpected end of input", input.getPosition(), ["any character not in: " + json.stringify(self.chars)], null),
                input.getPosition(), ["any character not in: " + json.stringify(self.chars)]);
        }
        
        if char not in self.chars {
            input.next();
            return ParseResult(true, char, null, input.getPosition(), []);
        }
        
        return ParseResult(false, null,
            ParseError("Unexpected '" + char + "'", input.getPosition(), ["any character not in: " + json.stringify(self.chars)], char),
            input.getPosition(), ["any character not in: " + json.stringify(self.chars)]);
    }
}

class StringParser < Parser {
    init(expected) {
        super("string");
        self.expected = expected;
    }

    _parse(input) {
        let startPos = input.getPosition();
        
        for i in range(len(self.expected)) {
            let char = input.peekChar();
            if char == null or char != self.expected[i] {
                return ParseResult(false, null,
                    ParseError("Expected string '" + self.expected + "'", startPos, [self.expected], 
                        char != null ? char : "end of input"),
                    startPos, [self.expected]);
            }
            input.next();
        }
        
        return ParseResult(true, self.expected, null, input.getPosition(), []);
    }
}

class StringNotParser < Parser {
    init(notExpected) {
        super("stringNot");
        self.notExpected = notExpected;
    }

    _parse(input) {
        let startPos = input.getPosition();
        
        for i in range(len(self.notExpected)) {
            let char = input.peekChar();
            if char == null or char != self.notExpected[i] {
                return ParseResult(true, null, null, input.getPosition(), []);
            }
            input.next();
        }
        
        return ParseResult(false, null,
            ParseError("Unexpected string '" + self.notExpected + "'", startPos, 
                ["any string except '" + self.notExpected + "'"], self.notExpected),
            startPos, ["any string except '" + self.notExpected + "'"]);
    }
}

class RegexParser < Parser {
    init(pattern) {
        super("regex");
        self.pattern = pattern;
        self.regex = regex.create("^" + pattern);
    }

    _parse(input) {
        let str = input.readWhile(fn(c) {
            return self.regex.test(c);
        });
        
        if len(str) > 0 {
            return ParseResult(true, str, null, input.getPosition(), []);
        }
        
        return ParseResult(false, null,
            ParseError("Expected pattern: " + self.pattern, input.getPosition(), [self.pattern], null),
            input.getPosition(), [self.pattern]);
    }
}

class SatisfyParser < Parser {
    init(predicate, description) {
        super("satisfy");
        self.predicate = predicate;
        self.description = description ?? "satisfying predicate";
    }

    _parse(input) {
        let char = input.peekChar();
        if char == null {
            return ParseResult(false, null,
                ParseError("Unexpected end of input", input.getPosition(), [self.description], null),
                input.getPosition(), [self.description]);
        }
        
        if self.predicate(char) {
            input.next();
            return ParseResult(true, char, null, input.getPosition(), []);
        }
        
        return ParseResult(false, null,
            ParseError("Expected " + self.description, input.getPosition(), [self.description], char),
            input.getPosition(), [self.description]);
    }
}

# ============================================================
# Combinator Parsers
# ============================================================

class SequenceParser < Parser {
    init(parsers) {
        super("sequence");
        self.parsers = parsers;
    }

    _parse(input) {
        let results = [];
        let position = input.getPosition();
        
        for parser in self.parsers {
            let result = parser._parse(input);
            if result.isFailure() {
                return ParseResult(false, null, result.error, position, result.expected);
            }
            results = results + [result.value];
        }
        
        return ParseResult(true, results, null, input.getPosition(), []);
    }
}

class ChoiceParser < Parser {
    init(parsers) {
        super("choice");
        self.parsers = parsers;
    }

    _parse(input) {
        let errors = [];
        let lastPosition = input.getPosition();
        
        for parser in self.parsers {
            let marker = input.mark();
            let result = parser._parse(input);
            
            if result.isSuccess() {
                return result;
            }
            
            input.reset(marker);
            errors = errors + [result.error];
            
            if result.position.index > lastPosition.index {
                lastPosition = result.position;
            }
        }
        
        let expected = [];
        for err in errors {
            expected = expected + err.expected;
        }
        
        return ParseResult(false, null,
            ParseError("All alternatives failed", lastPosition, expected, null),
            lastPosition, expected);
    }
}

class OptionalParser < Parser {
    init(parser) {
        super("optional");
        self.parser = parser;
    }

    _parse(input) {
        let marker = input.mark();
        let result = self.parser._parse(input);
        
        if result.isSuccess() {
            return ParseResult(true, result.value, null, result.position, []);
        }
        
        input.reset(marker);
        return ParseResult(true, null, null, input.getPosition(), []);
    }
}

class ManyParser < Parser {
    init(parser) {
        super("many");
        self.parser = parser;
    }

    _parse(input) {
        let results = [];
        
        while true {
            let marker = input.mark();
            let result = self.parser._parse(input);
            
            if result.isFailure() {
                input.reset(marker);
                break;
            }
            
            results = results + [result.value];
        }
        
        return ParseResult(true, results, null, input.getPosition(), []);
    }
}

class Many1Parser < Parser {
    init(parser) {
        super("many1");
        self.parser = parser;
    }

    _parse(input) {
        let results = [];
        
        let firstResult = self.parser._parse(input);
        if firstResult.isFailure() {
            return firstResult;
        }
        
        results = results + [firstResult.value];
        
        while true {
            let marker = input.mark();
            let result = self.parser._parse(input);
            
            if result.isFailure() {
                input.reset(marker);
                break;
            }
            
            results = results + [result.value];
        }
        
        return ParseResult(true, results, null, input.getPosition(), []);
    }
}

class SkipManyParser < Parser {
    init(parser) {
        super("skipMany");
        self.parser = parser;
    }

    _parse(input) {
        while true {
            let marker = input.mark();
            let result = self.parser._parse(input);
            
            if result.isFailure() {
                input.reset(marker);
                break;
            }
        }
        
        return ParseResult(true, null, null, input.getPosition(), []);
    }
}

class SkipMany1Parser < Parser {
    init(parser) {
        super("skipMany1");
        self.parser = parser;
    }

    _parse(input) {
        let firstResult = self.parser._parse(input);
        if firstResult.isFailure() {
            return firstResult;
        }
        
        while true {
            let marker = input.mark();
            let result = self.parser._parse(input);
            
            if result.isFailure() {
                input.reset(marker);
                break;
            }
        }
        
        return ParseResult(true, null, null, input.getPosition(), []);
    }
}

class BetweenParser < Parser {
    init(left, parser, right) {
        super("between");
        self.left = left;
        self.parser = parser;
        self.right = right;
    }

    _parse(input) {
        let leftResult = self.left._parse(input);
        if leftResult.isFailure() {
            return leftResult;
        }
        
        let centerResult = self.parser._parse(input);
        if centerResult.isFailure() {
            return centerResult;
        }
        
        let rightResult = self.right._parse(input);
        if rightResult.isFailure() {
            return rightResult;
        }
        
        return ParseResult(true, centerResult.value, null, input.getPosition(), []);
    }
}

class SepByParser < Parser {
    init(parser, separator) {
        super("sepBy");
        self.parser = parser;
        self.separator = separator;
    }

    _parse(input) {
        let results = [];
        
        let marker = input.mark();
        let firstResult = self.parser._parse(input);
        
        if firstResult.isFailure() {
            input.reset(marker);
            return ParseResult(true, results, null, input.getPosition(), []);
        }
        
        results = results + [firstResult.value];
        
        while true {
            let sepMarker = input.mark();
            let sepResult = self.separator._parse(input);
            
            if sepResult.isFailure() {
                input.reset(sepMarker);
                break;
            }
            
            let itemMarker = input.mark();
            let itemResult = self.parser._parse(input);
            
            if itemResult.isFailure() {
                input.reset(itemMarker);
                break;
            }
            
            results = results + [itemResult.value];
        }
        
        return ParseResult(true, results, null, input.getPosition(), []);
    }
}

class SepBy1Parser < Parser {
    init(parser, separator) {
        super("sepBy1");
        self.parser = parser;
        self.separator = separator;
    }

    _parse(input) {
        let results = [];
        
        let firstResult = self.parser._parse(input);
        if firstResult.isFailure() {
            return firstResult;
        }
        
        results = results + [firstResult.value];
        
        while true {
            let sepMarker = input.mark();
            let sepResult = self.separator._parse(input);
            
            if sepResult.isFailure() {
                input.reset(sepMarker);
                break;
            }
            
            let itemMarker = input.mark();
            let itemResult = self.parser._parse(input);
            
            if itemResult.isFailure() {
                input.reset(itemMarker);
                break;
            }
            
            results = results + [itemResult.value];
        }
        
        return ParseResult(true, results, null, input.getPosition(), []);
    }
}

class LabeledParser < Parser {
    init(parser, label) {
        super("label");
        self.parser = parser;
        self.label = label;
    }

    _parse(input) {
        let result = self.parser._parse(input);
        
        if result.isFailure() and len(result.expected) == 0 {
            return ParseResult(false, null, result.error, result.position, [self.label]);
        }
        
        return result;
    }
}

class TracedParser < Parser {
    init(parser, label) {
        super("trace");
        self.parser = parser;
        self.label = label;
    }

    _parse(input) {
        print("[" + self.label + "] Starting at " + str(input.getPosition()));
        
        let result = self.parser._parse(input);
        
        if result.isSuccess() {
            print("[" + self.label + "] Success: " + str(result.value));
        } else {
            print("[" + self.label + "] Failed: " + str(result.error));
        }
        
        return result;
    }
}

class NotParser < Parser {
    init(parser) {
        super("not");
        self.parser = parser;
    }

    _parse(input) {
        let marker = input.mark();
        let result = self.parser._parse(input);
        
        input.reset(marker);
        
        if result.isSuccess() {
            return ParseResult(false, null,
                ParseError("Unexpected success", input.getPosition(), [], result.value),
                input.getPosition(), []);
        }
        
        return ParseResult(true, null, null, input.getPosition(), []);
    }
}

class LookaheadParser < Parser {
    init(parser) {
        super("lookahead");
        self.parser = parser;
    }

    _parse(input) {
        let marker = input.mark();
        let result = self.parser._parse(input);
        input.reset(marker);
        
        if result.isSuccess() {
            return ParseResult(true, null, null, input.getPosition(), []);
        }
        
        return ParseResult(false, null, result.error, input.getPosition(), result.expected);
    }
}

class EndParser < Parser {
    init() {
        super("end");
    }

    _parse(input) {
        if input.isEnd() {
            return ParseResult(true, null, null, input.getPosition(), []);
        }
        
        let char = input.peekChar();
        return ParseResult(false, null,
            ParseError("Expected end of input", input.getPosition(), ["end of input"], char),
            input.getPosition(), ["end of input"]);
    }
}

# ============================================================
# Transforming Parsers
# ============================================================

class ManyTillParser < Parser {
    init(parser, end) {
        super("manyTill");
        self.parser = parser;
        self.end = end;
    }

    _parse(input) {
        let results = [];
        
        while true {
            let endMarker = input.mark();
            let endResult = self.end._parse(input);
            
            if endResult.isSuccess() {
                input.reset(endMarker);
                break;
            }
            
            let itemMarker = input.mark();
            let itemResult = self.parser._parse(input);
            
            if itemResult.isFailure() {
                input.reset(itemMarker);
                break;
            }
            
            results = results + [itemResult.value];
        }
        
        return ParseResult(true, results, null, input.getPosition(), []);
    }
}

class SomeTillParser < Parser {
    init(parser, end) {
        super("someTill");
        self.parser = parser;
        self.end = end;
    }

    _parse(input) {
        let results = [];
        
        while true {
            let endMarker = input.mark();
            let endResult = self.end._parse(input);
            
            if endResult.isSuccess() {
                input.reset(endMarker);
                if len(results) == 0 {
                    return ParseResult(false, null,
                        ParseError("Expected at least one item before end", input.getPosition(), ["item"], null),
                        input.getPosition(), ["item"]);
                }
                break;
            }
            
            let itemMarker = input.mark();
            let itemResult = self.parser._parse(input);
            
            if itemResult.isFailure() {
                input.reset(itemMarker);
                if len(results) == 0 {
                    return itemResult;
                }
                break;
            }
            
            results = results + [itemResult.value];
        }
        
        return ParseResult(true, results, null, input.getPosition(), []);
    }
}

class ChainLeftParser < Parser {
    init(parser, operator) {
        super("chainLeft");
        self.parser = parser;
        self.operator = operator;
    }

    _parse(input) {
        let result = self.parser._parse(input);
        
        if result.isFailure() {
            return result;
        }
        
        let value = result.value;
        
        while true {
            let opMarker = input.mark();
            let opResult = self.operator._parse(input);
            
            if opResult.isFailure() {
                input.reset(opMarker);
                break;
            }
            
            let rightMarker = input.mark();
            let rightResult = self.parser._parse(input);
            
            if rightResult.isFailure() {
                input.reset(rightMarker);
                break;
            }
            
            value = [opResult.value, value, rightResult.value];
        }
        
        return ParseResult(true, value, null, input.getPosition(), []);
    }
}

class ChainRightParser < Parser {
    init(parser, operator) {
        super("chainRight");
        self.parser = parser;
        self.operator = operator;
    }

    _parse(input) {
        let result = self.parser._parse(input);
        
        if result.isFailure() {
            return result;
        }
        
        let rightMarker = input.mark();
        let opResult = self.operator._parse(input);
        
        if opResult.isFailure() {
            input.reset(rightMarker);
            return result;
        }
        
        let rightResult = self.parser._parse(input);
        
        if rightResult.isFailure() {
            return rightResult;
        }
        
        let value = [opResult.value, result.value, rightResult.value];
        
        return ParseResult(true, value, null, input.getPosition(), []);
    }
}

# ============================================================
# Common Parser Combinators
# ============================================================

fn anyChar() {
    return AnyCharParser();
}

fn char(c) {
    return CharParser(c);
}

fn charNot(c) {
    return CharNotParser(c);
}

fn oneOf(chars) {
    return OneOfParser(chars);
}

fn noneOf(chars) {
    return NoneOfParser(chars);
}

fn string(s) {
    return StringParser(s);
}

fn stringNot(s) {
    return StringNotParser(s);
}

fn regex(pattern) {
    return RegexParser(pattern);
}

fn satisfy(predicate, description) {
    return SatisfyParser(predicate, description);
}

fn digit() {
    return satisfy(fn(c) { return c >= "0" and c <= "9"; }, "digit");
}

fn letter() {
    return satisfy(fn(c) { 
        return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z"); 
    }, "letter");
}

fn alphaNum() {
    return satisfy(fn(c) { 
        return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9"); 
    }, "alphanumeric");
}

fn whitespace() {
    return satisfy(fn(c) { return c == " " or c == "\t" or c == "\n" or c == "\r"; }, "whitespace");
}

fn space() {
    return char(" ");
}

fn spaces() {
    return many(whitespace());
}

fn spaces1() {
    return many1(whitespace());
}

fn newline() {
    return char("\n");
}

fn tab() {
    return char("\t");
}

fn upper() {
    return satisfy(fn(c) { return c >= "A" and c <= "Z"; }, "uppercase letter");
}

fn lower() {
    return satisfy(fn(c) { return c >= "a" and c <= "z"; }, "lowercase letter");
}

fn word() {
    return many1(letter());
}

fn integer() {
    return many1(digit()).map(fn(s) { return parseInt(join(s, "")); });
}

fn signedInteger() {
    return (optional(char("-")).then(integer())).map(fn(parts) {
        let sign = parts[0] ?? "+";
        let num = parts[1];
        if sign == "-" {
            return -num;
        }
        return num;
    });
}

fn decimal() {
    return (integer().then(optional(char(".").then(many1(digit()))))).map(fn(parts) {
        let intPart = parts[0];
        let fracPart = parts[1] ?? [];
        if len(fracPart) > 0 {
            return parseFloat(str(intPart) + "." + join(fracPart[1], ""));
        }
        return intPart;
    });
}

fn float() {
    return signedInteger().or(decimal());
}

fn bool() {
    return (string("true").or(string("false"))).map(fn(s) { return s == "true"; });
}

fn quotedString() {
    return between(char('"'), many(noneOf(['"'])), char('"')).map(fn(parts) { return join(parts, ""); });
}

fn singleQuotedString() {
    return between(char("'"), noneOf(["'"]), char("'")).map(fn(parts) { return join(parts, ""); });
}

fn skipSpaces() {
    return skipMany(whitespace());
}

fn endOfInput() {
    return EndParser();
}

fn pure(value) {
    return PureParser(value);
}

fn fail(message) {
    return FailParser(message);
}

fn empty() {
    return EmptyParser();
}

# ============================================================
# Precedence Climbing
# ============================================================

class PrecedenceParser < Parser {
    init(term, operators) {
        super("precedence");
        self.term = term;
        self.operators = operators;
    }

    _parse(input) {
        return self._parsePrec(input, 0);
    }

    _parsePrec(input, minPrec) {
        let left = self.term._parse(input);
        
        if left.isFailure() {
            return left;
        }
        
        while true {
            let gotPrec = 0;
            let op = null;
            
            for opDef in self.operators {
                let opName = opDef[0];
                let prec = opDef[1];
                let assoc = opDef[2] ?? "left";
                
                let opParser = string(opName);
                let marker = input.mark();
                let opResult = opParser._parse(input);
                
                if opResult.isSuccess() and prec >= minPrec {
                    gotPrec = prec;
                    op = opName;
                    input.reset(marker);
                    break;
                }
                
                input.reset(marker);
            }
            
            if op == null {
                break;
            }
            
            input.next();
            let rightMinPrec = gotPrec + 1;
            
            let right = self._parsePrec(input, rightMinPrec);
            
            if right.isFailure() {
                return right;
            }
            
            left = ParseResult(true, [op, left.value, right.value], null, input.getPosition(), []);
        }
        
        return left;
    }
}

fn precedence(term, operators) {
    return PrecedenceParser(term, operators);
}

# ============================================================
# Building Expressions
# ============================================================

class ExpressionBuilder {
    init() {
        self.term = null;
        self.prefix = [];
        self.infix = [];
        self.postfix = [];
    }

    term(parser) {
        self.term = parser;
        return self;
    }

    prefix(op, precedence, parser) {
        self.prefix = self.prefix + [[op, precedence, parser]];
        return self;
    }

    infix(op, precedence, assoc, parser) {
        self.infix = self.infix + [[op, precedence, assoc, parser]];
        return self;
    }

    postfix(op, precedence, parser) {
        self.postfix = self.postfix + [[op, precedence, parser]];
        return self;
    }

    build() {
        return self.term;
    }
}

# ============================================================
# Token Parser
# ============================================================

class TokenParser < Parser {
    init(parser) {
        super("token");
        self.parser = parser;
    }

    _parse(input) {
        skipSpaces(input);
        return self.parser._parse(input);
    }
}

fn token(parser) {
    return TokenParser(parser);
}

# ============================================================
# Parenthesized Expression
# ============================================================

fn parens(parser) {
    return between(char("("), parser, char(")"));
}

fn brackets(parser) {
    return between(char("["), parser, char("]"));
}

fn braces(parser) {
    return between(char("{"), parser, char("}"));
}

fn angles(parser) {
    return between(char("<"), parser, char(">"));
}

# ============================================================
# Comment Parsers
# ============================================================

fn lineComment(start) {
    return (string(start).then(manyTill(anyChar(), newline().or(endOfInput())))).map(fn(parts) {
        return parts[1];
    });
}

fn blockComment(start, end) {
    return (string(start).then(manyTill(anyChar(), string(end)))).map(fn(parts) {
        return parts[1];
    });
}

# ============================================================
# JSON Parser (using parser combinators)
# ============================================================

let jsonValue = null;
let jsonString = null;
let jsonNumber = null;
let jsonBool = null;
let jsonNull = null;
let jsonArray = null;
let jsonObject = null;
let jsonMember = null;

jsonNull = string("null").map(fn(_) { return null; });

jsonBool = (string("true").or(string("false"))).map(fn(s) { return s == "true"; });

jsonString = quotedString();

jsonNumber = float();

jsonArray = brackets(many(jsonValue.sepBy(",")));

jsonMember = (jsonString.then(char(":")).then(jsonValue)).map(fn(parts) {
    return {"key": parts[0], "value": parts[2]};
});

jsonObject = braces(many(jsonMember.sepBy(",")));

jsonValue = jsonNull.or(jsonBool).or(jsonString).or(jsonNumber).or(jsonArray).or(jsonObject);

# ============================================================
# CSV Parser
# ============================================================

class CSVParser < Parser {
    init(options) {
        super("csv");
        self.delimiter = options["delimiter"] ?? ",";
        self.quote = options["quote"] ?? '"';
        self.hasHeader = options["hasHeader"] ?? false;
    }

    _parse(input) {
        let rows = [];
        let headers = [];
        
        if self.hasHeader {
            let headerResult = self._parseRow(input);
            if headerResult.isSuccess() {
                headers = headerResult.value;
            }
        }
        
        while not input.isEnd() {
            let rowResult = self._parseRow(input);
            
            if rowResult.isFailure() {
                break;
            }
            
            if self.hasHeader and len(headers) > 0 {
                let row = {};
                for i in range(len(headers)) {
                    if i < len(rowResult.value) {
                        row[headers[i]] = rowResult.value[i];
                    }
                }
                rows = rows + [row];
            } else {
                rows = rows + [rowResult.value];
            }
        }
        
        return ParseResult(true, {"headers": headers, "rows": rows}, null, input.getPosition(), []);
    }

    _parseRow(input) {
        skipSpaces(input);
        let values = [];
        
        while not input.isEnd() {
            let valueResult = self._parseValue(input);
            
            if valueResult.isFailure() {
                break;
            }
            
            values = values + [valueResult.value];
            
            let commaResult = char(self.delimiter).tryParse(input);
            if commaResult.isFailure() {
                break;
            }
        }
        
        newline().tryParse(input);
        
        return ParseResult(true, values, null, input.getPosition(), []);
    }

    _parseValue(input) {
        let quote = char(self.quote);
        let quoteResult = quote.tryParse(input);
        
        if quoteResult.isSuccess() {
            return self._parseQuotedValue(input);
        }
        
        return self._parseUnquotedValue(input);
    }

    _parseQuotedValue(input) {
        let value = "";
        
        while not input.isEnd() {
            let escapeQuote = string(self.quote + self.quote);
            let escapeResult = escapeQuote.tryParse(input);
            
            if escapeResult.isSuccess() {
                value = value + self.quote;
                continue;
            }
            
            let endQuote = char(self.quote);
            let endResult = endQuote.tryParse(input);
            
            if endResult.isSuccess() {
                break;
            }
            
            let charResult = anyChar();
            let charParseResult = charResult._parse(input);
            
            if charParseResult.isSuccess() {
                value = value + charParseResult.value;
            }
        }
        
        return ParseResult(true, value, null, input.getPosition(), []);
    }

    _parseUnquotedValue(input) {
        let value = input.readWhile(fn(c) {
            return c != self.delimiter and c != "\n" and c != "\r";
        });
        
        return ParseResult(true, value, null, input.getPosition(), []);
    }
}

fn parseCSV(input, options) {
    let parser = CSVParser(options ?? {});
    return parser.parse(input);
}

# ============================================================
# Export
# ============================================================

{
    "Position": Position,
    "Location": Location,
    "ParseResult": ParseResult,
    "ParseError": ParseError,
    "InputStream": InputStream,
    "Parser": Parser,
    "PureParser": PureParser,
    "FailParser": FailParser,
    "EmptyParser": EmptyParser,
    "AnyCharParser": AnyCharParser,
    "CharParser": CharParser,
    "CharNotParser": CharNotParser,
    "OneOfParser": OneOfParser,
    "NoneOfParser": NoneOfParser,
    "StringParser": "StringNotParser StringParser,
   ": StringNotParser,
    "RegexParser": RegexParser,
    "SatisfyParser": SatisfyParser,
    "SequenceParser": SequenceParser,
    "ChoiceParser": ChoiceParser,
    "OptionalParser": OptionalParser,
    "ManyParser": ManyParser,
    "Many1Parser": Many1Parser,
    "SkipManyParser": SkipManyParser,
    "SkipMany1Parser": SkipMany1Parser,
    "BetweenParser": BetweenParser,
    "SepByParser": SepByParser,
    "SepBy1Parser": SepBy1Parser,
    "LabeledParser": LabeledParser,
    "TracedParser": TracedParser,
    "NotParser": NotParser,
    "LookaheadParser": LookaheadParser,
    "EndParser": EndParser,
    "ManyTillParser": ManyTillParser,
    "SomeTillParser": SomeTillParser,
    "ChainLeftParser": ChainLeftParser,
    "ChainRightParser": ChainRightParser,
    "PrecedenceParser": PrecedenceParser,
    "ExpressionBuilder": ExpressionBuilder,
    "TokenParser": TokenParser,
    "CSVParser": CSVParser,
    "anyChar": anyChar,
    "char": char,
    "charNot": charNot,
    "oneOf": oneOf,
    "noneOf": noneOf,
    "string": string,
    "stringNot": stringNot,
    "regex": regex,
    "satisfy": satisfy,
    "digit": digit,
    "letter": letter,
    "alphaNum": alphaNum,
    "whitespace": whitespace,
    "space": space,
    "spaces": spaces,
    "spaces1": spaces1,
    "newline": newline,
    "tab": tab,
    "upper": upper,
    "lower": lower,
    "word": word,
    "integer": integer,
    "signedInteger": signedInteger,
    "decimal": decimal,
    "float": float,
    "bool": bool,
    "quotedString": quotedString,
    "singleQuotedString": singleQuotedString,
    "skipSpaces": skipSpaces,
    "endOfInput": endOfInput,
    "pure": pure,
    "fail": fail,
    "empty": empty,
    "precedence": precedence,
    "token": token,
    "parens": parens,
    "brackets": brackets,
    "braces": braces,
    "angles": angles,
    "lineComment": lineComment,
    "blockComment": blockComment,
    "parseCSV": parseCSV,
    "jsonValue": jsonValue,
    "jsonString": jsonString,
    "jsonNumber": jsonNumber,
    "jsonBool": jsonBool,
    "jsonNull": jsonNull,
    "jsonArray": jsonArray,
    "jsonObject": jsonObject,
    "jsonMember": jsonMember,
    "VERSION": VERSION
}

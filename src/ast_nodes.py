from abc import ABC, abstractmethod
from dataclasses import dataclass
from src.token_types import Token

# Base Nodes
class Node(ABC):
    @abstractmethod
    def token_literal(self) -> str:
        pass

    def __str__(self):
        pass

class Statement(Node):
    pass

class Expression(Node):
    pass

# Root Node
@dataclass
class Program(Node):
    statements: list[Statement]

    def token_literal(self) -> str:
        if self.statements:
            return self.statements[0].token_literal()
        return ""

    def __str__(self):
        return "".join(str(s) for s in self.statements)

# Expression Nodes
@dataclass
class Identifier(Expression):
    token: Token
    value: str

    def token_literal(self) -> str:
        return self.token.literal
    
    def __str__(self):
        return self.value

@dataclass
class IntegerLiteral(Expression):
    token: Token
    value: int

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return str(self.value)

@dataclass
class FloatLiteral(Expression):
    token: Token
    value: float

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return str(self.value)

@dataclass
class BinaryLiteral(Expression):
    token: Token
    value: str

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return self.value

@dataclass
class OctalLiteral(Expression):
    token: Token
    value: str

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return self.value

@dataclass
class HexLiteral(Expression):
    token: Token
    value: str

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return self.value


@dataclass
class BooleanLiteral(Expression):
    token: Token
    value: bool

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return self.token.literal

@dataclass
class StringLiteral(Expression):
    token: Token
    value: str

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return self.token.literal

@dataclass
class NullLiteral(Expression):
    token: Token

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return "null"

@dataclass
class PrefixExpression(Expression):
    token: Token
    operator: str
    right: Expression

    def token_literal(self) -> str:
        return self.token.literal
    
    def __str__(self):
        return f"({self.operator}{str(self.right)})"

@dataclass
class InfixExpression(Expression):
    token: Token
    left: Expression
    operator: str
    right: Expression

    def token_literal(self) -> str:
        return self.token.literal
    
    def __str__(self):
        return f"({str(self.left)} {self.operator} {str(self.right)})"

@dataclass
class AssignExpression(Expression):
    token: Token
    name: Identifier
    value: Expression

    def token_literal(self) -> str:
        return self.token.literal
    
    def __str__(self):
        return f"({str(self.name)} = {str(self.value)})"

@dataclass
class BlockStatement(Statement):
    token: Token
    statements: list[Statement]

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return "".join(str(s) for s in self.statements)

@dataclass
class ArrayLiteral(Expression):
    token: Token
    elements: list[Expression]

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return f"[{', '.join(str(e) for e in self.elements)}]"

@dataclass
class IndexExpression(Expression):
    token: Token
    left: Expression
    index: Expression

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return f"({str(self.left)}[{str(self.index)}])"

@dataclass
class HashLiteral(Expression):
    token: Token
    pairs: dict[Expression, Expression]

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        pairs_str = ", ".join(f"{str(k)}:{str(v)}" for k, v in self.pairs.items())
        return f"{{{pairs_str}}}"

@dataclass
class IfExpression(Expression):
    token: Token
    condition: Expression
    consequence: BlockStatement
    alternative: BlockStatement | None = None

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        out = f"if {str(self.condition)} {str(self.consequence)}"
        if self.alternative:
            out += f" else {str(self.alternative)}"
        return out

@dataclass
class WhileStatement(Statement):
    token: Token
    condition: Expression
    body: BlockStatement

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return f"while {str(self.condition)} {str(self.body)}"

@dataclass
class ForStatement(Statement):
    token: Token
    initialization: Statement
    condition: Expression
    increment: Expression
    body: BlockStatement

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return f"for ({str(self.initialization)}; {str(self.condition)}; {str(self.increment)}) {str(self.body)}"
        
@dataclass
class ForInStatement(Statement):
    token: Token
    iterator: Identifier
    iterable: Expression
    body: BlockStatement

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return f"for {self.iterator} in {self.iterable} {self.body}"

@dataclass
class FunctionLiteral(Expression):
    token: Token
    parameters: list[Identifier]
    body: BlockStatement
    name: Identifier | None = None

    def token_literal(self) -> str:
        return self.token.literal
    
    def __str__(self):
        params = ", ".join(str(p) for p in self.parameters)
        name = self.name or ""
        return f"{self.token_literal()} {name}({params}) {{ {str(self.body)} }}"

@dataclass
class CallExpression(Expression):
    token: Token
    function: Expression
    arguments: list[Expression]

    def token_literal(self) -> str:
        return self.token.literal
    
    def __str__(self):
        args = ", ".join(str(a) for a in self.arguments)
        return f"{str(self.function)}({args})"

@dataclass
class LetStatement(Statement):
    token: Token
    name: Identifier
    value: Expression

    def token_literal(self) -> str:
        return self.token.literal

    def __str__(self):
        return f"{self.token_literal()} {self.name} = {str(self.value)};"

@dataclass
class ReturnStatement(Statement):
    token: Token
    return_value: Expression | None = None

    def token_literal(self) -> str:
        return self.token.literal
    
    def __str__(self):
        if self.return_value:
            return f"{self.token_literal()} {str(self.return_value)};"
        return f"{self.token_literal()};"


@dataclass
class ExpressionStatement(Statement):
    token: Token
    expression: Expression

    def token_literal(self) -> str:
        return self.token.literal
    
    def __str__(self):
        return str(self.expression)

@dataclass
class ClassStatement(Statement):
    token: Token
    name: Identifier
    superclass: Identifier | None
    body: BlockStatement

    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class SuperExpression(Expression):
    token: Token
    
    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class SelfExpression(Expression):
    token: Token

    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class NewExpression(Expression):
    token: Token
    cls: Expression

    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class ImportStatement(Statement):
    token: Token
    path: StringLiteral

    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class FromStatement(Statement):
    token: Token
    path: StringLiteral
    imports: list[Identifier]

    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class TryStatement(Statement):
    token: Token
    try_block: BlockStatement
    except_block: BlockStatement | None
    finally_block: BlockStatement | None

    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class RaiseStatement(Statement):
    token: Token
    exception: Expression

    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class AssertStatement(Statement):
    token: Token
    condition: Expression
    message: Expression | None

    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class WithStatement(Statement):
    token: Token
    context: Expression
    body: BlockStatement

    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class YieldExpression(Expression):
    token: Token
    value: Expression | None

    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class AsyncStatement(Statement):
    token: Token
    statement: Statement

    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class AwaitExpression(Expression):
    token: Token
    expression: Expression

    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class PassStatement(Statement):
    token: Token

    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class BreakStatement(Statement):
    token: Token

    def token_literal(self) -> str:
        return self.token.literal

@dataclass
class ContinueStatement(Statement):
    token: Token

    def token_literal(self) -> str:
        return self.token.literal
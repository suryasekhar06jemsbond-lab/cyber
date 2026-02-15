from src.ast_nodes import *
from dataclasses import dataclass
import sys
import time
import asyncio
from functools import reduce

# Object System
@dataclass
class Integer:
    value: int
    def inspect(self) -> str: return str(self.value)
    def hash_key(self): return ("INTEGER", self.value)

@dataclass
class Float:
    value: float
    def inspect(self) -> str: return str(self.value)
    def hash_key(self): return ("FLOAT", self.value)

@dataclass
class Boolean:
    value: bool
    def inspect(self) -> str: return str(self.value).lower()
    def hash_key(self): return ("BOOLEAN", 1 if self.value else 0)

@dataclass
class String:
    value: str
    def inspect(self) -> str: return self.value
    def hash_key(self): return ("STRING", self.value)

@dataclass
class Null:
    def inspect(self) -> str: return "null"
    def hash_key(self): return ("NULL", 0)

@dataclass
class Error:
    message: str
    def inspect(self) -> str: return f"ERROR: {self.message}"

@dataclass
class Array:
    elements: list
    def inspect(self) -> str: return f"[{', '.join(e.inspect() for e in self.elements)}]"

@dataclass
class Hash:
    pairs: dict
    def inspect(self) -> str: return f"{{{', '.join(f'{v[0].inspect()}: {v[1].inspect()}' for _, v in self.pairs.items())}}}"

@dataclass
class Builtin:
    fn: callable
    def inspect(self) -> str: return "builtin function"

class Environment:
    def __init__(self, outer=None):
        self.store = {}
        self.outer = outer
    def get(self, name):
        val = self.store.get(name)
        if val is None and self.outer is not None:
            return self.outer.get(name)
        return val
    def set(self, name, val):
        self.store[name] = val
        return val

@dataclass
class Function:
    parameters: list[Identifier]
    body: BlockStatement
    env: Environment
    def inspect(self) -> str:
        return f"fn({', '.join(str(p) for p in self.parameters)}) {{\n{str(self.body)}\n}}"

@dataclass
class Class:
    name: Identifier
    superclass: 'Class'
    methods: dict
    def inspect(self) -> str: return self.name.value

@dataclass
class Instance:
    cls: Class
    fields: dict
    @property
    def methods(self): return self.cls.methods
    def inspect(self) -> str: return f"{self.cls.name.value} instance"
    def get(self, name):
        if name in self.fields: return self.fields[name]
        method = self.cls.methods.get(name)
        if method: return method
        if self.cls.superclass: return self.cls.superclass.methods.get(name)
    def set(self, name, value): self.fields[name] = value

@dataclass
class BoundMethod:
    method: Function
    receiver: Instance
    def inspect(self) -> str: return f"bound method"

@dataclass
class Module:
    name: str
    env: Environment
    def inspect(self) -> str: return f"module '{self.name}'"

@dataclass
class ReturnValue:
    value: any
    def inspect(self) -> str: return self.value.inspect()

@dataclass
class BreakValue:
    def inspect(self) -> str: return "break"

@dataclass
class ContinueValue:
    def inspect(self) -> str: return "continue"

TRUE = Boolean(True)
FALSE = Boolean(False)
NULL = Null()

def _is_error(obj): return isinstance(obj, Error)
def _is_truthy(obj):
    if obj == NULL: return False
    if obj == TRUE: return True
    if obj == FALSE: return False
    return True

# Built-in functions
def len_builtin(*args):
    if len(args) != 1: return Error(f"wrong number of arguments. got={len(args)}, want=1")
    if isinstance(args[0], String): return Integer(len(args[0].value))
    if isinstance(args[0], Array): return Integer(len(args[0].elements))
    return Error(f"argument to `len` not supported, got {type(args[0]).__name__}")

def print_builtin(*args):
    print(*(a.inspect() for a in args))
    return NULL

def type_builtin(*args):
    if len(args) != 1: return Error(f"wrong number of arguments. got={len(args)}, want=1")
    return String(type(args[0]).__name__)

def time_builtin(*args):
    return Float(time.time())

def input_builtin(*args):
    if len(args) > 1: return Error(f"wrong number of arguments. got={len(args)}, want=0 or 1")
    prompt = args[0].value if args else ""
    return String(input(prompt))

def str_builtin(*args):
    if len(args) != 1: return Error(f"wrong number of arguments. got={len(args)}, want=1")
    return String(args[0].inspect())

def int_builtin(*args):
    if len(args) != 1: return Error(f"wrong number of arguments. got={len(args)}, want=1")
    if isinstance(args[0], (String, Integer, Float)):
        try:
            return Integer(int(args[0].value))
        except ValueError:
            return Error(f"could not convert {args[0].inspect()} to integer")
    return Error(f"argument to `int` not supported, got {type(args[0]).__name__}")

def float_builtin(*args):
    if len(args) != 1: return Error(f"wrong number of arguments. got={len(args)}, want=1")
    if isinstance(args[0], (String, Integer, Float)):
        try:
            return Float(float(args[0].value))
        except ValueError:
            return Error(f"could not convert {args[0].inspect()} to float")
    return Error(f"argument to `float` not supported, got {type(args[0]).__name__}")

def abs_builtin(*args):
    if len(args) != 1: return Error(f"wrong number of arguments. got={len(args)}, want=1")
    if isinstance(args[0], (Integer, Float)):
        return type(args[0])(abs(args[0].value))
    return Error(f"argument to `abs` not supported, got {type(args[0]).__name__}")

def round_builtin(*args):
    if len(args) not in (1, 2): return Error(f"wrong number of arguments. got={len(args)}, want=1 or 2")
    if not isinstance(args[0], (Integer, Float)):
        return Error(f"argument to `round` not supported, got {type(args[0]).__name__}")
    if len(args) == 1:
        return Integer(round(args[0].value))
    if not isinstance(args[1], Integer):
        return Error(f"second argument to `round` must be an integer, got {type(args[1]).__name__}")
    return Float(round(args[0].value, args[1].value))

def max_builtin(*args):
    if not args: return Error("max() expected 1 argument, got 0")
    if isinstance(args[0], Array):
        if not args[0].elements: return NULL
        return max(args[0].elements, key=lambda x: x.value)
    return max(args, key=lambda x: x.value)

def min_builtin(*args):
    if not args: return Error("min() expected 1 argument, got 0")
    if isinstance(args[0], Array):
        if not args[0].elements: return NULL
        return min(args[0].elements, key=lambda x: x.value)
    return min(args, key=lambda x: x.value)

def sum_builtin(*args):
    if len(args) != 1: return Error(f"wrong number of arguments. got={len(args)}, want=1")
    if not isinstance(args[0], Array):
        return Error(f"argument to `sum` must be an array, got {type(args[0]).__name__}")
    total = 0
    for el in args[0].elements:
        if not isinstance(el, (Integer, Float)):
            return Error("can only sum numbers")
        total += el.value
    return Float(total) if any(isinstance(el, Float) for el in args[0].elements) else Integer(total)

async def map_builtin(*args):
    if len(args) != 2: return Error(f"wrong number of arguments. got={len(args)}, want=2")
    fn, arr = args
    if not isinstance(fn, Function): return Error("first argument must be a function")
    if not isinstance(arr, Array): return Error("second argument must be an array")
    
    results = [await _apply_function(fn, [el]) for el in arr.elements]
    return Array(results)

async def filter_builtin(*args):
    if len(args) != 2: return Error(f"wrong number of arguments. got={len(args)}, want=2")
    fn, arr = args
    if not isinstance(fn, Function): return Error("first argument must be a function")
    if not isinstance(arr, Array): return Error("second argument must be an array")
    
    results = []
    for el in arr.elements:
        if _is_truthy(await _apply_function(fn, [el])):
            results.append(el)
    return Array(results)

async def reduce_builtin(*args):
    if len(args) not in (2, 3): return Error(f"wrong number of arguments. got={len(args)}, want=2 or 3")
    fn, arr = args[0], args[1]
    initial = args[2] if len(args) == 3 else None

    if not isinstance(fn, Function): return Error("first argument must be a function")
    if not isinstance(arr, Array): return Error("second argument must be an array")
    
    elements = arr.elements
    if initial:
        accumulator = initial
    else:
        if not elements: return Error("reduce of empty sequence with no initial value")
        accumulator = elements[0]
        elements = elements[1:]

    for el in elements:
        accumulator = await _apply_function(fn, [accumulator, el])
    return accumulator


builtins = {
    "len": Builtin(len_builtin), "print": Builtin(print_builtin), "type": Builtin(type_builtin),
    "time": Builtin(time_builtin), "input": Builtin(input_builtin), "str": Builtin(str_builtin),
    "int": Builtin(int_builtin), "float": Builtin(float_builtin), "abs": Builtin(abs_builtin),
    "round": Builtin(round_builtin), "max": Builtin(max_builtin), "min": Builtin(min_builtin),
    "sum": Builtin(sum_builtin), "map": Builtin(map_builtin), "filter": Builtin(filter_builtin),
    "reduce": Builtin(reduce_builtin),
}

# Evaluation logic
async def evaluate(node: Node, env: Environment):
    node_type = type(node)
    
    # Literals
    if node_type == Program: return await _eval_program(node, env)
    if node_type == ExpressionStatement: return await evaluate(node.expression, env)
    if node_type == BlockStatement: return await _eval_block_statement(node, env)
    if node_type in (IntegerLiteral, FloatLiteral, StringLiteral, BooleanLiteral, NullLiteral, BinaryLiteral, OctalLiteral, HexLiteral):
        return _eval_literal(node)
    
    # Expressions
    if node_type == PrefixExpression:
        right = await evaluate(node.right, env)
        if _is_error(right): return right
        return _eval_prefix_expression(node.operator, right)
    if node_type == InfixExpression:
        left = await evaluate(node.left, env)
        if _is_error(left): return left
        # For member access (. operator), don't evaluate the right side - it's the member name
        if node.operator == ".":
            right = node.right  # Use the AST node directly, not evaluated
            return _eval_infix_expression(node.operator, left, right)
        right = await evaluate(node.right, env)
        if _is_error(right): return right
        return _eval_infix_expression(node.operator, left, right)
    if node_type == IfExpression: return await _eval_if_expression(node, env)
    if node_type == Identifier: return _eval_identifier(node, env)
    if node_type == FunctionLiteral:
        return Function(node.parameters, node.body, env)
    if node_type == CallExpression:
        function = await evaluate(node.function, env)
        if _is_error(function): return function
        args = await _eval_expressions(node.arguments, env)
        if len(args) == 1 and _is_error(args[0]): return args[0]
        return await _apply_function(function, args)
    if node_type == ArrayLiteral:
        elements = await _eval_expressions(node.elements, env)
        if len(elements) == 1 and _is_error(elements[0]): return elements[0]
        return Array(elements)
    if node_type == IndexExpression:
        left = await evaluate(node.left, env)
        if _is_error(left): return left
        index = await evaluate(node.index, env)
        if _is_error(index): return index
        return await _eval_index_expression(left, index)
    if node_type == HashLiteral: return await _eval_hash_literal(node, env)

    # Statements
    if node_type == LetStatement:
        val = await evaluate(node.value, env)
        if _is_error(val): return val
        env.set(node.name.value, val)
        return val
    if node_type == AssignExpression:
        val = await evaluate(node.value, env)
        if _is_error(val): return val
        # Handle both simple assignment and member assignment
        if isinstance(node.name, Identifier):
            env.set(node.name.value, val)
        elif isinstance(node.name, InfixExpression) and node.name.operator == '.':
            # Member assignment: obj.property = value
            left = await evaluate(node.name.left, env)
            if _is_error(left): return left
            if not isinstance(left, Instance):
                return Error(f"cannot assign to member of non-instance: {type(left).__name__}")
            # Get the member name (right side of the dot)
            if not isinstance(node.name.right, Identifier):
                return Error("member name must be identifier")
            left.set(node.name.right.value, val)
        else:
            return Error(f"invalid assignment target")
        return val
    if node_type == ReturnStatement:
        val = await evaluate(node.return_value, env) if node.return_value else NULL
        if _is_error(val): return val
        return ReturnValue(val)
    if node_type == WhileStatement: return await _eval_while_statement(node, env)
    if node_type == ForStatement: return await _eval_for_statement(node, env)
    if node_type == ForInStatement: return await _eval_for_in_statement(node, env)
    if node_type == ClassStatement: return await _eval_class_statement(node, env)
    if node_type == SuperExpression: return _eval_super_expression(env)
    if node_type == SelfExpression: return _eval_self_expression(env)
    if node_type == NewExpression:
        cls = await evaluate(node.cls, env)
        if _is_error(cls): return cls
        if not isinstance(cls, Class):
            return Error(f"new requires a class, got {type(cls).__name__}")
        # Return the class so that _apply_function can create the instance and call init
        return cls
    if node_type == AsyncStatement: return await _eval_async_statement(node, env)
    if node_type == AwaitExpression: return await _eval_await_expression(node, env)
    if node_type == BreakStatement: return BreakValue()
    if node_type == ContinueStatement: return ContinueValue()
    if node_type == PassStatement: return NULL

    return Error(f"unknown node type: {node_type.__name__}")

async def _eval_program(program, env):
    result = NULL
    for statement in program.statements:
        result = await evaluate(statement, env)
        if isinstance(result, (ReturnValue, Error)):
            return result.value if isinstance(result, ReturnValue) else result
    return result

async def _eval_block_statement(block, env):
    result = NULL
    for statement in block.statements:
        result = await evaluate(statement, env)
        if result and isinstance(result, (ReturnValue, Error, BreakValue, ContinueValue)):
            return result
    return result

def _eval_literal(node):
    node_type = type(node)
    if node_type == IntegerLiteral: return Integer(node.value)
    if node_type == FloatLiteral: return Float(node.value)
    if node_type == StringLiteral: return String(node.value)
    if node_type == BooleanLiteral: return TRUE if node.value else FALSE
    if node_type == NullLiteral: return NULL
    if node_type == BinaryLiteral: return Integer(int(node.value, 2))
    if node_type == OctalLiteral: return Integer(int(node.value, 8))
    if node_type == HexLiteral: return Integer(int(node.value, 16))
    return Error("unknown literal type")

def _eval_prefix_expression(operator, right):
    if operator == "!": return FALSE if _is_truthy(right) else TRUE
    if operator == "-":
        if not isinstance(right, (Integer, Float)): return Error(f"unknown operator: -{type(right).__name__.upper()}")
        return type(right)(-right.value)
    if operator == "~":
        if not isinstance(right, Integer): return Error(f"unknown operator: ~{type(right).__name__.upper()}")
        return Integer(~right.value)
    return Error(f"unknown operator: {operator}{type(right).__name__.upper()}")

def _eval_infix_expression(operator, left, right):
    if operator == ".":
        return _eval_member_expression(left, right)
    if type(left) != type(right) and operator not in ('==', '!='):
        return Error(f"type mismatch: {type(left).__name__.upper()} {operator} {type(right).__name__.upper()}")

    if isinstance(left, (Integer, Float)) and isinstance(right, (Integer, Float)):
        return _eval_numeric_infix_expression(operator, left, right)
    if isinstance(left, String) and isinstance(right, String):
        return _eval_string_infix_expression(operator, left, right)
    if operator == "==": return Boolean(left == right)
    if operator == "!=": return Boolean(left != right)
    
    return Error(f"unknown operator: {type(left).__name__.upper()} {operator} {type(right).__name__.upper()}")

def _eval_member_expression(left, right):
    """Evaluate member access expression (e.g., obj.method)"""
    if not isinstance(right, Identifier):
        return Error(f"member name must be identifier, got {type(right).__name__}")
    
    member_name = right.value
    
    if isinstance(left, Instance):
        # Instance member access - use the Instance's get method for proper lookup
        result = left.get(member_name)
        if result:
            if isinstance(result, Function):
                # Bind method to instance
                return BoundMethod(result, left)
            return result
        return Error(f"instance has no member '{member_name}'")
    
    if isinstance(left, Hash):
        key = right.hash_key()
        if key in left.pairs:
            return left.pairs[key][1]
        return Error(f"hash has no key '{member_name}'")
    
    return Error(f"member access not supported on {type(left).__name__}")

def _eval_numeric_infix_expression(op, left, right):
    lval, rval = left.value, right.value
    common_type = Float if isinstance(left, Float) or isinstance(right, Float) else Integer
    
    if op == "+": return common_type(lval + rval)
    if op == "-": return common_type(lval - rval)
    if op == "*": return common_type(lval * rval)
    if op == "/":
        if rval == 0: return Error("division by zero")
        return Float(lval / rval)
    if op == "**": return common_type(lval ** rval)
    if op == "%": return common_type(lval % rval)
    if op == "//":
        if rval == 0: return Error("division by zero")
        return Integer(lval // rval)
    if op == "&": return Integer(lval & rval)
    if op == "|": return Integer(lval | rval)
    if op == "^": return Integer(lval ^ rval)
    if op == "<<": return Integer(lval << rval)
    if op == ">>": return Integer(lval >> rval)
    if op == ">": return Boolean(lval > rval)
    if op == "<": return Boolean(lval < rval)
    if op == ">=": return Boolean(lval >= rval)
    if op == "<=": return Boolean(lval <= rval)
    if op == "==": return Boolean(lval == rval)
    if op == "!=": return Boolean(lval != rval)
    
    return Error(f"unknown operator: {type(left).__name__} {op} {type(right).__name__}")

def _eval_string_infix_expression(op, left, right):
    if op == "+": return String(left.value + right.value)
    return Error(f"unknown operator: String {op} String")

async def _eval_if_expression(ie, env):
    condition = await evaluate(ie.condition, env)
    if _is_error(condition): return condition
    if _is_truthy(condition):
        return await evaluate(ie.consequence, env)
    elif ie.alternative:
        return await evaluate(ie.alternative, env)
    return NULL

def _eval_identifier(node, env):
    val = env.get(node.value)
    if val: return val
    builtin = builtins.get(node.value)
    if builtin: return builtin
    return Error(f"identifier not found: {node.value}")

async def _eval_expressions(exps, env):
    return [await evaluate(e, env) for e in exps]

async def _apply_function(fn, args):
    if isinstance(fn, Function):
        extended_env = Environment(outer=fn.env)
        for param, arg in zip(fn.parameters, args):
            extended_env.set(param.value, arg)
        evaluated = await evaluate(fn.body, extended_env)
        if isinstance(evaluated, ReturnValue): return evaluated.value
        return evaluated # Should be NULL for functions without return
    if isinstance(fn, BoundMethod):
        # Apply bound method - bind 'self' to the receiver
        extended_env = Environment(outer=fn.method.env)
        # Set 'self' as first parameter if the method expects it
        if fn.method.parameters:
            first_param = fn.method.parameters[0]
            extended_env.set(first_param.value, fn.receiver)
        for param, arg in zip(fn.method.parameters[1:], args):
            extended_env.set(param.value, arg)
        evaluated = await evaluate(fn.method.body, extended_env)
        if isinstance(evaluated, ReturnValue): return evaluated.value
        return evaluated
    if isinstance(fn, Builtin):
        # some builtins are async
        if asyncio.iscoroutinefunction(fn.fn):
            return await fn.fn(*args)
        return fn.fn(*args)
    if isinstance(fn, Class):
        instance = Instance(fn, {})
        initializer = fn.methods.get("init")
        if initializer:
            # The 'self' argument is implicitly passed
            # Ignore the return value of init - it should not affect the instance
            await _apply_function(initializer, [instance] + args)
        return instance
    return Error(f"not a function: {type(fn).__name__}")

async def _eval_index_expression(left, index):
    if isinstance(left, Array) and isinstance(index, Integer):
        if 0 <= index.value < len(left.elements):
            return left.elements[index.value]
        return NULL
    if isinstance(left, Hash):
        key = index.hash_key()
        if key in left.pairs:
            return left.pairs[key][1]
        return NULL
    return Error(f"index operator not supported: {type(left).__name__}")

async def _eval_hash_literal(node, env):
    pairs = {}
    for key_node, value_node in node.pairs.items():
        key = await evaluate(key_node, env)
        if _is_error(key): return key
        if not hasattr(key, "hash_key"): return Error(f"unusable as hash key: {type(key).__name__}")
        value = await evaluate(value_node, env)
        if _is_error(value): return value
        hashed = key.hash_key()
        pairs[hashed] = (key, value)
    return Hash(pairs)

async def _eval_while_statement(ws, env):
    result = NULL
    while True:
        condition = await evaluate(ws.condition, env)
        if _is_error(condition): return condition
        if not _is_truthy(condition): break
        
        result = await evaluate(ws.body, env)
        if isinstance(result, (ReturnValue, Error)): return result
        if isinstance(result, BreakValue): break
        if isinstance(result, ContinueValue): continue
    return result

async def _eval_for_statement(fs, env):
    scope_env = Environment(outer=env)
    await evaluate(fs.initialization, scope_env)
    result = NULL
    while True:
        condition = await evaluate(fs.condition, scope_env)
        if _is_error(condition): return condition
        if not _is_truthy(condition): break
        
        body_result = await evaluate(fs.body, scope_env)
        if isinstance(body_result, (ReturnValue, Error)): return body_result
        if isinstance(body_result, BreakValue): break
        if isinstance(body_result, ContinueValue):
            await evaluate(fs.increment, scope_env)
            continue
        
        await evaluate(fs.increment, scope_env)
    return result

async def _eval_for_in_statement(fis, env):
    iterable = await evaluate(fis.iterable, env)
    if _is_error(iterable): return iterable
    if not isinstance(iterable, (Array, String)):
        return Error(f"for..in loop not supported for type {type(iterable).__name__}")
        
    scope_env = Environment(outer=env)
    result = NULL
    elements = iterable.elements if isinstance(iterable, Array) else [String(c) for c in iterable.value]
    
    for element in elements:
        scope_env.set(fis.iterator.value, element)
        body_result = await evaluate(fis.body, scope_env)
        if isinstance(body_result, (ReturnValue, Error)): return body_result
        if isinstance(body_result, BreakValue): break
        if isinstance(body_result, ContinueValue): continue
        
    return result

async def _eval_class_statement(cs, env):
    superclass = None
    if cs.superclass:
        superclass = await evaluate(cs.superclass, env)
        if not isinstance(superclass, Class):
            return Error("Superclass must be a class.")

    methods = {}
    class_env = Environment(outer=env)
    cls = Class(cs.name, superclass, methods)
    class_env.set(cs.name.value, cls)
    
    for stmt in cs.body.statements:
        if isinstance(stmt, ExpressionStatement) and isinstance(stmt.expression, FunctionLiteral):
            fn_literal = stmt.expression
            # When defining a method, the environment should be the class env.
            function = Function(fn_literal.parameters, fn_literal.body, class_env)
            methods[fn_literal.name.value] = function
        else:
            # Allow pass statements in class bodies
            if not isinstance(stmt, PassStatement):
                return Error("Only functions and pass statements are allowed inside a class body.")


    env.set(cs.name.value, cls)
    return NULL

def _eval_super_expression(env):
    # This is a simplification. Real implementation needs to track 'self' and the current class.
    return env.get("super")

def _eval_self_expression(env):
    return env.get("self")

async def _eval_async_statement(astmt, env):
    # This is a simplified async model. In a real scenario, you'd have an event loop.
    return await evaluate(astmt.statement, env)

async def _eval_await_expression(awt, env):
    return await evaluate(awt.expression, env)

import unittest
from src.lexer import Lexer
from src.parser import Parser
from src.interpreter import evaluate, Environment, Integer, Boolean, String, Null, Float, Array, Error
import asyncio

class TestInterpreter(unittest.TestCase):
    def _test_eval(self, source):
        lexer = Lexer(source)
        parser = Parser(lexer)
        program = parser.parse_program()
        env = Environment()
        # To handle top-level await, we run the evaluation in an asyncio event loop.
        return asyncio.run(evaluate(program, env))

    def test_integer_expression(self):
        tests = [("5", 5), ("10", 10), ("-5", -5), ("-10", -10)]
        for source, expected in tests:
            evaluated = self._test_eval(source)
            self.assertIsInstance(evaluated, Integer)
            self.assertEqual(evaluated.value, expected)

    def test_float_expression(self):
        tests = [("5.5", 5.5), ("10.0", 10.0), ("-5.5", -5.5)]
        for source, expected in tests:
            evaluated = self._test_eval(source)
            self.assertIsInstance(evaluated, Float)
            self.assertEqual(evaluated.value, expected)

    def test_string_expression(self):
        tests = [('"hello"', 'hello'), ("'world'", 'world')]
        for source, expected in tests:
            evaluated = self._test_eval(source)
            self.assertIsInstance(evaluated, String)
            self.assertEqual(evaluated.value, expected)

    def test_boolean_expression(self):
        tests = [("true", True), ("false", False)]
        for source, expected in tests:
            evaluated = self._test_eval(source)
            self.assertIsInstance(evaluated, Boolean)
            self.assertEqual(evaluated.value, expected)
            
    def test_null_expression(self):
        evaluated = self._test_eval("null")
        self.assertIsInstance(evaluated, Null)

    def test_let_statement(self):
        tests = [
            ("let a = 5; a;", 5),
            ("let a = 5 * 5; a;", 25),
            ("let a = 5; let b = a; b;", 5),
        ]
        for source, expected in tests:
            self.assertEqual(self._test_eval(source).value, expected)

    def test_function_application(self):
        tests = [
            ("let identity = fn(x) { x; }; identity(5);", 5),
            ("let double = fn(x) { x * 2; }; double(5);", 10),
            ("let add = fn(x, y) { x + y; }; add(5, 5);", 10),
            ("fn(x) { x; }(5)", 5)
        ]
        for source, expected in tests:
            self.assertEqual(self._test_eval(source).value, expected)

    def test_closures(self):
        source = """
        let newAdder = fn(x) {
            fn(y) { x + y };
        };
        let addTwo = newAdder(2);
        addTwo(2);
        """
        self.assertEqual(self._test_eval(source).value, 4)

    def test_builtins(self):
        tests = [
            ('len("")', 0),
            ('len("four")', 4),
            ('len("hello world")', 11),
            ('len([1, 2, 3])', 3),
            ('len([])', 0),
            ('max([1, 2, 3])', 3),
            ('min([1, 2, 3])', 1),
            ('sum([1, 2, 3])', 6),
            ('abs(-5)', 5),
            ('round(5.5)', 6),
        ]
        for source, expected in tests:
            evaluated = self._test_eval(source)
            self.assertEqual(evaluated.value, expected)

    def test_array_literals(self):
        source = "[1, 2 * 2, 3 + 3]"
        evaluated = self._test_eval(source)
        self.assertIsInstance(evaluated, Array)
        self.assertEqual(len(evaluated.elements), 3)
        self.assertEqual(evaluated.elements[0].value, 1)
        self.assertEqual(evaluated.elements[1].value, 4)
        self.assertEqual(evaluated.elements[2].value, 6)

    def test_array_index_expressions(self):
        tests = [
            ("[1, 2, 3][0]", 1),
            ("[1, 2, 3][1]", 2),
            ("[1, 2, 3][2]", 3),
            ("let i = 0; [1][i];", 1),
            ("[1, 2, 3][1 + 1];", 3),
        ]
        for source, expected in tests:
            self.assertEqual(self._test_eval(source).value, expected)

    def test_error_handling(self):
        tests = [
            ("5 + true;", "type mismatch: INTEGER + BOOLEAN"),
            ("5 + true; 5;", "type mismatch: INTEGER + BOOLEAN"),
            ("-true", "unknown operator: -BOOLEAN"),
            ("true + false;", "unknown operator: BOOLEAN + BOOLEAN"),
            ("foobar", "identifier not found: foobar"),
        ]
        for source, expected_msg in tests:
            evaluated = self._test_eval(source)
            self.assertIsInstance(evaluated, Error)
            self.assertEqual(evaluated.message, expected_msg)

    def test_class_and_instance(self):
        source = """
        class Person {
            fn init(self, name) {
                self.name = name;
            }
            fn greet(self) {
                return "Hello, " + self.name;
            }
        }
        let p = new Person("John");
        p.greet();
        """
        evaluated = self._test_eval(source)
        self.assertIsInstance(evaluated, String)
        self.assertEqual(evaluated.value, "Hello, John")

if __name__ == '__main__':
    unittest.main()
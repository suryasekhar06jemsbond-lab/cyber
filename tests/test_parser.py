import unittest
from src.lexer import Lexer
from src.parser import Parser
from src.ast_nodes import *

class TestParser(unittest.TestCase):
    def _parse_program(self, source):
        lexer = Lexer(source)
        parser = Parser(lexer)
        program = parser.parse_program()
        self.assertFalse(parser.errors, f"Parser has errors: {parser.errors}")
        return program

    def test_let_statements(self):
        source = "let x = 5; let y = 10; let foobar = 838383;"
        program = self._parse_program(source)
        self.assertEqual(len(program.statements), 3)
        expected = [("x", 5), ("y", 10), ("foobar", 838383)]
        for i, stmt in enumerate(program.statements):
            self.assertIsInstance(stmt, LetStatement)
            self.assertEqual(stmt.name.value, expected[i][0])
            # self.assertEqual(stmt.value.value, expected[i][1])

    def test_return_statements(self):
        source = "return 5; return 10; return;"
        program = self._parse_program(source)
        self.assertEqual(len(program.statements), 3)
        for stmt in program.statements:
            self.assertIsInstance(stmt, ReturnStatement)

    def test_class_statement(self):
        source = "class MyClass: ParentClass { pass; }"
        program = self._parse_program(source)
        self.assertEqual(len(program.statements), 1)
        stmt = program.statements[0]
        self.assertIsInstance(stmt, ClassStatement)
        self.assertEqual(stmt.name.value, "MyClass")
        self.assertEqual(stmt.superclass.value, "ParentClass")

    def test_for_in_statement(self):
        source = "for (x in my_array) { print(x); }"
        program = self._parse_program(source)
        self.assertEqual(len(program.statements), 1)
        stmt = program.statements[0]
        self.assertIsInstance(stmt, ForInStatement)
        self.assertEqual(stmt.iterator.value, "x")
        self.assertEqual(stmt.iterable.value, "my_array")

    def test_operator_precedence(self):
        tests = [
            ("-a * b", "((-a) * b)"),
            ("a + b / c", "(a + (b / c))"),
            ("a + b * c + d / e - f", "(((a + (b * c)) + (d / e)) - f)"),
            ("5 > 4 == 3 < 4", "((5 > 4) == (3 < 4))"),
            ("3 + 4 * 5 == 3 * 1 + 2 * 3", "((3 + (4 * 5)) == ((3 * 1) + (2 * 3)))"),
            ("1 + (2 + 3) + 4", "((1 + (2 + 3)) + 4)"),
            ("(5 + 5) * 2", "((5 + 5) * 2)"),
            ("2 / (5 + 5)", "(2 / (5 + 5))"),
            ("-(5 + 5)", "(-(5 + 5))"),
            ("!(true == true)", "(!(true == true))"),
            ("a + add(b * c) + d", "((a + add((b * c))) + d)"),
            ("add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))", "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"),
            ("add(a + b + c * d / f + g)", "add((((a + b) + ((c * d) / f)) + g))"),
        ]
        for source, expected in tests:
            program = self._parse_program(source)
            self.assertEqual(str(program).replace(";", ""), expected)

    def test_function_literal_with_name(self):
        source = "let myFunction = fn myFn(x, y) { x + y; };"
        program = self._parse_program(source)
        stmt = program.statements[0].value
        self.assertIsInstance(stmt, FunctionLiteral)
        self.assertEqual(stmt.name.value, "myFn")

    def test_binary_expressions(self):
        source = "0b1010 + 0b1010;"
        program = self._parse_program(source)
        stmt = program.statements[0].expression
        self.assertIsInstance(stmt, InfixExpression)
        self.assertIsInstance(stmt.left, BinaryLiteral)
        self.assertEqual(stmt.left.value, "1010")

if __name__ == '__main__':
    unittest.main()
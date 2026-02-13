# Cy Language Spec (Bootstrap Draft)

Version: `0.6-draft` (`v4 runtime`)

## File Extension

- Source files use `.cy`.

## Lexical Rules

1. `#` starts a line comment.
2. Whitespace is ignored except as separator.
3. Statements end with `;` unless the statement is a block form (`if`, `while`, `for`, `fn`, `try/catch`, `class`, `module`).

## Literals

1. Integer literals: `42`
2. String literals: `"hello"`
3. Boolean literals: `true`, `false`
4. `null` literal: `null`
5. Array literals: `[1, 2, 3]`
6. Object literals: `{x: 1, "y": 2}`

## Expressions

1. Arithmetic: `+ - * /`
2. Comparisons: `== != < > <= >=`
3. Unary operators: `-expr`, `!expr`
4. Grouping: `(expr)`
5. Identifier references: `name`
6. Function calls: `name(arg1, arg2)`
7. Indexing: `arr[0]`, `obj["x"]`
8. Member access: `obj.key`
9. Array comprehensions: `[expr for x in iterable if cond]`

Direct-codegen note:
1. Runtime interpreter supports comprehensions.
2. `v3` direct C codegen supports comprehensions in both array and object iteration forms.

## Statements

1. Expression statement: `1 + 2;`
2. Variable declaration: `let x = expr;`
3. Variable assignment: `x = expr;`
4. Return statement: `return expr;`
5. Conditional statement:

```cy
if (cond) {
    ...
} else {
    ...
}
```

6. Function declaration:

```cy
fn add(a, b) {
    return a + b;
}
```

7. Import statement:

```cy
import "lib.cy";
```

8. Exception handling:

```cy
try {
    throw "boom";
} catch (err) {
    print(err);
}
```

9. While loop:

```cy
while (cond) {
    ...
}
```

10. For-each loop:

```cy
for (item in iterable) {
    ...
}
```

11. Loop control:

```cy
break;
continue;
```

12. Class declaration:

```cy
class Point {
    fn init(self, x, y) {
        object_set(self, "x", x);
        object_set(self, "y", y);
    }
}
```

13. Module declaration:

```cy
module Math {
    fn add(a, b) {
        return a + b;
    }
}
```

14. Type alias declaration:

```cy
typealias NumberType = "int";
```

Import behavior:
1. Runtime interpreter (`cy`) resolves imports at runtime.
2. `v3` compiler resolves and de-duplicates imports at compile time.

## Builtins

1. `print(...)`
2. `len(value)`
3. `read(path)`
4. `write(path, value)`
5. `argc()`
6. `argv(index)`
7. `type(value)`
8. `push(array, value)`
9. `pop(array)`
10. Type predicates: `type_of`, `is_int`, `is_bool`, `is_string`, `is_array`, `is_function`, `is_null`
11. Object helpers: `object_new`, `object_set`, `object_get`
12. Object utilities: `keys(object)`
13. Class/object construction: `new(class_obj, ...)`
14. Class helpers: `class_new`, `class_with_ctor`, `class_set_method`, `class_name`
15. Class calls: `class_instantiate0/1/2`, `class_call0/1/2`
16. Compatibility/version: `lang_version()`, `require_version(version_string)`

## Runtime Notes

1. Arithmetic is integer arithmetic.
2. Top-level expression statements print non-null result values.
3. Imports are de-duplicated per run.
4. `argc()` includes the script path at index `0` (same indexing used by `argv`).
5. Runtime supports statement trace mode via `--trace` CLI flag.
6. Runtime supports in-process debugger flags: `--debug`, `--break`, `--step`, `--step-count`.
7. Runtime supports bytecode expression VM via `--vm`, with expression bytecode caching.
8. Runtime supports strict VM mode via `--vm-strict` (runtime error on VM fallback).
9. Runtime supports parser/lint mode via `--parse-only` (alias: `--lint`).
10. Runtime supports allocation guard flag `--max-alloc N`.
11. Runtime supports CLI version output via `--version`.

## Standard Library Modules

1. `stdlib/types.cy`
2. `stdlib/class.cy`

# Nyx Language Spec (Bootstrap Draft)

Version: `0.6-draft` (`v4 runtime`)

## File Extension

- Source files use `.ny` (only `.ny` is supported).

## Lexical Rules

1. `#` starts a line comment.
2. Whitespace is ignored except as separator.
3. Statements end with `;` unless the statement is a block form (`if`, `switch`, `while`, `for`, `fn`, `try/catch`, `class`, `module`).

## Literals

1. Integer literals: `42`
2. String literals: `"hello"`
3. Boolean literals: `true`, `false`
4. `null` literal: `null`
5. Array literals: `[1, 2, 3]`
6. Object literals: `{x: 1, "y": 2}`

## Expressions

1. Arithmetic: `+ - * / %`
2. Comparisons: `== != < > <= >=`
3. Unary operators: `-expr`, `!expr`
4. Logical operators: `expr && expr`, `expr || expr`
5. Null-coalescing: `expr ?? fallback`
6. Grouping: `(expr)`
7. Identifier references: `name`
8. Function calls: `name(arg1, arg2)`
9. Indexing: `arr[0]`, `obj["x"]`
10. Member access: `obj.key`
11. Array comprehensions:
   - Single-variable: `[expr for x in iterable if cond]`
   - Dual-variable: `[expr for i, x in iterable if cond]` (array: `i=index`, object: `i=key`)

Direct-codegen note:
1. Runtime interpreter supports comprehensions.
2. `v3` direct C codegen supports comprehensions in both array and object iteration forms.

## Statements

1. Expression statement: `1 + 2;`
2. Variable declaration: `let x = expr;`
3. Variable assignment: `x = expr;`
4. Return statement: `return expr;`
5. Conditional statement:

```nyx
if (cond) {
    ...
} else if (other_cond) {
    ...
} else {
    ...
}
```

6. Function declaration:

```nyx
fn add(a, b) {
    return a + b;
}
```

7. Import statement:

```nyx
import "lib.ny";
```

8. Exception handling:

```nyx
try {
    throw "boom";
} catch (err) {
    print(err);
}
```

9. While loop:

```nyx
while (cond) {
    ...
}
```

10. For-each loop:

```nyx
for (item in iterable) {
    ...
}
```

```nyx
for (k, v in iterable) {
    ...
}
```

11. Loop control:

```nyx
break;
continue;
```

12. Class declaration:

```nyx
class Point {
    fn init(self, x, y) {
        object_set(self, "x", x);
        object_set(self, "y", y);
    }
}
```

13. Module declaration:

```nyx
module Math {
    fn add(a, b) {
        return a + b;
    }
}
```

14. Switch statement:

```nyx
switch (value) {
    case 1: { print("one"); }
    case 2: { print("two"); }
    default: { print("other"); }
}
```

15. Type alias declaration:

```nyx
typealias NumberType = "int";
```

Import behavior:
1. Runtime interpreter (`nyx`) resolves imports at runtime.
2. `v3` compiler resolves and de-duplicates imports at compile time.

## Builtins

1. `print(...)`
2. `len(value)`
3. Numeric helpers: `abs`, `min`, `max`, `clamp`, `sum`
4. Boolean helpers: `all`, `any`
5. `range(stop)` / `range(start, stop)` / `range(start, stop, step)`
6. `read(path)`
7. `write(path, value)`
8. `argc()`
9. `argv(index)`
10. `type(value)`
11. `str(value)`, `int(value)`
12. `push(array, value)`
13. `pop(array)`
14. Type predicates: `type_of`, `is_int`, `is_bool`, `is_string`, `is_array`, `is_function`, `is_null`
15. Object helpers: `object_new`, `object_set`, `object_get`
16. Object utilities: `keys(object)`, `values(object)`, `items(object)`, `has(object, key)`
17. Class/object construction: `new(class_obj, ...)`
18. Class helpers: `class_new`, `class_with_ctor`, `class_set_method`, `class_name`
19. Class calls: `class_instantiate0/1/2`, `class_call0/1/2`
20. Compatibility/version: `lang_version()`, `require_version(version_string)`

## Runtime Notes

1. Arithmetic is integer arithmetic.
2. Top-level expression statements print non-null result values.
3. Imports are de-duplicated per run.
4. `argc()` includes the script path at index `0` (same indexing used by `argv`).
5. Runtime supports statement trace mode via `--trace` CLI flag.
6. Runtime supports in-process debugger flags: `--debug`, `--break`, `--step`, `--step-count`.
7. Runtime supports bytecode VM mode via `--vm`, with bytecode caching for expressions and statement blocks.
8. Runtime supports strict VM mode via `--vm-strict` (runtime error on VM fallback).
9. Runtime supports parser/lint mode via `--parse-only` (alias: `--lint`).
10. Runtime supports allocation guard flag `--max-alloc N`.
11. Runtime supports step guard flag `--max-steps N`.
12. Runtime supports call depth guard flag `--max-call-depth N`.
13. Runtime supports CLI version output via `--version`.

## Standard Library Modules

1. `stdlib/types.ny`
2. `stdlib/class.ny`

## Builtin Packages

Imports with `ny` prefix are built in to the runtime/compiler and do not require files on disk:

1. `import "nymath";` exposes `nymath` module helpers (`abs`, `min`, `max`, `clamp`, `pow`, `sum`)
2. `import "nyarrays";` exposes `nyarrays` module helpers (`first`, `last`, `sum`, `enumerate`)
3. `import "nyobjects";` exposes `nyobjects` module helpers (`merge`, `get_or`)
4. `import "nyjson";` exposes `nyjson.parse`/`nyjson.stringify` (primitive-focused JSON helpers)
5. `import "nyhttp";` exposes `nyhttp.get`/`nyhttp.text`/`nyhttp.ok` (file-path fetch helper module)

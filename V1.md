# v1 Milestone: Compiler-Capable Runtime

Status: `completed`

## Goal

Provide enough native language features to begin writing a compiler in `.ny`.

## v1 Features Implemented

1. Variables and assignment
- `let name = expr;`
- `name = expr;`

2. Control flow
- `if (cond) { ... } else { ... }`
- Comparisons: `== != < > <= >=`
- Boolean literals: `true`, `false`

3. Functions
- Function declarations: `fn name(args) { ... }`
- Function calls: `name(...)`
- `return expr;`
- Lexical closures

4. Strings and arrays
- String literals: `"text"`
- Array literals: `[1, 2, 3]`
- Indexing: `arr[0]`

5. File I/O builtins
- `read(path)`
- `write(path, value)`

6. Module/import support
- `import "relative_or_absolute_path.ny";`
- Imports are de-duplicated per run

## Builtins

- `print(...)`
- `len(value)`
- `read(path)`
- `write(path, value)`

## Acceptance Checks

1. `make` builds native runtime
2. `./scripts/test_v0.sh` passes
3. `./scripts/test_v1.sh` passes

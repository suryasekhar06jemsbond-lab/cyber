# Nyx Programming Language - Complete Guide (Beginner to Advanced)

<p align="center">
  <img src="nyx-logo.png" alt="Nyx Logo" width="200" height="200"/>
</p>

<p align="center">
  <a href="https://marketplace.visualstudio.com/items?itemName=SuryaSekharRoy.nyx-language">
    <img src="https://img.shields.io/visual-studio-marketplace/v/SuryaSekharRoy.nyx-language" alt="Version">
  </a>
  <a href="https://marketplace.visualstudio.com/items?itemName=SuryaSekHarRoy.nyx-language">
    <img src="https://img.shields.io/visual-studio-marketplace/i/SuryaSekHarRoy.nyx-language" alt="Installs">
  </a>
  <a href="LICENSE.md">
    <img src="https://img.shields.io/github/license/suryasekhar06jemsbond-lab/cyber" alt="License">
  </a>
  <img src="https://img.shields.io/github/forks/suryasekhar06jemsbond-lab/cyber" alt="Forks">
  <img src="https://img.shields.io/github/stars/suryasekhar06jemsbond-lab/cyber" alt="Stars">
</p>

---

# Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Your First Nyx Program](#your-first-nyx-program)
4. [Language Fundamentals](#language-fundamentals)
5. [Data Types](#data-types)
6. [Variables and Mutability](#variables-and-mutability)
7. [Operators](#operators)
8. [Control Flow](#control-flow)
9. [Functions](#functions)
10. [Classes and Object-Oriented Programming](#classes-and-object-oriented-programming)
11. [Modules and Imports](#modules-and-imports)
12. [Error Handling](#error-handling)
13. [Concurrency and Async Programming](#concurrency-and-async-programming)
14. [Standard Library Reference](#standard-library-reference)
15. [Advanced Features](#advanced-features)
16. [Examples and Recipes](#examples-and-recipes)
17. [Project Structure](#project-structure)
18. [Troubleshooting](#troubleshooting)

---

# 1. Introduction

## What is Nyx?

**Nyx** is a modern, expressive, high-level programming language that runs everywhere. Written in C with a custom VM, it combines the simplicity of scripting languages with the power of systems programming. Whether you're a beginner learning to code or an expert building complex systems, Nyx has something for everyone.

## Why Learn Nyx?

- **Modern Syntax** - Clean, readable code like Python but with systems-level capabilities
- **High Performance** - Compiled to bytecode, runs on custom VM with JIT compilation
- **Memory Safe** - Ownership & borrowing system (inspired by Rust) prevents memory bugs
- **Cross-Platform** - Windows, Linux, macOS - write once, run anywhere
- **Rich Standard Library** - 70+ built-in modules for any task
- **Package Manager** - Built-in nypm for easy dependency management
- **Great Tooling** - VS Code extension, debugger, formatter, linter

## Version Information
- **Current Version**: 2.0.2
- **License**: Proprietary
- **Author**: Surya Sekhar Roy
- **Repository**: github.com/suryasekhar06jemsbond-lab/cyber

---

# 2. Installation

## Option 1: VS Code Marketplace (Recommended)

```powershell
# Open VS Code
# Press Ctrl+Shift+X
# Search "Nyx Language"
# Click Install
```

## Option 2: Manual Installation (VSIX)

```powershell
# Download the .vsix file from releases
code --install-extension nyx-language-2.0.2.vsix
```

## Option 3: Standalone Runtime

```powershell
# Windows - Download and run
curl -L -o nyx.exe "https://github.com/suryasekhar06jemsbond-lab/cyber/releases/download/v2.0.2/nyx.exe"
nyx.exe --version

# Add to PATH for global access
```

## Option 4: Install Script

```powershell
# Windows (PowerShell)
irm https://raw.githubusercontent.com/suryasekhar06jemsbond-lab/cyber/main/scripts/install.ps1 | iex

# Linux/macOS
curl -fsSL https://raw.githubusercontent.com/suryasekhar06jemsbond-lab/cyber/main/scripts/install.sh | sh
```

## Verify Installation

```powershell
nyx --version
# Output: 2.0.2

nyx --help
```

---

# 3. Your First Nyx Program

## Hello World

Create a file called `hello.ny` and write:

```nyx
print("Hello, World!");
```

Run it:

```powershell
nyx hello.ny
```

Output: `Hello, World!`

## Simple Calculator

```nyx
// A simple calculator program
let a = 10;
let b = 5;

print("a + b = " + str(a + b));
print("a - b = " + str(a - b));
print("a * b = " + str(a * b));
print("a / b = " + str(a / b));
```

## Interactive Input

```nyx
import io;

print("Enter your name:");
let name = io.input();
print("Hello, " + name + "!");
```

---

# 4. Language Fundamentals

## Comments

```nyx
// This is a single-line comment

/*
 This is a
 multi-line comment
*/

/// Documentation comment
```

## Statements and Expressions

```nyx
// Statement - performs an action
let x = 5;

// Expression - produces a value
let y = x + 3;  // x + 3 is an expression
```

## Blocks

```nyx
let result = {
    let a = 10;
    let b = 20;
    a + b  // Last expression is the block's value
};
print(result);  // 30
```

---

# 5. Data Types

## Primitive Types

### Numbers

```nyx
// Integers
let int_val = 42;
let hex_val = 0xFF;      // 255
let binary_val = 0b1010; // 10
let octal_val = 0o755;   // 493

// Floats
let float_val = 3.14;
let scientific = 1e10;    // 10000000000

// Type conversion
let str_num = "42";
let num = int(str_num);  // 42
let as_str = str(42);    // "42"
let as_float = float(3); // 3.0
```

### Strings

```nyx
let s1 = "Hello";
let s2 = 'World';
let s3 = `Template: ${s1} ${s2}`;  // "Template: Hello World"

// String methods
let len = len("Hello");           // 5
let upper = "hello".to_upper();   // "HELLO"
let lower = "HELLO".to_lower();  // "hello"
let trimmed = "  hello  ".trim(); // "hello"
let split = "a,b,c".split(",");  // ["a", "b", "c"]
let replace = "hello".replace("l", "r"); // "herro"
let contains = "hello".contains("ell"); // true
let starts = "hello".starts_with("hel"); // true
let ends = "hello".ends_with("lo");     // true
let index = "hello".find("l");          // 2
let substr = "hello".substr(1, 3);      // "ell"
let join = ["a", "b", "c"].join("-");   // "a-b-c"
```

### Booleans

```nyx
let is_true = true;
let is_false = false;

// Boolean operations
let and_op = true && false;   // false
let or_op = true || false;     // true
let not_op = !true;            // false
```

### Null

```nyx
let empty = null;

// Null coalescing
let value = null ?? "default"; // "default"

// Null-aware access
let name = user?.name ?? "Anonymous";
```

## Compound Types

### Arrays

```nyx
// Array creation
let numbers = [1, 2, 3, 4, 5];
let mixed = [1, "two", 3.0, true];
let empty = [];

// Array indexing (0-based)
let first = numbers[0];   // 1
let last = numbers[-1];    // 5

// Array slicing
let slice = numbers[1:4];  // [2, 3, 4]

// Array methods
let len = len(numbers);                // 5
numbers.push(6);                       // [1,2,3,4,5,6]
let popped = numbers.pop();            // 6, numbers = [1,2,3,4,5]
let shifted = numbers.shift();         // 1, numbers = [2,3,4,5]
numbers.unshift(0);                    // [0,1,2,3,4,5]
let joined = numbers.join(", ");       // "1, 2, 3, 4, 5"
let reversed = numbers.reverse();       // [5,4,3,2,1]
let sorted = numbers.sort();           // [1,2,3,4,5]
let cloned = numbers.clone();

// Array comprehension
let squares = [for x in range(10) { x * x }];  // [0,1,4,9,16,25,36,49,64,81]
let evens = [for x in range(10) if x % 2 == 0 { x }]; // [0,2,4,6,8]
```

### Objects (Dictionaries)

```nyx
// Object creation
let person = {
    name: "John",
    age: 30,
    city: "NYC"
};

// Accessing values
let name = person.name;    // "John"
let age = person["age"];   // 30

// Modifying objects
person.age = 31;
person.email = "john@example.com";
del person.city;

// Object methods
let keys = keys(person);      // ["name", "age", "email"]
let values = values(person);   // ["John", 31, "john@example.com"]
let has_name = "name" in person; // true
let merged = {a: 1}.merge({b: 2}); // {a: 1, b: 2}
let cloned = person.clone();

// Object spread
let defaults = {theme: "dark", lang: "en"};
let user_config = {...defaults, theme: "light"};
```

### Tuples

```nyx
let point = (10, 20);
let x = point[0];  // 10
let y = point[1];  // 20

// Destructuring
let (a, b) = point;
```

---

# 6. Variables and Mutability

## Immutable Variables (Default)

```nyx
let name = "Nyx";
let age = 5;

// Cannot reassign
// name = "Other";  // Error!
```

## Mutable Variables

```nyx
mut count = 0;
count = count + 1;
print(count);  // 1
```

## Constants

```nyx
const PI = 3.14159;
const MAX_SIZE = 100;
```

## Type Annotations

```nyx
let num: int = 42;
let text: string = "Hello";
let flag: bool = true;
let arr: [int] = [1, 2, 3];
let obj: {name: string, age: int} = {name: "John", age: 30};
```

---

# 7. Operators

## Arithmetic Operators

```nyx
let a = 10, b = 3;

let sum = a + b;      // 13
let diff = a - b;     // 7
let prod = a * b;     // 30
let quot = a / b;     // 3 (integer division)
let rem = a % b;      // 1 (remainder)
let pow = a ** b;     // 1000 (10^3)

// Increment/Decrement
mut x = 5;
x += 3;   // 8
x -= 2;   // 6
x *= 2;   // 12
x /= 3;   // 4
```

## Comparison Operators

```nyx
let a = 5, b = 10;

let eq = a == b;    // false
let neq = a != b;   // true
let lt = a < b;     // true
let gt = a > b;     // false
let lte = a <= b;   // true
let gte = a >= b;   // false
```

## Logical Operators

```nyx
let a = true, b = false;

let and = a && b;   // false
let or = a || b;    // true
let not = !a;       // false
```

## Null Coalescing

```nyx
let a = null ?? "default";  // "default"
let b = "value" ?? "default"; // "value"
```

## Ternary Operator

```nyx
let age = 20;
let status = age >= 18 ? "adult" : "minor";
```

---

# 8. Control Flow

## If-Else

```nyx
let age = 20;

if age >= 18 {
    print("Adult");
} else if age >= 13 {
    print("Teen");
} else {
    print("Child");
}
```

## Match (Pattern Matching)

```nyx
let value = 2;

let result = match value {
    1 => "one",
    2 => "two",
    3 => "three",
    _ => "other"
};
print(result);  // "two"

// Match with conditions
let num = 15;
let desc = match {
    num < 0 => "negative",
    num == 0 => "zero",
    num < 10 => "single digit",
    num < 100 => "double digit",
    _ => "large number"
};
```

## Switch

```nyx
let day = "Monday";

switch day {
    case "Saturday", "Sunday" {
        print("Weekend!");
    }
    case "Monday" {
        print("Start of work week");
    }
    default {
        print("Weekday");
    }
}
```

## While Loop

```nyx
mut i = 0;
while i < 5 {
    print(i);
    i += 1;
}
// Output: 0, 1, 2, 3, 4
```

## For Loop

```nyx
// Iterate over array
for num in [1, 2, 3, 4, 5] {
    print(num);
}

// Iterate with index
for i, num in [10, 20, 30] {
    print("${i}: ${num}");
}

// Iterate over range
for i in range(5) {     // 0, 1, 2, 3, 4
    print(i);
}

for i in range(1, 6) {  // 1, 2, 3, 4, 5
    print(i);
}

// Iterate over object
for key, value in {name: "John", age: 30} {
    print("${key}: ${value}");
}
```

## Loop Control

```nyx
// Break
for i in range(10) {
    if i == 5 {
        break;
    }
    print(i);  // 0, 1, 2, 3, 4
}

// Continue
for i in range(5) {
    if i == 2 {
        continue;
    }
    print(i);  // 0, 1, 3, 4 (skips 2)
}
```

---

# 9. Functions

## Basic Functions

```nyx
fn greet(name) {
    return "Hello, " + name + "!";
}

print(greet("Nyx"));  // "Hello, Nyx!"
```

## Parameters and Return Types

```nyx
// Default parameters
fn greet(name, greeting = "Hello") {
    return greeting + ", " + name + "!";
}

print(greet("Nyx"));           // "Hello, Nyx!"
print(greet("Nyx", "Hi"));     // "Hi, Nyx!"

// Return type annotations
fn add(a: int, b: int): int {
    return a + b;
}

// Variadic functions
fn sum(*numbers) {
    let total = 0;
    for n in numbers {
        total += n;
    }
    return total;
}

print(sum(1, 2, 3, 4, 5));  // 15
```

## Lambda Functions

```nyx
let double = fn(x) { x * 2 };
print(double(5));  // 10

// Immediately invoked
print(fn(x, y) { x + y }(3, 4));  // 7
```

## Higher-Order Functions

```nyx
fn apply(fn, value) {
    return fn(value);
}

let result = apply(fn(x) { x * 2 }, 5);
print(result);  // 10

// Return a function
fn multiplier(n) {
    return fn(x) { x * n };
}

let double = multiplier(2);
let triple = multiplier(3);
print(double(5));   // 10
print(triple(5));  // 15
```

## Closures

```nyx
fn counter() {
    let count = 0;
    return fn() {
        count += 1;
        return count;
    };
}

let c = counter();
print(c());  // 1
print(c());  // 2
print(c());  // 3
```

## Recursion

```nyx
fn factorial(n) {
    if n <= 1 {
        return 1;
    }
    return n * factorial(n - 1);
}

print(factorial(5));  // 120

// Fibonacci
fn fib(n) {
    if n <= 1 {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

for i in range(10) {
    print(fib(i));
}
```

---

# 10. Classes and Object-Oriented Programming

## Defining Classes

```nyx
class Person {
    // Constructor
    fn init(self, name, age) {
        self.name = name;
        self.age = age;
    }
    
    // Instance method
    fn introduce(self) {
        return "I'm " + self.name + ", " + str(self.age) + " years old";
    }
    
    // Another method
    fn birthday(self) {
        self.age += 1;
    }
    
    // Static method
    static fn create(name) {
        return new Person(name, 0);
    }
}

// Creating instances
let john = new Person("John", 30);
print(john.introduce());
john.birthday();
print(john.age);  // 31

// Static method
let baby = Person.create("Baby");
```

## Inheritance

```nyx
class Animal {
    fn init(self, name) {
        self.name = name;
    }
    
    fn speak(self) {
        return "...";
    }
}

class Dog < Animal {
    fn init(self, name, breed) {
        super.init(name);
        self.breed = breed;
    }
    
    fn speak(self) {
        return "Woof!";
    }
    
    fn fetch(self) {
        return self.name + " fetches the ball";
    }
}

let dog = new Dog("Buddy", "Golden Retriever");
print(dog.speak());  // "Woof!"
print(dog.fetch());   // "Buddy fetches the ball"
```

## Encapsulation

```nyx
class BankAccount {
    fn init(self, initial_balance) {
        // Private variable (convention)
        self._balance = initial_balance;
    }
    
    fn deposit(self, amount) {
        if amount > 0 {
            self._balance += amount;
            return true;
        }
        return false;
    }
    
    fn withdraw(self, amount) {
        if amount > 0 && amount <= self._balance {
            self._balance -= amount;
            return true;
        }
        return false;
    }
    
    fn get_balance(self) {
        return self._balance;
    }
}

let account = new BankAccount(1000);
account.deposit(500);
account.withdraw(200);
print(account.get_balance());  // 1300
```

## Static Variables

```nyx
class Counter {
    static mut count = 0;
    
    fn init(self) {
        Counter.count += 1;
    }
    
    static fn get_count() {
        return Counter.count;
    }
}

let a = new Counter();
let b = new Counter();
print(Counter.get_count());  // 2
```

---

# 11. Modules and Imports

## Creating Modules

Create a file `math_utils.ny`:

```nyx
module MathUtils {
    const PI = 3.14159;
    
    fn square(x) {
        return x * x;
    }
    
    fn cube(x) {
        return x * x * x;
    }
    
    fn factorial(n) {
        if n <= 1 { return 1; }
        return n * factorial(n - 1);
    }
}
```

## Importing Modules

```nyx
// Import entire module
import MathUtils;
print(MathUtils.square(5));     // 25
print(MathUtils.PI);            // 3.14159

// Alias import
import MathUtils as mu;
print(mu.cube(3));               // 27

// Selective import
import MathUtils.{square, cube};

// Import built-in modules
import math;
import json;
import http;
import tensor;
```

---

# 12. Error Handling

## Try-Catch

```nyx
try {
    let result = risky_operation();
    print("Success: " + str(result));
} catch error {
    print("Error: " + str(error));
}
```

## Catch Specific Errors

```nyx
try {
    parse_data(input);
} catch ParseError as e {
    print("Parse error: " + str(e));
} catch NetworkError as e {
    print("Network error: " + str(e));
} catch error {
    print("Unknown error: " + str(error));
}
```

## Throw Custom Errors

```nyx
fn divide(a, b) {
    if b == 0 {
        throw "Cannot divide by zero!";
    }
    return a / b;
}

try {
    let result = divide(10, 0);
} catch error {
    print(error);  // "Cannot divide by zero!"
}
```

## Finally Block

```nyx
try {
    risky_operation();
} catch error {
    print("Error: " + str(error));
} finally {
    cleanup();  // Always runs
}
```

---

# 13. Concurrency and Async Programming

## Async Functions

```nyx
import async;

// Async function
async fn fetch_data(url) {
    let response = http.get(url);
    return response.json();
}

// Await result
let data = await fetch_data("https://api.example.com/data");
```

## Parallel Execution

```nyx
// Run multiple tasks in parallel
let results = await async.collect([
    fetch_data("https://api1.com"),
    fetch_data("https://api2.com"),
    fetch_data("https://api3.com")
]);
```

## Spawning Tasks

```nyx
let task = async.spawn(fn() {
    let result = long_computation();
    return result;
});

// Do other work here...

let result = await task;
```

## Channels

```nyx
let channel = async.channel();

async.spawn(fn() {
    channel.send("message");
});

let msg = channel.recv();
```

---

# 14. Standard Library Reference

This section covers all 70+ modules in the Nyx standard library.

## Core Modules

### json - JSON Processing

```nyx
import json;

// Parse JSON string
let data = json.parse('{"name": "John", "age": 30}');
print(data.name);  // "John"

// Convert to JSON string
let str = json.stringify({name: "John", age: 30});
// '{"name":"John","age":30}'
```

### http - Web Server and Client

```nyx
import http;

// Create HTTP server
let server = http.Server.new(8080);

// Define routes
server.get("/", fn(req) {
    return req.send("Hello!");
});

server.get("/api/users", fn(req) {
    return req.json({
        users: [
            {name: "Alice", age: 30},
            {name: "Bob", age: 25}
        ]
    });
});

server.post("/api/data", fn(req) {
    let data = req.json();
    return req.json({received: true});
});

// Make HTTP request
let response = http.get("https://api.example.com/data");
let status = response.status;
let body = response.json();
```

### file - File Operations

```nyx
import file;

// Read file
let content = file.read("data.txt");

// Write file
file.write("output.txt", "Hello, World!");

// Append to file
file.append("log.txt", "New entry\n");

// Check if file exists
if file.exists("data.txt") {
    print("File exists");
}

// Get file info
let info = file.info("data.txt");
print(info.size);
print(info.modified);

// List directory
let files = file.list(".");
```

### os - Operating System

```nyx
import os;

// Environment variables
let path = os.getenv("PATH");
os.setenv("MY_VAR", "value");

// System info
let platform = os.platform();  // "windows", "linux", "darwin"
let arch = os.arch();           // "x64", "arm64"

// Execute command
let output = os.exec("ls -la");
print(output);

// Get current directory
let cwd = os.cwd();

// File path operations
let joined = os.path.join("dir", "file.txt");
let basename = os.path.basename("/path/to/file.txt");  // "file.txt"
let dirname = os.path.dirname("/path/to/file.txt");    // "/path/to"
```

### time - Date and Time

```nyx
import time;

// Current time
let now = time.now();
print(now.unix());      // Unix timestamp
print(now.iso());       // ISO 8601 string

// Parse time
let parsed = time.parse("2024-01-15", "%Y-%m-%d");
print(parsed.year);
print(parsed.month);
print(parsed.day);

// Format time
let formatted = now.format("%Y-%m-%d %H:%M:%S");

// Time arithmetic
let tomorrow = now.add(1, "day");
let yesterday = now.sub(1, "day");

// Sleep
time.sleep(1);  // Sleep for 1 second
```

### regex - Regular Expressions

```nyx
import regex;

// Match
let pattern = regex.new(r"\d+");
let match = pattern.match("abc123def");
print(match.group());  // "123"

// Find all
let matches = pattern.find_all("abc123def456");
print(matches);  // ["123", "456"]

// Replace
let result = pattern.replace("abc123def", "NUM");
// "abcNUMdef"

// Split
let parts = pattern.split("a1b2c3");
// ["a", "b", "c"]
```

---

## Data Structures

### collections - Advanced Collections

```nyx
import collections;

// List (Doubly-linked list)
let list = collections.list();
list.push_back(1);
list.push_back(2);
list.push_front(0);

// Queue
let queue = collections.queue();
queue.push(1);
queue.push(2);
let first = queue.pop();

// Stack
let stack = collections.stack();
stack.push(1);
stack.push(2);
let top = stack.pop();

// Deque
let deque = collections.deque();
deque.push_front(1);
deque.push_back(2);

// Heap (priority queue)
let heap = collections.heap();
heap.push(3);
heap.push(1);
heap.push(2);
let min = heap.pop();  // 1

// Tree
let tree = collections.tree();
tree.insert(5);
tree.insert(3);
tree.insert(7);

// Graph
let graph = collections.graph();
graph.add_edge(1, 2);
graph.add_edge(2, 3);
```

---

## Math and Science

### math - Mathematical Functions

```nyx
import math;

// Basic functions
print(math.abs(-5));      // 5
print(math.ceil(3.14));   // 4
print(math.floor(3.14));  // 3
print(math.round(3.5));   // 4
print(math.sqrt(16));     // 4
print(math.pow(2, 3));   // 8

// Trigonometry
print(math.sin(math.PI / 2));  // 1
print(math.cos(0));             // 1
print(math.tan(0));             // 0
print(math.atan(1));            // π/4

// Logarithms
print(math.log(math.E));        // 1
print(math.log10(100));         // 2
print(math.exp(1));             // 2.718...

// Constants
print(math.PI);
print(math.E);

// Min/Max
print(math.min(1, 2, 3));  // 1
print(math.max(1, 2, 3));  // 3

// Clamp
print(math.clamp(5, 0, 10));  // 5
print(math.clamp(-1, 0, 10)); // 0
```

### tensor - Multi-dimensional Arrays

```nyx
import tensor;

// Create tensors
let t1 = tensor.tensor([1, 2, 3, 4]);
let t2 = tensor.randn([3, 4]);  // Random normal
let t3 = tensor.zeros([2, 3]);
let t4 = tensor.ones([2, 3]);
let t5 = tensor.arange(10);  // 0 to 9

// Operations
let sum = tensor.sum(t1);
let mean = tensor.mean(t1);
let std = tensor.std(t1);

// Math operations
let added = t1 + 1;
let multiplied = t1 * 2;
let matmul = tensor.matmul(tensor.randn([2, 3]), tensor.randn([3, 2]));

// Reshape
let reshaped = tensor.reshape(t1, [2, 2]);

// Indexing
let val = t1[0];
let slice = t1[0:2];

// Conversion
let arr = t1.to_array();
```

### nn - Neural Networks

```nyx
import nn;

// Layers
let linear = nn.Linear.new(10, 5);
let conv = nn.Conv2d.new(1, 16, 3);
let relu = nn.ReLU.new();
let sigmoid = nn.Sigmoid.new();
let dropout = nn.Dropout.new(0.5);

// Activation functions
let activated = relu.forward(tensor.randn([4, 10]));

// Create a model
let model = nn.Sequential([
    nn.Linear.new(784, 128),
    nn.ReLU.new(),
    nn.Dropout.new(0.2),
    nn.Linear.new(128, 10)
]);

// Forward pass
let input = tensor.randn([32, 784]);
let output = model.forward(input);
print(tensor.shape(output));  // [32, 10]
```

### optim - Optimization Algorithms

```nyx
import optim;

// SGD optimizer
let sgd = optim.SGD.new(model.parameters(), lr: 0.01, momentum: 0.9);

// Adam optimizer
let adam = optim.Adam.new(model.parameters(), lr: 0.001);

// Training loop
for epoch in range(100) {
    let pred = model.forward(x);
    let loss = compute_loss(pred, y);
    
    optimizer.zero_grad();
    loss.backward();
    optimizer.step();
}
```

### autograd - Automatic Differentiation

```nyx
import autograd;

// Create variables with gradients
let x = autograd.variable(3.0);
let y = autograd.variable(2.0);

// Perform operations
let z = x * y + x;

// Backward
z.backward();

// Get gradients
print(x.grad);  // dy/dx = y + 1 = 3
print(y.grad);  // dy/dy = x = 3
```

### fft - Fast Fourier Transform

```nyx
import fft;

// Compute FFT
let signal = [1, 2, 3, 4];
let transformed = fft.fft(signal);

// Inverse FFT
let reconstructed = fft.ifft(transformed);

// Power spectrum
let power = fft.power(signal);

// Frequency bins
let freqs = fft.freq(44100, len(signal));
```

### blas - Linear Algebra

```nyx
import blas;

// Matrix multiplication
let a = [[1, 2], [3, 4]];
let b = [[5, 6], [7, 8]];
let result = blas.matmul(a, b);

// Vector operations
let v1 = [1, 2, 3];
let v2 = [4, 5, 6];
let dot = blas.dot(v1, v2);     // 32
let norm1 = blas.norm(v1);      // sqrt(14)

// Solve linear system
let A = [[2, 1], [1, 3]];
let b = [3, 4];
let x = blas.solve(A, b);
```

### sparse - Sparse Matrices

```nyx
import sparse;

// Create sparse matrix
let indices = [[0, 1], [1, 2], [2, 0]];
let values = [1, 2, 3];
let shape = [3, 3];
let sm = sparse.csr(indices, values, shape);

// Operations
let result = sparse.matmul(sm, dense_vector);
```

---

## Networking

### network - Network Utilities

```nyx
import network;

// TCP
let tcp = network.TCP.new();
tcp.connect("example.com", 80);
tcp.send("GET / HTTP/1.1\r\n\r\n");
let response = tcp.recv();
tcp.close();

// UDP
let udp = network.UDP.new();
udp.bind("0.0.0.0", 8080);
let (data, addr) = udp.recvfrom();
udp.sendto(data, addr);
```

### socket - Low-level Sockets

```nyx
import socket;

// Create socket
let sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM);
sock.connect(("example.com", 80));

// Send/Receive
sock.send(b"Hello");
let data = sock.recv(1024);

sock.close();
```

---

## Cryptography

### crypto - Cryptographic Functions

```nyx
import crypto;

// Hashing
let sha256 = crypto.sha256("hello");
let md5 = crypto.md5("hello");
let sha1 = crypto.sha1("hello");

// HMAC
let hmac = crypto.hmac_sha256("key", "message");

// AES encryption
let key = crypto.rand_bytes(32);  // 256-bit key
let iv = crypto.rand_bytes(16);   // 128-bit IV
let encrypted = crypto.aes_encrypt("message", key, iv);
let decrypted = crypto.aes_decrypt(encrypted, key, iv);

// RSA
let (pubkey, privkey) = crypto.rsa_generate(2048);
let encrypted = crypto.rsa_encrypt(pubkey, "message");
let decrypted = crypto.rsa_decrypt(privkey, encrypted);

// Random
let random_bytes = crypto.rand_bytes(32);
let random_int = crypto.rand_int(100);
```

### jwt - JSON Web Tokens

```nyx
import jwt;

// Create token
let payload = {
    sub: "1234567890",
    name: "John Doe",
    iat: time.now().unix()
};
let token = jwt.encode(payload, "secret", "HS256");

// Verify token
let decoded = jwt.decode(token, "secret");
print(decoded.name);  // "John Doe"
```

---

## Database

### database - Database Operations

```nyx
import database;

// Connect to SQLite
let db = database.connect("myapp.db");

// Create table
db.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT)");

// Insert
db.execute("INSERT INTO users (name, email) VALUES (?, ?)", ["John", "john@example.com"]);

// Query
let rows = db.query("SELECT * FROM users WHERE id = ?", [1]);
for row in rows {
    print(row.name);
}

// Update
db.execute("UPDATE users SET name = ? WHERE id = ?", ["Jane", 1]);

// Delete
db.execute("DELETE FROM users WHERE id = ?", [1]);

db.close();
```

### redis - Redis Client

```nyx
import redis;

// Connect
let r = redis.connect("localhost", 6379);

// String operations
r.set("key", "value");
let val = r.get("key");
r.incr("counter");
r.append("key", "more");

// Hash operations
r.hset("user", "name", "John");
r.hget("user", "name");
r.hgetall("user");

// List operations
r.lpush("queue", "item");
let item = r.rpop("queue");

// Pub/Sub
let pub = redis.connect("localhost", 6379);
pub.publish("channel", "message");

let sub = redis.connect("localhost", 6379);
sub.subscribe("channel");
let msg = sub.recv();
```

---

## Data Processing

### compress - Compression

```nyx
import compress;

// Gzip
let compressed = compress.gzip("large text data");
let decompressed = compress.gunzip(compressed);

// ZIP
let zipped = compress.zip({"file1.txt": "content1", "file2.txt": "content2"});
let unzipped = compress.unzip(zipped);

// Zlib
let deflated = compress.deflate("data");
let inflated = compress.inflate(deflated);
```

### serialization - Serialization

```nyx
import serialization;

// Pickle (Nyx object serialization)
let data = {name: "John", scores: [90, 85, 88]};
let pickled = serialization.pickle(data);
let unpickled = serialization.unpickle(pickled);

// MessagePack
let packed = serialization.pack(data);
let unpacked = serialization.unpack(packed);

// Protocol Buffers (simplified)
let encoded = serialization.protobuf_encode(data, schema);
let decoded = serialization.protobuf_decode(encoded, schema);
```

### xml - XML Processing

```nyx
import xml;

// Parse XML
let doc = xml.parse('<root><item id="1">Hello</item></root>');
let item = doc.root.children[0];
print(item.attr["id"]);  // "1"
print(item.text);         // "Hello"

// Build XML
let builder = xml.Builder.new();
builder.start("root");
builder.start("item", {id: "1"});
builder.text("Hello");
builder.end("item");
builder.end("root");
let xml_str = builder.to_string();
```

---

## Advanced Computing

### nlp - Natural Language Processing

```nyx
import nlp;

// Tokenization
let tokens = nlp.tokenize("Hello, world!");
// ["Hello", ",", "world", "!"]

// Stop words removal
let filtered = nlp.remove_stop_words(tokens);

// Stemming
let stemmed = nlp.stem("running");  // "run"

// Lemmatization
let lemmas = nlp.lemmatize(["running", "ran"]);  // ["run", "run"]

// Sentiment analysis
let sentiment = nlp.sentiment("I love this product!");  // positive

// Named Entity Recognition
let entities = nlp.ner("John works at Google in NYC");
// [{"text": "John", "type": "PERSON"}, {"text": "Google", "type": "ORG"}, {"text": "NYC", "type": "LOC"}]

// Word embeddings
let vec = nlp.embedding("king");
let similar = nlp.most_similar("king", ["queen", "man", "woman"]);
```

### visualize - Data Visualization

```nyx
import visualize;

// Line chart
let chart = visualize.line_chart();
chart.add_series([1, 2, 3, 4, 5], label: "Sales");
chart.add_series([2, 4, 6, 8, 10], label: "Revenue");
chart.set_title("Sales vs Revenue");
chart.save("chart.html");

// Bar chart
let bar = visualize.bar_chart();
bar.add_category("Q1", [100, 200]);
bar.add_category("Q2", [150, 250]);
bar.save("bar.html");

// Scatter plot
let scatter = visualize.scatter();
scatter.add_points([[1,2], [3,4], [5,6]]);
scatter.save("scatter.html");

// Histogram
let hist = visualize.histogram();
hist.add_data([1,1,2,2,2,3,3,4]);
hist.save("hist.html");

// Heatmap
let heatmap = visualize.heatmap();
heatmap.set_data([[1,2,3], [4,5,6], [7,8,9]]);
heatmap.save("heatmap.html");
```

### experiment - ML Experiment Tracking

```nyx
import experiment;

// Create experiment
let exp = experiment.start("my_experiment");
exp.log_param("learning_rate", 0.01);
exp.log_param("batch_size", 32);

// Log metrics
for epoch in range(100) {
    let train_loss = train();
    let val_loss = validate();
    
    exp.log_metric("train_loss", train_loss, step: epoch);
    exp.log_metric("val_loss", val_loss, step: exp.step);
}

// Log artifacts
exp.log_artifact("model.pt", model);
exp.log_artifact("results.csv", csv_data);

// End experiment
exp.end();
```

### mlops - MLOps Utilities

```nyx
import mlops;

// Model serving
let server = mlops.serve(model, port: 8080);
server.predict(input_data);

// Model registry
mlops.register_model("my_model", model, metrics: {accuracy: 0.95});
let loaded = mlops.load_model("my_model");

// Feature store
let fs = mlops.FeatureStore.new("my_store");
fs.write_features("user_features", user_id, features);
let features = fs.read_features("user_features", user_id);

// Model monitoring
let monitor = mlops.Monitor.new(model);
monitor.track_predictions(predictions);
let drift = monitor.detect_drift(new_data);
```

---

## GUI and Graphics

### gui - Desktop GUI

```nyx
import gui;

// Create window
let window = gui.Window.new("My App", 800, 600);

// Create widgets
let button = gui.Button.new("Click Me");
button.on_click(fn() {
    print("Button clicked!");
});

let label = gui.Label.new("Hello, Nyx!");

let input = gui.Input.new();
let text = input.text;

let checkbox = gui.Checkbox.new("Enable feature");

let slider = gui.Slider.new(0, 100, 50);

// Layout
let layout = gui.VBox.new();
layout.add(label);
layout.add(button);
layout.add(input);
layout.add(checkbox);
layout.add(slider);

window.set_layout(layout);

// Event loop
window.show();
```

### game - 2D Game Development

```nyx
import game;

// Create game
let g = game.Game.new("My Game", 800, 600);

// Create sprites
let player = game.Sprite.new("player.png");
player.set_position(100, 100);
player.set_velocity(5, 0);

// Create scene
let scene = game.Scene.new();
scene.add(player);

// Game loop
g.on_update(fn(dt) {
    player.move();
    
    if player.collides_with(enemy) {
        player.take_damage();
    }
});

g.on_draw(fn() {
    scene.render();
});

g.run();
```

---

## System and Utilities

### process - Process Management

```nyx
import process;

// Execute command
let output = process.exec("ls -la");
print(output.stdout);
print(output.stderr);
print(output.exit_code);

// Spawn process
let child = process.spawn("my_program", ["arg1", "arg2"]);
let pid = child.pid;
let output = child.wait();

// Current process
let pid = process.pid();
let args = process.args();
let env = process.env();
```

### cli - Command-Line Interface

```nyx
import cli;

// Parse arguments
let parser = cli.new_parser();
parser.add_option("-n", "--name", type: "string", required: true);
parser.add_option("-v", "--verbose", type: "bool");
parser.add_option("-p", "--port", type: "int", default: 8080);

let args = parser.parse();

// Colored output
print(cli.color("Success!", "green"));
print(cli.color("Error!", "red"));
print(cli.color("Warning!", "yellow"));

// Progress bar
let bar = cli.progress_bar(100);
for i in range(100) {
    bar.update(i);
    time.sleep(0.01);
}
```

### log - Logging

```nyx
import log;

// Configure logger
log.setup(level: "INFO", format: "[{time}] {level}: {message}");

// Log messages
log.debug("Debug message");
log.info("Info message");
log.warning("Warning message");
log.error("Error message");
log.critical("Critical message");

// With context
log.info("User action", user_id: 123, action: "login");
```

### debug - Debugging

```nyx
import debug;

// Print variable
debug.print(var);

// Breakpoint
debug.breakpoint();

// Stack trace
debug.traceback();

// Memory inspection
debug.inspect(obj);

// Timing
let duration = debug.timeit(fn() {
    expensive_operation();
});
```

### config - Configuration Management

```nyx
import config;

// Load config file
let cfg = config.load("app.json");

// Get values
let port = cfg.get("server.port", default: 8080);
let debug = cfg.get("debug.enabled", default: false);

// Nested values
let db_host = cfg.get("database.host");

// Set values
cfg.set("server.port", 9000);
cfg.set("new_key", "new_value");

// Save
cfg.save("app.json");

// Environment variables
let env_cfg = config.from_env();
let api_key = env_cfg.get("API_KEY");
```

### cache - Caching

```nyx
import cache;

// In-memory cache
let c = cache.new();
c.set("key1", "value1", ttl: 60);  // 60 second TTL
let val = c.get("key1");
c.delete("key1");

// LRU cache
let lru = cache.lru(100);  // Max 100 items
lru.set("key", "value");

// File cache
let file_cache = cache.file("./cache_dir");
file_cache.set("data", some_data);

// Redis cache
let redis_cache = cache.redis("localhost", 6379);
redis_cache.set("key", "value", ttl: 3600);
```

### io - Input/Output

```nyx
import io;

// Read from stdin
let input = io.input();
print("You entered: " + input);

// Read line
let line = io.input_line();

// File I/O (same as file module)
let f = io.file_open("test.txt", "r");
let content = f.read();
f.close();

// Binary I/O
let bin = io.file_open("data.bin", "rb");
let bytes = bin.read_bytes(1024);
bin.close();
```

---

## Additional Modules

### algorithm - Algorithms

```nyx
import algorithm;

// Sorting
let sorted = algorithm.sort([3, 1, 4, 1, 5]);
let sorted_desc = algorithm.sort_desc([3, 1, 4]);

// Searching
let index = algorithm.binary_search([1, 2, 3, 4, 5], 3);

// Shuffling
let shuffled = algorithm.shuffle([1, 2, 3, 4, 5]);

// Permutations
let perms = algorithm.permutations([1, 2, 3]);

// Combinations
let combs = algorithm.combinations([1, 2, 3, 4], 2);
```

### bench - Benchmarking

```nyx
import bench;

// Time execution
let duration = bench.timeit(fn() {
    // code to benchmark
});

// Memory usage
let mem = bench.memory_usage(fn() {
    // code
});

// Compare functions
let results = bench.compare([
    fn() { sort_fast(data) },
    fn() { sort_slow(data) }
]);
```

### class - Class Utilities

```nyx
import class_util;

// Metaclass
class MyMeta {
    static fn new_class(name, bases) {
        // Custom class creation
    }
}

// Class methods
class MyClass {
    fn instance_method(self) {}
    static fn static_method() {}
}
```

### cron - Cron Jobs

```nyx
import cron;

// Schedule job
let job = cron.schedule("0 * * * *", fn() {
    print("Hourly task");
});

// Parse cron expression
let next = cron.next_run("0 0 * * *");
print(next);
```

### distributed - Distributed Computing

```nyx
import distributed;

// Create cluster
let cluster = distributed.Cluster.new(["node1:8000", "node2:8000"]);

// Run distributed task
let result = cluster.submit_task(fn() {
    // Task code
});

// Distributed data
let ddata = cluster.distribute([1, 2, 3, 4]);
let mapped = ddata.map(fn(x) { x * 2 });
let reduced = ddata.reduce(fn(a, b) { a + b });
```

### ffi - Foreign Function Interface

```nyx
import ffi;

// Call C function
let lib = ffi.load("libc.so.6");
let puts = lib.func("puts", ffi.types.int, [ffi.types.char_ptr]);
puts("Hello from C!");
```

### formatter - Code Formatting

```nyx
import formatter;

// Format Nyx code
let formatted = formatter.format(source_code);

// Check formatting
let is_formatted = formatter.check(source_code);

// Apply formatting
let result = formatter.apply(source_code);
```

### governance - Governance

```nyx
import governance;

// Access control
let acl = governance.ACL.new();
acl.allow("user1", "read", "resource1");
acl.deny("user2", "write", "resource1");

// Rate limiting
let limiter = governance.RateLimiter.new(100, 60);  // 100 per minute

// Audit logging
governance.audit.log("user1", "read", "resource1");
```

### hub - Model Hub

```nyx
import hub;

// List models
let models = hub.list("text-classification");

// Load model
let classifier = hub.load("hf:bert-base-uncased");

// Use model
let result = classifier("I love this!");
```

### metrics - Metrics and Monitoring

```nyx
import metrics;

// Counter
let counter = metrics.counter("requests");
counter.inc();

// Gauge
let gauge = metrics.gauge("temperature");
gauge.set(25.5);

// Histogram
let histogram = metrics.histogram("request_duration");
histogram.observe(0.5);

// Export to Prometheus
let exporter = metrics.prometheusExporter();
exporter.serve(9090);
```

### monitor - System Monitoring

```nyx
import monitor;

// CPU
let cpu = monitor.cpu();
print(cpu.usage());      // Percentage
print(cpu.per_core());   // Per-core usage

// Memory
let mem = monitor.memory();
print(mem.used());
print(mem.available());
print(mem.percent());

// Disk
let disk = monitor.disk();
print(disk.usage("/"));
print(disk.io_counters());

// Network
let net = monitor.net();
print(net.io_counters());
```

### parser - Parsing

```nyx
import parser;

// JSON (same as json module)
let data = parser.json.parse('{"a": 1}');

// CSV
let rows = parser.csv.parse("a,b,c\n1,2,3");
for row in rows {
    print(row.a);
}

// INI
let config = parser.ini.parse("[section]\nkey=value");

// Custom grammar
let grammar = parser.Grammar.new();
grammar.rule("expr", "number | expr op expr");
let parsed = grammar.parse("1 + 2");
```

### precision - High Precision

```nyx
import precision;

// Decimal
let d = precision.decimal("3.14159265358979323846");
let result = d + precision.decimal("0.00000005");

// BigInt
let big = precision.bigint("12345678901234567890");
let factorial = precision.factorial(100);
```

### serving - Model Serving

```nyx
import serving;

// Create inference server
let server = serving.Server.new(model);
server.add_preprocess(fn(input) {
    return normalize(input);
});
server.add_postprocess(fn(output) {
    return softmax(output);
});
server.start(port: 8080);

// Make prediction
let result = server.predict(input_data);
```

### state_machine - State Machines

```nyx
import state_machine;

// Define state machine
let sm = state_machine.StateMachine.new("idle");

sm.add_state("idle");
sm.add_state("processing");
sm.add_state("complete");

sm.add_transition("idle", "processing", "start");
sm.add_transition("processing", "complete", "finish");
sm.add_transition("complete", "idle", "reset");

// Run
sm.start();
sm.send("start");
print(sm.current_state());  // "processing"
```

### string - String Utilities

```nyx
import string;

// Case conversion
print(string.capitalize("hello"));  // "Hello"
print(string.upper("hello"));       // "HELLO"
print(string.lower("HELLO"));       // "hello"
print(string.title("hello world")); // "Hello World"

// Padding
print(string.pad_left("5", 3, "0"));  // "005"
print(string.pad_right("hi", 5, ".")); // "hi..."

// Trimming
print(string.strip("  hello  "));   // "hello"
print(string.lstrip("  hello"));    // "hello"
print(string.rstrip("hello  "));    // "hello"

// Search
print(string.find("hello", "ll"));   // 2
print(string.rfind("hello", "l"));   // 3
print(string.contains("hello", "ll")); // true

// Split
print(string.split("a,b,c", ","));    // ["a", "b", "c"]
print(string.splitlines("a\nb\nc"));  // ["a", "b", "c"]
```

### symbolic - Symbolic Math

```nyx
import symbolic;

// Variables
let x = symbolic.var("x");
let y = symbolic.var("y");

// Expressions
let expr = x ** 2 + 2 * x + 1;

// Simplification
let simplified = symbolic.simplify(expr);

// Differentiation
let dx = symbolic.diff(expr, x);

// Evaluation
let val = expr.subs(x, 2);  // 4 + 4 + 1 = 9

// Solve equation
let solutions = symbolic.solve(x ** 2 - 4, x);  // [-2, 2]
```

### systems - Systems Programming

```nyx
import systems;

// Memory
let ptr = systems.alloc(100);
systems.free(ptr);

// Pointers
let addr = systems.address_of(variable);
let value = systems.deref(addr);

// Memory operations
systems.memcpy(dest, src, size);
systems.memset(ptr, value, size);
systems.memcmp(ptr1, ptr2, size);
```

### test - Testing Framework

```nyx
import test;

// Assertions
test.assert_eq(1 + 1, 2);
test.assert_neq(1, 2);
test.assert_true(true);
test.assert_false(false);
test.assert_null(null);
test.assert_not_null("value");
test.assert_throw(fn() { throw "error" });

// Test cases
test.describe("My Module", fn() {
    test.it("should add numbers", fn() {
        test.assert_eq(add(1, 2), 3);
    });
    
    test.it("should handle errors", fn() {
        // Test code
    });
});

// Run tests
test.run();
```

### time - Time (Advanced)

```nyx
import time;

// Timers
let timer = time.Timer.new();
timer.start();
expensive_operation();
let elapsed = timer.elapsed();

// Time zones
let utc = time.now_utc();
let local = time.now_local("America/New_York");

// Durations
let dur = time.duration(1, "hour");
let later = time.now().add(dur);
```

### train - Training Utilities

```nyx
import train;

// Data loader
let loader = train.DataLoader.new(dataset, batch_size: 32, shuffle: true);

for batch in loader {
    let x = batch.input;
    let y = batch.target;
    
    let pred = model.forward(x);
    let loss = criterion(pred, y);
    
    optimizer.zero_grad();
    loss.backward();
    optimizer.step();
}

// Checkpointing
train.checkpoint.save(model, optimizer, epoch: 10, loss: 0.5);
train.checkpoint.load("checkpoint.pt");
```

### validator - Data Validation

```nyx
import validator;

// Define schema
let schema = validator.schema({
    name: validator.string().required().min(1).max(100),
    email: validator.string().required().email(),
    age: validator.number().min(0).max(150),
    role: validator.enum(["admin", "user", "guest"]),
    metadata: validator.object({
        active: validator.boolean(),
        tags: validator.array(validator.string())
    })
});

// Validate
let result = schema.validate(data);
if !result.is_valid {
    print(result.errors);
}
```

### web - Web Utilities

```nyx
import web;

// URL parsing
let url = web.parse_url("https://example.com/path?query=value");
print(url.host);    // "example.com"
print(url.path);    // "/path"
print(url.query);   // {query: "value"}

// HTML parsing
let doc = web.parse_html('<html><body><div class="content">Hello</div></body></html>');
let div = doc.query_selector(".content");
print(div.text);  // "Hello"

// URL encoding
let encoded = web.url_encode({key: "value with spaces"});
let decoded = web.url_decode(encoded);
```

### types - Type System

```nyx
import types;

// Type checking
types.is_int(42);      // true
types.is_string("hi"); // true
types.is_array([]);    // true
types.is_object({});   // true
types.is_function(fn() {}); // true

// Type conversion
let str_type = types.type_of(value);
let is_same = types.is_same(typeof(a), typeof(b));

// Union types
let union = types.union("string", "number");
```

---

# 15. Advanced Features

## Iterators

```nyx
let numbers = [1, 2, 3, 4, 5];

// Map
let doubled = numbers.map(fn(x) { x * 2 });

// Filter
let evens = numbers.filter(fn(x) { x % 2 == 0 });

// Reduce
let sum = numbers.reduce(fn(acc, x) { acc + x }, 0);

// Chain
let result = numbers
    .filter(fn(x) { x > 2 })
    .map(fn(x) { x * 10 })
    .reduce(fn(acc, x) { acc + x }, 0);
```

## Generators

```nyx
fn range_gen(n) {
    let i = 0;
    while i < n {
        yield i;
        i += 1;
    }
}

for num in range_gen(5) {
    print(num);  // 0, 1, 2, 3, 4
}
```

## Decorators

```nyx
fn timing_decorator(fn) {
    return fn(input) {
        let start = time.now();
        let result = fn(input);
        let elapsed = time.now().sub(start);
        print("Function took " + str(elapsed) + "ms");
        return result;
    };
}

@timing_decorator
fn slow_function() {
    time.sleep(1);
}
```

## Metaprogramming

```nyx
// Macro-like code generation
fn create_adder(n) {
    return "fn add_" + str(n) + "(x) { return x + " + str(n) + "; }";
}

eval(create_adder(5));  // Creates add_5 function
print(add_5(10));  // 15
```

## Memory Management

```nyx
// Ownership
let obj1 = new MyClass();
let obj2 = obj1;  // obj1 is moved to obj2
// obj1 is now invalid

// Borrowing
fn process(ref obj) {
    // Can read and modify obj temporarily
    obj.value = 42;
}

let data = new MyData();
process(ref data);
// data is valid again after function returns
```

---

# 16. Examples and Recipes

## Web Server with Routing

```nyx
import http;

let app = http.Server.new(8080);

// Middleware
fn logger(req, next) {
    print(req.method + " " + req.path);
    return next(req);
}

app.use(logger);

// Routes
app.get("/", fn(r) { r.send("Welcome") });
app.get("/api/users", fn(r) { r.json({users: []}) });
app.post("/api/users", fn(r) { 
    let user = r.json();
    r.json({created: true, id: 1});
});

app.listen();
```

## REST API

```nyx
import http, json;

let server = http.Server.new(3000);
let users = [
    {id: 1, name: "Alice"},
    {id: 2, name: "Bob"}
];

server.get("/api/users", fn(req) {
    return req.json(users);
});

server.get("/api/users/:id", fn(req) {
    let id = int(req.params.id);
    let user = users.filter(fn(u) { u.id == id })[0];
    if user {
        return req.json(user);
    }
    return req.status(404).json({error: "Not found"});
});

server.post("/api/users", fn(req) {
    let new_user = r.json();
    new_user.id = len(users) + 1;
    users.push(new_user);
    return req.status(201).json(new_user);
});

server.listen();
```

## Database Application

```nyx
import database, json;

let db = database.connect("blog.db");

// Initialize
db.execute("CREATE TABLE IF NOT EXISTS posts (
    id INTEGER PRIMARY KEY,
    title TEXT,
    content TEXT,
    created_at TEXT
)");

// Create post
fn create_post(title, content) {
    let now = time.now().iso();
    db.execute("INSERT INTO posts (title, content, created_at) VALUES (?, ?, ?)",
        [title, content, now]);
}

// Get all posts
fn get_posts() {
    return db.query("SELECT * FROM posts ORDER BY created_at DESC");
}

// Get post by ID
fn get_post(id) {
    let rows = db.query("SELECT * FROM posts WHERE id = ?", [id]);
    return rows[0];
}

// Update post
fn update_post(id, title, content) {
    db.execute("UPDATE posts SET title = ?, content = ? WHERE id = ?",
        [title, content, id]);
}

// Delete post
fn delete_post(id) {
    db.execute("DELETE FROM posts WHERE id = ?", [id]);
}
```

## File Processing Pipeline

```nyx
import file, json, compress;

fn process_files(input_dir, output_dir) {
    let files = file.list(input_dir);
    
    for filepath in files {
        if filepath.ends_with(".json") {
            // Read
            let content = file.read(filepath);
            let data = json.parse(content);
            
            // Process
            let processed = process_data(data);
            
            // Write
            let output_path = output_dir + "/" + file.basename(filepath);
            file.write(output_path, json.stringify(processed));
            
            // Compress
            let compressed = compress.gzip(json.stringify(processed));
            file.write(output_path + ".gz", compressed);
        }
    }
}
```

## Concurrent Web Scraper

```nyx
import http, async;

fn scrape_urls(urls) {
    // Fetch all URLs concurrently
    let tasks = urls.map(fn(url) {
        return async.spawn(fn() {
            let resp = http.get(url);
            return {
                url: url,
                status: resp.status,
                content: resp.text
            };
        });
    });
    
    // Wait for all
    let results = await async.collect(tasks);
    
    // Process results
    for result in results {
        if result.status == 200 {
            print("Success: " + result.url);
        } else {
            print("Failed: " + result.url);
        }
    }
}

let urls = [
    "https://example.com",
    "https://example.org",
    "https://example.net"
];
scrape_urls(urls);
```

## Machine Learning Pipeline

```nyx
import tensor, nn, optim, dataset;

fn train_model() {
    // Load data
    let (x_train, y_train) = dataset.load_mnist("train");
    let (x_test, y_test) = dataset.load_mnist("test");
    
    // Create model
    let model = nn.Sequential([
        nn.Linear.new(784, 256),
        nn.ReLU.new(),
        nn.Dropout.new(0.2),
        nn.Linear.new(256, 128),
        nn.ReLU.new(),
        nn.Linear.new(128, 10)
    ]);
    
    // Optimizer
    let optimizer = optim.Adam.new(model.parameters(), lr: 0.001);
    let criterion = nn.CrossEntropyLoss.new();
    
    // Training loop
    for epoch in range(10) {
        let total_loss = 0;
        
        for i in range(0, len(x_train), 32) {
            let batch_x = tensor.tensor(x_train[i:i+32]);
            let batch_y = tensor.tensor(y_train[i:i+32]);
            
            // Forward
            let pred = model.forward(batch_x);
            let loss = criterion(pred, batch_y);
            
            // Backward
            optimizer.zero_grad();
            loss.backward();
            optimizer.step();
            
            total_loss += loss.data;
        }
        
        print("Epoch " + str(epoch) + ", Loss: " + str(total_loss));
    }
    
    // Evaluate
    let test_pred = model.forward(tensor.tensor(x_test));
    let accuracy = compute_accuracy(test_pred, y_test);
    print("Test Accuracy: " + str(accuracy));
    
    return model;
}

let model = train_model();
```

## GUI Application

```nyx
import gui;

let window = gui.Window.new("Todo App", 600, 400);
let todos = [];

fn render() {
    let layout = gui.VBox.new();
    
    // Title
    layout.add(gui.Label.new("My Todo List"));
    
    // Input
    let input = gui.Input.new();
    let add_btn = gui.Button.new("Add");
    
    add_btn.on_click(fn() {
        let text = input.text;
        if text != "" {
            todos.push({text: text, done: false});
            input.set_text("");
            render();
        }
    });
    
    let input_layout = gui.HBox.new();
    input_layout.add(input);
    input_layout.add(add_btn);
    layout.add(input_layout);
    
    // List
    for i, todo in todos {
        let check = gui.Checkbox.new(todo.text);
        check.on_change(fn(checked) {
            todos[i].done = checked;
        });
        
        let delete_btn = gui.Button.new("X");
        delete_btn.on_click(fn() {
            todos.splice(i, 1);
            render();
        });
        
        let item_layout = gui.HBox.new();
        item_layout.add(check);
        item_layout.add(delete_btn);
        layout.add(item_layout);
    }
    
    window.set_layout(layout);
}

render();
window.show();
```

## Real-time Chat Server

```nyx
import http, websocket;

let server = http.Server.new(8080);
let clients = [];

// WebSocket upgrade
server.get("/ws", fn(req) {
    let ws = websocket.accept(req);
    clients.push(ws);
    
    // Handle messages
    ws.on_message(fn(msg) {
        // Broadcast to all clients
        for client in clients {
            if client != ws {
                client.send(msg);
            }
        }
    });
    
    ws.on_close(fn() {
        let index = clients.index_of(ws);
        if index >= 0 {
            clients.splice(index, 1);
        }
    });
    
    return null;  // Don't send HTTP response
});

server.listen();
print("Chat server running on ws://localhost:8080/ws");
```

---

# 17. Project Structure

## Single File Project

```
my_script.ny
```

## Multi-file Project

```
my-project/
├── main.ny           # Entry point
├── lib/              # Local modules
│   ├── utils.ny
│   ├── helpers.ny
│   └── math/
│       ├── operations.ny
│       └── constants.ny
├── tests/            # Test files
│   ├── test_utils.ny
│   └── test_math.ny
├── ny.pkg           # Package manifest
└── ny.lock          # Dependency lock file
```

## Package Manifest (ny.pkg)

```json
{
    "name": "my-package",
    "version": "1.0.0",
    "description": "My Nyx package",
    "author": "Your Name",
    "license": "MIT",
    "dependencies": {
        "core": ">=1.0.0",
        "http": "^2.0.0",
        "json": ">=1.0.0"
    },
    "devDependencies": {
        "test": ">=1.0.0"
    }
}
```

---

# 18. Troubleshooting

## Common Issues

### "Command not found"
- Ensure Nyx is in your PATH
- Restart your terminal

### "Module not found"
- Check package is installed: `nypm list`
- Verify import statement spelling

### "Permission denied"
- On Linux/macOS: `chmod +x nyx`
- Check file permissions

### "Out of memory"
- Check for infinite loops
- Increase system memory

### "Stack overflow"
- Reduce recursion depth
- Use iterative approach instead

## Debug Tips

```nyx
import debug;

// Print variable value
debug.print(my_variable);

// Break into debugger
debug.breakpoint();

// Print stack trace
debug.traceback();

// Measure execution time
let start = time.now();
// ... code ...
print(time.now().sub(start));
```

## Getting Help

- GitHub Issues: github.com/suryasekhar06jemsbond-lab/cyber/issues
- Documentation: docs.nyxlang.dev
- Community: Discord server

---

# License

Copyright © 2024 Surya Sekhar Roy. All rights reserved.

---

<p align="center">
  Made with ❤️ by Surya Sekhar Roy
</p>

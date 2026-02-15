# Nyx Programming Language - Complete Guide

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

# 📖 Table of Contents

1. [What is Nyx?](#what-is-nyx)
2. [What Nyx Can Do](#what-nyx-can-do)
3. [What Nyx is Good For](#what-nyx-is-good-for)
4. [Installation](#installation)
5. [Version Verification](#version-verification)
6. [Language Basics](#language-basics)
7. [Standard Library Reference](#standard-library-reference)
8. [Running Code](#running-code)
9. [Tools & CLI Commands](#tools--cli-commands)
10. [Examples by Category](#examples-by-category)
11. [Project Structure](#project-structure)
12. [Troubleshooting](#troubleshooting)

---

# 🔰 What is Nyx?

**Nyx** is a modern, expressive, high-level programming language that runs everywhere. Written in C with a custom VM, it combines the simplicity of scripting languages with the power of systems programming.

## Key Characteristics:
- **Modern Syntax** - Clean, readable code like Python
- **High Performance** - Compiled to bytecode, runs on custom VM
- **Memory Safe** - Ownership & borrowing system (inspired by Rust)
- **Cross-Platform** - Windows, Linux, macOS
- **Rich Standard Library** - 70+ built-in modules
- **Package Manager** - Built-in nypm for dependencies

## Version Information:
- **Current Version**: 0.20.1
- **License**: Proprietary
- **Author**: Surya Sekhar Roy
- **Repository**: github.com/suryasekhar06jemsbond-lab/cyber

---

# 🚀 What Nyx Can Do

Nyx is a general-purpose language suitable for virtually any programming task:

| Category | Capabilities |
|----------|-------------|
| **Web Development** | HTTP servers, REST APIs, WebSocket, routing, middleware |
| **Machine Learning** | Tensor operations, neural networks, autograd, optimizers |
| **Data Science** | Collections, algorithms, FFT, linear algebra, statistics |
 Programming** | Low| **Systems-level memory control, FFI, native performance |
| ** Automation, fileScripting** | processing, system tasks |
| **Game Development** | 2D graphics, game loops, sprite rendering |
| **CLI Applications** | Command-line tools, argument parsing, colored output |
| **Cryptography** | Hashing, encryption, JWT, digital signatures, AES/RSA |
| **Networking** | TCP/UDP sockets, HTTP client/server, WebSocket |
| **Database** | SQL support, NoSQL, Redis integration |
| **Parallel Computing** | Async/await, parallel execution, distributed computing |
| **NLP** | Text processing, tokenization, language models |
| **Visualization** | Charts, graphs, data plotting |
| **GUI** | Desktop GUI applications, window management |

---

# ⭐ What Nyx is Good For

## 1. Rapid Development
Clean, concise syntax lets you build applications faster with less boilerplate.

```nyx
// Quick HTTP server in 5 lines
import http;
let server = http.Server.new(8080);
server.get("/", fn(r) { return r.send("Hello!"); });
server.listen();
```

## 2. Machine Learning & AI
Built-in tensor operations and neural network modules make ML development straightforward.

```nyx
import tensor, nn, autograd;
// Create neural network layers, perform backpropagation
```

## 3. Cross-Platform Development
Write once, run anywhere - same code works on Windows, Linux, macOS.

## 4. Educational Use
Simple enough for beginners to learn programming, powerful enough for experts.

## 5. Enterprise Applications
Robust error handling, testing frameworks, and mature tooling for production use.

## 6. Research & Experiments
Easy prototyping with extensive standard library and package ecosystem.

---

# 💾 Installation

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
code --install-extension nyx-language-0.20.1.vsix
```

## Option 3: Standalone Runtime

```powershell
# Windows - Download and run
curl -L -o nyx.exe "https://github.com/suryasekhar06jemsbond-lab/cyber/releases/download/v0.20.1/nyx.exe"
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

---

# ✅ Version Verification

## Check Nyx Runtime Version

```powershell
# Terminal command
nyx --version

# Output: 0.20.1
```

## Check Version in Code

```nyx
// Get runtime version string
print(lang_version());
// Output: "0.20.1"

// Require specific version
require_version(">=0.20.0");

// Version constraints
require_version("^0.20.0");   // Compatible with 0.20.x
require_version("~0.20.0");    // Exactly 0.20.x  
require_version(">=0.20.0");   // 0.20.0 or higher
require_version("0.20.0");     // Exactly 0.20.0
```

## Check Extension Version

- Open VS Code Extensions panel
- Look for "Nyx Language" entry
- Version displayed in the extension info

---

# 📚 Language Basics

## Hello World

```nyx
print("Hello, Nyx!");
```

## Variables

```nyx
// Immutable variables (default)
let name = "Nyx";
let age = 25;
let is_awesome = true;

// Mutable variables
mut count = 0;
count = count + 1;

// Type annotations
let num: int = 42;
let text: string = "Hello";
let flag: bool = true;
```

## Data Types

```nyx
// Numbers
let integer = 42;
let float = 3.14;
let hex = 0xFF;
let binary = 0b1010;
let octal = 0o755;

// Strings
let s1 = "Hello";
let s2 = 'World';
let s3 = `Template string: ${s1}`;

// Arrays
let arr = [1, 2, 3, 4, 5];
let empty = [];

// Objects/Dictionaries
let obj = {
    name: "John",
    age: 30,
    city: "NYC"
};

// Null
let nothing = null;
```

## Operators

```nyx
// Arithmetic
let sum = 10 + 5;      // 15
let diff = 10 - 5;      // 5
let prod = 10 * 5;      // 50
let quot = 10 / 5;      // 2
let mod = 10 % 3;       // 1
let pow = 2 ** 8;       // 256

// Comparison
let eq = 5 == 5;        // true
let neq = 5 != 3;       // true
let lt = 3 < 5;         // true
let gt = 5 > 3;         // true
let lte = 3 <= 5;        // true
let gte = 5 >= 5;       // true

// Logical
let and_result = true && false;   // false
let or_result = true || false;    // true
let not_result = !true;            // false

// Null coalescing
let value = null ?? "default";    // "default"

// Null-aware access
let name = user?.name ?? "Anonymous";
```

## Control Flow

```nyx
// If-else
if age >= 18 {
    print("Adult");
} else if age >= 13 {
    print("Teen");
} else {
    print("Child");
}

// Ternary
let status = age >= 18 ? "Adult" : "Minor";

// While loop
let i = 0;
while i < 5 {
    print(i);
    i = i + 1;
}

// For loop (array iteration)
for num in [1, 2, 3, 4, 5] {
    print(num);
}

// For loop (with index)
for i, num in numbers {
    print("${i}: ${num}");
}

// For range
for i in range(10) {
    print(i);  // 0-9
}

// Switch/match
let day = "Monday";
switch day {
    case "Saturday", "Sunday" {
        print("Weekend!");
    }
    case "Monday" {
        print("Start of week");
    }
    default {
        print("Weekday");
    }
}

// Match expression
let result = match value {
    1 => "one",
    2 => "two",
    _ => "other"
};
```

## Functions

```nyx
// Basic function
fn greet(name) {
    return "Hello, " + name + "!";
}

// Multiple parameters
fn add(a, b) {
    return a + b;
}

// Default parameters
fn greet(name, greeting = "Hello") {
    return greeting + ", " + name + "!";
}

// Variadic
fn sum_all(*numbers) {
    let total = 0;
    for n in numbers {
        total = total + n;
    }
    return total;
}

// Lambda/Anonymous
let double = fn(x) { return x * 2; };
let add_ten = fn(x) { x + 10 };

// Higher-order functions
fn apply(fn, value) {
    return fn(value);
}

let result = apply(fn(x) { return x * 2; }, 5);  // 10

// Closure
fn counter() {
    let count = 0;
    return fn() {
        count = count + 1;
        return count;
    };
}
let c = counter();
print(c());  // 1
print(c());  // 2
```

## Classes

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
    
    // Static method
    static fn create(name) {
        return new Person(name, 0);
    }
}

let john = new Person("John", 30);
print(john.introduce());

// Inheritance
class Employee < Person {
    fn init(self, name, age, role) {
        super.init(name, age);
        self.role = role;
    }
    
    fn introduce(self) {
        return super.introduce() + " I work as " + self.role;
    }
}
```

## Modules

```nyx
// math.ny - Module file
module Math {
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

// Using module
import Math;
print(Math.square(5));     // 25
print(Math.PI);            // 3.14159
print(Math.factorial(5));  // 120

// Alias import
import math as m;
print(m.square(4));

// Selective import
import Math.{square, cube};

// Built-in modules
import tensor;
import nn;
import http;
import json;
```

## Error Handling

```nyx
// Try-catch
try {
    let result = risky_operation();
    print("Success: " + str(result));
} catch error {
    print("Error: " + str(error));
}

// Try-catch with specific types
try {
    parse_data(input);
} catch ParseError as e {
    print("Parse error: " + str(e));
} catch NetworkError as e {
    print("Network error: " + str(e));
} catch error {
    print("Unknown error: " + str(error));
}

// Throw custom errors
fn divide(a, b) {
    if b == 0 {
        throw "Cannot divide by zero!";
    }
    return a / b;
}

// Finally block
try {
    let file = open("data.txt");
    // process file
} catch error {
    print("Error: " + str(error));
} finally {
    // cleanup code
}
```

## Array Comprehensions

```nyx
let numbers = [1, 2, 3, 4, 5];

// Map
let doubled = [x * 2 for x in numbers];

// Filter
let filtered = [x for x in numbers if x > 2];

// Map + Filter
let result = [x * 2 for x in numbers if x % 2 == 0];

// Nested
let matrix = [[i * j for j in range(5)] for i in range(5)];

// Dictionary comprehension
let squares = {x: x*x for x in range(10)};
```

---

# 📦 Standard Library Reference

Nyx includes 70+ built-in modules. Here's how to use each one:

## 🚂 Tensor & Math

### tensor - Tensor Operations
```nyx
import tensor;

// Create tensors
let t1 = tensor.zeros([3, 3]);
let t2 = tensor.ones([2, 2]);
let t3 = tensor.randn([4, 4]);  // Random normal
let t4 = tensor.arange(10);      // 0 to 9

// Operations
let sum = tensor.sum(t1);
let mean = tensor.mean(t1);
let max_val = tensor.max(t1);
let min_val = tensor.min(t1);

// Matrix operations
let result = tensor.matmul(t1, t2);
let transposed = tensor.transpose(t1);
let inverted = tensor.inverse(t2);

// Reshape
let reshaped = tensor.reshape(t1, [9, 1]);

// Concatenate
let combined = tensor.concat(t1, t2, axis: 0);

// Slicing
let slice = tensor.slice(t1, [0, 0], [2, 2]);

// Save/Load
tensor.save(t1, "tensor.npy");
let loaded = tensor.load("tensor.npy");
```
**Run**: `nyx script.ny`

### math - Mathematical Functions
```nyx
import math;

// Constants
print(math.PI);   // 3.14159...
print(math.E);     // 2.71828...

// Basic functions
print(math.abs(-5));      // 5
print(math.floor(3.7));   // 3
print(math.ceil(3.2));    // 4
print(math.round(3.5));   // 4

// Trigonometry
print(math.sin(math.PI / 2));  // 1
print(math.cos(0));             // 1
print(math.tan(math.PI / 4));   // ~1

// Power & roots
print(math.sqrt(16));    // 4
print(math.pow(2, 8));   // 256
print(math.exp(1));      // ~2.718

// Logarithms
print(math.log(math.E));     // 1
print(math.log10(100));      // 2
print(math.log2(8));         // 3

// Special functions
print(math.gamma(5));    // 24
print(math.factorial(5)); // 120
```

### fft - Fast Fourier Transform
```nyx
import fft;

// Compute FFT
let signal = [1, 2, 3, 4];
let transformed = fft.fft(signal);

// Inverse FFT
let restored = fft.ifft(transformed);

// Power spectrum
let spectrum = fft.power(signal);

// 2D FFT
let image = tensor.randn([64, 64]);
let freq = fft.fft2d(image);
```

### blas - Linear Algebra
```nyx
import blas;

// Matrix operations (optimized)
let a = tensor.randn([100, 100]);
let b = tensor.randn([100, 100]);
let c = blas.gemm(a, b);  // Matrix multiply

// Vector operations
let x = tensor.randn([100]);
let y = tensor.randn([100]);
let dot = blas.dot(x, y);

// Norms
let norm2 = blas.norm(x);
let norm1 = blas.norm(x, 1);
```

### autograd - Automatic Differentiation
```nyx
import autograd;

// Create variables
let x = autograd.variable(2.0);
let y = autograd.variable(3.0);

// Define computation
let z = x * y + x;

// Backward pass
z.backward();

// Get gradients
print(x.grad);  // dy/dx = y = 3
print(y.grad);  // dy/dy = x = 2
```

---

## 🧠 Neural Networks

### nn - Neural Network Modules
```nyx
import nn, tensor;

// Create layers
let linear = nn.Linear.new(784, 128);
let conv2d = nn.Conv2d.new(1, 32, kernel_size: 3);
let relu = nn.ReLU.new();
let sigmoid = nn.Sigmoid.new();
let tanh = nn.Tanh.new();
let softmax = nn.Softmax.new(10);

// Create network
class Network {
    fn init(self) {
        self.fc1 = nn.Linear.new(784, 256);
        self.fc2 = nn.Linear.new(256, 128);
        self.fc3 = nn.Linear.new(128, 10);
        self.relu = nn.ReLU.new();
    }
    
    fn forward(self, x) {
        x = self.relu.forward(self.fc1.forward(x));
        x = self.relu.forward(self.fc2.forward(x));
        x = self.fc3.forward(x);
        return x;
    }
}

// Forward pass
let net = Network.new();
let input = tensor.randn([32, 784]);
let output = net.forward(input);
print(tensor.shape(output));  // [32, 10]
```

### optimize - Optimizers
```nyx
import optimize, autograd, tensor;

// Create optimizer
let params = [
    autograd.variable(tensor.randn([10, 10])),
    autograd.variable(tensor.randn([10]))
];
let optimizer = optimize.Adam.new(params, lr: 0.001);

// Training loop
for epoch in range(100) {
    let loss = train_step(params);
    loss.backward();
    optimizer.step();
    optimizer.zero_grad();
}

// Other optimizers
let sgd = optimize.SGD.new(params, lr: 0.01, momentum: 0.9);
let rmsprop = optimize.RMSprop.new(params, lr: 0.01);
let adagrad = optimize.Adagrad.new(params);
```

### train - Training Utilities
```nyx
import train, tensor, nn;

// Create data loader
let train_data = train.DataLoader.new(
    tensor.randn([1000, 784]),
    tensor.randint(10, [1000]),
    batch_size: 32,
    shuffle: true
);

// Training loop
for epoch in range(10) {
    for batch in train_data {
        let input = batch[0];
        let target = batch[1];
        // train step
    }
}

// Checkpointing
train.save_checkpoint("model.pt", model, optimizer, epoch);
train.load_checkpoint("model.pt", model, optimizer);
```

---

## 📊 Data Structures & Algorithms

### collections - Collections & Data Structures
```nyx
import collections;

// LinkedList
let list = collections.LinkedList.new();
list.push_back(1);
list.push_back(2);
list.push_front(0);
for val in list {
    print(val);
}

// Binary Search Tree
let bst = collections.BST.new();
bst.insert(5);
bst.insert(3);
bst.insert(7);
print(bst.search(5));
print(bst.inorder());

// AVL Tree (self-balancing)
let avl = collections.AVL.new();
avl.insert(10);
avl.insert(20);
avl.insert(30);

// Red-Black Tree
let rbtree = collections.RedBlackTree.new();
rbtree.insert(1);
rbtree.insert(5);
rbtree.insert(10);

// Heap
let minheap = collections.MinHeap.new();
minheap.push(5);
minheap.push(1);
minheap.push(3);
print(minheap.pop());  // 1

let maxheap = collections.MaxHeap.new();

// Graph
let graph = collections.Graph.new();
graph.add_edge("A", "B", 1.0);
graph.add_edge("B", "C", 2.0);
let path = graph.dijkstra("A", "C");

// Trie
let trie = collections.Trie.new();
trie.insert("hello");
trie.insert("world");
print(trie.search("hello"));
print(trie.starts_with("he"));

// HashMap
let map = collections.HashMap.new();
map.set("key", "value");
print(map.get("key"));
```

### algorithm - Algorithms
```nyx
import algorithm, collections;

// Sorting
let arr = [5, 2, 8, 1, 9];
algorithm.quicksort(arr);
algorithm.merge_sort(arr);
algorithm.heap_sort(arr);

// Searching
let sorted = [1, 2, 3, 4, 5];
print(algorithm.binary_search(sorted, 3));  // 2

// Shuffling
algorithm.shuffle(arr);

// Set operations
let a = [1, 2, 3];
let b = [2, 3, 4];
let union = algorithm.union(a, b);
let intersection = algorithm.intersection(a, b);
let difference = algorithm.difference(a, b);
```

### heap - Priority Queue
```nyx
import heap;

// Min Heap
let min_h = heap.MinHeap.new();
min_h.push(5);
min_h.push(1);
min_h.push(3);
print(min_h.pop());  // 1
print(min_h.peek()); // 3

// Max Heap
let max_h = heap.MaxHeap.new();
max_h.push(1);
max_h.push(5);
max_h.push(3);
print(max_h.pop());  // 5
```

---

## 🌐 Web & Network

### http - HTTP Server & Client
```nyx
import http;

// HTTP Server
let server = http.Server.new(8080);

// GET request
server.get("/", fn(req) {
    return http.Response.ok("Hello World!");
});

server.get("/api/users", fn(req) {
    let users = [{"name": "John"}, {"name": "Jane"}];
    return http.Response.json(users);
});

// POST request
server.post("/api/data", fn(req) {
    let body = req.body;
    // process data
    return http.Response.created({"status": "ok"});
});

// With middleware
server.use(fn(req, next) {
    print("Request: " + req.path);
    return next(req);
});

// Start server
server.listen();

// HTTP Client
let response = http.get("https://api.github.com");
print(response.status);       // 200
print(response.body);         // JSON response
print(response.headers);      // Headers

// POST request
let post_response = http.post("https://api.example.com/data", 
    body: '{"name": "Nyx"}',
    headers: {"Content-Type": "application/json"}
);
```

### socket - TCP/UDP Sockets
```nyx
import socket;

// TCP Server
let server = socket.TCP.new();
server.bind("127.0.0.1", 8080);
server.listen();

let client = server.accept();
client.send("Welcome!");
let msg = client.recv();
client.close();

// TCP Client
let client = socket.TCP.new();
client.connect("127.0.0.1", 8080);
client.send("Hello");
let response = client.recv();

// UDP
let udp = socket.UDP.new();
udp.bind(8081);
udp.send("127.0.0.1", 8080, "Message");
let (data, addr) = udp.recv();
```

### web - Web Utilities
```nyx
import web;

// URL parsing
let url = web.parse_url("https://user:pass@example.com:8080/path?query=1#anchor");
print(url.scheme);   // https
print(url.host);     // example.com
print(url.port);     // 8080
print(url.path);     // /path
print(url.query);    // query=1

// Query string
let qs = web.parse_qs("name=John&age=30");
print(qs["name"]);   // John

// HTML parsing
let html = "<div><p>Hello</p></div>";
let doc = web.parse_html(html);
let text = doc.text();
```

---

## 🔐 Cryptography

### crypto - Cryptographic Functions
```nyx
import crypto;

// Hashing
let sha256 = crypto.sha256("Hello World");
let sha512 = crypto.sha512("Hello");
let md5 = crypto.md5("Hello");
let blake2b = crypto.blake2b("Data");

// Encryption
let key = crypto.generate_key("AES-256");
let encrypted = crypto.encrypt("Secret message", key);
let decrypted = crypto.decrypt(encrypted, key);

// RSA
let (pub, priv) = crypto.rsa_generate(2048);
let ciphertext = crypto.rsa_encrypt("Message", pub);
let plaintext = crypto.rsa_decrypt(ciphertext, priv);

// Digital signature
let signature = crypto.sign(data, private_key);
let valid = crypto.verify(data, signature, public_key);
```

### jwt - JSON Web Tokens
```nyx
import jwt;

// Create token
let payload = {
    "sub": "user123",
    "name": "John Doe",
    "iat": 1516239022
};
let secret = "my-secret-key";
let token = jwt.encode(payload, secret);

// Verify token
let decoded = jwt.decode(token, secret);
print(decoded["sub"]);  // user123

// With expiration
let exp_payload = jwt.encode(payload, secret, expires_in: "1h");
let verified = jwt.verify(exp_payload, secret);
```

### hashing - Password Hashing
```nyx
import hashing;

// Hash password
let hash = hashing.hash("mypassword");
let verify = hashing.verify("mypassword", hash);

// Different algorithms
let bcrypt_hash = hashing.bcrypt("password", cost: 10);
let argon2_hash = hashing.argon2("password");

// Verify
print(hashing.verify("mypassword", bcrypt_hash));  // true
```

---

## 💾 Database

### database - SQL Database
```nyx
import database;

// Connect to SQLite
let db = database.connect("mydb.sqlite");

// Create table
db.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT)");

// Insert
db.execute("INSERT INTO users (name, email) VALUES (?, ?)", ["John", "john@example.com"]);

// Query
let rows = db.query("SELECT * FROM users WHERE name = ?", ["John"]);
for row in rows {
    print(row["name"]);
}

// Prepared statements
let stmt = db.prepare("SELECT * FROM users WHERE id = ?");
let user = stmt.fetch(1);
```

### redis - Redis Client
```nyx
import redis;

// Connect
let client = redis.connect("localhost", 6379);

// Strings
client.set("key", "value");
let val = client.get("key");
client.incr("counter");
client.decr("counter");

// Lists
client.lpush("mylist", "item1");
client.rpush("mylist", "item2");
let items = client.lrange("mylist", 0, -1);

// Hashes
client.hset("user:1", "name", "John");
client.hset("user:1", "age", "30");
let user = client.hgetall("user:1");

// Pub/Sub
let pubsub = client.subscribe("news");
pubsub.on("message", fn(channel, msg) {
    print(msg);
});
client.publish("news", "Breaking news!");
```

---

## 📊 Data Processing

### json - JSON Processing
```nyx
import json;

// Parse JSON
let data = json.parse('{"name": "Nyx", "version": "1.0"}');
print(data["name"]);  // Nyx

// Stringify
let str = json.stringify(data);

// Pretty print
let pretty = json.stringify(data, indent: 2);

// Validate
let valid = json.validate(json_str);
```

### xml - XML Processing
```nyx
import xml;

// Parse XML
let doc = xml.parse('<root><item>Hello</item></root>');
let text = doc.find("item").text();

// Create XML
let builder = xml.Builder.new();
builder.start("root");
builder.element("item", "Value");
builder.end();
let xml_str = builder.to_string();

// Transform
let transformed = xml.xslt_transform(doc, stylesheet);
```

### compression - Data Compression
```nyx
import compress;

// Compress
let data = "Hello World!";
let compressed = compress.gzip(data);
let deflated = compress.deflate(data);

// Decompress
let decompressed = compress.gunzip(compressed);
let inflated = compress.inflate(deflated);

// Zip files
compress.zip(["file1.txt", "file2.txt"], "archive.zip");
let files = compress.unzip("archive.zip");
```

---

## 🧪 Testing

### test - Testing Framework
```nyx
import test;

// Basic tests
test.describe("Math functions", fn() {
    test.it("should add correctly", fn() {
        test.assert_eq(add(2, 3), 5);
    });
    
    test.it("should multiply correctly", fn() {
        test.assert_eq(multiply(3, 4), 12);
    });
});

// Assertions
test.assert(true);
test.assert_eq(actual, expected);
test.assert_ne(a, b);
test.assert_gt(5, 3);
test.assert_lt(3, 5);
test.assert_in("needle", "haystack");
test.assert_contains([1,2,3], 2);

// Run tests
test.run();

// With coverage
test.run_coverage();
```

---

## 🛠️ Tools & CLI Commands

## Core Commands

```powershell
# Run a Nyx file
nyx main.ny

# Run with arguments
nyx script.ny arg1 arg2

# Check version
nyx --version

# Parse only (syntax check)
nyx --parse-only file.ny

# Lint file
nyx --lint file.ny

# Run with VM
nyx --vm file.ny

# Debug mode
nyx --debug file.ny

# Trace execution
nyx --trace file.ny

# Max steps limit
nyx --max-steps 10000 file.ny

# Max call depth
nyx --max-call-depth 1000 file.ny
```

## Code Formatting (nyfmt)

```powershell
# Format file
nyfmt file.ny

# Check formatting (no changes)
nyfmt --check file.ny

# Format directory
nyfmt ./src/

# Custom indent
nyfmt --indent 4 file.ny
```

## Linting (nylint)

```powershell
# Lint file
nylint file.ny

# Strict mode
nylint --strict file.ny

# Output format
nylint --format json file.ny

# Lint directory
nylint ./src/
```

## Package Manager (nypm)

```powershell
# Initialize project
nypm init my-project

# Add dependency
nypm add tensor ./local-tensor

# Install dependencies
nypm install

# List dependencies
nypm list

# Remove dependency
nypm remove mylib

# Publish package
nypm publish mypkg 1.0.0 ./mypkg

# Search registry
nypm search tensor
```

## Debugger (nydbg)

```powershell
# Debug file
nydbg file.ny

# Breakpoints
nydbg --break 10,20 file.ny

# Step through
nydbg --step file.ny

# Watch variables
nydbg --watch "count,x,y" file.ny

# Conditional breakpoints
nydbg --break 15 --condition "i > 10" file.ny
```

---

# 💻 Examples by Category

## Web Server
```nyx
import http;

let server = http.Server.new(8080);

server.get("/", fn(req) {
    return http.Response.html("<h1>Welcome to Nyx!</h1>");
});

server.get("/api/data", fn(req) {
    return http.Response.json({
        status: "ok",
        data: [1, 2, 3, 4, 5]
    });
});

server.post("/api/submit", fn(req) {
    let body = json.parse(req.body);
    return http.Response.json({received: body});
});

server.listen();
print("Server running on http://localhost:8080");
```
**Run**: `nyx server.ny`

## Machine Learning
```nyx
import tensor, nn, autograd, optimize;

// Create simple neural network
let w1 = autograd.variable(tensor.randn([2, 4]));
let b1 = autograd.variable(tensor.zeros([4]));
let w2 = autograd.variable(tensor.randn([4, 1]));
let b2 = autograd.variable(tensor.zeros([1]));

let optimizer = optimize.SGD.new([w1, b1, w2, b2], lr: 0.1);

// Training data
let X = tensor.array([[0,0], [0,1], [1,0], [1,1]]);
let y = tensor.array([[0], [1], [1], [0]]);  // XOR

// Train
for epoch in range(1000) {
    // Forward
    let h = tensor.matmul(X, w1.value) + b1.value;
    let h_relu = tensor.relu(h);
    let pred = tensor.matmul(h_relu, w2.value) + b2.value;
    
    // Loss
    let loss = tensor.mean(tensor.pow(tensor.sub(pred, y), 2));
    
    // Backward
    loss.backward();
    optimizer.step();
    optimizer.zero_grad();
    
    if epoch % 100 == 0 {
        print("Epoch " + str(epoch) + " Loss: " + str(loss.value));
    }
}
```
**Run**: `nyx ml_example.ny`

## File Processing
```nyx
import io, json, csv;

// Read file
let content = io.read_file("data.txt");
print(content);

// Write file
io.write_file("output.txt", "Hello, Nyx!");

// Read lines
let lines = io.read_lines("file.txt");
for line in lines {
    print(line);
}

// JSON
let data = json.parse(io.read_file("data.json"));
io.write_file("output.json", json.stringify(data));

// CSV
let rows = csv.read("data.csv");
for row in rows {
    print(row);
}
csv.write("output.csv", [["Name", "Age"], ["John", "30"]]);
```
**Run**: `nyx process.ny`

## Cryptography
```nyx
import crypto, jwt;

// Hash a password
let password = "securePassword123";
let hash = crypto.sha256(password);
print("Hash: " + hash);

// Generate key and encrypt
let key = crypto.generate_key("AES-256");
let secret = "Very secret message";
let encrypted = crypto.encrypt(secret, key);
let decrypted = crypto.decrypt(encrypted, key);
print("Decrypted: " + decrypted);

// JWT
let payload = {"user_id": 123, "role": "admin"};
let token = jwt.encode(payload, "secret-key");
print("Token: " + token);
let decoded = jwt.verify(token, "secret-key");
print("User: " + str(decoded["user_id"]));
```
**Run**: `nyx crypto_example.ny`

---

# 📁 Project Structure

A typical Nyx project:

```
my-project/
├── main.ny              # Entry point
├── nyx.mod              # Module definition
├── ny.lock              # Dependency lock file
├── .cydeps/             # Downloaded dependencies
│   └── tensor/
├── src/
│   ├── utils.ny         # Utility functions
│   ├── models/
│   │   └── model.ny
│   └── lib/
│       └── helpers.ny
├── tests/
│   ├── test_main.ny
│   └── test_utils.ny
├── examples/
│   └── example.ny
├── scripts/
│   └── build.ny
├── docs/
│   └── README.md
└── config.ny            # Configuration
```

### Module Definition (nyx.mod)
```nyx
module "my-project" {
    version "1.0.0"
    description "My awesome Nyx project"
    author "Your Name"
    license "MIT"
    dependencies {
        tensor ">=1.0.0"
        http ">=2.0.0"
    }
}
```

---

# 🐛 Troubleshooting

## Common Issues

### "nyx is not recognized"
```powershell
# Windows - Install globally
irm https://raw.githubusercontent.com/suryasekhar06jemsbond-lab/cyber/main/scripts/install.ps1 | iex

# Linux/macOS
curl -fsSL https://raw.githubusercontent.com/suryasekhar06jemsbond-lab/cyber/main/scripts/install.sh | sh

# Restart terminal
```

### Extension not loading
1. Check logs: `Help → Toggle Developer Tools → Console`
2. Try reinstalling: `Extensions → Uninstall → Reinstall`
3. Check file associations: `.ny` and `.nx` files

### Build errors
```powershell
# Ensure C compiler is installed
# Windows: Visual Studio Build Tools, MinGW, or LLVM
# Linux: gcc or clang
```

### Memory errors
```powershell
# Increase allocation
nyx --max-alloc 1073741824 file.ny  # 1GB
```

---

# 📄 License

Copyright (c) 2026 Surya Sekhar Roy
All Rights Reserved

---

<p align="center">
  <sub>Built with ❤️ by the Nyx Team</sub>
</p>

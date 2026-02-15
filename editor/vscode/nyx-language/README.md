# Nyx Language - VS Code Extension

<p align="center">
  <img src="nyx-logo.png" alt="Nyx Logo" width="128" height="128"/>
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
</p>

Nyx is a modern, expressive programming language that runs everywhere. This extension provides full IDE support for Nyx in Visual Studio Code.

## ✨ Features

### 🚀 Getting Started
- **Quick Installation**: Install from VS Code Marketplace or download the `.vsix` file
- **Global CLI**: After one-time setup, use `nyx` from any terminal
- **Built-in Runtime**: The extension includes the Nyx runtime for immediate use

### 🛠️ IDE Features
- **Syntax Highlighting**: Full support for `.ny` and `.nx` file extensions
- **Code Snippets**: Common patterns and templates
- **File Icons**: Custom icons for Nyx files in Explorer
- **Integrated Terminal**: Run Nyx files directly from VS Code

### 📦 Nyx Package Manager (nypm)
- Initialize new projects
- Install and manage dependencies
- Publish packages to registries
- Version management

### 🧪 Testing & Development
- Run individual files or entire projects
- Debug support with breakpoints
- Test coverage reporting
- Benchmarking tools

## 📖 Language Overview

Nyx is a concise, expressive language designed for:

```nyx
// Hello World
print("Hello, Nyx!");

// Variables
let name = "World";
let greeting = "Hello, " + name + "!";

// Functions
fn add(a, b) {
    return a + b;
}

// Classes
class Greeter {
    fn init(self, name) {
        self.name = name;
    }
    
    fn greet(self) {
        return "Hello, " + self.name + "!";
    }
}

let g = new Greeter("Nyx");
print(g.greet());

// Arrays and iteration
let numbers = [1, 2, 3, 4, 5];
for num in numbers {
    print(num * 2);
}

// Array comprehensions
let doubled = [x * 2 for x in numbers if x > 2];
```

## 🔧 Installation

### Option 1: VS Code Marketplace (Recommended)
1. Open VS Code
2. Go to Extensions (`Ctrl+Shift+X`)
3. Search for "Nyx Language"
4. Click Install

### Option 2: Manual Installation (VSIX)
1. Download the `nyx-language-X.X.X.vsix` file
2. In VS Code: `Extensions → ⋮ → Install from VSIX...`
3. Select the downloaded file

### Option 3: Command Line
```powershell
# Windows
code --install-extension nyx-language.vsix

# Linux
code --install-extension nyx-language.vsix
```

## ⚡ Quick Start

### 1. Create a New Project
```powershell
# Using VS Code command palette
# Press Ctrl+Shift+P and type "Nyx: Create Project"

# Or using terminal
nyx init my-project
cd my-project
```

### 2. Write Your First Nyx Code

Create `main.ny`:
```nyx
// main.ny - My first Nyx program
print("Welcome to Nyx!");

let numbers = [1, 2, 3, 4, 5];
let sum = 0;

for n in numbers {
    sum = sum + n;
}

print("Sum: " + str(sum));
```

### 3. Run Your Code

**From VS Code:**
- Press `F1` → Type "Nyx: Run File" → Press Enter
- Or right-click → "Run Nyx File"

**From Terminal:**
```powershell
# After global installation
nyx main.ny

# Or use the wrapper in project
.\nyx.bat main.ny
```

## 📚 Language Syntax

### Variables and Types

```nyx
// Integer
let age = 25;

// String
let name = "Nyx";
let message = "Hello, " + "World!";

// Boolean
let isAwesome = true;

// Array
let numbers = [1, 2, 3, 4, 5];

// Object
let person = {
    name: "John",
    age: 30
};

// Null
let nothing = null;
```

### Operators

```nyx
// Arithmetic
let sum = 10 + 5;      // 15
let diff = 10 - 5;     // 5
let prod = 10 * 5;     // 50
let quot = 10 / 5;     // 2
let mod = 10 % 3;      // 1

// Comparison
let eq = 5 == 5;       // true
let neq = 5 != 3;      // true
let lt = 3 < 5;        // true
let gt = 5 > 3;        // true
let lte = 3 <= 5;      // true
let gte = 5 >= 5;      // true

// Logical
let and = true && false;  // false
let or = true || false;   // true
let not = !true;          // false

// Null coalescing
let value = null ?? "default";  // "default"
```

### Control Flow

```nyx
// If-else
if age >= 18 {
    print("Adult");
} else if age >= 13 {
    print("Teen");
} else {
    print("Child");
}

// While loop
let i = 0;
while i < 5 {
    print(i);
    i = i + 1;
}

// For loop (array)
for num in numbers {
    print(num);
}

// For loop (with index)
for i, num in numbers {
    print(str(i) + ": " + str(num));
}

// Switch
let day = "Monday";
switch day {
    case "Saturday", "Sunday" {
        print("Weekend!");
    }
    default {
        print("Weekday");
    }
}
```

### Functions

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

// Higher-order functions
fn apply(fn, value) {
    return fn(value);
}

let result = apply(fn(x) { return x * 2; }, 5);  // 10
```

### Classes

```nyx
class Person {
    fn init(self, name, age) {
        self.name = name;
        self.age = age;
    }
    
    fn introduce(self) {
        return "I'm " + self.name + ", " + str(self.age) + " years old";
    }
}

let john = new Person("John", 30);
print(john.introduce());
```

### Modules

```nyx
// math.ny - Module file
module Math {
    fn square(x) {
        return x * x;
    }
    
    fn cube(x) {
        return x * x * x;
    }
}

// Using module
import Math;
print(Math.square(5));  // 25
```

### Error Handling

```nyx
// Try-catch
try {
    let result = riskyOperation();
    print(result);
} catch error {
    print("Error: " + error);
}

// Throw custom errors
fn divide(a, b) {
    if b == 0 {
        throw "Cannot divide by zero!";
    }
    return a / b;
}
```

## 💻 Command Reference

### VS Code Commands (Ctrl+Shift+P)

| Command | Description |
|---------|-------------|
| `Nyx: Run File` | Run the current .ny/.nx file |
| `Nyx: Create Project` | Create a new Nyx project |
| `Nyx: Initialize Module` | Create a nyx.mod file |
| `Nyx: Install Package` | Install a Nyx package |
| `Nyx: Build Package` | Build the current project |
| `Nyx: Test Package` | Run tests |
| `Nyx: Lint Workspace` | Check for issues |
| `Nyx: Format Code` | Format the code |
| `Nyx: Benchmark File` | Run benchmarks |

### Terminal Commands

After global installation:

```powershell
# Run a Nyx file
nyx main.ny

# Run with arguments
nyx script.ny arg1 arg2

# Version info
nyx --version

# Parse only (syntax check)
nyx --parse-only file.ny

# Lint file
nyx --lint file.ny

# Run with VM
nyx --vm file.ny

# Debug mode
nyx --debug file.ny
```

## 🛠️ Tools

### nyfmt - Code Formatter
```powershell
# Format file
nyfmt file.ny

# Check formatting
nyfmt --check file.ny
```

### nylint - Linter
```powershell
# Lint file
nylint file.ny

# Strict mode
nylint --strict file.ny
```

### nypm - Package Manager
```powershell
# Initialize project
nypm init my-project

# Add dependency
nypm add mylib ./mylib 1.0.0

# Install dependencies
nypm install

# Publish package
nypm publish mypkg 1.0.0 ./mypkg
```

### nydbg - Debugger
```powershell
# Debug with breakpoints
nydbg file.ny

# Debug with specific breakpoints
nydbg --break 10,20 file.ny

# Step-through debugging
nydbg --step file.ny
```

## 📁 Project Structure

A typical Nyx project:

```
my-project/
├── main.ny           # Entry point
├── nyx.mod           # Module definition
├── ny.lock           # Dependency lock file
├── .cydeps/          # Installed dependencies
├── src/
│   └── utils.ny      # Source files
├── tests/
│   └── test.ny       # Test files
└── README.md
```

### Module Definition (nyx.mod)
```nyx
module "my-project" {
    version "1.0.0"
    description "My awesome project"
    author "Your Name"
    license "MIT"
}
```

## 🔄 Version Compatibility

Nyx follows semantic versioning. The language guarantees:

- **Patch versions** (1.0.x): Bug fixes, no breaking changes
- **Minor versions** (1.x.0): New features, backward compatible
- **Major versions** (x.0.0): Breaking changes

Use version constraints:
```nyx
require_version("^1.0.0");  // Compatible with 1.x.x
require_version("~1.2.0");   // Compatible with 1.2.x
require_version(">=1.0.0");  // 1.0.0 or higher
```

## 🎯 Examples

### Fibonacci
```nyx
fn fib(n) {
    if n <= 1 {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

for i in range(10) {
    print("Fib(" + str(i) + ") = " + str(fib(i)));
}
```

### HTTP Request (with cy:http)
```nyx
import cy:http;

let response = cy:http.get("https://api.example.com/data");
print(response.status);
print(response.body);
```

### JSON Parsing (with cy:json)
```nyx
import cy:json;

let json_str = '{"name": "Nyx", "version": "1.0"}';
let obj = cy:json.parse(json_str);
print(obj.name);  // "Nyx"
```

## 🐛 Troubleshooting

### "nyx is not recognized"
Make sure you've installed nyx globally:
```powershell
# Windows
irm https://raw.githubusercontent.com/suryasekhar06jemsbond-lab/cyber/main/scripts/install.ps1 | iex

# Linux/macOS
curl -fsSL https://raw.githubusercontent.com/suryasekhar06jemsbond-lab/cyber/main/scripts/install.sh | sh
```

Then restart your terminal.

### Extension not loading
1. Check VS Code logs: `Help → Toggle Developer Tools → Console`
2. Try reinstalling the extension
3. Check that `.ny` and `.nx` files are recognized

### Build errors
Ensure you have a C compiler installed:
- **Windows**: Visual Studio Build Tools, MinGW (gcc), or LLVM (clang)
- **Linux**: gcc or clang

## 📄 License

See [LICENSE.md](LICENSE.md) for details.

## 🙏 Acknowledgments

- Built with C99 and VS Code Extension API
- Inspired by modern scripting languages

---

<p align="center">
  <sub>Built with ❤️ by the Nyx Team</sub>
</p>

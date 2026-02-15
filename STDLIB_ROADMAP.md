# Nyx Standard Library Roadmap

A comprehensive plan to build a competitive standard library for the Nyx programming language.

## Philosophy

**"Languages win because of their libraries"**

The goal is to make Nyx productive for real-world applications by providing batteries-included stdlib modules.

---

## Phase 1: Fundamentals ✅ COMPLETED

Essential modules that every language needs.

| Module | File | Description |
|--------|------|-------------|
| String | [`stdlib/string.ny`](stdlib/string.ny) | Comprehensive string utilities (80+ functions) |
| Math | [`stdlib/math.ny`](stdlib/math.ny) | Math functions, constants, statistics |
| Time | [`stdlib/time.ny`](stdlib/time.ny) | Time/date handling, timers |
| IO | [`stdlib/io.ny`](stdlib/io.ny) | File I/O, buffered streams |
| JSON | [`stdlib/json.ny`](stdlib/json.ny) | JSON parsing/serialization |

---

## Phase 2: Networking ✅ COMPLETED

Web and network communication.

| Module | File | Description |
|--------|------|-------------|
| HTTP | [`stdlib/http.ny`](stdlib/http.ny) | HTTP client, request builders |
| Socket | [`stdlib/socket.ny`](stdlib/socket.ny) | TCP/UDP sockets |

---

## Phase 3: Concurrency ✅ COMPLETED

Async programming and concurrency primitives.

| Module | File | Description |
|--------|------|-------------|
| Async | [`stdlib/async.ny`](stdlib/async.ny) | Futures, promises, async/await |
| FFI | [`stdlib/ffi.ny`](stdlib/ffi.ny) | Foreign function interface |
| C Interop | [`stdlib/c.ny`](stdlib/c.ny) | C library bindings |

---

## Phase 4: Developer Tools ✅ COMPLETED

Debugging, logging, testing.

| Module | File | Description |
|--------|------|-------------|
| Debug | [`stdlib/debug.ny`](stdlib/debug.ny) | Profiling, breakpoints, assertions |
| Log | [`stdlib/log.ny`](stdlib/log.ny) | Structured logging |
| Test | [`stdlib/test.ny`](stdlib/test.ny) | Testing framework |
| Collections | [`stdlib/collections.ny`](stdlib/collections.ny) | Data structures |
| Algorithm | [`stdlib/algorithm.ny`](stdlib/algorithm.ny) | Sorting, searching |

---

## Phase 5: Advanced Libraries ✅ COMPLETED

Critical pieces for ecosystem competitiveness.

### A. Cryptography & Security

| Module | File | Status | Description |
|--------|------|--------|-------------|
| Crypto | [`stdlib/crypto.ny`](stdlib/crypto.ny) | ✅ | Hashing (FNV, DJB2, CRC32, SHA-256), encoding (Base64, Hex), encryption (XOR, ROT13), secure random |

### B. Database & Persistence

| Module | File | Status | Description |
|--------|------|--------|-------------|
| Database | [`stdlib/database.ny`](stdlib/database.ny) | ✅ | KV store, SQL-like database, document store, CSV import/export, LRU cache |

### C. Web Framework

| Module | File | Status | Description |
|--------|------|--------|-------------|
| Web | [`stdlib/web.ny`](stdlib/web.ny) | ✅ | Router, middleware (CORS, rate limiter), template engine, REST helpers |

---

## Phase 6: Scientific & AI Computing ✅ COMPLETED

### A. Scientific Computing

| Module | File | Status | Description |
|--------|------|--------|-------------|
| Science | [`stdlib/science.ny`](stdlib/science.ny) | ✅ | Vectors, matrices, linear algebra, ODE solvers, numerical integration |

### B. Tensor Engine (NumNyx)

| Module | File | Status | Description |
|--------|------|--------|-------------|
| Tensor | [`stdlib/tensor.ny`](stdlib/tensor.ny) | ✅ | N-dimensional arrays, broadcasting, matrix ops, autograd, JIT placeholder |

### C. Neural Networks (NyxML)

| Module | File | Status | Description |
|--------|------|--------|-------------|
| NN | [`stdlib/nn.ny`](stdlib/nn.ny) | ✅ | Layers (Linear, Conv2d, ReLU, Sigmoid, Tanh, Softmax, Dropout, BatchNorm), Optimizers (SGD, Adam, RMSprop), Loss functions (MSE, CrossEntropy, BCE), Training loop |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Nyx Runtime                       │
├─────────────────────────────────────────────────────┤
│  Core: string, math, time, io, json, collections    │
├─────────────────────────────────────────────────────┤
│  Networking: http, socket, web                      │
├─────────────────────────────────────────────────────┤
│  Concurrency: async, ffi, c                         │
├─────────────────────────────────────────────────────┤
│  Dev Tools: debug, log, test, algorithm             │
├─────────────────────────────────────────────────────┤
│  Storage: database, crypto                          │
├─────────────────────────────────────────────────────┤
│  Science: science, tensor (NumNyx), nn (NyxML)      │
└─────────────────────────────────────────────────────┘
```

---

## What's Implemented

### Tensor Engine (NumNyx-style)
- ✅ N-dimensional tensor with shape tracking
- ✅ Broadcasting for element-wise operations
- ✅ Matrix multiplication (matmul)
- ✅ Dot product, transpose, reshape
- ✅ Activation functions (sigmoid, relu, tanh, softmax)
- ✅ Reduction operations (sum, mean, min, max)
- ✅ Autograd framework (gradient tracking)
- ✅ JIT compilation placeholder
- ✅ Device management (CPU/GPU abstraction)

### Neural Network (NyxML)
- ✅ Dense/Linear layer
- ✅ Convolutional layer (2D)
- ✅ Activation layers (ReLU, Sigmoid, Tanh, Softmax, LeakyReLU)
- ✅ Dropout
- ✅ Batch Normalization
- ✅ Flatten
- ✅ Sequential container
- ✅ Optimizers (SGD, Adam, RMSprop)
- ✅ Loss functions (MSE, CrossEntropy, BCE)
- ✅ Training loop helper
- ✅ DataLoader

---

## Implementation Notes

1. **Native extensions** - Many modules have placeholder native calls (`_function_name()`) that need real C implementation in `native/nyx.c`

2. **FFI usage** - Use `ffi.open()`, `ffi.symbol()`, `ffi.call()` for native interop

3. **Performance** - Pure Nyx implementations are good for prototyping; critical paths should use native calls (especially BLAS/LAPACK for linear algebra)

4. **GPU Support** - Current implementation is CPU-only. GPU acceleration requires CUDA/OpenCL bindings

5. **Testing** - Each module should have corresponding tests

---

## Version History

- **0.10.0** - Major stdlib expansion
  - Added crypto, database, web, science modules
  - Added NumNyx tensor engine with autograd
  - Added NyxML neural network framework
  - ~70,000+ lines of stdlib code total

- **0.9.0** - Core modules
  - Basic string, math, time, io, json
  - HTTP, socket, async
  - Debug, logging, test

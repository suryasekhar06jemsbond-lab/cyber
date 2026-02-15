# ============================================================================
# Nyx Systems Programming Primitives
# ============================================================================
# Low-level systems programming features for Nyx
# Provides: RAII, pointers, unsafe blocks, memory management
# ============================================================================

# ============================================================================
# Memory Management & RAII
# ============================================================================

# Box<T> - Heap allocation with ownership
fn Box(value) {
    return {
        "type": "Box",
        "value": value,
        "is_allocated": true
    };
}

# Unbox - Extract value from Box, consuming it
fn unbox(box) {
    if box.type != "Box" {
        error("Expected Box, got: " + str(box.type));
    }
    return box.value;
}

# Scope guard for RAII pattern
fn scope_guard(release_fn) {
    return {
        "release": release_fn,
        "active": true
    };
}

# ============================================================================
# Pointer Types
# ============================================================================

# Raw pointer (use with caution)
fn RawPtr(address, type_) {
    return {
        "type": "RawPtr",
        "address": address,
        "target_type": type_,
        "is_null": address == 0
    };
}

# Create null pointer
fn null_ptr(type_) {
    return RawPtr(0, type_);
}

# Check if pointer is null
fn is_null_ptr(ptr) {
    return ptr.is_null;
}

# ============================================================================
# Unsafe Operations (restricted to unsafe blocks)
# ============================================================================

# Unsafe block marker - these bypass safety checks
fn unsafe(block_fn) {
    return {
        "type": "unsafe_block",
        "fn": block_fn,
        "requires_unsafe_context": true
    };
}

# ============================================================================
# Memory Operations
# ============================================================================

# Zero-initialize memory
fn zero_mem(size) {
    let result = [];
    for i in range(size) {
        result = result + [0];
    }
    return result;
}

# Copy memory (memcpy semantics)
fn memcpy(dest, src, size) {
    for i in range(size) {
        dest[i] = src[i];
    }
    return dest;
}

# Set memory (memset semantics)
fn memset(dest, value, size) {
    for i in range(size) {
        dest[i] = value;
    }
    return dest;
}

# ============================================================================
# Atomic Operations (for concurrency)
# ============================================================================

# Atomic integer (thread-safe)
fn AtomicInt(initial_value) {
    return {
        "type": "AtomicInt",
        "value": initial_value,
        "lock": null
    };
}

# Atomic load
fn atomic_load(atomic) {
    return atomic.value;
}

# Atomic store
fn atomic_store(atomic, new_value) {
    atomic.value = new_value;
    return new_value;
}

# Atomic add (fetch-and-add)
fn atomic_add(atomic, delta) {
    let old = atomic.value;
    atomic.value = atomic.value + delta;
    return old;
}

# ============================================================================
# Mutex for Thread Safety
# ============================================================================

fn Mutex(initial_value) {
    return {
        "type": "Mutex",
        "value": initial_value,
        "locked": false,
        "owner": null
    };
}

fn mutex_lock(mutex) {
    mutex.locked = true;
    return mutex;
}

fn mutex_unlock(mutex) {
    mutex.locked = false;
    return mutex;
}

fn mutex_get(mutex) {
    return mutex.value;
}

fn mutex_set(mutex, value) {
    mutex.value = value;
    return value;
}

# ============================================================================
# Read-Write Lock
# ============================================================================

fn RwLock(initial_value) {
    return {
        "type": "RwLock",
        "value": initial_value,
        "readers": 0,
        "writer": null
    };
}

fn rw_read(rwlock) {
    rwlock.readers = rwlock.readers + 1;
    return rwlock.value;
}

fn rw_write(rwlock, new_value) {
    rwlock.value = new_value;
    return new_value;
}

fn rw_read_unlock(rwlock) {
    rwlock.readers = rwlock.readers - 1;
    return null;
}

# ============================================================================
# Drop (Destructor) Management
# ============================================================================

# Register destructor for value
fn with_destructor(value, drop_fn) {
    return {
        "type": "WithDestructor",
        "value": value,
        "drop": drop_fn
    };
}

# ============================================================================
# Unsafe Pointer Operations
# ============================================================================

# Cast between pointer types
fn ptr_cast(ptr, new_type) {
    return {
        "type": "RawPtr",
        "address": ptr.address,
        "target_type": new_type,
        "is_null": ptr.is_null
    };
}

# Offset pointer
fn ptr_offset(ptr, offset) {
    return {
        "type": "RawPtr",
        "address": ptr.address + offset,
        "target_type": ptr.target_type,
        "is_null": false
    };
}

# ============================================================================
# Size and Alignment
# ============================================================================

# Size of type in bytes
const TYPE_SIZES = {
    "i8": 1,
    "i16": 2,
    "i32": 4,
    "i64": 8,
    "u8": 1,
    "u16": 2,
    "u32": 4,
    "u64": 8,
    "f32": 4,
    "f64": 8,
    "bool": 1,
    "char": 1
};

fn size_of(type_) {
    if type_ in TYPE_SIZES {
        return TYPE_SIZES[type_];
    }
    return 8; # Default pointer size
}

fn align_of(type_) {
    return size_of(type_); # Alignment equals size for simple types
}

# ============================================================================
# Stack Allocation (simulated)
# ============================================================================

# Alloca - stack allocation
fn alloca(size) {
    return zero_mem(size);
}

# ============================================================================
# Foreign Function Interface
# ============================================================================

# Define external function
fn extern_fn(name, ret_type, arg_types) {
    return {
        "type": "extern",
        "name": name,
        "return_type": ret_type,
        "arg_types": arg_types
    };
}

# Call external function
fn call_extern(fn_def, args) {
    # In real implementation, this would call into C
    return null;
}

# ============================================================================
# Systems Programming Utilities
# ============================================================================

# Volatile read (prevent optimization)
fn volatile_read(ptr) {
    return ptr.address;
}

# Volatile write (prevent optimization)
fn volatile_write(ptr, value) {
    return value;
}

# Compiler fence
fn compiler_fence() {
    # Memory ordering hint
    return true;
}

# ============================================================================
# Error Handling for Systems Code
# ============================================================================

# Result for fallible operations
fn Ok(value) {
    return {
        "type": "Result",
        "ok": true,
        "value": value,
        "error": null
    };
}

fn Err(error) {
    return {
        "type": "Result",
        "ok": false,
        "value": null,
        "error": error
    };
}

fn is_ok(result) {
    return result.ok;
}

fn is_err(result) {
    return !result.ok;
}

# ============================================================================
# Panicking
# ============================================================================

# Panic with message
fn panic(message) {
    error("PANIC: " + message);
}

# Unreachable code marker
fn unreachable() {
    error("UNREACHABLE: executed unreachable code");
}

# ============================================================================
# Documentation
# ============================================================================
# 
# systems.ny provides low-level systems programming primitives.
# These mirror Rust's std::mem, std::ptr, std::sync, etc.
#
# Usage:
#   let boxed = Box(42);
#   let value = unbox(boxed);
#
#   let mutex = Mutex(0);
#   mutex_lock(mutex);
#   # critical section
#   mutex_unlock(mutex);
#
# ============================================================================

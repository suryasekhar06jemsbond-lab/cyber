# ===========================================
# Nyx Standard Library - FFI Module
# ===========================================
# Foreign Function Interface for C/C++ interop
# CRITICAL: This enables Nyx to call native code

# Load a shared library (DLL on Windows, .so on Linux)
fn open(lib_path) {
    # This would be implemented as a native call
    # Returns a library handle
    return _ffi_open(lib_path);
}

# Close a loaded library
fn close(lib) {
    return _ffi_close(lib);
}

# Get a function pointer from a library
fn symbol(lib, func_name) {
    return _ffi_symbol(lib, func_name);
}

# Call a C function
fn call(func_ptr, ret_type, ...args) {
    # Types: void, int, float, double, string, pointer
    return _ffi_call(func_ptr, ret_type, args);
}

# Call with argument types specified
fn call_with_types(func_ptr, ret_type, arg_types, args) {
    return _ffi_call_typed(func_ptr, ret_type, arg_types, args);
}

# Allocate memory
fn malloc(size) {
    return _ffi_malloc(size);
}

# Free memory
fn free(ptr) {
    return _ffi_free(ptr);
}

# Allocate string in C memory
fn to_c_string(s) {
    let ptr = _ffi_malloc(len(s) + 1);
    # Copy string to pointer
    # In real implementation, this would copy bytes
    return ptr;
}

# Convert C string to Nyx string
fn from_c_string(ptr) {
    # Would read from C memory
    return "";
}

# Convert Nyx array to C array
fn to_c_array(arr, elem_type) {
    let size = len(arr);
    let elem_size = _ffi_type_size(elem_type);
    let ptr = _ffi_malloc(size * elem_size);
    return ptr;
}

# Get size of C type
fn type_size(type_name) {
    if type_name == "char" {
        return 1;
    }
    if type_name == "short" {
        return 2;
    }
    if type_name == "int" {
        return 4;
    }
    if type_name == "long" {
        return 8;
    }
    if type_name == "float" {
        return 4;
    }
    if type_name == "double" {
        return 8;
    }
    if type_name == "pointer" {
        return 8;
    }
    throw "ffi.type_size: unknown type " + type_name;
}

# Read memory
fn peek(ptr, type_name) {
    return _ffi_peek(ptr, type_name);
}

# Write memory
fn poke(ptr, value, type_name) {
    return _ffi_poke(ptr, value, type_name);
}

# Get pointer address
fn address_of(ptr) {
    return _ffi_address(ptr);
}

# Add offset to pointer
fn ptr_add(ptr, offset) {
    return _ffi_ptr_add(ptr, offset);
}

# Convert to void pointer
fn as_void_ptr(ptr) {
    return _ffi_void_ptr(ptr);
}

# FFI Type constants
let TYPE_VOID = 0;
let TYPE_CHAR = 1;
let TYPE_SHORT = 2;
let TYPE_INT = 3;
let TYPE_LONG = 4;
let TYPE_FLOAT = 5;
let TYPE_DOUBLE = 6;
let TYPE_POINTER = 7;
let TYPE_STRING = 8;

# FFI Library wrapper class
class Library {
    fn init(self, path) {
        self.handle = open(path);
        if self.handle == null {
            throw "ffi.Library: failed to load " + path;
        }
    }
    
    fn func(self, name, ret_type) {
        let ptr = symbol(self.handle, name);
        if ptr == null {
            throw "ffi.Library: function " + name + " not found";
        }
        return CFunction(ptr, ret_type);
    }
    
    fn close(self) {
        close(self.handle);
        self.handle = null;
    }
}

# C Function wrapper
class CFunction {
    fn init(self, ptr, ret_type) {
        self.ptr = ptr;
        self.ret_type = ret_type;
    }
    
    fn call(self, ...args) {
        return call(self.ptr, self.ret_type, ...args);
    }
}

# C Data types for type safety
class CType {
    fn init(self, name, size) {
        self.name = name;
        self.size = size;
    }
}

# Predefined C types
let C_CHAR = CType("char", 1);
let C_SHORT = CType("short", 2);
let C_INT = CType("int", 4);
let C_LONG = CType("long", 8);
let C_FLOAT = CType("float", 4);
let C_DOUBLE = CType("double", 8);
let C_POINTER = CType("pointer", 8);
let C_VOID = CType("void", 0);

# C Struct definition helper
class CStruct {
    fn init(self, name) {
        self.name = name;
        self.fields = [];
    }
    
    fn add_field(self, field_name, field_type) {
        push(self.fields, field_name);
        push(self.fields, field_type);
        return self;
    }
    
    fn size(self) {
        let total = 0;
        for i in range(1, len(self.fields), 2) {
            total = total + self.fields[i].size;
        }
        return total;
    }
}

# Example: Create a C struct for a point
fn Point() {
    return CStruct("Point")
        .add_field("x", C_INT)
        .add_field("y", C_INT);
}

# Callback/Function pointer support
class Callback {
    fn init(self, nyx_func, ret_type, arg_types) {
        self.nyx_func = nyx_func;
        self.ret_type = ret_type;
        self.arg_types = arg_types;
    }
    
    fn to_c(self) {
        # Creates a C function pointer that calls the Nyx function
        return _ffi_callback_create(self.nyx_func, self.ret_type, self.arg_types);
    }
}

# Example usage:
# let lib = Library("libc.so.6");
# let printf = lib.func("printf", C_INT);
# printf.call("Hello %s\n", "World");

# ===========================================
# Nyx Standard Library - C Interop Module
# ===========================================
# Extended C/C++ interoperability

# C type sizes (in bytes)
let C_CHAR = 1;
let C_SHORT = 2;
let C_INT = 4;
let C_LONG = 4;
let C_LONGLONG = 8;
let C_FLOAT = 4;
let C_DOUBLE = 8;
let C_POINTER = 8;
let C_SIZE_T = 8;

# C type signedness
let C_SIGNED = 1;
let C_UNSIGNED = 2;

# Load C library
fn lib(name) {
    return CLibrary(name);
}

# C Library wrapper
class CLibrary {
    fn init(self, name) {
        self.name = name;
        self.handle = ffi.open(name);
        if self.handle == null {
            throw "Failed to load library: " + name;
        }
    }
    
    fn func(self, name, ret_type, arg_types) {
        return CFunction(self.handle, name, ret_type, arg_types);
    }
    
    fn var(self, name, c_type) {
        return CVar(self.handle, name, c_type);
    }
    
    fn close(self) {
        ffi.close(self.handle);
    }
}

# C Function wrapper
class CFunction {
    fn init(self, lib_handle, name, ret_type, arg_types) {
        self.lib_handle = lib_handle;
        self.name = name;
        self.ret_type = ret_type;
        self.arg_types = arg_types;
        
        # Get function pointer
        self.ptr = ffi.symbol(lib_handle, name);
        if self.ptr == null {
            throw "Function not found: " + name;
        }
    }
    
    fn call(self, ...args) {
        # Convert Nyx args to C args
        let c_args = [];
        for i in range(len(args)) {
            if i < len(self.arg_types) {
                push(c_args, _to_c_value(args[i], self.arg_types[i]));
            }
        }
        
        # Call function
        let result = ffi.call_with_types(self.ptr, self.ret_type, self.arg_types, c_args);
        
        # Convert result from C
        return _from_c_value(result, self.ret_type);
    }
}

# C Variable wrapper
class CVar {
    fn init(self, lib_handle, name, c_type) {
        self.lib_handle = lib_handle;
        self.name = name;
        self.c_type = c_type;
    }
    
    fn get(self) {
        let ptr = ffi.symbol(self.lib_handle, self.name);
        if ptr == null {
            throw "Variable not found: " + self.name;
        }
        return _from_c_value(ffi.peek(ptr, self.c_type), self.c_type);
    }
    
    fn set(self, value) {
        let ptr = ffi.symbol(self.lib_handle, self.name);
        if ptr == null {
            throw "Variable not found: " + self.name;
        }
        ffi.poke(ptr, _to_c_value(value, self.c_type), self.c_type);
    }
}

# Convert Nyx value to C value
fn _to_c_value(nyx_value, c_type) {
    if c_type == "int" || c_type == C_INT {
        return int(nyx_value);
    }
    if c_type == "float" || c_type == C_FLOAT {
        return float(nyx_value);
    }
    if c_type == "double" || c_type == C_DOUBLE {
        return float(nyx_value);
    }
    if c_type == "string" || c_type == "char*" {
        return ffi.to_c_string(str(nyx_value));
    }
    return nyx_value;
}

# Convert C value to Nyx value
fn _from_c_value(c_value, c_type) {
    if c_type == "int" || c_type == C_INT {
        return int(c_value);
    }
    if c_type == "float" || c_type == C_FLOAT {
        return float(c_value);
    }
    if c_type == "double" || c_type == C_DOUBLE {
        return float(c_value);
    }
    if c_type == "string" || c_type == "char*" {
        return ffi.from_c_string(c_value);
    }
    return c_value;
}

# C struct definition
class Struct {
    fn init(self, name) {
        self.name = name;
        self.fields = [];
        self.size = 0;
    }
    
    fn add(self, field_name, c_type) {
        push(self.fields, field_name);
        push(self.fields, c_type);
        self.size = self.size + _type_size(c_type);
        return self;
    }
    
    fn create(self) {
        return CStructInstance(self);
    }
    
    fn size_of(self) {
        return self.size;
    }
}

# C struct instance
class CStructInstance {
    fn init(self, struct_def) {
        self.def = struct_def;
        self.data = ffi.malloc(struct_def.size);
    }
    
    fn get(self, field_name) {
        let offset = _field_offset(self.def, field_name);
        if offset < 0 {
            throw "Field not found: " + field_name;
        }
        let ptr = ffi.ptr_add(self.data, offset);
        let c_type = _field_type(self.def, field_name);
        return ffi.peek(ptr, c_type);
    }
    
    fn set(self, field_name, value) {
        let offset = _field_offset(self.def, field_name);
        if offset < 0 {
            throw "Field not found: " + field_name;
        }
        let ptr = ffi.ptr_add(self.data, offset);
        let c_type = _field_type(self.def, field_name);
        ffi.poke(ptr, value, c_type);
    }
    
    fn address(self) {
        return self.data;
    }
    
    fn free(self) {
        ffi.free(self.data);
    }
}

fn _field_offset(struct_def, field_name) {
    let offset = 0;
    for i in range(0, len(struct_def.fields), 2) {
        if struct_def.fields[i] == field_name {
            return offset;
        }
        offset = offset + _type_size(struct_def.fields[i + 1]);
    }
    return -1;
}

fn _field_type(struct_def, field_name) {
    for i in range(0, len(struct_def.fields), 2) {
        if struct_def.fields[i] == field_name {
            return struct_def.fields[i + 1];
        }
    }
    return null;
}

fn _type_size(c_type) {
    if c_type == C_CHAR { return 1; }
    if c_type == C_SHORT { return 2; }
    if c_type == C_INT { return 4; }
    if c_type == C_LONG { return 4; }
    if c_type == C_LONGLONG { return 8; }
    if c_type == C_FLOAT { return 4; }
    if c_type == C_DOUBLE { return 8; }
    if c_type == C_POINTER { return 8; }
    if c_type == C_SIZE_T { return 8; }
    return 8;
}

# Callback from C to Nyx
class CCallback {
    fn init(self, nyx_func, ret_type, arg_types) {
        self.nyx_func = nyx_func;
        self.ret_type = ret_type;
        self.arg_types = arg_types;
        # Create C callback
        self.ptr = _create_callback(nyx_func, ret_type, arg_types);
    }
    
    fn call(self, ...args) {
        return self.nyx_func(...args);
    }
    
    fn free(self) {
        # Free callback
    }
}

fn _create_callback(nyx_func, ret_type, arg_types) {
    # Would create native callback
    return null;
}

# Common C structures
fn struct_Point() {
    return Struct("Point")
        .add("x", C_INT)
        .add("y", C_INT);
}

fn struct_Point2D() {
    return Struct("Point2D")
        .add("x", C_DOUBLE)
        .add("y", C_DOUBLE);
}

fn struct_Point3D() {
    return Struct("Point3D")
        .add("x", C_DOUBLE)
        .add("y", C_DOUBLE)
        .add("z", C_DOUBLE);
}

fn struct_Complex() {
    return Struct("Complex")
        .add("real", C_DOUBLE)
        .add("imag", C_DOUBLE);
}

fn struct_File() {
    return Struct("FILE")
        .add("_ptr", C_POINTER);
}

# Example usage:
# let libc = lib("c");
# let printf = libc.func("printf", C_INT, ["char*"]);
# printf.call("Hello %s\n", "World");

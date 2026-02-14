# Type helpers for Nyx

fn type_of(value) {
    return type(value);
}

fn is_int(value) {
    return type(value) == "int";
}

fn is_bool(value) {
    return type(value) == "bool";
}

fn is_string(value) {
    return type(value) == "string";
}

fn is_array(value) {
    return type(value) == "array";
}

fn is_function(value) {
    return type(value) == "function";
}

fn is_null(value) {
    return type(value) == "null";
}
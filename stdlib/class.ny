# Minimal class/object helpers built on arrays.
# Object layout: [key0, value0, key1, value1, ...]

fn object_new() {
    return [];
}

fn object_set(obj, key, value) {
    push(obj, key);
    push(obj, value);
    return obj;
}

fn _object_get(obj, key, i) {
    if (i >= len(obj)) {
        return argv(-1);
    }
    if (obj[i] == key) {
        return obj[i + 1];
    }
    return _object_get(obj, key, i + 2);
}

fn object_get(obj, key) {
    return _object_get(obj, key, 0);
}

fn class_new(name) {
    let cls = object_new();
    object_set(cls, "__name__", name);
    return cls;
}

fn class_with_ctor(name, ctor) {
    let cls = class_new(name);
    object_set(cls, "__ctor__", ctor);
    return cls;
}

fn class_set_method(cls, name, method_fn) {
    object_set(cls, name, method_fn);
    return cls;
}

fn class_name(cls) {
    return object_get(cls, "__name__");
}

fn class_instantiate0(cls) {
    let inst = object_new();
    object_set(inst, "__class__", cls);
    let ctor = object_get(cls, "__ctor__");
    if (type(ctor) == "function") {
        ctor(inst);
    }
    return inst;
}

fn class_instantiate1(cls, a) {
    let inst = object_new();
    object_set(inst, "__class__", cls);
    let ctor = object_get(cls, "__ctor__");
    if (type(ctor) == "function") {
        ctor(inst, a);
    }
    return inst;
}

fn class_instantiate2(cls, a, b) {
    let inst = object_new();
    object_set(inst, "__class__", cls);
    let ctor = object_get(cls, "__ctor__");
    if (type(ctor) == "function") {
        ctor(inst, a, b);
    }
    return inst;
}

fn class_call0(inst, method_name) {
    let cls = object_get(inst, "__class__");
    let method = object_get(cls, method_name);
    return method(inst);
}

fn class_call1(inst, method_name, a) {
    let cls = object_get(inst, "__class__");
    let method = object_get(cls, method_name);
    return method(inst, a);
}

fn class_call2(inst, method_name, a, b) {
    let cls = object_get(inst, "__class__");
    let method = object_get(cls, method_name);
    return method(inst, a, b);
}
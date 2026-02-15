#!/usr/bin/env nyx

print("Running comprehensive Nyx language tests...");

# --- Primitives ---
let i = 100;
let f = 10;
let b = true;
let s = "String";
let n = null;

if (i == 100 && b == true) {
    print("Primitives: OK");
} else {
    print("Primitives: FAIL");
}

# --- Strings ---
let str = "Hello" + " " + "World";
if (str == "Hello World") {
    print("Strings: OK");
} else {
    print("Strings: FAIL");
}

# --- Arithmetic ---
let sum = 10 + 20;
let sub = 20 - 5;
let mul = 5 * 4;
let div = 20 / 2;
let mod = 10 % 3;

if (sum == 30 && sub == 15 && mul == 20 && div == 10 && mod == 1) {
    print("Arithmetic: OK");
} else {
    print("Arithmetic: FAIL");
}

# --- Logic ---
if (true && true) {
    if (false || true) {
        if (!false) {
            print("Logic: OK");
        }
    }
}

# --- Arrays ---
let arr = [1, 2, 3, 4, 5];
if (arr[0] == 1 && arr[4] == 5) {
    print("Arrays: OK");
}
let len = 0;
for (x in arr) {
    len = len + 1;
}
if (len == 5) {
    print("Array Iteration: OK");
}

# --- Objects ---
let obj = {
    name: "Nyx",
    version: 1
};
if (obj.name == "Nyx" && obj.version == 1) {
    print("Objects: OK");
}
obj.version = 2;
if (obj.version == 2) {
    print("Object Mutation: OK");
}

# --- Functions ---
fn add(a, b) {
    return a + b;
}

fn fib(n) {
    if (n <= 1) { return n; }
    return fib(n - 1) + fib(n - 2);
}

if (add(10, 20) == 30) {
    print("Functions: OK");
}
if (fib(10) == 55) {
    print("Recursion: OK");
}

# --- Loops (While) ---
let w = 0;
while (w < 5) {
    w = w + 1;
}
if (w == 5) {
    print("While Loop: OK");
} else {
    print("While Loop: FAIL");
}

# --- Control Flow (Break/Continue) ---
let bc = 0;
let bc_sum = 0;
while (bc < 10) {
    bc = bc + 1;
    if (bc == 5) { continue; }
    if (bc > 8) { break; }
    bc_sum = bc_sum + bc;
}
# 1+2+3+4+6+7+8 = 31
if (bc_sum == 31) {
    print("Break/Continue: OK");
} else {
    print("Break/Continue: FAIL");
}

# --- Switch ---
let sw_val = 2;
let sw_res = "none";
switch (sw_val) {
    case 1: { sw_res = "one"; }
    case 2: { sw_res = "two"; }
    default: { sw_res = "other"; }
}
if (sw_res == "two") {
    print("Switch: OK");
} else {
    print("Switch: FAIL");
}

# --- Builtins ---
if (abs(-10) == 10) {
    print("Builtins: OK");
} else {
    print("Builtins: FAIL");
}

# --- Error Handling ---
try {
    throw "Error";
} catch (e) {
    if (e == "Error") {
        print("Try/Catch: OK");
    } else {
        print("Try/Catch: FAIL");
    }
}

print("All tests completed.");
# ===========================================
# Nyx Standard Library - Test Module
# ===========================================
# Testing framework for Nyx

# Test state
let _test_results = [];
let _test_count = 0;
let _test_passed = 0;
let _test_failed = 0;
let _test_skipped = 0;
let _test_only_mode = false;
let _test_current_suite = "";

# Reset test state
fn reset() {
    _test_results = [];
    _test_count = 0;
    _test_passed = 0;
    _test_failed = 0;
    _test_skipped = 0;
    _test_current_suite = "";
    _test_only_mode = false;
}

# Assert condition is true
fn assert(condition, message) {
    _test_count = _test_count + 1;
    if condition {
        _test_passed = _test_passed + 1;
        push(_test_results, {status: "pass", message: message});
    } else {
        _test_failed = _test_failed + 1;
        push(_test_results, {status: "fail", message: message});
    }
}

# Assert equal
fn eq(actual, expected, message) {
    _test_count = _test_count + 1;
    if actual == expected {
        _test_passed = _test_passed + 1;
        push(_test_results, {status: "pass", message: message});
    } else {
        _test_failed = _test_failed + 1;
        push(_test_results, {status: "fail", message: message + 
            " (expected " + str(expected) + ", got " + str(actual) + ")"});
    }
}

# Assert not equal
fn neq(actual, expected, message) {
    _test_count = _test_count + 1;
    if actual != expected {
        _test_passed = _test_passed + 1;
        push(_test_results, {status: "pass", message: message});
    } else {
        _test_failed = _test_failed + 1;
        push(_test_results, {status: "fail", message: message});
    }
}

# Assert throws exception
fn raises(fn_to_test, message) {
    _test_count = _test_count + 1;
    try {
        fn_to_test();
        _test_failed = _test_failed + 1;
        push(_test_results, {status: "fail", message: message + " (no exception raised)"});
    } catch e {
        _test_passed = _test_passed + 1;
        push(_test_results, {status: "pass", message: message});
    }
}

# Assert approximately equal (for floats)
fn approx(actual, expected, tolerance, message) {
    _test_count = _test_count + 1;
    if type(tolerance) == "null" {
        tolerance = 0.0001;
    }
    if abs(actual - expected) <= tolerance {
        _test_passed = _test_passed + 1;
        push(_test_results, {status: "pass", message: message});
    } else {
        _test_failed = _test_failed + 1;
        push(_test_results, {status: "fail", message: message + 
            " (expected " + str(expected) + ", got " + str(actual) + ")"});
    }
}

# Assert contains
fn contains_(container, item, message) {
    _test_count = _test_count + 1;
    let found = false;
    
    if type(container) == "array" {
        for c in container {
            if c == item {
                found = true;
                break;
            }
        }
    } else if type(container) == "string" {
        found = contains(container, item);
    }
    
    if found {
        _test_passed = _test_passed + 1;
        push(_test_results, {status: "pass", message: message});
    } else {
        _test_failed = _test_failed + 1;
        push(_test_results, {status: "fail", message: message});
    }
}

# Skip a test
fn skip(message) {
    _test_count = _test_count + 1;
    _test_skipped = _test_skipped + 1;
    push(_test_results, {status: "skip", message: message});
}

# Only run this test
fn only(message) {
    _test_only_mode = true;
    # In a full implementation, this would track which tests to run
}

# Run a test function
fn test(name, fn_to_test) {
    if _test_only_mode {
        # Only run if marked as only
    }
    
    try {
        fn_to_test();
    } catch e {
        _test_failed = _test_failed + 1;
        push(_test_results, {status: "fail", message: name + ": " + str(e)});
    }
}

# Run a test suite
fn suite(name, tests) {
    _test_current_suite = name;
    for test_fn in tests {
        test(name, test_fn);
    }
}

# Get test results
fn results() {
    return {
        total: _test_count,
        passed: _test_passed,
        failed: _test_failed,
        skipped: _test_skipped,
        details: _test_results
    };
}

# Print test summary
fn summary() {
    let r = results();
    print("================================");
    print("Test Summary");
    print("================================");
    print("Total:   " + str(r.total));
    print("Passed:  " + str(r.passed));
    print("Failed:  " + str(r.failed));
    print("Skipped: " + str(r.skipped));
    print("================================");
    
    if r.failed > 0 {
        print("\nFailed tests:");
        for result in r.details {
            if result.status == "fail" {
                print("  FAIL: " + result.message);
            }
        }
    }
    
    return r.failed == 0;
}

# Assert true
fn is_true(value, message) {
    return assert(value == true, message);
}

# Assert false
fn is_false(value, message) {
    return assert(value == false, message);
}

# Assert null
fn is_null(value, message) {
    return assert(value == null, message);
}

# Assert not null
fn is_not_null(value, message) {
    return assert(value != null, message);
}

# Assert array is empty
fn is_empty(arr, message) {
    _test_count = _test_count + 1;
    if type(arr) != "array" {
        _test_failed = _test_failed + 1;
        push(_test_results, {status: "fail", message: message + " (not an array)"});
        return;
    }
    if len(arr) == 0 {
        _test_passed = _test_passed + 1;
        push(_test_results, {status: "pass", message: message});
    } else {
        _test_failed = _test_failed + 1;
        push(_test_results, {status: "fail", message: message + " (array not empty)"});
    }
}

# Assert array length
fn len_is(arr, expected_len, message) {
    _test_count = _test_count + 1;
    if type(arr) != "array" {
        _test_failed = _test_failed + 1;
        push(_test_results, {status: "fail", message: message + " (not an array)"});
        return;
    }
    if len(arr) == expected_len {
        _test_passed = _test_passed + 1;
        push(_test_results, {status: "pass", message: message});
    } else {
        _test_failed = _test_failed + 1;
        push(_test_results, {status: "fail", message: message + 
            " (expected length " + str(expected_len) + ", got " + str(len(arr)) + ")"});
    }
}

# Test runner class for more control
class TestRunner {
    fn init(self) {
        self.results = [];
        self.verbose = false;
    }
    
    fn set_verbose(self, v) {
        self.verbose = v;
        return self;
    }
    
    fn run(self, name, fn_to_test) {
        try {
            fn_to_test();
            push(self.results, {name: name, status: "pass"});
            if self.verbose {
                print("  PASS: " + name);
            }
        } catch e {
            push(self.results, {name: name, status: "fail", error: str(e)});
            if self.verbose {
                print("  FAIL: " + name + " - " + str(e));
            }
        }
    }
    
    fn summary(self) {
        let passed = 0;
        let failed = 0;
        for r in self.results {
            if r.status == "pass" {
                passed = passed + 1;
            } else {
                failed = failed + 1;
            }
        }
        return {passed: passed, failed: failed, total: len(self.results)};
    }
}

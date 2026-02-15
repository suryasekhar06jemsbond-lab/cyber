# ===========================================
# Nyx Standard Library - Debug Module
# ===========================================
# Comprehensive debugging and profiling utilities

# Get current stack trace
fn trace() {
    # Would return current stack trace
    # In real implementation, this would capture the call stack
    return _debug_trace();
}

# Pretty print value for debugging
fn inspect(value, options) {
    if type(options) == "null" {
        options = {};
    }
    
    let depth = options.depth;
    if type(depth) == "null" {
        depth = 3;
    }
    
    return _inspect_value(value, depth, 0);
}

fn _inspect_value(value, depth, indent) {
    if depth < 0 {
        return "...";
    }
    
    let t = type(value);
    
    if t == "null" {
        return "null";
    }
    if t == "bool" {
        return (if value { "true" } else { "false" });
    }
    if t == "int" || t == "float" {
        return str(value);
    }
    if t == "string" {
        if len(value) > 50 {
            return "\"" + value[:50] + "...\"";
        }
        return "\"" + value + "\"";
    }
    if t == "function" {
        return "<function>";
    }
    if t == "array" {
        if len(value) == 0 {
            return "[]";
        }
        let parts = [];
        for item in value {
            push(parts, _inspect_value(item, depth - 1, indent + 2));
        }
        return "[" + join(parts, ", ") + "]";
    }
    if t == "object" {
        if len(value) == 0 {
            return "{}";
        }
        let parts = [];
        for i in range(0, len(value), 2) {
            let k = value[i];
            let v = value[i + 1];
            push(parts, k + ": " + _inspect_value(v, depth - 1, indent + 2));
        }
        return "{" + join(parts, ", ") + "}";
    }
    
    return "<" + t + ">";
}

# Deep inspection with full details
fn deep_inspect(value, max_depth) {
    if type(max_depth) == "null" {
        max_depth = 10;
    }
    return _deep_inspect(value, 0, max_depth);
}

fn _deep_inspect(value, current_depth, max_depth) {
    if current_depth >= max_depth {
        return "<max depth reached>";
    }
    
    let t = type(value);
    
    if t == "null" {
        return "null";
    }
    if t == "bool" {
        return (if value { "true" } else { "false" }) + " (bool)";
    }
    if t == "int" {
        return str(value) + " (int)";
    }
    if t == "float" {
        return str(value) + " (float)";
    }
    if t == "string" {
        return "\"" + value + "\" (string, len=" + str(len(value)) + ")";
    }
    if t == "function" {
        return "<function> (len=" + str(len(value)) + ")";
    }
    if t == "array" {
        if len(value) == 0 {
            return "[] (array)";
        }
        let parts = [];
        for i in range(len(value)) {
            push(parts, "[" + str(i) + "] " + _deep_inspect(value[i], current_depth + 1, max_depth));
        }
        return "array[\n" + join(parts, "\n") + "\n]";
    }
    if t == "object" {
        if len(value) == 0 {
            return "{} (object)";
        }
        let parts = [];
        for i in range(0, len(value), 2) {
            let k = value[i];
            let v = value[i + 1];
            push(parts, k + ": " + _deep_inspect(v, current_depth + 1, max_depth));
        }
        return "object {\n" + join(parts, "\n") + "\n}";
    }
    
    return "<" + t + ">";
}

# Breakpoint (debug stop)
fn breakpoint() {
    # In debug mode, this would pause execution
    print("Breakpoint hit!");
    print("Stack: " + trace());
}

# Assert with message
fn assert(condition, message) {
    if !condition {
        throw "Assertion failed: " + message;
    }
}

# Assert equal
fn assert_eq(actual, expected, message) {
    if actual != expected {
        let msg = "Assertion failed: expected " + str(expected) + " but got " + str(actual);
        if type(message) != "null" {
            msg = msg + " - " + message;
        }
        throw msg;
    }
}

# Assert not equal
fn assert_ne(actual, expected, message) {
    if actual == expected {
        let msg = "Assertion failed: expected not " + str(expected) + " but got " + str(actual);
        if type(message) != "null" {
            msg = msg + " - " + message;
        }
        throw msg;
    }
}

# Assert null
fn assert_null(value, message) {
    if value != null {
        let msg = "Assertion failed: expected null but got " + str(value);
        if type(message) != "null" {
            msg = msg + " - " + message;
        }
        throw msg;
    }
}

# Assert not null
fn assert_not_null(value, message) {
    if value == null {
        throw "Assertion failed: value is null" + (if type(message) != "null" { " - " + message } else { "" });
    }
}

# Assert true
fn assert_true(value, message) {
    if !value {
        throw "Assertion failed: expected true" + (if type(message) != "null" { " - " + message } else { "" });
    }
}

# Assert false
fn assert_false(value, message) {
    if value {
        throw "Assertion failed: expected false" + (if type(message) != "null" { " - " + message } else { "" });
    }
}

# Assert contains
fn assert_contains(container, item, message) {
    if type(container) == "string" {
        if !contains(container, item) {
            throw "Assertion failed: '" + item + "' not found in string" + (if type(message) != "null" { " - " + message } else { "" });
        }
    } else if type(container) == "array" {
        let found = false;
        for i in container {
            if i == item {
                found = true;
                break;
            }
        }
        if !found {
            throw "Assertion failed: item not found in array" + (if type(message) != "null" { " - " + message } else { "" });
        }
    }
}

# Timing decorator
fn timed(fn_to_wrap) {
    return fn(...args) {
        let start = time();
        let result = fn_to_wrap(...args);
        let elapsed = time() - start;
        print("Function " + str(fn_to_wrap) + " took " + str(elapsed) + "s");
        return result;
    };
}

# Memory info (placeholder)
fn memory() {
    return {
        used: _debug_memory_used(),
        total: _debug_memory_total(),
        peak: _debug_memory_peak()
    };
}

# Memory profiling
fn memory_profile() {
    # Would return detailed memory info
    return memory();
}

# Garbage collection
fn gc() {
    # Would trigger garbage collection
    return _debug_gc();
}

# Profiler class
class Profiler {
    fn init(self) {
        self.data = {};
        self.running = false;
        self._start_time = null;
    }
    
    fn start(self) {
        self.running = true;
        self._start_time = time();
        return self;
    }
    
    fn stop(self) {
        self.running = false;
        return self;
    }
    
    fn record(self, name, duration) {
        if self.data[name] == null {
            self.data[name] = {count: 0, total: 0, min: 999999999, max: 0};
        }
        let entry = self.data[name];
        entry.count = entry.count + 1;
        entry.total = entry.total + duration;
        if duration < entry.min { entry.min = duration; }
        if duration > entry.max { entry.max = duration; }
    }
    
    fn report(self) {
        let results = [];
        for name in self.data {
            let entry = self.data[name];
            let avg = entry.total / entry.count;
            push(results, {
                name: name,
                count: entry.count,
                total: entry.total,
                avg: avg,
                min: entry.min,
                max: entry.max
            });
        }
        return results;
    }
    
    fn summary(self) {
        let report = self.report();
        print("=== Profiler Summary ===");
        for r in report {
            print(r.name + ":");
            print("  calls: " + str(r.count));
            print("  total: " + str(r.total));
            print("  avg: " + str(r.avg));
        }
    }
    
    fn sorted_by_total(self) {
        let report = self.report();
        # Simple sort by total
        for i in range(len(report)) {
            for j in range(i + 1, len(report)) {
                if report[j].total > report[i].total {
                    let temp = report[i];
                    report[i] = report[j];
                    report[j] = temp;
                }
            }
        }
        return report;
    }
}

# Simple profiler decorator
fn profile(fn_to_wrap) {
    return fn(...args) {
        let start = time();
        let result = fn_to_wrap(...args);
        let elapsed = time() - start;
        print("Profiled " + str(fn_to_wrap) + ": " + str(elapsed) + "s");
        return result;
    };
}

# Context manager for profiling
class ProfileContext {
    fn init(self, profiler, name) {
        self.profiler = profiler;
        self.name = name;
        self.start_time = null;
    }
    
    fn __enter__(self) {
        self.start_time = time();
        return self;
    }
    
    fn __exit__(self) {
        let elapsed = time() - self.start_time;
        self.profiler.record(self.name, elapsed);
    }
}

# Watch variable changes
class Watcher {
    fn init(self) {
        self.values = {};
    }
    
    fn watch(self, name, value) {
        let old = self.values[name];
        self.values[name] = value;
        if old != null && old != value {
            print("Watch: " + name + " changed from " + str(old) + " to " + str(value));
        }
    }
    
    fn get(self, name) {
        return self.values[name];
    }
    
    fn all(self) {
        return self.values;
    }
}

# Debug print (prints and returns)
fn dd(...values) {
    for v in values {
        print(inspect(v));
    }
    if len(values) == 1 {
        return values[0];
    }
    return values;
}

# Dump variable info
fn dump(name, value) {
    print("=== DUMP: " + name + " ===");
    print(inspect(value));
    return value;
}

# Deep dump
fn dump_deep(name, value, max_depth) {
    print("=== DEEP DUMP: " + name + " ===");
    print(deep_inspect(value, max_depth));
    return value;
}

# Measure execution time
fn measure(fn_to_measure) {
    let start = time();
    let result = fn_to_measure();
    let elapsed = time() - start;
    return {result: result, elapsed: elapsed};
}

# Timer for code blocks
class TimerBlock {
    fn init(self, name) {
        self.name = name;
        self.start_time = null;
        self.elapsed = null;
    }
    
    fn __enter__(self) {
        self.start_time = time();
        return self;
    }
    
    fn __exit__(self) {
        self.elapsed = time() - self.start_time;
        print("Timer '" + self.name + "': " + str(self.elapsed) + "s");
    }
}

# Stack frame info
fn frame_info() {
    return {
        file: "unknown",
        line: 0,
        function: "unknown"
    };
}

# Source context - get lines around a line number
fn source_context(filename, line, context) {
    if type(context) == "null" {
        context = 5;
    }
    
    # Would read file and extract context
    # This is a placeholder
    return {
        filename: filename,
        line: line,
        before: [],
        after: []
    };
}

# ===========================================
# Breakpoint Management
# ===========================================

# Breakpoint manager state
let _breakpoint_enabled = true;
let _breakpoint_count = 0;
let _watch_points = {};

# Enable/disable breakpoints
fn breakpoint_enable() {
    _breakpoint_enabled = true;
}

fn breakpoint_disable() {
    _breakpoint_enabled = false;
}

fn breakpoint_is_enabled() {
    return _breakpoint_enabled;
}

# Watch point - break when variable changes
fn watch_point(name, value) {
    if !_breakpoint_enabled {
        return;
    }
    
    let prev = _watch_points[name];
    _watch_points[name] = value;
    
    if prev != null && prev != value {
        print("Watch point triggered: " + name + " changed from " + str(prev) + " to " + str(value));
        breakpoint();
    }
}

# Breakpoint with message
fn breakpoint_msg(message) {
    if !_breakpoint_enabled {
        return;
    }
    
    print("[BREAKPOINT] " + message);
    print("  Stack trace:");
    
    let trace = _debug_trace();
    for i in 0..min(5, len(trace)) {
        print("    " + str(i) + ": " + str(trace[i]));
    }
    
    # Would pause execution in debug mode
    # _debug_pause();
}

# Conditional breakpoint with counter
fn breakpoint_after(n, message) {
    if !_breakpoint_enabled {
        return;
    }
    
    _breakpoint_count = _breakpoint_count + 1;
    
    if _breakpoint_count >= n {
        breakpoint_msg("After " + str(n) + " hits: " + message);
    }
}

# Break on error
fn breakpoint_on_error(fn_to_wrap) {
    return fn(...args) {
        let result = null;
        
        try {
            result = fn_to_wrap(...args);
        } catch e {
            print("Error in " + str(fn_to_wrap) + ": " + str(e));
            breakpoint();
            throw e;
        }
        
        return result;
    };
}

# Step-by-step debugging
let _step_mode = false;
let _step_count = 0;

fn step_enable() {
    _step_mode = true;
    _step_count = 0;
}

fn step_disable() {
    _step_mode = false;
}

fn step_next() {
    if _step_mode {
        _step_count = _step_count + 1;
        print("[STEP] Step " + str(_step_count));
    }
}

# Breakpoint with expression evaluation
fn breakpoint_eval(expr_fn) {
    if !_breakpoint_enabled {
        return;
    }
    
    let result = expr_fn();
    
    print("[BREAKPOINT] Expression result: " + str(result));
    
    # _debug_pause();
}

# Memory breakpoint - watch memory address
fn memory_watch(ptr, size) {
    let initial = _debug_read_memory(ptr, size);
    
    return fn() {
        let current = _debug_read_memory(ptr, size);
        
        if current != initial {
            print("[MEMORY] Memory changed at " + str(ptr));
            breakpoint();
        }
    };
}

# Breakpoint that logs state
fn breakpoint_log(state_fn, label) {
    if !_breakpoint_enabled {
        return;
    }
    
    let state = state_fn();
    
    print("[LOG] " + label + ":");
    print("  " + str(state));
    
    # Continue execution
}

# Exception breakpoint
fn breakpoint_on_exception(fn_to_wrap) {
    return fn(...args) {
        try {
            return fn_to_wrap(...args);
        } catch e {
            print("[EXCEPTION] " + str(e));
            print("Stack trace:");
            let trace = _debug_trace();
            for t in trace {
                print("  " + str(t));
            }
            breakpoint();
            throw e;
        }
    };
}

# Performance breakpoint - break after N milliseconds
let _perf_start_time = 0;

fn perf_start() {
    _perf_start_time = time();
}

fn perf_break_if_over(ms) {
    let elapsed = (time() - _perf_start_time) * 1000;
    
    if elapsed > ms {
        print("[PERF] Elapsed time " + str(elapsed) + "ms exceeds " + str(ms) + "ms");
        breakpoint();
    }
}

# Debug counter
let _debug_counter = 0;

fn counter_increment(label) {
    _debug_counter = _debug_counter + 1;
    
    if _debug_counter % 100 == 0 {
        print("[COUNTER] " + label + ": " + str(_debug_counter));
    }
}

# Breakpoint with local variable inspection
fn breakpoint_vars(...var_names) {
    if !_breakpoint_enabled {
        return;
    }
    
    print("[BREAKPOINT] Local variables:");
    
    for name in var_names {
        # Would access local variable by name
        # In real implementation, would inspect local scope
        print("  " + name + " = [local]");
    }
    
    # _debug_pause();
}

# Time-based breakpoint
let _time_breakpoints = {};

fn break_every_n_seconds(n) {
    let key = str(n);
    let last = _time_breakpoints[key];
    let now = time();
    
    if last == null || (now - last) >= n {
        _time_breakpoints[key] = now;
        breakpoint_msg("Every " + str(n) + " seconds");
    }
}

# Breakpoint on specific call count
fn break_on_call(n, fn_to_wrap) {
    let call_count = 0;
    
    return fn(...args) {
        call_count = call_count + 1;
        
        if call_count == n {
            breakpoint_msg("Call #" + str(n) + " of function");
        }
        
        return fn_to_wrap(...args);
    };
}

# Export enhanced breakpoint functions
export {
    trace, inspect,
    breakpoint, breakpoint_if, breakpoint_enable, breakpoint_disable, breakpoint_is_enabled,
    breakpoint_msg, breakpoint_after, breakpoint_on_error, breakpoint_eval,
    breakpoint_log, breakpoint_on_exception, breakpoint_vars,
    watch_point,
    step_enable, step_disable, step_next,
    perf_start, perf_break_if_over,
    counter_increment,
    memory_watch,
    break_every_n_seconds, break_on_call,
    dprint, trace_calls
};

# Error tracking
class ErrorTracker {
    fn init(self) {
        self.errors = [];
        self.counts = {};
    }
    
    fn track(self, error) {
        push(self.errors, {
            error: error,
            timestamp: time()
        });
        
        let key = str(error);
        if self.counts[key] == null {
            self.counts[key] = 0;
        }
        self.counts[key] = self.counts[key] + 1;
    }
    
    fn get_errors(self) {
        return self.errors;
    }
    
    fn get_counts(self) {
        return self.counts;
    }
    
    fn summary(self) {
        print("=== Error Summary ===");
        for k in self.counts {
            print(k + ": " + str(self.counts[k]));
        }
    }
}

# Benchmark function
fn benchmark(fn_to_benchmark, iterations) {
    if type(iterations) == "null" {
        iterations = 1000;
    }
    
    let times = [];
    
    for i in range(iterations) {
        let start = time();
        fn_to_benchmark();
        let elapsed = time() - start;
        push(times, elapsed);
    }
    
    # Calculate statistics
    let total = 0;
    let min_time = times[0];
    let max_time = times[0];
    
    for t in times {
        total = total + t;
        if t < min_time { min_time = t; }
        if t > max_time { max_time = t; }
    }
    
    let avg = total / len(times);
    
    # Calculate median
    let sorted = times[..];
    # Simple sort
    for i in range(len(sorted)) {
        for j in range(i + 1, len(sorted)) {
            if sorted[j] < sorted[i] {
                let temp = sorted[i];
                sorted[i] = sorted[j];
                sorted[j] = temp;
            }
        }
    }
    let median = sorted[len(sorted) / 2];
    
    return {
        iterations: iterations,
        total: total,
        avg: avg,
        min: min_time,
        max: max_time,
        median: median
    };
}

# Print benchmark results
fn benchmark_report(result) {
    print("=== Benchmark Results ===");
    print("Iterations: " + str(result.iterations));
    print("Total time: " + str(result.total) + "s");
    print("Average: " + str(result.avg * 1000) + "ms");
    print("Min: " + str(result.min * 1000) + "ms");
    print("Max: " + str(result.max * 1000) + "ms");
    print("Median: " + str(result.median * 1000) + "ms");
}

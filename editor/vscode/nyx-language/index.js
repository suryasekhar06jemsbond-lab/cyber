function assert(condition, message) {
    if (!condition) {
        throw new Error(`Assertion failed: ${message}`);
    }
    console.log(`PASS: ${message}`);
}

function assertEqual(actual, expected, message) {
    if (actual !== expected) {
        throw new Error(`Assertion failed: ${message} (Expected ${expected}, got ${actual})`);
    }
    console.log(`PASS: ${message}`);
}

module.exports = { assert, assertEqual };
const path = require('path');
const cryptoUsage = require('./usage'); // Runs the crypto usage (which is in root)
const math = require(path.join(__dirname, 'packages/nyx-math/index'));
const string = require(path.join(__dirname, 'packages/nyx-string/index'));
const fsPkg = require(path.join(__dirname, 'packages/nyx-fs/index'));
const jsonPkg = require(path.join(__dirname, 'packages/nyx-json/index'));
const testPkg = require(path.join(__dirname, 'packages/nyx-test/index'));
const netPkg = require(path.join(__dirname, 'packages/nyx-net/index'));
const datePkg = require(path.join(__dirname, 'packages/nyx-date/index'));
const colorPkg = require(path.join(__dirname, 'packages/nyx-color/index'));
const fs = require('fs');

console.log('\n--- Testing nyx-math ---');
const val = 15;
const clamped = math.clamp(val, 0, 10);
console.log(`clamp(${val}, 0, 10) = ${clamped} (Expected: 10)`);
if (clamped !== 10) throw new Error("Math clamp failed");

const lerped = math.lerp(0, 100, 0.5);
console.log(`lerp(0, 100, 0.5) = ${lerped} (Expected: 50)`);
if (lerped !== 50) throw new Error("Math lerp failed");

const mapped = math.map(50, 0, 100, 0, 1);
console.log(`map(50, 0, 100, 0, 1) = ${mapped} (Expected: 0.5)`);
if (mapped !== 0.5) throw new Error("Math map failed");

console.log('nyx-math tests passed.');

console.log('\n--- Testing nyx-string ---');
const hello = "hello";
const reversed = string.reverse(hello);
console.log(`reverse('${hello}') = '${reversed}' (Expected: 'olleh')`);
if (reversed !== 'olleh') throw new Error("String reverse failed");

const cap = string.capitalize(hello);
console.log(`capitalize('${hello}') = '${cap}' (Expected: 'Hello')`);
if (cap !== 'Hello') throw new Error("String capitalize failed");

const longStr = "Hello World";
const trunc = string.truncate(longStr, 5);
console.log(`truncate('${longStr}', 5) = '${trunc}' (Expected: 'He...')`);
if (trunc !== 'He...') throw new Error("String truncate failed");

console.log('nyx-string tests passed.');

console.log('\n--- Testing nyx-json ---');
const jsonObj = { a: 1, b: "test" };
const jsonStr = jsonPkg.stringify(jsonObj);
console.log(`JSON Stringify: ${jsonStr.replace(/\n/g, '')}`);
const parsed = jsonPkg.parse(jsonStr);
if (parsed.a !== 1) throw new Error("JSON parse failed");
console.log('nyx-json tests passed.');

console.log('\n--- Testing nyx-fs ---');
const testFile = 'test_fs.txt';
fsPkg.writeFile(testFile, 'nyx content');
if (!fsPkg.exists(testFile)) throw new Error("FS write/exists failed");
const content = fsPkg.readFile(testFile);
if (content !== 'nyx content') throw new Error("FS read failed");
fsPkg.remove(testFile); // Cleanup
console.log('nyx-fs tests passed.');

testPkg.assertEqual(1 + 1, 2, "Basic arithmetic");

console.log('\n--- Testing nyx-date ---');
const nowStr = datePkg.now();
console.log(`Now: ${nowStr}`);
const fmtDate = datePkg.format(nowStr, 'YYYY-MM-DD');
console.log(`Formatted: ${fmtDate}`);
if (!fmtDate.match(/^\d{4}-\d{2}-\d{2}$/)) throw new Error("Date format failed");

const nextDay = datePkg.addDays(nowStr, 1);
console.log(`addDays(now, 1): ${nextDay}`);
if (nextDay === nowStr) throw new Error("Date addDays failed");

console.log('\n--- Testing nyx-color ---');
const rgb = colorPkg.hexToRgb('#ffffff');
if (rgb.r !== 255) throw new Error("Color hexToRgb failed");
console.log(`hexToRgb('#ffffff') = ${JSON.stringify(rgb)}`);

console.log('\n--- Testing nyx-net ---');
netPkg.post('https://jsonplaceholder.typicode.com/posts', { title: 'nyx', body: 'test', userId: 1 }).then(res => {
    if (res.status !== 201) throw new Error(`Net POST failed with status ${res.status}`);
    console.log('nyx-net tests passed.');
    console.log('\nAll packages tested successfully.');
}).catch(err => {
    console.error(err);
    process.exit(1);
});
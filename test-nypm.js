const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const nypmPath = path.join(__dirname, 'nypm.js');
const registryPath = path.join(__dirname, 'packages');
const testDir = path.join(os.tmpdir(), 'nypm-test-' + Date.now());
const testPkgName = `nyx-test-pkg-${Date.now()}`;

console.log(`--- Starting Full NYPM Test Suite ---`);
console.log(`Test Workspace: ${testDir}`);

try {
    if (!fs.existsSync(testDir)) fs.mkdirSync(testDir);

    const run = (cmd) => {
        console.log(`\n> nypm ${cmd}`);
        return execSync(`node "${nypmPath}" ${cmd}`, { cwd: testDir, encoding: 'utf8' });
    };

    // 1. Init
    run('init');
    if (!fs.existsSync(path.join(testDir, 'package.json'))) throw new Error('Init failed');

    // 2. Create and Publish a test package
    const pkgDir = path.join(testDir, testPkgName);
    fs.mkdirSync(pkgDir);
    fs.writeFileSync(path.join(pkgDir, 'package.json'), JSON.stringify({ name: testPkgName, version: '1.0.0' }));
    fs.writeFileSync(path.join(pkgDir, 'index.js'), 'module.exports = "hello";');
    
    console.log(`\n> nypm publish (custom package)`);
    execSync(`node "${nypmPath}" publish "${pkgDir}"`, { cwd: testDir, encoding: 'utf8' });
    
    if (!fs.existsSync(path.join(registryPath, testPkgName))) throw new Error('Publish failed');

    // 3. Search
    const searchOut = run(`search ${testPkgName}`);
    if (!searchOut.includes(testPkgName)) throw new Error('Search failed');

    // 4. Install
    run(`install ${testPkgName}`);
    if (!fs.existsSync(path.join(testDir, 'nyx_modules', testPkgName))) throw new Error('Install failed');

    // 5. List
    const listOut = run('list');
    if (!listOut.includes(testPkgName)) throw new Error('List failed');

    // 6. Doctor
    const doctorOut = run('doctor');
    if (!doctorOut.includes('✅')) throw new Error('Doctor failed');

    // 7. Remove
    run(`remove ${testPkgName}`);
    if (fs.existsSync(path.join(testDir, 'nyx_modules', testPkgName))) throw new Error('Remove failed');

    // 8. Update (re-install from manifest)
    // Add dependency back manually to test update/install-all
    const pkgJsonPath = path.join(testDir, 'package.json');
    const pkgJson = JSON.parse(fs.readFileSync(pkgJsonPath));
    pkgJson.dependencies = { [testPkgName]: '^1.0.0' };
    fs.writeFileSync(pkgJsonPath, JSON.stringify(pkgJson));
    
    run('update');
    if (!fs.existsSync(path.join(testDir, 'nyx_modules', testPkgName))) throw new Error('Update failed');

    // 9. Clean
    run('clean');
    if (fs.existsSync(path.join(testDir, 'nyx_modules'))) throw new Error('Clean failed');

    console.log('\n--- SUCCESS: All tests passed ---');

} catch (e) {
    console.error('\nTEST FAILED:', e.message);
    if (e.stdout) console.log(e.stdout);
    if (e.stderr) console.error(e.stderr);
    process.exit(1);
} finally {
    // Cleanup registry
    const regPkgPath = path.join(registryPath, testPkgName);
    if (fs.existsSync(regPkgPath)) {
        fs.rmSync(regPkgPath, { recursive: true, force: true });
    }
    // Cleanup temp dir
    try {
        fs.rmSync(testDir, { recursive: true, force: true });
    } catch (e) {}
}
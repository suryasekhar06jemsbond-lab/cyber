const fs = require('fs');
const path = require('path');

const packagesDir = path.join(__dirname, '..', 'packages');

if (!fs.existsSync(packagesDir)) {
    fs.mkdirSync(packagesDir, { recursive: true });
}

console.log('Generating 1000 packages...');

for (let i = 1; i <= 1000; i++) {
    const pkgName = `nyx-pkg-${String(i).padStart(4, '0')}`;
    const pkgDir = path.join(packagesDir, pkgName);

    if (!fs.existsSync(pkgDir)) {
        fs.mkdirSync(pkgDir);
    }

    const packageJson = {
        name: pkgName,
        version: "1.0.0",
        main: "index.js",
        description: `Auto-generated package ${pkgName}`,
        license: "MIT"
    };

    fs.writeFileSync(path.join(pkgDir, 'package.json'), JSON.stringify(packageJson, null, 2));

    const indexJs = `
function hello() {
    return "Hello from ${pkgName}";
}

function add(a, b) {
    return a + b;
}

module.exports = { hello, add };
`;
    fs.writeFileSync(path.join(pkgDir, 'index.js'), indexJs.trim());
}

console.log('Done! 1000 packages generated in ' + packagesDir);
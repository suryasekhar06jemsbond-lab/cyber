#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const REGISTRY_PATH = path.join(__dirname, 'packages');
const MODULES_DIR = 'nyx_modules';

const args = process.argv.slice(2);
const command = args[0];
const param1 = args[1];

if (!command) {
    console.log('Usage: nypm <command> [args]');
    process.exit(1);
}

switch (command) {
    case 'init':
        init();
        break;
    case 'install':
        install(param1);
        break;
    case 'search':
        search(param1);
        break;
    case 'list':
        list();
        break;
    case 'publish':
        publish(param1);
        break;
    case 'remove':
        remove(param1);
        break;
    case 'update':
        update(param1);
        break;
    case 'clean':
        clean();
        break;
    case 'doctor':
        doctor();
        break;
    default:
        console.log(`Unknown command: ${command}`);
        process.exit(1);
}

function init() {
    const pkgPath = path.join(process.cwd(), 'package.json');
    if (fs.existsSync(pkgPath)) {
        console.log('package.json already exists.');
        return;
    }
    const defaultPkg = {
        name: path.basename(process.cwd()),
        version: '1.0.0',
        dependencies: {}
    };
    fs.writeFileSync(pkgPath, JSON.stringify(defaultPkg, null, 2));
    console.log('Created package.json');
}

function install(packageName) {
    const modulesPath = path.join(process.cwd(), MODULES_DIR);
    if (!fs.existsSync(modulesPath)) {
        fs.mkdirSync(modulesPath, { recursive: true });
    }

    if (packageName) {
        installPackage(packageName, modulesPath);
        addToManifest(packageName);
    } else {
        installFromManifest(modulesPath);
    }
}

function search(query) {
    if (!query) {
        console.log('Usage: nypm search <query>');
        return;
    }
    if (!fs.existsSync(REGISTRY_PATH)) {
        console.error('Registry not found at ' + REGISTRY_PATH);
        return;
    }
    const packages = fs.readdirSync(REGISTRY_PATH);
    const matches = packages.filter(p => p.includes(query));
    if (matches.length === 0) {
        console.log('No packages found.');
    } else {
        matches.forEach(p => console.log(p));
    }
}

function list() {
    const modulesPath = path.join(process.cwd(), MODULES_DIR);
    if (!fs.existsSync(modulesPath)) {
        console.log('No packages installed.');
        return;
    }
    const installed = fs.readdirSync(modulesPath);
    if (installed.length === 0) {
        console.log('No packages installed.');
    } else {
        installed.forEach(p => console.log(p));
    }
}

function publish(packagePath) {
    if (!packagePath) {
        console.log('Usage: nypm publish <path>');
        return;
    }
    const absPath = path.resolve(packagePath);
    if (!fs.existsSync(absPath)) {
        console.error(`Path not found: ${absPath}`);
        return;
    }

    const pkgJsonPath = path.join(absPath, 'package.json');
    if (!fs.existsSync(pkgJsonPath)) {
        console.error(`No package.json found in ${absPath}`);
        return;
    }

    let pkg;
    try {
        pkg = JSON.parse(fs.readFileSync(pkgJsonPath, 'utf8'));
    } catch (e) {
        console.error('Failed to parse package.json');
        return;
    }

    if (!pkg.name) {
        console.error('package.json must have a name');
        return;
    }

    const destPath = path.join(REGISTRY_PATH, pkg.name);
    if (!fs.existsSync(REGISTRY_PATH)) {
        fs.mkdirSync(REGISTRY_PATH, { recursive: true });
    }

    console.log(`Publishing ${pkg.name} to registry...`);
    try {
        if (fs.cpSync) {
            fs.cpSync(absPath, destPath, { recursive: true });
        } else {
            copyRecursiveSync(absPath, destPath);
        }
        console.log(`Published ${pkg.name}`);
    } catch (e) {
        console.error(`Failed to publish ${pkg.name}: ${e.message}`);
    }
}

function remove(packageName) {
    if (!packageName) {
        console.log('Usage: nypm remove <package>');
        return;
    }
    const modulesPath = path.join(process.cwd(), MODULES_DIR);
    const packagePath = path.join(modulesPath, packageName);

    if (fs.existsSync(packagePath)) {
        if (fs.rmSync) {
            fs.rmSync(packagePath, { recursive: true, force: true });
        } else {
            fs.rmdirSync(packagePath, { recursive: true });
        }
        console.log(`Removed ${packageName} from ${MODULES_DIR}`);
    } else {
        console.log(`Package ${packageName} not found in ${MODULES_DIR}`);
    }

    removeFromManifest(packageName);
}

function update(packageName) {
    const modulesPath = path.join(process.cwd(), MODULES_DIR);
    if (!fs.existsSync(modulesPath)) {
        fs.mkdirSync(modulesPath, { recursive: true });
    }

    if (packageName) {
        installPackage(packageName, modulesPath);
    } else {
        installFromManifest(modulesPath);
    }
}

function clean() {
    const modulesPath = path.join(process.cwd(), MODULES_DIR);
    if (fs.existsSync(modulesPath)) {
        if (fs.rmSync) {
            fs.rmSync(modulesPath, { recursive: true, force: true });
        } else {
            fs.rmdirSync(modulesPath, { recursive: true });
        }
        console.log('Cleaned nyx_modules.');
    } else {
        console.log('Nothing to clean.');
    }
}

function doctor() {
    console.log('Running Nyx Doctor...');
    let issues = 0;

    if (fs.existsSync(REGISTRY_PATH)) {
        console.log('✅ Registry found at ' + REGISTRY_PATH);
    } else {
        console.log('❌ Registry not found at ' + REGISTRY_PATH);
        issues++;
    }

    const pkgPath = path.join(process.cwd(), 'package.json');
    if (fs.existsSync(pkgPath)) {
        console.log('✅ package.json found.');
        try {
            const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
            if (!pkg.name) {
                console.log('⚠️  package.json missing "name" field.');
                issues++;
            }
            
            if (pkg.dependencies) {
                const modulesPath = path.join(process.cwd(), MODULES_DIR);
                const missing = Object.keys(pkg.dependencies).filter(dep => !fs.existsSync(path.join(modulesPath, dep)));
                
                if (missing.length > 0) {
                    console.log('❌ Missing dependencies in nyx_modules: ' + missing.join(', '));
                    issues++;
                } else {
                    console.log('✅ All dependencies appear to be installed.');
                }
            }
        } catch (e) {
            console.log('❌ package.json is invalid JSON.');
            issues++;
        }
    } else {
        console.log('ℹ️  No package.json in current directory.');
    }

    if (fs.existsSync(path.join(process.cwd(), MODULES_DIR))) {
        console.log('✅ nyx_modules directory exists.');
    }

    console.log(`\nDoctor finished with ${issues} issue(s).`);
}

function installPackage(name, dest) {
    const srcPath = path.join(REGISTRY_PATH, name);
    const destPath = path.join(dest, name);

    if (!fs.existsSync(srcPath)) {
        console.error(`Package '${name}' not found in registry.`);
        return;
    }

    console.log(`Installing ${name}...`);
    try {
        if (fs.cpSync) {
            fs.cpSync(srcPath, destPath, { recursive: true });
        } else {
            copyRecursiveSync(srcPath, destPath);
        }
        console.log(`Installed ${name}`);
    } catch (e) {
        console.error(`Failed to install ${name}: ${e.message}`);
    }
}

function installFromManifest(dest) {
    const pkgPath = path.join(process.cwd(), 'package.json');
    if (!fs.existsSync(pkgPath)) {
        console.error('No package.json found.');
        return;
    }
    let pkg;
    try {
        pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    } catch (e) {
        console.error('Failed to parse package.json');
        return;
    }
    
    const deps = pkg.dependencies || {};
    Object.keys(deps).forEach(dep => {
        installPackage(dep, dest);
    });
}

function addToManifest(name) {
    const pkgPath = path.join(process.cwd(), 'package.json');
    let pkg = {};
    if (fs.existsSync(pkgPath)) {
        try {
            pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
        } catch (e) {
            // ignore error, start fresh or partial
        }
    } else {
        pkg = { name: path.basename(process.cwd()), version: '1.0.0', dependencies: {} };
    }
    
    if (!pkg.dependencies) pkg.dependencies = {};
    pkg.dependencies[name] = '^1.0.0'; // Default version assumption
    fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2));
}

function removeFromManifest(name) {
    const pkgPath = path.join(process.cwd(), 'package.json');
    if (!fs.existsSync(pkgPath)) {
        return;
    }

    let pkg;
    try {
        pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    } catch (e) {
        console.error('Failed to parse package.json');
        return;
    }

    if (pkg.dependencies && pkg.dependencies[name]) {
        delete pkg.dependencies[name];
        fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2));
        console.log(`Removed ${name} from package.json`);
    }
}

function copyRecursiveSync(src, dest) {
    const exists = fs.existsSync(src);
    const stats = exists && fs.statSync(src);
    const isDirectory = exists && stats.isDirectory();

    if (isDirectory) {
        if (!fs.existsSync(dest)) {
            fs.mkdirSync(dest);
        }
        fs.readdirSync(src).forEach(childItemName => {
            copyRecursiveSync(path.join(src, childItemName), path.join(dest, childItemName));
        });
    } else {
        fs.copyFileSync(src, dest);
    }
}
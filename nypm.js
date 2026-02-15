#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const https = require('https');
const { URL } = require('url');

const REGISTRY_PATH = path.join(__dirname, 'packages');
const MODULES_DIR = 'nyx_modules';
const OFFICIAL_REGISTRY = 'https://registry.nyxlang.dev';
const LOCK_FILE = 'ny.lock';

// Version resolution constants
const VERSION_RANGE_REGEX = /^(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z0-9.-]+))?$/;
const CARET_REGEX = /\^(\d+\.\d+\.\d+)/;
const TILDE_REGEX = /~(\d+\.\d+)/;
const RANGE_REGEX = /(\d+\.\d+\.\d+)\s*-\s*(\d+\.\d+\.\d+)/;

const args = process.argv.slice(2);
const command = args[0];
const param1 = args[1];
const param2 = args[2];

if (!command) {
    console.log('Usage: nypm <command> [args]');
    console.log('Commands:');
    console.log('  init              Initialize new package');
    console.log('  install [pkg]     Install package(s)');
    console.log('  search <query>    Search registry');
    console.log('  list              List installed packages');
    console.log('  publish <path>    Publish package');
    console.log('  remove <pkg>      Remove package');
    console.log('  update [pkg]      Update package(s)');
    console.log('  clean             Clean modules');
    console.log('  doctor            Check setup');
    console.log('  info <pkg>        Package information');
    console.log('  versions <pkg>    List package versions');
    console.log('  outdated          Check for updates');
    console.log('  add <pkg@ver>     Add specific version');
    process.exit(1);
}

switch (command) {
    case 'init':
        init();
        break;
    case 'install':
    case 'add':
        install(param1, param2);
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
    case 'rm':
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
    case 'info':
        info(param1);
        break;
    case 'versions':
        listVersions(param1);
        break;
    case 'outdated':
        outdated();
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

function install(packageName, version) {
    const modulesPath = path.join(process.cwd(), MODULES_DIR);
    if (!fs.existsSync(modulesPath)) {
        fs.mkdirSync(modulesPath, { recursive: true });
    }

    if (packageName) {
        // Handle package@version format
        if (packageName.includes('@') && !version) {
            const parts = packageName.split('@');
            packageName = parts[0];
            version = parts.slice(1).join('@');
        }
        installWithVersion(packageName + (version ? '@' + version : ''), modulesPath);
        addToManifest(packageName, version);
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

function addToManifest(name, version) {
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
    const versionRange = version || '^1.0.0';
    pkg.dependencies[name] = versionRange;
    fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2));
    
    // Update lock file
    saveLockFile(pkg.dependencies);
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

// ========== Version Resolution ==========

function parseVersion(version) {
    const match = version.match(VERSION_RANGE_REGEX);
    if (!match) return null;
    return {
        major: parseInt(match[1]),
        minor: parseInt(match[2]),
        patch: parseInt(match[3]),
        prerelease: match[4] || null,
        full: version
    };
}

function compareVersions(a, b) {
    const vA = parseVersion(a);
    const vB = parseVersion(b);
    if (!vA || !vB) return 0;

    if (vA.major !== vB.major) return vA.major - vB.major;
    if (vA.minor !== vB.minor) return vA.minor - vB.minor;
    if (vA.patch !== vB.patch) return vA.patch - vB.patch;
    
    // Pre-release versions have lower priority
    if (vA.prerelease && !vB.prerelease) return -1;
    if (!vA.prerelease && vB.prerelease) return 1;
    if (vA.prerelease && vB.prerelease) return vA.prerelease.localeCompare(vB.prerelease);
    
    return 0;
}

function satisfiesRange(version, range) {
    const v = parseVersion(version);
    if (!v) return false;

    // Handle exact version
    if (!range.includes('^') && !range.includes('~') && !range.includes('-')) {
        return version === range;
    }

    // Handle caret ^x.y.z - compatible with x.y.z
    const caretMatch = range.match(CARET_REGEX);
    if (caretMatch) {
        const base = parseVersion(caretMatch[1]);
        if (!base) return false;
        return v.major === base.major && 
               (v.minor > base.minor || (v.minor === base.minor && v.patch >= base.patch));
    }

    // Handle tilde ~x.y.z - compatible with x.y
    const tildeMatch = range.match(TILDE_REGEX);
    if (tildeMatch) {
        const base = parseVersion(tildeMatch[1] + '.0');
        if (!base) return false;
        return v.major === base.major && v.minor === base.minor && v.patch >= base.patch;
    }

    // Handle range x.y.z - a.b
    const rangeMatch = range.match(RANGE_REGEX);
    if (rangeMatch) {
        const min = parseVersion(rangeMatch[1]);
        const max = parseVersion(rangeMatch[2]);
        if (!min || !max) return false;
        return compareVersions(version, min.full) >= 0 && compareVersions(version, max.full) <= 0;
    }

    return false;
}

function resolveVersion(packageName, range, availableVersions) {
    if (!availableVersions || availableVersions.length === 0) {
        // Fallback to local registry
        const localPath = path.join(REGISTRY_PATH, packageName, 'package.json');
        if (fs.existsSync(localPath)) {
            const pkg = JSON.parse(fs.readFileSync(localPath, 'utf8'));
            return pkg.version || '1.0.0';
        }
        return '1.0.0';
    }

    // Sort versions semantically
    const sorted = [...availableVersions].sort(compareVersions).reverse();

    // Find satisfying version
    for (const v of sorted) {
        if (satisfiesRange(v, range)) {
            return v;
        }
    }

    return sorted[0] || '1.0.0';
}

// ========== New Commands ==========

function info(packageName) {
    if (!packageName) {
        console.log('Usage: nypm info <package>');
        return;
    }

    // Try local registry first
    const localPath = path.join(REGISTRY_PATH, packageName, 'package.json');
    if (fs.existsSync(localPath)) {
        const pkg = JSON.parse(fs.readFileSync(localPath, 'utf8'));
        console.log(`Name: ${pkg.name}`);
        console.log(`Version: ${pkg.version}`);
        console.log(`Description: ${pkg.description || 'N/A'}`);
        console.log(`Author: ${pkg.author || 'N/A'}`);
        console.log(`Repository: ${pkg.repository || 'N/A'}`);
        console.log(`License: ${pkg.license || 'N/A'}`);
        console.log(`Dependencies: ${Object.keys(pkg.dependencies || {}).join(', ') || 'None'}`);
        return;
    }

    // Try official registry
    fetchPackageFromRegistry(packageName, (err, pkg) => {
        if (err) {
            console.log(`Package '${packageName}' not found.`);
            return;
        }
        console.log(`Name: ${pkg.name}`);
        console.log(`Version: ${pkg.version}`);
        console.log(`Description: ${pkg.description || 'N/A'}`);
        console.log(`Author: ${pkg.author || 'N/A'}`);
        console.log(`Repository: ${pkg.repository || 'N/A'}`);
        console.log(`License: ${pkg.license || 'N/A'}`);
        console.log(`Dependencies: ${Object.keys(pkg.dependencies || {}).join(', ') || 'None'}`);
    });
}

function listVersions(packageName) {
    if (!packageName) {
        console.log('Usage: nypm versions <package>');
        return;
    }

    // Try local registry
    const localPath = path.join(REGISTRY_PATH, packageName);
    if (fs.existsSync(localPath)) {
        const versionsPath = path.join(localPath, 'versions.json');
        if (fs.existsSync(versionsPath)) {
            const versions = JSON.parse(fs.readFileSync(versionsPath, 'utf8'));
            console.log(`Available versions for ${packageName}:`);
            versions.forEach(v => console.log(`  ${v}`));
            return;
        }
        // Single version
        const pkgPath = path.join(localPath, 'package.json');
        if (fs.existsSync(pkgPath)) {
            const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
            console.log(`  ${pkg.version}`);
            return;
        }
    }

    console.log(`No versions found for ${packageName}`);
}

function outdated() {
    const pkgPath = path.join(process.cwd(), 'package.json');
    if (!fs.existsSync(pkgPath)) {
        console.log('No package.json found.');
        return;
    }

    let pkg;
    try {
        pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    } catch (e) {
        console.log('Invalid package.json');
        return;
    }

    const deps = pkg.dependencies || {};
    if (Object.keys(deps).length === 0) {
        console.log('No dependencies found.');
        return;
    }

    console.log('Checking for outdated packages...');
    let hasOutdated = false;

    for (const [name, range] of Object.entries(deps)) {
        const localPath = path.join(process.cwd(), MODULES_DIR, name, 'package.json');
        let currentVersion = 'unknown';
        
        if (fs.existsSync(localPath)) {
            const localPkg = JSON.parse(fs.readFileSync(localPath, 'utf8'));
            currentVersion = localPkg.version || 'unknown';
        }

        // Check for latest version
        const resolved = resolveVersion(name, range, []);
        if (currentVersion !== 'unknown' && resolved !== currentVersion) {
            console.log(`${name}: ${currentVersion} -> ${resolved} (wanted: ${range})`);
            hasOutdated = true;
        }
    }

    if (!hasOutdated) {
        console.log('All packages are up to date.');
    }
}

// ========== Registry Functions ==========

function fetchPackageFromRegistry(packageName, callback) {
    try {
        const url = new URL(`${OFFICIAL_REGISTRY}/${packageName}`);
        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const pkg = JSON.parse(data);
                    callback(null, pkg);
                } catch (e) {
                    callback(new Error('Invalid response'), null);
                }
            });
        }).on('error', (err) => {
            callback(err, null);
        });
    } catch (e) {
        callback(e, null);
    }
}

function installWithVersion(packageSpec, dest) {
    // Parse package@version
    let packageName = packageSpec;
    let versionRange = '^1.0.0';

    if (packageSpec.includes('@')) {
        const parts = packageSpec.split('@');
        packageName = parts[0];
        versionRange = parts[1] || '^1.0.0';
    }

    // Try local registry first
    const localPath = path.join(REGISTRY_PATH, packageName);
    
    if (fs.existsSync(localPath)) {
        const pkgPath = path.join(localPath, 'package.json');
        if (fs.existsSync(pkgPath)) {
            const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
            const resolved = resolveVersion(packageName, versionRange, [pkg.version]);
            const destPath = path.join(dest, packageName);
            
            console.log(`Installing ${packageName}@${resolved} from local registry...`);
            
            if (!fs.existsSync(dest)) {
                fs.mkdirSync(dest, { recursive: true });
            }
            
            if (fs.cpSync) {
                fs.cpSync(localPath, destPath, { recursive: true });
            } else {
                copyRecursiveSync(localPath, destPath);
            }
            return;
        }
    }

    // Try official registry
    fetchPackageFromRegistry(packageName, (err, pkg) => {
        if (err) {
            console.error(`Package '${packageName}' not found in registry.`);
            return;
        }

        const resolved = resolveVersion(packageName, versionRange, pkg.versions || [pkg.version]);
        console.log(`Installing ${packageName}@${resolved} from official registry...`);
        
        // In a real implementation, we would download the specific version
        // For now, just note the installation
        console.log(`Note: Remote package installation requires full registry implementation`);
    });
}

function saveLockFile(dependencies) {
    const lock = {
        version: '1.0.0',
        resolved: {},
        dependencies: {}
    };

    for (const [name, range] of Object.entries(dependencies)) {
        const resolved = resolveVersion(name, range, []);
        lock.resolved[name] = resolved;
        lock.dependencies[name] = { version: resolved };
    }

    fs.writeFileSync(path.join(process.cwd(), LOCK_FILE), JSON.stringify(lock, null, 2));
}

function loadLockFile() {
    const lockPath = path.join(process.cwd(), LOCK_FILE);
    if (fs.existsSync(lockPath)) {
        return JSON.parse(fs.readFileSync(lockPath, 'utf8'));
    }
    return null;
}
#!/usr/bin/env node
const fs = require('fs');
const { program } = require('commander');
const { encrypt, decrypt, hashString, hashPassword, verifyPassword, generateRandomKey, hmacString, generateKeyPair, publicEncrypt, privateDecrypt, sign, verify, generateUUID } = require('./index');

program
    .name('nyx-crypto')
    .description('CLI for Nyx Cryptography Utilities')
    .version('1.0.0');

program
    .command('encrypt')
    .description('Encrypt a text string')
    .argument('<text>', 'Text to encrypt')
    .argument('<password>', 'Master password')
    .action((text, password) => {
        const result = encrypt(text, password);
        console.log(JSON.stringify(result, null, 2));
    });

program
    .command('decrypt')
    .description('Decrypt data')
    .argument('<encryptedData>', 'Encrypted data (hex)')
    .argument('<password>', 'Master password')
    .argument('<iv>', 'Initialization Vector (hex)')
    .argument('<salt>', 'Salt (hex)')
    .argument('<tag>', 'Auth Tag (hex)')
    .action((encryptedData, password, iv, salt, tag) => {
        try {
            const result = decrypt(encryptedData, password, iv, salt, tag);
            console.log(result);
        } catch (error) {
            console.error('Decryption failed:', error.message);
            process.exit(1);
        }
    });

program
    .command('hash')
    .description('Hash a string using SHA-256')
    .argument('<text>', 'Text to hash')
    .action((text) => {
        console.log(hashString(text));
    });

program
    .command('hmac')
    .description('Create a HMAC of a string')
    .argument('<text>', 'Text to hash')
    .argument('<secret>', 'Secret key')
    .action((text, secret) => {
        console.log(hmacString(text, secret));
    });

program
    .command('generate-key')
    .description('Generate a random secure key')
    .option('-l, --length <number>', 'Length of the key in bytes', '32')
    .action((options) => {
        console.log(generateRandomKey(parseInt(options.length)));
    });

program
    .command('hash-password')
    .description('Hash a password securely')
    .argument('<password>', 'Password to hash')
    .action((password) => {
        const result = hashPassword(password);
        console.log(JSON.stringify(result, null, 2));
    });

program
    .command('verify-password')
    .description('Verify a password against a hash')
    .argument('<password>', 'Password to verify')
    .argument('<salt>', 'Salt (hex)')
    .argument('<hash>', 'Hash (hex)')
    .action((password, salt, hash) => {
        const isMatch = verifyPassword(password, salt, hash);
        console.log(isMatch ? 'Valid' : 'Invalid');
        if (!isMatch) process.exit(1);
    });

program
    .command('uuid')
    .description('Generate a UUID v4')
    .action(() => {
        console.log(generateUUID());
    });

program
    .command('gen-keypair')
    .description('Generate RSA key pair and save to files')
    .option('-o, --out <dir>', 'Output directory', '.')
    .action((options) => {
        const { publicKey, privateKey } = generateKeyPair();
        const dir = options.out;
        if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
        fs.writeFileSync(`${dir}/public.pem`, publicKey);
        fs.writeFileSync(`${dir}/private.pem`, privateKey);
        console.log(`Keys saved to ${dir}/public.pem and ${dir}/private.pem`);
    });

program
    .command('asym-encrypt')
    .description('Encrypt text using a public key file')
    .argument('<text>', 'Text to encrypt')
    .argument('<keyFile>', 'Path to public key file')
    .action((text, keyFile) => {
        const key = fs.readFileSync(keyFile, 'utf8');
        console.log(publicEncrypt(text, key));
    });

program
    .command('asym-decrypt')
    .description('Decrypt text using a private key file')
    .argument('<encrypted>', 'Base64 encrypted string')
    .argument('<keyFile>', 'Path to private key file')
    .action((encrypted, keyFile) => {
        const key = fs.readFileSync(keyFile, 'utf8');
        console.log(privateDecrypt(encrypted, key));
    });

program
    .command('sign')
    .description('Sign text using a private key file')
    .argument('<text>', 'Text to sign')
    .argument('<keyFile>', 'Path to private key file')
    .action((text, keyFile) => {
        const key = fs.readFileSync(keyFile, 'utf8');
        console.log(sign(text, key));
    });

program
    .command('verify')
    .description('Verify a signature using a public key file')
    .argument('<text>', 'Original text')
    .argument('<signature>', 'Signature to verify')
    .argument('<keyFile>', 'Path to public key file')
    .action((text, signature, keyFile) => {
        const key = fs.readFileSync(keyFile, 'utf8');
        console.log(verify(text, signature, key) ? 'Valid' : 'Invalid');
    });

program.parse();
const { encrypt, decrypt, hashString, hashPassword, verifyPassword, hmacString, generateRandomKey, generateKeyPair, publicEncrypt, privateDecrypt, sign, verify, generateUUID } = require('./index');

console.log('--- Encryption Test ---');
const secretMessage = "Hello Nyx Developers!";
const password = "super-secret-key";

console.log(`Original: ${secretMessage}`);
const encrypted = encrypt(secretMessage, password);
console.log(`Encrypted: ${encrypted.encryptedData}`);

const decrypted = decrypt(
    encrypted.encryptedData, 
    password, 
    encrypted.iv, 
    encrypted.salt, 
    encrypted.tag
);
console.log(`Decrypted: ${decrypted}`);

console.log('\n--- Hashing Test ---');
const textToHash = "nyx-language";
console.log(`SHA256 of '${textToHash}': ${hashString(textToHash)}`);

console.log('\n--- Password Verification ---');
const userPass = "myUserPassword123";
const stored = hashPassword(userPass);
const isMatch = verifyPassword(userPass, stored.salt, stored.hash);
console.log(`Password match: ${isMatch}`);

console.log('\n--- HMAC Test ---');
console.log(`HMAC: ${hmacString('some-data', 'secret-key')}`);

console.log('\n--- Key Generation ---');
console.log(`Random Key: ${generateRandomKey()}`);

console.log('\n--- Asymmetric Crypto Test ---');
const keys = generateKeyPair();
console.log('Keys generated.');

const asymEncrypted = publicEncrypt("Secret Data", keys.publicKey);
console.log(`Asym Encrypted (truncated): ${asymEncrypted.substring(0, 30)}...`);

const asymDecrypted = privateDecrypt(asymEncrypted, keys.privateKey);
console.log(`Asym Decrypted: ${asymDecrypted}`);

const signature = sign("Important Doc", keys.privateKey);
console.log(`Signature Valid: ${verify("Important Doc", signature, keys.publicKey)}`);

console.log(`\nUUID: ${generateUUID()}`);
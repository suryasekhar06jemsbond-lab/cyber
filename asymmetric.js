const crypto = require('crypto');

function generateKeyPair() {
    return crypto.generateKeyPairSync('rsa', {
        modulusLength: 4096,
        publicKeyEncoding: {
            type: 'spki',
            format: 'pem'
        },
        privateKeyEncoding: {
            type: 'pkcs8',
            format: 'pem'
        }
    });
}

function publicEncrypt(text, publicKey) {
    const buffer = Buffer.from(text, 'utf8');
    const encrypted = crypto.publicEncrypt(publicKey, buffer);
    return encrypted.toString('base64');
}

function privateDecrypt(encryptedBase64, privateKey) {
    const buffer = Buffer.from(encryptedBase64, 'base64');
    const decrypted = crypto.privateDecrypt(privateKey, buffer);
    return decrypted.toString('utf8');
}

function sign(text, privateKey) {
    const sign = crypto.createSign('SHA256');
    sign.update(text);
    sign.end();
    return sign.sign(privateKey, 'base64');
}

function verify(text, signatureBase64, publicKey) {
    const verify = crypto.createVerify('SHA256');
    verify.update(text);
    verify.end();
    return verify.verify(publicKey, signatureBase64, 'base64');
}

module.exports = { generateKeyPair, publicEncrypt, privateDecrypt, sign, verify };
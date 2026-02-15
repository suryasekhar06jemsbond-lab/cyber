const crypto = require('crypto');

function hashString(text) {
    return crypto.createHash('sha256').update(text).digest('hex');
}

function hmacString(text, secret) {
    return crypto.createHmac('sha256', secret).update(text).digest('hex');
}

function hashPassword(password) {
    const salt = crypto.randomBytes(16).toString('hex');
    // Use scrypt for better security
    const hash = crypto.scryptSync(password, salt, 64).toString('hex');
    return { salt, hash };
}

function verifyPassword(password, salt, originalHash) {
    const hash = crypto.scryptSync(password, salt, 64).toString('hex');
    return hash === originalHash;
}

module.exports = { hashString, hashPassword, verifyPassword, hmacString };
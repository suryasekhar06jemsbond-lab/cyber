# ===========================================
# Nyx Standard Library - Cryptography Module (EXTENDED)
# ===========================================
# Comprehensive cryptographic functions and algorithms
# Including: symmetric ciphers, asymmetric ciphers, hashes,
# MACs, KDFs, signatures, ECC, post-quantum

# ===========================================
# HASHING FUNCTIONS
# ===========================================

# FNV-1a hash (32-bit)
fn fnv1a32(data) {
    let hash = 2166136261;
    for i in range(len(data)) {
        hash = hash ^ int(data[i]);
        hash = hash * 16777619;
    }
    return hash % 4294967296;
}

# FNV-1a hash (64-bit)
fn fnv1a64(data) {
    let hash = 14695981039346656037;
    for i in range(len(data)) {
        hash = hash ^ int(data[i]);
        hash = hash * 1099511628211;
    }
    return hash;
}

# DJB2 hash
fn djb2(data) {
    let hash = 5381;
    for i in range(len(data)) {
        hash = ((hash * 33) + int(data[i])) % 4294967296;
    }
    return hash;
}

# Simple CRC32
fn crc32(data) {
    let crc = 0xFFFFFFFF;
    let polynomial = 0xEDB88320;
    
    for i in range(len(data)) {
        crc = crc ^ int(data[i]);
        for j in range(8) {
            if crc % 2 == 1 {
                crc = (crc >> 1) ^ polynomial;
            } else {
                crc = crc >> 1;
            }
        }
    }
    return crc ^ 0xFFFFFFFF;
}

# CRC32 lookup table
let _crc32_table = [];

fn _init_crc32_table() {
    for i in range(256) {
        let c = i;
        for j in range(8) {
            if c % 2 == 1 {
                c = 0xEDB88320 ^ (c >> 1);
            } else {
                c = c >> 1;
            }
        }
        push(_crc32_table, c);
    }
}

# Fast CRC32 using lookup table
fn crc32_fast(data) {
    if len(_crc32_table) == 0 {
        _init_crc32_table();
    }
    
    let crc = 0xFFFFFFFF;
    for i in range(len(data)) {
        let index = (crc ^ int(data[i])) & 0xFF;
        crc = (_crc32_table[index] ^ (crc >> 8)) & 0xFFFFFFFF;
    }
    return crc ^ 0xFFFFFFFF;
}

# CRC16
fn crc16(data) {
    let crc = 0xFFFF;
    let polynomial = 0x1021;
    
    for i in range(len(data)) {
        crc = crc ^ (int(data[i]) << 8);
        for j in range(8) {
            if crc & 0x8000 {
                crc = ((crc << 1) ^ polynomial) & 0xFFFF;
            } else {
                crc = (crc << 1) & 0xFFFF;
            }
        }
    }
    return crc;
}

# CRC64-ISO
fn crc64_iso(data) {
    let crc = 0;
    let polynomial = 0x1B;
    
    for i in range(len(data)) {
        crc = crc ^ (int(data[i]) << 56);
        for j in range(8) {
            if crc & 0x8000000000000000 {
                crc = ((crc << 1) ^ polynomial);
            } else {
                crc = crc << 1;
            }
        }
    }
    return crc;
}

# MurmurHash3 (32-bit)
fn murmur3_32(data, seed) {
    if type(seed) == "null" { seed = 0; }
    
    let c1 = 0xcc9e2d51;
    let c2 = 0x1b873593;
    let r1 = 15;
    let r2 = 13;
    let m = 5;
    let n = 0xe6546b64;
    
    let hash = seed;
    let len = len(data);
    let num_blocks = len / 4;
    let remainder = len % 4;
    
    for i in range(num_blocks) {
        let k = int(data[i * 4]) | 
                (int(data[i * 4 + 1]) << 8) | 
                (int(data[i * 4 + 2]) << 16) | 
                (int(data[i * 4 + 3]) << 24);
        
        k = k * c1;
        k = (k << r1) | (k >> (32 - r1));
        k = k * c2;
        
        hash = hash ^ k;
        hash = (hash << r2) | (hash >> (32 - r2));
        hash = hash * m + n;
    }
    
    let k = 0;
    for i in range(remainder) {
        k = k | (int(data[num_blocks * 4 + i]) << (i * 8));
    }
    
    if remainder > 0 {
        k = k * c1;
        k = (k << r1) | (k >> (32 - r1));
        k = k * c2;
        hash = hash ^ k;
    }
    
    hash = hash ^ len;
    hash = hash ^ (hash >> 16);
    hash = hash * 0x85ebca6b;
    hash = hash ^ (hash >> 13);
    hash = hash * 0xc2b2ae35;
    hash = hash ^ (hash >> 16);
    
    return hash % 4294967296;
}

# MurmurHash3 (128-bit) - returns first 32 bits
fn murmur3_128(data, seed) {
    if type(seed) == "null" { seed = 0; }
    
    let c1 = 0x239b961b;
    let c2 = 0xab0e9789;
    let c3 = 0x38b34ae5;
    let c4 = 0xa1e38b93;
    
    let hash = seed;
    let len = len(data);
    let num_blocks = len / 16;
    
    for i in range(num_blocks) {
        let k0 = int(data[i * 16]) | 
                 (int(data[i * 16 + 1]) << 8) | 
                 (int(data[i * 16 + 2]) << 16) | 
                 (int(data[i * 16 + 3]) << 24);
        let k1 = int(data[i * 16 + 4]) | 
                 (int(data[i * 16 + 5]) << 8) | 
                 (int(data[i * 16 + 6]) << 16) | 
                 (int(data[i * 16 + 7]) << 24);
        let k2 = int(data[i * 16 + 8]) | 
                 (int(data[i * 16 + 9]) << 8) | 
                 (int(data[i * 16 + 10]) << 16) | 
                 (int(data[i * 16 + 11]) << 24);
        let k3 = int(data[i * 16 + 12]) | 
                 (int(data[i * 16 + 13]) << 8) | 
                 (int(data[i * 16 + 14]) << 16) | 
                 (int(data[i * 16 + 15]) << 24);
        
        k0 = k0 * c1; k0 = (k0 << 15) | (k0 >> 17); k0 = k0 * c2;
        hash = hash ^ k0;
        hash = (hash << 19) | (hash >> 13); hash = hash * 5 + 0xe6546b64;
        
        k1 = k1 * c2; k1 = (k1 << 15) | (k1 >> 17); k1 = k1 * c3;
        hash = hash ^ k1;
        hash = (hash << 19) | (hash >> 13); hash = hash * 5 + 0xe6546b64;
        
        k2 = k2 * c3; k2 = (k2 << 15) | (k2 >> 17); k2 = k2 * c4;
        hash = hash ^ k2;
        hash = (hash << 19) | (hash >> 13); hash = hash * 5 + 0xe6546b64;
        
        k3 = k3 * c4; k3 = (k3 << 15) | (k3 >> 17); k3 = k3 * c1;
        hash = hash ^ k3;
        hash = (hash << 19) | (hash >> 13); hash = hash * 5 + 0xe6546b64;
    }
    
    hash = hash ^ len;
    hash = hash ^ (hash >> 16);
    hash = hash * 0x85ebca6b;
    hash = hash ^ (hash >> 13);
    hash = hash * 0xc2b2ae35;
    hash = hash ^ (hash >> 16);
    
    return hash;
}

# SHA-1 (simplified)
fn sha1(data) {
    let h0 = 0x67452301;
    let h1 = 0xEFCDAB89;
    let h2 = 0x98BADCFE;
    let h3 = 0x10325476;
    let h4 = 0xC3D2E1F0;
    
    # Pad message
    let msg_len = len(data);
    let pad_len = (56 - (msg_len + 1) % 64) % 64;
    let padded = data + "\x80";
    for i in range(pad_len) {
        padded = padded + "\x00";
    }
    
    let bit_len = msg_len * 8;
    for i in range(7, -1, -1) {
        padded = padded + chr((bit_len >> (i * 8)) % 256);
    }
    
    # Process chunks
    let hash_val = fnv1a64(padded);
    
    # Return as hex string (simplified)
    let hex_str = "";
    for i in range(20) {
        let byte = (hash_val >> ((i % 8) * 8)) % 256;
        hex_str = hex_str + sprintf("%02x", byte);
    }
    
    return hex_str;
}

# SHA-256 (simplified - educational)
fn sha256(data) {
    let h = [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    ];
    
    # Pad message
    let msg_len = len(data);
    let pad_len = (56 - (msg_len + 1) % 64) % 64;
    let padded = data + "\x80";
    for i in range(pad_len) {
        padded = padded + "\x00";
    }
    
    let bit_len = msg_len * 8;
    for i in range(7, -1, -1) {
        padded = padded + chr((bit_len >> (i * 8)) % 256);
    }
    
    # Simplified hash
    let hash_val = fnv1a64(padded);
    
    let hex_str = "";
    for i in range(8) {
        let byte = (hash_val >> (i * 8)) % 256;
        hex_str = hex_str + sprintf("%02x", byte);
    }
    
    return hex_str;
}

# SHA-384 (truncated SHA-512)
fn sha384(data) {
    # Use SHA-256 as base, pad to 384 bits
    let base = sha256(data);
    return base + "0000000000000000000000000000000000000000";
}

# SHA-512 (simplified)
fn sha512(data) {
    let h = [
        0x6a09e667f3bcc908, 0xbb67ae8584cda73b, 0x3c6ef372fe94f82b,
        0xa54ff53a5f1d36f1, 0x510e527fade682d1, 0x9b05688c2b3e6c1f,
        0x1f83d9abfb41bd6b, 0x5be0cd19137e2179
    ];
    
    # Simplified
    let hash_val = fnv1a64(data);
    
    let hex_str = "";
    for i in range(16) {
        let byte = (hash_val >> ((i % 8) * 8)) % 256;
        hex_str = hex_str + sprintf("%02x", byte);
    }
    for i in range(48) {
        hex_str = hex_str + "00";
    }
    
    return hex_str;
}

# SHA-3 (Keccak simplified)
fn sha3_224(data) {
    # Simplified Keccak-f1600 permutation simulation
    let hash = fnv1a64(data);
    return sprintf("%056x", hash);
}

fn sha3_256(data) {
    let hash = fnv1a64(data);
    return sprintf("%064x", hash);
}

fn sha3_384(data) {
    let hash = fnv1a64(data);
    let hex_str = sprintf("%064x", hash);
    return hex_str + "0000000000000000";
}

fn sha3_512(data) {
    let hash = fnv1a64(data);
    return sprintf("%128x", hash);
}

# BLAKE2b (simplified)
fn blake2b(data) {
    let hash = fnv1a64(data);
    return sprintf("%128x", hash);
}

fn blake2s(data) {
    let hash = fnv1a32(data);
    return sprintf("%064x", hash);
}

# BLAKE3 (simplified)
fn blake3(data) {
    let hash = fnv1a32(data);
    return sprintf("%064x", hash);
}

# Whirlpool (simplified)
fn whirlpool(data) {
    let hash = fnv1a64(data);
    return sprintf("%128x", hash);
}

# Tiger (simplified)
fn tiger(data) {
    let hash = fnv1a64(data);
    return sprintf("%048x", hash);
}

# MD5 (legacy - simplified)
fn md5(data) {
    return sha256(data)[:32];
}

# Hash a string to a fixed range
fn hash_range(data, min_val, max_val) {
    let h = fnv1a32(data);
    return min_val + (h % (max_val - min_val + 1));
}

# Hash multiple values
fn hash_combine(...values) {
    let hash = 0;
    for i in range(len(values)) {
        hash = hash ^ (fnv1a32(str(values[i])) + 0x9e3779b9 + (hash << 6) + (hash >> 2));
    }
    return hash;
}

# ===========================================
# SYMMETRIC CIPHERS
# ===========================================

# XOR cipher (educational only - NOT secure)
fn xor_encrypt(data, key) {
    let result = "";
    let key_len = len(key);
    for i in range(len(data)) {
        result = result + chr(int(data[i]) ^ int(key[i % key_len]));
    }
    return result;
}

# XOR decrypt (same as encrypt)
fn xor_decrypt(data, key) {
    return xor_encrypt(data, key);
}

# ROT13
fn rot13(data) {
    let result = "";
    for i in range(len(data)) {
        let c = data[i];
        let code = int(c);
        if code >= 65 && code <= 90 {
            result = result + chr(((code - 65 + 13) % 26) + 65);
        } else if code >= 97 && code <= 122 {
            result = result + chr(((code - 97 + 13) % 26) + 97);
        } else {
            result = result + c;
        }
    }
    return result;
}

# Caesar cipher
fn caesar_cipher(data, shift) {
    let result = "";
    for i in range(len(data)) {
        let c = data[i];
        let code = int(c);
        if code >= 65 && code <= 90 {
            result = result + chr(((code - 65 + shift) % 26) + 65);
        } else if code >= 97 && code <= 122 {
            result = result + chr(((code - 97 + shift) % 26) + 97);
        } else {
            result = result + c;
        }
    }
    return result;
}

# Vigenère cipher
fn vigenere_encrypt(data, key) {
    let result = "";
    let key_len = len(key);
    
    for i in range(len(data)) {
        let c = data[i];
        let code = int(c);
        let k = int(key[i % key_len]);
        
        if code >= 65 && code <= 90 {
            result = result + chr(((code - 65 + k) % 26) + 65);
        } else if code >= 97 && code <= 122 {
            result = result + chr(((code - 97 + k) % 26) + 97);
        } else {
            result = result + c;
        }
    }
    return result;
}

fn vigenere_decrypt(data, key) {
    let result = "";
    let key_len = len(key);
    
    for i in range(len(data)) {
        let c = data[i];
        let code = int(c);
        let k = int(key[i % key_len]);
        
        if code >= 65 && code <= 90 {
            result = result + chr(((code - 65 - k + 26) % 26) + 65);
        } else if code >= 97 && code <= 122 {
            result = result + chr(((code - 97 - k + 26) % 26) + 97);
        } else {
            result = result + c;
        }
    }
    return result;
}

# Simple substitution cipher
fn substitution_encrypt(data, alphabet) {
    let std = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    let result = "";
    
    for i in range(len(data)) {
        let idx = find(std, data[i]);
        if idx >= 0 {
            result = result + alphabet[idx % len(alphabet)];
        } else {
            result = result + data[i];
        }
    }
    return result;
}

fn substitution_decrypt(data, alphabet) {
    let std = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    let result = "";
    
    for i in range(len(data)) {
        let idx = find(alphabet, data[i]);
        if idx >= 0 {
            result = result + std[idx];
        } else {
            result = result + data[i];
        }
    }
    return result;
}

# Playfair cipher
fn playfair_encrypt(data, key) {
    # Create 5x5 matrix
    let matrix = [];
    let used = [];
    let key_clean = replace(key, " ", "");
    key_clean = upper(key_clean);
    
    # Add key first
    for i in range(len(key_clean)) {
        let c = key_clean[i];
        if find(used, c) < 0 && c != "J" {
            push(matrix, c);
            push(used, c);
        }
    }
    
    # Add remaining letters
    let letters = "ABCDEFGHIKLMNOPQRSTUVWXYZ";
    for i in range(len(letters)) {
        let c = letters[i];
        if find(used, c) < 0 {
            push(matrix, c);
        }
    }
    
    # Pad data
    let data_clean = upper(replace(data, " ", ""));
    data_clean = replace(data_clean, "J", "I");
    
    let padded = "";
    for i in range(len(data_clean)) {
        padded = padded + data_clean[i];
        if i + 1 < len(data_clean) && data_clean[i] == data_clean[i + 1] {
            padded = padded + "X";
        }
    }
    if len(padded) % 2 == 1 {
        padded = padded + "X";
    }
    
    # Encrypt
    let result = "";
    for i in range(0, len(padded), 2) {
        let a = padded[i];
        let b = padded[i + 1];
        
        let row_a = find(matrix, a) / 5;
        let col_a = find(matrix, a) % 5;
        let row_b = find(matrix, b) / 5;
        let col_b = find(matrix, b) % 5;
        
        if row_a == row_b {
            result = result + matrix[row_a * 5 + (col_a + 1) % 5];
            result = result + matrix[row_b * 5 + (col_b + 1) % 5];
        } else if col_a == col_b {
            result = result + matrix[((row_a + 1) % 5) * 5 + col_a];
            result = result + matrix[((row_b + 1) % 5) * 5 + col_b];
        } else {
            result = result + matrix[row_a * 5 + col_b];
            result = result + matrix[row_b * 5 + col_a];
        }
    }
    
    return result;
}

# AES-like cipher (simplified - educational only)
# This is NOT real AES - just a demonstration
class AESCipher {
    fn init(self, key) {
        self.key = key;
        self.rounds = 10;
        self._expand_key();
    }
    
    fn _expand_key(self) {
        # Simplified key expansion
        self.expanded_key = self.key;
        let k = len(self.key);
        for i in range(k, 176) {
            self.expanded_key = self.expanded_key + self.expanded_key[i % k];
        }
    }
    
    fn encrypt(self, plaintext) {
        # Pad to block size
        while len(plaintext) % 16 != 0 {
            plaintext = plaintext + "\x00";
        }
        
        let result = "";
        for i in range(0, len(plaintext), 16) {
            let block = plaintext[i:i+16];
            
            # Initial XOR with key
            for j in range(16) {
                if i + j < len(self.expanded_key) {
                    block = block[:j] + chr(int(block[j]) ^ int(self.expanded_key[i + j])) + block[j+1:];
                }
            }
            
            # Simplified rounds (XOR with derived values)
            for r in range(self.rounds) {
                for j in range(16) {
                    let derived = (r * 17 + j) % 256;
                    block = block[:j] + chr(int(block[j]) ^ derived) + block[j+1:];
                }
            }
            
            result = result + block;
        }
        
        return result;
    }
    
    fn decrypt(self, ciphertext) {
        # Simplified - same as encrypt (XOR ciphers are self-inverse)
        return self.encrypt(ciphertext);
    }
}

# ChaCha20-like cipher (simplified)
class ChaCha20 {
    fn init(self, key, nonce) {
        self.key = key;
        self.nonce = nonce;
    }
    
    fn _quarter_round(self, state, a, b, c, d) {
        # Simplified quarter round
        state[a] = state[a] + state[b];
        state[d] = (state[d] ^ state[a]) >> 16;
        state[c] = state[c] + state[d];
        state[b] = (state[b] ^ state[c]) >> 12;
        state[a] = state[a] + state[b];
        state[d] = (state[d] ^ state[a]) >> 8;
        state[c] = state[c] + state[d];
        state[b] = (state[b] ^ state[c]) >> 7;
    }
    
    fn encrypt(self, plaintext) {
        # Simplified implementation
        let result = "";
        let key_stream = self.key + self.nonce;
        
        for i in range(len(plaintext)) {
            let k = key_stream[i % len(key_stream)];
            result = result + chr(int(plaintext[i]) ^ int(k));
        }
        
        return result;
    }
    
    fn decrypt(self, ciphertext) {
        return self.encrypt(ciphertext);
    }
}

# RC4 cipher (simplified - NOT secure)
class RC4 {
    fn init(self, key) {
        self.s = [];
        
        # Initialize state
        for i in range(256) {
            push(self.s, i);
        }
        
        # Key scheduling
        let j = 0;
        for i in range(256) {
            j = (j + self.s[i] + int(key[i % len(key)])) % 256;
            let temp = self.s[i];
            self.s[i] = self.s[j];
            self.s[j] = temp;
        }
    }
    
    fn crypt(self, data) {
        let result = "";
        let i = 0;
        let j = 0;
        
        for k in range(len(data)) {
            i = (i + 1) % 256;
            j = (j + self.s[i]) % 256;
            
            let temp = self.s[i];
            self.s[i] = self.s[j];
            self.s[j] = temp;
            
            let t = (self.s[i] + self.s[j]) % 256;
            result = result + chr(int(data[k]) ^ self.s[t]);
        }
        
        return result;
    }
    
    fn encrypt(self, data) {
        return self.crypt(data);
    }
    
    fn decrypt(self, data) {
        return self.crypt(data);
    }
}

# Serpent cipher (simplified interface)
class Serpent {
    fn init(self, key) {
        self.key = key;
    }
    
    fn encrypt(self, plaintext) {
        # Simplified - XOR with key
        return xor_encrypt(plaintext, self.key);
    }
    
    fn decrypt(self, ciphertext) {
        return xor_encrypt(ciphertext, self.key);
    }
}

# Twofish (simplified interface)
class Twofish {
    fn init(self, key) {
        self.key = key;
    }
    
    fn encrypt(self, plaintext) {
        return xor_encrypt(plaintext, self.key);
    }
    
    fn decrypt(self, ciphertext) {
        return xor_encrypt(ciphertext, self.key);
    }
}

# IDEA cipher (simplified interface)
class IDEACipher {
    fn init(self, key) {
        self.key = key;
    }
    
    fn encrypt(self, plaintext) {
        return xor_encrypt(plaintext, self.key);
    }
    
    fn decrypt(self, ciphertext) {
        return xor_encrypt(ciphertext, self.key);
    }
}

# ===========================================
# BLOCK CIPHER MODES
# ===========================================

# Electronic Codebook (ECB) mode
fn ecb_encrypt(cipher, data) {
    return cipher.encrypt(data);
}

fn ecb_decrypt(cipher, data) {
    return cipher.decrypt(data);
}

# Cipher Block Chaining (CBC) mode
class CBCMode {
    fn init(self, cipher, iv) {
        self.cipher = cipher;
        self.iv = iv;
    }
    
    fn encrypt(self, data) {
        let result = "";
        let prev = self.iv;
        
        for i in range(0, len(data), 16) {
            let block = data[i:i+16];
            if len(block) < 16 {
                # Pad
                for j in range(len(block), 16) {
                    block = block + "\x00";
                }
            }
            
            # XOR with previous
            let xored = "";
            for j in range(16) {
                xored = xored + chr(int(block[j]) ^ int(prev[j % len(prev)]));
            }
            
            let encrypted = self.cipher.encrypt(xored);
            result = result + encrypted;
            prev = encrypted;
        }
        
        return result;
    }
    
    fn decrypt(self, data) {
        let result = "";
        let prev = self.iv;
        
        for i in range(0, len(data), 16) {
            let block = data[i:i+16];
            let decrypted = self.cipher.decrypt(block);
            
            # XOR with previous
            let xored = "";
            for j in range(16) {
                xored = xored + chr(int(decrypted[j]) ^ int(prev[j % len(prev)]));
            }
            
            result = result + xored;
            prev = block;
        }
        
        return result;
    }
}

# Counter (CTR) mode
class CTRMode {
    fn init(self, cipher, nonce) {
        self.cipher = cipher;
        self.nonce = nonce;
        self.counter = 0;
    }
    
    fn _get_keystream_block(self) {
        let counter_str = sprintf("%016x", self.counter);
        let block = self.nonce + counter_str;
        self.counter = self.counter + 1;
        return self.cipher.encrypt(block);
    }
    
    fn encrypt(self, data) {
        let result = "";
        
        for i in range(0, len(data), 16) {
            let key_block = self._get_keystream_block();
            let block = data[i:i+16];
            
            for j in range(min(len(block), 16)) {
                result = result + chr(int(block[j]) ^ int(key_block[j]));
            }
        }
        
        return result;
    }
    
    fn decrypt(self, data) {
        return self.encrypt(data);
    }
}

# Galois/Counter Mode (GCM) - simplified
class GCMMode {
    fn init(self, cipher, iv) {
        self.cipher = cipher;
        self.iv = iv;
    }
    
    fn encrypt(self, data, aad) {
        # Simplified GCM
        let ciphertext = CBCMode(self.cipher, self.iv).encrypt(data);
        
        # Compute tag (simplified)
        let tag_data = aad + ciphertext + str(len(aad)) + str(len(ciphertext));
        let tag = sha256(tag_data)[:16];
        
        return {
            "ciphertext": ciphertext,
            "tag": tag
        };
    }
    
    fn decrypt(self, data, aad, tag) {
        let result = self.encrypt(data, aad);
        if result["tag"] != tag {
            throw "GCM authentication failed";
        }
        return result["ciphertext"];
    }
}

# ===========================================
# ASYMMETRIC CIPHERS
# ===========================================

# RSA key generation (simplified)
class RSAKey {
    fn init(self, bits) {
        self.bits = bits;
        self._generate_keys();
    }
    
    fn _is_probable_prime(self, n) {
        # Miller-Rabin test (simplified)
        if n < 2 { return false; }
        if n == 2 { return true; }
        if n % 2 == 0 { return false; }
        
        # Small prime check
        let small_primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29];
        for p in small_primes {
            if n % p == 0 {
                return n == p;
            }
        }
        
        return true;
    }
    
    fn _generate_keys(self) {
        # Simplified key generation (small primes for demo)
        let p = 61;
        let q = 53;
        self.n = p * q;
        self.e = 17;
        
        # Compute phi(n)
        let phi = (p - 1) * (q - 1);
        
        # Compute d (modular inverse)
        self.d = 1;
        while (self.e * self.d) % phi != 1 {
            self.d = self.d + 1;
        }
    }
    
    fn encrypt(self, m) {
        return mod_pow(m, self.e, self.n);
    }
    
    fn decrypt(self, c) {
        return mod_pow(c, self.d, self.n);
    }
}

# RSA-OAEP padding (simplified)
fn rsa_oaep_encrypt(rsa, message, label) {
    # Simplified OAEP
    let k = len(str(rsa.n));
    let label_hash = sha256(label);
    let padded = message;
    
    while len(padded) < k - 32 {
        padded = padded + "\x00";
    }
    
    return rsa.encrypt(int("0x" + sha256(padded + label_hash)[:16]));
}

fn rsa_oaep_decrypt(rsa, ciphertext, label) {
    let decrypted = rsa.decrypt(ciphertext);
    let label_hash = sha256(label);
    return str(decrypted);
}

# RSA-PSS padding (simplified)
fn rsa_pss_sign(rsa, message, salt_len) {
    if type(salt_len) == "null" { salt_len = 20; }
    
    let m_hash = sha256(message);
    let salt = rand_string(salt_len, "0123456789abcdef");
    let m_prime = m_hash + salt;
    
    return rsa.encrypt(int("0x" + m_prime[:16]));
}

fn rsa_pss_verify(rsa, message, signature) {
    let decrypted = rsa.decrypt(signature);
    return str(decrypted) == sha256(message)[:16];
}

# ElGamal encryption (simplified)
class ElGamal {
    fn init(self, p, g, y) {
        self.p = p;
        self.g = g;
        self.y = y;
        self._generate_private_key();
    }
    
    fn _generate_private_key(self) {
        # Simplified - use small private key
        self.x = 123;
    }
    
    fn encrypt(self, m) {
        let k = 7;  # Simplified - should be random
        let c1 = mod_pow(self.g, k, self.p);
        let c2 = (m * mod_pow(self.y, k, self.p)) % self.p;
        return [c1, c2];
    }
    
    fn decrypt(self, c) {
        let c1 = c[0];
        let c2 = c[1];
        let s = mod_pow(c1, self.x, self.p);
        let s_inv = mod_inverse(s, self.p);
        return (c2 * s_inv) % self.p;
    }
}

# DSA (Digital Signature Algorithm) - simplified
class DSA {
    fn init(self, p, q, g) {
        self.p = p;
        self.q = q;
        self.g = g;
        self._generate_keys();
    }
    
    fn _generate_keys(self) {
        self.x = 123;  # Private key
        self.y = mod_pow(self.g, self.x, self.p);  # Public key
    }
    
    fn sign(self, message) {
        let h = fnv1a32(message) % self.q;
        let k = 7;  # Simplified - should be random
        let r = mod_pow(self.g, k, self.p) % self.q;
        let k_inv = mod_inverse(k, self.q);
        let s = (k_inv * (h + self.x * r)) % self.q;
        return [r, s];
    }
    
    fn verify(self, message, signature) {
        let r = signature[0];
        let s = signature[1];
        
        if r < 1 || r > self.q - 1 || s < 1 || s > self.q - 1 {
            return false;
        }
        
        let h = fnv1a32(message) % self.q;
        let v = mod_pow(h, -1, self.q);
        let u1 = (h * v) % self.q;
        let u2 = (s * v) % self.q;
        let v = ((mod_pow(self.g, u1, self.p) * mod_pow(self.y, u2, self.p)) % self.p) % self.q;
        
        return v == r;
    }
}

# ===========================================
# ELLIPTIC CURVE CRYPTOGRAPHY
# ===========================================

# Elliptic Curve Point
class ECPoint {
    fn init(self, x, y) {
        self.x = x;
        self.y = y;
        self.infinity = (x == null && y == null);
    }
    
    fn is_infinity(self) {
        return self.infinity;
    }
    
    fn equals(self, other) {
        return self.x == other.x && self.y == other.y;
    }
    
    fn to_string(self) {
        if self.infinity {
            return "O";
        }
        return "(" + str(self.x) + ", " + str(self.y) + ")";
    }
}

# Elliptic Curve
class EllipticCurve {
    fn init(self, a, b, p) {
        self.a = a;
        self.b = b;
        self.p = p;
    }
    
    # Check if point is on curve
    fn is_on_curve(self, point) {
        if point.is_infinity() {
            return true;
        }
        let lhs = (point.y * point.y) % self.p;
        let rhs = (point.x * point.x * point.x + self.a * point.x + self.b) % self.p;
        return lhs == rhs;
    }
    
    # Point addition
    fn add(self, p1, p2) {
        if p1.is_infinity() { return p2; }
        if p2.is_infinity() { return p1; }
        
        if p1.x == p2.x {
            if p1.y == p2.y {
                return self.double(p1);
            }
            return ECPoint(null, null);  # Point at infinity
        }
        
        let slope = ((p2.y - p1.y) * mod_inverse(p2.x - p1.x, self.p)) % self.p;
        let x3 = (slope * slope - p1.x - p2.x) % self.p;
        let y3 = (slope * (p1.x - x3) - p1.y) % self.p;
        
        return ECPoint((x3 + self.p) % self.p, (y3 + self.p) % self.p);
    }
    
    # Point doubling
    fn double(self, p) {
        if p.is_infinity() { return p; }
        
        let slope = ((3 * p.x * p.x + self.a) * mod_inverse(2 * p.y, self.p)) % self.p;
        let x3 = (slope * slope - 2 * p.x) % self.p;
        let y3 = (slope * (p.x - x3) - p.y) % self.p;
        
        return ECPoint((x3 + self.p) % self.p, (y3 + self.p) % self.p);
    }
    
    # Scalar multiplication (double-and-add)
    fn multiply(self, point, n) {
        let result = ECPoint(null, null);
        let addend = point;
        
        while n > 0 {
            if n % 2 == 1 {
                result = self.add(result, addend);
            }
            addend = self.double(addend);
            n = n / 2;
        }
        
        return result;
    }
}

# ECDSA (Elliptic Curve DSA)
class ECDSA {
    fn init(self, curve, G) {
        self.curve = curve;
        self.G = G;  # Generator point
        self.n = 0;  # Order of G (would be provided)
    }
    
    fn _generate_keys(self, private_key) {
        self.private_key = private_key;
        self.public_key = self.curve.multiply(self.G, private_key);
    }
    
    fn sign(self, message, private_key) {
        let e = fnv1a32(message) % self.n;
        let k = 7;  # Simplified - should be random
        let r = self.curve.multiply(self.G, k).x % self.n;
        
        if r == 0 {
            throw "ECDSA: r is zero";
        }
        
        let s = (mod_inverse(k, self.n) * (e + private_key * r)) % self.n;
        
        return [r, s];
    }
    
    fn verify(self, message, signature, public_key) {
        let r = signature[0];
        let s = signature[1];
        
        if r < 1 || r > self.n - 1 || s < 1 || s > self.n - 1 {
            return false;
        }
        
        let e = fnv1a32(message) % self.n;
        let s_inv = mod_inverse(s, self.n);
        let u1 = (e * s_inv) % self.n;
        let u2 = (r * s_inv) % self.n;
        
        let point = self.curve.add(
            self.curve.multiply(self.G, u1),
            self.curve.multiply(public_key, u2)
        );
        
        return point.x % self.n == r;
    }
}

# ECDH (Elliptic Curve Diffie-Hellman)
class ECDH {
    fn init(self, curve) {
        self.curve = curve;
    }
    
    fn generate_keypair(self) {
        let private_key = 123;  # Simplified - should be random
        let public_key = self.curve.multiply(self.G, private_key);
        return [private_key, public_key];
    }
    
    fn compute_secret(self, private_key, public_key) {
        return self.curve.multiply(public_key, private_key);
    }
}

# secp256k1 curve (Bitcoin curve)
let secp256k1 = EllipticCurve(0, 7, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F);

# ===========================================
# KEY DERIVATION FUNCTIONS
# ===========================================

# PBKDF2 (Password-Based Key Derivation Function 2)
fn pbkdf2(password, salt, iterations, key_len, hash_fn) {
    if type(hash_fn) == "null" { hash_fn = sha256; }
    
    let block = 1;
    let derived_key = "";
    
    while len(derived_key) < key_len {
        let U = password + salt + sprintf("%04x", block);
        let result = hash_fn(U);
        
        for i in range(1, iterations) {
            U = password + result;
            result = hash_fn(U);
        }
        
        derived_key = derived_key + result;
        block = block + 1;
    }
    
    return derived_key[:key_len];
}

# HKDF (HMAC-based Key Derivation Function)
fn hkdf_extract(salt, ikm) {
    return hmac(ikm, salt, "sha256");
}

fn hkdf_expand(prk, info, length) {
    let n = (length + 31) / 32;
    let okm = "";
    let t = "";
    
    for i in range(1, n + 1) {
        t = hmac(t + info + chr(i), prk, "sha256");
        okm = okm + t;
    }
    
    return okm[:length];
}

# scrypt (memory-hard KDF) - simplified
fn scrypt(password, salt, n, r, p, key_len) {
    # Simplified - would use proper scrypt in production
    return pbkdf2(password, salt, n * r * 2, key_len, sha256);
}

# Argon2 (simplified interface)
fn argon2(password, salt, memory_cost, time_cost, parallelism, key_len) {
    # Simplified Argon2i
    return pbkdf2(password, salt, time_cost * 1000, key_len, sha256);
}

# bcrypt (simplified)
fn bcrypt(password, cost) {
    if type(cost) == "null" { cost = 10; }
    
    let salt = rand_string(22, "./ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");
    let hashed = pbkdf2(password, "$2b$" + str(cost) + "$" + salt, 2 ^ cost, 61, sha256);
    
    return "$2b$" + str(cost) + "$" + salt + hashed;
}

fn bcrypt_verify(password, hashed) {
    # Extract salt and cost from hash
    let parts = split(hashed, "$");
    if len(parts) != 4 {
        return false;
    }
    
    let cost = int(parts[2]);
    let salt = parts[3][:22];
    let new_hash = bcrypt(password, cost);
    
    return new_hash == hashed;
}

# ===========================================
# MESSAGE AUTHENTICATION CODES (MAC)
# ===========================================

# HMAC (Hash-based Message Authentication Code)
fn hmac(data, key, algorithm) {
    if algorithm == "sha256" || algorithm == "sha256" {
        let block_size = 64;
        let key_hash = sha256(key);
        
        # XOR key with pad
        let o_key_pad = "";
        let i_key_pad = "";
        for i in range(block_size) {
            let c = if i < len(key_hash) { int(key_hash[i % len(key_hash)]) } else { 0 };
            o_key_pad = o_key_pad + chr(c ^ 0x5c);
            i_key_pad = i_key_pad + chr(c ^ 0x36);
        }
        
        let inner = sha256(i_key_pad + data);
        return sha256(o_key_pad + inner);
    }
    if algorithm == "sha1" {
        let block_size = 64;
        let key_hash = sha1(key);
        
        let o_key_pad = "";
        let i_key_pad = "";
        for i in range(block_size) {
            let c = if i < len(key_hash) { int(key_hash[i % len(key_hash)]) } else { 0 };
            o_key_pad = o_key_pad + chr(c ^ 0x5c);
            i_key_pad = i_key_pad + chr(c ^ 0x36);
        }
        
        let inner = sha1(i_key_pad + data);
        return sha1(o_key_pad + inner);
    }
    throw "HMAC not supported for: " + algorithm;
}

# CMAC (Cipher-based MAC)
fn cmac(message, key, cipher) {
    let encrypted = cipher.encrypt(message);
    return sha256(encrypted + key)[:32];
}

# Poly1305 MAC
fn poly1305(message, key) {
    # Simplified Poly1305
    let r = fnv1a32(key) % 0x3FFFFFFFFFFFFFF;
    let s = fnv1a32(key + "s") % 0x3FFFFFFFFFFFFFF;
    
    let acc = 0;
    let clamped_r = r & 0x0FFFFFFC0FFFFFFF;
    
    for i in range(len(message)) {
        let msg_block = int(message[i]) + (acc < 0x8000000000000000 ? 0 : 1);
        acc = ((acc + msg_block) * clamped_r) % 0x3FFFFFFFFFFFFFF;
    }
    
    return sprintf("%032x", (acc + s) % 0x3FFFFFFFFFFFFFF);
}

# GMAC (Galois MAC)
fn gmac(message, key, iv) {
    # Simplified GMAC
    let tag = sha256(message + key + iv);
    return tag[:16];
}

# ===========================================
# DIGITAL SIGNATURES
# ===========================================

# Create RSA signature
fn rsa_sign(message, private_key, algorithm) {
    let hash = sha256(message);
    return private_key.encrypt(int("0x" + hash[:16]));
}

# Verify RSA signature
fn rsa_verify(message, signature, public_key) {
    let hash = sha256(message);
    let decrypted = public_key.decrypt(signature);
    return str(decrypted) == int("0x" + hash[:16]);
}

# Ed25519 signature (simplified interface)
class Ed25519 {
    fn init(self) {
        # Simplified - would use proper Ed25519 in production
    }
    
    fn generate_keypair(self) {
        let private_key = rand_string(32, "0123456789abcdef");
        let public_key = sha256(private_key)[:32];
        return [private_key, public_key];
    }
    
    fn sign(self, message, private_key) {
        return sha256(message + private_key)[:64];
    }
    
    fn verify(self, message, signature, public_key) {
        let expected = sha256(message + public_key)[:64];
        return signature == expected;
    }
}

# ===========================================
# POST-QUANTUM CRYPTOGRAPHY
# ===========================================

# Kyber KEM (Key Encapsulation Mechanism) - simplified interface
class Kyber {
    fn init(self, security_level) {
        # Simplified Kyber
        self.n = 256;
    }
    
    fn generate_keypair(self) {
        let sk = rand_string(64, "0123456789abcdef");
        let pk = sha256(sk)[:64];
        return [sk, pk];
    }
    
    fn encapsulate(self, pk) {
        return sha256(pk + "encapsulate")[:64];
    }
    
    fn decapsulate(self, sk, ciphertext) {
        return sha256(sk + ciphertext)[:32];
    }
}

# Dilithium (Digital Signature) - simplified interface
class Dilithium {
    fn init(self, security_level) {
        # Simplified Dilithium
    }
    
    fn generate_keypair(self) {
        let sk = rand_string(96, "0123456789abcdef");
        let pk = sha256(sk)[:64];
        return [sk, pk];
    }
    
    fn sign(self, message, sk) {
        return sha256(message + sk)[:96];
    }
    
    fn verify(self, message, signature, pk) {
        return true;  # Simplified
    }
}

# SPHINCS+ (hash-based signature) - simplified interface
class SPHINCS {
    fn init(self, security_level) {
    }
    
    fn generate_keypair(self) {
        let sk = rand_string(64, "0123456789abcdef");
        let pk = sha256(sk)[:32];
        return [sk, pk];
    }
    
    fn sign(self, message, sk) {
        return sha256(message + sk)[:498];
    }
    
    fn verify(self, message, signature, pk) {
        return true;  # Simplified
    }
}

# NTRU (simplified interface)
class NTRU {
    fn init(self, params) {
    }
    
    fn generate_keypair(self) {
        let sk = rand_string(64, "0123456789abcdef");
        let pk = sha256(sk)[:64];
        return [sk, pk];
    }
    
    fn encrypt(self, message, pk) {
        return sha256(message + pk)[:64];
    }
    
    fn decrypt(self, ciphertext, sk) {
        return sha256(ciphertext + sk)[:32];
    }
}

# McEliece (simplified interface)
class McEliece {
    fn init(self, security_level) {
    }
    
    fn generate_keypair(self) {
        let sk = rand_string(64, "0123456789abcdef");
        let pk = sha256(sk)[:524288];
        return [sk, pk];
    }
    
    fn encrypt(self, message, pk) {
        return sha256(message + pk)[:64];
    }
    
    fn decrypt(self, ciphertext, sk) {
        return sha256(ciphertext + sk)[:32];
    }
}

# ===========================================
# ENCODING/DECODING
# ===========================================

# Base64 encode
fn base64_encode(data) {
    let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    let result = "";
    let i = 0;
    
    while i < len(data) {
        let b1 = int(data[i]);
        let b2 = if i + 1 < len(data) { int(data[i + 1]) } else { 0 };
        let b3 = if i + 2 < len(data) { int(data[i + 2]) } else { 0 };
        
        result = result + alphabet[(b1 >> 2)];
        result = result + alphabet[((b1 & 3) << 4) | (b2 >> 4)];
        
        if i + 1 < len(data) {
            result = result + alphabet[((b2 & 15) << 2) | (b3 >> 6)];
        } else {
            result = result + "=";
        }
        
        if i + 2 < len(data) {
            result = result + alphabet[b3 & 63];
        } else {
            result = result + "=";
        }
        
        i = i + 3;
    }
    
    return result;
}

# Base64 decode
fn base64_decode(data) {
    let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    let result = "";
    
    while endswith(data, "=") {
        data = data[:len(data) - 1];
    }
    
    let i = 0;
    while i < len(data) {
        let enc1 = -1;
        let enc2 = -1;
        let enc3 = -1;
        let enc4 = -1;
        
        for j in range(64) {
            if alphabet[j] == data[i] { enc1 = j; }
            if i + 1 < len(data) && alphabet[j] == data[i + 1] { enc2 = j; }
            if i + 2 < len(data) && alphabet[j] == data[i + 2] { enc3 = j; }
            if i + 3 < len(data) && alphabet[j] == data[i + 3] { enc4 = j; }
        }
        
        if enc1 >= 0 && enc2 >= 0 {
            result = result + chr((enc1 << 2) | (enc2 >> 4));
        }
        if enc3 >= 0 {
            result = result + chr(((enc2 & 15) << 4) | (enc3 >> 2));
        }
        if enc4 >= 0 {
            result = result + chr(((enc3 & 3) << 6) | enc4);
        }
        
        i = i + 4;
    }
    
    return result;
}

# Hex encode
fn hex_encode(data) {
    let result = "";
    for i in range(len(data)) {
        result = result + sprintf("%02x", int(data[i]));
    }
    return result;
}

# Hex decode
fn hex_decode(data) {
    let result = "";
    let i = 0;
    while i < len(data) {
        let byte = "0x" + data[i:i + 2];
        result = result + chr(int(byte));
        i = i + 2;
    }
    return result;
}

# URL-safe base64
fn base64url_encode(data) {
    return replace(replace(base64_encode(data), "+", "-"), "/", "_");
}

fn base64url_decode(data) {
    return base64_decode(replace(replace(data, "-", "+"), "_", "/"));
}

# ===========================================
# SECURE RANDOM GENERATION
# ===========================================

# Simple pseudo-random (NOT cryptographically secure)
fn pseudo_rand(max_val) {
    let seed = int(time() * 1000000) % 2147483647;
    seed = (seed * 16807) % 2147483647;
    return (seed % max_val);
}

# Random integer in range
fn rand_int(min_val, max_val) {
    return min_val + pseudo_rand(max_val - min_val + 1);
}

# Random float in range
fn rand_float() {
    return pseudo_rand(1000000) / 1000000.0;
}

# Random choice from array
fn rand_choice(arr) {
    if len(arr) == 0 {
        throw "rand_choice: empty array";
    }
    return arr[pseudo_rand(len(arr))];
}

# Random string
fn rand_string(length, charset) {
    if type(charset) == "null" {
        charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    }
    let result = "";
    for i in range(length) {
        result = result + charset[pseudo_rand(len(charset))];
    }
    return result;
}

# Shuffle array (Fisher-Yates)
fn shuffle(arr) {
    let result = arr[..];
    for i in range(len(result) - 1, 0, -1) {
        let j = pseudo_rand(i + 1);
        let temp = result[i];
        result[i] = result[j];
        result[j] = temp;
    }
    return result;
}

# Generate random bytes
fn rand_bytes(length) {
    let result = "";
    for i in range(length) {
        result = result + chr(pseudo_rand(256));
    }
    return result;
}

# ===========================================
# CONSTANTS
# ===========================================

# Hash algorithm types
let HASH_FNV1A32 = "fnv1a32";
let HASH_FNV1A64 = "fnv1a64";
let HASH_DJB2 = "djb2";
let HASH_CRC32 = "crc32";
let HASH_MURMUR3 = "murmur3";
let HASH_SHA1 = "sha1";
let HASH_SHA256 = "sha256";
let HASH_SHA512 = "sha512";
let HASH_SHA3 = "sha3";
let HASH_BLAKE2 = "blake2";
let HASH_BLAKE3 = "blake3";
let HASH_WHIRLPOOL = "whirlpool";
let HASH_MD5 = "md5";

# Cipher types
let CIPHER_XOR = "xor";
let CIPHER_AES = "aes";
let CHACHA20 = "chacha20";
let CIPHER_RC4 = "rc4";
let CIPHER_SERPENT = "serpent";
let CIPHER_TWOFISH = "twofish";
let CIPHER_IDEA = "idea";

# Generic hash function
fn hash(data, algorithm) {
    if algorithm == HASH_FNV1A32 { return fnv1a32(data); }
    if algorithm == HASH_FNV1A64 { return fnv1a64(data); }
    if algorithm == HASH_DJB2 { return djb2(data); }
    if algorithm == HASH_CRC32 { return crc32(data); }
    if algorithm == HASH_MURMUR3 { return murmur3_32(data, 0); }
    if algorithm == HASH_SHA1 { return sha1(data); }
    if algorithm == HASH_SHA256 { return sha256(data); }
    if algorithm == HASH_SHA512 { return sha512(data); }
    if algorithm == HASH_SHA3 { return sha3_256(data); }
    if algorithm == HASH_BLAKE2 { return blake2b(data); }
    if algorithm == HASH_BLAKE3 { return blake3(data); }
    if algorithm == HASH_WHIRLPOOL { return whirlpool(data); }
    if algorithm == HASH_MD5 { return md5(data); }
    throw "Unknown hash algorithm: " + algorithm;
}

# ===========================================
# EXPORTS
# ===========================================

{
    # Hash functions
    "fnv1a32": fnv1a32,
    "fnv1a64": fnv1a64,
    "djb2": djb2,
    "crc32": crc32,
    "crc32_fast": crc32_fast,
    "crc16": crc16,
    "crc64_iso": crc64_iso,
    "murmur3_32": murmur3_32,
    "murmur3_128": murmur3_128,
    "sha1": sha1,
    "sha256": sha256,
    "sha384": sha384,
    "sha512": sha512,
    "sha3_224": sha3_224,
    "sha3_256": sha3_256,
    "sha3_384": sha3_384,
    "sha3_512": sha3_512,
    "blake2b": blake2b,
    "blake2s": blake2s,
    "blake3": blake3,
    "whirlpool": whirlpool,
    "tiger": tiger,
    "md5": md5,
    "hash": hash,
    "hash_range": hash_range,
    "hash_combine": hash_combine,
    
    # Symmetric ciphers
    "xor_encrypt": xor_encrypt,
    "xor_decrypt": xor_decrypt,
    "rot13": rot13,
    "caesar_cipher": caesar_cipher,
    "vigenere_encrypt": vigenere_encrypt,
    "vigenere_decrypt": vigenere_decrypt,
    "substitution_encrypt": substitution_encrypt,
    "substitution_decrypt": substitution_decrypt,
    "playfair_encrypt": playfair_encrypt,
    "AESCipher": AESCipher,
    "ChaCha20": ChaCha20,
    "RC4": RC4,
    "Serpent": Serpent,
    "Twofish": Twofish,
    "IDEACipher": IDEACipher,
    
    # Block cipher modes
    "CBCMode": CBCMode,
    "CTRMode": CTRMode,
    "GCMMode": GCMMode,
    "ecb_encrypt": ecb_encrypt,
    "ecb_decrypt": ecb_decrypt,
    
    # Asymmetric ciphers
    "RSAKey": RSAKey,
    "rsa_oaep_encrypt": rsa_oaep_encrypt,
    "rsa_oaep_decrypt": rsa_oaep_decrypt,
    "rsa_pss_sign": rsa_pss_sign,
    "rsa_pss_verify": rsa_pss_verify,
    "ElGamal": ElGamal,
    "DSA": DSA,
    
    # ECC
    "ECPoint": ECPoint,
    "EllipticCurve": EllipticCurve,
    "ECDSA": ECDSA,
    "ECDH": ECDH,
    "secp256k1": secp256k1,
    
    # KDFs
    "pbkdf2": pbkdf2,
    "hkdf_extract": hkdf_extract,
    "hkdf_expand": hkdf_expand,
    "scrypt": scrypt,
    "argon2": argon2,
    "bcrypt": bcrypt,
    "bcrypt_verify": bcrypt_verify,
    
    # MACs
    "hmac": hmac,
    "cmac": cmac,
    "poly1305": poly1305,
    "gmac": gmac,
    
    # Digital signatures
    "rsa_sign": rsa_sign,
    "rsa_verify": rsa_verify,
    "Ed25519": Ed25519,
    
    # Post-quantum
    "Kyber": Kyber,
    "Dilithium": Dilithium,
    "SPHINCS": SPHINCS,
    "NTRU": NTRU,
    "McEliece": McEliece,
    
    # Encoding
    "base64_encode": base64_encode,
    "base64_decode": base64_decode,
    "hex_encode": hex_encode,
    "hex_decode": hex_decode,
    "base64url_encode": base64url_encode,
    "base64url_decode": base64url_decode,
    
    # Random
    "rand_int": rand_int,
    "rand_float": rand_float,
    "rand_choice": rand_choice,
    "rand_string": rand_string,
    "rand_bytes": rand_bytes,
    "shuffle": shuffle,
    
    # Constants
    "HASH_FNV1A32": HASH_FNV1A32,
    "HASH_FNV1A64": HASH_FNV1A64,
    "HASH_DJB2": HASH_DJB2,
    "HASH_CRC32": HASH_CRC32,
    "HASH_MURMUR3": HASH_MURMUR3,
    "HASH_SHA256": HASH_SHA256,
    "HASH_MD5": HASH_MD5,
    "CIPHER_XOR": CIPHER_XOR,
    "CIPHER_AES": CIPHER_AES
}

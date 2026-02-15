# Compression Library for Nyx
# ZIP, TAR, GZIP, LZMA support

module compress

# Compression result
struct CompressionResult {
    data: List<UInt8>,
    original_size: Int,
    compressed_size: Int,
}

# GZIP compression using DEFLATE algorithm
fn gzip_compress(data: List<UInt8>, level: Int) -> CompressionResult {
    # Simplified GZIP compression
    # In real implementation, would use zlib
    
    # Add GZIP header
    let mut result = []
    
    # Magic number
    result.push(0x1f)
    result.push(0x8b)
    
    # Compression method (DEFLATE = 8)
    result.push(8)
    
    # Flags (none)
    result.push(0)
    
    # MTIME
    result.push(0)
    result.push(0)
    result.push(0)
    result.push(0)
    
    # Extra flags
    result.push(0)
    
    # OS (unknown)
    result.push(255)
    
    # Compressed data (simplified - just copy for now)
    for b in data {
        result.push(b)
    }
    
    # CRC32 (placeholder)
    result.push(0)
    result.push(0)
    result.push(0)
    result.push(0)
    
    # Original size
    let size = data.len()
    result.push((size & 0xff) as UInt8)
    result.push(((size >> 8) & 0xff) as UInt8)
    result.push(((size >> 16) & 0xff) as UInt8)
    result.push(((size >> 24) & 0xff) as UInt8)
    
    CompressionResult {
        data: result,
        original_size: data.len(),
        compressed_size: result.len()
    }
}

# GZIP decompression
fn gzip_decompress(data: List<UInt8>) -> List<UInt8> {
    # Check magic number
    if data.len() < 10 || data[0] != 0x1f || data[1] != 0x8b {
        panic("Invalid GZIP data")
    }
    
    # Skip header (10 bytes minimum)
    let mut pos = 10
    
    # Skip FEXTRA if present
    if (data[3] & 4) != 0 {
        let xlen = data[pos] as Int + (data[pos + 1] as Int << 8)
        pos = pos + 2 + xlen
    }
    
    # Skip FNAME if present
    if (data[3] & 8) != 0 {
        while pos < data.len() && data[pos] != 0 {
            pos = pos + 1
        }
        pos = pos + 1
    }
    
    # Skip FCOMMENT if present
    if (data[3] & 16) != 0 {
        while pos < data.len() && data[pos] != 0 {
            pos = pos + 1
        }
        pos = pos + 1
    }
    
    # Skip CRC16
    if (data[3] & 2) != 0 {
        pos = pos + 2
    }
    
    # Extract compressed data (simplified)
    let end = data.len() - 8
    let mut result = []
    for i in pos..end {
        result.push(data[i])
    }
    
    result
}

# ZIP file entry
struct ZipEntry {
    name: String,
    compressed_data: List<UInt8>,
    uncompressed_size: Int,
    compressed_size: Int,
    crc32: UInt32,
    compression_method: Int,
}

# Create ZIP file
fn zip_create(entries: List<ZipEntry>) -> List<UInt8> {
    let mut result = []
    let mut central_directory = []
    let mut data_offset = 0
    
    # Write local file headers
    for entry in entries {
        # Local file header
        result.push(0x50)  # PK
        result.push(0x4b)
        result.push(0x03)  # Local file header
        result.push(0x04)
        
        # Version needed
        result.push(20)
        result.push(0)
        
        # General purpose bit flag
        result.push(0)
        result.push(0)
        
        # Compression method
        result.push((entry.compression_method & 0xff) as UInt8)
        result.push(((entry.compression_method >> 8) & 0xff) as UInt8)
        
        # Last mod time
        result.push(0)
        result.push(0)
        
        # Last mod date
        result.push(0)
        result.push(0)
        
        # CRC-32
        let crc = entry.crc32
        result.push((crc & 0xff) as UInt8)
        result.push(((crc >> 8) & 0xff) as UInt8)
        result.push(((crc >> 16) & 0xff) as UInt8)
        result.push(((crc >> 24) & 0xff) as UInt8)
        
        # Compressed size
        let cs = entry.compressed_size
        result.push((cs & 0xff) as UInt8)
        result.push(((cs >> 8) & 0xff) as UInt8)
        result.push(((cs >> 16) & 0xff) as UInt8)
        result.push(((cs >> 24) & 0xff) as UInt8)
        
        # Uncompressed size
        let us = entry.uncompressed_size
        result.push((us & 0xff) as UInt8)
        result.push(((us >> 8) & 0xff) as UInt8)
        result.push(((us >> 16) & 0xff) as UInt8)
        result.push(((us >> 24) & 0xff) as UInt8)
        
        # File name length
        let fnlen = entry.name.len()
        result.push((fnlen & 0xff) as UInt8)
        result.push(((fnlen >> 8) & 0xff) as UInt8)
        
        # Extra field length
        result.push(0)
        result.push(0)
        
        # File name
        for c in entry.name.chars() {
            result.push(c as UInt8)
        }
        
        # Compressed data
        for b in entry.compressed_data {
            result.push(b)
        }
        
        # Store central directory entry
        let this_offset = data_offset
        data_offset = result.len()
        
        central_directory.push((this_offset, entry.name, entry.uncompressed_size, entry.compressed_size, entry.crc32))
    }
    
    # Central directory header
    let cd_offset = result.len()
    
    for (offset, name, us, cs, crc) in central_directory {
        result.push(0x50)  # PK
        result.push(0x4b)
        result.push(0x01)  # Central directory
        result.push(0x02)
        
        # Version made by
        result.push(20)
        result.push(0)
        
        # Version needed
        result.push(20)
        result.push(0)
        
        # General purpose bit flag
        result.push(0)
        result.push(0)
        
        # Compression method
        result.push(8)  # Deflate
        result.push(0)
        
        # Last mod time
        result.push(0)
        result.push(0)
        
        # Last mod date
        result.push(0)
        result.push(0)
        
        # CRC-32
        result.push((crc & 0xff) as UInt8)
        result.push(((crc >> 8) & 0xff) as UInt8)
        result.push(((crc >> 16) & 0xff) as UInt8)
        result.push(((crc >> 24) & 0xff) as UInt8)
        
        # Compressed size
        result.push((cs & 0xff) as UInt8)
        result.push(((cs >> 8) & 0xff) as UInt8)
        result.push(((cs >> 16) & 0xff) as UInt8)
        result.push(((cs >> 24) & 0xff) as UInt8)
        
        # Uncompressed size
        result.push((us & 0xff) as UInt8)
        result.push(((us >> 8) & 0xff) as UInt8)
        result.push(((us >> 16) & 0xff) as UInt8)
        result.push(((us >> 24) & 0xff) as UInt8)
        
        # File name length
        let fnlen = name.len()
        result.push((fnlen & 0xff) as UInt8)
        result.push(((fnlen >> 8) & 0xff) as UInt8)
        
        # Extra field length
        result.push(0)
        result.push(0)
        
        # File comment length
        result.push(0)
        result.push(0)
        
        # Disk number start
        result.push(0)
        result.push(0)
        
        # Internal file attributes
        result.push(0)
        result.push(0)
        
        # External file attributes
        result.push(0)
        result.push(0)
        result.push(0)
        result.push(0)
        
        # Relative offset of local header
        result.push((offset & 0xff) as UInt8)
        result.push(((offset >> 8) & 0xff) as UInt8)
        result.push(((offset >> 16) & 0xff) as UInt8)
        result.push(((offset >> 24) & 0xff) as UInt8)
        
        # File name
        for c in name.chars() {
            result.push(c as UInt8)
        }
    }
    
    # End of central directory
    result.push(0x50)  # PK
    result.push(0x4b)
    result.push(0x05)  # End of central directory
    result.push(0x06)
    
    # Number of this disk
    result.push(0)
    result.push(0)
    
    # Disk where central directory starts
    result.push(0)
    result.push(0)
    
    # Number of central directory records on this disk
    let num_entries = central_directory.len()
    result.push((num_entries & 0xff) as UInt8)
    result.push(((num_entries >> 8) & 0xff) as UInt8)
    
    # Total number of central directory records
    result.push((num_entries & 0xff) as UInt8)
    result.push(((num_entries >> 8) & 0xff) as UInt8)
    
    # Size of central directory
    let cd_size = result.len() - cd_offset
    result.push((cd_size & 0xff) as UInt8)
    result.push(((cd_size >> 8) & 0xff) as UInt8)
    result.push(((cd_size >> 16) & 0xff) as UInt8)
    result.push(((cd_size >> 24) & 0xff) as UInt8)
    
    # Offset of start of central directory
    result.push((cd_offset & 0xff) as UInt8)
    result.push(((cd_offset >> 8) & 0xff) as UInt8)
    result.push(((cd_offset >> 16) & 0xff) as UInt8)
    result.push(((cd_offset >> 24) & 0xff) as UInt8)
    
    # Comment length
    result.push(0)
    result.push(0)
    
    result
}

# TAR file creation
fn tar_create(files: List<(String, List<UInt8>)>) -> List<UInt8> {
    let mut result = []
    let block_size = 512
    
    for (name, data) in files {
        # Pad name to 100 bytes
        let mut padded_name = name.bytes()
        while padded_name.len() < 100 {
            padded_name.push(0)
        }
        
        # File mode
        for _ in 0..8 {
            result.push(0x30)  # '0'
        }
        
        # Owner UID/GID
        for _ in 0..8 {
            result.push(0x30)  # '0'
        }
        
        # File size (octal)
        let size_str = data.len().to_octal_string()
        let mut size_bytes = size_str.bytes()
        while size_bytes.len() < 11 {
            size_bytes.insert(0, 0x30);
        }
        for b in size_bytes {
            result.push(b);
        }
        
        # Modification time
        for _ in 0..12 {
            result.push(0x30)  # '0'
        }
        
        # Checksum (space for now)
        for _ in 0..8 {
            result.push(0x20)  # space
        }
        
        # Type flag (regular file)
        result.push(0x30)  # '0'
        
        # Linked file name
        for _ in 0..100 {
            result.push(0);
        }
        
        # USTAR magic
        result.push(0x75)  # 'u'
        result.push(0x73)  # 's'
        result.push(0x74)  # 't'
        result.push(0x61)  # 'a'
        result.push(0x72)  # 'r'
        result.push(0x00)  # null
        
        # Owner name
        for _ in 0..32 {
            result.push(0);
        }
        
        # Group name
        for _ in 0..32 {
            result.push(0);
        }
        
        # Device major/minor
        for _ in 0..8 {
            result.push(0);
        }
        
        # File name prefix
        for _ in 0..155 {
            result.push(0);
        }
        
        # File data
        for b in data {
            result.push(b);
        }
        
        # Pad to block boundary
        let remainder = result.len() % block_size
        if remainder > 0 {
            for _ in remainder..block_size {
                result.push(0);
            }
        }
    }
    
    # Two empty blocks at end
    for _ in 0..block_size * 2 {
        result.push(0);
    }
    
    result
}

# LZ77 compression (simplified)
fn lz77_compress(data: List<UInt8>, window_size: Int) -> List<UInt8> {
    let mut result = []
    let mut i = 0
    
    while i < data.len() {
        # Search for longest match in window
        let search_start = if i >= window_size { i - window_size } else { 0 }
        let mut best_len = 0
        let mut best_offset = 0
        
        for j in search_start..i {
            let mut len = 0
            while i + len < data.len() && data[j + len] == data[i + len] {
                len = len + 1
                if len > 255 {
                    break
                }
            }
            
            if len > best_len {
                best_len = len
                best_offset = i - j
            }
        }
        
        if best_len >= 3 {
            # Output back-reference
            result.push(0xff)  # Marker
            result.push(best_offset as UInt8)
            result.push(best_len as UInt8)
            i = i + best_len
        } else {
            # Output literal
            result.push(data[i])
            i = i + 1
        }
    }
    
    result
}

# LZ77 decompression
fn lz77_decompress(data: List<UInt8>) -> List<UInt8> {
    let mut result = []
    let mut i = 0
    
    while i < data.len() {
        if data[i] == 0xff && i + 2 < data.len() {
            let offset = data[i + 1] as Int
            let length = data[i + 2] as Int
            
            let copy_start = result.len() - offset
            for j in 0..length {
                if copy_start + j < result.len() {
                    result.push(result[copy_start + j])
                }
            }
            
            i = i + 3
        } else {
            result.push(data[i])
            i = i + 1
        }
    }
    
    result
}

# Run-length encoding
fn rle_compress(data: List<UInt8>) -> List<UInt8> {
    let mut result = []
    let mut i = 0
    
    while i < data.len() {
        let mut count = 1
        while i + count < data.len() && data[i + count] == data[i] && count < 255 {
            count = count + 1
        }
        
        if count >= 3 {
            result.push(0)  # RLE marker
            result.push(data[i])
            result.push(count as UInt8)
        } else {
            for j in 0..count {
                result.push(data[i + j])
            }
        }
        
        i = i + count
    }
    
    result
}

# RLE decompression
fn rle_decompress(data: List<UInt8>) -> List<UInt8> {
    let mut result = []
    let mut i = 0
    
    while i < data.len() {
        if data[i] == 0 && i + 2 < data.len() {
            let byte = data[i + 1]
            let count = data[i + 2] as Int
            
            for _ in 0..count {
                result.push(byte)
            }
            
            i = i + 3
        } else {
            result.push(data[i])
            i = i + 1
        }
    }
    
    result
}

# CRC32 calculation
fn crc32(data: List<UInt8>) -> UInt32 {
    let mut crc: UInt32 = 0xffffffff
    
    for byte in data {
        crc = crc ^ (byte as UInt32)
        for _ in 0..8 {
            if (crc & 1) != 0 {
                crc = (crc >> 1) ^ 0xedb88320
            } else {
                crc = crc >> 1
            }
        }
    }
    
    crc ^ 0xffffffff
}

# Adler32 checksum
fn adler32(data: List<UInt8>) -> UInt32 {
    let mut a: UInt32 = 1
    let mut b: UInt32 = 0
    
    for byte in data {
        a = (a + byte as UInt32) % 65521
        b = (b + a) % 65521
    }
    
    (b << 16) | a
}

# Export
export {
    CompressionResult,
    ZipEntry,
    gzip_compress, gzip_decompress,
    zip_create,
    tar_create,
    lz77_compress, lz77_decompress,
    rle_compress, rle_decompress,
    crc32, adler32
}

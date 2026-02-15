# ===========================================
# Nyx Standard Library - IO Module
# ===========================================
# File and stream I/O utilities

# Read entire file as string
fn read_file(path) {
    let content = "";
    let f = open(path, "r");
    if f == null {
        throw "read_file: could not open file: " + path;
    }
    while true {
        let chunk = read(f, 1024);
        if len(chunk) == 0 {
            break;
        }
        content = content + chunk;
    }
    close(f);
    return content;
}

# Read file as lines
fn read_lines(path) {
    let content = read_file(path);
    return split(content, "\n");
}

# Read first n lines
fn read_nlines(path, n) {
    let lines = read_lines(path);
    return lines[:n];
}

# Write string to file
fn write_file(path, content) {
    let f = open(path, "w");
    if f == null {
        throw "write_file: could not open file: " + path;
    }
    write(f, content);
    close(f);
    return;
}

# Append to file
fn append_file(path, content) {
    let f = open(path, "a");
    if f == null {
        throw "append_file: could not open file: " + path;
    }
    write(f, content);
    close(f);
    return;
}

# Check if file exists
fn file_exists(path) {
    let f = open(path, "r");
    if f != null {
        close(f);
        return true;
    }
    return false;
}

# Get file size
fn file_size(path) {
    let f = open(path, "r");
    if f == null {
        throw "file_size: could not open file: " + path;
    }
    seek(f, 0, 2);
    let size = tell(f);
    close(f);
    return size;
}

# Copy file
fn copy_file(src, dst) {
    let content = read_file(src);
    write_file(dst, content);
}

# Move/rename file
fn move_file(src, dst) {
    copy_file(src, dst);
    delete_file(src);
}

# Delete file
fn delete_file(path) {
    # Would need native implementation
    throw "delete_file: not implemented";
}

# Create directory
fn mkdir(path) {
    # Would need native implementation
    throw "mkdir: not implemented";
}

# Create directory recursively
fn mkdir_p(path) {
    let parts = split(path, "/");
    let current = "";
    for part in parts {
        if len(current) > 0 {
            current = current + "/";
        }
        current = current + part;
        try {
            mkdir(current);
        } catch e {
            # Ignore if already exists
        }
    }
}

# List directory
fn list_dir(path) {
    # Would need native implementation
    throw "list_dir: not implemented";
}

# Get file extension
fn file_ext(path) {
    let idx = rfind(path, ".");
    if idx < 0 {
        return "";
    }
    return path[idx + 1:];
}

# Get filename without extension
fn file_stem(path) {
    let idx = rfind(path, "/");
    if idx < 0 {
        idx = rfind(path, "\\");
    }
    let filename = path;
    if idx >= 0 {
        filename = path[idx + 1:];
    }
    
    let dot_idx = rfind(filename, ".");
    if dot_idx < 0 {
        return filename;
    }
    return filename[:dot_idx];
}

# Get directory name
fn dirname(path) {
    let idx = rfind(path, "/");
    if idx < 0 {
        idx = rfind(path, "\\");
    }
    if idx < 0 {
        return ".";
    }
    return path[:idx];
}

# Get base filename
fn basename(path) {
    let idx = rfind(path, "/");
    if idx < 0 {
        idx = rfind(path, "\\");
    }
    if idx < 0 {
        return path;
    }
    return path[idx + 1:];
}

# Join path components
fn join_path(...parts) {
    let result = "";
    for i in range(len(parts)) {
        if i > 0 {
            # Add separator if needed
            if !endswith(result, "/") && !endswith(result, "\\") {
                result = result + "/";
            }
        }
        result = result + parts[i];
    }
    return result;
}

# Normalize path
fn normalize_path(path) {
    # Replace backslashes with forward slashes
    let result = replace(path, "\\", "/");
    # Remove duplicate slashes
    while contains(result, "//") {
        result = replace(result, "//", "/");
    }
    # Remove trailing slash (except for root)
    if len(result) > 1 && endswith(result, "/") {
        result = result[:len(result) - 1];
    }
    return result;
}

# Absolute path
fn abs_path(path) {
    # Would need native implementation
    return path;
}

# File class with methods
class File {
    fn init(self, path, mode) {
        self.path = path;
        self.mode = mode;
        self.handle = open(path, mode);
        if self.handle == null {
            throw "File: could not open " + path + " with mode " + mode;
        }
    }
    
    fn read(self, size) {
        if type(size) == "null" {
            # Read entire file
            let content = "";
            while true {
                let chunk = read(self.handle, 1024);
                if len(chunk) == 0 {
                    break;
                }
                content = content + chunk;
            }
            return content;
        }
        return read(self.handle, size);
    }
    
    fn read_line(self) {
        return readline(self.handle);
    }
    
    fn read_lines(self) {
        let lines = [];
        while true {
            let line = readline(self.handle);
            if line == null {
                break;
            }
            push(lines, line);
        }
        return lines;
    }
    
    fn write(self, content) {
        write(self.handle, content);
    }
    
    fn write_line(self, line) {
        write(self.handle, line + "\n");
    }
    
    fn seek(self, offset, whence) {
        return seek(self.handle, offset, whence);
    }
    
    fn tell(self) {
        return tell(self.handle);
    }
    
    fn flush(self) {
        # Would need native implementation
    }
    
    fn close(self) {
        close(self.handle);
        self.handle = null;
    }
    
    fn is_closed(self) {
        return self.handle == null;
    }
    
    fn is_eof(self) {
        # Would need native implementation
        return false;
    }
}

# Open file with context manager pattern
fn file(path, mode) {
    return File(path, mode);
}

# Buffered writer
class BufferedWriter {
    fn init(self, path, buffer_size) {
        if type(buffer_size) == "null" {
            buffer_size = 4096;
        }
        self.path = path;
        self.buffer_size = buffer_size;
        self.buffer = "";
        self.file = File(path, "w");
    }
    
    fn write(self, content) {
        self.buffer = self.buffer + content;
        if len(self.buffer) >= self.buffer_size {
            self.flush();
        }
    }
    
    fn flush(self) {
        if len(self.buffer) > 0 {
            self.file.write(self.buffer);
            self.buffer = "";
        }
    }
    
    fn close(self) {
        self.flush();
        self.file.close();
    }
}

# Buffered reader
class BufferedReader {
    fn init(self, path, buffer_size) {
        if type(buffer_size) == "null" {
            buffer_size = 4096;
        }
        self.path = path;
        self.buffer_size = buffer_size;
        self.file = File(path, "r");
        self.buffer = "";
        self.pos = 0;
    }
    
    fn read(self, size) {
        if type(size) == "null" || size > len(self.buffer) - self.pos {
            # Need to read more
            while len(self.buffer) - self.pos < size {
                let chunk = self.file.read(self.buffer_size);
                if len(chunk) == 0 {
                    break;
                }
                self.buffer = self.buffer + chunk;
            }
        }
        
        if type(size) == "null" {
            let result = self.buffer[self.pos:];
            self.pos = len(self.buffer);
            return result;
        }
        
        let result = self.buffer[self.pos:self.pos + size];
        self.pos = self.pos + size;
        return result;
    }
    
    fn read_line(self) {
        # Find newline
        while true {
            let newline_idx = -1;
            for i in range(self.pos, len(self.buffer)) {
                if self.buffer[i] == "\n" {
                    newline_idx = i;
                    break;
                }
            }
            
            if newline_idx >= 0 {
                let line = self.buffer[self.pos:newline_idx];
                self.pos = newline_idx + 1;
                return line;
            }
            
            # Read more
            let chunk = self.file.read(self.buffer_size);
            if len(chunk) == 0 {
                if self.pos < len(self.buffer) {
                    let line = self.buffer[self.pos:];
                    self.pos = len(self.buffer);
                    return line;
                }
                return null;
            }
            self.buffer = self.buffer + chunk;
        }
    }
    
    fn close(self) {
        self.file.close();
    }
}

# File watcher (simplified)
class FileWatcher {
    fn init(self, path) {
        self.path = path;
        self.last_mtime = null;
    }
    
    fn has_changed(self) {
        # Would need native implementation
        # Simplified version - always returns false
        return false;
    }
    
    fn wait_for_change(self, timeout) {
        # Would need native implementation
        throw "wait_for_change: not implemented";
    }
}

# Temporary file
class TempFile {
    fn init(self, prefix, suffix) {
        if type(prefix) == "null" {
            prefix = "nyx_";
        }
        if type(suffix) == "null" {
            suffix = ".tmp";
        }
        # Generate unique name
        let timestamp = now_millis();
        self.path = "/tmp/" + prefix + str(timestamp) + suffix;
        self.file = File(self.path, "w");
    }
    
    fn write(self, content) {
        self.file.write(content);
    }
    
    fn read(self) {
        self.file.close();
        return read_file(self.path);
    }
    
    fn close(self) {
        self.file.close();
    }
    
    fn unlink(self) {
        delete_file(self.path);
    }
}

# Directory walker
class DirectoryWalker {
    fn init(self, path) {
        self.path = path;
        self.entries = [];
        # Would need native implementation to get actual entries
    }
    
    fn walk(self, callback) {
        # Would need native implementation
        throw "walk: not implemented";
    }
}

# Get file metadata
fn file_info(path) {
    # Would need native implementation
    return {
        path: path,
        size: file_size(path),
        exists: file_exists(path)
    };
}

# Check if path is absolute
fn is_absolute(path) {
    if len(path) > 0 && (path[0] == "/" || path[1] == ":") {
        return true;
    }
    return false;
}

# Get relative path
fn rel_path(path, start) {
    # Would need native implementation
    return path;
}

# Common IOError class
class IOError {
    fn init(self, message) {
        self.message = message;
    }
    
    fn to_string(self) {
        return "IOError: " + self.message;
    }
}

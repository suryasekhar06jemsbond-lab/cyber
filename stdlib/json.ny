# ===========================================
# Nyx Standard Library - JSON Module
# ===========================================
# JSON parsing and serialization

# Parse JSON string to Nyx value
fn parse(json_str) {
    let parser = _JsonParser(json_str);
    return parser.parse();
}

# Convert Nyx value to JSON string
fn stringify(value) {
    return _json_stringify(value, false);
}

# Pretty print JSON
fn pretty(value) {
    return _json_stringify(value, true);
}

# Internal stringify function
fn _json_stringify(value, pretty) {
    let t = type(value);
    
    if t == "null" {
        return "null";
    }
    if t == "bool" {
        return (if value { "true" } else { "false" });
    }
    if t == "int" || t == "float" {
        return str(value);
    }
    if t == "string" {
        return _json_escape_string(value);
    }
    if t == "array" {
        return _json_stringify_array(value, pretty);
    }
    if t == "object" {
        return _json_stringify_object(value, pretty);
    }
    
    throw "json.stringify: unsupported type " + t;
}

fn _json_escape_string(s) {
    let result = "\"";
    for i in range(len(s)) {
        let c = s[i];
        if c == "\"" {
            result = result + "\\\"";
        } else if c == "\\" {
            result = result + "\\\\";
        } else if c == "\n" {
            result = result + "\\n";
        } else if c == "\r" {
            result = result + "\\r";
        } else if c == "\t" {
            result = result + "\\t";
        } else if c == "\b" {
            result = result + "\\b";
        } else if c == "\f" {
            result = result + "\\f";
        } else if int(c) < 32 {
            result = result + "\\u" + _pad_hex(int(c));
        } else {
            result = result + c;
        }
    }
    return result + "\"";
}

fn _pad_hex(n) {
    let hex = "";
    while n > 0 {
        let remainder = n % 16;
        if remainder < 10 {
            hex = chr(48 + remainder) + hex;
        } else {
            hex = chr(97 + remainder - 10) + hex;
        }
        n = n / 16;
    }
    while len(hex) < 4 {
        hex = "0" + hex;
    }
    return hex;
}

fn _json_stringify_array(arr, pretty) {
    if len(arr) == 0 {
        return "[]";
    }
    
    let parts = [];
    for item in arr {
        push(parts, _json_stringify(item, pretty));
    }
    
    if pretty {
        return "[" + join(parts, ", ") + "]";
    }
    return "[" + join(parts, ",") + "]";
}

fn _json_stringify_object(obj, pretty) {
    if len(obj) == 0 {
        return "{}";
    }
    
    let parts = [];
    let keys = _object_keys(obj);
    for key in keys {
        let value = _object_get(obj, key);
        let pair = _json_escape_string(key) + ": " + _json_stringify(value, pretty);
        push(parts, pair);
    }
    
    if pretty {
        return "{" + join(parts, ", ") + "}";
    }
    return "{" + join(parts, ",") + "}";
}

# Simple object helpers (would be builtins in real implementation)
fn _object_keys(obj) {
    let keys = [];
    for k in obj {
        push(keys, k);
    }
    return keys;
}

fn _object_get(obj, key) {
    for i in range(0, len(obj), 2) {
        if obj[i] == key {
            return obj[i + 1];
        }
    }
    return null;
}

# JSON Parser class
class _JsonParser {
    fn init(self, s) {
        self.s = s;
        self.pos = 0;
        self.len = len(s);
    }
    
    fn parse(self) {
        self._skip_whitespace();
        return self._parse_value();
    }
    
    fn _skip_whitespace(self) {
        while self.pos < self.len {
            let c = self.s[self.pos];
            if c == " " || c == "\n" || c == "\r" || c == "\t" {
                self.pos = self.pos + 1;
            } else {
                break;
            }
        }
    }
    
    fn _parse_value(self) {
        self._skip_whitespace();
        if self.pos >= self.len {
            throw "json.parse: unexpected end of input";
        }
        
        let c = self.s[self.pos];
        
        if c == "{" {
            return self._parse_object();
        }
        if c == "[" {
            return self._parse_array();
        }
        if c == "\"" {
            return self._parse_string();
        }
        if c == "t" || c == "f" {
            return self._parse_bool();
        }
        if c == "n" {
            return self._parse_null();
        }
        if c == "-" || (c >= "0" && c <= "9") {
            return self._parse_number();
        }
        
        throw "json.parse: unexpected character " + c;
    }
    
    fn _parse_object(self) {
        self.pos = self.pos + 1;  # skip {
        self._skip_whitespace();
        
        let obj = [];
        
        if self.pos < self.len && self.s[self.pos] == "}" {
            self.pos = self.pos + 1;
            return obj;
        }
        
        while true {
            self._skip_whitespace();
            
            # Expect key
            if self.s[self.pos] != "\"" {
                throw "json.parse: expected string key";
            }
            let key = self._parse_string();
            
            self._skip_whitespace();
            
            # Expect colon
            if self.pos >= self.len || self.s[self.pos] != ":" {
                throw "json.parse: expected colon";
            }
            self.pos = self.pos + 1;
            
            # Parse value
            let value = self._parse_value();
            
            push(obj, key);
            push(obj, value);
            
            self._skip_whitespace();
            
            if self.pos >= self.len {
                throw "json.parse: unexpected end in object";
            }
            
            if self.s[self.pos] == "}" {
                self.pos = self.pos + 1;
                break;
            }
            
            if self.s[self.pos] == "," {
                self.pos = self.pos + 1;
            } else {
                throw "json.parse: expected comma or closing brace";
            }
        }
        
        return obj;
    }
    
    fn _parse_array(self) {
        self.pos = self.pos + 1;  # skip [
        self._skip_whitespace();
        
        let arr = [];
        
        if self.pos < self.len && self.s[self.pos] == "]" {
            self.pos = self.pos + 1;
            return arr;
        }
        
        while true {
            let value = self._parse_value();
            push(arr, value);
            
            self._skip_whitespace();
            
            if self.pos >= self.len {
                throw "json.parse: unexpected end in array";
            }
            
            if self.s[self.pos] == "]" {
                self.pos = self.pos + 1;
                break;
            }
            
            if self.s[self.pos] == "," {
                self.pos = self.pos + 1;
            } else {
                throw "json.parse: expected comma or closing bracket";
            }
        }
        
        return arr;
    }
    
    fn _parse_string(self) {
        if self.s[self.pos] != "\"" {
            throw "json.parse: expected quote";
        }
        self.pos = self.pos + 1;
        
        let result = "";
        while self.pos < self.len {
            let c = self.s[self.pos];
            if c == "\"" {
                self.pos = self.pos + 1;
                return result;
            }
            if c == "\\" {
                self.pos = self.pos + 1;
                if self.pos >= self.len {
                    throw "json.parse: unexpected end in escape";
                }
                c = self.s[self.pos];
                if c == "n" {
                    result = result + "\n";
                } else if c == "r" {
                    result = result + "\r";
                } else if c == "t" {
                    result = result + "\t";
                } else if c == "\\" {
                    result = result + "\\";
                } else if c == "\"" {
                    result = result + "\"";
                } else if c == "u" {
                    # Unicode - simplified
                    self.pos = self.pos + 1;
                    let hex = "";
                    for i in range(4) {
                        hex = hex + self.s[self.pos + i];
                    }
                    result = result + chr(int("0x" + hex));
                    self.pos = self.pos + 4;
                } else {
                    result = result + c;
                }
            } else {
                result = result + c;
            }
            self.pos = self.pos + 1;
        }
        
        throw "json.parse: unterminated string";
    }
    
    fn _parse_number(self) {
        let start = self.pos;
        
        if self.s[self.pos] == "-" {
            self.pos = self.pos + 1;
        }
        
        while self.pos < self.len {
            let c = self.s[self.pos];
            if (c >= "0" && c <= "9") || c == "." || c == "e" || c == "E" || c == "+" || c == "-" {
                self.pos = self.pos + 1;
            } else {
                break;
            }
        }
        
        let num_str = self.s[start:self.pos];
        
        # Check if integer or float
        if contains(num_str, ".") || contains(num_str, "e") || contains(num_str, "E") {
            return float(num_str);
        }
        return int(num_str);
    }
    
    fn _parse_bool(self) {
        if self.s[self.pos] == "t" {
            if self.s[self.pos:self.pos+4] == "true" {
                self.pos = self.pos + 4;
                return true;
            }
        }
        if self.s[self.pos] == "f" {
            if self.s[self.pos:self.pos+5] == "false" {
                self.pos = self.pos + 5;
                return false;
            }
        }
        throw "json.parse: invalid boolean";
    }
    
    fn _parse_null(self) {
        if self.s[self.pos:self.pos+4] == "null" {
            self.pos = self.pos + 4;
            return null;
        }
        throw "json.parse: invalid null";
    }
}

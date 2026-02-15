# Configuration File Parser for Nyx
# TOML, YAML, and INI support

module config

# Configuration value types
enum ConfigValue {
    String(String),
    Int(Int),
    Float(Float),
    Bool(Bool),
    List(List<ConfigValue>),
    Table(Map<String, ConfigValue>),
    Array(Array<ConfigValue>),
}

# Parse result
struct Config {
    values: Map<String, ConfigValue>,
}

# TOML Parser

# Parse TOML string
fn parse_toml(content: String) -> Config {
    let mut values = {}
    let mut current_section = ""
    let mut current_table = {}
    let mut in_array = false
    let mut array_values: List<ConfigValue> = []
    let mut array_key = ""
    
    let lines = content.split("\n")
    
    for line in lines {
        let line = line.trim()
        
        # Skip empty lines and comments
        if line.len() == 0 || line.starts_with("#") {
            continue
        }
        
        # Section header
        if line.starts_with("[") && line.ends_with("]") {
            # Save previous table
            if current_section.len() > 0 {
                values[current_section] = ConfigValue::Table(current_table)
            }
            
            current_section = line.substring(1, line.len() - 1)
            current_table = {}
            continue
        }
        
        # Key-value pair
        if line.contains("=") {
            let parts = line.split("=")
            let key = parts[0].trim()
            let value = parts[1].trim()
            
            let parsed_value = parse_toml_value(value)
            
            if current_section.len() > 0 {
                current_table[key] = parsed_value
            } else {
                values[key] = parsed_value
            }
        }
    }
    
    # Save last table
    if current_section.len() > 0 {
        values[current_section] = ConfigValue::Table(current_table)
    }
    
    Config { values }
}

# Parse TOML value
fn parse_toml_value(s: String) -> ConfigValue {
    let s = s.trim()
    
    # Boolean
    if s == "true" {
        return ConfigValue::Bool(true)
    }
    if s == "false" {
        return ConfigValue::Bool(false)
    }
    
    # Integer
    match s.parse_int() {
        Some(n) => return ConfigValue::Int(n),
        None => {}
    }
    
    # Float
    match s.parse_float() {
        Some(f) => return ConfigValue::Float(f),
        None => {}
    }
    
    # String (remove quotes)
    if (s.starts_with("\"") && s.ends_with("\"")) || 
       (s.starts_with("'") && s.ends_with("'")) {
        return ConfigValue::String(s.substring(1, s.len() - 1))
    }
    
    # Array
    if s.starts_with("[") && s.ends_with("]") {
        let inner = s.substring(1, s.len() - 1)
        let elements = inner.split(",")
        let values = elements.map(|e| parse_toml_value(e))
        return ConfigValue::List(values)
    }
    
    ConfigValue::String(s)
}

# YAML Parser

# Parse YAML string
fn parse_yaml(content: String) -> Config {
    let mut values = {}
    let lines = content.split("\n")
    
    let mut current_indent = 0
    let mut stack: List<(Int, Map<String, ConfigValue>)> = [(0, values)]
    
    for line in lines {
        let line = line.trim()
        
        if line.len() == 0 || line.starts_with("#") {
            continue
        }
        
        # Count indentation
        let indent = count_leading_spaces(line)
        
        # Key-value pair
        if line.contains(":") {
            let parts = line.split(":")
            let key = parts[0].trim()
            let value = if parts.len() > 1 { parts[1].trim() } else { "" }
            
            # Pop stack to correct level
            while stack.len() > 1 && stack[stack.len() - 1].0 >= indent {
                stack.pop()
            }
            
            let (_, current_map) = stack[stack.len() - 1]
            
            if value.len() == 0 {
                # Nested object
                let new_map = {}
                current_map[key] = ConfigValue::Table(new_map)
                stack.push((indent, new_map))
            } else {
                current_map[key] = parse_yaml_value(value)
            }
        }
    }
    
    Config { values: values }
}

fn count_leading_spaces(s: String) -> Int {
    let mut count = 0
    for c in s.chars() {
        if c == ' ' {
            count = count + 1
        } else {
            break
        }
    }
    count
}

# Parse YAML value
fn parse_yaml_value(s: String) -> ConfigValue {
    let s = s.trim()
    
    # Boolean
    if s == "true" || s == "yes" || s == "on" {
        return ConfigValue::Bool(true)
    }
    if s == "false" || s == "no" || s == "off" {
        return ConfigValue::Bool(false)
    }
    
    # Null
    if s == "null" || s == "~" {
        return ConfigValue::String("null".to_string())
    }
    
    # Integer
    match s.parse_int() {
        Some(n) => return ConfigValue::Int(n),
        None => {}
    }
    
    # Float
    match s.parse_float() {
        Some(f) => return ConfigValue::Float(f),
        None => {}
    }
    
    # String
    ConfigValue::String(s)
}

# INI Parser

# Parse INI string
fn parse_ini(content: String) -> Config {
    let mut values = {}
    let mut current_section = ""
    let mut current_table = {}
    
    let lines = content.split("\n")
    
    for line in lines {
        let line = line.trim()
        
        if line.len() == 0 || line.starts_with(";") || line.starts_with("#") {
            continue
        }
        
        # Section header
        if line.starts_with("[") && line.ends_with("]") {
            if current_section.len() > 0 {
                values[current_section] = ConfigValue::Table(current_table)
            }
            
            current_section = line.substring(1, line.len() - 1)
            current_table = {}
            continue
        }
        
        # Key-value pair
        if line.contains("=") {
            let parts = line.split("=")
            let key = parts[0].trim()
            let value = parts[1].trim()
            
            current_table[key] = ConfigValue::String(value)
        }
    }
    
    if current_section.len() > 0 {
        values[current_section] = ConfigValue::Table(current_table)
    }
    
    Config { values }
}

# Get value from config
fn get(config: Config, key: String) -> Option<ConfigValue> {
    config.values.get(key)
}

# Get nested value
fn get_nested(config: Config, path: String) -> Option<ConfigValue> {
    let keys = path.split(".")
    let mut current: Option<ConfigValue> = None
    
    for key in keys {
        match current {
            Some(ConfigValue::Table(m)) => {
                current = m.get(key)
            },
            _ => return None
        }
    }
    
    current
}

# Get string value
fn get_string(config: Config, key: String, default: String) -> String {
    match config.values.get(key) {
        Some(ConfigValue::String(s)) => s,
        _ => default
    }
}

# Get int value
fn get_int(config: Config, key: String, default: Int) -> Int {
    match config.values.get(key) {
        Some(ConfigValue::Int(n)) => n,
        _ => default
    }
}

# Get float value
fn get_float(config: Config, key: String, default: Float) -> Float {
    match config.values.get(key) {
        Some(ConfigValue::Float(f)) => f,
        _ => default
    }
}

# Get bool value
fn get_bool(config: Config, key: String, default: Bool) -> Bool {
    match config.values.get(key) {
        Some(ConfigValue::Bool(b)) => b,
        _ => default
    }
}

# Get table
fn get_table(config: Config, key: String) -> Map<String, ConfigValue> {
    match config.values.get(key) {
        Some(ConfigValue::Table(t)) => t,
        _ => {}
    }
}

# Get list
fn get_list(config: Config, key: String) -> List<ConfigValue> {
    match config.values.get(key) {
        Some(ConfigValue::List(l)) => l,
        _ => []
    }
}

# Convert config to string

# Convert to TOML
fn to_toml(config: Config) -> String {
    let mut result = ""
    
    for (key, value) in config.values {
        match value {
            ConfigValue::Table(t) => {
                result = result + "[" + key + "]\n"
                for (k, v) in t {
                    result = result + k + " = " + value_to_string(v) + "\n"
                }
                result = result + "\n"
            },
            _ => {
                result = result + key + " = " + value_to_string(value) + "\n"
            }
        }
    }
    
    result
}

fn value_to_string(value: ConfigValue) -> String {
    match value {
        ConfigValue::String(s) => "\"" + s + "\"",
        ConfigValue::Int(n) => n.to_string(),
        ConfigValue::Float(f) => f.to_string(),
        ConfigValue::Bool(b) => if b { "true" } else { "false" },
        ConfigValue::List(l) => {
            let items = l.map(|v| value_to_string(v))
            "[" + items.join(", ") + "]"
        },
        ConfigValue::Table(t) => "{...}",
        ConfigValue::Array(a) => "{...}"
    }
}

# Convert to YAML
fn to_yaml(config: Config) -> String {
    let mut result = ""
    
    for (key, value) in config.values {
        result = result + value_to_yaml(value, key, 0)
    }
    
    result
}

fn value_to_yaml(value: ConfigValue, key: String, indent: Int) -> String {
    let prefix = "  ".repeat(indent)
    
    match value {
        ConfigValue::Table(t) => {
            let mut result = prefix + key + ":\n"
            for (k, v) in t {
                result = result + value_to_yaml(v, k, indent + 1)
            }
            result
        },
        ConfigValue::List(l) => {
            let mut result = prefix + key + ":\n"
            for v in l {
                result = result + prefix + "  - " + value_to_yaml_simple(v) + "\n"
            }
            result
        },
        _ => {
            prefix + key + ": " + value_to_yaml_simple(value) + "\n"
        }
    }
}

fn value_to_yaml_simple(value: ConfigValue) -> String {
    match value {
        ConfigValue::String(s) => s,
        ConfigValue::Int(n) => n.to_string(),
        ConfigValue::Float(f) => f.to_string(),
        ConfigValue::Bool(b) => if b { "true" } else { "false" },
        ConfigValue::List(l) => {
            let items = l.map(|v| value_to_yaml_simple(v))
            "[" + items.join(", ") + "]"
        },
        _ => "null"
    }
}

# Convert to INI
fn to_ini(config: Config) -> String {
    let mut result = ""
    
    for (key, value) in config.values {
        match value {
            ConfigValue::Table(t) => {
                result = result + "[" + key + "]\n"
                for (k, v) in t {
                    match v {
                        ConfigValue::String(s) => result = result + k + " = " + s + "\n",
                        _ => result = result + k + " = " + value_to_string(v) + "\n"
                    }
                }
                result = result + "\n"
            },
            _ => {}
        }
    }
    
    result
}

# Load from file
fn load_toml(path: String) -> Config {
    let content = path.read()
    parse_toml(content)
}

fn load_yaml(path: String) -> Config {
    let content = path.read()
    parse_yaml(content)
}

fn load_ini(path: String) -> Config {
    let content = path.read()
    parse_ini(content)
}

# Save to file
fn save_toml(config: Config, path: String) {
    let content = to_toml(config)
    path.write(content)
}

fn save_yaml(config: Config, path: String) {
    let content = to_yaml(config)
    path.write(content)
}

fn save_ini(config: Config, path: String) {
    let content = to_ini(config)
    path.write(content)
}

# Export
export {
    ConfigValue, Config,
    parse_toml, parse_yaml, parse_ini,
    get, get_nested,
    get_string, get_int, get_float, get_bool, get_table, get_list,
    to_toml, to_yaml, to_ini,
    load_toml, load_yaml, load_ini,
    save_toml, save_yaml, save_ini
}

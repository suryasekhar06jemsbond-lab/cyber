# Code Formatter for Nyx
# Automatic code formatting (like black)

module formatter

# Formatter options
struct FormatOptions {
    line_length: Int,
    indent_size: Int,
    use_tabs: Bool,
    quote_style: String,  # single, double
    trailing_comma: Bool,
}

fn options_new() -> FormatOptions {
    FormatOptions {
        line_length: 100,
        indent_size: 4,
        use_tabs: false,
        quote_style: "double".to_string(),
        trailing_comma: true,
    }
}

# Format Nyx source code
fn format_code(code: String, opts: FormatOptions) -> String {
    let lines = code.split("\n")
    let mut result = []
    let mut indent_level = 0
    
    for line in lines {
        let trimmed = line.trim()
        
        # Skip empty lines
        if trimmed.len() == 0 {
            result.push("".to_string())
            continue
        }
        
        # Adjust indent based on line content
        let indent_delta = count_brace_change(trimmed)
        indent_level = indent_level + indent_delta
        
        # Ensure non-negative
        if indent_level < 0 {
            indent_level = 0
        }
        
        # Format the line
        let indent = make_indent(indent_level, opts)
        let formatted = format_line(trimmed, opts)
        
        result.push(indent + formatted)
        
        # After closing brace, reduce indent
        if trimmed.starts_with("}") || trimmed.starts_with("]") || trimmed.starts_with(")") {
            indent_level = indent_level - 1
            if indent_level < 0 {
                indent_level = 0
            }
        }
    }
    
    # Remove trailing whitespace
    result.map(|l| l.trim_end())
}

fn make_indent(level: Int, opts: FormatOptions) -> String {
    if opts.use_tabs {
        "\t".repeat(level)
    } else {
        " ".repeat(level * opts.indent_size)
    }
}

fn count_brace_change(line: String) -> Int {
    let mut delta = 0
    
    for c in line.chars() {
        if c == '{' || c == '(' || c == '[' {
            delta = delta + 1
        }
        if c == '}' || c == ')' || c == ']' {
            delta = delta - 1
        }
    }
    
    delta
}

fn format_line(line: String, opts: FormatOptions) -> String {
    let mut result = line
    
    # Add space after keywords
    let keywords = ["if", "else", "for", "while", "return", "fn", "let", "mut", "class", "struct", "impl", "pub", "use", "mod"]
    
    for kw in keywords {
        result = result.replace(kw + "(", kw + " (")
        result = result.replace(kw + "{", kw + " {")
    }
    
    # Format operators
    result = result.replace(" = ", " = ")
    result = result.replace(" + ", " + ")
    result = result.replace(" - ", " - ")
    result = result.replace(" * ", " * ")
    result = result.replace(" / ", " / ")
    result = result.replace(" == ", " == ")
    result = result.replace(" != ", " != ")
    result = result.replace(" <= ", " <= ")
    result = result.replace(" >= ", " >= ")
    result = result.replace(" && ", " && ")
    result = result.replace(" || ", " || ")
    
    # Format colons
    result = result.replace(": ", ": ")
    result = result.replace(" :", ":")
    
    # Format commas
    result = result.replace(",", ", ")
    result = result.replace("  ,", ",")
    
    # Remove multiple spaces
    while result.contains("  ") {
        result = result.replace("  ", " ")
    }
    
    result
}

# Format with line wrapping
fn format_wrapped(code: String, opts: FormatOptions) -> String {
    let lines = code.split("\n")
    let mut result = []
    let mut current_line = ""
    let mut indent_level = 0
    
    for line in lines {
        let trimmed = line.trim()
        
        if trimmed.len() == 0 {
            if current_line.len() > 0 {
                result.push(format_line(current_line.trim(), opts))
                current_line = ""
            }
            result.push("".to_string())
            continue
        }
        
        let indent = make_indent(indent_level, opts)
        let formatted = format_line(trimmed, opts)
        
        if current_line.len() + formatted.len() + 1 > opts.line_length && current_line.len() > 0 {
            result.push(format_line(current_line.trim(), opts))
            current_line = indent + formatted
        } else {
            if current_line.len() > 0 {
                current_line = current_line + " " + formatted
            } else {
                current_line = indent + formatted
            }
        }
        
        # Update indent level
        let delta = count_brace_change(trimmed)
        if delta > 0 {
            indent_level = indent_level + delta
        }
        if trimmed.starts_with("}") || trimmed.starts_with("]") || trimmed.starts_with(")") {
            indent_level = indent_level - 1
            if indent_level < 0 {
                indent_level = 0
            }
        }
    }
    
    if current_line.len() > 0 {
        result.push(format_line(current_line.trim(), opts))
    }
    
    result.join("\n")
}

# Check if code needs formatting
fn needs_formatting(code: String) -> Bool {
    # Simple heuristics
    let lines = code.split("\n")
    
    for line in lines {
        # Check for inconsistent indentation
        if line.contains("    ") && line.contains("\t") {
            return true
        }
        
        # Check for long lines
        if line.len() > 120 {
            return true
        }
        
        # Check for missing spaces
        if line.contains("if(") || line.contains("for(") || line.contains("while(") {
            return true
        }
        
        if line.contains("){") || line.contains("} {") {
            return true
        }
    }
    
    false
}

# Format file
fn format_file(path: String, opts: FormatOptions) -> String {
    let content = path.read()
    format_wrapped(content, opts)
}

# Format and write to file
fn format_file_inplace(path: String, opts: FormatOptions) {
    let formatted = format_file(path, opts)
    path.write(formatted)
}

# Diff format (show what would change)
fn diff_format(original: String, opts: FormatOptions) -> String {
    let formatted = format_wrapped(original, opts)
    let mut result = ""
    
    let orig_lines = original.split("\n")
    let form_lines = formatted.split("\n")
    
    let max_lines = orig_lines.len().max(form_lines.len())
    
    for i in 0..max_lines {
        let orig = if i < orig_lines.len() { orig_lines[i] } else { "" }
        let form = if i < form_lines.len() { form_lines[i] } else { "" }
        
        if orig != form {
            result = result + "- " + orig + "\n"
            result = result + "+ " + form + "\n"
        }
    }
    
    result
}

# Format module
fn format_module(module_code: String, opts: FormatOptions) -> String {
    let lines = module_code.split("\n")
    let mut result = []
    let mut in_doc_comment = false
    
    for line in lines {
        let trimmed = line.trim()
        
        # Handle doc comments
        if trimmed.starts_with("#") {
            if !in_doc_comment {
                result.push("")
                result.push("# Documentation")
                result.push("")
                in_doc_comment = true
            }
        } else {
            in_doc_comment = false
        }
        
        result.push(line)
    }
    
    format_wrapped(result.join("\n"), opts)
}

# Sort imports
fn sort_imports(code: String) -> String {
    let lines = code.split("\n")
    let mut imports: List<String> = []
    let mut other: List<String> = []
    
    for line in lines {
        let trimmed = line.trim()
        if trimmed.starts_with("use ") || trimmed.starts_with("import ") {
            imports.push(line)
        } else {
            other.push(line)
        }
    }
    
    # Sort imports alphabetically
    imports.sort()
    
    # Reconstruct
    imports + [""] + other
}

# Add imports
fn add_import(code: String, import_stmt: String, opts: FormatOptions) -> String {
    let lines = code.split("\n")
    let mut result = []
    let mut added = false
    
    for line in lines {
        let trimmed = line.trim()
        
        # Find where to insert (after other imports)
        if !added && (trimmed.starts_with("use ") || trimmed.starts_with("import ") || trimmed == "") {
            result.push(import_stmt)
            added = true
        }
        
        result.push(line)
    }
    
    if !added {
        result.push(import_stmt)
    }
    
    result.join("\n")
}

# Remove unused imports
fn remove_unused_imports(code: String) -> String {
    let lines = code.split("\n")
    let mut imports: Map<String, String> = {}
    let mut used_names: Map<String, Bool> = {}
    let mut other: List<String> = []
    
    # Collect imports
    for line in lines {
        let trimmed = line.trim()
        if trimmed.starts_with("use ") {
            let module = trimmed.substring(4).split("::").first()
            imports[module] = line
        } else if trimmed.starts_with("import ") {
            let module = trimmed.substring(7).split("::").first()
            imports[module] = line
        } else {
            # Track potential usage
            for word in trimmed.split(" ") {
                if word.len() > 2 {
                    used_names[word] = true
                }
            }
            other.push(line)
        }
    }
    
    # Filter unused
    let mut result: List<String> = []
    for (name, line) in imports {
        if used_names.contains_key(name) {
            result.push(line)
        }
    }
    
    result + [""] + other
}

# Validate format
fn validate_format(code: String, opts: FormatOptions) -> List<String> {
    let errors = []
    
    # Check for syntax errors in formatting
    let lines = code.split("\n")
    
    for (i, line) in lines.enumerate() {
        # Check for mismatched braces
        let open_braces = line.chars().filter(|c| c == '{' || c == '(' || c == '[').count()
        let close_braces = line.chars().filter(|c| c == '}' || c == ')' || c == ']').count()
        
        if (open_braces + close_braces) % 2 != 0 {
            errors.push("Line " + (i + 1).to_string() + ": Mismatched braces")
        }
        
        # Check for trailing whitespace
        if line.ends_with(" ") || line.ends_with("\t") {
            errors.push("Line " + (i + 1).to_string() + ": Trailing whitespace")
        }
    }
    
    errors
}

# Quick format (minimal changes)
fn quick_format(code: String) -> String {
    format_code(code, options_new())
}

# Strict format (comprehensive changes)
fn strict_format(code: String) -> String {
    let opts = FormatOptions {
        line_length: 88,
        indent_size: 4,
        use_tabs: false,
        quote_style: "double".to_string(),
        trailing_comma: true
    };
    
    let formatted = format_wrapped(code, opts)
    sort_imports(formatted)
}

# Export
export {
    FormatOptions, options_new,
    format_code, format_wrapped, format_file, format_file_inplace,
    needs_formatting, diff_format,
    format_module, sort_imports, add_import, remove_unused_imports,
    validate_format, quick_format, strict_format
}

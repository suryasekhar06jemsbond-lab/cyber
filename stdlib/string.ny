# ===========================================
# Nyx Standard Library - String Module (EXTENDED)
# ===========================================
# Comprehensive string utilities including Unicode,
# regex, transformations, encoding, fuzzy matching,
# NLP processing, and similarity metrics

# ===========================================
# BASIC STRING OPERATIONS
# ===========================================

# Convert to uppercase
fn upper(s) {
    if type(s) != "string" {
        throw "upper: expected string, got " + type(s);
    }
    let result = "";
    for i in range(len(s)) {
        let c = s[i];
        let code = int(c);
        if code >= 97 && code <= 122 {
            result = result + chr(code - 32);
        } else {
            result = result + c;
        }
    }
    return result;
}

# Convert to lowercase
fn lower(s) {
    if type(s) != "string" {
        throw "lower: expected string, got " + type(s);
    }
    let result = "";
    for i in range(len(s)) {
        let c = s[i];
        let code = int(c);
        if code >= 65 && code <= 90 {
            result = result + chr(code + 32);
        } else {
            result = result + c;
        }
    }
    return result;
}

# Capitalize first letter
fn capitalize(s) {
    if type(s) != "string" {
        throw "capitalize: expected string, got " + type(s);
    }
    if len(s) == 0 {
        return s;
    }
    let first = upper(s[0]);
    if len(s) > 1 {
        return first + lower(s[1:]);
    }
    return first;
}

# Title case
fn title(s) {
    if type(s) != "string" {
        throw "title: expected string, got " + type(s);
    }
    if len(s) == 0 {
        return s;
    }
    let result = "";
    let capitalize_next = true;
    for i in range(len(s)) {
        let c = s[i];
        if capitalize_next {
            result = result + upper(c);
            capitalize_next = false;
        } else {
            result = result + lower(c);
        }
        if c == " " || c == "\t" || c == "\n" || c == "-" || c == "_" {
            capitalize_next = true;
        }
    }
    return result;
}

# Swap case
fn swapcase(s) {
    if type(s) != "string" {
        throw "swapcase: expected string, got " + type(s);
    }
    let result = "";
    for i in range(len(s)) {
        let c = s[i];
        let code = int(c);
        if code >= 65 && code <= 90 {
            result = result + chr(code + 32);
        } else if code >= 97 && code <= 122 {
            result = result + chr(code - 32);
        } else {
            result = result + c;
        }
    }
    return result;
}

# ===========================================
# WHITESPACE AND PADDING
# ===========================================

# Strip whitespace
fn strip(s) {
    return lstrip(rstrip(s));
}

# Strip from left
fn lstrip(s) {
    if type(s) != "string" {
        throw "lstrip: expected string, got " + type(s);
    }
    let i = 0;
    while i < len(s) {
        let c = s[i];
        if c != " " && c != "\t" && c != "\n" && c != "\r" {
            break;
        }
        i = i + 1;
    }
    return s[i:];
}

# Strip from right
fn rstrip(s) {
    if type(s) != "string" {
        throw "rstrip: expected string, got " + type(s);
    }
    let i = len(s) - 1;
    while i >= 0 {
        let c = s[i];
        if c != " " && c != "\t" && c != "\n" && c != "\r" {
            break;
        }
        i = i - 1;
    }
    return s[:i+1];
}

# Strip specific characters
fn strip_chars(s, chars) {
    if type(chars) == "null" {
        return strip(s);
    }
    return lstrip_chars(rstrip_chars(s, chars), chars);
}

fn lstrip_chars(s, chars) {
    if type(s) != "string" {
        throw "lstrip_chars: expected string";
    }
    if type(chars) != "string" {
        throw "lstrip_chars: expected string for chars";
    }
    let i = 0;
    while i < len(s) {
        let c = s[i];
        let found = false;
        for j in range(len(chars)) {
            if c == chars[j] {
                found = true;
                break;
            }
        }
        if !found {
            break;
        }
        i = i + 1;
    }
    return s[i:];
}

fn rstrip_chars(s, chars) {
    if type(s) != "string" {
        throw "rstrip_chars: expected string";
    }
    if type(chars) != "string" {
        throw "rstrip_chars: expected string for chars";
    }
    let i = len(s) - 1;
    while i >= 0 {
        let c = s[i];
        let found = false;
        for j in range(len(chars)) {
            if c == chars[j] {
                found = true;
                break;
            }
        }
        if !found {
            break;
        }
        i = i - 1;
    }
    return s[:i+1];
}

# Pad left
fn ljust(s, width, fillchar) {
    if type(fillchar) == "null" { fillchar = " "; }
    if len(s) >= width {
        return s;
    }
    let padding = "";
    for i in range(width - len(s)) {
        padding = padding + fillchar;
    }
    return s + padding;
}

# Pad right
fn rjust(s, width, fillchar) {
    if type(fillchar) == "null" { fillchar = " "; }
    if len(s) >= width {
        return s;
    }
    let padding = "";
    for i in range(width - len(s)) {
        padding = padding + fillchar;
    }
    return padding + s;
}

# Center
fn center(s, width, fillchar) {
    if type(fillchar) == "null" { fillchar = " "; }
    if len(s) >= width {
        return s;
    }
    let left = (width - len(s)) / 2;
    let right = width - len(s) - left;
    let result = "";
    for i in range(left) {
        result = result + fillchar;
    }
    result = result + s;
    for i in range(right) {
        result = result + fillchar;
    }
    return result;
}

# Zfill (pad with zeros)
fn zfill(s, width) {
    if len(s) >= width {
        return s;
    }
    let sign = "";
    if s[0] == "+" || s[0] == "-" {
        sign = s[0];
        s = s[1:];
    }
    let zeros = "";
    for i in range(width - len(s) - len(sign)) {
        zeros = zeros + "0";
    }
    return sign + zeros + s;
}

# ===========================================
# SPLITTING AND JOINING
# ===========================================

# Split by delimiter
fn split(s, delim) {
    if type(s) != "string" {
        throw "split: expected string, got " + type(s);
    }
    if type(delim) != "string" {
        throw "split: expected delimiter string, got " + type(delim);
    }
    if len(delim) == 0 {
        return [s];
    }
    
    let result = [];
    let current = "";
    let i = 0;
    
    while i < len(s) {
        let found = true;
        for j in range(len(delim)) {
            if i + j >= len(s) || s[i + j] != delim[j] {
                found = false;
                break;
            }
        }
        if found {
            push(result, current);
            current = "";
            i = i + len(delim);
        } else {
            current = current + s[i];
            i = i + 1;
        }
    }
    push(result, current);
    return result;
}

# Split with max splits
fn split_n(s, delim, n) {
    if type(n) == "null" {
        return split(s, delim);
    }
    if n <= 0 {
        return [s];
    }
    
    let result = [];
    let current = "";
    let i = 0;
    let splits = 0;
    
    while i < len(s) && splits < n - 1 {
        let found = true;
        for j in range(len(delim)) {
            if i + j >= len(s) || s[i + j] != delim[j] {
                found = false;
                break;
            }
        }
        if found {
            push(result, current);
            current = "";
            i = i + len(delim);
            splits = splits + 1;
        } else {
            current = current + s[i];
            i = i + 1;
        }
    }
    push(result, current + s[i:]);
    return result;
}

# Split by whitespace
fn split_whitespace(s) {
    if type(s) != "string" {
        throw "split_whitespace: expected string";
    }
    let result = [];
    let current = "";
    for c in s {
        if c == " " || c == "\t" || c == "\n" || c == "\r" {
            if len(current) > 0 {
                push(result, current);
                current = "";
            }
        } else {
            current = current + c;
        }
    }
    if len(current) > 0 {
        push(result, current);
    }
    return result;
}

# Split lines
fn splitlines(s, keepends) {
    if type(keepends) == "null" { keepends = false; }
    
    let result = [];
    let current = "";
    
    for i in range(len(s)) {
        let c = s[i];
        if c == "\n" {
            if keepends {
                current = current + c;
            }
            push(result, current);
            current = "";
            if keepends && i + 1 < len(s) && s[i + 1] == "\r" {
                # skip
            }
        } else if c == "\r" && i + 1 < len(s) && s[i + 1] == "\n" {
            if keepends {
                current = current + c + s[i + 1];
            }
            push(result, current);
            current = "";
            i = i + 1;
        } else {
            current = current + c;
        }
    }
    if len(current) > 0 {
        push(result, current);
    }
    
    return result;
}

# Join array with delimiter
fn join(arr, delim) {
    if type(arr) != "array" {
        throw "join: expected array, got " + type(arr);
    }
    if type(delim) != "string" {
        throw "join: expected delimiter string, got " + type(delim);
    }
    
    let result = "";
    for i in range(len(arr)) {
        if i > 0 {
            result = result + delim;
        }
        result = result + str(arr[i]);
    }
    return result;
}

# ===========================================
# SEARCH AND REPLACE
# ===========================================

# Replace substring
fn replace(s, old, new) {
    if type(s) != "string" {
        throw "replace: expected string";
    }
    if type(old) != "string" || type(new) != "string" {
        throw "replace: expected string arguments";
    }
    if len(old) == 0 {
        return s;
    }
    
    let result = "";
    let i = 0;
    
    while i < len(s) {
        let found = true;
        for j in range(len(old)) {
            if i + j >= len(s) || s[i + j] != old[j] {
                found = false;
                break;
            }
        }
        if found {
            result = result + new;
            i = i + len(old);
        } else {
            result = result + s[i];
            i = i + 1;
        }
    }
    return result;
}

# Replace with max count
fn replace_n(s, old, new, n) {
    if type(n) == "null" {
        return replace(s, old, new);
    }
    if n <= 0 {
        return s;
    }
    
    let result = "";
    let i = 0;
    let count = 0;
    
    while i < len(s) && count < n {
        let found = true;
        for j in range(len(old)) {
            if i + j >= len(s) || s[i + j] != old[j] {
                found = false;
                break;
            }
        }
        if found {
            result = result + new;
            i = i + len(old);
            count = count + 1;
        } else {
            result = result + s[i];
            i = i + 1;
        }
    }
    return result + s[i:];
}

# Find substring
fn find(s, sub) {
    if type(s) != "string" || type(sub) != "string" {
        throw "find: expected strings";
    }
    if len(sub) == 0 {
        return 0;
    }
    if len(sub) > len(s) {
        return -1;
    }
    
    for i in range(len(s) - len(sub) + 1) {
        let found = true;
        for j in range(len(sub)) {
            if s[i + j] != sub[j] {
                found = false;
                break;
            }
        }
        if found {
            return i;
        }
    }
    return -1;
}

# Find from right
fn rfind(s, sub) {
    if type(s) != "string" || type(sub) != "string" {
        throw "rfind: expected strings";
    }
    if len(sub) == 0 {
        return len(s);
    }
    if len(sub) > len(s) {
        return -1;
    }
    
    for i in range(len(s) - len(sub), -1, -1) {
        let found = true;
        for j in range(len(sub)) {
            if s[i + j] != sub[j] {
                found = false;
                break;
            }
        }
        if found {
            return i;
        }
    }
    return -1;
}

# Find index (like find)
fn index(s, sub) {
    let result = find(s, sub);
    if result == -1 {
        throw "substring not found";
    }
    return result;
}

# Find from right
fn rindex(s, sub) {
    let result = rfind(s, sub);
    if result == -1 {
        throw "substring not found";
    }
    return result;
}

# Check if contains
fn contains(s, sub) {
    return find(s, sub) >= 0;
}

# Check if starts with
fn startswith(s, prefix) {
    if type(s) != "string" || type(prefix) != "string" {
        throw "startswith: expected strings";
    }
    if len(prefix) > len(s) {
        return false;
    }
    for i in range(len(prefix)) {
        if s[i] != prefix[i] {
            return false;
        }
    }
    return true;
}

# Check if ends with
fn endswith(s, suffix) {
    if type(s) != "string" || type(suffix) != "string" {
        throw "endswith: expected strings";
    }
    if len(suffix) > len(s) {
        return false;
    }
    let start = len(s) - len(suffix);
    for i in range(len(suffix)) {
        if s[start + i] != suffix[i] {
            return false;
        }
    }
    return true;
}

# Count occurrences
fn count(s, sub) {
    if type(s) != "string" || type(sub) != "string" {
        throw "count: expected strings";
    }
    if len(sub) == 0 {
        return len(s) + 1;
    }
    
    let cnt = 0;
    let i = 0;
    while i < len(s) {
        let found = true;
        for j in range(len(sub)) {
            if i + j >= len(s) || s[i + j] != sub[j] {
                found = false;
                break;
            }
        }
        if found {
            cnt = cnt + 1;
            i = i + len(sub);
        } else {
            i = i + 1;
        }
    }
    return cnt;
}

# ===========================================
# STRING TRANSFORMATIONS
# ===========================================

# Reverse string
fn reverse(s) {
    if type(s) != "string" {
        throw "reverse: expected string, got " + type(s);
    }
    let result = "";
    for i in range(len(s) - 1, -1, -1) {
        result = result + s[i];
    }
    return result;
}

# Remove duplicates
fn unique(s) {
    let result = "";
    let seen = [];
    for c in s {
        if find(seen, c) < 0 {
            result = result + c;
            push(seen, c);
        }
    }
    return result;
}

# Remove all occurrences of characters
fn remove_chars(s, chars) {
    let result = "";
    for c in s {
        if find(chars, c) < 0 {
            result = result + c;
        }
    }
    return result;
}

# Keep only specified characters
fn keep_chars(s, chars) {
    let result = "";
    for c in s {
        if find(chars, c) >= 0 {
            result = result + c;
        }
    }
    return result;
}

# Expand tabs
fn expand_tabs(s, tabsize) {
    if type(tabsize) == "null" { tabsize = 8; }
    let result = "";
    let pos = 0;
    
    for c in s {
        if c == "\t" {
            let spaces = tabsize - (pos % tabsize);
            for i in range(spaces) {
                result = result + " ";
            }
            pos = pos + spaces;
        } else {
            result = result + c;
            pos = pos + 1;
        }
    }
    return result;
}

# ===========================================
# UNICODE OPERATIONS
# ===========================================

# Get Unicode code point
fn ord(c) {
    if len(c) != 1 {
        throw "ord: expected single character";
    }
    return int(c);
}

# Get character from code point
fn chr(code) {
    return "" + chr(code);
}

# Check if string is ASCII
fn is_ascii(s) {
    for i in range(len(s)) {
        let code = int(s[i]);
        if code > 127 {
            return false;
        }
    }
    return true;
}

# Check if string is alpha (letters)
fn is_alpha(s) {
    if len(s) == 0 {
        return false;
    }
    for i in range(len(s)) {
        let code = int(s[i]);
        if !((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) {
            return false;
        }
    }
    return true;
}

# Check if string is alphanumeric
fn is_alnum(s) {
    if len(s) == 0 {
        return false;
    }
    for i in range(len(s)) {
        let code = int(s[i]);
        if !((code >= 65 && code <= 90) || (code >= 97 && code <= 122) || (code >= 48 && code <= 57)) {
            return false;
        }
    }
    return true;
}

# Check if string is digit
fn is_digit(s) {
    if len(s) == 0 {
        return false;
    }
    for i in range(len(s)) {
        let code = int(s[i]);
        if code < 48 || code > 57 {
            return false;
        }
    }
    return true;
}

# Check if string is numeric
fn is_numeric(s) {
    return is_digit(s);
}

# Check if string is decimal
fn is_decimal(s) {
    return is_digit(s);
}

# Check if string is space
fn is_space(s) {
    if len(s) == 0 {
        return false;
    }
    for i in range(len(s)) {
        let code = int(s[i]);
        if code != 32 && code != 9 && code != 10 && code != 13 && code != 11 && code != 12 {
            return false;
        }
    }
    return true;
}

# Check if string is title case
fn is_title(s) {
    if len(s) == 0 {
        return false;
    }
    let prev_cased = false;
    
    for i in range(len(s)) {
        let code = int(s[i]);
        let is_cased = (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
        
        if is_cased && prev_cased {
            return false;
        }
        
        if !is_cased && i > 0 {
            prev_cased = false;
        } else if is_cased {
            prev_cased = true;
        }
    }
    return true;
}

# Check if lowercase
fn is_lower(s) {
    for i in range(len(s)) {
        let code = int(s[i]);
        if code >= 65 && code <= 90 {
            return false;
        }
    }
    return len(s) > 0;
}

# Check if uppercase
fn is_upper(s) {
    for i in range(len(s)) {
        let code = int(s[i]);
        if code >= 97 && code <= 122 {
            return false;
        }
    }
    return len(s) > 0;
}

# ===========================================
# REGEX-LIKE OPERATIONS
# ===========================================

# Simple pattern matching (* and ?)
fn fnmatch(s, pattern) {
    let s_idx = 0;
    let p_idx = 0;
    
    while s_idx < len(s) && p_idx < len(pattern) {
        if pattern[p_idx] == "*" {
            # Match zero or more characters
            return fnmatch(s[s_idx:], pattern[p_idx + 1:]) || 
                   (s_idx < len(s) && fnmatch(s[s_idx + 1:], pattern));
        } else if pattern[p_idx] == "?" {
            # Match any single character
            s_idx = s_idx + 1;
            p_idx = p_idx + 1;
        } else if s[s_idx] == pattern[p_idx] {
            s_idx = s_idx + 1;
            p_idx = p_idx + 1;
        } else {
            return false;
        }
    }
    
    while p_idx < len(pattern) && pattern[p_idx] == "*" {
        p_idx = p_idx + 1;
    }
    
    return s_idx == len(s) && p_idx == len(pattern);
}

# Wildcard to regex (simple conversion)
fn wildcard_to_regex(pattern) {
    let result = "^";
    for i in range(len(pattern)) {
        let c = pattern[i];
        if c == "*" {
            result = result + ".*";
        } else if c == "?" {
            result = result + ".";
        } else if c == "." {
            result = result + "\\.";
        } else if c == "[" || c == "]" || c == "(" || c == ")" || 
                   c == "+" || c == "^" || c == "$" || c == "|" || c == "\\" {
            result = result + "\\" + c;
        } else {
            result = result + c;
        }
    }
    result = result + "$";
    return result;
}

# Simple substring extraction by pattern
fn extract(s, pattern) {
    let matches = [];
    let current = "";
    let in_brace = false;
    
    for i in range(len(pattern)) {
        if pattern[i] == "(" {
            in_brace = true;
        } else if pattern[i] == ")" {
            in_brace = false;
        }
    }
    
    # Simple implementation: find all matches
    if contains(pattern, "*") {
        let parts = split(pattern, "*");
        for i in range(len(parts) - 1) {
            let start = find(s, parts[i]);
            if start >= 0 {
                start = start + len(parts[i]);
                let end = find(s[start:], parts[i + 1]);
                if end >= 0 {
                    push(matches, s[start:start + end]);
                }
            }
        }
    }
    
    return matches;
}

# ===========================================
# ENCODING/DECODING
# ===========================================

# URL encode
fn url_encode(s) {
    let result = "";
    for i in range(len(s)) {
        let c = s[i];
        let code = int(c);
        if (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || 
           (code >= 48 && code <= 57) || c == "-" || c == "_" || c == "." || c == "~" {
            result = result + c;
        } else {
            result = result + "%" + sprintf("%02X", code);
        }
    }
    return result;
}

# URL decode
fn url_decode(s) {
    let result = "";
    let i = 0;
    while i < len(s) {
        let c = s[i];
        if c == "%" && i + 2 < len(s) {
            let hex = "0x" + s[i + 1:i + 3];
            result = result + chr(int(hex));
            i = i + 3;
        } else if c == "+" {
            result = result + " ";
            i = i + 1;
        } else {
            result = result + c;
            i = i + 1;
        }
    }
    return result;
}

# HTML escape
fn html_escape(s) {
    let result = "";
    for i in range(len(s)) {
        let c = s[i];
        if c == "&" {
            result = result + "&";
        } else if c == "<" {
            result = result + "<";
        } else if c == ">" {
            result = result + ">";
        } else if c == '"' {
            result = result + """;
        } else if c == "'" {
            result = result + "'";
        } else {
            result = result + c;
        }
    }
    return result;
}

# HTML unescape
fn html_unescape(s) {
    let result = s;
    result = replace(result, "&", "&");
    result = replace(result, "<", "<");
    result = replace(result, ">", ">");
    result = replace(result, """, '"');
    result = replace(result, "'", "'");
    return result;
}

# ===========================================
# FUZZY MATCHING
# ===========================================

# Levenshtein distance
fn levenshtein(s1, s2) {
    let m = len(s1);
    let n = len(s2);
    
    # Create matrix
    let dp = [];
    for i in range(m + 1) {
        let row = [];
        for j in range(n + 1) {
            push(row, 0);
        }
        push(dp, row);
    }
    
    for i in range(m + 1) {
        dp[i][0] = i;
    }
    for j in range(n + 1) {
        dp[0][j] = j;
    }
    
    for i in range(1, m + 1) {
        for j in range(1, n + 1) {
            if s1[i - 1] == s2[j - 1] {
                dp[i][j] = dp[i - 1][j - 1];
            } else {
                dp[i][j] = 1 + min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
            }
        }
    }
    
    return dp[m][n];
}

# Hamming distance
fn hamming_distance(s1, s2) {
    if len(s1) != len(s2) {
        throw "hamming_distance: strings must have same length";
    }
    
    let dist = 0;
    for i in range(len(s1)) {
        if s1[i] != s2[i] {
            dist = dist + 1;
        }
    }
    return dist;
}

# Jaro similarity
fn jaro_similarity(s1, s2) {
    let len1 = len(s1);
    let len2 = len(s2);
    
    if len1 == 0 && len2 == 0 {
        return 1.0;
    }
    
    let match_distance = max(len1, len2) / 2 - 1;
    if match_distance < 0 {
        match_distance = 0;
    }
    
    let s1_matches = [];
    let s2_matches = [];
    
    for i in range(len1) {
        push(s1_matches, false);
    }
    for i in range(len2) {
        push(s2_matches, false);
    }
    
    let matches = 0;
    let transpositions = 0;
    
    for i in range(len1) {
        let start = max(0, i - match_distance);
        let end = min(i + match_distance + 1, len2);
        
        for j in range(start, end) {
            if s2_matches[j] || s1[i] != s2[j] {
                continue;
            }
            s1_matches[i] = true;
            s2_matches[j] = true;
            matches = matches + 1;
            break;
        }
    }
    
    if matches == 0 {
        return 0.0;
    }
    
    let k = 0;
    for i in range(len1) {
        if !s1_matches[i] {
            continue;
        }
        while !s2_matches[k] {
            k = k + 1;
        }
        if s1[i] != s2[k] {
            transpositions = transpositions + 1;
        }
        k = k + 1;
    }
    
    return (matches / len1 + matches / len2 + 
            (matches - transpositions / 2) / matches) / 3.0;
}

# Jaro-Winkler similarity
fn jaro_winkler_similarity(s1, s2, prefix_weight) {
    if type(prefix_weight) == "null" { prefix_weight = 0.1; }
    
    let jaro = jaro_similarity(s1, s2);
    
    # Find common prefix (up to 4 chars)
    let prefix = 0;
    for i in range(min(4, min(len(s1), len(s2)))) {
        if s1[i] == s2[i] {
            prefix = prefix + 1;
        } else {
            break;
        }
    }
    
    return jaro + prefix * prefix_weight * (1 - jaro);
}

# ===========================================
# STRING SIMILARITY METRICS
# ===========================================

# Dice coefficient (bigrams)
fn dice_coefficient(s1, s2) {
    if len(s1) < 2 || len(s2) < 2 {
        return 0.0;
    }
    
    let bigrams1 = [];
    for i in range(len(s1) - 1) {
        let bg = s1[i:i + 2];
        push(bigrams1, bg);
    }
    
    let bigrams2 = [];
    for i in range(len(s2) - 1) {
        let bg = s2[i:i + 2];
        push(bigrams2, bg);
    }
    
    let common = 0;
    for bg in bigrams1 {
        if find(bigrams2, bg) >= 0 {
            common = common + 1;
        }
    }
    
    return 2.0 * common / (len(bigrams1) + len(bigrams2));
}

# Overlap coefficient
fn overlap_coefficient(s1, s2) {
    if len(s1) == 0 || len(s2) == 0 {
        return 0.0;
    }
    
    # Character sets
    let set1 = [];
    for i in range(len(s1)) {
        if find(set1, s1[i]) < 0 {
            push(set1, s1[i]);
        }
    }
    
    let set2 = [];
    for i in range(len(s2)) {
        if find(set2, s2[i]) < 0 {
            push(set2, s2[i]);
        }
    }
    
    let intersection = 0;
    for c in set1 {
        if find(set2, c) >= 0 {
            intersection = intersection + 1;
        }
    }
    
    return intersection / min(len(set1), len(set2));
}

# Longest common subsequence
fn lcs_length(s1, s2) {
    let m = len(s1);
    let n = len(s2);
    
    let dp = [];
    for i in range(m + 1) {
        let row = [];
        for j in range(n + 1) {
            push(row, 0);
        }
        push(dp, row);
    }
    
    for i in range(1, m + 1) {
        for j in range(1, n + 1) {
            if s1[i - 1] == s2[j - 1] {
                dp[i][j] = dp[i - 1][j - 1] + 1;
            } else {
                dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]);
            }
        }
    }
    
    return dp[m][n];
}

# Longest common substring
fn lcsubstring(s1, s2) {
    let m = len(s1);
    let n = len(s2);
    
    let max_len = 0;
    let end = 0;
    
    for i in range(m) {
        for j in range(n) {
            if s1[i] == s2[j] {
                let len = 1;
                while i + len < m && j + len < n && s1[i + len] == s2[j + len] {
                    len = len + 1;
                }
                if len > max_len {
                    max_len = len;
                    end = i + len;
                }
            }
        }
    }
    
    if max_len == 0 {
        return "";
    }
    return s1[end - max_len:end];
}

# ===========================================
# NLP TEXT PROCESSING
# ===========================================

# Tokenize (word tokenization)
fn tokenize(s) {
    let result = [];
    let current = "";
    
    for i in range(len(s)) {
        let c = s[i];
        let code = int(c);
        
        if (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || 
           (code >= 48 && code <= 57) || c == "_" {
            current = current + c;
        } else {
            if len(current) > 0 {
                push(result, current);
                current = "";
            }
        }
    }
    
    if len(current) > 0 {
        push(result, current);
    }
    
    return result;
}

# Sentence tokenization
fn sent_tokenize(s) {
    let result = [];
    let current = "";
    let in_quote = false;
    
    for i in range(len(s)) {
        let c = s[i];
        
        if c == '"' || c == "'" {
            in_quote = !in_quote;
        }
        
        if !in_quote && (c == "." || c == "!" || c == "?") {
            current = current + c;
            push(result, current);
            current = "";
            
            # Skip whitespace
            while i + 1 < len(s) && (s[i + 1] == " " || s[i + 1] == "\t") {
                i = i + 1;
            }
        } else {
            current = current + c;
        }
    }
    
    if len(current) > 0 {
        push(result, current);
    }
    
    return result;
}

# Word stemming (simple suffix removal)
fn stem(s) {
    let suffixes = ["ing", "ed", "es", "s", "ly", "ment", "tion", "ness", "able", "ible"];
    
    for suf in suffixes {
        if len(s) > len(suf) + 2 && endswith(s, suf) {
            return s[:len(s) - len(suf)];
        }
    }
    
    return s;
}

# Remove stopwords (simple list)
fn remove_stopwords(words) {
    let stopwords = [
        "a", "an", "the", "and", "or", "but", "is", "are", "was", "were",
        "be", "been", "being", "have", "has", "had", "do", "does", "did",
        "will", "would", "could", "should", "may", "might", "must", "shall",
        "can", "need", "dare", "ought", "used", "to", "of", "in", "for",
        "on", "with", "at", "by", "from", "as", "into", "through", "during",
        "before", "after", "above", "below", "between", "under", "again",
        "further", "then", "once", "here", "there", "when", "where", "why",
        "how", "all", "each", "few", "more", "most", "other", "some", "such",
        "no", "nor", "not", "only", "own", "same", "so", "than", "too", "very",
        "just", "also", "now", "i", "me", "my", "myself", "we", "our", "ours",
        "ourselves", "you", "your", "yours", "yourself", "yourselves", "he",
        "him", "his", "himself", "she", "her", "hers", "herself", "it", "its",
        "itself", "they", "them", "their", "theirs", "themselves", "what", 
        "which", "who", "whom", "this", "that", "these", "those", "am"
    ];
    
    let result = [];
    for w in words {
        if find(stopwords, lower(w)) < 0 {
            push(result, w);
        }
    }
    return result;
}

# N-grams
fn ngrams(s, n) {
    if len(s) < n {
        return [];
    }
    
    let result = [];
    for i in range(len(s) - n + 1) {
        push(result, s[i:i + n]);
    }
    return result;
}

# Bigrams
fn bigrams(s) {
    return ngrams(s, 2);
}

# Trigrams
fn trigrams(s) {
    return ngrams(s, 3);
}

# Word frequency
fn word_frequency(words) {
    let freq = {};
    for w in words {
        let lw = lower(w);
        freq[lw] = (freq[lw] || 0) + 1;
    }
    return freq;
}

# TF-IDF calculation (simplified)
fn tf(words) {
    let total = len(words);
    let tf_scores = {};
    
    for w in words {
        let lw = lower(w);
        tf_scores[lw] = (tf_scores[lw] || 0) + 1;
    }
    
    for k in keys(tf_scores) {
        tf_scores[k] = tf_scores[k] / total;
    }
    
    return tf_scores;
}

# ===========================================
# TEXT METRICS
# ===========================================

# Character count
fn char_count(s) {
    return len(s);
}

# Word count
fn word_count(s) {
    let words = split_whitespace(s);
    return len(words);
}

# Line count
fn line_count(s) {
    return len(splitlines(s));
}

# Sentence count
fn sentence_count(s) {
    return len(sent_tokenize(s));
}

# Average word length
fn avg_word_length(s) {
    let words = split_whitespace(s);
    if len(words) == 0 {
        return 0;
    }
    
    let total = 0;
    for w in words {
        total = total + len(w);
    }
    return total / len(words);
}

# ===========================================
# TEXT TRANSFORMATIONS
# ===========================================

# CamelCase to snake_case
fn camel_to_snake(s) {
    let result = "";
    for i in range(len(s)) {
        let c = s[i];
        let code = int(c);
        if code >= 65 && code <= 90 {
            if i > 0 {
                result = result + "_";
            }
            result = result + lower(c);
        } else {
            result = result + c;
        }
    }
    return lower(result);
}

# Snake_case to camelCase
fn snake_to_camel(s) {
    let parts = split(s, "_");
    let result = "";
    for i in range(len(parts)) {
        if i == 0 {
            result = result + lower(parts[i]);
        } else {
            result = result + capitalize(parts[i]);
        }
    }
    return result;
}

# kebab-case conversion
fn to_kebab(s) {
    let result = camel_to_snake(s);
    return replace(result, "_", "-");
}

# Remove punctuation
fn remove_punctuation(s) {
    let result = "";
    for i in range(len(s)) {
        let code = int(s[i]);
        if (code >= 65 && code <= 90) || (code >= 97 && code <= 122) ||
           (code >= 48 && code <= 57) || s[i] == " " || s[i] == "\n" || s[i] == "\t" {
            result = result + s[i];
        }
    }
    return result;
}

# Normalize whitespace
fn normalize_whitespace(s) {
    let result = "";
    let prev_space = false;
    
    for i in range(len(s)) {
        let c = s[i];
        if c == " " || c == "\t" || c == "\n" || c == "\r" {
            if !prev_space {
                result = result + " ";
                prev_space = true;
            }
        } else {
            result = result + c;
            prev_space = false;
        }
    }
    return strip(result);
}

# ===========================================
# PARTITIONING
# ===========================================

# Partition string into 3 parts
fn partition(s, sep) {
    let idx = find(s, sep);
    if idx < 0 {
        return [s, "", ""];
    }
    return [s[:idx], sep, s[idx + len(sep):]];
}

# Partition from right
fn rpartition(s, sep) {
    let idx = rfind(s, sep);
    if idx < 0 {
        return ["", "", s];
    }
    return [s[:idx], sep, s[idx + len(sep):]];
}

# ===========================================
# STRING SLICING UTILITIES
# ===========================================

# Get first n characters
fn head(s, n) {
    return s[:n];
}

# Get last n characters
fn tail(s, n) {
    if n >= len(s) {
        return s;
    }
    return s[len(s) - n:];
}

# Get substring from index to end
fn substr(s, start) {
    if start < 0 {
        start = len(s) + start;
    }
    return s[start:];
}

# Slice with step
fn slice(s, start, end, step) {
    if type(step) == "null" { step = 1; }
    if type(end) == "null" { end = len(s); }
    if start < 0 { start = len(s) + start; }
    if end < 0 { end = len(s) + end; }
    
    let result = "";
    if step > 0 {
        for i in range(start, end, step) {
            result = result + s[i];
        }
    } else {
        for i in range(start, end, step) {
            result = result + s[i];
        }
    }
    return result;
}

# ===========================================
# CHECKING FUNCTIONS
# ===========================================

# Check if empty
fn is_empty(s) {
    return len(s) == 0;
}

# Check if printable
fn is_printable(s) {
    for i in range(len(s)) {
        let code = int(s[i]);
        if code < 32 || code > 126 {
            return false;
        }
    }
    return true;
}

# Check if decimal string
fn is_decimal_str(s) {
    if len(s) == 0 {
        return false;
    }
    
    let i = 0;
    if s[0] == "+" || s[0] == "-" {
        i = 1;
    }
    
    for j in range(i, len(s)) {
        let code = int(s[j]);
        if code < 48 || code > 57 {
            return false;
        }
    }
    return true;
}

# Check if identifier
fn is_identifier(s) {
    if len(s) == 0 {
        return false;
    }
    
    for i in range(len(s)) {
        let code = int(s[i]);
        if i == 0 {
            if !((code >= 65 && code <= 90) || (code >= 97 && code <= 122) || s[i] == "_") {
                return false;
            }
        } else {
            if !((code >= 65 && code <= 90) || (code >= 97 && code <= 122) || 
                  (code >= 48 && code <= 57) || s[i] == "_") {
                return false;
            }
        }
    }
    return true;
}

# ===========================================
# MISCELLANEOUS
# ===========================================

# String length
fn len_str(s) {
    return len(s);
}

# Check type
fn is_string(s) {
    return type(s) == "string";
}

# Template string (simple)
fn template(s, values) {
    let result = s;
    for k in keys(values) {
        let placeholder = "{" + k + "}";
        result = replace(result, placeholder, str(values[k]));
    }
    return result;
}

# Indent text
fn indent(s, spaces, indent_char) {
    if type(spaces) == "null" { spaces = 4; }
    if type(indent_char) == "null" { indent_char = " "; }
    
    let prefix = "";
    for i in range(spaces) {
        prefix = prefix + indent_char;
    }
    
    let lines = splitlines(s);
    let result = "";
    for line in lines {
        if len(result) > 0 {
            result = result + "\n";
        }
        result = result + prefix + line;
    }
    return result;
}

# Dedent text (remove common leading whitespace)
fn dedent(s) {
    let lines = splitlines(s);
    let min_indent = 1000;
    
    for line in lines {
        let stripped = lstrip(line);
        if len(stripped) > 0 {
            let indent = len(line) - len(stripped);
            if indent < min_indent {
                min_indent = indent;
            }
        }
    }
    
    if min_indent == 0 {
        return s;
    }
    
    let result = "";
    for line in lines {
        if len(line) >= min_indent {
            result = result + line[min_indent:];
        } else {
            result = result + line;
        }
        result = result + "\n";
    }
    return result[:len(result) - 1];
}

# Wrap text to specified width
fn wrap(s, width) {
    let words = split_whitespace(s);
    let lines = [];
    let current = "";
    
    for w in words {
        if len(current) + len(w) + 1 <= width {
            if len(current) > 0 {
                current = current + " ";
            }
            current = current + w;
        } else {
            if len(current) > 0 {
                push(lines, current);
            }
            current = w;
        }
    }
    
    if len(current) > 0 {
        push(lines, current);
    }
    
    return join(lines, "\n");
}

# ===========================================
# EXPORTS
# ===========================================

{
    # Basic
    "upper": upper,
    "lower": lower,
    "capitalize": capitalize,
    "title": title,
    "swapcase": swapcase,
    
    # Whitespace
    "strip": strip,
    "lstrip": lstrip,
    "rstrip": rstrip,
    "strip_chars": strip_chars,
    "lstrip_chars": lstrip_chars,
    "rstrip_chars": rstrip_chars,
    "expand_tabs": expand_tabs,
    "normalize_whitespace": normalize_whitespace,
    
    # Padding
    "ljust": ljust,
    "rjust": rjust,
    "center": center,
    "zfill": zfill,
    
    # Split/Join
    "split": split,
    "split_n": split_n,
    "split_whitespace": split_whitespace,
    "splitlines": splitlines,
    "join": join,
    
    # Search/Replace
    "replace": replace,
    "replace_n": replace_n,
    "find": find,
    "rfind": rfind,
    "index": index,
    "rindex": rindex,
    "contains": contains,
    "startswith": startswith,
    "endswith": endswith,
    "count": count,
    
    # Transformations
    "reverse": reverse,
    "unique": unique,
    "remove_chars": remove_chars,
    "keep_chars": keep_chars,
    "remove_punctuation": remove_punctuation,
    
    # Unicode
    "ord": ord,
    "chr": chr,
    "is_ascii": is_ascii,
    "is_alpha": is_alpha,
    "is_alnum": is_alnum,
    "is_digit": is_digit,
    "is_numeric": is_numeric,
    "is_decimal": is_decimal,
    "is_space": is_space,
    "is_title": is_title,
    "is_lower": is_lower,
    "is_upper": is_upper,
    "is_printable": is_printable,
    "is_decimal_str": is_decimal_str,
    "is_identifier": is_identifier,
    
    # Regex-like
    "fnmatch": fnmatch,
    "wildcard_to_regex": wildcard_to_regex,
    "extract": extract,
    
    # Encoding
    "url_encode": url_encode,
    "url_decode": url_decode,
    "html_escape": html_escape,
    "html_unescape": html_unescape,
    
    # Fuzzy matching
    "levenshtein": levenshtein,
    "hamming_distance": hamming_distance,
    "jaro_similarity": jaro_similarity,
    "jaro_winkler_similarity": jaro_winkler_similarity,
    
    # Similarity
    "dice_coefficient": dice_coefficient,
    "overlap_coefficient": overlap_coefficient,
    "lcs_length": lcs_length,
    "lcsubstring": lcsubstring,
    
    # NLP
    "tokenize": tokenize,
    "sent_tokenize": sent_tokenize,
    "stem": stem,
    "remove_stopwords": remove_stopwords,
    "ngrams": ngrams,
    "bigrams": bigrams,
    "trigrams": trigrams,
    "word_frequency": word_frequency,
    "tf": tf,
    
    # Metrics
    "char_count": char_count,
    "word_count": word_count,
    "line_count": line_count,
    "sentence_count": sentence_count,
    "avg_word_length": avg_word_length,
    
    # Case conversion
    "camel_to_snake": camel_to_snake,
    "snake_to_camel": snake_to_camel,
    "to_kebab": to_kebab,
    
    # Partitioning
    "partition": partition,
    "rpartition": rpartition,
    
    # Slicing
    "head": head,
    "tail": tail,
    "substr": substr,
    "slice": slice,
    
    # Misc
    "is_empty": is_empty,
    "is_string": is_string,
    "template": template,
    "indent": indent,
    "dedent": dedent,
    "wrap": wrap,
    "len_str": len_str
}

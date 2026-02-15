# Regex Engine for Nyx
# Regular expression pattern matching

module regex

# Regex pattern
struct Regex {
    pattern: String,
    tokens: List<Token>,
}

# Token types for regex
enum TokenType {
    Literal,
    Dot,
    Star,
    Plus,
    Question,
    AnchorStart,
    AnchorEnd,
    CharClass,
    Group,
    Alternation,
    Repeat,
}

struct Token {
    ttype: TokenType,
    value: Dynamic,
}

# Compile regex pattern
fn compile(pattern: String) -> Regex {
    let mut tokens = []
    let mut i = 0
    
    while i < pattern.len() {
        let c = pattern[i]
        
        match c {
            '.' => tokens.push(Token { ttype: TokenType::Dot, value: 0 }),
            '*' => tokens.push(Token { ttype: TokenType::Star, value: 0 }),
            '+' => tokens.push(Token { ttype: TokenType::Plus, value: 0 }),
            '?' => tokens.push(Token { ttype: TokenType::Question, value: 0 }),
            '^' => tokens.push(Token { ttype: TokenType::AnchorStart, value: 0 }),
            '$' => tokens.push(Token { ttype: TokenType::AnchorEnd, value: 0 }),
            '[' => {
                # Character class
                let mut class = []
                i = i + 1
                while i < pattern.len() && pattern[i] != ']' {
                    class.push(pattern[i])
                    i = i + 1
                }
                tokens.push(Token { ttype: TokenType::CharClass, value: class })
            },
            '(' => tokens.push(Token { ttype: TokenType::Group, value: 0 }),
            ')' => tokens.push(Token { ttype: TokenType::Group, value: 0 }),
            '|' => tokens.push(Token { ttype: TokenType::Alternation, value: 0 }),
            _ => tokens.push(Token { ttype: TokenType::Literal, value: c }),
        }
        
        i = i + 1
    }
    
    Regex { pattern, tokens }
}

# Match regex against string
fn match(regex: Regex, text: String) -> Bool {
    if regex.tokens.len() == 0 {
        return true
    }
    
    match_at(regex, text, 0, 0)
}

# Match at specific position
fn match_at(regex: Regex, text: String, text_pos: Int, token_pos: Int) -> Bool {
    if token_pos >= regex.tokens.len() {
        return text_pos >= text.len()
    }
    
    let token = regex.tokens[token_pos]
    
    match token.ttype {
        TokenType::Literal => {
            if text_pos >= text.len() || text[text_pos] != token.value {
                return false
            }
            match_at(regex, text, text_pos + 1, token_pos + 1)
        },
        TokenType::Dot => {
            if text_pos >= text.len() {
                return false
            }
            match_at(regex, text, text_pos + 1, token_pos + 1)
        },
        TokenType::Star => {
            # Zero or more of previous
            match_at(regex, text, text_pos, token_pos + 1) ||
            (text_pos < text.len() && match_at(regex, text, text_pos + 1, token_pos))
        },
        TokenType::Plus => {
            # One or more of previous
            if text_pos >= text.len() {
                return false
            }
            match_at(regex, text, text_pos + 1, token_pos) ||
            match_at(regex, text, text_pos + 1, token_pos + 1)
        },
        TokenType::Question => {
            # Zero or one
            match_at(regex, text, text_pos, token_pos + 1) ||
            (text_pos < text.len() && match_at(regex, text, text_pos + 1, token_pos + 1))
        },
        TokenType::AnchorStart => {
            text_pos == 0 && match_at(regex, text, text_pos, token_pos + 1)
        },
        TokenType::AnchorEnd => {
            text_pos == text.len() && match_at(regex, text, text_pos, token_pos + 1)
        },
        TokenType::CharClass => {
            if text_pos >= text.len() {
                return false
            }
            let c = text[text_pos]
            let class = token.value
            let in_class = class.contains(c)
            in_class && match_at(regex, text, text_pos + 1, token_pos + 1)
        },
        TokenType::Group => {
            match_at(regex, text, text_pos, token_pos + 1)
        },
        TokenType::Alternation => {
            # Try alternatives
            match_at(regex, text, text_pos, token_pos + 1)
        },
        _ => false
    }
}

# Find all matches
fn find_all(regex: Regex, text: String) -> List<Match> {
    let mut matches = []
    
    for i in 0..text.len() {
        if match_at(regex, text, i, 0) {
            let mut end = i
            while end < text.len() && match_at(regex, text, end, 0) {
                end = end + 1
            }
            matches.push(Match { start: i, end: end - 1, text: text.substring(i, end) })
        }
    }
    
    matches
}

# Match result
struct Match {
    start: Int,
    end: Int,
    text: String,
}

# Get matched text
fn match_text(m: Match) -> String {
    m.text
}

# Get capture groups
fn groups(m: Match) -> List<String> {
    [m.text]
}

# Replace all matches
fn replace_all(regex: Regex, text: String, replacement: String) -> String {
    let mut result = ""
    let mut i = 0
    
    while i < text.len() {
        let mut matched = false
        for j in (i + 1)..=text.len() {
            let substr = text.substring(i, j)
            if match(regex, substr) {
                result = result + replacement
                i = j
                matched = true
                break
            }
        }
        if !matched {
            result = result + text[i]
            i = i + 1
        }
    }
    
    result
}

# Split by regex
fn split(regex: Regex, text: String) -> List<String> {
    let mut result = []
    let mut current = ""
    let mut i = 0
    
    while i < text.len() {
        let substr = text.substring(i, text.len())
        
        # Check if we can split here
        let can_split = match regex.tokens[0] {
            Token { ttype: TokenType::Literal, value } => text[i] == value,
            _ => false
        };
        
        if can_split {
            result.push(current)
            current = ""
            i = i + 1
        } else {
            current = current + text[i]
            i = i + 1
        }
    }
    
    if current.len() > 0 {
        result.push(current)
    }
    
    result
}

# Test common patterns
fn is_email(s: String) -> Bool {
    let email_regex = compile("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}".to_string())
    match(email_regex, s)
}

fn is_url(s: String) -> Bool {
    let url_regex = compile("https?://[a-zA-Z0-9.-]+".to_string())
    match(url_regex, s)
}

fn is_phone(s: String) -> Bool {
    let phone_regex = compile("\\d{3}-\\d{3}-\\d{4}".to_string())
    match(phone_regex, s)
}

fn is_date(s: String) -> Bool {
    let date_regex = compile("\\d{4}-\\d{2}-\\d{2}".to_string())
    match(date_regex, s)
}

fn is_ip_address(s: String) -> Bool {
    let ip_regex = compile("\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}".to_string())
    match(ip_regex, s)
}

# Extract all matches
fn extract(regex: Regex, text: String) -> List<String> {
    let matches = find_all(regex, text)
    matches.map(|m| m.text)
}

# Common patterns
let EMAIL_PATTERN = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"
let URL_PATTERN = "https?://[a-zA-Z0-9.-]+"
let PHONE_PATTERN = "\\d{3}-\\d{3}-\\d{4}"
let DATE_PATTERN = "\\d{4}-\\d{2}-\\d{2}"
let IP_PATTERN = "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}"

# Export
export {
    Regex, Token, TokenType,
    compile, match, match_at, find_all,
    Match, match_text, groups,
    replace_all, split, extract,
    is_email, is_url, is_phone, is_date, is_ip_address,
    EMAIL_PATTERN, URL_PATTERN, PHONE_PATTERN, DATE_PATTERN, IP_PATTERN
}

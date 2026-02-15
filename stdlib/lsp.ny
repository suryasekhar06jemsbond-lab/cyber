# Language Server Protocol for Nyx
# IDE integration support

module lsp

# LSP message types
enum MessageType {
    Request,
    Response,
    Notification,
}

# LSP request
struct Request {
    id: Int,
    method: String,
    params: Dynamic,
}

# LSP response
struct Response {
    id: Int,
    result: Dynamic,
    error: Dynamic,
}

# LSP notification
struct Notification {
    method: String,
    params: Dynamic,
}

# Text document position
struct Position {
    line: Int,
    character: Int,
}

# Text document range
struct Range {
    start: Position,
    end: Position,
}

# Text document identifier
struct TextDocumentIdentifier {
    uri: String,
}

# Text document item
struct TextDocumentItem {
    uri: String,
    language_id: String,
    version: Int,
    text: String,
}

# Initialize request params
struct InitializeParams {
    process_id: Int,
    root_uri: String,
    capabilities: ClientCapabilities,
}

# Client capabilities
struct ClientCapabilities {
    text_document: TextDocumentClientCapabilities,
    workspace: WorkspaceClientCapabilities,
}

struct TextDocumentClientCapabilities {
    completion: CompletionCapability,
    hover: HoverCapability,
    definition: DefinitionCapability,
    references: ReferencesCapability,
    diagnostics: DiagnosticsCapability,
}

struct WorkspaceClientCapabilities {
    workspace_folders: Bool,
}

struct CompletionCapability {
    dynamic_registration: Bool,
}

struct HoverCapability {
    dynamic_registration: Bool,
}

struct DefinitionCapability {
    dynamic_registration: Bool,
}

struct ReferencesCapability {
    dynamic_registration: Bool,
}

struct DiagnosticsCapability {
    dynamic_registration: Bool,
}

# Server capabilities
struct ServerCapabilities {
    text_document_sync: Int,  # 1 = full, 2 = incremental, 0 = none
    completion_provider: CompletionOptions,
    hover_provider: Bool,
    definition_provider: Bool,
    references_provider: Bool,
}

struct CompletionOptions {
    trigger_characters: List<String>,
}

# Initialize result
struct InitializeResult {
    capabilities: ServerCapabilities,
    server_info: ServerInfo,
}

struct ServerInfo {
    name: String,
    version: String,
}

# Document symbols
struct DocumentSymbolParams {
    text_document: TextDocumentIdentifier,
}

struct SymbolInformation {
    name: String,
    kind: Int,
    location: Location,
}

struct Location {
    uri: String,
    range: Range,
}

# Completions
struct CompletionParams {
    text_document: TextDocumentIdentifier,
    position: Position,
}

struct CompletionList {
    is_incomplete: Bool,
    items: List<CompletionItem>,
}

struct CompletionItem {
    label: String,
    kind: Int,
    detail: String,
    documentation: String,
    insert_text: String,
}

# Hover
struct HoverParams {
    text_document: TextDocumentIdentifier,
    position: Position,
}

struct Hover {
    contents: Dynamic,
    range: Range,
}

# Definition
struct DefinitionParams {
    text_document: TextDocumentIdentifier,
    position: Position,
}

# References
struct ReferenceParams {
    text_document: TextDocumentIdentifier,
    position: Position,
}

# Diagnostics
struct PublishDiagnosticsParams {
    uri: String,
    version: Int,
    diagnostics: List<Diagnostic>,
}

struct Diagnostic {
    range: Range,
    severity: Int,
    message: String,
    source: String,
}

# Create LSP server
struct LanguageServer {
    capabilities: ServerCapabilities,
    documents: Map<String, String>,
}

fn server_new() -> LanguageServer {
    LanguageServer {
        capabilities: ServerCapabilities {
            text_document_sync: 1,
            completion_provider: CompletionOptions {
                trigger_characters: [".", ":".to_string()]
            },
            hover_provider: true,
            definition_provider: true,
            references_provider: true,
        },
        documents: {}
    }
}

# Handle initialize request
fn handle_initialize(server: LanguageServer, params: InitializeParams) -> InitializeResult {
    InitializeResult {
        capabilities: server.capabilities,
        server_info: ServerInfo {
            name: "Nyx Language Server".to_string(),
            version: "1.0.0".to_string()
        }
    }
}

# Handle text document did open
fn handle_text_document_did_open(server: LanguageServer, text_doc: TextDocumentItem) {
    server.documents[text_doc.uri] = text_doc.text
}

# Handle text document did change
fn handle_text_document_did_change(server: LanguageServer, uri: String, text: String) {
    server.documents[uri] = text
}

# Handle text document did close
fn handle_text_document_did_close(server: LanguageServer, uri: String) {
    server.documents.remove(uri)
}

# Handle completion request
fn handle_completion(server: LanguageServer, params: CompletionParams) -> CompletionList {
    let uri = params.text_document.uri
    let pos = params.position
    
    # Get document
    let text = match server.documents.get(uri) {
        Some(t) => t,
        None => ""
    }
    
    # Get current line
    let lines = text.split("\n")
    let current_line = if pos.line < lines.len() { 
        lines[pos.line] 
    } else { 
        "" 
    }
    
    # Get word at position
    let word = get_word_at(current_line, pos.character)
    
    # Generate completions based on word
    let items = generate_completions(word)
    
    CompletionList {
        is_incomplete: false,
        items
    }
}

fn get_word_at(line: String, pos: Int) -> String {
    if pos > line.len() {
        return ""
    }
    
    # Find start
    let mut start = pos
    while start > 0 && is_identifier_char(line[start - 1]) {
        start = start - 1
    }
    
    # Find end
    let mut end = pos
    while end < line.len() && is_identifier_char(line[end]) {
        end = end + 1
    }
    
    if end > start {
        line.substring(start, end)
    } else {
        ""
    }
}

fn is_identifier_char(c: Char) -> Bool {
    (c >= 'a' && c <= 'z') ||
    (c >= 'A' && c <= 'Z') ||
    (c >= '0' && c <= '9') ||
    c == '_'
}

fn generate_completions(word: String) -> List<CompletionItem> {
    let keywords = [
        "fn", "let", "mut", "const", "if", "else", "for", "while",
        "return", "break", "continue", "struct", "enum", "impl", "trait",
        "pub", "mod", "use", "import", "export", "class", "async", "await"
    ]
    
    let builtins = [
        "print", "println", "panic", "assert", "match", "Some", "None",
        "Ok", "Err", "Result", "Option", "List", "Map", "Set"
    ]
    
    let items = []
    
    for kw in keywords {
        if kw.starts_with(word) {
            items.push(CompletionItem {
                label: kw.to_string(),
                kind: 14,  # Keyword
                detail: "keyword".to_string(),
                documentation: "".to_string(),
                insert_text: kw.to_string()
            })
        }
    }
    
    for bn in builtins {
        if bn.starts_with(word) {
            items.push(CompletionItem {
                label: bn.to_string(),
                kind: 9,  # Function
                detail: "builtin".to_string(),
                documentation: "".to_string(),
                insert_text: bn.to_string()
            })
        }
    }
    
    items
}

# Handle hover request
fn handle_hover(server: LanguageServer, params: HoverParams) -> Hover {
    let uri = params.text_document.uri
    let pos = params.position
    
    # Get document
    let text = match server.documents.get(uri) {
        Some(t) => t,
        None => ""
    }
    
    # Get word at position
    let lines = text.split("\n")
    let current_line = if pos.line < lines.len() { 
        lines[pos.line] 
    } else { 
        "" 
    }
    
    let word = get_word_at(current_line, pos.character)
    
    # Generate documentation for word
    let doc = get_documentation(word)
    
    Hover {
        contents: Dynamic::String(doc),
        range: Range {
            start: Position { line: pos.line, character: pos.character - word.len() },
            end: pos
        }
    }
}

fn get_documentation(word: String) -> String {
    match word {
        "fn" => "Function declaration\n\nSyntax: fn name(params) -> return_type { ... }",
        "let" => "Variable binding\n\nCreates an immutable variable binding",
        "mut" => "Mutable binding\n\nCreates a mutable variable binding",
        "if" => "Conditional statement\n\nSyntax: if condition { ... } else { ... }",
        "for" => "For loop\n\nSyntax: for item in iterable { ... }",
        "while" => "While loop\n\nSyntax: while condition { ... }",
        "return" => "Return statement\n\nReturns a value from a function",
        "struct" => "Structure definition\n\nDefines a custom data structure",
        "class" => "Class definition\n\nDefines a class with methods",
        "async" => "Async function\n\nDeclares an asynchronous function",
        "print" => "Print function\n\nPrints a value to stdout",
        _ => "No documentation available"
    }
}

# Handle definition request
fn handle_definition(server: LanguageServer, params: DefinitionParams) -> Dynamic {
    # In a real implementation, this would find the definition location
    Dynamic::Null
}

# Handle references request
fn handle_references(server: LanguageServer, params: ReferenceParams) -> Dynamic {
    # In a real implementation, this would find all references
    Dynamic::List([])
}

# Diagnostics - analyze document for errors
fn analyze_document(text: String) -> List<Diagnostic> {
    let mut diagnostics = []
    let lines = text.split("\n")
    
    for (line_num, line) in lines.enumerate() {
        # Check for common issues
        
        # Unclosed strings
        let mut in_string = false
        for (i, c) in line.chars().enumerate() {
            if c == '"' && (i == 0 || line[i-1] != '\\') {
                in_string = !in_string
            }
        }
        
        if in_string {
            diagnostics.push(Diagnostic {
                range: Range {
                    start: Position { line: line_num, character: 0 },
                    end: Position { line: line_num, character: line.len() }
                },
                severity: 1,  # Error
                message: "Unclosed string literal".to_string(),
                source: "nyx".to_string()
            })
        }
        
        # Unused variables (simple check)
        if line.contains("let ") && !line.contains("=") {
            diagnostics.push(Diagnostic {
                range: Range {
                    start: Position { line: line_num, character: 0 },
                    end: Position { line: line_num, character: 3 }
                },
                severity: 2,  # Warning
                message: "Incomplete variable declaration".to_string(),
                source: "nyx".to_string()
            })
        }
    }
    
    diagnostics
}

# LSP JSON-RPC message handling
fn parse_message(content: String) -> Dynamic {
    # In a real implementation, would parse JSON-RPC
    Dynamic::Map({})
}

fn create_response(id: Int, result: Dynamic) -> String {
    # Create JSON-RPC response
    "{\"jsonrpc\": \"2.0\", \"id\": " + id.to_string() + ", \"result\": " + "{} }"
}

fn create_error_response(id: Int, code: Int, message: String) -> String {
    "{\"jsonrpc\": \"2.0\", \"id\": " + id.to_string() + ", \"error\": {\"code\": " + code.to_string() + ", \"message\": \"" + message + "\"}}"
}

# Export
export {
    MessageType, Request, Response, Notification,
    Position, Range,
    TextDocumentIdentifier, TextDocumentItem,
    InitializeParams, ClientCapabilities, ServerCapabilities, ServerCapabilities,
    InitializeResult, ServerInfo,
    CompletionParams, CompletionList, CompletionItem,
    HoverParams, Hover,
    DefinitionParams, ReferenceParams,
    PublishDiagnosticsParams, Diagnostic,
    LanguageServer, server_new,
    handle_initialize,
    handle_text_document_did_open, handle_text_document_did_change, handle_text_document_did_close,
    handle_completion, handle_hover, handle_definition, handle_references,
    analyze_document,
    parse_message, create_response, create_error_response
}

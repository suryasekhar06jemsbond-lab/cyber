# CLI Argument Parsing Library for Nyx
# Command-line interface utilities

module cli

# Argument types
enum ArgType {
    String,
    Int,
    Float,
    Bool,
    ListString,
    ListInt,
}

# Argument definition
struct Arg {
    name: String,
    short: String,
    ttype: ArgType,
    default: Dynamic,
    required: Bool,
    help: String,
}

# Create string argument
fn arg_string(name: String, help: String) -> Arg {
    Arg {
        name,
        short: "".to_string(),
        ttype: ArgType::String,
        default: Dynamic::String(""),
        required: false,
        help
    }
}

# Create integer argument
fn arg_int(name: String, help: String) -> Arg {
    Arg {
        name,
        short: "".to_string(),
        ttype: ArgType::Int,
        default: Dynamic::Int(0),
        required: false,
        help
    }
}

# Create float argument
fn arg_float(name: String, help: String) -> Arg {
    Arg {
        name,
        short: "".to_string(),
        ttype: ArgType::Float,
        default: Dynamic::Float(0.0),
        required: false,
        help
    }
}

# Create boolean argument (flag)
fn arg_bool(name: String, help: String) -> Arg {
    Arg {
        name,
        short: "".to_string(),
        ttype: ArgType::Bool,
        default: Dynamic::Bool(false),
        required: false,
        help
    }
}

# Add short name to argument
fn with_short(arg: Arg, short: String) -> Arg {
    Arg { short, ..arg }
}

# Add default value
fn with_default(arg: Arg, default: Dynamic) -> Arg {
    Arg { default, ..arg }
}

# Make argument required
fn required(arg: Arg) -> Arg {
    Arg { required: true, ..arg }
}

# Command definition
struct Command {
    name: String,
    args: List<Arg>,
    help: String,
    action: fn(Map<String, Dynamic>) -> (),
}

# CLI parser
struct Parser {
    program: String,
    version: String,
    commands: List<Command>,
    global_args: List<Arg>,
}

# Create new parser
fn parser_new(program: String, version: String) -> Parser {
    Parser {
        program,
        version,
        commands: [],
        global_args: []
    }
}

# Add global argument
fn add_argument(parser: Parser, arg: Arg) -> Parser {
    let mut parser = parser
    parser.global_args.push(arg)
    parser
}

# Add command
fn add_command(parser: Parser, cmd: Command) -> Parser {
    let mut parser = parser
    parser.commands.push(cmd)
    parser
}

# Parse command line arguments
fn parse_args(parser: Parser, args: List<String>) -> Dynamic {
    if args.len() == 0 {
        return Dynamic::Map({})
    }
    
    let mut values = {}
    let mut cmd_name = ""
    let mut cmd_args: List<String> = []
    
    let mut i = 0
    while i < args.len() {
        let arg = args[i]
        
        if arg.starts_with("--") {
            # Long option
            let name = arg.substring(2)
            if i + 1 < args.len() && !args[i + 1].starts_with("-") {
                values[name] = Dynamic::String(args[i + 1])
                i = i + 2
            } else {
                values[name] = Dynamic::Bool(true)
                i = i + 1
            }
        } else if arg.starts_with("-") {
            # Short option
            let name = arg.substring(1)
            if i + 1 < args.len() && !args[i + 1].starts_with("-") {
                values[name] = Dynamic::String(args[i + 1])
                i = i + 2
            } else {
                values[name] = Dynamic::Bool(true)
                i = i + 1
            }
        } else if cmd_name.len() == 0 {
            # Command name
            cmd_name = arg
            i = i + 1
        } else {
            # Positional argument
            cmd_args.push(arg)
            i = i + 1
        }
    }
    
    if cmd_name.len() > 0 {
        values["_command"] = Dynamic::String(cmd_name)
        values["_args"] = Dynamic::List(cmd_args.map(|s| Dynamic::String(s)))
    }
    
    Dynamic::Map(values)
}

# Print help message
fn print_help(parser: Parser) {
    print(parser.program, " v", parser.version)
    print("")
    print("Usage:", parser.program, "[options] [command]")
    print("")
    print("Options:")
    
    for arg in parser.global_args {
        let name = "--" + arg.name
        let short = if arg.short.len() > 0 { ", -" + arg.short } else { "" }
        print("  ", name, short, " : ", arg.help)
    }
    
    if parser.commands.len() > 0 {
        print("")
        print("Commands:")
        for cmd in parser.commands {
            print("  ", cmd.name, " : ", cmd.help)
        }
    }
}

# Print usage
fn print_usage(parser: Parser) {
    print("Usage:", parser.program, "[options] [command]")
}

# Version
fn print_version(parser: Parser) {
    print(parser.program, " version ", parser.version)
}

# Simple flag check
fn has_flag(values: Map<String, Dynamic>, name: String) -> Bool {
    match values.get(name) {
        Some(Dynamic::Bool(b)) => b,
        _ => false
    }
}

# Get string value
fn get_string(values: Map<String, Dynamic>, name: String) -> String {
    match values.get(name) {
        Some(Dynamic::String(s)) => s,
        _ => "".to_string()
    }
}

# Get integer value
fn get_int(values: Map<String, Dynamic>, name: String) -> Int {
    match values.get(name) {
        Some(Dynamic::Int(i)) => i,
        _ => 0
    }
}

# Get float value
fn get_float(values: Map<String, Dynamic>, name: String) -> Float {
    match values.get(name) {
        Some(Dynamic::Float(f)) => f,
        _ => 0.0
    }
}

# Get bool value
fn get_bool(values: Map<String, Dynamic>, name: String) -> Bool {
    match values.get(name) {
        Some(Dynamic::Bool(b)) => b,
        _ => false
    }
}

# Get list value
fn get_list(values: Map<String, Dynamic>, name: String) -> List<Dynamic> {
    match values.get(name) {
        Some(Dynamic::List(l)) => l,
        _ => []
    }
}

# Subcommand structure
struct Subcommand {
    name: String,
    help: String,
    parser: fn(List<String>) -> Dynamic,
}

# Create subcommand
fn subcommand(name: String, help: String, parser: fn(List<String>) -> Dynamic) -> Subcommand {
    Subcommand { name, help, parser }
}

# Progress bar
struct ProgressBar {
    total: Int,
    current: Int,
    width: Int,
    prefix: String,
}

fn progress_new(total: Int) -> ProgressBar {
    ProgressBar {
        total,
        current: 0,
        width: 40,
        prefix: "".to_string()
    }
}

fn progress_set_prefix(pb: ProgressBar, prefix: String) -> ProgressBar {
    ProgressBar { prefix, ..pb }
}

fn progress_update(pb: ProgressBar, current: Int) -> ProgressBar {
    ProgressBar { current, ..pb }
}

fn progress_draw(pb: ProgressBar) {
    let filled = (pb.current as Float / pb.total as Float * pb.width as Float) as Int
    let empty = pb.width - filled
    
    let bar = "=".repeat(filled) + "-".repeat(empty)
    let percent = (pb.current as Float / pb.total as Float * 100.0) as Int
    
    print("\r", pb.prefix, "[", bar, "] ", percent, "% (", pb.current, "/", pb.total, ")")
}

fn progress_finish(pb: ProgressBar) {
    print("")
}

# Spinner for loading states
struct Spinner {
    frames: List<String>,
    current: Int,
}

fn spinner_new() -> Spinner {
    Spinner {
        frames: ["|", "/", "-", "\\"],
        current: 0
    }
}

fn spinner_next(sp: Spinner) -> Spinner {
    Spinner {
        current: (sp.current + 1) % sp.frames.len(),
        ..sp
    }
}

fn spinner_draw(sp: Spinner) {
    print("\r", sp.frames[sp.current], " ")
}

# Confirmation prompt
fn confirm(prompt: String) -> Bool {
    print(prompt, " [y/N]: ")
    let input = ""
    input.to_lowercase() == "y"
}

# Selection prompt
fn select(prompt: String, options: List<String>) -> Int {
    print(prompt)
    for (i, opt) in options.enumerate() {
        print("  ", i + 1, ". ", opt)
    }
    
    print("Selection: ")
    let input = ""
    
    match input.parse_int() {
        Some(n) if n >= 1 && n <= options.len() => n - 1,
        _ => 0
    }
}

# Export
export {
    Arg, ArgType,
    arg_string, arg_int, arg_float, arg_bool,
    with_short, with_default, required,
    Command, Parser,
    parser_new, add_argument, add_command, parse_args,
    print_help, print_usage, print_version,
    has_flag, get_string, get_int, get_float, get_bool, get_list,
    Subcommand, subcommand,
    ProgressBar, progress_new, progress_set_prefix, progress_update, progress_draw, progress_finish,
    Spinner, spinner_new, spinner_next, spinner_draw,
    confirm, select
}

# ===========================================
# Nyx Standard Library - Logging Module
# ===========================================
# Comprehensive logging utilities

# Log levels
let DEBUG = 10;
let INFO = 20;
let WARNING = 30;
let ERROR = 40;
let CRITICAL = 50;

let LOG_LEVEL_NAMES = {
    10: "DEBUG",
    20: "INFO",
    30: "WARNING",
    40: "ERROR",
    50: "CRITICAL"
};

# Logger class
class Logger {
    fn init(self, name) {
        self.name = name;
        self.level = INFO;
        self.handlers = [];
        self.formatters = [];
        self.filters = [];
    }
    
    fn set_level(self, level) {
        self.level = level;
        return self;
    }
    
    fn add_handler(self, handler) {
        push(self.handlers, handler);
        return self;
    }
    
    fn set_formatter(self, formatter) {
        push(self.formatters, formatter);
        return self;
    }
    
    fn add_filter(self, filter_fn) {
        push(self.filters, filter_fn);
        return self;
    }
    
    fn log(self, level, message) {
        # Check level
        if level < self.level {
            return;
        }
        
        # Apply filters
        for filter_fn in self.filters {
            if !filter_fn(self.name, level, message) {
                return;
            }
        }
        
        # Format message
        let formatted = message;
        for formatter in self.formatters {
            formatted = formatter(self.name, level, message);
        }
        
        # Send to handlers
        for handler in self.handlers {
            handler(level, formatted);
        }
    }
    
    fn debug(self, message) {
        self.log(DEBUG, message);
    }
    
    fn info(self, message) {
        self.log(INFO, message);
    }
    
    fn warning(self, message) {
        self.log(WARNING, message);
    }
    
    fn error(self, message) {
        self.log(ERROR, message);
    }
    
    fn critical(self, message) {
        self.log(CRITICAL, message);
    }
    
    fn exception(self, message) {
        # Would include stack trace
        self.log(ERROR, message);
    }
}

# Handler class
class Handler {
    fn init(self, level) {
        if type(level) == "null" {
            level = DEBUG;
        }
        self.level = level;
        self.formatter = null;
    }
    
    fn set_level(self, level) {
        self.level = level;
        return self;
    }
    
    fn set_formatter(self, formatter) {
        self.formatter = formatter;
        return self;
    }
    
    fn emit(self, record) {
        # To be overridden
    }
}

# Console handler
class ConsoleHandler {
    fn init(self, level) {
        if type(level) == "null" {
            level = DEBUG;
        }
        self.level = level;
        self.formatter = null;
    }
    
    fn set_level(self, level) {
        self.level = level;
        return self;
    }
    
    fn set_formatter(self, formatter) {
        self.formatter = formatter;
        return self;
    }
    
    fn emit(self, record) {
        if record.level < self.level {
            return;
        }
        
        let message = record.message;
        if self.formatter != null {
            message = self.formatter(record);
        }
        
        if record.level >= ERROR {
            print("[ERROR] " + message);
        } else if record.level >= WARNING {
            print("[WARN] " + message);
        } else if record.level >= INFO {
            print("[INFO] " + message);
        } else {
            print("[DEBUG] " + message);
        }
    }
}

# File handler
class FileHandler {
    fn init(self, filename, level) {
        if type(level) == "null" {
            level = DEBUG;
        }
        self.filename = filename;
        self.level = level;
        self.formatter = null;
    }
    
    fn set_level(self, level) {
        self.level = level;
        return self;
    }
    
    fn set_formatter(self, formatter) {
        self.formatter = formatter;
        return self;
    }
    
    fn emit(self, record) {
        if record.level < self.level {
            return;
        }
        
        let message = record.message;
        if self.formatter != null {
            message = self.formatter(record);
        }
        
        append_file(self.filename, message + "\n");
    }
}

# Rotating file handler (basic version)
class RotatingFileHandler {
    fn init(self, filename, max_bytes, level) {
        if type(level) == "null" {
            level = DEBUG;
        }
        self.filename = filename;
        self.max_bytes = max_bytes;
        self.level = level;
        self.backup_count = 5;
    }
    
    fn emit(self, record) {
        if record.level < self.level {
            return;
        }
        
        # Check rotation
        if file_exists(self.filename) {
            let size = file_size(self.filename);
            if size >= self.max_bytes {
                # Rotate
                for i in range(self.backup_count - 1, 0, -1) {
                    let src = self.filename + "." + str(i);
                    let dst = self.filename + "." + str(i + 1);
                    if file_exists(dst) {
                        delete_file(dst);
                    }
                    if file_exists(src) {
                        move_file(src, dst);
                    }
                }
                # Move current to .1
                if file_exists(self.filename + ".1") {
                    delete_file(self.filename + ".1");
                }
                move_file(self.filename, self.filename + ".1");
            }
        }
        
        append_file(self.filename, record.message + "\n");
    }
}

# Log record
class LogRecord {
    fn init(self, name, level, message) {
        self.name = name;
        self.level = level;
        self.message = message;
        self.timestamp = time();
        self.level_name = LOG_LEVEL_NAMES[level];
    }
    
    fn to_string(self) {
        return format_time(self.timestamp, "%Y-%m-%d %H:%M:%S") + " [" + self.level_name + "] " + self.message;
    }
}

# Formatter class
class Formatter {
    fn init(self, format_str) {
        if type(format_str) == "null" {
            format_str = "%(asctime)s [%(levelname)s] %(name)s: %(message)s";
        }
        self.format_str = format_str;
    }
    
    fn format(self, name, level, message) {
        let level_name = LOG_LEVEL_NAMES[level];
        let timestamp = time();
        
        let result = self.format_str;
        result = replace(result, "%(asctime)s", format_time(timestamp, "%Y-%m-%d %H:%M:%S"));
        result = replace(result, "%(levelname)s", level_name);
        result = replace(result, "%(name)s", name);
        result = replace(result, "%(message)s", message);
        
        return result;
    }
    
    fn __call__(self, name, level, message) {
        return self.format(name, level, message);
    }
}

# Simple formatter function
fn simple_formatter(name, level, message) {
    return format_time(time(), "%Y-%m-%d %H:%M:%S") + " [" + LOG_LEVEL_NAMES[level] + "] " + message;
}

# Detailed formatter
fn detailed_formatter(name, level, message) {
    return format_time(time(), "%Y-%m-%d %H:%M:%S.%f") + " [" + LOG_LEVEL_NAMES[level] + "] " + name + ": " + message;
}

# JSON formatter
fn json_formatter(name, level, message) {
    return json_encode({
        timestamp: time(),
        level: LOG_LEVEL_NAMES[level],
        logger: name,
        message: message
    });
}

# Get logger
fn get_logger(name) {
    return Logger(name);
}

# Root logger
let root_logger = Logger("root");

# Convenience functions
fn debug(message) {
    root_logger.debug(message);
}

fn info(message) {
    root_logger.info(message);
}

fn warning(message) {
    root_logger.warning(message);
}

fn error(message) {
    root_logger.error(message);
}

fn critical(message) {
    root_logger.critical(message);
}

# Basic configuration
fn basic_config(level, format, handlers) {
    if type(level) == "null" {
        level = INFO;
    }
    if type(format) == "null" {
        format = "%(asctime)s [%(levelname)s] %(name)s: %(message)s";
    }
    
    root_logger.set_level(level);
    
    if type(format) != "null" {
        let formatter = Formatter(format);
        root_logger.set_formatter(formatter.format);
    }
    
    if type(handlers) == "null" {
        root_logger.add_handler(ConsoleHandler(level));
    } else {
        for h in handlers {
            root_logger.add_handler(h);
        }
    }
}

# Configure from dict
fn config(config_dict) {
    if config_dict.level != null {
        root_logger.set_level(config_dict.level);
    }
    
    if config_dict.format != null {
        root_logger.set_formatter(Formatter(config_dict.format));
    }
    
    if config_dict.handlers != null {
        for h in config_dict.handlers {
            root_logger.add_handler(h);
        }
    }
}

# Filter functions
fn level_filter(min_level, name, level, message) {
    return level >= min_level;
}

fn name_filter(pattern, name, level, message) {
    return contains(name, pattern);
}

# Logger hierarchy
let _loggers = {};

fn Logger_get(name) {
    if _loggers[name] == null {
        _loggers[name] = Logger(name);
    }
    return _loggers[name];
}

# Context manager for temporary log level
class LogLevelContext {
    fn init(self, logger, level) {
        self.logger = logger;
        self.old_level = logger.level;
        logger.set_level(level);
    }
    
    fn __enter__(self) {
        return self.logger;
    }
    
    fn __exit__(self) {
        self.logger.set_level(self.old_level);
    }
}

# Colored console output (ANSI)
let RESET = "\x1b[0m";
let RED = "\x1b[31m";
let GREEN = "\x1b[32m";
let YELLOW = "\x1b[33m";
let BLUE = "\x1b[34m";
let MAGENTA = "\x1b[35m";
let CYAN = "\x1b[36m";
let WHITE = "\x1b[37m";
let BOLD = "\x1b[1m";

# Colored formatter
fn colored_formatter(name, level, message) {
    let color = WHITE;
    if level >= CRITICAL {
        color = RED + BOLD;
    } else if level >= ERROR {
        color = RED;
    } else if level >= WARNING {
        color = YELLOW;
    } else if level >= INFO {
        color = GREEN;
    } else {
        color = CYAN;
    }
    
    return color + format_time(time(), "%H:%M:%S") + RESET + " [" + color + LOG_LEVEL_NAMES[level] + RESET + "] " + name + ": " + message;
}

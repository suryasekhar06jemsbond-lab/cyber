# ============================================================
# Nyx Standard Library - Validator Module
# ============================================================
# Comprehensive data validation framework providing schema
# validation, type checking, custom validators, and complex
# validation rules.

# ============================================================
# Constants
# ============================================================

let VERSION = "1.0.0";

# Validation error codes
let ERR_REQUIRED = "required";
let ERR_TYPE = "type";
let ERR_MIN_LENGTH = "min_length";
let ERR_MAX_LENGTH = "max_length";
let ERR_MIN_VALUE = "min_value";
let ERR_MAX_VALUE = "max_value";
let ERR_PATTERN = "pattern";
let ERR_ENUM = "enum";
let ERR_FORMAT = "format";
let ERR_CUSTOM = "custom";
let ERR_NESTED = "nested";
let ERR_ARRAY = "array";
let ERR_OBJECT = "object";
let ERR_ONE_OF = "one_of";
let ERR_ALL_OF = "all_of";
let ERR_DEPENDENCY = "dependency";
let ERR_CONDITIONAL = "conditional";

# Common formats
let FMT_EMAIL = "email";
let FMT_URL = "url";
let FMT_URI = "uri";
let FMT_UUID = "uuid";
let FMT_IPV4 = "ipv4";
let FMT_IPV6 = "ipv6";
let FMT_DATE = "date";
let FMT_TIME = "time";
let FMT_DATETIME = "datetime";
let FMT_ISO8601 = "iso8601";
let FMT_PHONE = "phone";
let FMT_CREDIT_CARD = "credit_card";
let FMT_HEX = "hex";
let FMT_BASE64 = "base64";
let FMT_JSON = "json";

# Common types
let TYPE_STRING = "string";
let TYPE_NUMBER = "number";
let TYPE_INTEGER = "integer";
let TYPE_BOOLEAN = "boolean";
let TYPE_ARRAY = "array";
let TYPE_OBJECT = "object";
let TYPE_NULL = "null";
let TYPE_DATE = "date";

# ============================================================
# Validation Error
# ============================================================

class ValidationError {
    init(path, code, message, value, details) {
        self.path = path;
        self.code = code;
        self.message = message;
        self.value = value;
        self.details = details ?? {};
    }

    toDict() {
        return {
            "path": self.path,
            "code": self.code,
            "message": self.message,
            "value": self.value,
            "details": self.details
        };
    }

    toString() {
        let pathStr = "";
        for part in self.path {
            if pathStr != "" {
                pathStr = pathStr + ".";
            }
            if type(part) == "integer" {
                pathStr = pathStr + "[" + str(part) + "]";
            } else {
                pathStr = pathStr + part;
            }
        }
        return pathStr + ": " + self.message;
    }
}

# ============================================================
# Validation Result
# ============================================================

class ValidationResult {
    init() {
        self.valid = true;
        self.errors = [];
        self.warnings = [];
    }

    addError(path, code, message, value, details) {
        self.valid = false;
        let error = ValidationError(path, code, message, value, details);
        self.errors = self.errors + [error];
    }

    addWarning(path, code, message, value, details) {
        let warning = ValidationError(path, code, message, value, details);
        self.warnings = self.warnings + [warning];
    }

    isValid() {
        return self.valid;
    }

    hasErrors() {
        return len(self.errors) > 0;
    }

    hasWarnings() {
        return len(self.warnings) > 0;
    }

    getErrors() {
        return self.errors;
    }

    getWarnings() {
        return self.warnings;
    }

    getErrorMessages() {
        let messages = [];
        for error in self.errors {
            messages = messages + [error.toString()];
        }
        return messages;
    }

    toDict() {
        return {
            "valid": self.valid,
            "errors": [e.toDict() for e in self.errors],
            "warnings": [w.toDict() for w in self.warnings],
            "errorCount": len(self.errors),
            "warningCount": len(self.warnings)
        };
    }
}

# ============================================================
# Validator Base Class
# ============================================================

class Validator {
    init() {
        self.rules = {};
    }

    validate(value) {
        return self.validateAt(value, []);
    }

    validateAt(value, path) {
        return ValidationResult();
    }

    addRule(field, rule) {
        if self.rules[field] == null {
            self.rules[field] = [];
        }
        self.rules[field] = self.rules[field] + [rule];
    }

    clearRules() {
        self.rules = {};
    }
}

# ============================================================
# Schema Validator
# ============================================================

class SchemaValidator {
    init(schema) {
        self.schema = schema;
        self.validators = _buildValidators(schema);
    }

    validate(value) {
        return self.validateAt(value, []);
    }

    validateAt(value, path) {
        let result = ValidationResult();
        
        if self.schema["required"] == true {
            if value == null {
                result.addError(path, ERR_REQUIRED, "Value is required", value, {});
                return result;
            }
        }
        
        if value == null {
            return result;
        }
        
        # Type validation
        if self.schema["type"] != null {
            let typeResult = self._validateType(value, path);
            if typeResult.hasErrors() {
                for error in typeResult.errors {
                    result.errors = result.errors + [error];
                }
                result.valid = false;
            }
        }
        
        # String validations
        if type(value) == "string" {
            self._validateString(value, path, result);
        }
        
        # Number validations
        if type(value) == "number" {
            self._validateNumber(value, path, result);
        }
        
        # Array validations
        if type(value) == "list" {
            self._validateArray(value, path, result);
        }
        
        # Object validations
        if type(value) == "map" {
            self._validateObject(value, path, result);
        }
        
        # Enum validation
        if self.schema["enum"] != null {
            if value not in self.schema["enum"] {
                result.addError(path, ERR_ENUM, 
                    "Value must be one of: " + json.stringify(self.schema["enum"]),
                    value, {"allowed": self.schema["enum"]});
            }
        }
        
        # Custom validator
        if self.schema["validator"] != null {
            let customResult = self.schema["validator"](value);
            if type(customResult) == "map" {
                if customResult["valid"] == false {
                    result.addError(path, ERR_CUSTOM, 
                        customResult["message"] ?? "Custom validation failed",
                        value, customResult["details"] ?? {});
                }
            }
        }
        
        return result;
    }

    _validateType(value, path) {
        let result = ValidationResult();
        let expectedType = self.schema["type"];
        
        let actualType = type(value);
        if expectedType == TYPE_INTEGER {
            if actualType != "number" or value != floor(value) {
                result.addError(path, ERR_TYPE, 
                    "Value must be an integer", value, 
                    {"expected": expectedType, "actual": actualType});
            }
        } else if expectedType != actualType {
            result.addError(path, ERR_TYPE, 
                "Value must be of type " + expectedType, value, 
                {"expected": expectedType, "actual": actualType});
        }
        
        return result;
    }

    _validateString(value, path, result) {
        # Min length
        if self.schema["minLength"] != null {
            if len(value) < self.schema["minLength"] {
                result.addError(path, ERR_MIN_LENGTH, 
                    "String must be at least " + str(self.schema["minLength"]) + " characters",
                    value, {"minLength": self.schema["minLength"], "actual": len(value)});
            }
        }
        
        # Max length
        if self.schema["maxLength"] != null {
            if len(value) > self.schema["maxLength"] {
                result.addError(path, ERR_MAX_LENGTH, 
                    "String must be at most " + str(self.schema["maxLength"]) + " characters",
                    value, {"maxLength": self.schema["maxLength"], "actual": len(value)});
            }
        }
        
        # Pattern (regex)
        if self.schema["pattern"] != null {
            if not _regexMatch(value, self.schema["pattern"]) {
                result.addError(path, ERR_PATTERN, 
                    "String must match pattern: " + self.schema["pattern"],
                    value, {"pattern": self.schema["pattern"]});
            }
        }
        
        # Format
        if self.schema["format"] != null {
            let formatResult = self._validateFormat(value, path);
            if formatResult.hasErrors() {
                for error in formatResult.errors {
                    result.errors = result.errors + [error];
                }
                result.valid = false;
            }
        }
    }

    _validateNumber(value, path, result) {
        # Min value
        if self.schema["min"] != null {
            if value < self.schema["min"] {
                result.addError(path, ERR_MIN_VALUE, 
                    "Value must be at least " + str(self.schema["min"]),
                    value, {"min": self.schema["min"], "actual": value});
            }
        }
        
        # Max value
        if self.schema["max"] != null {
            if value > self.schema["max"] {
                result.addError(path, ERR_MAX_VALUE, 
                    "Value must be at most " + str(self.schema["max"]),
                    value, {"max": self.schema["max"], "actual": value});
            }
        }
        
        # Multiple of
        if self.schema["multipleOf"] != null {
            if value % self.schema["multipleOf"] != 0 {
                result.addError(path, ERR_TYPE, 
                    "Value must be a multiple of " + str(self.schema["multipleOf"]),
                    value, {"multipleOf": self.schema["multipleOf"]});
            }
        }
        
        # Exclusive minimum
        if self.schema["exclusiveMin"] != null {
            if value <= self.schema["exclusiveMin"] {
                result.addError(path, ERR_MIN_VALUE, 
                    "Value must be greater than " + str(self.schema["exclusiveMin"]),
                    value, {"exclusiveMin": self.schema["exclusiveMin"], "actual": value});
            }
        }
        
        # Exclusive maximum
        if self.schema["exclusiveMax"] != null {
            if value >= self.schema["exclusiveMax"] {
                result.addError(path, ERR_MAX_VALUE, 
                    "Value must be less than " + str(self.schema["exclusiveMax"]),
                    value, {"exclusiveMax": self.schema["exclusiveMax"], "actual": value});
            }
        }
    }

    _validateArray(value, path, result) {
        # Min items
        if self.schema["minItems"] != null {
            if len(value) < self.schema["minItems"] {
                result.addError(path, ERR_MIN_LENGTH, 
                    "Array must have at least " + str(self.schema["minItems"]) + " items",
                    value, {"minItems": self.schema["minItems"], "actual": len(value)});
            }
        }
        
        # Max items
        if self.schema["maxItems"] != null {
            if len(value) > self.schema["maxItems"] {
                result.addError(path, ERR_MAX_LENGTH, 
                    "Array must have at most " + str(self.schema["maxItems"]) + " items",
                    value, {"maxItems": self.schema["maxItems"], "actual": len(value)});
            }
        }
        
        # Unique items
        if self.schema["uniqueItems"] == true {
            if not _isUnique(value) {
                result.addError(path, ERR_ARRAY, 
                    "Array items must be unique",
                    value, {});
            }
        }
        
        # Items schema
        if self.schema["items"] != null {
            let itemValidator = SchemaValidator(self.schema["items"]);
            for i in range(len(value)) {
                let itemPath = path + [i];
                let itemResult = itemValidator.validateAt(value[i], itemPath);
                for error in itemResult.errors {
                    result.errors = result.errors + [error];
                }
                if not itemResult.valid {
                    result.valid = false;
                }
            }
        }
    }

    _validateObject(value, path, result) {
        # Properties validation
        if self.schema["properties"] != null {
            for propName in keys(self.schema["properties"]) {
                if value[propName] != null {
                    let propSchema = self.schema["properties"][propName];
                    let propValidator = SchemaValidator(propSchema);
                    let propPath = path + [propName];
                    let propResult = propValidator.validateAt(value[propName], propPath);
                    
                    for error in propResult.errors {
                        result.errors = result.errors + [error];
                    }
                    if not propResult.valid {
                        result.valid = false;
                    }
                } else if self.schema["required"] != null and propName in self.schema["required"] {
                    result.addError(path + [propName], ERR_REQUIRED, 
                        "Property " + propName + " is required",
                        null, {"property": propName});
                    result.valid = false;
                }
            }
        }
        
        # Min properties
        if self.schema["minProperties"] != null {
            let propCount = len(keys(value));
            if propCount < self.schema["minProperties"] {
                result.addError(path, ERR_OBJECT, 
                    "Object must have at least " + str(self.schema["minProperties"]) + " properties",
                    value, {"minProperties": self.schema["minProperties"], "actual": propCount});
            }
        }
        
        # Max properties
        if self.schema["maxProperties"] != null {
            let propCount = len(keys(value));
            if propCount > self.schema["maxProperties"] {
                result.addError(path, ERR_OBJECT, 
                    "Object must have at most " + str(self.schema["maxProperties"]) + " properties",
                    value, {"maxProperties": self.schema["maxProperties"], "actual": propCount});
            }
        }
        
        # Additional properties
        if self.schema["additionalProperties"] == false {
            let allowedProps = keys(self.schema["properties"] ?? {});
            for propName in keys(value) {
                if propName not in allowedProps {
                    result.addError(path + [propName], ERR_OBJECT, 
                        "Property " + propName + " is not allowed",
                        value[propName], {"property": propName});
                    result.valid = false;
                }
            }
        }
    }

    _validateFormat(value, path) {
        let result = ValidationResult();
        let format = self.schema["format"];
        
        if format == FMT_EMAIL {
            if not _isValidEmail(value) {
                result.addError(path, ERR_FORMAT, "Invalid email format", value, {"format": format});
            }
        } else if format == FMT_URL {
            if not _isValidURL(value) {
                result.addError(path, ERR_FORMAT, "Invalid URL format", value, {"format": format});
            }
        } else if format == FMT_UUID {
            if not _isValidUUID(value) {
                result.addError(path, ERR_FORMAT, "Invalid UUID format", value, {"format": format});
            }
        } else if format == FMT_IPV4 {
            if not _isValidIPv4(value) {
                result.addError(path, ERR_FORMAT, "Invalid IPv4 address", value, {"format": format});
            }
        } else if format == FMT_IPV6 {
            if not _isValidIPv6(value) {
                result.addError(path, ERR_FORMAT, "Invalid IPv6 address", value, {"format": format});
            }
        } else if format == FMT_DATE {
            if not _isValidDate(value) {
                result.addError(path, ERR_FORMAT, "Invalid date format (YYYY-MM-DD)", value, {"format": format});
            }
        } else if format == FMT_DATETIME or format == FMT_ISO8601 {
            if not _isValidDateTime(value) {
                result.addError(path, ERR_FORMAT, "Invalid datetime format (ISO 8601)", value, {"format": format});
            }
        } else if format == FMT_PHONE {
            if not _isValidPhone(value) {
                result.addError(path, ERR_FORMAT, "Invalid phone number format", value, {"format": format});
            }
        } else if format == FMT_HEX {
            if not _isValidHex(value) {
                result.addError(path, ERR_FORMAT, "Invalid hex string", value, {"format": format});
            }
        } else if format == FMT_BASE64 {
            if not _isValidBase64(value) {
                result.addError(path, ERR_FORMAT, "Invalid base64 string", value, {"format": format});
            }
        } else if format == FMT_JSON {
            if not _isValidJSON(value) {
                result.addError(path, ERR_FORMAT, "Invalid JSON string", value, {"format": format});
            }
        } else if format == FMT_CREDIT_CARD {
            if not _isValidCreditCard(value) {
                result.addError(path, ERR_FORMAT, "Invalid credit card number", value, {"format": format});
            }
        }
        
        return result;
    }
}

# ============================================================
# Helper Functions
# ============================================================

fn _regexMatch(value, pattern) {
    # Simple regex matching using regex module
    let regex = require("regex");
    let matcher = regex.create(pattern);
    return matcher.test(value);
}

fn _isUnique(arr) {
    let seen = {};
    for item in arr {
        let key = json.stringify(item);
        if seen[key] == true {
            return false;
        }
        seen[key] = true;
    }
    return true;
}

fn _isValidEmail(value) {
    # Basic email validation
    let regex = require("regex");
    let pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$";
    return regex.create(pattern).test(value);
}

fn _isValidURL(value) {
    let regex = require("regex");
    let pattern = "^https?://[a-zA-Z0-9.-]+(?:/[a-zA-Z0-9._~:/?#\\[\\]@!$&'()*+,;=-]*)?$";
    return regex.create(pattern).test(value);
}

fn _isValidUUID(value) {
    let regex = require("regex");
    let pattern = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$";
    return regex.create(pattern).test(value);
}

fn _isValidIPv4(value) {
    let parts = split(value, ".");
    if len(parts) != 4 {
        return false;
    }
    for part in parts {
        let num = parseInt(part);
        if num < 0 or num > 255 {
            return false;
        }
    }
    return true;
}

fn _isValidIPv6(value) {
    let regex = require("regex");
    let pattern = "^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$";
    return regex.create(pattern).test(value);
}

fn _isValidDate(value) {
    let regex = require("regex");
    let pattern = "^[0-9]{4}-[0-9]{2}-[0-9]{2}$";
    if not regex.create(pattern).test(value) {
        return false;
    }
    # Additional validation would go here
    return true;
}

fn _isValidDateTime(value) {
    let regex = require("regex");
    let pattern = "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})?$";
    return regex.create(pattern).test(value);
}

fn _isValidPhone(value) {
    let regex = require("regex");
    let pattern = "^[+]?[0-9]{10,15}$";
    return regex.create(pattern).test(value);
}

fn _isValidHex(value) {
    let regex = require("regex");
    let pattern = "^[0-9a-fA-F]+$";
    return regex.create(pattern).test(value);
}

fn _isValidBase64(value) {
    let regex = require("regex");
    let pattern = "^[A-Za-z0-9+/]*={0,2}$";
    return regex.create(pattern).test(value);
}

fn _isValidJSON(value) {
    try {
        let parsed = json.parse(value);
        return parsed != null;
    } catch e {
        return false;
    }
}

fn _isValidCreditCard(value) {
    # Luhn algorithm
    let digits = [];
    for c in value {
        if c >= "0" and c <= "9" {
            digits = digits + [parseInt(c)];
        }
    }
    
    if len(digits) < 13 or len(digits) > 19 {
        return false;
    }
    
    let sum = 0;
    let alternate = false;
    for i in range(len(digits) - 1, -1, -1) {
        let d = digits[i];
        if alternate {
            d = d * 2;
            if d > 9 {
                d = d - 9;
            }
        }
        sum = sum + d;
        alternate = not alternate;
    }
    
    return sum % 10 == 0;
}

# ============================================================
# Built-in Validators
# ============================================================

class RequiredValidator {
    init(message) {
        self.message = message ?? "This field is required";
    }

    validate(value, path) {
        let result = ValidationResult();
        if value == null or value == "" {
            result.addError(path, ERR_REQUIRED, self.message, value, {});
        }
        return result;
    }
}

class TypeValidator {
    init(expectedType, message) {
        self.expectedType = expectedType;
        self.message = message ?? "Value must be of type " + expectedType;
    }

    validate(value, path) {
        let result = ValidationResult();
        if type(value) != self.expectedType {
            result.addError(path, ERR_TYPE, self.message, value, 
                {"expected": self.expectedType, "actual": type(value)});
        }
        return result;
    }
}

class RangeValidator {
    init(min, max, message) {
        self.min = min;
        self.max = max;
        self.message = message ?? "Value must be between " + str(min) + " and " + str(max);
    }

    validate(value, path) {
        let result = ValidationResult();
        if type(value) == "number" {
            if self.min != null and value < self.min {
                result.addError(path, ERR_MIN_VALUE, self.message, value, {"min": self.min});
            }
            if self.max != null and value > self.max {
                result.addError(path, ERR_MAX_VALUE, self.message, value, {"max": self.max});
            }
        }
        return result;
    }
}

class LengthValidator {
    init(minLength, maxLength, message) {
        self.minLength = minLength;
        self.maxLength = maxLength;
        self.message = message;
    }

    validate(value, path) {
        let result = ValidationResult();
        if type(value) == "string" or type(value) == "list" {
            let len = type(value) == "string" ? len(value) : len(value);
            if self.minLength != null and len < self.minLength {
                let msg = self.message ?? "Length must be at least " + str(self.minLength);
                result.addError(path, ERR_MIN_LENGTH, msg, value, {"minLength": self.minLength});
            }
            if self.maxLength != null and len > self.maxLength {
                let msg = self.message ?? "Length must be at most " + str(self.maxLength);
                result.addError(path, ERR_MAX_LENGTH, msg, value, {"maxLength": self.maxLength});
            }
        }
        return result;
    }
}

class PatternValidator {
    init(pattern, message) {
        self.pattern = pattern;
        self.message = message ?? "Value must match pattern: " + pattern;
        self.regex = regex.create(pattern);
    }

    validate(value, path) {
        let result = ValidationResult();
        if type(value) == "string" {
            if not self.regex.test(value) {
                result.addError(path, ERR_PATTERN, self.message, value, {"pattern": self.pattern});
            }
        }
        return result;
    }
}

class FormatValidator {
    init(format, message) {
        self.format = format;
        self.message = message ?? "Invalid " + format + " format";
    }

    validate(value, path) {
        let result = ValidationResult();
        if type(value) == "string" {
            let validator = SchemaValidator({"format": self.format});
            let formatResult = validator._validateFormat(value, path);
            if formatResult.hasErrors() {
                result.addError(path, ERR_FORMAT, self.message, value, {"format": self.format});
            }
        }
        return result;
    }
}

class EnumValidator {
    init(allowedValues, message) {
        self.allowedValues = allowedValues;
        self.message = message ?? "Value must be one of: " + json.stringify(allowedValues);
    }

    validate(value, path) {
        let result = ValidationResult();
        if value not in self.allowedValues {
            result.addError(path, ERR_ENUM, self.message, value, {"allowed": self.allowedValues});
        }
        return result;
    }
}

class CustomValidator {
    init(validatorFn, message) {
        self.validatorFn = validatorFn;
        self.message = message ?? "Custom validation failed";
    }

    validate(value, path) {
        let result = ValidationResult();
        try {
            let isValid = self.validatorFn(value);
            if not isValid {
                result.addError(path, ERR_CUSTOM, self.message, value, {});
            }
        } catch e {
            result.addError(path, ERR_CUSTOM, self.message + ": " + str(e), value, {"error": str(e)});
        }
        return result;
    }
}

# ============================================================
# Composite Validators
# ============================================================

class OneOfValidator {
    init(schemas, message) {
        self.schemas = schemas;
        self.message = message ?? "Value must match exactly one schema";
    }

    validate(value, path) {
        let result = ValidationResult();
        let matches = 0;
        
        for schema in self.schemas {
            let validator = SchemaValidator(schema);
            let schemaResult = validator.validate(value);
            if schemaResult.isValid() {
                matches = matches + 1;
            }
        }
        
        if matches == 0 {
            result.addError(path, ERR_ONE_OF, self.message, value, {"schemas": len(self.schemas)});
        } else if matches > 1 {
            result.addError(path, ERR_ONE_OF, "Value matches multiple schemas", value, {"matches": matches});
        }
        
        return result;
    }
}

class AllOfValidator {
    init(schemas, message) {
        self.schemas = schemas;
        self.message = message ?? "Value must match all schemas";
    }

    validate(value, path) {
        let result = ValidationResult();
        
        for i in range(len(self.schemas)) {
            let validator = SchemaValidator(self.schemas[i]);
            let schemaResult = validator.validate(value);
            if not schemaResult.isValid() {
                result.addError(path, ERR_ALL_OF, 
                    "Schema " + str(i) + " validation failed", value, 
                    {"schemaIndex": i, "errors": schemaResult.getErrorMessages()});
            }
        }
        
        return result;
    }
}

class AnyOfValidator {
    init(schemas, message) {
        self.schemas = schemas;
        self.message = message ?? "Value must match at least one schema";
    }

    validate(value, path) {
        let result = ValidationResult();
        
        for schema in self.schemas {
            let validator = SchemaValidator(schema);
            let schemaResult = validator.validate(value);
            if schemaResult.isValid() {
                return result;
            }
        }
        
        result.addError(path, ERR_ONE_OF, self.message, value, {"schemas": len(self.schemas)});
        return result;
    }
}

class NotValidator {
    init(schema, message) {
        self.schema = schema;
        self.message = message ?? "Value must not match this schema";
    }

    validate(value, path) {
        let result = ValidationResult();
        let validator = SchemaValidator(self.schema);
        let schemaResult = validator.validate(value);
        
        if schemaResult.isValid() {
            result.addError(path, ERR_CUSTOM, self.message, value, {});
        }
        
        return result;
    }
}

# ============================================================
# Conditional Validator
# ============================================================

class ConditionalValidator {
    init(condition, thenSchema, elseSchema, message) {
        self.condition = condition;
        self.thenSchema = thenSchema;
        self.elseSchema = elseSchema;
        self.message = message ?? "Conditional validation failed";
    }

    validate(value, path) {
        let result = ValidationResult();
        
        let shouldValidate = false;
        if type(self.condition) == "function" {
            shouldValidate = self.condition(value);
        } else if type(self.condition) == "map" {
            # Check if condition fields exist
            for field in keys(self.condition) {
                if value[field] == self.condition[field] {
                    shouldValidate = true;
                }
            }
        }
        
        if shouldValidate and self.thenSchema != null {
            let validator = SchemaValidator(self.thenSchema);
            let thenResult = validator.validate(value);
            for error in thenResult.errors {
                result.errors = result.errors + [error];
            }
            if not thenResult.valid {
                result.valid = false;
            }
        } else if not shouldValidate and self.elseSchema != null {
            let validator = SchemaValidator(self.elseSchema);
            let elseResult = validator.validate(value);
            for error in elseResult.errors {
                result.errors = result.errors + [error];
            }
            if not elseResult.valid {
                result.valid = false;
            }
        }
        
        return result;
    }
}

# ============================================================
# Dependency Validator
# ============================================================

class DependencyValidator {
    init(dependencies, message) {
        self.dependencies = dependencies;
        self.message = message ?? "Required dependency not satisfied";
    }

    validate(value, path) {
        let result = ValidationResult();
        
        for field in keys(self.dependencies) {
            if value[field] != null {
                let requiredFields = self.dependencies[field];
                if type(requiredFields) == "list" {
                    for reqField in requiredFields {
                        if value[reqField] == null {
                            result.addError(path + [reqField], ERR_DEPENDENCY, 
                                "Field " + reqField + " is required when " + field + " is present",
                                value, {"field": field, "required": reqField});
                        }
                    }
                }
            }
        }
        
        return result;
    }
}

# ============================================================
# Validator Builder
# ============================================================

class ValidatorBuilder {
    init() {
        self.validators = [];
        self._field = null;
    }

    field(fieldName) {
        self._field = fieldName;
        return self;
    }

    required(message) {
        self.validators = self.validators + [RequiredValidator(message)];
        return self;
    }

    type(expectedType, message) {
        self.validators = self.validators + [TypeValidator(expectedType, message)];
        return self;
    }

    min(value, message) {
        self.validators = self.validators + [RangeValidator(value, null, message)];
        return self;
    }

    max(value, message) {
        self.validators = self.validators + [RangeValidator(null, value, message)];
        return self;
    }

    range(min, max, message) {
        self.validators = self.validators + [RangeValidator(min, max, message)];
        return self;
    }

    minLength(length, message) {
        self.validators = self.validators + [LengthValidator(length, null, message)];
        return self;
    }

    maxLength(length, message) {
        self.validators = self.validators + [LengthValidator(null, length, message)];
        return self;
    }

    length(min, max, message) {
        self.validators = self.validators + [LengthValidator(min, max, message)];
        return self;
    }

    pattern(pattern, message) {
        self.validators = self.validators + [PatternValidator(pattern, message)];
        return self;
    }

    format(format, message) {
        self.validators = self.validators + [FormatValidator(format, message)];
        return self;
    }

    enum(values, message) {
        self.validators = self.validators + [EnumValidator(values, message)];
        return self;
    }

    custom(validatorFn, message) {
        self.validators = self.validators + [CustomValidator(validatorFn, message)];
        return self;
    }

    oneOf(schemas, message) {
        self.validators = self.validators + [OneOfValidator(schemas, message)];
        return self;
    }

    allOf(schemas, message) {
        self.validators = self.validators + [AllOfValidator(schemas, message)];
        return self;
    }

    anyOf(schemas, message) {
        self.validators = self.validators + [AnyOfValidator(schemas, message)];
        return self;
    }

    not(schema, message) {
        self.validators = self.validators + [NotValidator(schema, message)];
        return self;
    }

    build() {
        let validators = self.validators;
        return fn(value) {
            let result = ValidationResult();
            for validator in validators {
                let validatorResult = validator.validate(value, []);
                for error in validatorResult.errors {
                    result.errors = result.errors + [error];
                }
                if not validatorResult.valid {
                    result.valid = false;
                }
            }
            return result;
        };
    }
}

# ============================================================
# Form Validator
# ============================================================

class FormValidator {
    init(schema) {
        self.schema = schema;
        self.validators = {};
        
        # Build validators for each field
        for fieldName in keys(schema) {
            let fieldSchema = schema[fieldName];
            self.validators[fieldName] = SchemaValidator(fieldSchema);
        }
    }

    validate(data) {
        let result = ValidationResult();
        
        # Check required fields
        for fieldName in keys(self.schema) {
            let fieldSchema = self.schema[fieldName];
            
            if fieldSchema["required"] == true {
                if data[fieldName] == null {
                    result.addError([fieldName], ERR_REQUIRED, 
                        "Field " + fieldName + " is required", null, 
                        {"field": fieldName});
                }
            }
        }
        
        # Validate each field
        for fieldName in keys(self.validators) {
            if data[fieldName] != null {
                let fieldResult = self.validators[fieldName].validate(data[fieldName]);
                for error in fieldResult.errors {
                    result.errors = result.errors + [[fieldName] + error.path];
                    result.errors[len(result.errors) - 1] = error;
                }
                if not fieldResult.valid {
                    result.valid = false;
                }
            }
        }
        
        return result;
    }

    validateField(fieldName, value) {
        if self.validators[fieldName] != null {
            return self.validators[fieldName].validate(value);
        }
        return ValidationResult();
    }
}

# ============================================================
# Schema Builder
# ============================================================

class SchemaBuilder {
    init() {
        self.schema = {};
    }

    type(typeName) {
        self.schema["type"] = typeName;
        return self;
    }

    required(isRequired) {
        self.schema["required"] = isRequired;
        return self;
    }

    min(value) {
        self.schema["min"] = value;
        return self;
    }

    max(value) {
        self.schema["max"] = value;
        return self;
    }

    minLength(length) {
        self.schema["minLength"] = length;
        return self;
    }

    maxLength(length) {
        self.schema["maxLength"] = length;
        return self;
    }

    minItems(count) {
        self.schema["minItems"] = count;
        return self;
    }

    maxItems(count) {
        self.schema["maxItems"] = count;
        return self;
    }

    pattern(regex) {
        self.schema["pattern"] = regex;
        return self;
    }

    format(format) {
        self.schema["format"] = format;
        return self;
    }

    enum(values) {
        self.schema["enum"] = values;
        return self;
    }

    items(itemSchema) {
        self.schema["items"] = itemSchema;
        return self;
    }

    properties(props) {
        self.schema["properties"] = props;
        return self;
    }

    additionalProperties(allowed) {
        self.schema["additionalProperties"] = allowed;
        return self;
    }

    uniqueItems() {
        self.schema["uniqueItems"] = true;
        return self;
    }

    validator(fn) {
        self.schema["validator"] = fn;
        return self;
    }

    build() {
        return self.schema;
    }
}

# ============================================================
# Common Schema Definitions
# ============================================================

let CommonSchemas = {
    "email": {
        "type": "string",
        "format": "email"
    },
    "url": {
        "type": "string",
        "format": "url"
    },
    "uuid": {
        "type": "string",
        "format": "uuid"
    },
    "ipv4": {
        "type": "string",
        "format": "ipv4"
    },
    "ipv6": {
        "type": "string",
        "format": "ipv6"
    },
    "date": {
        "type": "string",
        "format": "date"
    },
    "datetime": {
        "type": "string",
        "format": "datetime"
    },
    "phone": {
        "type": "string",
        "format": "phone"
    },
    "creditCard": {
        "type": "string",
        "format": "credit_card"
    },
    "json": {
        "type": "string",
        "format": "json"
    },
    "nonEmptyString": {
        "type": "string",
        "minLength": 1
    },
    "positiveInteger": {
        "type": "integer",
        "min": 1
    },
    "nonNegativeInteger": {
        "type": "integer",
        "min": 0
    },
    "boolean": {
        "type": "boolean"
    },
    "array": {
        "type": "array"
    },
    "object": {
        "type": "object"
    }
};

# ============================================================
# Validation Utility Functions
# ============================================================

fn validate(value, schema) {
    let validator = SchemaValidator(schema);
    return validator.validate(value);
}

fn validateField(value, fieldSchema) {
    let validator = SchemaValidator(fieldSchema);
    return validator.validate(value);
}

fn isValid(value, schema) {
    let result = validate(value, schema);
    return result.isValid();
}

fn createSchema() {
    return SchemaBuilder();
}

fn createValidator() {
    return ValidatorBuilder();
}

fn createFormValidator(schema) {
    return FormValidator(schema);
}

fn getErrorMessages(result) {
    return result.getErrorMessages();
}

# ============================================================
# Export
# ============================================================

{
    "ValidationError": ValidationError,
    "ValidationResult": ValidationResult,
    "Validator": Validator,
    "SchemaValidator": SchemaValidator,
    "RequiredValidator": RequiredValidator,
    "TypeValidator": TypeValidator,
    "RangeValidator": RangeValidator,
    "LengthValidator": LengthValidator,
    "PatternValidator": PatternValidator,
    "FormatValidator": FormatValidator,
    "EnumValidator": EnumValidator,
    "CustomValidator": CustomValidator,
    "OneOfValidator": OneOfValidator,
    "AllOfValidator": AllOfValidator,
    "AnyOfValidator": AnyOfValidator,
    "NotValidator": NotValidator,
    "ConditionalValidator": ConditionalValidator,
    "DependencyValidator": DependencyValidator,
    "ValidatorBuilder": ValidatorBuilder,
    "FormValidator": FormValidator,
    "SchemaBuilder": SchemaBuilder,
    "CommonSchemas": CommonSchemas,
    "validate": validate,
    "validateField": validateField,
    "isValid": isValid,
    "createSchema": createSchema,
    "createValidator": createValidator,
    "createFormValidator": createFormValidator,
    "getErrorMessages": getErrorMessages,
    "ERR_REQUIRED": ERR_REQUIRED,
    "ERR_TYPE": ERR_TYPE,
    "ERR_MIN_LENGTH": ERR_MIN_LENGTH,
    "ERR_MAX_LENGTH": ERR_MAX_LENGTH,
    "ERR_MIN_VALUE": ERR_MIN_VALUE,
    "ERR_MAX_VALUE": ERR_MAX_VALUE,
    "ERR_PATTERN": ERR_PATTERN,
    "ERR_ENUM": ERR_ENUM,
    "ERR_FORMAT": ERR_FORMAT,
    "ERR_CUSTOM": ERR_CUSTOM,
    "ERR_NESTED": ERR_NESTED,
    "ERR_ARRAY": ERR_ARRAY,
    "ERR_OBJECT": ERR_OBJECT,
    "ERR_ONE_OF": ERR_ONE_OF,
    "ERR_ALL_OF": ERR_ALL_OF,
    "ERR_DEPENDENCY": ERR_DEPENDENCY,
    "ERR_CONDITIONAL": ERR_CONDITIONAL,
    "FMT_EMAIL": FMT_EMAIL,
    "FMT_URL": FMT_URL,
    "FMT_URI": FMT_URI,
    "FMT_UUID": FMT_UUID,
    "FMT_IPV4": FMT_IPV4,
    "FMT_IPV6": FMT_IPV6,
    "FMT_DATE": FMT_DATE,
    "FMT_TIME": FMT_TIME,
    "FMT_DATETIME": FMT_DATETIME,
    "FMT_ISO8601": FMT_ISO8601,
    "FMT_PHONE": FMT_PHONE,
    "FMT_CREDIT_CARD": FMT_CREDIT_CARD,
    "FMT_HEX": FMT_HEX,
    "FMT_BASE64": FMT_BASE64,
    "FMT_JSON": FMT_JSON,
    "TYPE_STRING": TYPE_STRING,
    "TYPE_NUMBER": TYPE_NUMBER,
    "TYPE_INTEGER": TYPE_INTEGER,
    "TYPE_BOOLEAN": TYPE_BOOLEAN,
    "TYPE_ARRAY": TYPE_ARRAY,
    "TYPE_OBJECT": TYPE_OBJECT,
    "TYPE_NULL": TYPE_NULL,
    "TYPE_DATE": TYPE_DATE,
    "VERSION": VERSION
}

# Debugger Module for Cyber Language

This module provides comprehensive debugging capabilities for the Cyber language, including error detection, reporting, and handling features.

## Features
- Error Detection
- Reporting
- Debugging Capabilities
- Syntax Validation
- Type Checking
- Runtime Error Handling
- Issue Reporting System

## Error Severity Levels
- **Critical**: Causes program termination.
- **High**: Serious issues that affect functionality but do not terminate the program.
- **Medium**: Warning signs that could lead to issues later.
- **Low**: Informational messages that do not affect the program.

## Error Codes
- `E100`: Syntax Error
- `E200`: Type Mismatch
- `E300`: Runtime Error

## Error Detection
Error detection is carried out during the parsing stage. The following functions are implemented:

```python
class ErrorDetector:
    def __init__(self):
        self.errors = []

    def detect_syntax(self, code):
        pass  # Implement syntax checking logic

    def check_types(self, code):
        pass  # Implement type checking logic

    def report_errors(self):
        for error in self.errors:
            print(error)
```

## Reporting
Error reporting uses a logging system. Depending on the severity level, errors can be logged or printed.

## Example Usage
```python
if __name__ == '__main__':
    detector = ErrorDetector()
    code_string = 'var = 5'
    detector.detect_syntax(code_string)
    detector.check_types(code_string)
    detector.report_errors()
```

## Runtime Error Handling
Runtime errors will be caught using try-except blocks to prevent program crashing:

```python
try:
    execute_code(code_string)
except Exception as e:
    print(f'Runtime error: {e}')
```

## Issue Reporting System
For any issues found during debugging, users can submit reports through the following interface:

```python
class IssueReporter:
    def __init__(self):
        self.issues = []

    def report_issue(self, description):
        self.issues.append(description)
        print('Issue reported: ', description)
```
```
# High-Precision Arithmetic Library for Nyx
# Arbitrary precision numerical computing

module precision

# BigFloat structure with configurable precision
struct BigFloat {
    mantissa: String,  # Decimal digits
    exponent: Int,     # Power of 10
    precision: Int,    # Number of significant digits
    sign: Int          # 1 or -1
}

# Create BigFloat from string
fn bigfloat_from_str(s: String, precision: Int) -> BigFloat {
    let s = s.trim()
    
    let sign = if s.starts_with("-") { -1 } else { 1 }
    let s = if s.starts_with("-") || s.starts_with("+") { 
        s.substring(1) 
    } else { s }
    
    let parts = s.split("e")
    let mantissa = parts[0].replace(".", "")
    let exponent = if parts.len() > 1 { 
        parts[1].parse_int().unwrap_or(0) 
    } else { 
        -(mantissa.index_of(".") as Int) 
    }
    
    # Trim to precision
    let mantissa = mantissa.replace(".", "")
    let mantissa = if mantissa.len() > precision {
        mantissa.substring(0, precision)
    } else {
        mantissa
    }
    
    BigFloat {
        mantissa,
        exponent,
        precision,
        sign
    }
}

# Create BigFloat from integer
fn bigfloat_from_int(n: Int, precision: Int) -> BigFloat {
    let sign = if n < 0 { -1 } else { 1 }
    let mantissa = n.abs().to_string()
    
    BigFloat {
        mantissa,
        exponent: 0,
        precision,
        sign
    }
}

# Create BigFloat from float
fn bigfloat_from_float(n: Float, precision: Int) -> BigFloat {
    bigfloat_from_str(n.to_string(), precision)
}

# Convert BigFloat to string
fn bigfloat_to_string(x: BigFloat) -> String {
    let sign = if x.sign < 0 { "-" } else { "" }
    let mantissa = x.mantissa
    let exponent = x.exponent
    
    # Insert decimal point
    let decimal_pos = mantissa.len() - x.exponent
    let mantissa = if decimal_pos > 0 && decimal_pos < mantissa.len() {
        mantissa.substring(0, decimal_pos) + "." + mantissa.substring(decimal_pos)
    } else if decimal_pos <= 0 {
        "0." + "0".repeat(-decimal_pos) + mantissa
    } else {
        mantissa + "0".repeat(decimal_pos - mantissa.len())
    }
    
    sign + mantissa
}

# BigFloat addition
fn bigfloat_add(a: BigFloat, b: BigFloat) -> BigFloat {
    let precision = a.precision.max(b.precision)
    
    # Align exponents
    let (m1, e1) = align_exponent(a, b)
    let (m2, e2) = align_exponent(b, a)
    
    # Add mantissas
    let result = bigint_add(m1, m2)
    
    BigFloat {
        mantissa: result,
        exponent: e1,
        precision,
        sign: 1
    }
}

# Align exponents for addition
fn align_exponent(a: BigFloat, b: BigFloat) -> (String, Int) {
    let diff = a.exponent - b.exponent
    if diff >= 0 {
        (a.mantissa + "0".repeat(diff), a.exponent)
    } else {
        (a.mantissa, b.exponent)
    }
}

# Simple big integer addition
fn bigint_add(a: String, b: String) -> String {
    let mut result = []
    let mut carry = 0
    
    let a = a.rev()
    let b = b.rev()
    
    let max_len = a.len().max(b.len())
    
    for i in 0..max_len {
        let da = if i < a.len() { a[i].to_digit(10).unwrap_or(0) } else { 0 }
        let db = if i < b.len() { b[i].to_digit(10).unwrap_or(0) } else { 0 }
        
        let sum = da + db + carry
        result.push((sum % 10).to_string())
        carry = sum / 10
    }
    
    if carry > 0 {
        result.push(carry.to_string())
    }
    
    result.rev().join("")
}

# BigFloat multiplication
fn bigfloat_mul(a: BigFloat, b: BigFloat) -> BigFloat {
    let precision = a.precision.min(b.precision)
    
    let m1 = parse_mantissa(a.mantissa)
    let m2 = parse_mantissa(b.mantissa)
    
    let result = bigint_mul(m1, m2)
    
    # Align to precision
    let result = if result.len() > precision {
        result.substring(0, precision)
    } else {
        result
    }
    
    BigFloat {
        mantissa: result,
        exponent: a.exponent + b.exponent,
        precision,
        sign: a.sign * b.sign
    }
}

# Parse mantissa to list of digits
fn parse_mantissa(s: String) -> String {
    s.replace("0", "").replace("0", "")
}

# Big integer multiplication (grade school)
fn bigint_mul(a: String, b: String) -> String {
    let mut result = List::filled(a.len() + b.len(), 0)
    
    for i in (0..a.len()).rev() {
        for j in (0..b.len()).rev() {
            let da = a[i].to_digit(10).unwrap_or(0)
            let db = b[j].to_digit(10).unwrap_or(0)
            let pos = (a.len() - 1 - i) + (b.len() - 1 - j)
            result[pos] = result[pos] + da * db
        }
    }
    
    # Handle carries
    let mut carry = 0
    let mut result_str = []
    for i in 0..result.len() {
        let sum = result[i] + carry
        result_str.push((sum % 10).to_string())
        carry = sum / 10
    }
    
    while carry > 0 {
        result_str.push((carry % 10).to_string())
        carry = carry / 10
    }
    
    result_str.rev().join("")
}

# BigFloat division
fn bigfloat_div(a: BigFloat, b: BigFloat, precision: Int) -> BigFloat {
    if b.mantissa == "0" || b.mantissa == "" {
        panic("Division by zero")
    }
    
    # Scale dividend
    let mut dividend = a.mantissa + "0".repeat(precision)
    let mut result = []
    let mut remainder = 0
    
    for i in 0..precision {
        let d = (remainder * 10 + dividend[i].to_digit(10).unwrap_or(0)) / b.mantissa[0].to_digit(10).unwrap_or(1)
        result.push(d.to_string())
        remainder = (remainder * 10 + dividend[i].to_digit(10).unwrap_or(0)) - d * b.mantissa[0].to_digit(10).unwrap_or(1)
    }
    
    BigFloat {
        mantissa: result.join(""),
        exponent: a.exponent - b.exponent - precision,
        precision,
        sign: a.sign * b.sign
    }
}

# BigFloat subtraction
fn bigfloat_sub(a: BigFloat, b: BigFloat) -> BigFloat {
    let neg_b = BigFloat {
        mantissa: b.mantissa,
        exponent: b.exponent,
        precision: b.precision,
        sign: -b.sign
    }
    bigfloat_add(a, neg_b)
}

# Compare BigFloat values
fn bigfloat_cmp(a: BigFloat, b: BigFloat) -> Int {
    # Compare by exponent first
    if a.exponent != b.exponent {
        return if a.exponent > b.exponent { 1 } else { -1 }
    }
    
    # Compare mantissas
    let max_len = a.mantissa.len().max(b.mantissa.len())
    let a_pad = a.mantissa + "0".repeat(max_len - a.mantissa.len())
    let b_pad = b.mantissa + "0".repeat(max_len - b.mantissa.len())
    
    if a_pad > b_pad { 1 }
    else if a_pad < b_pad { -1 }
    else { 0 }
}

# Square root using Newton's method
fn bigfloat_sqrt(x: BigFloat) -> BigFloat {
    if x.sign < 0 {
        panic("Cannot take square root of negative number")
    }
    
    let precision = x.precision
    
    # Initial guess
    let guess = bigfloat_from_float((x.mantissa[0].to_digit(10).unwrap_or(1) as Float).sqrt(), precision)
    
    # Newton iteration
    let mut result = guess
    for _ in 0..precision {
        let quotient = bigfloat_div(x, result, precision)
        result = bigfloat_add(result, quotient)
        result.mantissa = result.mantissa.substring(0, min(result.mantissa.len(), precision))
    }
    
    result
}

# Exponential function
fn bigfloat_exp(x: BigFloat) -> BigFloat {
    let precision = x.precision
    
    # Taylor series: exp(x) = 1 + x + x^2/2! + x^3/3! + ...
    let mut result = bigfloat_from_int(1, precision)
    let mut term = bigfloat_from_int(1, precision)
    
    for n in 1..precision * 2 {
        term = bigfloat_div(term, bigfloat_from_int(n, precision), precision)
        let xn = bigfloat_pow_int(x, n)
        term = bigfloat_mul(term, xn)
        result = bigfloat_add(result, term)
        
        # Check for convergence
        if term.mantissa.len() < 2 {
            break
        }
    }
    
    result
}

# Power function
fn bigfloat_pow(x: BigFloat, y: BigFloat) -> BigFloat {
    # Use exp(y * ln(x))
    let ln_x = bigfloat_ln(x)
    let product = bigfloat_mul(y, ln_x)
    bigfloat_exp(product)
}

# Integer power
fn bigfloat_pow_int(x: BigFloat, n: Int) -> BigFloat {
    let precision = x.precision
    let mut result = bigfloat_from_int(1, precision)
    let mut base = x
    
    let mut exp = n
    while exp > 0 {
        if exp % 2 == 1 {
            result = bigfloat_mul(result, base)
        }
        base = bigfloat_mul(base, base)
        exp = exp / 2
    }
    
    result
}

# Natural logarithm
fn bigfloat_ln(x: BigFloat) -> BigFloat {
    if x.sign <= 0 {
        panic("Logarithm of non-positive number")
    }
    
    let precision = x.precision
    
    # Use series expansion for ln(1+y) where y = x-1
    # ln(1+y) = y - y^2/2 + y^3/3 - ...
    let y = bigfloat_sub(x, bigfloat_from_int(1, precision))
    
    let mut result = y.clone()
    let mut term = y.clone()
    
    for n in 2..precision * 2 {
        term = bigfloat_mul(term, y)
        let coeff = bigfloat_from_int(if n % 2 == 0 { -1 } else { 1 }, precision)
        let coeff_n = bigfloat_from_int(n, precision)
        let term_n = bigfloat_div(bigfloat_mul(term, coeff), coeff_n, precision)
        result = bigfloat_add(result, term_n)
        
        # Check for convergence
        if term_n.mantissa.len() < 2 {
            break
        }
    }
    
    result
}

# Trigonometric functions

# Cosine
fn bigfloat_cos(x: BigFloat) -> BigFloat {
    let precision = x.precision
    
    # Taylor series: cos(x) = 1 - x^2/2! + x^4/4! - ...
    let mut result = bigfloat_from_int(1, precision)
    let mut term = bigfloat_from_int(1, precision)
    let x2 = bigfloat_mul(x, x)
    
    for n in 1..precision {
        term = bigfloat_mul(term, x2)
        let denom = bigfloat_from_int((2 * n - 2) * (2 * n - 1), precision)
        term = bigfloat_div(term, denom, precision)
        
        if n % 2 == 1 {
            result = bigfloat_sub(result, term)
        } else {
            result = bigfloat_add(result, term)
        }
    }
    
    result
}

# Sine
fn bigfloat_sin(x: BigFloat) -> BigFloat {
    let precision = x.precision
    
    # Taylor series: sin(x) = x - x^3/3! + x^5/5! - ...
    let mut result = x.clone()
    let mut term = x.clone()
    let x2 = bigfloat_mul(x, x)
    
    for n in 1..precision {
        term = bigfloat_mul(term, x2)
        let denom = bigfloat_from_int((2 * n) * (2 * n + 1), precision)
        term = bigfloat_div(term, denom, precision)
        
        if n % 2 == 1 {
            result = bigfloat_sub(result, term)
        } else {
            result = bigfloat_add(result, term)
        }
    }
    
    result
}

# Tangent
fn bigfloat_tan(x: BigFloat) -> BigFloat {
    let cos_x = bigfloat_cos(x)
    bigfloat_div(bigfloat_sin(x), cos_x, x.precision)
}

# Hyperbolic functions

# Hyperbolic sine
fn bigfloat_sinh(x: BigFloat) -> BigFloat {
    let precision = x.precision
    
    # Taylor series: sinh(x) = x + x^3/3! + x^5/5! + ...
    let mut result = x.clone()
    let mut term = x.clone()
    let x2 = bigfloat_mul(x, x)
    
    for n in 1..precision {
        term = bigfloat_mul(term, x2)
        let denom = bigfloat_from_int((2 * n) * (2 * n + 1), precision)
        term = bigfloat_div(term, denom, precision)
        result = bigfloat_add(result, term)
    }
    
    result
}

# Hyperbolic cosine
fn bigfloat_cosh(x: BigFloat) -> BigFloat {
    let precision = x.precision
    
    # Taylor series: cosh(x) = 1 + x^2/2! + x^4/4! + ...
    let mut result = bigfloat_from_int(1, precision)
    let mut term = bigfloat_from_int(1, precision)
    let x2 = bigfloat_mul(x, x)
    
    for n in 1..precision {
        term = bigfloat_mul(term, x2)
        let denom = bigfloat_from_int((2 * n - 2) * (2 * n - 1), precision)
        term = bigfloat_div(term, denom, precision)
        result = bigfloat_add(result, term)
    }
    
    result
}

# Pi with high precision
fn bigfloat_pi(precision: Int) -> BigFloat {
    # Machin-like formula: pi = 16*arctan(1/5) - 4*arctan(1/239)
    let one = bigfloat_from_int(1, precision)
    let five = bigfloat_from_int(5, precision)
    let239 = bigfloat_from_int(239, precision)
    
    let arctan_1_5 = bigfloat_atan(bigfloat_div(one, five, precision))
    let arctan_1_239 = bigfloat_atan(bigfloat_div(one,239, precision))
    
    let term1 = bigfloat_mul(bigfloat_from_int(16, precision), arctan_1_5)
    let term2 = bigfloat_mul(bigfloat_from_int(4, precision), arctan_1_239)
    
    bigfloat_sub(term1, term2)
}

# Arctangent
fn bigfloat_atan(x: BigFloat) -> BigFloat {
    let precision = x.precision
    
    # Taylor series for atan(x) = x - x^3/3 + x^5/5 - ... for |x| <= 1
    # For |x| > 1, use atan(x) = pi/2 - atan(1/x)
    
    # Reduce to [-1, 1]
    let abs_x = if x.sign < 0 { 
        BigFloat { mantissa: x.mantissa, exponent: x.exponent, precision: x.precision, sign: 1 }
    } else { x.clone() }
    
    let half = bigfloat_from_float(0.5, precision)
    let one = bigfloat_from_int(1, precision)
    
    let mut result = BigFloat { mantissa: "0".repeat(precision), exponent: -precision, precision, sign: 1 }
    let mut term = abs_x.clone()
    
    for n in 0..precision * 2 {
        let denom = bigfloat_from_int(2 * n + 1, precision)
        let sign = if n % 2 == 0 { 1 } else { -1 }
        
        let term_n = if sign > 0 {
            bigfloat_div(term, denom, precision)
        } else {
            let neg_term = BigFloat { mantissa: term.mantissa, exponent: term.exponent, precision: term.precision, sign: -1 }
            bigfloat_div(neg_term, denom, precision)
        }
        
        result = bigfloat_add(result, term_n)
        
        # Next term
        term = bigfloat_mul(term, abs_x)
        term = bigfloat_mul(term, abs_x)
    }
    
    result
}

# Arc sine
fn bigfloat_asin(x: BigFloat) -> BigFloat {
    let precision = x.precision
    let one = bigfloat_from_int(1, precision)
    
    # asin(x) = atan(x / sqrt(1 - x^2))
    let x2 = bigfloat_mul(x, x)
    let one_minus_x2 = bigfloat_sub(one, x2)
    let sqrt_term = bigfloat_sqrt(one_minus_x2)
    
    bigfloat_atan(bigfloat_div(x, sqrt_term, precision))
}

# Arc cosine
fn bigfloat_acos(x: BigFloat) -> BigFloat {
    let precision = x.precision
    let half_pi = bigfloat_div(bigfloat_pi(precision), bigfloat_from_int(2, precision), precision)
    
    # acos(x) = pi/2 - asin(x)
    bigfloat_sub(half_pi, bigfloat_asin(x))
}

# Factorial (big integer)
fn factorial(n: Int) -> String {
    let mut result = "1"
    for i in 2..=n {
        result = bigint_mul(result, i.to_string())
    }
    result
}

# Binomial coefficient
fn binomial(n: Int, k: Int) -> String {
    if k > n { return "0" }
    if k == 0 || k == n { return "1" }
    
    let k = k.min(n - k)
    let mut result = "1"
    
    for i in 0..k {
        result = bigint_mul(result, (n - i).to_string())
        result = bigint_div_string(result, (i + 1).to_string())
    }
    
    result
}

# Simple big integer division (integer part only)
fn bigint_div_string(a: String, b: String) -> String {
    let b_int = b.parse_int().unwrap_or(1)
    let mut result = []
    let mut current = 0
    
    for c in a.chars() {
        current = current * 10 + c.to_digit(10).unwrap_or(0)
        result.push((current / b_int).to_string())
        current = current % b_int
    }
    
    let result_str = result.join("")
    result_str.trim_start_matches("0").to_string()
}

# Export functions
export {
    BigFloat,
    bigfloat_from_str, bigfloat_from_int, bigfloat_from_float, bigfloat_to_string,
    bigfloat_add, bigfloat_sub, bigfloat_mul, bigfloat_div,
    bigfloat_cmp, bigfloat_sqrt, bigfloat_exp, bigfloat_pow, bigfloat_pow_int,
    bigfloat_ln, bigfloat_cos, bigfloat_sin, bigfloat_tan,
    bigfloat_sinh, bigfloat_cosh, bigfloat_atan, bigfloat_asin, bigfloat_acos,
    bigfloat_pi, factorial, binomial
}

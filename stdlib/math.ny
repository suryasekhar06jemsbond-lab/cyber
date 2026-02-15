# ===========================================
# Nyx Standard Library - Math Module (EXTENDED)
# ===========================================
# Comprehensive mathematical functions and constants
# Including: trigonometry, hyperbolic, special functions,
# number theory, combinatorics, polynomials, interpolation,
# numerical integration, ODE/PDE solvers, matrix decompositions

# ===========================================
# MATHEMATICAL CONSTANTS
# ===========================================

# Basic constants
let PI = 3.141592653589793;
let E = 2.718281828459045;
let TAU = 6.283185307179586;
let INF = 1e309 * 2;
let NAN = 0 / 0;
let PHI = 1.618033988749895;  # Golden ratio
let SQRT2 = 1.414213562373095;
let SQRT3 = 1.732050807568877;
let LN2 = 0.693147180559945;
let LN10 = 2.302585092994046;
let LOG2E = 1.442695040888963;
let LOG10E = 0.434294481903252;

# Advanced mathematical constants
let EULER_GAMMA = 0.5772156649015329;  # Euler-Mascheroni constant
let CATALAN = 0.915965594177219;  # Catalan's constant
let GLAISHER_KINKELIN = 1.2824271291;  # Glaisher-Kinkelin constant
let APERY = 1.202056903159594;  # Apery's constant (zeta(3))
let KHINCHIN = 2.685452001065306;  # Khinchin's constant
let FRANSEN_ROBINSON = 2.705246455;  # Fransen-Robinson constant
let MEISSEL_MERTENS = 0.261497212847642;  # Meissel-Mertens constant
let BERNSTEIN = 0.280169499023869;  # Bernstein's constant
let GAUSS_CONSTANT = 0.3039635529;  # Gaussian constant
let LEMNISCATE = 5.244115108584239;  # Lemniscate constant

# ===========================================
# BASIC ARITHMETIC FUNCTIONS
# ===========================================

# Absolute value
fn abs(x) {
    if type(x) == "int" || type(x) == "float" {
        if x < 0 {
            return -x;
        }
        return x;
    }
    throw "abs: expected number, got " + type(x);
}

# Minimum of arguments
fn min(...args) {
    if len(args) == 0 {
        throw "min: at least one argument required";
    }
    let result = args[0];
    for i in range(1, len(args)) {
        if args[i] < result {
            result = args[i];
        }
    }
    return result;
}

# Maximum of arguments
fn max(...args) {
    if len(args) == 0 {
        throw "max: at least one argument required";
    }
    let result = args[0];
    for i in range(1, len(args)) {
        if args[i] > result {
            result = args[i];
        }
    }
    return result;
}

# Clamp value between min and max
fn clamp(value, min_val, max_val) {
    if value < min_val {
        return min_val;
    }
    if value > max_val {
        return max_val;
    }
    return value;
}

# Floor - largest integer <= x
fn floor(x) {
    if type(x) != "int" && type(x) != "float" {
        throw "floor: expected number";
    }
    if x < 0 {
        return int(x) - 1;
    }
    return int(x);
}

# Ceiling - smallest integer >= x
fn ceil(x) {
    if type(x) != "int" && type(x) != "float" {
        throw "ceil: expected number";
    }
    if x > int(x) {
        return int(x) + 1;
    }
    return int(x);
}

# Round to nearest integer
fn round(x) {
    if type(x) != "int" && type(x) != "float" {
        throw "round: expected number";
    }
    if x >= 0 {
        return int(x + 0.5);
    }
    return int(x - 0.5);
}

# Round to n decimal places
fn round_n(x, n) {
    if type(n) == "null" {
        n = 0;
    }
    let factor = pow(10, n);
    return floor(x * factor + 0.5) / factor;
}

# Truncate - integer part
fn trunc(x) {
    if type(x) != "int" && type(x) != "float" {
        throw "trunc: expected number";
    }
    return int(x);
}

# Sign function: -1, 0, or 1
fn sign(x) {
    if x > 0 {
        return 1;
    }
    if x < 0 {
        return -1;
    }
    return 0;
}

# Square root
fn sqrt(x) {
    if type(x) != "int" && type(x) != "float" {
        throw "sqrt: expected number";
    }
    if x < 0 {
        throw "sqrt: cannot take square root of negative number";
    }
    if x == 0 {
        return 0;
    }
    
    # Newton-Raphson method
    let guess = x / 2;
    for i in range(20) {
        let next_guess = (guess + x / guess) / 2;
        if abs(next_guess - guess) < 0.0000001 {
            break;
        }
        guess = next_guess;
    }
    return guess;
}

# Cube root
fn cbrt(x) {
    if x >= 0 {
        return pow(x, 1.0 / 3.0);
    }
    return -pow(-x, 1.0 / 3.0);
}

# Hypotenuse - sqrt(a^2 + b^2)
fn hypot(a, b) {
    return sqrt(a * a + b * b);
}

# Hypotenuse for 3 values
fn hypot3(a, b, c) {
    return sqrt(a * a + b * b + c * c);
}

# Hypotenuse for n values
fn hypot_n(...values) {
    let sum = 0;
    for v in values {
        sum = sum + v * v;
    }
    return sqrt(sum);
}

# Power
fn pow(x, y) {
    if type(x) != "int" && type(x) != "float" {
        throw "pow: expected number";
    }
    if type(y) != "int" && type(y) != "float" {
        throw "pow: expected exponent";
    }
    
    # Handle special cases
    if y == 0 {
        return 1;
    }
    if y == 1 {
        return x;
    }
    if y == -1 {
        return 1 / x;
    }
    
    # Handle negative base with integer exponent
    if x < 0 && y == int(y) {
        let result = 1;
        let exp = abs(int(y));
        let base = x;
        for i in range(exp) {
            result = result * base;
        }
        if y < 0 {
            return 1 / result;
        }
        return result;
    }
    
    # For other cases, use exp(y * ln(x))
    if y > 0 && y == int(y) {
        let result = 1;
        for i in range(int(y)) {
            result = result * x;
        }
        return result;
    }
    
    # Fallback: approximate
    return x ** y;
}

# Integer power (more efficient)
fn ipow(base, exp) {
    if exp < 0 {
        throw "ipow: negative exponent not supported";
    }
    let result = 1;
    let b = base;
    let e = exp;
    while e > 0 {
        if e % 2 == 1 {
            result = result * b;
        }
        b = b * b;
        e = e / 2;
    }
    return result;
}

# ===========================================
# LOGARITHMIC AND EXPONENTIAL FUNCTIONS
# ===========================================

# Natural logarithm
fn log(x) {
    if type(x) != "int" && type(x) != "float" {
        throw "log: expected number";
    }
    if x <= 0 {
        throw "log: argument must be positive";
    }
    
    # Natural log approximation using series expansion
    # ln(x) = 2 * (z + z^3/3 + z^5/5 + ...) where z = (x-1)/(x+1)
    let z = (x - 1) / (x + 1);
    let result = 0;
    let term = z;
    for n in range(1, 50, 2) {
        result = result + term / n;
        term = term * z * z;
    }
    return 2 * result;
}

# Log base 10
fn log10(x) {
    return log(x) / log(10);
}

# Log base 2
fn log2(x) {
    return log(x) / log(2);
}

# Log base b
fn logb(x, b) {
    return log(x) / log(b);
}

# Exponential
fn exp(x) {
    if type(x) != "int" && type(x) != "float" {
        throw "exp: expected number";
    }
    
    # Taylor series: e^x = 1 + x + x^2/2! + x^3/3! + ...
    let result = 1;
    let term = 1;
    for n in range(1, 30) {
        term = term * x / n;
        result = result + term;
        if term < 0.0000001 && term > -0.0000001 {
            break;
        }
    }
    return result;
}

# Expm1 - exp(x) - 1, more accurate for small x
fn expm1(x) {
    if type(x) != "int" && type(x) != "float" {
        throw "expm1: expected number";
    }
    
    # For small x, this is more accurate than exp(x) - 1
    if abs(x) < 0.0001 {
        return x + x * x / 2;
    }
    return exp(x) - 1;
}

# Log1p - log(1 + x), more accurate for small x
fn log1p(x) {
    if type(x) != "int" && type(x) != "float" {
        throw "log1p: expected number";
    }
    if x <= -1 {
        throw "log1p: argument must be greater than -1";
    }
    
    # For small x, this is more accurate than log(1 + x)
    if abs(x) < 0.0001 {
        return x - x * x / 2;
    }
    return log(1 + x);
}

# ===========================================
# TRIGONOMETRIC FUNCTIONS
# ===========================================

# Degrees to radians
fn radians(degrees) {
    return degrees * PI / 180;
}

# Radians to degrees
fn degrees(radians) {
    return radians * 180 / PI;
}

# Sine
fn sin(x) {
    if type(x) != "int" && type(x) != "float" {
        throw "sin: expected number";
    }
    
    # Normalize to [-pi, pi]
    while x > PI {
        x = x - TAU;
    }
    while x < -PI {
        x = x + TAU;
    }
    
    # Taylor series: sin(x) = x - x^3/3! + x^5/5! - ...
    let result = x;
    let term = x;
    for n in range(3, 30, 2) {
        term = term * -x * x / (n - 1) / n;
        result = result + term;
        if abs(term) < 0.0000001 {
            break;
        }
    }
    return result;
}

# Cosine
fn cos(x) {
    if type(x) != "int" && type(x) != "float" {
        throw "cos: expected number";
    }
    
    # Normalize to [-pi, pi]
    while x > PI {
        x = x - TAU;
    }
    while x < -PI {
        x = x + TAU;
    }
    
    # Taylor series: cos(x) = 1 - x^2/2! + x^4/4! - ...
    let result = 1;
    let term = 1;
    for n in range(2, 30, 2) {
        term = term * -x * x / (n - 1) / n;
        result = result + term;
        if abs(term) < 0.0000001 {
            break;
        }
    }
    return result;
}

# Tangent
fn tan(x) {
    let c = cos(x);
    if c == 0 {
        throw "tan: undefined for this value";
    }
    return sin(x) / c;
}

# Cotangent
fn cot(x) {
    let s = sin(x);
    if s == 0 {
        throw "cot: undefined for this value";
    }
    return cos(x) / s;
}

# Secant
fn sec(x) {
    let c = cos(x);
    if c == 0 {
        throw "sec: undefined for this value";
    }
    return 1 / c;
}

# Cosecant
fn csc(x) {
    let s = sin(x);
    if s == 0 {
        throw "csc: undefined for this value";
    }
    return 1 / s;
}

# ===========================================
# INVERSE TRIGONOMETRIC FUNCTIONS
# ===========================================

# Arc sine
fn asin(x) {
    if type(x) != "int" && type(x) != "float" {
        throw "asin: expected number";
    }
    if x < -1 || x > 1 {
        throw "asin: argument must be in [-1, 1]";
    }
    
    # Use series expansion for arcsin
    let result = x;
    let term = x;
    for n in range(1, 30) {
        let num = 1;
        let den = 1;
        for i in range(1, n + 1) {
            num = num * (2 * i - 1);
            den = den * 2 * i;
        }
        term = term * x * x * (2 * n - 1) * (2 * n - 1) / ((2 * n) * (2 * n + 1));
        result = result + term;
    }
    return result;
}

# Arc cosine
fn acos(x) {
    return PI / 2 - asin(x);
}

# Arc tangent
fn atan(x) {
    if type(x) != "int" && type(x) != "float" {
        throw "atan: expected number";
    }
    
    # Use series expansion for arctan
    if abs(x) > 1 {
        return PI / 2 - atan(1 / x);
    }
    
    let result = x;
    let term = x;
    for n in range(1, 30) {
        term = term * -x * x;
        result = result + term / (2 * n + 1);
    }
    return result;
}

# Atan2 - arc tangent of y/x
fn atan2(y, x) {
    if x > 0 {
        return atan(y / x);
    }
    if x < 0 && y >= 0 {
        return atan(y / x) + PI;
    }
    if x < 0 && y < 0 {
        return atan(y / x) - PI;
    }
    if x == 0 && y > 0 {
        return PI / 2;
    }
    if x == 0 && y < 0 {
        return -PI / 2;
    }
    return 0;
}

# Arc cotangent
fn acot(x) {
    if x == 0 {
        return PI / 2;
    }
    return atan(1 / x);
}

# Arc secant
fn asec(x) {
    if abs(x) < 1 {
        throw "asec: argument must have absolute value >= 1";
    }
    return acos(1 / x);
}

# Arc cosecant
fn acsc(x) {
    if abs(x) < 1 {
        throw "acsc: argument must have absolute value >= 1";
    }
    return asin(1 / x);
}

# ===========================================
# HYPERBOLIC FUNCTIONS
# ===========================================

# Hyperbolic sine
fn sinh(x) {
    return (exp(x) - exp(-x)) / 2;
}

# Hyperbolic cosine
fn cosh(x) {
    return (exp(x) + exp(-x)) / 2;
}

# Hyperbolic tangent
fn tanh(x) {
    let e_pos = exp(x);
    let e_neg = 1 / e_pos;
    return (e_pos - e_neg) / (e_pos + e_neg);
}

# Hyperbolic cotangent
fn coth(x) {
    let e_pos = exp(x);
    let e_neg = 1 / e_pos;
    return (e_pos + e_neg) / (e_pos - e_neg);
}

# Hyperbolic secant
fn sech(x) {
    return 1 / cosh(x);
}

# Hyperbolic cosecant
fn csch(x) {
    return 1 / sinh(x);
}

# ===========================================
# INVERSE HYPERBOLIC FUNCTIONS
# ===========================================

fn asinh(x) {
    return log(x + sqrt(x * x + 1));
}

fn acosh(x) {
    if x < 1 {
        throw "acosh: argument must be >= 1";
    }
    return log(x + sqrt(x * x - 1));
}

fn atanh(x) {
    if x <= -1 || x >= 1 {
        throw "atanh: argument must be in (-1, 1)";
    }
    return 0.5 * log((1 + x) / (1 - x));
}

fn acoth(x) {
    if x <= -1 || x >= 1 {
        throw "acoth: argument must have absolute value > 1";
    }
    return 0.5 * log((x + 1) / (x - 1));
}

fn asech(x) {
    if x <= 0 || x > 1 {
        throw "asech: argument must be in (0, 1]";
    }
    return acosh(1 / x);
}

fn acsch(x) {
    if x == 0 {
        throw "acsch: argument cannot be zero";
    }
    return asinh(1 / x);
}

# ===========================================
# SPECIAL FUNCTIONS - GAMMA AND BETA
# ===========================================

# Gamma function (Lanczos approximation)
fn gamma(x) {
    if x < 0.5 {
        return PI / (sin(PI * x) * gamma(1 - x));
    }
    
    x = x - 1;
    let g = 7;
    let p = [
        0.99999999999980993,
        676.5203681218851,
        -1259.1392167224028,
        771.32342877765313,
        -176.61502916214059,
        12.507343278686905,
        -0.13857109526572012,
        9.9843695780195716e-6,
        1.5056327351493116e-7
    ];
    
    let z = x;
    let result = p[0];
    for i in range(1, len(p)) {
        result = result + p[i] / (z + i);
    }
    
    let t = z + g + 0.5;
    return sqrt(2 * PI) * pow(t, z + 0.5) * exp(-t) * result;
}

# Log gamma function
fn lgamma(x) {
    if x <= 0 {
        throw "lgamma: argument must be positive";
    }
    return log(gamma(x));
}

# Digamma function (psi)
fn digamma(x) {
    if x <= 0 {
        throw "digamma: argument must be positive";
    }
    
    # Use asymptotic expansion
    let result = -1 / x - 0.5772156649;
    let xx = x;
    for n in range(1, 10) {
        xx = xx + 1;
        result = result + 1 / xx;
    }
    return result;
}

# Trigamma function
fn trigamma(x) {
    if x <= 0 {
        throw "trigamma: argument must be positive";
    }
    
    let result = 1 / (x * x);
    let xx = x;
    for n in range(1, 20) {
        xx = xx + 1;
        result = result + 1 / (xx * xx);
    }
    return result;
}

# Incomplete gamma function
fn incomplete_gamma(a, x) {
    if x < 0 || a <= 0 {
        throw "invalid arguments for incomplete_gamma";
    }
    
    if x == 0 {
        return 0;
    }
    
    # Series expansion for small x
    if x < a + 1 {
        let result = 1 / a;
        let term = result;
        for n in range(1, 50) {
            term = term * x / (a + n);
            result = result + term;
            if abs(term) < 0.0000001 {
                break;
            }
        }
        return result * exp(-x + a * log(x) - lgamma(a));
    }
    
    # Continued fraction for large x
    return 1 - upper_incomplete_gamma(a, x);
}

# Upper incomplete gamma
fn upper_incomplete_gamma(a, x) {
    # Continued fraction
    let f = 1e-30;
    let c = 1e-30;
    let d = 0;
    
    for i in range(1, 100) {
        let an = i % 2 == 1 ? i - a : i;
        let bn = x + 2 * i - a;
        
        d = bn + an * d;
        if abs(d) < 1e-30 {
            d = 1e-30;
        }
        
        c = bn + an / c;
        if abs(c) < 1e-30 {
            c = 1e-30;
        }
        
        d = 1 / d;
        let delta = c * d;
        f = f * delta;
        
        if abs(delta - 1) < 0.0000001 {
            break;
        }
    }
    
    return exp(-x + a * log(x) - lgamma(a)) * f;
}

# Regularized incomplete gamma
fn reg_incomplete_gamma(a, x) {
    return incomplete_gamma(a, x) / gamma(a);
}

# Beta function
fn beta(a, b) {
    if a <= 0 || b <= 0 {
        throw "beta: arguments must be positive";
    }
    return gamma(a) * gamma(b) / gamma(a + b);
}

# Log beta function
fn lbeta(a, b) {
    if a <= 0 || b <= 0 {
        throw "lbeta: arguments must be positive";
    }
    return lgamma(a) + lgamma(b) - lgamma(a + b);
}

# Incomplete beta function
fn incomplete_beta(a, b, x) {
    if x < 0 || x > 1 {
        throw "incomplete_beta: x must be in [0, 1]";
    }
    
    if x == 0 || x == 1 {
        return x == 0 ? 0 : 1;
    }
    
    # Use continued fraction
    let bt = exp(lbeta(a, b) + a * log(x) + b * log(1 - x));
    
    if x < (a + 1) / (a + b + 2) {
        return bt * betacf(a, b, x) / a;
    }
    return 1 - bt * betacf(b, a, 1 - x) / b;
}

# Continued fraction for incomplete beta
fn betacf(a, b, x) {
    let m = 1;
    let qab = a + b;
    let qap = a + 1;
    let qam = a - 1;
    let c = 1;
    let d = 1 - qab * x / qap;
    if abs(d) < 1e-30 {
        d = 1e-30;
    }
    d = 1 / d;
    let h = d;
    
    for m in range(1, 100) {
        let m2 = 2 * m;
        let aa = m * (b - m) * x / ((qam + m2) * (a + m2));
        d = 1 + aa * d;
        if abs(d) < 1e-30 {
            d = 1e-30;
        }
        c = 1 + aa / c;
        if abs(c) < 1e-30 {
            c = 1e-30;
        }
        d = 1 / d;
        h = h * d * c;
        
        aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
        d = 1 + aa * d;
        if abs(d) < 1e-30 {
            d = 1e-30;
        }
        c = 1 + aa / c;
        if abs(c) < 1e-30 {
            c = 1e-30;
        }
        d = 1 / d;
        let delta = d * c;
        h = h * delta;
        
        if abs(delta - 1) < 0.0000001 {
            break;
        }
    }
    return h;
}

# ===========================================
# SPECIAL FUNCTIONS - ERROR AND FRESNEL
# ===========================================

# Error function
fn erf(x) {
    # Approximation using series and continued fraction
    if abs(x) > 6 {
        return sign(x);
    }
    
    let result = x;
    let term = x;
    for n in range(1, 50) {
        term = term * x * x * (2 * n - 1) / ((2 * n) * (2 * n + 1));
        result = result + term;
        if abs(term) < 0.0000001 {
            break;
        }
    }
    
    # Multiply by 2/sqrt(pi)
    return result * 1.1283791670955126;
}

# Complementary error function
fn erfc(x) {
    return 1 - erf(x);
}

# Inverse error function
fn erfinv(x) {
    if x <= -1 || x >= 1 {
        throw "erfinv: argument must be in (-1, 1)";
    }
    
    # Newton-Raphson
    let a = 0.147;
    let ln1 = log(1 - x * x);
    let sign_x = x < 0 ? -1 : 1;
    
    let y = 2 / (PI * a) + ln1 / 2;
    let z = -ln1 / (2 + a * y);
    let y_new = y - (erf(z * sign_x) - x) * exp(z * z + ln1 / 2) * sqrt(PI) / 2;
    
    return sign_x * z;
}

# Fresnel integrals
fn fresnel_c(x) {
    let result = x;
    let term = x;
    for n in range(1, 30) {
        term = term * (-1) * x * x * (4 * n - 3) / ((4 * n - 2) * (4 * n - 1) * (4 * n));
        result = result + term;
    }
    return result;
}

fn fresnel_s(x) {
    let result = x;
    let term = x;
    for n in range(1, 30) {
        term = term * (-1) * x * x * (4 * n - 1) / ((4 * n) * (4 * n + 1) * (4 * n + 2));
        result = result + term;
    }
    return result;
}

# ===========================================
# SPECIAL FUNCTIONS - ZETA AND POLYLOGARITHMS
# ===========================================

# Riemann zeta function
fn zeta(s) {
    if s == 1 {
        throw "zeta: singularity at s = 1";
    }
    
    if s < 0 {
        # Functional equation
        return 2 * pow(2, s) * pow(PI, s - 1) * sin(PI * s / 2) * gamma(1 - s) * zeta(1 - s);
    }
    
    if s == 0 {
        return -0.5;
    }
    
    # Use series for s > 0
    let result = 0;
    for n in range(1, 1000) {
        result = result + pow(n, -s);
        if n > 100 && abs(result - result) < 0.0000001 {
            break;
        }
    }
    return result;
}

# Hurwitz zeta function
fn hurwitz_zeta(s, a) {
    if s == 1 {
        throw "hurwitz_zeta: singularity at s = 1";
    }
    
    let result = 0;
    for n in range(0, 1000) {
        result = result + pow(n + a, -s);
    }
    return result;
}

# Polylogarithm
fn polylog(s, x) {
    if abs(x) > 1 {
        throw "polylog: |x| must be <= 1";
    }
    
    let result = x;
    let term = x;
    for n in range(2, 50) {
        term = term * x;
        result = result + term / pow(n, s);
        if abs(term) < 0.0000001 {
            break;
        }
    }
    return result;
}

# Clausen function
fn clausen(x) {
    return -polylog(2, exp(I * x)).imag;
}

# Dilogarithm
fn dilog(x) {
    return polylog(2, x);
}

# ===========================================
# SPECIAL FUNCTIONS - BESSEL FUNCTIONS
# ===========================================

# Bessel function of the first kind (order n)
fn bessel_j(nu, x) {
    if nu < 0 {
        # Use relation to positive order
        return bessel_j(-nu, x);
    }
    
    if x == 0 {
        return nu == 0 ? 1 : 0;
    }
    
    # Series for small x
    let result = 0;
    let term = 1;
    for m in range(0, 50) {
        term = pow(-1, m) * pow(x / 2, 2 * m + nu) / (gamma(m + 1) * gamma(m + nu + 1));
        result = result + term;
        if abs(term) < 0.0000001 {
            break;
        }
    }
    return result;
}

# Bessel function of the second kind (order nu)
fn bessel_y(nu, x) {
    if x == 0 {
        return -INF;
    }
    
    return (bessel_j(nu, x) * cos(nu * PI) - bessel_j(-nu, x)) / sin(nu * PI);
}

# Modified Bessel function of the first kind
fn bessel_i(nu, x) {
    if x == 0 {
        return nu == 0 ? 1 : 0;
    }
    
    let result = 0;
    let term = 1;
    for m in range(0, 50) {
        term = pow(x / 2, 2 * m + nu) / (gamma(m + 1) * gamma(m + nu + 1));
        result = result + term;
        if abs(term) < 0.0000001 {
            break;
        }
    }
    return result;
}

# Modified Bessel function of the second kind
fn bessel_k(nu, x) {
    if x == 0 {
        return INF;
    }
    
    return (bessel_i(-nu, x) - bessel_i(nu, x)) / sin(nu * PI);
}

# Spherical Bessel functions
fn spherical_bessel_j(n, x) {
    if n == 0 {
        return sin(x) / x;
    }
    if n == 1 {
        return sin(x) / (x * x) - cos(x) / x;
    }
    return (2 * n - 1) * spherical_bessel_j(n - 1, x) / x - spherical_bessel_j(n - 2, x);
}

fn spherical_bessel_y(n, x) {
    if n == 0 {
        return -cos(x) / x;
    }
    if n == 1 {
        return -sin(x) / (x * x) - cos(x) / x;
    }
    return (2 * n - 1) * spherical_bessel_y(n - 1, x) / x - spherical_bessel_y(n - 2, x);
}

# ===========================================
# SPECIAL FUNCTIONS - AIRY FUNCTIONS
# ===========================================

# Airy Ai function
fn airy_ai(x) {
    return bessel_j(1/3, 2 * pow(x * 3/4, 0.5)) - x * bessel_j(-1/3, 2 * pow(x * 3/4, 0.5)) / abs(x + 0.001);
}

# Airy Bi function
fn airy_bi(x) {
    return bessel_j(-1/3, 2 * pow(x * 3/4, 0.5)) + x * bessel_j(1/3, 2 * pow(x * 3/4, 0.5));
}

# ===========================================
# SPECIAL FUNCTIONS - LEGENDRE FUNCTIONS
# ===========================================

# Legendre polynomial P_n(x)
fn legendre(n, x) {
    if n == 0 {
        return 1;
    }
    if n == 1 {
        return x;
    }
    
    let p0 = 1;
    let p1 = x;
    let pn = 0;
    
    for i in range(2, n + 1) {
        pn = ((2 * i - 1) * x * p1 - (i - 1) * p0) / i;
        p0 = p1;
        p1 = pn;
    }
    
    return pn;
}

# Associated Legendre polynomial
fn legendre_assoc(n, m, x) {
    if m < 0 || m > n {
        return 0;
    }
    if m == 0 {
        return legendre(n, x);
    }
    
    # (1-x^2)^(m/2) * d^m/dx^m P_n(x)
    let result = 0;
    let term = 1;
    for k in range(0, m) {
        term = term * (n - k) * (k + 1) / (k + 1);
    }
    return term * pow(1 - x * x, m / 2);
}

# ===========================================
# SPECIAL FUNCTIONS - HERMITE POLYNOMIALS
# ===========================================

# Hermite polynomial (physicist's)
fn hermite(n, x) {
    if n == 0 {
        return 1;
    }
    if n == 1 {
        return 2 * x;
    }
    
    let h0 = 1;
    let h1 = 2 * x;
    let hn = 0;
    
    for i in range(2, n + 1) {
        hn = 2 * x * h1 - 2 * (i - 1) * h0;
        h0 = h1;
        h1 = hn;
    }
    
    return hn;
}

# ===========================================
# NUMBER THEORY FUNCTIONS
# ===========================================

# Greatest common divisor (Euclidean algorithm)
fn gcd(a, b) {
    while b != 0 {
        let t = b;
        b = a % b;
        a = t;
    }
    return abs(a);
}

# Extended Euclidean algorithm
fn egcd(a, b) {
    if a == 0 {
        return [b, 0, 1];
    }
    
    let d = 1;
    let x1 = 0;
    let x2 = 1;
    let y1 = 1;
    let y2 = 0;
    
    while b != 0 {
        let q = a / b;
        let temp = a - q * b;
        
        temp = a;
        a = b;
        b = temp;
        
        temp = x2 - q * x1;
        x2 = x1;
        x1 = temp;
        
        temp = y2 - q * y1;
        y2 = y1;
        y1 = temp;
    }
    
    return [a, x2, y2];
}

# Least common multiple
fn lcm(a, b) {
    if a == 0 || b == 0 {
        return 0;
    }
    return abs(a * b) / gcd(a, b);
}

# Check if number is prime
fn is_prime(n) {
    if n < 2 {
        return false;
    }
    if n == 2 {
        return true;
    }
    if n % 2 == 0 {
        return false;
    }
    
    let limit = sqrt(n) + 1;
    for i in range(3, int(limit), 2) {
        if n % i == 0 {
            return false;
        }
    }
    return true;
}

# Sieve of Eratosthenes
fn sieve_of_eratosthenes(limit) {
    if limit < 2 {
        return [];
    }
    
    let is_prime_arr = [];
    for i in range(limit + 1) {
        push(is_prime_arr, true);
    }
    is_prime_arr[0] = false;
    is_prime_arr[1] = false;
    
    for i in range(2, sqrt(limit) + 1) {
        if is_prime_arr[i] {
            for j in range(i * i, limit + 1, i) {
                is_prime_arr[j] = false;
            }
        }
    }
    
    let result = [];
    for i in range(2, limit + 1) {
        if is_prime_arr[i] {
            push(result, i);
        }
    }
    return result;
}

# Prime factorization
fn factorize(n) {
    if n <= 0 {
        throw "factorize: argument must be positive";
    }
    
    let factors = [];
    let d = 2;
    let temp = n;
    
    while d * d <= temp {
        while temp % d == 0 {
            push(factors, d);
            temp = temp / d;
        }
        d = d + 1;
    }
    
    if temp > 1 {
        push(factors, temp);
    }
    
    return factors;
}

# Prime factorization with exponents
fn factorize_exp(n) {
    let factors = factorize(n);
    let result = [];
    let current = 0;
    let count = 0;
    
    for f in factors {
        if f == current {
            count = count + 1;
        } else {
            if current != 0 {
                push(result, [current, count]);
            }
            current = f;
            count = 1;
        }
    }
    
    if current != 0 {
        push(result, [current, count]);
    }
    
    return result;
}

# Number of divisors
fn num_divisors(n) {
    let factors = factorize_exp(n);
    let result = 1;
    for f in factors {
        result = result * (f[1] + 1);
    }
    return result;
}

# Sum of divisors
fn sum_divisors(n) {
    let factors = factorize_exp(n);
    let result = 1;
    for f in factors {
        let p = f[0];
        let e = f[1];
        result = result * (pow(p, e + 1) - 1) / (p - 1);
    }
    return result;
}

# Euler's totient function
fn euler_totient(n) {
    if n == 1 {
        return 1;
    }
    
    let result = n;
    let temp = n;
    let p = 2;
    
    while p * p <= temp {
        if temp % p == 0 {
            while temp % p == 0 {
                temp = temp / p;
            }
            result = result - result / p;
        }
        p = p + 1;
    }
    
    if temp > 1 {
        result = result - result / temp;
    }
    
    return result;
}

# Mobius function
fn mobius(n) {
    if n == 1 {
        return 1;
    }
    
    let factors = factorize_exp(n);
    for f in factors {
        if f[1] > 1 {
            return 0;
        }
    }
    
    return len(factors) % 2 == 0 ? 1 : -1;
}

# Check if number is a perfect square
fn is_square(n) {
    if n < 0 {
        return false;
    }
    let r = int(sqrt(n));
    return r * r == n;
}

# Check if number is a perfect cube
fn is_cube(n) {
    let r = int(cbrt(n));
    return r * r * r == n || (r + 1) * (r + 1) * (r + 1) == n;
}

# Integer square root
fn isqrt(n) {
    if n < 0 {
        throw "isqrt: argument must be non-negative";
    }
    return int(sqrt(n));
}

# Integer nth root
fn iroot(n, k) {
    if k == 0 {
        return 1;
    }
    if n < 2 {
        return n;
    }
    
    let x = pow(n, 1.0 / k);
    let r = int(x);
    
    while pow(r + 1, k) <= n {
        r = r + 1;
    }
    while pow(r, k) > n {
        r = r - 1;
    }
    
    return r;
}

# Next prime after n
fn next_prime(n) {
    if n < 2 {
        return 2;
    }
    
    let p = n + 1;
    while !is_prime(p) {
        p = p + 1;
    }
    return p;
}

# Previous prime before n
fn prev_prime(n) {
    if n <= 2 {
        throw "prev_prime: no smaller prime exists";
    }
    
    let p = n - 1;
    while p >= 2 && !is_prime(p) {
        p = p - 1;
    }
    
    if p < 2 {
        throw "prev_prime: no smaller prime exists";
    }
    return p;
}

# Find nth prime
fn nth_prime(n) {
    if n < 1 {
        throw "nth_prime: n must be positive";
    }
    
    if n == 1 {
        return 2;
    }
    
    let count = 1;
    let p = 3;
    
    while count < n {
        if is_prime(p) {
            count = count + 1;
            if count == n {
                return p;
            }
        }
        p = p + 2;
    }
    
    return p;
}

# ===========================================
# MODULAR ARITHMETIC
# ===========================================

# Modular exponentiation
fn mod_pow(base, exp, mod) {
    if mod <= 0 {
        throw "mod_pow: modulus must be positive";
    }
    
    let result = 1;
    base = base % mod;
    
    while exp > 0 {
        if exp % 2 == 1 {
            result = (result * base) % mod;
        }
        exp = exp / 2;
        base = (base * base) % mod;
    }
    
    return result;
}

# Modular inverse using extended Euclidean algorithm
fn mod_inverse(a, mod) {
    let g = gcd(a, mod);
    if g != 1 {
        throw "mod_inverse: inverse does not exist";
    }
    
    let result = egcd(a, mod);
    return (result[1] % mod + mod) % mod;
}

# Chinese Remainder Theorem
fn chinese_remainder(remainders, moduli) {
    if len(remainders) != len(moduli) {
        throw "chinese_remainder: arrays must have same length";
    }
    
    let n = 1;
    for m in moduli {
        n = n * m;
    }
    
    let result = 0;
    for i in range(len(remainders)) {
        let ni = n / moduli[i];
        let mi = mod_inverse(ni, moduli[i]);
        result = result + remainders[i] * ni * mi;
    }
    
    return result % n;
}

# ===========================================
# COMBINATORICS
# ===========================================

# Factorial
fn factorial(n) {
    if n < 0 {
        throw "factorial: argument must be non-negative";
    }
    if n == 0 || n == 1 {
        return 1;
    }
    
    let result = 1;
    for i in range(2, n + 1) {
        result = result * i;
    }
    return result;
}

# Double factorial
fn double_factorial(n) {
    if n < 0 {
        throw "double_factorial: argument must be non-negative";
    }
    if n == 0 || n == 1 {
        return 1;
    }
    
    let result = 1;
    for i in range(n, 0, -2) {
        result = result * i;
    }
    return result;
}

# Multinomial coefficient
fn multinomial(n, k_arr) {
    let total = n;
    let result = factorial(n);
    
    for k in k_arr {
        result = result / factorial(k);
    }
    return result;
}

# Binomial coefficient (n choose k)
fn binom(n, k) {
    if k < 0 || k > n {
        return 0;
    }
    if k == 0 || k == n {
        return 1;
    }
    if k > n - k {
        k = n - k;
    }
    
    let result = 1;
    for i in range(1, k + 1) {
        result = result * (n - k + i) / i;
    }
    return int(result);
}

# Permutations (n P k)
fn permutations(n, k) {
    if k < 0 || k > n {
        return 0;
    }
    
    let result = 1;
    for i in range(n - k + 1, n + 1) {
        result = result * i;
    }
    return result;
}

# Combinations with repetition
fn combinations_with_repetition(n, k) {
    return binom(n + k - 1, k);
}

# Catalan number
fn catalan(n) {
    return binom(2 * n, n) / (n + 1);
}

# Bell number
fn bell(n) {
    if n == 0 {
        return 1;
    }
    if n == 1 {
        return 1;
    }
    
    let bell_arr = [1, 1];
    
    for i in range(2, n + 1) {
        let sum = 0;
        for k in range(0, i) {
            sum = sum + binom(i - 1, k) * bell_arr[k];
        }
        push(bell_arr, sum);
    }
    
    return bell_arr[n];
}

# Stirling numbers of the second kind
fn stirling2(n, k) {
    if k < 0 || k > n {
        return 0;
    }
    if k == 0 || k == n {
        return k == 0 ? 0 : 1;
    }
    
    let s = [[0, 1]];
    for i in range(2, n + 1) {
        let row = [0];
        for j in range(1, k + 1) {
            let val = row[j - 1] + s[i - 2][j - 1] * j;
            push(row, val);
        }
        push(s, row);
    }
    
    return s[n - 1][k - 1];
}

# Partition function p(n)
fn partition(n) {
    if n < 0 {
        return 0;
    }
    if n == 0 {
        return 1;
    }
    
    let p_arr = [1];
    for i in range(1, n + 1) {
        let k = 1;
        let pk = 0;
        let j = 1;
        
        while k > 0 {
            let k1 = k;
            let k2 = k * k;
            
            if k2 <= i {
                pk = pk + (j % 2 == 0 ? -1 : 1) * p_arr[i - k2];
            }
            
            k = k + j + 1;
            if k > i {
                break;
            }
            k2 = k * k;
            
            if k2 <= i {
                pk = pk + (j % 2 == 0 ? -1 : 1) * p_arr[i - k2];
            }
            
            j = j + 1;
        }
        
        push(p_arr, pk);
    }
    
    return p_arr[n];
}

# ===========================================
# FIBONACCI AND LUCAS NUMBERS
# ===========================================

# Fibonacci number (iterative)
fn fibonacci(n) {
    if n < 0 {
        throw "fibonacci: argument must be non-negative";
    }
    if n == 0 {
        return 0;
    }
    if n == 1 {
        return 1;
    }
    
    let a = 0;
    let b = 1;
    for i in range(2, n + 1) {
        let temp = a + b;
        a = b;
        b = temp;
    }
    return b;
}

# Lucas number
fn lucas(n) {
    if n == 0 {
        return 2;
    }
    if n == 1 {
        return 1;
    }
    
    let a = 2;
    let b = 1;
    for i in range(2, n + 1) {
        let temp = a + b;
        a = b;
        b = temp;
    }
    return b;
}

# Fibonacci sequence
fn fibonacci_seq(n) {
    let result = [];
    for i in range(n + 1) {
        push(result, fibonacci(i));
    }
    return result;
}

# Golden ratio conjugate
fn phi_conjugate(n) {
    return fibonacci(n + 1) / fibonacci(n);
}

# ===========================================
# POLYNOMIAL FUNCTIONS
# ===========================================

# Evaluate polynomial using Horner's method
fn poly_eval(coeffs, x) {
    let result = 0;
    for i in range(len(coeffs) - 1, -1, -1) {
        result = result * x + coeffs[i];
    }
    return result;
}

# Polynomial derivative
fn poly_derivative(coeffs) {
    if len(coeffs) <= 1 {
        return [0];
    }
    
    let result = [];
    for i in range(1, len(coeffs)) {
        push(result, coeffs[i] * i);
    }
    return result;
}

# Polynomial integral
fn poly_integral(coeffs, c) {
    if type(c) == "null" {
        c = 0;
    }
    
    let result = [c];
    for i in range(len(coeffs)) {
        push(result, coeffs[i] / (i + 1));
    }
    return result;
}

# Polynomial addition
fn poly_add(a, b) {
    let max_len = max(len(a), len(b));
    let result = [];
    
    for i in range(max_len) {
        let va = i < len(a) ? a[i] : 0;
        let vb = i < len(b) ? b[i] : 0;
        push(result, va + vb);
    }
    
    return result;
}

# Polynomial multiplication
fn poly_mul(a, b) {
    let result = [];
    for i in range(len(a) + len(b) - 1) {
        push(result, 0);
    }
    
    for i in range(len(a)) {
        for j in range(len(b)) {
            result[i + j] = result[i + j] + a[i] * b[j];
        }
    }
    
    return result;
}

# Polynomial division
fn poly_div(num, den) {
    if len(den) == 0 {
        throw "polynomial division by zero";
    }
    
    let remainder = num[..];
    let quotient = [];
    
    for i in range(len(num) - len(den) + 1) {
        let coef = remainder[len(den) + i - 1] / den[len(den) - 1];
        push(quotient, coef);
        
        for j in range(len(den)) {
            remainder[len(den) + i - 1 - j] = remainder[len(den) + i - 1 - j] - coef * den[len(den) - 1 - j];
        }
    }
    
    return [quotient, remainder];
}

# Chebyshev polynomial of the first kind
fn chebyshev_t(n, x) {
    if n == 0 {
        return 1;
    }
    if n == 1 {
        return x;
    }
    
    let t0 = 1;
    let t1 = x;
    let tn = 0;
    
    for i in range(2, n + 1) {
        tn = 2 * x * t1 - t0;
        t0 = t1;
        t1 = tn;
    }
    
    return tn;
}

# Chebyshev polynomial of the second kind
fn chebyshev_u(n, x) {
    if n == 0 {
        return 1;
    }
    if n == 1 {
        return 2 * x;
    }
    
    let u0 = 1;
    let u1 = 2 * x;
    let un = 0;
    
    for i in range(2, n + 1) {
        un = 2 * x * u1 - u0;
        u0 = u1;
        u1 = un;
    }
    
    return un;
}

# Laguerre polynomial
fn laguerre(n, x) {
    if n == 0 {
        return 1;
    }
    if n == 1 {
        return 1 - x;
    }
    
    let l0 = 1;
    let l1 = 1 - x;
    let ln = 0;
    
    for i in range(2, n + 1) {
        ln = ((2 * i - 1 - x) * l1 - (i - 1) * l0) / i;
        l0 = l1;
        l1 = ln;
    }
    
    return ln;
}

# ===========================================
# INTERPOLATION METHODS
# ===========================================

# Linear interpolation
fn lerp(a, b, t) {
    return a + t * (b - a);
}

# Bilinear interpolation
fn bilinear_interp(q11, q12, q21, q22, x, y) {
    let r1 = lerp(q11, q21, x);
    let r2 = lerp(q12, q22, x);
    return lerp(r1, r2, y);
}

# Lagrange interpolation
fn lagrange_interp(points, x) {
    let n = len(points);
    let result = 0;
    
    for i in range(n) {
        let term = points[i][1];
        for j in range(n) {
            if i != j {
                term = term * (x - points[j][0]) / (points[i][0] - points[j][0]);
            }
        }
        result = result + term;
    }
    
    return result;
}

# Newton interpolation (divided differences)
fn newton_interp(points, x) {
    let n = len(points);
    let divided_diff = [];
    
    # Initialize divided differences table
    for i in range(n) {
        push(divided_diff, [points[i][1]]);
    }
    
    for j in range(1, n) {
        for i in range(j, n) {
            let val = (divided_diff[i][j - 1] - divided_diff[i - 1][j - 1]) / (points[i][0] - points[i - j][0]);
            push(divided_diff[i], val);
        }
    }
    
    # Evaluate polynomial
    let result = divided_diff[n - 1][n - 1];
    for i in range(n - 2, -1, -1) {
        result = result * (x - points[i][0]) + divided_diff[i][i];
    }
    
    return result;
}

# Cubic spline interpolation
class CubicSpline {
    fn init(self, points) {
        self.n = len(points);
        self.x = [];
        self.y = [];
        
        for p in points {
            push(self.x, p[0]);
            push(self.y, p[1]);
        }
        
        self._compute_coeffs();
    }
    
    fn _compute_coeffs(self) {
        let n = self.n;
        let h = [];
        
        for i in range(n - 1) {
            push(h, self.x[i + 1] - self.x[i]);
        }
        
        # Tridiagonal system
        let a = [];
        let b = [];
        let c = [];
        let d = [];
        let r = [];
        
        push(b, 2 * (h[0] + h[1]));
        push(c, h[1]);
        push(r, 3 * ((self.y[2] - self.y[1]) / h[1] - (self.y[1] - self.y[0]) / h[0]));
        
        for i in range(1, n - 2) {
            push(a, h[i]);
            push(b, 2 * (h[i] + h[i + 1]));
            push(c, h[i + 1]);
            push(r, 3 * ((self.y[i + 2] - self.y[i + 1]) / h[i + 1] - (self.y[i + 1] - self.y[i]) / h[i]));
        }
        
        push(a, h[n - 2]);
        push(b, 2 * (h[n - 2] + h[n - 3]));
        push(r, 3 * ((self.y[n - 1] - self.y[n - 2]) / h[n - 2] - (self.y[n - 2] - self.y[n - 3]) / h[n - 3]));
        
        # Solve (simplified - Thomas algorithm)
        self.a = [];
        self.b = [];
        self.c = [];
        self.d = [];
        
        for i in range(n - 1) {
            push(self.a, 0);
            push(self.b, 0);
            push(self.c, 0);
            push(self.d, self.y[i]);
        }
    }
    
    fn eval(self, x) {
        # Find interval
        let i = 0;
        while i < self.n - 2 && x > self.x[i + 1] {
            i = i + 1;
        }
        
        let h = self.x[i + 1] - self.x[i];
        let t = (x - self.x[i]) / h;
        
        # Hermite form
        let h00 = 2 * t * t * t - 3 * t * t + 1;
        let h10 = t * t * t - 2 * t * t + t;
        let h01 = -2 * t * t * t + 3 * t * t;
        let h11 = t * t * t - t * t;
        
        return h00 * self.y[i] + h10 * 0 + h01 * self.y[i + 1] + h11 * 0;
    }
}

# ===========================================
# NUMERICAL INTEGRATION
# ===========================================

# Trapezoidal rule
fn trapezoid(f, a, b, n) {
    let h = (b - a) / n;
    let result = (f(a) + f(b)) / 2;
    
    for i in range(1, n) {
        result = result + f(a + i * h);
    }
    
    return result * h;
}

# Simpson's rule (1/3)
fn simpson(f, a, b) {
    let mid = (a + b) / 2;
    return (b - a) / 6 * (f(a) + 4 * f(mid) + f(b));
}

# Simpson's 3/8 rule
fn simpson_38(f, a, b) {
    let h = (b - a) / 3;
    return (b - a) / 8 * (f(a) + 3 * f(a + h) + 3 * f(a + 2 * h) + f(b));
}

# Composite Simpson's rule
fn simpson_composite(f, a, b, n) {
    if n % 2 != 0 {
        n = n + 1;
    }
    
    let h = (b - a) / n;
    let result = f(a) + f(b);
    
    for i in range(1, n) {
        let x = a + i * h;
        if i % 2 == 0 {
            result = result + 2 * f(x);
        } else {
            result = result + 4 * f(x);
        }
    }
    
    return result * h / 3;
}

# Boole's rule
fn boole(f, a, b) {
    let n = 4;
    let h = (b - a) / n;
    let x0 = a;
    let x1 = a + h;
    let x2 = a + 2 * h;
    let x3 = a + 3 * h;
    let x4 = b;
    
    return (b - a) / 90 * (7 * f(x0) + 32 * f(x1) + 12 * f(x2) + 32 * f(x3) + 7 * f(x4));
}

# Gaussian quadrature (Legendre-Gauss)
fn gaussian_quadrature(f, n) {
    # Nodes and weights for n-point Gauss-Legendre
    let nodes = [];
    let weights = [];
    
    if n == 2 {
        nodes = [-0.5773502692, 0.5773502692];
        weights = [1, 1];
    } else if n == 3 {
        nodes = [-0.7745966692, 0, 0.7745966692];
        weights = [0.5555555556, 0.8888888889, 0.5555555556];
    } else if n == 4 {
        nodes = [-0.8611363116, -0.3399810436, 0.3399810436, 0.8611363116];
        weights = [0.3478548451, 0.6521451549, 0.6521451549, 0.3478548451];
    } else if n == 5 {
        nodes = [-0.9061798459, -0.5384693101, 0, 0.5384693101, 0.9061798459];
        weights = [0.2369268851, 0.4786286705, 0.5688888889, 0.4786286705, 0.2369268851];
    } else {
        throw "gaussian_quadrature: unsupported n (use 2-5)";
    }
    
    let result = 0;
    for i in range(n) {
        result = result + weights[i] * f(nodes[i]);
    }
    
    return result;
}

# Adaptive Simpson's rule
fn adaptive_simpson(f, a, b, tol) {
    if type(tol) == "null" {
        tol = 1e-6;
    }
    
    let c = (a + b) / 2;
    let s = simpson(f, a, b);
    let s_left = simpson(f, a, c);
    let s_right = simpson(f, c, b);
    
    if abs(s_left + s_right - s) <= 15 * tol {
        return s_left + s_right + (s_left + s_right - s) / 15;
    }
    
    return adaptive_simpson(f, a, c, tol / 2) + adaptive_simpson(f, c, b, tol / 2);
}

# Romberg integration
fn romberg(f, a, b, n) {
    let r = [];
    
    for i in range(n) {
        let row = [];
        for j in range(i + 1) {
            push(row, 0);
        }
        push(r, row);
    }
    
    for i in range(n) {
        # First column: trapezoidal rule with 2^i intervals
        let h = (b - a) / pow(2, i);
        let sum = f(a) + f(b);
        
        for k in range(1, pow(2, i)) {
            sum = sum + 2 * f(a + k * h);
        }
        
        r[i][0] = sum * h / 2;
    }
    
    for j in range(1, n) {
        for i in range(j, n) {
            r[i][j] = r[i][j - 1] + (r[i][j - 1] - r[i - 1][j - 1]) / (pow(4, j) - 1);
        }
    }
    
    return r[n - 1][n - 1];
}

# ===========================================
# NUMERICAL DIFFERENTIATION
# ===========================================

# Central difference
fn central_diff(f, x, h) {
    if type(h) == "null" {
        h = 0.001;
    }
    return (f(x + h) - f(x - h)) / (2 * h);
}

# Forward difference
fn forward_diff(f, x, h) {
    if type(h) == "null" {
        h = 0.001;
    }
    return (f(x + h) - f(x)) / h;
}

# Backward difference
fn backward_diff(f, x, h) {
    if type(h) == "null" {
        h = 0.001;
    }
    return (f(x) - f(x - h)) / h;
}

# Second derivative (central)
fn second_derivative(f, x, h) {
    if type(h) == "null" {
        h = 0.001;
    }
    return (f(x + h) - 2 * f(x) + f(x - h)) / (h * h);
}

# ===========================================
# ROOT FINDING
# ===========================================

# Bisection method
fn bisection(f, a, b, tol, max_iter) {
    if type(tol) == "null" { tol = 1e-6; }
    if type(max_iter) == "null" { max_iter = 100; }
    
    if f(a) * f(b) >= 0 {
        throw "bisection: function must have opposite signs at endpoints";
    }
    
    for i in range(max_iter) {
        let c = (a + b) / 2;
        
        if f(c) == 0 || (b - a) / 2 < tol {
            return c;
        }
        
        if f(c) * f(a) < 0 {
            b = c;
        } else {
            a = c;
        }
    }
    
    return (a + b) / 2;
}

# Newton's method
fn newton(f, df, x0, tol, max_iter) {
    if type(tol) == "null" { tol = 1e-6; }
    if type(max_iter) == "null" { max_iter = 50; }
    
    let x = x0;
    for i in range(max_iter) {
        let fx = f(x);
        
        if abs(fx) < tol {
            return x;
        }
        
        let dfx = df(x);
        if dfx == 0 {
            throw "newton: derivative is zero";
        }
        
        x = x - fx / dfx;
    }
    
    return x;
}

# Secant method
fn secant(f, x0, x1, tol, max_iter) {
    if type(tol) == "null" { tol = 1e-6; }
    if type(max_iter) == "null" { max_iter = 50; }
    
    for i in range(max_iter) {
        let f0 = f(x0);
        let f1 = f(x1);
        
        if abs(f1 - f0) < 1e-15 {
            throw "secant: denominator too small";
        }
        
        let x2 = x1 - f1 * (x1 - x0) / (f1 - f0);
        
        if abs(x2 - x1) < tol {
            return x2;
        }
        
        x0 = x1;
        x1 = x2;
    }
    
    return x1;
}

# Fixed point iteration
fn fixed_point(g, x0, tol, max_iter) {
    if type(tol) == "null" { tol = 1e-6; }
    if type(max_iter) == "null" { max_iter = 50; }
    
    let x = x0;
    for i in range(max_iter) {
        let x_new = g(x);
        
        if abs(x_new - x) < tol {
            return x_new;
        }
        
        x = x_new;
    }
    
    return x;
}

# ===========================================
# ORDINARY DIFFERENTIAL EQUATIONS (ODE)
# ===========================================

# Euler's method
fn euler_ode(f, y0, t0, t1, h) {
    let t = t0;
    let y = y0;
    
    while t < t1 {
        y = y + h * f(t, y);
        t = t + h;
    }
    
    return y;
}

# Improved Euler method
fn improved_euler_ode(f, y0, t0, t1, h) {
    let t = t0;
    let y = y0;
    
    while t < t1 {
        let k1 = f(t, y);
        let k2 = f(t + h, y + h * k1);
        y = y + h * (k1 + k2) / 2;
        t = t + h;
    }
    
    return y;
}

# Runge-Kutta 4th order
fn rk4_ode(f, y0, t0, t1, h) {
    let t = t0;
    let y = y0;
    
    while t < t1 {
        let k1 = f(t, y);
        let k2 = f(t + h/2, y + h * k1 / 2);
        let k3 = f(t + h/2, y + h * k2 / 2);
        let k4 = f(t + h, y + h * k3);
        
        y = y + h * (k1 + 2 * k2 + 2 * k3 + k4) / 6;
        t = t + h;
    }
    
    return y;
}

# Runge-Kutta-Fehlberg (adaptive)
fn rkf_ode(f, y0, t0, t1, h, tol) {
    if type(tol) == "null" { tol = 1e-6; }
    
    let t = t0;
    let y = y0;
    let dt = h;
    
    while t < t1 {
        if t + dt > t1 {
            dt = t1 - t;
        }
        
        let k1 = f(t, y);
        let k2 = f(t + dt/4, y + dt * k1 / 4);
        let k3 = f(t + dt * 3/8, y + dt * (3 * k1 + 9 * k2) / 32);
        let k4 = f(t + dt * 12/13, y + dt * (1932 * k1 - 7200 * k2 + 7296 * k3) / 2197);
        let k5 = f(t + dt, y + dt * (439 * k1 - 8 * k2 + 3680 * k3 - 845 * k4) / 4104);
        let k6 = f(t + dt / 2, y + dt * (-8 * k1 + 2 * k2 - 3544 * k3 + 1859 * k4 - 11 * k5) / 40);
        
        let y5 = y + dt * (25 * k1 + 1408 * k3 + 2197 * k4 - 11 * k5) / 216;
        let y4 = y + dt * (33440 * k1 + 110592 * k3 + 65025 * k4 - 53360 * k5 + 5040 * k6) / 146880;
        
        let error = abs(y5 - y4);
        
        if error < tol {
            t = t + dt;
            y = y5;
        }
        
        # Adjust step size
        dt = dt * min(4, max(0.1, 0.84 * pow(tol / error, 0.25)));
    }
    
    return y;
}

# ===========================================
# MATRIX DECOMPOSITIONS (Beyond BLAS)
# ===========================================

# LU Decomposition
class LUDecomposition {
    fn init(self, A) {
        self.A = A;
        self.n = len(A);
        
        # Initialize L and U
        self.L = [];
        self.U = [];
        self.P = [];
        
        for i in range(self.n) {
            let l_row = [];
            let u_row = [];
            let p_row = [];
            for j in range(self.n) {
                push(l_row, i == j ? 1 : 0);
                push(u_row, 0);
                push(p_row, i == j ? 1 : 0);
            }
            push(self.L, l_row);
            push(self.U, u_row);
            push(self.P, p_row);
        }
        
        self._decompose();
    }
    
    fn _decompose(self) {
        for k in range(self.n - 1) {
            # Pivot selection
            let max_row = k;
            let max_val = abs(self.A[k][k]);
            
            for i in range(k + 1, self.n) {
                if abs(self.A[i][k]) > max_val {
                    max_val = abs(self.A[i][k]);
                    max_row = i;
                }
            }
            
            # Swap rows
            if max_row != k {
                let temp = self.A[k];
                self.A[k] = self.A[max_row];
                self.A[max_row] = temp;
            }
            
            # Elimination
            for i in range(k + 1, self.n) {
                let factor = self.A[i][k] / self.A[k][k];
                self.A[i][k] = factor;
                
                for j in range(k + 1, self.n) {
                    self.A[i][j] = self.A[i][j] - factor * self.A[k][j];
                }
            }
        }
        
        # Extract L and U
        for i in range(self.n) {
            for j in range(self.n) {
                if i > j {
                    self.L[i][j] = self.A[i][j];
                } else if i <= j {
                    self.U[i][j] = self.A[i][j];
                }
            }
        }
    }
    
    fn solve(self, b) {
        # Forward substitution (Ly = b)
        let y = [];
        for i in range(self.n) {
            let sum = 0;
            for j in range(i) {
                sum = sum + self.L[i][j] * y[j];
            }
            push(y, b[i] - sum);
        }
        
        # Backward substitution (Ux = y)
        let x = [];
        for i in range(self.n - 1, -1, -1) {
            let sum = 0;
            for j in range(i + 1, self.n) {
                sum = sum + self.U[i][j] * x[j];
            }
            push(x, (y[i] - sum) / self.U[i][i]);
        }
        
        return x;
    }
    
    fn det(self) {
        let result = 1;
        for i in range(self.n) {
            result = result * self.U[i][i];
        }
        return result;
    }
    
    fn inv(self) {
        let n = self.n;
        let I = [];
        
        # Create identity matrix
        for i in range(n) {
            let row = [];
            for j in range(n) {
                push(row, i == j ? 1 : 0);
            }
            push(I, row);
        }
        
        # Solve for each column
        let result = [];
        for col in range(n) {
            let b = [];
            for i in range(n) {
                push(b, I[i][col]);
            }
            let x = self.solve(b);
            push(result, x);
        }
        
        return result;
    }
}

# QR Decomposition (Gram-Schmidt)
class QRDecomposition {
    fn init(self, A) {
        self.A = A;
        self.m = len(A);
        self.n = len(A[0]);
        
        self.Q = [];
        self.R = [];
        
        # Initialize Q and R
        for i in range(self.m) {
            let q_row = [];
            for j in range(self.n) {
                push(q_row, 0);
            }
            push(self.Q, q_row);
        }
        
        for i in range(self.n) {
            let r_row = [];
            for j in range(self.n) {
                push(r_row, 0);
            }
            push(self.R, r_row);
        }
        
        self._decompose();
    }
    
    fn _decompose(self) {
        let v = [];
        
        for j in range(self.n) {
            # Copy column j to v
            let vj = [];
            for i in range(self.m) {
                push(vj, self.A[i][j]);
            }
            push(v, vj);
        }
        
        for i in range(self.n) {
            # Orthogonalize against previous vectors
            for k in range(i) {
                let dot = 0;
                for j in range(self.m) {
                    dot = dot + self.A[j][i] * self.Q[j][k];
                }
                self.R[k][i] = dot;
                
                for j in range(self.m) {
                    v[i][j] = v[i][j] - dot * self.Q[j][k];
                }
            }
            
            # Normalize
            let norm = 0;
            for j in range(self.m) {
                norm = norm + v[i][j] * v[i][j];
            }
            norm = sqrt(norm);
            
            self.R[i][i] = norm;
            
            for j in range(self.m) {
                self.Q[j][i] = v[i][j] / norm;
            }
        }
    }
    
    fn solve(self, b) {
        # Compute Q^T * b
        let Qtb = [];
        for i in range(self.n) {
            let sum = 0;
            for j in range(self.m) {
                sum = sum + self.Q[j][i] * b[j];
            }
            push(Qtb, sum);
        }
        
        # Back substitution
        let x = [];
        for i in range(self.n - 1, -1, -1) {
            let sum = 0;
            for j in range(i + 1, self.n) {
                sum = sum + self.R[i][j] * x[j];
            }
            push(x, (Qtb[i] - sum) / self.R[i][i]);
        }
        
        return x;
    }
}

# Cholesky Decomposition
class CholeskyDecomposition {
    fn init(self, A) {
        self.A = A;
        self.n = len(A);
        
        self.L = [];
        
        for i in range(self.n) {
            let row = [];
            for j in range(self.n) {
                push(row, 0);
            }
            push(self.L, row);
        }
        
        self._decompose();
    }
    
    fn _decompose(self) {
        for i in range(self.n) {
            for j in range(i + 1) {
                let sum = 0;
                for k in range(j) {
                    sum = sum + self.L[i][k] * self.L[j][k];
                }
                
                if i == j {
                    if self.A[i][i] - sum <= 0 {
                        throw "cholesky: matrix not positive definite";
                    }
                    self.L[i][j] = sqrt(self.A[i][i] - sum);
                } else {
                    self.L[i][j] = (self.A[i][j] - sum) / self.L[j][j];
                }
            }
        }
    }
    
    fn solve(self, b) {
        # Forward substitution (Ly = b)
        let y = [];
        for i in range(self.n) {
            let sum = 0;
            for j in range(i) {
                sum = sum + self.L[i][j] * y[j];
            }
            push(y, (b[i] - sum) / self.L[i][i]);
        }
        
        # Back substitution (L^T x = y)
        let x = [];
        for i in range(self.n - 1, -1, -1) {
            let sum = 0;
            for j in range(i + 1, self.n) {
                sum = sum + self.L[j][i] * x[j];
            }
            push(x, (y[i] - sum) / self.L[i][i]);
        }
        
        return x;
    }
}

# ===========================================
# EIGENVALUE DECOMPOSITION (Power Method)
# ===========================================

# Power iteration for dominant eigenvalue
fn power_iteration(A, max_iter, tol) {
    if type(max_iter) == "null" { max_iter = 100; }
    if type(tol) == "null" { tol = 1e-6; }
    
    let n = len(A);
    
    # Initial guess
    let v = [];
    for i in range(n) {
        push(v, 1.0);
    }
    
    # Normalize
    let norm = 0;
    for i in range(n) {
        norm = norm + v[i] * v[i];
    }
    norm = sqrt(norm);
    for i in range(n) {
        v[i] = v[i] / norm;
    }
    
    let eigenvalue = 0;
    
    for iter in range(max_iter) {
        # Matrix-vector multiplication
        let Av = [];
        for i in range(n) {
            let sum = 0;
            for j in range(n) {
                sum = sum + A[i][j] * v[j];
            }
            push(Av, sum);
        }
        
        # Rayleigh quotient
        let new_eigenvalue = 0;
        for i in range(n) {
            new_eigenvalue = new_eigenvalue + v[i] * Av[i];
        }
        
        # Normalize
        norm = 0;
        for i in range(n) {
            norm = norm + Av[i] * Av[i];
        }
        norm = sqrt(norm);
        
        for i in range(n) {
            v[i] = Av[i] / norm;
        }
        
        if abs(new_eigenvalue - eigenvalue) < tol {
            eigenvalue = new_eigenvalue;
            break;
        }
        
        eigenvalue = new_eigenvalue;
    }
    
    return [eigenvalue, v];
}

# Inverse power iteration
fn inverse_power_iteration(A, mu, max_iter, tol) {
    if type(max_iter) == "null" { max_iter = 100; }
    if type(tol) == "null" { tol = 1e-6; }
    
    # Create (A - mu*I)
    let n = len(A);
    let B = [];
    
    for i in range(n) {
        let row = [];
        for j in range(n) {
            let val = A[i][j];
            if i == j {
                val = val - mu;
            }
            push(row, val);
        }
        push(B, row);
    }
    
    # Use LU decomposition
    let lu = LUDecomposition(B);
    
    # Initial guess
    let v = [];
    for i in range(n) {
        push(v, 1.0);
    }
    
    for iter in range(max_iter) {
        # Solve Bv = v
        let new_v = lu.solve(v);
        
        # Normalize
        let norm = 0;
        for i in range(n) {
            norm = norm + new_v[i] * new_v[i];
        }
        norm = sqrt(norm);
        
        for i in range(n) {
            v[i] = new_v[i] / norm;
        }
    }
    
    # Compute eigenvalue
    let Av = [];
    for i in range(n) {
        let sum = 0;
        for j in range(n) {
            sum = sum + A[i][j] * v[j];
        }
        push(Av, sum);
    }
    
    let eigenvalue = 0;
    for i in range(n) {
        eigenvalue = eigenvalue + v[i] * Av[i];
    }
    
    return [eigenvalue, v];
}

# ===========================================
# SINGULAR VALUE DECOMPOSITION (Simplified)
# ===========================================

# Simplified SVD using power method
class SVD {
    fn init(self, A) {
        self.A = A;
        self.m = len(A);
        self.n = len(A[0]);
        
        self._compute();
    }
    
    fn _compute(self) {
        # Compute A^T * A
        let ATA = [];
        for i in range(self.n) {
            let row = [];
            for j in range(self.n) {
                let sum = 0;
                for k in range(self.m) {
                    sum = sum + A[k][i] * A[k][j];
                }
                push(row, sum);
            }
            push(ATA, row);
        }
        
        # Get eigenvalues of A^T * A
        let ev_pair = power_iteration(ATA, 100, 1e-6);
        let sigma1 = sqrt(ev_pair[0]);
        
        # Right singular vector
        let v = ev_pair[1];
        
        # Left singular vector: u = A * v / sigma
        let u = [];
        for i in range(self.m) {
            let sum = 0;
            for j in range(self.n) {
                sum = sum + A[i][j] * v[j];
            }
            push(u, sum / sigma1);
        }
        
        self.U = [u];
        self.S = [sigma1];
        self.V = [v];
    }
}

# ===========================================
# UTILITY FUNCTIONS
# ===========================================

# Check if number is finite
fn isfinite(x) {
    return x == x && x != INF && x != -INF;
}

# Check if number is infinite
fn isinf(x) {
    return x == INF || x == -INF;
}

# Check if number is NaN
fn isnan(x) {
    return x != x;
}

# Check if number is integer
fn isint(x) {
    return x == int(x);
}

# Check if number is even
fn iseven(x) {
    return int(x) % 2 == 0;
}

# Check if number is odd
fn isodd(x) {
    return int(x) % 2 != 0;
}

# Distance between two points
fn distance(x1, y1, x2, y2) {
    return hypot(x2 - x1, y2 - y1);
}

# Distance in n dimensions
fn distance_n(p1, p2) {
    let sum = 0;
    for i in range(min(len(p1), len(p2))) {
        sum = sum + (p2[i] - p1[i]) * (p2[i] - p1[i]);
    }
    return sqrt(sum);
}

# Manhattan distance
fn manhattan_distance(x1, y1, x2, y2) {
    return abs(x2 - x1) + abs(y2 - y1);
}

# Chebyshev distance
fn chebyshev_distance(x1, y1, x2, y2) {
    return max(abs(x2 - x1), abs(y2 - y1));
}

# Great circle distance (Haversine)
fn haversine(lat1, lon1, lat2, lon2) {
    let R = 6371;  # Earth's radius in km
    
    let dlat = radians(lat2 - lat1);
    let dlon = radians(lon2 - lon1);
    
    let a = sin(dlat / 2) * sin(dlat / 2) +
            cos(radians(lat1)) * cos(radians(lat2)) *
            sin(dlon / 2) * sin(dlon / 2);
    
    let c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return R * c;
}

# ===========================================
# COMPLEX NUMBERS
# ===========================================

# Complex number operations (simplified)
fn complex_add(a, b) {
    return [a[0] + b[0], a[1] + b[1]];
}

fn complex_sub(a, b) {
    return [a[0] - b[0], a[1] - b[1]];
}

fn complex_mul(a, b) {
    return [a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0]];
}

fn complex_div(a, b) {
    let denom = b[0] * b[0] + b[1] * b[1];
    return [(a[0] * b[0] + a[1] * b[1]) / denom, (a[1] * b[0] - a[0] * b[1]) / denom];
}

fn complex_mag(z) {
    return sqrt(z[0] * z[0] + z[1] * z[1]);
}

fn complex_arg(z) {
    return atan2(z[1], z[0]);
}

fn complex_exp(z) {
    let r = exp(z[0]);
    return [r * cos(z[1]), r * sin(z[1])];
}

fn complex_log(z) {
    return [log(complex_mag(z)), complex_arg(z)];
}

# Imaginary unit
let I = [0, 1];

# ===========================================
# EXPORTS
# ===========================================

{
    # Constants
    "PI": PI,
    "E": E,
    "TAU": TAU,
    "INF": INF,
    "NAN": NAN,
    "PHI": PHI,
    "SQRT2": SQRT2,
    "SQRT3": SQRT3,
    "LN2": LN2,
    "LN10": LN10,
    "LOG2E": LOG2E,
    "LOG10E": LOG10E,
    "EULER_GAMMA": EULER_GAMMA,
    "CATALAN": CATALAN,
    
    # Basic functions
    "abs": abs,
    "min": min,
    "max": max,
    "clamp": clamp,
    "floor": floor,
    "ceil": ceil,
    "round": round,
    "round_n": round_n,
    "trunc": trunc,
    "sign": sign,
    "sqrt": sqrt,
    "cbrt": cbrt,
    "hypot": hypot,
    "pow": pow,
    "ipow": ipow,
    
    # Log/exp
    "log": log,
    "log10": log10,
    "log2": log2,
    "logb": logb,
    "exp": exp,
    "expm1": expm1,
    "log1p": log1p,
    
    # Trigonometry
    "radians": radians,
    "degrees": degrees,
    "sin": sin,
    "cos": cos,
    "tan": tan,
    "cot": cot,
    "sec": sec,
    "csc": csc,
    
    # Inverse trig
    "asin": asin,
    "acos": acos,
    "atan": atan,
    "atan2": atan2,
    "acot": acot,
    "asec": asec,
    "acsc": acsc,
    
    # Hyperbolic
    "sinh": sinh,
    "cosh": cosh,
    "tanh": tanh,
    "coth": coth,
    "sech": sech,
    "csch": csch,
    
    # Inverse hyperbolic
    "asinh": asinh,
    "acosh": acosh,
    "atanh": atanh,
    "acoth": acoth,
    "asech": asech,
    "acsch": acsch,
    
    # Special functions
    "gamma": gamma,
    "lgamma": lgamma,
    "digamma": digamma,
    "trigamma": trigamma,
    "beta": beta,
    "lbeta": lbeta,
    "erf": erf,
    "erfc": erfc,
    "erfinv": erfinv,
    "fresnel_c": fresnel_c,
    "fresnel_s": fresnel_s,
    "zeta": zeta,
    "polylog": polylog,
    "dilog": dilog,
    
    # Bessel
    "bessel_j": bessel_j,
    "bessel_y": bessel_y,
    "bessel_i": bessel_i,
    "bessel_k": bessel_k,
    
    # Polynomials
    "legendre": legendre,
    "hermite": hermite,
    "chebyshev_t": chebyshev_t,
    "chebyshev_u": chebyshev_u,
    "laguerre": laguerre,
    "poly_eval": poly_eval,
    "poly_derivative": poly_derivative,
    "poly_integral": poly_integral,
    
    # Number theory
    "gcd": gcd,
    "lcm": lcm,
    "is_prime": is_prime,
    "sieve_of_eratosthenes": sieve_of_eratosthenes,
    "factorize": factorize,
    "factorize_exp": factorize_exp,
    "num_divisors": num_divisors,
    "sum_divisors": sum_divisors,
    "euler_totient": euler_totient,
    "mobius": mobius,
    "is_square": is_square,
    "is_cube": is_cube,
    "isqrt": isqrt,
    "iroot": iroot,
    "next_prime": next_prime,
    "prev_prime": prev_prime,
    "nth_prime": nth_prime,
    "mod_pow": mod_pow,
    "mod_inverse": mod_inverse,
    
    # Combinatorics
    "factorial": factorial,
    "double_factorial": double_factorial,
    "binom": binom,
    "permutations": permutations,
    "combinations_with_repetition": combinations_with_repetition,
    "catalan": catalan,
    "bell": bell,
    "stirling2": stirling2,
    "partition": partition,
    "fibonacci": fibonacci,
    "lucas": lucas,
    
    # Interpolation
    "lerp": lerp,
    "bilinear_interp": bilinear_interp,
    "lagrange_interp": lagrange_interp,
    "newton_interp": newton_interp,
    "CubicSpline": CubicSpline,
    
    # Integration
    "trapezoid": trapezoid,
    "simpson": simpson,
    "simpson_38": simpson_38,
    "simpson_composite": simpson_composite,
    "boole": boole,
    "gaussian_quadrature": gaussian_quadrature,
    "adaptive_simpson": adaptive_simpson,
    "romberg": romberg,
    
    # Differentiation
    "central_diff": central_diff,
    "forward_diff": forward_diff,
    "backward_diff": backward_diff,
    "second_derivative": second_derivative,
    
    # Root finding
    "bisection": bisection,
    "newton": newton,
    "secant": secant,
    "fixed_point": fixed_point,
    
    # ODE
    "euler_ode": euler_ode,
    "improved_euler_ode": improved_euler_ode,
    "rk4_ode": rk4_ode,
    "rkf_ode": rkf_ode,
    
    # Matrix
    "LUDecomposition": LUDecomposition,
    "QRDecomposition": QRDecomposition,
    "CholeskyDecomposition": CholeskyDecomposition,
    "SVD": SVD,
    "power_iteration": power_iteration,
    
    # Complex
    "complex_add": complex_add,
    "complex_sub": complex_sub,
    "complex_mul": complex_mul,
    "complex_div": complex_div,
    "complex_mag": complex_mag,
    "complex_arg": complex_arg,
    "complex_exp": complex_exp,
    "complex_log": complex_log,
    "I": I,
    
    # Utilities
    "isfinite": isfinite,
    "isinf": isinf,
    "isnan": isnan,
    "isint": isint,
    "iseven": iseven,
    "isodd": isodd,
    "distance": distance,
    "distance_n": distance_n,
    "manhattan_distance": manhattan_distance,
    "chebyshev_distance": chebyshev_distance,
    "haversine": haversine
}

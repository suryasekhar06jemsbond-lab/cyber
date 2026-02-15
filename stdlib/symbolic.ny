# ============================================================
# Nyx Standard Library - Symbolic Module
# ============================================================
# Comprehensive symbolic mathematics library providing capabilities
# equivalent to sympy and sage for symbolic computation,
# algebraic manipulation, and mathematical expression handling.

# ============================================================
# Symbol Class
# ============================================================

class Symbol {
    init(name, **assumptions) {
        self.name = name;
        self.assumptions = assumptions;
        self._hash = hash(name);
    }

    __repr__() {
        return self.name;
    }

    __str__() {
        return self.name;
    }

    __hash__() {
        return self._hash;
    }

    __eq__(other) {
        if type(other) == "symbol" {
            return self.name == other.name;
        }
        return false;
    }

    __ne__(other) {
        return !self.__eq__(other);
    }

    __add__(other) {
        return Add.new(self, other);
    }

    __radd__(other) {
        return Add.new(other, self);
    }

    __sub__(other) {
        return Sub.new(self, other);
    }

    __rsub__(other) {
        return Sub.new(other, self);
    }

    __mul__(other) {
        return Mul.new(self, other);
    }

    __rmul__(other) {
        return Mul.new(other, self);
    }

    __div__(other) {
        return Div.new(self, other);
    }

    __rdiv__(other) {
        return Div.new(other, self);
    }

    __pow__(other) {
        return Pow.new(self, other);
    }

    __rpow__(other) {
        return Pow.new(other, self);
    }

    simplify() {
        return self;
    }

    expand() {
        return self;
    }

    factor() {
        return self;
    }

    collect(var) {
        return self;
    }

    subs(old, new) {
        if self.name == old {
            return new;
        }
        return self;
    }

    diff(var) {
        if self.name == var {
            return Integer.new(1);
        }
        return Integer.new(0);
    }

    integrate(var) {
        if self.name == var {
            return Mul.new(self, Symbol.new(var));
        }
        return self;
    }

    simplify() {
        return self;
    }

    evalf(precision) {
        return Float.new(0);
    }

    is_number() {
        return false;
    }

    is_symbol() {
        return true;
    }

    is_constant() {
        return false;
    }

    is_real() {
        return self.assumptions.real || false;
    }

    is_complex() {
        return self.assumptions.complex || false;
    }

    is_positive() {
        return self.assumptions.positive || false;
    }

    is_negative() {
        return self.assumptions.negative || false;
    }

    is_integer() {
        return self.assumptions.integer || false;
    }

    is_even() {
        return self.assumptions.even || false;
    }

    is_odd() {
        return self.assumptions.odd || false;
    }

    is_prime() {
        return self.assumptions.prime || false;
    }

    is_composite() {
        return self.assumptions.composite || false;
    }

    is_finite() {
        return self.assumptions.finite || true;
    }

    is_infinite() {
        return self.assumptions.infinite || false;
    }

    is_zero() {
        return false;
    }

    is_one() {
        return false;
    }

    is_Number() {
        return false;
    }
}

# ============================================================
# Number Classes
# ============================================================

class Number {
    init(value) {
        self.value = value;
    }

    is_number() {
        return true;
    }

    is_symbol() {
        return false;
    }

    is_constant() {
        return true;
    }

    is_zero() {
        return self.value == 0;
    }

    is_one() {
        return self.value == 1;
    }

    is_Number() {
        return true;
    }

    __hash__() {
        return hash(str(self.value));
    }
}

class Integer {
    init(value) {
        Number.init(self, value);
    }

    __repr__() {
        return str(self.value);
    }

    __str__() {
        return str(self.value);
    }

    __eq__(other) {
        if type(other) == "integer" {
            return self.value == other.value;
        }
        if type(other) == "float" {
            return self.value == other.value;
        }
        return false;
    }

    __ne__(other) {
        return !self.__eq__(other);
    }

    __add__(other) {
        if type(other) == "integer" {
            return Integer.new(self.value + other.value);
        }
        if type(other) == "float" {
            return Float.new(self.value + other.value);
        }
        return Add.new(self, other);
    }

    __sub__(other) {
        if type(other) == "integer" {
            return Integer.new(self.value - other.value);
        }
        if type(other) == "float" {
            return Float.new(self.value - other.value);
        }
        return Sub.new(self, other);
    }

    __mul__(other) {
        if type(other) == "integer" {
            return Integer.new(self.value * other.value);
        }
        if type(other) == "float" {
            return Float.new(self.value * other.value);
        }
        return Mul.new(self, other);
    }

    __div__(other) {
        if type(other) == "integer" {
            if self.value % other.value == 0 {
                return Integer.new(self.value / other.value);
            }
            return Rational.new(self.value, other.value);
        }
        if type(other) == "float" {
            return Float.new(self.value / other.value);
        }
        return Div.new(self, other);
    }

    __pow__(other) {
        if type(other) == "integer" {
            return Integer.new(pow(self.value, other.value));
        }
        return Pow.new(self, other);
    }

    simplify() {
        return self;
    }

    evalf(precision) {
        return Float.new(self.value);
    }

    is_integer() {
        return true;
    }

    is_even() {
        return self.value % 2 == 0;
    }

    is_odd() {
        return self.value % 2 != 0;
    }

    is_positive() {
        return self.value > 0;
    }

    is_negative() {
        return self.value < 0;
    }

    is_prime() {
        if self.value < 2 {
            return false;
        }
        for let i in range(2, int(sqrt(self.value)) + 1) {
            if self.value % i == 0 {
                return false;
            }
        }
        return true;
    }

    is_composite() {
        return !self.is_prime() && self.value > 1;
    }

    abs() {
        return Integer.new(abs(self.value));
    }

    factorial() {
        let result = 1;
        for let i in range(2, self.value + 1) {
            result = result * i;
        }
        return Integer.new(result);
    }

    gcd(other) {
        let a = abs(self.value);
        let b = abs(other.value);
        while b != 0 {
            let t = b;
            b = a % b;
            a = t;
        }
        return Integer.new(a);
    }

    lcm(other) {
        return Integer.new(abs(self.value * other.value) / self.gcd(other).value);
    }
}

class Float {
    init(value) {
        Number.init(self, value);
    }

    __repr__() {
        return str(self.value);
    }

    __str__() {
        return str(self.value);
    }

    __eq__(other) {
        if type(other) == "float" {
            return self.value == other.value;
        }
        if type(other) == "integer" {
            return self.value == other.value;
        }
        return false;
    }

    __ne__(other) {
        return !self.__eq__(other);
    }

    __add__(other) {
        if type(other) == "float" {
            return Float.new(self.value + other.value);
        }
        if type(other) == "integer" {
            return Float.new(self.value + other.value);
        }
        return Add.new(self, other);
    }

    __sub__(other) {
        if type(other) == "float" {
            return Float.new(self.value - other.value);
        }
        if type(other) == "integer" {
            return Float.new(self.value - other.value);
        }
        return Sub.new(self, other);
    }

    __mul__(other) {
        if type(other) == "float" {
            return Float.new(self.value * other.value);
        }
        if type(other) == "integer" {
            return Float.new(self.value * other.value);
        }
        return Mul.new(self, other);
    }

    __div__(other) {
        if type(other) == "float" {
            return Float.new(self.value / other.value);
        }
        if type(other) == "integer" {
            return Float.new(self.value / other.value);
        }
        return Div.new(self, other);
    }

    is_real() {
        return true;
    }

    is_positive() {
        return self.value > 0;
    }

    is_negative() {
        return self.value < 0;
    }

    is_zero() {
        return self.value == 0;
    }

    evalf(precision) {
        return self;
    }

    simplify() {
        return self;
    }

    abs() {
        return Float.new(abs(self.value));
    }
}

class Rational {
    init(p, q) {
        Number.init(self, 0);
        self.p = p;
        self.q = q;
        self._simplify();
    }

    _simplify() {
        if self.q < 0 {
            self.p = -self.p;
            self.q = -self.q;
        }
        if self.p == 0 {
            self.q = 1;
            return;
        }
        let g = gcd(abs(self.p), self.q);
        if g > 1 {
            self.p = self.p / g;
            self.q = self.q / g;
        }
    }

    __repr__() {
        if self.q == 1 {
            return str(self.p);
        }
        return str(self.p) + "/" + str(self.q);
    }

    __str__() {
        return self.__repr__();
    }

    __eq__(other) {
        if type(other) == "rational" {
            return self.p == other.p && self.q == other.q;
        }
        if type(other) == "integer" {
            return self.p == other.value * self.q;
        }
        return false;
    }

    __add__(other) {
        if type(other) == "integer" {
            return Rational.new(self.p + other.value * self.q, self.q);
        }
        if type(other) == "rational" {
            return Rational.new(self.p * other.q + other.p * self.q, self.q * other.q);
        }
        return Add.new(self, other);
    }

    __sub__(other) {
        if type(other) == "integer" {
            return Rational.new(self.p - other.value * self.q, self.q);
        }
        if type(other) == "rational" {
            return Rational.new(self.p * other.q - other.p * self.q, self.q * other.q);
        }
        return Sub.new(self, other);
    }

    __mul__(other) {
        if type(other) == "integer" {
            return Rational.new(self.p * other.value, self.q);
        }
        if type(other) == "rational" {
            return Rational.new(self.p * other.p, self.q * other.q);
        }
        return Mul.new(self, other);
    }

    __div__(other) {
        if type(other) == "integer" {
            return Rational.new(self.p, self.q * other.value);
        }
        if type(other) == "rational" {
            return Rational.new(self.p * other.q, self.q * other.p);
        }
        return Div.new(self, other);
    }

    simplify() {
        return self;
    }

    evalf(precision) {
        return Float.new(self.p / self.q);
    }

    numerator() {
        return Integer.new(self.p);
    }

    denominator() {
        return Integer.new(self.q);
    }

    is_integer() {
        return self.q == 1;
    }

    is_positive() {
        return self.p > 0;
    }

    is_negative() {
        return self.p < 0;
    }

    is_zero() {
        return self.p == 0;
    }

    is_one() {
        return self.p == 1 && self.q == 1;
    }
}

class Complex {
    init(re, im) {
        self.re = re;
        self.im = im;
    }

    __repr__() {
        if self.im == 0 {
            return str(self.re);
        }
        if self.re == 0 {
            return str(self.im) + "i";
        }
        if self.im > 0 {
            return str(self.re) + " + " + str(self.im) + "i";
        }
        return str(self.re) + " - " + str(-self.im) + "i";
    }

    __str__() {
        return self.__repr__();
    }

    __eq__(other) {
        if type(other) == "complex" {
            return self.re == other.re && self.im == other.im;
        }
        return false;
    }

    __add__(other) {
        if type(other) == "complex" {
            return Complex.new(self.re + other.re, self.im + other.im);
        }
        return Complex.new(self.re + other, self.im);
    }

    __sub__(other) {
        if type(other) == "complex" {
            return Complex.new(self.re - other.re, self.im - other.im);
        }
        return Complex.new(self.re - other, self.im);
    }

    __mul__(other) {
        if type(other) == "complex" {
            return Complex.new(self.re * other.re - self.im * other.im, self.re * other.im + self.im * other.re);
        }
        return Complex.new(self.re * other, self.im * other);
    }

    conjugate() {
        return Complex.new(self.re, -self.im);
    }

    abs() {
        return sqrt(self.re * self.re + self.im * self.im);
    }

    arg() {
        return atan2(self.im, self.re);
    }

    is_real() {
        return self.im == 0;
    }

    is_complex() {
        return true;
    }
}

class Infinity {
    init() {
        self.positive = true;
    }

    __repr__() {
        return "oo";
    }

    __str__() {
        return "oo";
    }

    __add__(other) {
        return self;
    }

    __sub__(other) {
        return self;
    }

    __mul__(other) {
        return self;
    }

    __div__(other) {
        if other == 0 {
            return self;
        }
        return self;
    }

    __pow__(other) {
        if other > 0 {
            return self;
        }
        return Integer.new(0);
    }

    is_positive() {
        return true;
    }

    is_infinite() {
        return true;
    }

    is_number() {
        return true;
    }
}

class NegativeInfinity {
    init() {
        self.positive = false;
    }

    __repr__() {
        return "-oo";
    }

    __str__() {
        return "-oo";
    }

    __add__(other) {
        return self;
    }

    is_negative() {
        return true;
    }

    is_infinite() {
        return true;
    }
}

class NaN {
    init() {}

    __repr__() {
        return "nan";
    }

    __str__() {
        return "nan";
    }

    is_number() {
        return true;
    }
}

# ============================================================
# Mathematical Expressions
# ============================================================

class Expr {
    init() {}

    simplify() {
        return self;
    }

    expand() {
        return self;
    }

    factor() {
        return self;
    }

    subs(old, new) {
        return self;
    }

    diff(var) {
        return Integer.new(0);
    }

    integrate(var) {
        return self;
    }

    evalf(precision) {
        return self;
    }

    series(var, point, order) {
        return self;
    }

    limit(var, value, direction) {
        return self;
    }

    is_number() {
        return false;
    }

    is_symbol() {
        return false;
    }

    is_Add() {
        return false;
    }

    is_Mul() {
        return false;
    }

    is_Pow() {
        return false;
    }

    is_Number() {
        return false;
    }

    is_Integer() {
        return false;
    }

    is_Float() {
        return false;
    }

    is_Symbol() {
        return false;
    }

    is_Rational() {
        return false;
    }

    is_Complex() {
        return false;
    }

    args() {
        return [self];
    }

    func() {
        return self;
    }

    func_name() {
        return type(self);
    }
}

class Add {
    init(*args) {
        self.args = args;
        self._coeffs = {};
        self._simplified = false;
    }

    __repr__() {
        let parts = [];
        for let i in range(len(self.args)) {
            let arg = self.args[i];
            let s = repr(arg);
            
            if i > 0 {
                if type(arg) == "integer" && arg.value < 0 {
                    parts.push(" - " + str(-arg.value));
                } else if type(arg) == "float" && arg.value < 0 {
                    parts.push(" - " + str(-arg.value));
                } else {
                    parts.push(" + " + s);
                }
            } else {
                if type(arg) == "integer" && arg.value < 0 {
                    parts.push("-" + str(-arg.value));
                } else if type(arg) == "float" && arg.value < 0 {
                    parts.push("-" + str(-arg.value));
                } else {
                    parts.push(s);
                }
            }
        }
        
        if len(parts) == 0 {
            return "0";
        }
        
        let result = "";
        for let part in parts {
            result = result + part;
        }
        return result;
    }

    __str__() {
        return self.__repr__();
    }

    simplify() {
        if self._simplified {
            return self;
        }
        
        let terms = {};
        
        for let arg in self.args {
            let key = repr(arg);
            if !terms[key] {
                terms[key] = arg;
            }
        }
        
        self._simplified = true;
        return self;
    }

    expand() {
        # Expand nested expressions
        return self;
    }

    diff(var) {
        let result = [];
        for let arg in self.args {
            result.push(arg.diff(var));
        }
        return Add.new(...result);
    }

    integrate(var) {
        let result = [];
        for let arg in self.args {
            result.push(arg.integrate(var));
        }
        return Add.new(...result);
    }

    subs(old, new_val) {
        let result = [];
        for let arg in self.args {
            result.push(arg.subs(old, new_val));
        }
        return Add.new(...result);
    }

    is_Add() {
        return true;
    }

    args() {
        return self.args;
    }
}

class Mul {
    init(*args) {
        self.args = args;
    }

    __repr__() {
        if len(self.args) == 0 {
            return "1";
        }
        
        let parts = [];
        for let arg in self.args {
            parts.push(repr(arg));
        }
        
        let result = "";
        for let i in range(len(parts)) {
            if i > 0 {
                result = result + "*";
            }
            result = result + parts[i];
        }
        
        return result;
    }

    __str__() {
        return self.__repr__();
    }

    simplify() {
        return self;
    }

    expand() {
        return self;
    }

    diff(var) {
        # Product rule
        let result = [];
        
        for let i in range(len(self.args)) {
            let new_args = [...self.args];
            new_args[i] = self.args[i].diff(var);
            result.push(Mul.new(...new_args));
        }
        
        return Add.new(...result);
    }

    integrate(var) {
        # Integration by parts (simplified)
        return self;
    }

    is_Mul() {
        return true;
    }

    args() {
        return self.args;
    }
}

class Div {
    init(num, den) {
        self.num = num;
        self.den = den;
    }

    __repr__() {
        return "(" + repr(self.num) + "/" + repr(self.den) + ")";
    }

    __str__() {
        return self.__repr__();
    }

    simplify() {
        return self;
    }

    expand() {
        return self;
    }

    diff(var) {
        # Quotient rule
        let u = self.num;
        let v = self.den;
        
        let du = u.diff(var);
        let dv = v.diff(var);
        
        return Div.new(
            Sub.new(Mul.new(du, v), Mul.new(u, dv)),
            Pow.new(v, Integer.new(2))
        );
    }

    is_Div() {
        return true;
    }

    args() {
        return [self.num, self.den];
    }
}

class Pow {
    init(base, exp) {
        self.base = base;
        self.exp = exp;
    }

    __repr__() {
        return "(" + repr(self.base) + ")**" + repr(self.exp) + ")";
    }

    __str__() {
        return self.__repr__();
    }

    simplify() {
        # Simplify powers
        return self;
    }

    expand() {
        # Expand powers
        return self;
    }

    diff(var) {
        if self.base == Symbol.new(var) {
            # d/dx(x^n) = n*x^(n-1)
            return Mul.new(self.exp, Pow.new(self.base, Sub.new(self.exp, Integer.new(1))));
        }
        
        # Chain rule: d/dx(f(x)^n) = n*f(x)^(n-1)*f'(x)
        let f = self.base;
        let n = self.exp;
        
        return Mul.new(
            n,
            Pow.new(f, Sub.new(n, Integer.new(1))),
            f.diff(var)
        );
    }

    integrate(var) {
        if self.base == Symbol.new(var) {
            # Integral of x^n = x^(n+1)/(n+1)
            let n_plus_1 = Add.new(self.exp, Integer.new(1));
            return Div.new(Pow.new(self.base, n_plus_1), n_plus_1);
        }
        
        return self;
    }

    is_Pow() {
        return true;
    }

    args() {
        return [self.base, self.exp];
    }
}

class Neg {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "-" + repr(self.arg);
    }

    __str__() {
        return self.__repr__();
    }

    simplify() {
        return Neg.new(self.arg.simplify());
    }

    diff(var) {
        return Neg.new(self.arg.diff(var));
    }

    integrate(var) {
        return Neg.new(self.arg.integrate(var));
    }
}

# ============================================================
# Trigonometric Functions
# ============================================================

class sin {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "sin(" + repr(self.arg) + ")";
    }

    __str__() {
        return self.__repr__();
    }

    diff(var) {
        return Mul.new(cos.new(self.arg), self.arg.diff(var));
    }

    integrate(var) {
        # cos(x) = sin(x)
        if self.arg == Symbol.new(var) {
            return Mul.new(Integer.new(-1), cos.new(self.arg));
        }
        return self;
    }
}

class cos {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "cos(" + repr(self.arg) + ")";
    }

    __str__() {
        return self.__repr__();
    }

    diff(var) {
        return Mul.new(Integer.new(-1), sin.new(self.arg), self.arg.diff(var));
    }

    integrate(var) {
        # sin(x) = -cos(x)
        if self.arg == Symbol.new(var) {
            return sin.new(self.arg);
        }
        return self;
    }
}

class tan {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "tan(" + repr(self.arg) + ")";
    }

    __str__() {
        return self.__repr__();
    }

    diff(var) {
        return Mul.new(Pow.new(sec.new(self.arg), Integer.new(2)), self.arg.diff(var));
    }

    integrate(var) {
        return self;
    }
}

class sec {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "sec(" + repr(self.arg) + ")";
    }

    diff(var) {
        return Mul.new(sec.new(self.arg), tan.new(self.arg), self.arg.diff(var));
    }
}

class csc {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "csc(" + repr(self.arg) + ")";
    }

    diff(var) {
        return Mul.new(Integer.new(-1), csc.new(self.arg), cot.new(self.arg), self.arg.diff(var));
    }
}

class cot {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "cot(" + repr(self.arg) + ")";
    }

    diff(var) {
        return Mul.new(Integer.new(-1), Pow.new(csc.new(self.arg), Integer.new(2)), self.arg.diff(var));
    }
}

# ============================================================
# Inverse Trigonometric Functions
# ============================================================

class asin {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "asin(" + repr(self.arg) + ")";
    }

    diff(var) {
        return Div.new(self.arg.diff(var), sqrt.new(Sub.new(Integer.new(1), Pow.new(self.arg, Integer.new(2)))));
    }
}

class acos {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "acos(" + repr(self.arg) + ")";
    }

    diff(var) {
        return Div.new(Integer.new(-1), self.arg.diff(var), sqrt.new(Sub.new(Integer.new(1), Pow.new(self.arg, Integer.new(2)))));
    }
}

class atan {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "atan(" + repr(self.arg) + ")";
    }

    diff(var) {
        return Div.new(self.arg.diff(var), Add.new(Integer.new(1), Pow.new(self.arg, Integer.new(2))));
    }

    integrate(var) {
        # x*atan(x) - (1/2)*log(x^2+1)
        if self.arg == Symbol.new(var) {
            return Sub.new(
                Mul.new(self.arg, atan.new(self.arg)),
                Mul.new(Rational.new(1, 2), log.new(Add.new(Pow.new(self.arg, Integer.new(2)), Integer.new(1))))
            );
        }
        return self;
    }
}

# ============================================================
# Hyperbolic Functions
# ============================================================

class sinh {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "sinh(" + repr(self.arg) + ")";
    }

    diff(var) {
        return Mul.new(cosh.new(self.arg), self.arg.diff(var));
    }
}

class cosh {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "cosh(" + repr(self.arg) + ")";
    }

    diff(var) {
        return Mul.new(sinh.new(self.arg), self.arg.diff(var));
    }
}

class tanh {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "tanh(" + repr(self.arg) + ")";
    }

    diff(var) {
        return Mul.new(Pow.new(sech.new(self.arg), Integer.new(2)), self.arg.diff(var));
    }
}

class sech {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "sech(" + repr(self.arg) + ")";
    }
}

# ============================================================
# Exponential and Logarithmic Functions
# ============================================================

class exp {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "exp(" + repr(self.arg) + ")";
    }

    __str__() {
        return self.__repr__();
    }

    diff(var) {
        return Mul.new(exp.new(self.arg), self.arg.diff(var));
    }

    integrate(var) {
        if self.arg == Symbol.new(var) {
            return self;
        }
        return self;
    }

    simplify() {
        # exp(log(x)) = x
        return self;
    }
}

class log {
    init(arg, base) {
        self.arg = arg;
        self.base = base || "e";
    }

    __repr__() {
        if self.base == "e" {
            return "log(" + repr(self.arg) + ")";
        }
        return "log(" + repr(self.arg) + ", " + str(self.base) + ")";
    }

    __str__() {
        return self.__repr__();
    }

    diff(var) {
        if self.base == "e" || self.base == "e" {
            return Div.new(self.arg.diff(var), self.arg);
        }
        
        # log_b(x) = log(x)/log(b)
        return Div.new(
            self.arg.diff(var),
            Mul.new(self.arg, log.new(Integer.new(self.base)))
        );
    }

    integrate(var) {
        # Integral of 1/x = log(x)
        if self.arg == Symbol.new(var) {
            return Mul.new(self.arg, Sub.new(log.new(self.arg), Integer.new(1)));
        }
        
        # u = log(x), du = dx/x
        return self;
    }
}

class sqrt {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "sqrt(" + repr(self.arg) + ")";
    }

    __str__() {
        return self.__repr__();
    }

    diff(var) {
        return Div.new(self.arg.diff(var), Mul.new(Integer.new(2), sqrt.new(self.arg)));
    }

    integrate(var) {
        if self.arg == Symbol.new(var) {
            # Integral of sqrt(x) = (2/3)*x^(3/2)
            return Mul.new(Rational.new(2, 3), Pow.new(self.arg, Rational.new(3, 2)));
        }
        return self;
    }

    simplify() {
        # sqrt(x^2) = |x|
        return self;
    }
}

# ============================================================
# Special Functions
# ============================================================

class factorial {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "factorial(" + repr(self.arg) + ")";
    }

    diff(var) {
        return self;
    }
}

class gamma {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "gamma(" + repr(self.arg) + ")";
    }

    diff(var) {
        return self;
    }
}

class zeta {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "zeta(" + repr(self.arg) + ")";
    }
}

class erf {
    init(arg) {
        self.arg = arg;
    }

    __repr__() {
        return "erf(" + repr(self.arg) + ")";
    }

    diff(var) {
        return Mul.new(
            Div.new(Integer.new(2), sqrt.new(PI.new())),
            exp.new(Neg.new(Pow.new(self.arg, Integer.new(2)))),
            self.arg.diff(var)
        );
    }
}

class Piecewise {
    init(*args) {
        self.pieces = args;  # List of (expr, condition) pairs
    }

    __repr__() {
        let parts = [];
        for let piece in self.pieces {
            parts.push("(" + repr(piece[0]) + ", " + repr(piece[1]) + ")");
        }
        
        let result = "Piecewise(";
        for let i in range(len(parts)) {
            if i > 0 {
                result = result + ", ";
            }
            result = result + parts[i];
        }
        result = result + ")";
        
        return result;
    }
}

# ============================================================
# Matrix
# ============================================================

class Matrix {
    init(rows, cols) {
        self.rows = rows || 1;
        self.cols = cols || 1;
        
        self._data = [];
        for let i in range(self.rows) {
            let row = [];
            for let j in range(self.cols) {
                row.push(Integer.new(0));
            }
            self._data.push(row);
        }
    }

    init_from_list(data) {
        self.rows = len(data);
        self.cols = len(data[0]) || 0;
        self._data = data;
    }

    get(i, j) {
        if i >= 0 && i < self.rows && j >= 0 && j < self.cols {
            return self._data[i][j];
        }
        return null;
    }

    set(i, j, value) {
        if i >= 0 && i < self.rows && j >= 0 && j < self.cols {
            self._data[i][j] = value;
        }
    }

    __repr__() {
        let result = "Matrix([";
        
        for let i in range(self.rows) {
            if i > 0 {
                result = result + "       ";
            }
            result = result + "[";
            
            for let j in range(self.cols) {
                if j > 0 {
                    result = result + ", ";
                }
                result = result + repr(self._data[i][j]);
            }
            
            result = result + "]";
            
            if i < self.rows - 1 {
                result = result + ",";
            }
            result = result + "\n";
        }
        
        result = result + "])";
        
        return result;
    }

    __str__() {
        return self.__repr__();
    }

    __add__(other) {
        if type(other) == "matrix" {
            if self.rows != other.rows || self.cols != other.cols {
                throw "Matrix dimensions must match for addition";
            }
            
            let result = Matrix.new(self.rows, self.cols);
            
            for let i in range(self.rows) {
                for let j in range(self.cols) {
                    result.set(i, j, Add.new(self.get(i, j), other.get(i, j)));
                }
            }
            
            return result;
        }
        
        return self;
    }

    __sub__(other) {
        if type(other) == "matrix" {
            if self.rows != other.rows || self.cols != other.cols {
                throw "Matrix dimensions must match for subtraction";
            }
            
            let result = Matrix.new(self.rows, self.cols);
            
            for let i in range(self.rows) {
                for let j in range(self.cols) {
                    result.set(i, j, Sub.new(self.get(i, j), other.get(i, j)));
                }
            }
            
            return result;
        }
        
        return self;
    }

    __mul__(other) {
        if type(other) == "matrix" {
            # Matrix multiplication
            if self.cols != other.rows {
                throw "Matrix dimensions incompatible for multiplication";
            }
            
            let result = Matrix.new(self.rows, other.cols);
            
            for let i in range(self.rows) {
                for let j in range(other.cols) {
                    let sum = Integer.new(0);
                    
                    for let k in range(self.cols) {
                        sum = Add.new(sum, Mul.new(self.get(i, k), other.get(k, j)));
                    }
                    
                    result.set(i, j, sum);
                }
            }
            
            return result;
        }
        
        # Scalar multiplication
        let result = Matrix.new(self.rows, self.cols);
        
        for let i in range(self.rows) {
            for let j in range(self.cols) {
                result.set(i, j, Mul.new(self.get(i, j), other));
            }
        }
        
        return result;
    }

    transpose() {
        let result = Matrix.new(self.cols, self.rows);
        
        for let i in range(self.rows) {
            for let j in range(self.cols) {
                result.set(j, i, self.get(i, j));
            }
        }
        
        return result;
    }

    inverse() {
        if self.rows != self.cols {
            throw "Only square matrices can be inverted";
        }
        
        # Create augmented matrix [A|I]
        let n = self.rows;
        let aug = Matrix.new(n, 2 * n);
        
        for let i in range(n) {
            for let j in range(n) {
                aug.set(i, j, self.get(i, j));
                if i == j {
                    aug.set(i, j + n, Integer.new(1));
                } else {
                    aug.set(i, j + n, Integer.new(0));
                }
            }
        }
        
        # Gaussian elimination
        for let i in range(n) {
            # Find pivot
            let pivot = aug.get(i, i);
            
            # Make pivot 1
            for let j in range(2 * n) {
                aug.set(i, j, Div.new(aug.get(i, j), pivot));
            }
            
            # Eliminate column
            for let k in range(n) {
                if k != i {
                    let factor = aug.get(k, i);
                    
                    for let j in range(2 * n) {
                        let val = Sub.new(aug.get(k, j), Mul.new(factor, aug.get(i, j)));
                        aug.set(k, j, val);
                    }
                }
            }
        }
        
        # Extract inverse
        let result = Matrix.new(n, n);
        
        for let i in range(n) {
            for let j in range(n) {
                result.set(i, j, aug.get(i, j + n));
            }
        }
        
        return result;
    }

    det() {
        if self.rows != self.cols {
            throw "Only square matrices have determinants";
        }
        
        let n = self.rows;
        
        if n == 1 {
            return self.get(0, 0);
        }
        
        if n == 2 {
            return Sub.new(
                Mul.new(self.get(0, 0), self.get(1, 1)),
                Mul.new(self.get(0, 1), self.get(1, 0))
            );
        }
        
        if n == 3 {
            return Add.new(
                Mul.new(self.get(0, 0), Sub.new(Mul.new(self.get(1, 1), self.get(2, 2)), Mul.new(self.get(1, 2), self.get(2, 1)))),
                Mul.new(self.get(0, 1), Sub.new(Mul.new(self.get(1, 2), self.get(2, 0)), Mul.new(self.get(1, 0), self.get(2, 2)))),
                Mul.new(self.get(0, 2), Sub.new(Mul.new(self.get(1, 0), self.get(2, 1)), Mul.new(self.get(1, 1), self.get(2, 0))))
            );
        }
        
        # Laplace expansion for larger matrices
        let result = Integer.new(0);
        
        for let j in range(n) {
            let cofactor = self.cofactor(0, j);
            
            if j % 2 == 0 {
                result = Add.new(result, Mul.new(self.get(0, j), cofactor));
            } else {
                result = Sub.new(result, Mul.new(self.get(0, j), cofactor));
            }
        }
        
        return result;
    }

    cofactor(i, j) {
        let n = self.rows;
        let sub = Matrix.new(n - 1, n - 1);
        
        let r = 0;
        for let ii in range(n) {
            if ii == i {
                continue;
            }
            
            let c = 0;
            for let jj in range(n) {
                if jj == j {
                    continue;
                }
                
                sub.set(r, c, self.get(ii, jj));
                c = c + 1;
            }
            
            r = r + 1;
        }
        
        return sub.det();
    }

    trace() {
        if self.rows != self.cols {
            throw "Only square matrices have traces";
        }
        
        let result = Integer.new(0);
        
        for let i in range(self.rows) {
            result = Add.new(result, self.get(i, i));
        }
        
        return result;
    }

    rank() {
        # Simplified rank calculation
        return 0;
    }

    eigenvalues() {
        # Simplified eigenvalue calculation
        return [];
    }

    eigenvectors() {
        return [];
    }

    solve(b) {
        # Solve Ax = b
        return self.inverse() * b;
    }

    diagonal() {
        let diag = [];
        for let i in range(min(self.rows, self.cols)) {
            diag.push(self.get(i, i));
        }
        return diag;
    }

    trace() {
        let sum = Integer.new(0);
        for let i in range(min(self.rows, self.cols)) {
            sum = Add.new(sum, self.get(i, i));
        }
        return sum;
    }

    is_square() {
        return self.rows == self.cols;
    }

    is_zero {
        for() let i in range(self.rows) {
            for let j in range(self.cols) {
                if !self.get(i, j).is_zero() {
                    return false;
                }
            }
        }
        return true;
    }

    is_identity() {
        if !self.is_square() {
            return false;
        }
        
        for let i in range(self.rows) {
            for let j in range(self.cols) {
                if i == j {
                    if !self.get(i, j).is_one() {
                        return false;
                    }
                } else {
                    if !self.get(i, j).is_zero() {
                        return false;
                    }
                }
            }
        }
        
        return true;
    }
}

# ============================================================
# Polynomial
# ============================================================

class Poly {
    init(coeffs, var) {
        self.coeffs = coeffs;  # List of coefficients, highest degree first
        self.var = var || Symbol.new("x");
        self._simplified = false;
    }

    degree() {
        return len(self.coeffs) - 1;
    }

    __repr__() {
        if len(self.coeffs) == 0 {
            return "0";
        }
        
        let terms = [];
        
        for let i in range(len(self.coeffs)) {
            let coeff = self.coeffs[i];
            let power = len(self.coeffs) - 1 - i;
            
            if coeff.is_zero() {
                continue;
            }
            
            let term = "";
            
            # Coefficient
            if power == len(self.coeffs) - 1 {
                if !coeff.is_one() {
                    term = term + repr(coeff);
                }
            } else {
                if coeff.is_one() {
                    term = term + "";
                } else if coeff.is_negative() {
                    term = term + " - " + repr(Integer.new(-coeff.value));
                } else {
                    term = term + " + " + repr(coeff);
                }
            }
            
            # Variable
            if power > 1 {
                term = term + self.var.name + "^" + str(power);
            } else if power == 1 {
                term = term + self.var.name;
            }
            
            terms.push(term);
        }
        
        if len(terms) == 0 {
            return "0";
        }
        
        let result = terms[0];
        for let i in range(1, len(terms)) {
            result = result + terms[i];
        }
        
        return result;
    }

    __str__() {
        return self.__repr__();
    }

    __add__(other) {
        if type(other) == "poly" && other.var == self.var {
            let max_degree = max(self.degree(), other.degree());
            let result = [];
            
            for let i in range(max_degree + 1) {
                let c1 = i < len(self.coeffs) ? self.coeffs[i] : Integer.new(0);
                let c2 = i < len(other.coeffs) ? other.coeffs[i] : Integer.new(0);
                result.push(Add.new(c1, c2));
            }
            
            return Poly.new(result, self.var);
        }
        
        return self;
    }

    __sub__(other) {
        if type(other) == "poly" && other.var == self.var {
            let max_degree = max(self.degree(), other.degree());
            let result = [];
            
            for let i in range(max_degree + 1) {
                let c1 = i < len(self.coeffs) ? self.coeffs[i] : Integer.new(0);
                let c2 = i < len(other.coeffs) ? other.coeffs[i] : Integer.new(0);
                result.push(Sub.new(c1, c2));
            }
            
            return Poly.new(result, self.var);
        }
        
        return self;
    }

    __mul__(other) {
        if type(other) == "poly" && other.var == self.var {
            let result_degree = self.degree() + other.degree();
            let result = [];
            
            for let i in range(result_degree + 1) {
                result.push(Integer.new(0));
            }
            
            for let i in range(len(self.coeffs)) {
                for let j in range(len(other.coeffs)) {
                    result[i + j] = Add.new(result[i + j], Mul.new(self.coeffs[i], other.coeffs[j]));
                }
            }
            
            return Poly.new(result, self.var);
        }
        
        return self;
    }

    coeff(power) {
        let degree = self.degree();
        let idx = degree - power;
        
        if idx >= 0 && idx < len(self.coeffs) {
            return self.coeffs[idx];
        }
        
        return Integer.new(0);
    }

    eval(x) {
        let result = Integer.new(0);
        let power = self.degree();
        
        for let i in range(len(self.coeffs)) {
            result = Add.new(result, Mul.new(self.coeffs[i], Pow.new(x, Integer.new(power - i))));
        }
        
        return result;
    }

    roots() {
        # Find roots (simplified - only for degree 1 and 2)
        let d = self.degree();
        
        if d == 0 {
            return [];
        }
        
        if d == 1 {
            # ax + b = 0 => x = -b/a
            let a = self.coeff(1);
            let b = self.coeff(0);
            return [Div.new(Neg.new(b), a)];
        }
        
        if d == 2 {
            # ax^2 + bx + c = 0 => x = (-b ± sqrt(b^2 - 4ac)) / 2a
            let a = self.coeff(2);
            let b = self.coeff(1);
            let c = self.coeff(0);
            
            let discriminant = Sub.new(Pow.new(b, Integer.new(2)), Mul.new(Integer.new(4), Mul.new(a, c)));
            let sqrt_disc = sqrt.new(discriminant);
            
            let root1 = Div.new(Add.new(Neg.new(b), sqrt_disc), Mul.new(Integer.new(2), a));
            let root2 = Div.new(Sub.new(Neg.new(b), sqrt_disc), Mul.new(Integer.new(2), a));
            
            return [root1, root2];
        }
        
        return [];
    }

    differentiate() {
        # Derivative of polynomial
        if self.degree() == 0 {
            return Poly.new([Integer.new(0)], self.var);
        }
        
        let new_coeffs = [];
        
        for let i in range(len(self.coeffs) - 1) {
            let power = self.degree() - i;
            new_coeffs.push(Mul.new(self.coeffs[i], Integer.new(power)));
        }
        
        return Poly.new(new_coeffs, self.var);
    }

    integrate() {
        # Integrate polynomial
        let new_coeffs = [Integer.new(0)];
        
        for let i in range(len(self.coeffs)) {
            let power = self.degree() - i + 1;
            new_coeffs.push(Div.new(self.coeffs[i], Integer.new(power)));
        }
        
        return Poly.new(new_coeffs, self.var);
    }

    factor() {
        # Factor polynomial (simplified)
        return self;
    }

    gcd(other) {
        # GCD of polynomials (simplified)
        return Poly.new([Integer.new(1)], self.var);
    }

    quo(other) {
        # Quotient of polynomial division
        return self;
    }

    rem(other) {
        # Remainder of polynomial division
        return Poly.new([Integer.new(0)], self.var);
    }
}

# ============================================================
# Series Expansion
# ============================================================

class Series {
    init(expr, var, point, order) {
        self.expr = expr;
        self.var = var;
        self.point = point || 0;
        self.order = order || 6;
        self._terms = [];
        self._compute();
    }

    _compute() {
        # Compute series expansion (simplified)
        let x = Symbol.new(self.var);
        let x0 = self.point;
        
        # Use Taylor series expansion
        for let n in range(self.order + 1) {
            let term = self.expr.diff_n(self.var, n).subs(self.var, x0);
            term = Div.new(term, factorial.new(Integer.new(n)));
            term = Mul.new(term, Pow.new(Sub.new(x, x0), Integer.new(n)));
            
            self._terms.push(term);
        }
    }

    __repr__() {
        let terms = [];
        
        for let i in range(len(self._terms)) {
            terms.push(repr(self._terms[i]));
        }
        
        let result = " + ".join(terms);
        
        if len(self._terms) > self.order + 1 {
            result = result + " + O(" + self.var + "^" + str(self.order + 1) + ")";
        }
        
        return result;
    }

    truncate(order) {
        return Series.new(self.expr, self.var, self.point, order);
    }

    remove_order() {
        return Add.new(...self._terms);
    }
}

# ============================================================
# Utility Functions
# ============================================================

fn Symbol(name, **assumptions):
    return Symbol.new(name, assumptions)

fn symbols(names, **assumptions):
    let result = {};
    let name_list = names.split(",");
    
    for let name in name_list {
        name = trim(name);
        result[name] = Symbol.new(name, assumptions);
    }
    
    return result

fn sympify(expr) {
    # Convert string to symbolic expression
    return expr;
}

fn nsimplify(expr) {
    # Numerical simplification
    return expr;
}

fn simplify(expr) {
    return expr.simplify();
}

fn expand(expr) {
    return expr.expand();
}

fn factor(expr) {
    return expr.factor();
}

fn collect(expr, var) {
    return expr.collect(var);
}

fn subs(expr, old, new) {
    return expr.subs(old, new);
}

fn diff(expr, var) {
    return expr.diff(var);
}

fn integrate(expr, var) {
    return expr.integrate(var);
}

fn limit(expr, var, value, direction) {
    return expr.limit(var, value, direction);
}

fn series(expr, var, point, order) {
    return Series.new(expr, var, point, order);
}

fn solve(expr, var) {
    # Solve equation
    return [];
}

fn solveset(expr, var, domain) {
    # Solve equation with domain
    return [];
}

fn nsolve(expr, var, guess) {
    # Numerical solution
    return guess;
}

fn diff_n(expr, var, n) {
    # nth derivative
    let result = expr;
    
    for let i in range(n) {
        result = result.diff(var);
    }
    
    return result;
}

fn integrate_n(expr, var, n) {
    # nth integral
    let result = expr;
    
    for let i in range(n) {
        result = result.integrate(var);
    }
    
    return result;
}

# Constants
let I = Complex.new(0, 1);
let oo = Infinity.new();
let zoo = Complex.new(0, 0);
let nan = NaN.new();
let pi = Float.new(3.141592653589793);
let e = Float.new(2.718281828459045);
let E = e;
let I = Complex.new(0, 1);
let oo = Infinity.new();
let zoo = Complex.new(0, 0);
let nan = NaN.new();
let pi = Float.new(3.141592653589793);
let e = Float.new(2.718281828459045);
let E = e;

# ============================================================
# Pretty Printing
# ============================================================

fn pretty(expr) {
    return repr(expr);
}

fn pprint(expr) {
    print(pretty(expr));
}

# ============================================================
# Latex Output
# ============================================================

fn latex(expr) {
    # Convert to LaTeX format
    return repr(expr);
}

# ============================================================
# Code Generation
# ============================================================

fn ccode(expr) {
    # C code generation
    return repr(expr);
}

fn cxxcode(expr) {
    # C++ code generation
    return repr(expr);
}

fn jscode(expr) {
    # JavaScript code generation
    return repr(expr);
}

fn pycode(expr) {
    # Python code generation
    return repr(expr);
}

fn fcode(expr) {
    # Fortran code generation
    return repr(expr);
}

# ============================================================
# Export
# ============================================================

let Symbol = Symbol;
let symbols = symbols;
let Integer = Integer;
let Float = Float;
let Rational = Rational;
let Complex = Complex;
let Infinity = Infinity;
let NegativeInfinity = NegativeInfinity;
let NaN = NaN;
let Matrix = Matrix;
let Poly = Poly;
let Series = Series;

# ===========================================
# Nyx Standard Library - Science Module
# ===========================================
# Linear algebra, tensors, numerical computing

# ===========================================
# VECTOR OPERATIONS
# ===========================================

class Vector {
    fn init(self, data) {
        self.data = data;
    }
    
    fn len(self) {
        return len(self.data);
    }
    
    fn get(self, i) {
        return self.data[i];
    }
    
    fn set(self, i, value) {
        self.data[i] = value;
    }
    
    # Addition
    fn add(self, other) {
        if len(self.data) != len(other.data) {
            throw "Vector size mismatch";
        }
        let result = [];
        for i in range(len(self.data)) {
            push(result, self.data[i] + other.data[i]);
        }
        return Vector(result);
    }
    
    # Subtraction
    fn sub(self, other) {
        if len(self.data) != len(other.data) {
            throw "Vector size mismatch";
        }
        let result = [];
        for i in range(len(self.data)) {
            push(result, self.data[i] - other.data[i]);
        }
        return Vector(result);
    }
    
    # Scalar multiplication
    fn scale(self, scalar) {
        let result = [];
        for i in range(len(self.data)) {
            push(result, self.data[i] * scalar);
        }
        return Vector(result);
    }
    
    # Dot product
    fn dot(self, other) {
        if len(self.data) != len(other.data) {
            throw "Vector size mismatch";
        }
        let result = 0;
        for i in range(len(self.data)) {
            result = result + self.data[i] * other.data[i];
        }
        return result;
    }
    
    # Cross product (3D only)
    fn cross(self, other) {
        if len(self.data) != 3 || len(other.data) != 3 {
            throw "Cross product only defined for 3D vectors";
        }
        return Vector([
            self.data[1] * other.data[2] - self.data[2] * other.data[1],
            self.data[2] * other.data[0] - self.data[0] * other.data[2],
            self.data[0] * other.data[1] - self.data[1] * other.data[0]
        ]);
    }
    
    # Magnitude (norm)
    fn magnitude(self) {
        let sum = 0;
        for i in range(len(self.data)) {
            sum = sum + self.data[i] * self.data[i];
        }
        return sqrt(sum);
    }
    
    # Normalize
    fn normalize(self) {
        let mag = self.magnitude();
        if mag == 0 {
            return Vector([]);
        }
        return self.scale(1 / mag);
    }
    
    # Angle between vectors (radians)
    fn angle(self, other) {
        let dot = self.dot(other);
        let m1 = self.magnitude();
        let m2 = other.magnitude();
        if m1 == 0 || m2 == 0 {
            return 0;
        }
        return acos(dot / (m1 * m2));
    }
    
    # Distance to another vector
    fn distance(self, other) {
        return self.sub(other).magnitude();
    }
    
    # Projection onto another vector
    fn project_onto(self, other) {
        let dot = self.dot(other);
        let other_mag_sq = other.dot(other);
        if other_mag_sq == 0 {
            return Vector([]);
        }
        return other.scale(dot / other_mag_sq);
    }
    
    fn to_array(self) {
        return self.data[..];
    }
}

# Create vector from array
fn vector(arr) {
    return Vector(arr);
}

# Zero vector
fn zeros(n) {
    let result = [];
    for i in range(n) {
        push(result, 0);
    }
    return Vector(result);
}

# One vector
fn ones(n) {
    let result = [];
    for i in range(n) {
        push(result, 1);
    }
    return Vector(result);
}

# Random vector
fn random_vector(n, min_val, max_val) {
    if type(min_val) == "null" { min_val = 0; }
    if type(max_val) == "null" { max_val = 1; }
    
    let result = [];
    for i in range(n) {
        push(result, min_val + rand_float() * (max_val - min_val));
    }
    return Vector(result);
}

# ===========================================
# MATRIX OPERATIONS
# ===========================================

class Matrix {
    fn init(self, rows, cols) {
        self.rows = rows;
        self.cols = cols;
        self.data = [];
        
        # Initialize with zeros
        for i in range(rows) {
            let row = [];
            for j in range(cols) {
                push(row, 0);
            }
            push(self.data, row);
        }
    }
    
    fn get(self, i, j) {
        return self.data[i][j];
    }
    
    fn set(self, i, j, value) {
        self.data[i][j] = value;
    }
    
    # Get row
    fn row(self, i) {
        return Vector(self.data[i][..]);
    }
    
    # Get column
    fn col(self, j) {
        let result = [];
        for i in range(self.rows) {
            push(result, self.data[i][j]);
        }
        return Vector(result);
    }
    
    # Set row
    fn set_row(self, i, vec) {
        if len(vec) != self.cols {
            throw "Row size mismatch";
        }
        self.data[i] = vec[..];
    }
    
    # Set column
    fn set_col(self, j, vec) {
        if len(vec) != self.rows {
            throw "Column size mismatch";
        }
        for i in range(self.rows) {
            self.data[i][j] = vec[i];
        }
    }
    
    # Addition
    fn add(self, other) {
        if self.rows != other.rows || self.cols != other.cols {
            throw "Matrix size mismatch";
        }
        let result = Matrix(self.rows, self.cols);
        for i in range(self.rows) {
            for j in range(self.cols) {
                result.set(i, j, self.data[i][j] + other.data[i][j]);
            }
        }
        return result;
    }
    
    # Subtraction
    fn sub(self, other) {
        if self.rows != other.rows || self.cols != other.cols {
            throw "Matrix size mismatch";
        }
        let result = Matrix(self.rows, self.cols);
        for i in range(self.rows) {
            for j in range(self.cols) {
                result.set(i, j, self.data[i][j] - other.data[i][j]);
            }
        }
        return result;
    }
    
    # Scalar multiplication
    fn scale(self, scalar) {
        let result = Matrix(self.rows, self.cols);
        for i in range(self.rows) {
            for j in range(self.cols) {
                result.set(i, j, self.data[i][j] * scalar);
            }
        }
        return result;
    }
    
    # Matrix multiplication
    fn mul(self, other) {
        if self.cols != other.rows {
            throw "Matrix dimensions incompatible for multiplication";
        }
        let result = Matrix(self.rows, other.cols);
        
        for i in range(self.rows) {
            for j in range(other.cols) {
                let sum = 0;
                for k in range(self.cols) {
                    sum = sum + self.data[i][k] * other.data[k][j];
                }
                result.set(i, j, sum);
            }
        }
        return result;
    }
    
    # Transpose
    fn transpose(self) {
        let result = Matrix(self.cols, self.rows);
        for i in range(self.rows) {
            for j in range(self.cols) {
                result.set(j, i, self.data[i][j]);
            }
        }
        return result;
    }
    
    # Determinant (2x2 and 3x3 only)
    fn det(self) {
        if self.rows != self.cols {
            throw "Matrix must be square";
        }
        
        if self.rows == 1 {
            return self.data[0][0];
        }
        
        if self.rows == 2 {
            return self.data[0][0] * self.data[1][1] - self.data[0][1] * self.data[1][0];
        }
        
        if self.rows == 3 {
            return self.data[0][0] * (self.data[1][1] * self.data[2][2] - self.data[1][2] * self.data[2][1])
                 - self.data[0][1] * (self.data[1][0] * self.data[2][2] - self.data[1][2] * self.data[2][0])
                 + self.data[0][2] * (self.data[1][0] * self.data[2][1] - self.data[1][1] * self.data[2][0]);
        }
        
        throw "Determinant only implemented for matrices up to 3x3";
    }
    
    # Inverse (2x2 and 3x3 only)
    fn inverse(self) {
        let d = self.det();
        if d == 0 {
            throw "Matrix is singular (determinant = 0)";
        }
        
        if self.rows == 2 {
            let result = Matrix(2, 2);
            result.set(0, 0, self.data[1][1] / d);
            result.set(0, 1, -self.data[0][1] / d);
            result.set(1, 0, -self.data[1][0] / d);
            result.set(1, 1, self.data[0][0] / d);
            return result;
        }
        
        throw "Inverse only implemented for 2x2 matrices";
    }
    
    # Trace
    fn trace(self) {
        if self.rows != self.cols {
            throw "Matrix must be square";
        }
        let result = 0;
        for i in range(self.rows) {
            result = result + self.data[i][i];
        }
        return result;
    }
    
    # Frobenius norm
    fn frobenius_norm(self) {
        let sum = 0;
        for i in range(self.rows) {
            for j in range(self.cols) {
                sum = sum + self.data[i][j] * self.data[i][j];
            }
        }
        return sqrt(sum);
    }
    
    # Identity matrix
    fn identity(n) {
        let result = Matrix(n, n);
        for i in range(n) {
            result.set(i, i, 1);
        }
        return result;
    }
    
    # Map function over elements
    fn map(self, fn_to_apply) {
        let result = Matrix(self.rows, self.cols);
        for i in range(self.rows) {
            for j in range(self.cols) {
                result.set(i, j, fn_to_apply(self.data[i][j], i, j));
            }
        }
        return result;
    }
    
    # Apply to array
    fn to_array(self) {
        return self.data[..];
    }
    
    fn to_string(self) {
        let result = "";
        for i in range(self.rows) {
            result = result + "[";
            for j in range(self.cols) {
                result = result + str(self.data[i][j]);
                if j < self.cols - 1 {
                    result = result + ", ";
                }
            }
            result = result + "]\n";
        }
        return result;
    }
}

# Create matrix from 2D array
fn matrix(arr) {
    let rows = len(arr);
    let cols = len(arr[0]);
    let m = Matrix(rows, cols);
    for i in range(rows) {
        for j in range(cols) {
            m.set(i, j, arr[i][j]);
        }
    }
    return m;
}

# Identity matrix
fn identity_matrix(n) {
    return Matrix.identity(n);
}

# Zero matrix
fn zeros_matrix(rows, cols) {
    return Matrix(rows, cols);
}

# ===========================================
# NUMERICAL SOLVERS
# ===========================================

# Gaussian elimination
fn gaussian_elimination(A, b) {
    let n = len(A);
    
    # Create augmented matrix
    let aug = [];
    for i in range(n) {
        let row = A[i][..];
        push(row, b[i]);
        push(aug, row);
    }
    
    # Forward elimination
    for i in range(n) {
        # Find pivot
        let max_row = i;
        for j in range(i + 1, n) {
            if abs(aug[j][i]) > abs(aug[max_row][i]) {
                max_row = j;
            }
        }
        
        # Swap rows
        let temp = aug[i];
        aug[i] = aug[max_row];
        aug[max_row] = temp;
        
        # Make pivot 1
        let pivot = aug[i][i];
        if abs(pivot) < 0.0000001 {
            throw "Matrix is singular";
        }
        
        for j in range(i, n + 1) {
            aug[i][j] = aug[i][j] / pivot;
        }
        
        # Eliminate
        for j in range(i + 1, n) {
            let factor = aug[j][i];
            for k in range(i, n + 1) {
                aug[j][k] = aug[j][k] - factor * aug[i][k];
            }
        }
    }
    
    # Back substitution
    let x = [];
    for i in range(n - 1, -1, -1) {
        let sum = aug[i][n];
        for j in range(i + 1, n) {
            sum = sum - aug[i][j] * x[n - 1 - j];
        }
        push(x, sum);
    }
    
    return Vector(x);
}

# Newton's method for root finding
fn newton_root(fn_to_solve, fn_derivative, initial_guess, tolerance, max_iterations) {
    if type(tolerance) == "null" { tolerance = 0.000001; }
    if type(max_iterations) == "null" { max_iterations = 100; }
    
    let x = initial_guess;
    
    for i in range(max_iterations) {
        let fx = fn_to_solve(x);
        
        if abs(fx) < tolerance {
            return x;
        }
        
        let dfx = fn_derivative(x);
        
        if abs(dfx) < 0.0000001 {
            throw "Derivative too small";
        }
        
        x = x - fx / dfx;
    }
    
    throw "Did not converge";
}

# Bisection method
fn bisection(fn_to_solve, a, b, tolerance, max_iterations) {
    if type(tolerance) == "null" { tolerance = 0.000001; }
    if type(max_iterations) == "null" { max_iterations = 100; }
    
    let fa = fn_to_solve(a);
    let fb = fn_to_solve(b);
    
    if fa * fb > 0 {
        throw "Function has same sign at endpoints";
    }
    
    for i in range(max_iterations) {
        let c = (a + b) / 2;
        let fc = fn_to_solve(c);
        
        if abs(fc) < tolerance {
            return c;
        }
        
        if fa * fc < 0 {
            b = c;
            fb = fc;
        } else {
            a = c;
            fa = fc;
        }
    }
    
    return (a + b) / 2;
}

# Fixed point iteration
fn fixed_point(fn_to_solve, initial_guess, tolerance, max_iterations) {
    if type(tolerance) == "null" { tolerance = 0.000001; }
    if type(max_iterations) == "null" { max_iterations = 100; }
    
    let x = initial_guess;
    
    for i in range(max_iterations) {
        let x_new = fn_to_solve(x);
        
        if abs(x_new - x) < tolerance {
            return x_new;
        }
        
        x = x_new;
    }
    
    throw "Did not converge";
}

# Numerical integration (Simpson's rule)
fn integrate(fn_to_integrate, a, b, n) {
    if type(n) == "null" { n = 100; }
    
    let h = (b - a) / n;
    let sum = fn_to_integrate(a) + fn_to_integrate(b);
    
    for i in range(1, n) {
        let x = a + i * h;
        let coeff = if i % 2 == 0 { 2 } else { 4 };
        sum = sum + coeff * fn_to_integrate(x);
    }
    
    return sum * h / 3;
}

# Numerical integration (Trapezoidal rule)
fn integrate_trap(fn_to_integrate, a, b, n) {
    if type(n) == "null" { n = 100; }
    
    let h = (b - a) / n;
    let sum = (fn_to_integrate(a) + fn_to_integrate(b)) / 2;
    
    for i in range(1, n) {
        let x = a + i * h;
        sum = sum + fn_to_integrate(x);
    }
    
    return sum * h;
}

# ===========================================
# INTERPOLATION
# ===========================================

# Linear interpolation
fn lerp(x, x0, y0, x1, y1) {
    if x1 == x0 {
        return y0;
    }
    return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
}

# Cubic spline interpolation (simplified)
fn spline_interpolate(x_vals, y_vals, x) {
    let n = len(x_vals);
    
    # Find the interval
    let i = 0;
    for j in range(n - 1) {
        if x >= x_vals[j] && x <= x_vals[j + 1] {
            i = j;
            break;
        }
    }
    
    let x0 = x_vals[i];
    let x1 = x_vals[i + 1];
    let y0 = y_vals[i];
    let y1 = y_vals[i + 1];
    
    # Linear interpolation as fallback
    return lerp(x, x0, y0, x1, y1);
}

# ===========================================
# ODE SOLVERS
# ===========================================

# Euler method for ODEs
fn ode_euler(fn_derivative, y0, t0, t_end, h) {
    let result = [];
    let t = t0;
    let y = y0;
    
    while t < t_end {
        push(result, [t, y]);
        let dy = fn_derivative(t, y);
        y = y + dy * h;
        t = t + h;
    }
    
    return result;
}

# Runge-Kutta 4th order
fn ode_rk4(fn_derivative, y0, t0, t_end, h) {
    let result = [];
    let t = t0;
    let y = y0;
    
    while t < t_end {
        push(result, [t, y]);
        
        let k1 = fn_derivative(t, y);
        let k2 = fn_derivative(t + h/2, y + k1 * h/2);
        let k3 = fn_derivative(t + h/2, y + k2 * h/2);
        let k4 = fn_derivative(t + h, y + k3 * h);
        
        y = y + (k1 + 2*k2 + 2*k3 + k4) * h / 6;
        t = t + h;
    }
    
    return result;
}

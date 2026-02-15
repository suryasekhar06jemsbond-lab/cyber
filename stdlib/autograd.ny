# Automatic Differentiation Library for Nyx
# Enables gradient-based optimization

module autograd

# Variable with gradient tracking
struct Variable {
    value: Float,
    grad: Float,
    requires_grad: Bool,
    children: List<Variable>,
    op: String,  # Operation that created this variable
}

# Create a new variable
fn variable(value: Float, requires_grad: Bool) -> Variable {
    Variable {
        value,
        grad: 0.0,
        requires_grad,
        children: [],
        op: "leaf"
    }
}

# Create a constant (no gradient)
fn constant(value: Float) -> Variable {
    variable(value, false)
}

# Backward pass to compute gradients
fn backward(v: Variable) {
    if !v.requires_grad {
        return
    }
    
    # Start from this node
    if v.op == "leaf" {
        v.grad = 1.0
    }
    
    # Process in topological order
    let mut visited = {}
    let mut stack = [v]
    
    while stack.len() > 0 {
        let curr = stack.pop()
        
        if visited.contains(curr) {
            continue
        }
        visited.add(curr)
        
        # Accumulate gradient from children
        for child in curr.children {
            if child.requires_grad {
                stack.push(child)
            }
        }
    }
    
    # Compute gradients recursively
    compute_grad(v)
}

# Recursive gradient computation
fn compute_grad(v: Variable) {
    match v.op {
        "leaf" => {},
        "add" => {
            # Gradient is 1 for each input
            for child in v.children {
                child.grad = child.grad + v.grad
            }
        },
        "mul" => {
            # Gradient is the other operand
            if v.children.len() == 2 {
                let a = v.children[0]
                let b = v.children[1]
                a.grad = a.grad + v.grad * b.value
                b.grad = b.grad + v.grad * a.value
            }
        },
        "sub" => {
            # Gradient is 1 for first, -1 for second
            if v.children.len() == 2 {
                v.children[0].grad = v.children[0].grad + v.grad
                v.children[1].grad = v.children[1].grad - v.grad
            }
        },
        "div" => {
            # Gradient: a/b -> a' * b - a * b' / b^2
            if v.children.len() == 2 {
                let a = v.children[0]
                let b = v.children[1]
                let b_sq = b.value * b.value
                a.grad = a.grad + v.grad / b.value
                b.grad = b.grad - v.grad * a.value / b_sq
            }
        },
        "pow" => {
            # Gradient: x^n -> n * x^(n-1)
            if v.children.len() == 1 {
                let base = v.children[0]
                let exp = v.value  # We need to track exponent separately
                base.grad = base.grad + v.grad * exp * (base.value.pow(exp - 1.0))
            }
        },
        "exp" => {
            if v.children.len() == 1 {
                let child = v.children[0]
                child.grad = child.grad + v.grad * v.value
            }
        },
        "log" => {
            if v.children.len() == 1 {
                let child = v.children[0]
                child.grad = child.grad + v.grad / child.value
            }
        },
        "sin" => {
            if v.children.len() == 1 {
                let child = v.children[0]
                child.grad = child.grad + v.grad * child.value.cos()
            }
        },
        "cos" => {
            if v.children.len() == 1 {
                let child = v.children[0]
                child.grad = child.grad - v.grad * child.value.sin()
            }
        },
        "tan" => {
            if v.children.len() == 1 {
                let child = v.children[0]
                let cos_x = child.value.cos()
                child.grad = child.grad + v.grad / (cos_x * cos_x)
            }
        },
        "sqrt" => {
            if v.children.len() == 1 {
                let child = v.children[0]
                child.grad = child.grad + v.grad / (2.0 * v.value)
            }
        },
        "relu" => {
            if v.children.len() == 1 {
                let child = v.children[0]
                if child.value > 0.0 {
                    child.grad = child.grad + v.grad
                }
            }
        },
        "sigmoid" => {
            if v.children.len() == 1 {
                let child = v.children[0]
                child.grad = child.grad + v.grad * v.value * (1.0 - v.value)
            }
        },
        "tanh" => {
            if v.children.len() == 1 {
                let child = v.children[0]
                child.grad = child.grad + v.grad * (1.0 - v.value * v.value)
            }
        },
        "softmax" => {
            # Gradient for softmax is more complex
            # d(softmax_i)/dx_j = softmax_i * (delta_ij - softmax_j)
        },
        _ => {}
    }
}

# Arithmetic operations

fn add(a: Variable, b: Variable) -> Variable {
    let result = Variable {
        value: a.value + b.value,
        grad: 0.0,
        requires_grad: a.requires_grad || b.requires_grad,
        children: [a, b],
        op: "add"
    }
    result
}

fn sub(a: Variable, b: Variable) -> Variable {
    let result = Variable {
        value: a.value - b.value,
        grad: 0.0,
        requires_grad: a.requires_grad || b.requires_grad,
        children: [a, b],
        op: "sub"
    }
    result
}

fn mul(a: Variable, b: Variable) -> Variable {
    let result = Variable {
        value: a.value * b.value,
        grad: 0.0,
        requires_grad: a.requires_grad || b.requires_grad,
        children: [a, b],
        op: "mul"
    }
    result
}

fn div(a: Variable, b: Variable) -> Variable {
    let result = Variable {
        value: a.value / b.value,
        grad: 0.0,
        requires_grad: a.requires_grad || b.requires_grad,
        children: [a, b],
        op: "div"
    }
    result
}

fn neg(a: Variable) -> Variable {
    let zero = constant(0.0)
    sub(zero, a)
}

# Power operation
fn pow(a: Variable, n: Float) -> Variable {
    let result = Variable {
        value: a.value.pow(n),
        grad: 0.0,
        requires_grad: a.requires_grad,
        children: [a],
        op: "pow"
    }
    result
}

# Exponential
fn exp(a: Variable) -> Variable {
    let result = Variable {
        value: a.value.exp(),
        grad: 0.0,
        requires_grad: a.requires_grad,
        children: [a],
        op: "exp"
    }
    result
}

# Logarithm (natural)
fn log(a: Variable) -> Variable {
    let result = Variable {
        value: a.value.ln(),
        grad: 0.0,
        requires_grad: a.requires_grad,
        children: [a],
        op: "log"
    }
    result
}

# Trigonometric functions
fn sin(a: Variable) -> Variable {
    let result = Variable {
        value: a.value.sin(),
        grad: 0.0,
        requires_grad: a.requires_grad,
        children: [a],
        op: "sin"
    }
    result
}

fn cos(a: Variable) -> Variable {
    let result = Variable {
        value: a.value.cos(),
        grad: 0.0,
        requires_grad: a.requires_grad,
        children: [a],
        op: "cos"
    }
    result
}

fn tan(a: Variable) -> Variable {
    let result = Variable {
        value: a.value.tan(),
        grad: 0.0,
        requires_grad: a.requires_grad,
        children: [a],
        op: "tan"
    }
    result
}

# Square root
fn sqrt(a: Variable) -> Variable {
    let result = Variable {
        value: a.value.sqrt(),
        grad: 0.0,
        requires_grad: a.requires_grad,
        children: [a],
        op: "sqrt"
    }
    result
}

# Activation functions
fn relu(a: Variable) -> Variable {
    let result = Variable {
        value: if a.value > 0.0 { a.value } else { 0.0 },
        grad: 0.0,
        requires_grad: a.requires_grad,
        children: [a],
        op: "relu"
    }
    result
}

fn sigmoid(a: Variable) -> Variable {
    let result = Variable {
        value: 1.0 / (1.0 + (-a.value).exp()),
        grad: 0.0,
        requires_grad: a.requires_grad,
        children: [a],
        op: "sigmoid"
    }
    result
}

fn tanh(a: Variable) -> Variable {
    let result = Variable {
        value: a.value.tanh(),
        grad: 0.0,
        requires_grad: a.requires_grad,
        children: [a],
        op: "tanh"
    }
    result
}

# Softmax
fn softmax(x: List<Variable>) -> Variable {
    # Find max for numerical stability
    let mut max_val = x[0].value
    for v in x {
        if v.value > max_val {
            max_val = v.value
        }
    }
    
    # Compute exp
    let mut exp_sum = 0.0
    for v in x {
        exp_sum = exp_sum + (v.value - max_val).exp()
    }
    
    # Create result
    let result = Variable {
        value: (x[0].value - max_val).exp() / exp_sum,
        grad: 0.0,
        requires_grad: x.iter().any(|v| v.requires_grad),
        children: x,
        op: "softmax"
    }
    result
}

# Sum operation
fn sum(xs: List<Variable>) -> Variable {
    let total = xs.iter().map(|v| v.value).sum()
    let result = Variable {
        value: total,
        grad: 0.0,
        requires_grad: xs.iter().any(|v| v.requires_grad),
        children: xs,
        op: "sum"
    }
    result
}

# Mean operation
fn mean(xs: List<Variable>) -> Variable {
    let count = xs.len() as Float
    let total = sum(xs)
    div(total, constant(count))
}

# Matrix operations for neural networks

# Matrix-vector multiplication
fn matmul(a: List<List<Variable>>, b: List<Variable>) -> List<Variable> {
    let rows = a.len()
    let mut result = []
    
    for i in 0..rows {
        let mut sum_var = constant(0.0)
        for j in 0..b.len() {
            sum_var = add(sum_var, mul(a[i][j], b[j]))
        }
        result.push(sum_var)
    }
    
    result
}

# Transpose
fn transpose(a: List<List<Variable>>) -> List<List<Variable>> {
    let rows = a.len()
    let cols = if rows > 0 { a[0].len() } else { 0 }
    
    let mut result = List::filled(cols, |_| List::filled(rows, constant(0.0)))
    
    for i in 0..rows {
        for j in 0..cols {
            result[j][i] = a[i][j]
        }
    }
    
    result
}

# Flatten
fn flatten(a: List<List<Variable>>) -> List<Variable> {
    let mut result = []
    for row in a {
        for v in row {
            result.push(v)
        }
    }
    result
}

# Reshape
fn reshape(a: List<Variable>, rows: Int, cols: Int) -> List<List<Variable>> {
    if a.len() != rows * cols {
        panic("Size mismatch")
    }
    
    let mut result = List::filled(rows, |_| List::filled(cols, constant(0.0)))
    let mut idx = 0
    
    for i in 0..rows {
        for j in 0..cols {
            result[i][j] = a[idx]
            idx = idx + 1
        }
    }
    
    result
}

# Concatenate
fn concat(xs: List<List<Variable>>, axis: Int) -> List<List<Variable>> {
    if axis == 0 {
        # Vertical concatenation
        let mut result = []
        for x in xs {
            for row in x {
                result.push(row)
            }
        }
        result
    } else {
        # Horizontal
        if xs.len() == 0 {
            return []
        }
        let mut result = List::filled(xs[0].len(), |_| [])
        for x in xs {
            for (i, v) in x.enumerate() {
                result[i].push(v)
            }
        }
        result
    }
}

# Neural network layer
struct Linear {
    weights: List<List<Variable>>,
    bias: List<Variable>,
}

fn linear_new(input_size: Int, output_size: Int) -> Linear {
    # Xavier initialization
    let scale = (2.0 / (input_size + output_size) as Float).sqrt()
    
    let mut weights = []
    for i in 0..output_size {
        let mut row = []
        for j in 0..input_size {
            # Random in [-scale, scale]
            let val = (rand_float() * 2.0 - 1.0) * scale
            row.push(variable(val, true))
        }
        weights.push(row)
    }
    
    let bias = List::range(0, output_size).map(|_| variable(0.0, true))
    
    Linear { weights, bias }
}

fn linear_forward(layer: Linear, x: List<Variable>) -> List<Variable> {
    # y = Wx + b
    let wx = matmul(layer.weights, x)
    
    # Add bias
    wx.enumerate().map(|(i, v)| add(v, layer.bias[i]))
}

# Simple random number generator
fn rand_float() -> Float {
    # Simple LCG
    let seed = 12345
    ((seed * 1103515245 + 12345) % 2147483648) as Float / 2147483648.0
}

# Compute gradients for a function
fn grad(f: fn(Variable) -> Variable, x: List<Float>) -> List<Float> {
    # Create variables
    let vars = x.map(|v| variable(v, true))
    
    # Forward pass
    let result = f(vars[0])
    
    # Backward pass
    backward(result)
    
    # Extract gradients
    vars.map(|v| v.grad)
}

# Jacobian-vector product
fn jvp(f: fn(Variable) -> Variable, x: Variable, v: Variable) -> Variable {
    # First forward pass
    let y = f(x)
    
    # Set gradient of output
    y.grad = v.value
    
    # Backward
    compute_grad(y)
    
    # Return gradient w.r.t. input
    x.grad = x.grad * v.value
    x.grad
}

# Hessian-vector product
fn hvp(f: fn(Variable) -> Variable, x: Variable, v: Variable) -> Variable {
    # First compute first derivative
    let y = f(x)
    y.grad = 1.0
    compute_grad(y)
    
    # Now compute second derivative
    let x2 = variable(x.value, true)
    x2.grad = x.grad * v.value
    
    # Backward again
    compute_grad(x2)
    
    variable(x2.grad, false)
}

# Export
export {
    Variable,
    variable, constant,
    backward, compute_grad,
    add, sub, mul, div, neg,
    pow, exp, log, sin, cos, tan, sqrt,
    relu, sigmoid, tanh, softmax,
    sum, mean, matmul, transpose, flatten, reshape, concat,
    Linear, linear_new, linear_forward,
    grad, jvp, hvp
}

# ===========================================
# Nyx Standard Library - Tensor Module (EXTENDED)
# ===========================================
# Comprehensive tensor operations and multi-dimensional array support
# Including: tensor creation, manipulation, broadcasting, mathematical ops,
# linear algebra, slicing, reshaping, statistical operations, and more

# ===========================================
# TENSOR CORE
# ===========================================

# Tensor class for multi-dimensional arrays
class Tensor {
    fn init(self, data, dtype = "float64", requires_grad = false) {
        self.data = data;
        self.dtype = dtype;
        self.requires_grad = requires_grad;
        self.grad = null;
        self.shape = _compute_shape(data);
        self.ndim = len(self.shape);
        self.strides = _compute_strides(self.shape);
    }
    
    fn clone(self) {
        let new_data = _deep_copy(self.data);
        let t = Tensor(new_data, self.dtype, self.requires_grad);
        return t;
    }
    
    fn to_list(self) {
        return _deep_copy(self.data);
    }
    
    fn print(self) {
        print("Tensor(shape=" + str(self.shape) + ", dtype=" + self.dtype + ")");
        _print_tensor(self.data, 0);
        return self;
    }
}

# Compute shape of nested array
fn _compute_shape(data) {
    if !is_array(data) {
        return [];
    }
    if len(data) == 0 {
        return [0];
    }
    let shape = [len(data)];
    if is_array(data[0]) {
        let inner_shape = _compute_shape(data[0]);
        for i in range(len(inner_shape)) {
            push(shape, inner_shape[i]);
        }
    }
    return shape;
}

# Compute strides for efficient access
fn _compute_strides(shape) {
    let strides = [];
    let acc = 1;
    for i in range(len(shape) - 1, -1, -1) {
        insert(strides, 0, acc);
        acc = acc * shape[i];
    }
    return strides;
}

# Deep copy nested array
fn _deep_copy(data) {
    if !is_array(data) {
        return data;
    }
    let result = [];
    for i in range(len(data)) {
        push(result, _deep_copy(data[i]));
    }
    return result;
}

# Print tensor data recursively
fn _print_tensor(data, indent) {
    let prefix = "";
    for i in range(indent) {
        prefix = prefix + "  ";
    }
    if !is_array(data) {
        print(prefix + str(data));
    } else if len(data) > 0 && is_array(data[0]) {
        print(prefix + "[");
        for i in range(len(data)) {
            _print_tensor(data[i], indent + 1);
        }
        print(prefix + "]");
    } else {
        print(prefix + "[" + _array_to_string(data) + "]");
    }
}

fn _array_to_string(arr) {
    let s = "";
    for i in range(len(arr)) {
        if i > 0 {
            s = s + ", ";
        }
        s = s + str(arr[i]);
    }
    return s;
}

# ===========================================
# TENSOR CREATION FUNCTIONS
# ===========================================

# Create tensor from data
fn tensor(data, dtype = "float64", requires_grad = false) {
    return Tensor(data, dtype, requires_grad);
}

# Create tensor of zeros
fn zeros(shape, dtype = "float64", requires_grad = false) {
    let data = _create_zeros(shape);
    return Tensor(data, dtype, requires_grad);
}

fn _create_zeros(shape) {
    if len(shape) == 0 {
        return 0.0;
    }
    let arr = [];
    for i in range(shape[0]) {
        if len(shape) > 1 {
            push(arr, _create_zeros(slice(shape, 1, len(shape))));
        } else {
            push(arr, 0.0);
        }
    }
    return arr;
}

# Create tensor of ones
fn ones(shape, dtype = "float64", requires_grad = false) {
    let data = _create_ones(shape);
    return Tensor(data, dtype, requires_grad);
}

fn _create_ones(shape) {
    if len(shape) == 0 {
        return 1.0;
    }
    let arr = [];
    for i in range(shape[0]) {
        if len(shape) > 1 {
            push(arr, _create_ones(slice(shape, 1, len(shape))));
        } else {
            push(arr, 1.0);
        }
    }
    return arr;
}

# Create tensor with a constant value
fn full(shape, value, dtype = "float64", requires_grad = false) {
    let data = _create_full(shape, value);
    return Tensor(data, dtype, requires_grad);
}

fn _create_full(shape, value) {
    if len(shape) == 0 {
        return value;
    }
    let arr = [];
    for i in range(shape[0]) {
        if len(shape) > 1 {
            push(arr, _create_full(slice(shape, 1, len(shape)), value));
        } else {
            push(arr, value);
        }
    }
    return arr;
}

# Create identity matrix
fn eye(n, dtype = "float64", requires_grad = false) {
    let data = [];
    for i in range(n) {
        let row = [];
        for j in range(n) {
            if i == j {
                push(row, 1.0);
            } else {
                push(row, 0.0);
            }
        }
        push(data, row);
    }
    return Tensor(data, dtype, requires_grad);
}

# Create diagonal tensor
fn diag(v, dtype = "float64", requires_grad = false) {
    let n = len(v);
    let data = [];
    for i in range(n) {
        let row = [];
        for j in range(n) {
            if i == j {
                push(row, v[i]);
            } else {
                push(row, 0.0);
            }
        }
        push(data, row);
    }
    return Tensor(data, dtype, requires_grad);
}

# Create range tensor
fn arange(start, end, step = 1, dtype = "float64", requires_grad = false) {
    let data = [];
    let i = start;
    while i < end {
        push(data, float(i));
        i = i + step;
    }
    return Tensor(data, dtype, requires_grad);
}

# Create evenly spaced tensor
fn linspace(start, end, num = 50, dtype = "float64", requires_grad = false) {
    if num <= 1 {
        return Tensor([start], dtype, requires_grad);
    }
    let step = (end - start) / (num - 1);
    let data = [];
    for i in range(num) {
        push(data, start + i * step);
    }
    return Tensor(data, dtype, requires_grad);
}

# Create log spaced tensor
fn logspace(start, end, num = 50, base = 10.0, dtype = "float64", requires_grad = false) {
    let data = [];
    let step = (end - start) / (num - 1);
    for i in range(num) {
        let val = pow(base, start + i * step);
        push(data, val);
    }
    return Tensor(data, dtype, requires_grad);
}

# Create random uniform tensor
fn rand(shape, dtype = "float64", requires_grad = false) {
    let data = _create_random(shape);
    return Tensor(data, dtype, requires_grad);
}

fn _create_random(shape) {
    if len(shape) == 0 {
        return rand();
    }
    let arr = [];
    for i in range(shape[0]) {
        if len(shape) > 1 {
            push(arr, _create_random(slice(shape, 1, len(shape))));
        } else {
            push(arr, rand());
        }
    }
    return arr;
}

# Create random normal tensor
fn randn(shape, mean = 0.0, std = 1.0, dtype = "float64", requires_grad = false) {
    let data = _create_randn(shape, mean, std);
    return Tensor(data, dtype, requires_grad);
}

fn _create_randn(shape, mean, std) {
    if len(shape) == 0 {
        return _randn_single(mean, std);
    }
    let arr = [];
    for i in range(shape[0]) {
        if len(shape) > 1 {
            push(arr, _create_randn(slice(shape, 1, len(shape)), mean, std));
        } else {
            push(arr, _randn_single(mean, std));
        }
    }
    return arr;
}

fn _randn_single(mean, std) {
    # Box-Muller transform
    let u1 = rand();
    while u1 == 0.0 {
        u1 = rand();
    }
    let u2 = rand();
    let z0 = sqrt(-2.0 * log(u1)) * cos(6.28318530718 * u2);
    return z0 * std + mean;
}

# Create random integer tensor
fn randint(low, high, shape, dtype = "int32", requires_grad = false) {
    let data = _create_randint(shape, low, high);
    return Tensor(data, dtype, requires_grad);
}

fn _create_randint(shape, low, high) {
    if len(shape) == 0 {
        return low + int(rand() * (high - low));
    }
    let arr = [];
    for i in range(shape[0]) {
        if len(shape) > 1 {
            push(arr, _create_randint(slice(shape, 1, len(shape)), low, high));
        } else {
            push(arr, low + int(rand() * (high - low)));
        }
    }
    return arr;
}

# Create empty tensor (uninitialized)
fn empty(shape, dtype = "float64", requires_grad = false) {
    let data = _create_empty(shape);
    return Tensor(data, dtype, requires_grad);
}

fn _create_empty(shape) {
    if len(shape) == 0 {
        return 0.0;
    }
    let arr = [];
    for i in range(shape[0]) {
        if len(shape) > 1 {
            push(arr, _create_empty(slice(shape, 1, len(shape))));
        } else {
            push(arr, 0.0);
        }
    }
    return arr;
}

# ===========================================
# TENSOR MANIPULATION
# ===========================================

# Reshape tensor
fn reshape(tensor, new_shape) {
    let flat = _flatten(tensor.data);
    let data = _reshape_helper(flat, new_shape);
    return Tensor(data, tensor.dtype, tensor.requires_grad);
}

fn _flatten(data) {
    if !is_array(data) {
        return [data];
    }
    let result = [];
    for i in range(len(data)) {
        let inner = _flatten(data[i]);
        for j in range(len(inner)) {
            push(result, inner[j]);
        }
    }
    return result;
}

fn _reshape_helper(flat, shape) {
    if len(shape) == 0 {
        return flat[0];
    }
    let total = 1;
    for i in range(len(shape)) {
        total = total * shape[i];
    }
    if total != len(flat) {
        throw "Cannot reshape: size mismatch";
    }
    return _reshape_recursive(flat, shape, 0);
}

fn _reshape_recursive(flat, shape, index) {
    if len(shape) == 0 {
        return flat[index];
    }
    let arr = [];
    for i in range(shape[0]) {
        if len(shape) > 1 {
            push(arr, _reshape_recursive(flat, slice(shape, 1, len(shape)), index));
        } else {
            push(arr, flat[index + i]);
        }
    }
    return arr;
}

# Transpose tensor
fn transpose(tensor, axes = null) {
    let data = _transpose(tensor.data, axes, tensor.shape);
    let new_shape = _get_transpose_shape(tensor.shape, axes);
    return Tensor(data, tensor.dtype, tensor.requires_grad);
}

fn _transpose(data, axes, shape) {
    if axes == null {
        # Default: reverse all axes
        return _reverse_dims(data);
    }
    if len(axes) == 2 {
        return _transpose_2d(data, axes[0], axes[1]);
    }
    return _transpose_nd(data, axes, shape);
}

fn _reverse_dims(data) {
    if !is_array(data) {
        return data;
    }
    let result = [];
    for i in range(len(data) - 1, -1, -1) {
        push(result, _reverse_dims(data[i]));
    }
    return result;
}

fn _transpose_2d(data, axis0, axis1) {
    # Simplified 2D transpose
    return data;
}

fn _transpose_nd(data, axes, shape) {
    return data;
}

fn _get_transpose_shape(shape, axes) {
    if axes == null {
        let new_shape = [];
        for i in range(len(shape) - 1, -1, -1) {
            push(new_shape, shape[i]);
        }
        return new_shape;
    }
    let new_shape = [];
    for i in range(len(axes)) {
        push(new_shape, shape[axes[i]]);
    }
    return new_shape;
}

# Squeeze tensor (remove dimensions of size 1)
fn squeeze(tensor, axis = null) {
    let data = _squeeze(tensor.data, tensor.shape, axis);
    let new_shape = _get_squeeze_shape(tensor.shape, axis);
    return Tensor(data, tensor.dtype, tensor.requires_grad);
}

fn _squeeze(data, shape, axis) {
    if axis == null {
        return data;
    }
    return data;
}

fn _get_squeeze_shape(shape, axis) {
    if axis == null {
        let new_shape = [];
        for i in range(len(shape)) {
            if shape[i] != 1 {
                push(new_shape, shape[i]);
            }
        }
        return new_shape;
    }
    let new_shape = [];
    for i in range(len(shape)) {
        if i != axis || shape[i] != 1 {
            push(new_shape, shape[i]);
        }
    }
    return new_shape;
}

# Unsqueeze tensor (add dimension of size 1)
fn unsqueeze(tensor, axis) {
    let data = _unsqueeze(tensor.data, axis);
    let new_shape = [];
    for i in range(len(tensor.shape)) {
        push(new_shape, tensor.shape[i]);
    }
    insert(new_shape, axis, 1);
    let t = Tensor(data, tensor.dtype, tensor.requires_grad);
    t.shape = new_shape;
    return t;
}

fn _unsqueeze(data, axis) {
    return data;
}

# Concatenate tensors
fn cat(tensors, axis = 0) {
    let data_arr = [];
    for i in range(len(tensors)) {
        push(data_arr, tensors[i].data);
    }
    let data = _concatenate(data_arr, axis);
    return Tensor(data, tensors[0].dtype, tensors[0].requires_grad);
}

fn _concatenate(arrays, axis) {
    if axis == 0 {
        let result = [];
        for i in range(len(arrays)) {
            for j in range(len(arrays[i])) {
                push(result, arrays[i][j]);
            }
        }
        return result;
    }
    return arrays[0];
}

# Stack tensors
fn stack(tensors, axis = 0) {
    let data_arr = [];
    for i in range(len(tensors)) {
        push(data_arr, tensors[i].data);
    }
    let data = _stack(data_arr, axis);
    return Tensor(data, tensors[0].dtype, tensors[0].requires_grad);
}

fn _stack(arrays, axis) {
    return arrays;
}

# Split tensor
fn split(tensor, sections, axis = 0) {
    let result = [];
    let data = tensor.data;
    if axis == 0 {
        let idx = 0;
        for i in range(len(sections)) {
            let part = [];
            for j in range(sections[i]) {
                if idx < len(data) {
                    push(part, data[idx]);
                    idx = idx + 1;
                }
            }
            push(result, Tensor(part, tensor.dtype, tensor.requires_grad));
        }
    }
    return result;
}

# Tile tensor
fn tile(tensor, reps) {
    let data = _tile(tensor.data, reps);
    let new_shape = [];
    for i in range(len(tensor.shape)) {
        push(new_shape, tensor.shape[i] * reps[i]);
    }
    return Tensor(data, tensor.dtype, tensor.requires_grad);
}

fn _tile(data, reps) {
    if len(reps) == 0 {
        return data;
    }
    let result = [];
    for i in range(reps[0]) {
        if len(reps) > 1 {
            push(result, _tile(data, slice(reps, 1, len(reps))));
        } else {
            push(result, data);
        }
    }
    return result;
}

# Repeat tensor elements
fn repeat(tensor, repeats) {
    let flat = _flatten(tensor.data);
    let data = _repeat(flat, repeats);
    let new_shape = [];
    for i in range(len(tensor.shape)) {
        push(new_shape, tensor.shape[i] * repeats[i]);
    }
    return Tensor(data, tensor.dtype, tensor.requires_grad);
}

fn _repeat(flat, repeats) {
    let result = [];
    for i in range(len(flat)) {
        for j in range(repeats[0]) {
            push(result, flat[i]);
        }
    }
    return result;
}

# Flip tensor
fn flip(tensor, dims) {
    let data = _flip(tensor.data, dims);
    return Tensor(data, tensor.dtype, tensor.requires_grad);
}

fn _flip(data, dims) {
    if len(dims) == 0 {
        return data;
    }
    if dims[0] == 0 {
        let result = [];
        for i in range(len(data) - 1, -1, -1) {
            if len(dims) > 1 {
                push(result, _flip(data[i], slice(dims, 1, len(dims))));
            } else {
                push(result, data[i]);
            }
        }
        return result;
    }
    return data;
}

# Roll tensor
fn roll(tensor, shifts, dims = null) {
    return tensor.clone();
}

# Swap axes
fn swapaxes(tensor, axis0, axis1) {
    let axes = [];
    for i in range(tensor.ndim) {
        if i == axis0 {
            push(axes, axis1);
        } else if i == axis1 {
            push(axes, axis0);
        } else {
            push(axes, i);
        }
    }
    return transpose(tensor, axes);
}

# Move axis
fn moveaxis(tensor, source, destination) {
    return tensor.clone();
}

# ===========================================
# INDEXING AND SLICING
# ===========================================

# Get item
fn getitem(tensor, indices) {
    let data = _getitem(tensor.data, indices);
    return Tensor(data, tensor.dtype, tensor.requires_grad);
}

fn _getitem(data, indices) {
    if !is_array(indices) {
        indices = [indices];
    }
    let result = data;
    for i in range(len(indices)) {
        if indices[i] != null {
            if indices[i] < 0 {
                indices[i] = len(result) + indices[i];
            }
            result = result[indices[i]];
        }
    }
    return result;
}

# Set item
fn setitem(tensor, indices, value) {
    let data = _setitem(tensor.data, indices, value);
    return Tensor(data, tensor.dtype, tensor.requires_grad);
}

fn _setitem(data, indices, value) {
    # Simplified implementation
    return data;
}

# Slice tensor
fn slice_tensor(tensor, start, end, step = null) {
    return tensor.clone();
}

# Masked selection
fn mask_select(tensor, mask) {
    let flat = _flatten(tensor.data);
    let result = [];
    for i in range(len(flat)) {
        if mask[i] {
            push(result, flat[i]);
        }
    }
    return Tensor(result, tensor.dtype, tensor.requires_grad);
}

# Where operation
fn where(condition, x, y) {
    if !is_array(x) {
        x = [x];
    }
    if !is_array(y) {
        y = [y];
    }
    let result = [];
    for i in range(len(condition)) {
        if condition[i] {
            push(result, x[i % len(x)]);
        } else {
            push(result, y[i % len(y)]);
        }
    }
    return Tensor(result, "float64", false);
}

# ===========================================
# MATHEMATICAL OPERATIONS
# ===========================================

# Element-wise add
fn add(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return a + b; });
    return Tensor(data, "float64", tensor1.requires_grad or tensor2.requires_grad);
}

# Element-wise subtract
fn sub(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return a - b; });
    return Tensor(data, "float64", tensor1.requires_grad or tensor2.requires_grad);
}

# Element-wise multiply
fn mul(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return a * b; });
    return Tensor(data, "float64", tensor1.requires_grad or tensor2.requires_grad);
}

# Element-wise divide
fn div(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return a / b; });
    return Tensor(data, "float64", tensor1.requires_grad or tensor2.requires_grad);
}

# Element-wise power
fn pow(tensor, exponent) {
    let data = _map(tensor.data, fn(a) { return pow(a, exponent); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Element-wise modulo
fn mod(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return a % b; });
    return Tensor(data, "float64", tensor1.requires_grad or tensor2.requires_grad);
}

# Floor division
fn floor_div(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return int(a / b); });
    return Tensor(data, "int32", tensor1.requires_grad or tensor2.requires_grad);
}

# Element-wise operations helper
fn _element_wise(data1, data2, op) {
    if !is_array(data1) && !is_array(data2) {
        return op(data1, data2);
    }
    if is_array(data1) && is_array(data2) {
        if len(data1) != len(data2) {
            throw "Shape mismatch in element-wise operation";
        }
        let result = [];
        for i in range(len(data1)) {
            push(result, _element_wise(data1[i], data2[i], op));
        }
        return result;
    }
    if is_array(data1) {
        let result = [];
        for i in range(len(data1)) {
            push(result, op(data1[i], data2));
        }
        return result;
    }
    let result = [];
    for i in range(len(data2)) {
        push(result, op(data1, data2[i]));
    }
    return result;
}

# Map function over tensor
fn _map(data, fn) {
    if !is_array(data) {
        return fn(data);
    }
    let result = [];
    for i in range(len(data)) {
        push(result, _map(data[i], fn));
    }
    return result;
}

# Element-wise negate
fn neg(tensor) {
    let data = _map(tensor.data, fn(a) { return -a; });
    return Tensor(data, tensor.dtype, tensor.requires_grad);
}

# Absolute value
fn abs(tensor) {
    let data = _map(tensor.data, fn(a) { return abs(a); });
    return Tensor(data, tensor.dtype, tensor.requires_grad);
}

# Sign function
fn sign(tensor) {
    let data = _map(tensor.data, fn(a) { 
        if a > 0 { return 1; }
        if a < 0 { return -1; }
        return 0;
    });
    return Tensor(data, tensor.dtype, tensor.requires_grad);
}

# Square root
fn sqrt(tensor) {
    let data = _map(tensor.data, fn(a) { return sqrt(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Exponential
fn exp(tensor) {
    let data = _map(tensor.data, fn(a) { return exp(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Logarithm (natural)
fn log(tensor) {
    let data = _map(tensor.data, fn(a) { return log(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Logarithm base 10
fn log10(tensor) {
    let data = _map(tensor.data, fn(a) { return log(a) / log(10.0); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Logarithm base 2
fn log2(tensor) {
    let data = _map(tensor.data, fn(a) { return log(a) / log(2.0); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Sine
fn sin(tensor) {
    let data = _map(tensor.data, fn(a) { return sin(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Cosine
fn cos(tensor) {
    let data = _map(tensor.data, fn(a) { return cos(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Tangent
fn tan(tensor) {
    let data = _map(tensor.data, fn(a) { return tan(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Arc sine
fn asin(tensor) {
    let data = _map(tensor.data, fn(a) { return asin(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Arc cosine
fn acos(tensor) {
    let data = _map(tensor.data, fn(a) { return acos(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Arc tangent
fn atan(tensor) {
    let data = _map(tensor.data, fn(a) { return atan(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Hyperbolic sine
fn sinh(tensor) {
    let data = _map(tensor.data, fn(a) { return sinh(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Hyperbolic cosine
fn cosh(tensor) {
    let data = _map(tensor.data, fn(a) { return cosh(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Hyperbolic tangent
fn tanh(tensor) {
    let data = _map(tensor.data, fn(a) { return tanh(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Ceiling
fn ceil(tensor) {
    let data = _map(tensor.data, fn(a) { return ceil(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Floor
fn floor(tensor) {
    let data = _map(tensor.data, fn(a)); });
    return { return floor(a Tensor(data, "float64", tensor.requires_grad);
}

# Round
fn round(tensor, decimals = 0) {
    let data = _map(tensor.data, fn(a) { return round(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Truncate
fn trunc(tensor) {
    let data = _map(tensor.data, fn(a) { 
        if a >= 0 { return floor(a); }
        return ceil(a);
    });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Clamp
fn clamp(tensor, min_val, max_val) {
    let data = _map(tensor.data, fn(a) { 
        if a < min_val { return min_val; }
        if a > max_val { return max_val; }
        return a;
    });
    return Tensor(data, tensor.dtype, tensor.requires_grad);
}

# Clip (alias for clamp)
fn clip(tensor, min_val, max_val) {
    return clamp(tensor, min_val, max_val);
}

# ===========================================
# REDUCTION OPERATIONS
# ===========================================

# Sum
fn sum(tensor, axis = null, keepdim = false) {
    let result = _sum(tensor.data, axis);
    if keepdim {
        return _keepdim(result, tensor.shape, axis);
    }
    return Tensor(result, "float64", tensor.requires_grad);
}

fn _sum(data, axis) {
    if axis == null {
        return _flatten_sum(data);
    }
    if axis == 0 {
        let result = [];
        for j in range(len(data[0])) {
            let s = 0.0;
            for i in range(len(data)) {
                s = s + data[i][j];
            }
            push(result, s);
        }
        return result;
    }
    return _flatten_sum(data);
}

fn _flatten_sum(data) {
    if !is_array(data) {
        return data;
    }
    let s = 0.0;
    for i in range(len(data)) {
        s = s + _flatten_sum(data[i]);
    }
    return s;
}

# Mean
fn mean(tensor, axis = null, keepdim = false) {
    let total = sum(tensor, axis, false);
    let count = _get_count(tensor.shape, axis);
    if axis == null {
        return div_scalar(total, count);
    }
    return div_scalar(total, float(count));
}

fn _get_count(shape, axis) {
    if axis == null {
        let c = 1;
        for i in range(len(shape)) {
            c = c * shape[i];
        }
        return c;
    }
    return shape[axis];
}

fn div_scalar(tensor, scalar) {
    let data = _map(tensor.data, fn(a) { return a / scalar; });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Product
fn prod(tensor, axis = null, keepdim = false) {
    let result = _prod(tensor.data, axis);
    if keepdim {
        return _keepdim(result, tensor.shape, axis);
    }
    return Tensor(result, "float64", tensor.requires_grad);
}

fn _prod(data, axis) {
    if axis == null {
        let p = 1.0;
        let flat = _flatten(data);
        for i in range(len(flat)) {
            p = p * flat[i];
        }
        return p;
    }
    return 1.0;
}

# Standard deviation
fn std(tensor, axis = null, keepdim = false, unbiased = true) {
    let m = mean(tensor, axis, keepdim);
    let centered = sub(tensor, m);
    let squared = mul(centered, centered);
    let var_val = var(squared, axis, keepdim, unbiased);
    return sqrt(var_val);
}

# Variance
fn var(tensor, axis = null, keepdim = false, unbiased = true) {
    let m = mean(tensor, axis, keepdim);
    let centered = sub(tensor, m);
    let squared = mul(centered, centered);
    return mean(squared, axis, keepdim);
}

# Min
fn min(tensor, axis = null, keepdim = false) {
    let result = _min(tensor.data, axis);
    if keepdim {
        return _keepdim(result, tensor.shape, axis);
    }
    return Tensor(result, tensor.dtype, tensor.requires_grad);
}

fn _min(data, axis) {
    if axis == null {
        let flat = _flatten(data);
        let m = flat[0];
        for i in range(1, len(flat)) {
            if flat[i] < m {
                m = flat[i];
            }
        }
        return m;
    }
    return data[0];
}

# Max
fn max(tensor, axis = null, keepdim = false) {
    let result = _max(tensor.data, axis);
    if keepdim {
        return _keepdim(result, tensor.shape, axis);
    }
    return Tensor(result, tensor.dtype, tensor.requires_grad);
}

fn _max(data, axis) {
    if axis == null {
        let flat = _flatten(data);
        let m = flat[0];
        for i in range(1, len(flat)) {
            if flat[i] > m {
                m = flat[i];
            }
        }
        return m;
    }
    return data[0];
}

# Argmin
fn argmin(tensor, axis = null) {
    if axis == null {
        let flat = _flatten(tensor.data);
        let min_idx = 0;
        for i in range(1, len(flat)) {
            if flat[i] < flat[min_idx] {
                min_idx = i;
            }
        }
        return min_idx;
    }
    return 0;
}

# Argmax
fn argmax(tensor, axis = null) {
    if axis == null {
        let flat = _flatten(tensor.data);
        let max_idx = 0;
        for i in range(1, len(flat)) {
            if flat[i] > flat[max_idx] {
                max_idx = i;
            }
        }
        return max_idx;
    }
    return 0;
}

# Keepdim helper
fn _keepdim(result, shape, axis) {
    if axis == null {
        return [[result]];
    }
    return result;
}

# Any
fn any(tensor, axis = null, keepdim = false) {
    let result = _any(tensor.data, axis);
    if keepdim {
        return _keepdim(result, tensor.shape, axis);
    }
    return result;
}

fn _any(data, axis) {
    if axis == null {
        let flat = _flatten(data);
        for i in range(len(flat)) {
            if flat[i] {
                return true;
            }
        }
        return false;
    }
    return false;
}

# All
fn all(tensor, axis = null, keepdim = false) {
    let result = _all(tensor.data, axis);
    if keepdim {
        return _keepdim(result, tensor.shape, axis);
    }
    return result;
}

fn _all(data, axis) {
    if axis == null {
        let flat = _flatten(data);
        for i in range(len(flat)) {
            if !flat[i] {
                return false;
            }
        }
        return true;
    }
    return true;
}

# Count non-zero
fn count_nonzero(tensor, axis = null) {
    let flat = _flatten(tensor.data);
    let count = 0;
    for i in range(len(flat)) {
        if flat[i] != 0 {
            count = count + 1;
        }
    }
    return count;
}

# ===========================================
# COMPARISON OPERATIONS
# ===========================================

# Element-wise equal
fn eq(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return a == b; });
    return Tensor(data, "bool", false);
}

# Element-wise not equal
fn ne(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return a != b; });
    return Tensor(data, "bool", false);
}

# Element-wise greater than
fn gt(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return a > b; });
    return Tensor(data, "bool", false);
}

# Element-wise greater than or equal
fn ge(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return a >= b; });
    return Tensor(data, "bool", false);
}

# Element-wise less than
fn lt(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return a < b; });
    return Tensor(data, "bool", false);
}

# Element-wise less than or equal
fn le(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return a <= b; });
    return Tensor(data, "bool", false);
}

# Is close (approximately equal)
fn isclose(tensor1, tensor2, rtol = 1e-05, atol = 1e-08) {
    let diff = abs(sub(tensor1, tensor2));
    let tolerance = atol + rtol * abs(tensor2);
    return lt(diff, tolerance);
}

# ===========================================
# LINEAR ALGEBRA
# ===========================================

# Matrix multiplication
fn matmul(tensor1, tensor2) {
    let data = _matmul(tensor1.data, tensor2.data);
    return Tensor(data, "float64", tensor1.requires_grad or tensor2.requires_grad);
}

fn _matmul(data1, data2) {
    # 2D matrix multiplication
    let rows1 = len(data1);
    let cols1 = len(data1[0]);
    let rows2 = len(data2);
    let cols2 = len(data2[0]);
    
    if cols1 != rows2 {
        throw "Matrix multiplication: shape mismatch";
    }
    
    let result = [];
    for i in range(rows1) {
        let row = [];
        for j in range(cols2) {
            let sum = 0.0;
            for k in range(cols1) {
                sum = sum + data1[i][k] * data2[k][j];
            }
            push(row, sum);
        }
        push(result, row);
    }
    return result;
}

# Dot product
fn dot(tensor1, tensor2) {
    let flat1 = _flatten(tensor1.data);
    let flat2 = _flatten(tensor2.data);
    if len(flat1) != len(flat2) {
        throw "Dot product: shape mismatch";
    }
    let result = 0.0;
    for i in range(len(flat1)) {
        result = result + flat1[i] * flat2[i];
    }
    return result;
}

# Outer product
fn outer(tensor1, tensor2) {
    let flat1 = _flatten(tensor1.data);
    let flat2 = _flatten(tensor2.data);
    let result = [];
    for i in range(len(flat1)) {
        let row = [];
        for j in range(len(flat2)) {
            push(row, flat1[i] * flat2[j]);
        }
        push(result, row);
    }
    return Tensor(result, "float64", tensor1.requires_grad or tensor2.requires_grad);
}

# Cross product
fn cross(tensor1, tensor2, axis = -1) {
    return tensor1.clone();
}

# Vector norm
fn norm(tensor, ord = 2, axis = null, keepdim = false) {
    if axis == null {
        let flat = _flatten(tensor.data);
        if ord == 2 {
            let sum = 0.0;
            for i in range(len(flat)) {
                sum = sum + flat[i] * flat[i];
            }
            return sqrt(sum);
        } else if ord == 1 {
            let sum = 0.0;
            for i in range(len(flat)) {
                sum = sum + abs(flat[i]);
            }
            return sum;
        } else if ord == inf {
            let m = abs(flat[0]);
            for i in range(1, len(flat)) {
                if abs(flat[i]) > m {
                    m = abs(flat[i]);
                }
            }
            return m;
        }
    }
    return 0.0;
}

# Matrix trace
fn trace(tensor) {
    let data = tensor.data;
    let n = min([len(data), len(data[0])]);
    let sum = 0.0;
    for i in range(n) {
        sum = sum + data[i][i];
    }
    return sum;
}

# Determinant
fn det(tensor) {
    let data = tensor.data;
    let n = len(data);
    if n == 1 {
        return data[0][0];
    }
    if n == 2 {
        return data[0][0] * data[1][1] - data[0][1] * data[1][0];
    }
    if n == 3 {
        return data[0][0] * (data[1][1] * data[2][2] - data[1][2] * data[2][1])
             - data[0][1] * (data[1][0] * data[2][2] - data[1][2] * data[2][0])
             + data[0][2] * (data[1][0] * data[2][1] - data[1][1] * data[2][0]);
    }
    return 0.0;
}

# Matrix inverse
fn inv(tensor) {
    let data = tensor.data;
    let n = len(data);
    # Create augmented matrix
    let aug = [];
    for i in range(n) {
        let row = [];
        for j in range(n) {
            push(row, data[i][j]);
        }
        for j in range(n) {
            if i == j {
                push(row, 1.0);
            } else {
                push(row, 0.0);
            }
        }
        push(aug, row);
    }
    # Gauss-Jordan elimination
    for i in range(n) {
        # Find pivot
        let pivot = aug[i][i];
        if abs(pivot) < 1e-10 {
            throw "Matrix is singular";
        }
        # Scale pivot row
        for j in range(2 * n) {
            aug[i][j] = aug[i][j] / pivot;
        }
        # Eliminate column
        for k in range(n) {
            if k != i {
                let factor = aug[k][i];
                for j in range(2 * n) {
                    aug[k][j] = aug[k][j] - factor * aug[i][j];
                }
            }
        }
    }
    # Extract inverse
    let result = [];
    for i in range(n) {
        let row = [];
        for j in range(n, 2 * n) {
            push(row, aug[i][j]);
        }
        push(result, row);
    }
    return Tensor(result, "float64", tensor.requires_grad);
}

# Matrix transpose
fn t(tensor) {
    return transpose(tensor);
}

# ===========================================
# BROADCASTING
# ===========================================

# Broadcast tensors to same shape
fn broadcast(tensor1, tensor2) {
    let shape1 = tensor1.shape;
    let shape2 = tensor2.shape;
    let new_shape = _broadcast_shape(shape1, shape2);
    let t1 = tensor1;
    let t2 = tensor2;
    if shape1 != new_shape {
        t1 = expand(t1, new_shape);
    }
    if shape2 != new_shape {
        t2 = expand(t2, new_shape);
    }
    return [t1, t2];
}

fn _broadcast_shape(shape1, shape2) {
    let len1 = len(shape1);
    let len2 = len(shape2);
    let max_len = max([len1, len2]);
    let result = [];
    for i in range(max_len) {
        let s1 = 1;
        let s2 = 1;
        if i < len1 {
            s1 = shape1[len1 - 1 - i];
        }
        if i < len2 {
            s2 = shape2[len2 - 1 - i];
        }
        if s1 != s2 && s1 != 1 && s2 != 1 {
            throw "Cannot broadcast: incompatible shapes";
        }
        push(result, max([s1, s2]));
    }
    return reverse(result);
}

# Expand tensor to new shape
fn expand(tensor, shape) {
    if tensor.shape == shape {
        return tensor.clone();
    }
    let data = _expand(tensor.data, tensor.shape, shape);
    return Tensor(data, tensor.dtype, tensor.requires_grad);
}

fn _expand(data, old_shape, new_shape) {
    return data;
}

# ===========================================
# TENSOR PROPERTIES
# ===========================================

# Get number of elements
fn numel(tensor) {
    let shape = tensor.shape;
    let n = 1;
    for i in range(len(shape)) {
        n = n * shape[i];
    }
    return n;
}

# Get element size
fn itemsize(tensor) {
    if tensor.dtype == "float64" || tensor.dtype == "int64" {
        return 8;
    }
    if tensor.dtype == "float32" || tensor.dtype == "int32" {
        return 4;
    }
    if tensor.dtype == "int16" {
        return 2;
    }
    if tensor.dtype == "int8" {
        return 1;
    }
    return 8;
}

# Get total byte size
fn nbytes(tensor) {
    return numel(tensor) * itemsize(tensor);
}

# Check if tensor is contiguous
fn is_contiguous(tensor) {
    return true;
}

# Get device
fn device(tensor) {
    return "cpu";
}

# ===========================================
# TYPE CONVERSION
# ===========================================

# Convert to float32
fn float32(tensor) {
    let data = _map(tensor.data, fn(a) { return float(a); });
    return Tensor(data, "float32", tensor.requires_grad);
}

# Convert to float64
fn float64(tensor) {
    let data = _map(tensor.data, fn(a) { return float(a); });
    return Tensor(data, "float64", tensor.requires_grad);
}

# Convert to int32
fn int32(tensor) {
    let data = _map(tensor.data, fn(a) { return int(a); });
    return Tensor(data, "int32", tensor.requires_grad);
}

# Convert to int64
fn int64(tensor) {
    let data = _map(tensor.data, fn(a) { return int(a); });
    return Tensor(data, "int64", tensor.requires_grad);
}

# Convert to bool
fn bool(tensor) {
    let data = _map(tensor.data, fn(a) { return a != 0; });
    return Tensor(data, "bool", tensor.requires_grad);
}

# Cast to type
fn cast(tensor, dtype) {
    return Tensor(tensor.data, dtype, tensor.requires_grad);
}

# ===========================================
# ADVANCED OPERATIONS
# ===========================================

# Cumulative sum
fn cumsum(tensor, axis = null) {
    let flat = _flatten(tensor.data);
    let result = [];
    let acc = 0.0;
    for i in range(len(flat)) {
        acc = acc + flat[i];
        push(result, acc);
    }
    return Tensor(result, "float64", tensor.requires_grad);
}

# Cumulative product
fn cumprod(tensor, axis = null) {
    let flat = _flatten(tensor.data);
    let result = [];
    let acc = 1.0;
    for i in range(len(flat)) {
        acc = acc * flat[i];
        push(result, acc);
    }
    return Tensor(result, "float64", tensor.requires_grad);
}

# Cumulative max
fn cummax(tensor, axis = null) {
    let flat = _flatten(tensor.data);
    let result = [];
    let m = flat[0];
    push(result, m);
    for i in range(1, len(flat)) {
        if flat[i] > m {
            m = flat[i];
        }
        push(result, m);
    }
    return Tensor(result, "float64", tensor.requires_grad);
}

# Cumulative min
fn cummin(tensor, axis = null) {
    let flat = _flatten(tensor.data);
    let result = [];
    let m = flat[0];
    push(result, m);
    for i in range(1, len(flat)) {
        if flat[i] < m {
            m = flat[i];
        }
        push(result, m);
    }
    return Tensor(result, "float64", tensor.requires_grad);
}

# Diff (discrete difference)
fn diff(tensor, axis = -1) {
    let flat = _flatten(tensor.data);
    let result = [];
    for i in range(1, len(flat)) {
        push(result, flat[i] - flat[i-1]);
    }
    return Tensor(result, "float64", tensor.requires_grad);
}

# Pad tensor
fn pad(tensor, pad_width, mode = "constant", value = 0.0) {
    return tensor.clone();
}

# Unique elements
fn unique(tensor, return_inverse = false) {
    let flat = _flatten(tensor.data);
    let seen = {};
    let result = [];
    for i in range(len(flat)) {
        if !has(seen, str(flat[i])) {
            set(seen, str(flat[i]), true);
            push(result, flat[i]);
        }
    }
    return Tensor(result, tensor.dtype, tensor.requires_grad);
}

# Sort tensor
fn sort(tensor, axis = -1, descending = false) {
    let flat = _flatten(tensor.data);
    let sorted = _quicksort(flat, descending);
    return Tensor(sorted, tensor.dtype, tensor.requires_grad);
}

fn _quicksort(arr, descending) {
    if len(arr) <= 1 {
        return arr;
    }
    let pivot = arr[0];
    let left = [];
    let right = [];
    for i in range(1, len(arr)) {
        if descending {
            if arr[i] > pivot {
                push(left, arr[i]);
            } else {
                push(right, arr[i]);
            }
        } else {
            if arr[i] < pivot {
                push(left, arr[i]);
            } else {
                push(right, arr[i]);
            }
        }
    }
    let result = [];
    for i in range(len(_quicksort(left, descending))) {
        push(result, _quicksort(left, descending)[i]);
    }
    push(result, pivot);
    for i in range(len(_quicksort(right, descending))) {
        push(result, _quicksort(right, descending)[i]);
    }
    return result;
}

# Argsort
fn argsort(tensor, axis = -1, descending = false) {
    let flat = _flatten(tensor.data);
    let indexed = [];
    for i in range(len(flat)) {
        push(indexed, [flat[i], i]);
    }
    let sorted = _quicksort_indexed(indexed, descending);
    let result = [];
    for i in range(len(sorted)) {
        push(result, sorted[i][1]);
    }
    return Tensor(result, "int64", false);
}

fn _quicksort_indexed(arr, descending) {
    if len(arr) <= 1 {
        return arr;
    }
    let pivot = arr[0];
    let left = [];
    let right = [];
    for i in range(1, len(arr)) {
        if descending {
            if arr[i][0] > pivot[0] {
                push(left, arr[i]);
            } else {
                push(right, arr[i]);
            }
        } else {
            if arr[i][0] < pivot[0] {
                push(left, arr[i]);
            } else {
                push(right, arr[i]);
            }
        }
    }
    let result = [];
    let left_sorted = _quicksort_indexed(left, descending);
    for i in range(len(left_sorted)) {
        push(result, left_sorted[i]);
    }
    push(result, pivot);
    let right_sorted = _quicksort_indexed(right, descending);
    for i in range(len(right_sorted)) {
        push(result, right_sorted[i]);
    }
    return result;
}

# Top k elements
fn topk(tensor, k, axis = -1, largest = true, sorted = true) {
    let flat = _flatten(tensor.data);
    let sorted_flat = _quicksort(flat, not largest);
    let result = [];
    for i in range(min([k, len(sorted_flat)])) {
        push(result, sorted_flat[i]);
    }
    return Tensor(result, tensor.dtype, tensor.requires_grad);
}

# ===========================================
# TENSOR FACTORY METHODS
# ===========================================

# Like functions (create tensor with same properties)
fn zeros_like(tensor) {
    return zeros(tensor.shape, tensor.dtype, tensor.requires_grad);
}

fn ones_like(tensor) {
    return ones(tensor.shape, tensor.dtype, tensor.requires_grad);
}

fn empty_like(tensor) {
    return empty(tensor.shape, tensor.dtype, tensor.requires_grad);
}

fn full_like(tensor, value) {
    return full(tensor.shape, value, tensor.dtype, tensor.requires_grad);
}

# ===========================================
# TENSOR MATH OPERATORS
# ===========================================

# Add tensor to self
fn Tensor_add(self, other) {
    if is_number(other) {
        let data = _map(self.data, fn(a) { return a + other; });
        return Tensor(data, self.dtype, self.requires_grad);
    }
    return add(self, other);
}

# Subtract from tensor
fn Tensor_sub(self, other) {
    if is_number(other) {
        let data = _map(self.data, fn(a) { return a - other; });
        return Tensor(data, self.dtype, self.requires_grad);
    }
    return sub(self, other);
}

# Multiply tensor
fn Tensor_mul(self, other) {
    if is_number(other) {
        let data = _map(self.data, fn(a) { return a * other; });
        return Tensor(data, self.dtype, self.requires_grad);
    }
    return mul(self, other);
}

# Divide tensor
fn Tensor_div(self, other) {
    if is_number(other) {
        let data = _map(self.data, fn(a) { return a / other; });
        return Tensor(data, self.dtype, self.requires_grad);
    }
    return div(self, other);
}

# Power
fn Tensor_pow(self, other) {
    if is_number(other) {
        return pow(self, other);
    }
    return pow(self, other);
}

# Negative
fn Tensor_neg(self) {
    return neg(self);
}

# Get item
fn Tensor_getitem(self, key) {
    return getitem(self, key);
}

# ===========================================
# ADVANCED TENSOR OPERATIONS
# ===========================================

# Scatter
fn scatter(tensor, axis, index, value) {
    return tensor.clone();
}

# Gather
fn gather(tensor, axis, index) {
    return tensor.clone();
}

# Non-zero indices
fn nonzero(tensor) {
    let flat = _flatten(tensor.data);
    let result = [];
    for i in range(len(flat)) {
        if flat[i] != 0 {
            push(result, i);
        }
    }
    return Tensor(result, "int64", false);
}

# Histogram
fn histogram(tensor, bins = 10, range = null) {
    let flat = _flatten(tensor.data);
    if range == null {
        let min_val = flat[0];
        let max_val = flat[0];
        for i in range(1, len(flat)) {
            if flat[i] < min_val { min_val = flat[i]; }
            if flat[i] > max_val { max_val = flat[i]; }
        }
        range = [min_val, max_val];
    }
    let width = (range[1] - range[0]) / bins;
    let counts = [];
    for i in range(bins) {
        push(counts, 0);
    }
    for i in range(len(flat)) {
        let bin_idx = int((flat[i] - range[0]) / width);
        if bin_idx >= 0 && bin_idx < bins {
            counts[bin_idx] = counts[bin_idx] + 1;
        }
    }
    return Tensor(counts, "int64", false);
}

# ===========================================
# TENSOR UTILITIES
# ===========================================

# Save tensor to file (simplified)
fn save(tensor, filename) {
    # This would be implemented with actual file I/O
    print("Saved tensor to " + filename);
}

# Load tensor from file (simplified)
fn load(filename) {
    # This would be implemented with actual file I/O
    print("Loaded tensor from " + filename);
    return zeros([1]);
}

# Print tensor info
fn info(tensor) {
    print("Tensor Info:");
    print("  Shape: " + str(tensor.shape));
    print("  Dtype: " + tensor.dtype);
    print("  Requires_grad: " + str(tensor.requires_grad));
    print("  Ndim: " + str(tensor.ndim));
    print("  Numel: " + str(numel(tensor)));
    print("  Nbytes: " + str(nbytes(tensor)));
}

# ===========================================
# COMPLEX TENSOR OPERATIONS
# ===========================================

# FFT (Fast Fourier Transform)
fn fft(tensor, n = null, axis = -1) {
    let flat = _flatten(tensor.data);
    let size = n;
    if n == null {
        size = len(flat);
    }
    let result = _fft(flat, size);
    return Tensor(result, "complex128", tensor.requires_grad);
}

fn _fft(data, n) {
    # Simplified DFT
    let result_real = [];
    let result_imag = [];
    for k in range(n) {
        let real_sum = 0.0;
        let imag_sum = 0.0;
        for t in range(min([n, len(data)])) {
            let angle = -6.28318530718 * k * t / n;
            real_sum = real_sum + data[t] * cos(angle);
            imag_sum = imag_sum + data[t] * sin(angle);
        }
        push(result_real, real_sum);
        push(result_imag, imag_sum);
    }
    return result_real;
}

# Inverse FFT
fn ifft(tensor, n = null, axis = -1) {
    return tensor.clone();
}

# Convolution
fn conv1d(tensor, kernel, stride = 1, padding = 0) {
    return tensor.clone();
}

fn conv2d(tensor, kernel, stride = 1, padding = 0) {
    return tensor.clone();
}

# Pooling
fn max_pool1d(tensor, kernel_size, stride = 1, padding = 0) {
    return tensor.clone();
}

fn max_pool2d(tensor, kernel_size, stride = 1, padding = 0) {
    return tensor.clone();
}

fn avg_pool1d(tensor, kernel_size, stride = 1, padding = 0) {
    return tensor.clone();
}

fn avg_pool2d(tensor, kernel_size, stride = 1, padding = 0) {
    return tensor.clone();
}

# ===========================================
# TENSOR GRADIENT UTILITIES
# ===========================================

# Set gradient
fn set_grad(tensor, grad) {
    if tensor.requires_grad {
        tensor.grad = grad;
    }
    return tensor;
}

# Backward pass (placeholder)
fn backward(tensor) {
    if !tensor.requires_grad {
        throw "Tensor does not require gradients";
    }
    # This would implement actual autograd
    print("Backward pass executed");
}

# Gradient of tensor
fn grad(tensor) {
    return tensor.grad;
}

# Detach tensor from computation graph
fn detach(tensor) {
    let t = tensor.clone();
    t.requires_grad = false;
    return t;
}

# ===========================================
# TENSOR COMPARISON AND LOGICAL
# ===========================================

# Logical and
fn logical_and(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return a and b; });
    return Tensor(data, "bool", false);
}

# Logical or
fn logical_or(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return a or b; });
    return Tensor(data, "bool", false);
}

# Logical xor
fn logical_xor(tensor1, tensor2) {
    let data = _element_wise(tensor1.data, tensor2.data, fn(a, b) { return (a or b) and not (a and b); });
    return Tensor(data, "bool", false);
}

# Logical not
fn logical_not(tensor) {
    let data = _map(tensor.data, fn(a) { return not a; });
    return Tensor(data, "bool", false);
}

# ===========================================
# HELPER FUNCTIONS
# ===========================================

# Check if value is a number
fn is_number(val) {
    return type(val) == "number";
}

# Reverse array
fn reverse(arr) {
    let result = [];
    for i in range(len(arr) - 1, -1, -1) {
        push(result, arr[i]);
    }
    return result;
}

# Max of two values
fn max(arr) {
    if !is_array(arr) {
        return arr;
    }
    let m = arr[0];
    for i in range(1, len(arr)) {
        if arr[i] > m {
            m = arr[i];
        }
    }
    return m;
}

# Min of two values
fn min(arr) {
    if !is_array(arr) {
        return arr;
    }
    let m = arr[0];
    for i in range(1, len(arr)) {
        if arr[i] < m {
            m = arr[i];
        }
    }
    return m;
}

# ===========================================
# EXPORTED FUNCTIONS
# ===========================================

# Module exports
let tensor_module = {
    "Tensor": Tensor,
    "tensor": tensor,
    "zeros": zeros,
    "ones": ones,
    "full": full,
    "eye": eye,
    "diag": diag,
    "arange": arange,
    "linspace": linspace,
    "logspace": logspace,
    "rand": rand,
    "randn": randn,
    "randint": randint,
    "empty": empty,
    "reshape": reshape,
    "transpose": transpose,
    "squeeze": squeeze,
    "unsqueeze": unsqueeze,
    "cat": cat,
    "stack": stack,
    "split": split,
    "tile": tile,
    "repeat": repeat,
    "flip": flip,
    "roll": roll,
    "swapaxes": swapaxes,
    "moveaxis": moveaxis,
    "getitem": getitem,
    "setitem": setitem,
    "slice_tensor": slice_tensor,
    "mask_select": mask_select,
    "where": where,
    "add": add,
    "sub": sub,
    "mul": mul,
    "div": div,
    "pow": pow,
    "mod": mod,
    "floor_div": floor_div,
    "neg": neg,
    "abs": abs,
    "sign": sign,
    "sqrt": sqrt,
    "exp": exp,
    "log": log,
    "log10": log10,
    "log2": log2,
    "sin": sin,
    "cos": cos,
    "tan": tan,
    "asin": acos,
    "atan": atan,
    "sinh": sinh,
    "cosh": cosh,
    "tanh": tanh,
    "ceil": ceil,
    "floor": floor,
    "round": round,
    "trunc": trunc,
    "clamp": clamp,
    "clip": clip,
    "sum": sum,
    "mean": mean,
    "prod": prod,
    "std": std,
    "var": var,
    "min": min,
    "max": max,
    "argmin": argmin,
    "argmax": argmax,
    "any": any,
    "all": all,
    "count_nonzero": count_nonzero,
    "eq": eq,
    "ne": ne,
    "gt": gt,
    "ge": ge,
    "lt": lt,
    "le": le,
    "isclose": isclose,
    "matmul": matmul,
    "dot": dot,
    "outer": outer,
    "cross": cross,
    "norm": norm,
    "trace": trace,
    "det": det,
    "inv": inv,
    "t": t,
    "broadcast": broadcast,
    "expand": expand,
    "numel": numel,
    "itemsize": itemsize,
    "nbytes": nbytes,
    "is_contiguous": is_contiguous,
    "device": device,
    "float32": float32,
    "float64": float64,
    "int32": int32,
    "int64": int64,
    "bool": bool,
    "cast": cast,
    "cumsum": cumsum,
    "cumprod": cumprod,
    "cummax": cummax,
    "cummin": cummin,
    "diff": diff,
    "pad": pad,
    "unique": unique,
    "sort": sort,
    "argsort": argsort,
    "topk": topk,
    "zeros_like": zeros_like,
    "ones_like": ones_like,
    "empty_like": empty_like,
    "full_like": full_like,
    "scatter": scatter,
    "gather": gather,
    "nonzero": nonzero,
    "histogram": histogram,
    "save": save,
    "load": load,
    "info": info,
    "fft": fft,
    "ifft": ifft,
    "conv1d": conv1d,
    "conv2d": conv2d,
    "max_pool1d": max_pool1d,
    "max_pool2d": max_pool2d,
    "avg_pool1d": avg_pool1d,
    "avg_pool2d": avg_pool2d,
    "set_grad": set_grad,
    "backward": backward,
    "grad": grad,
    "detach": detach,
    "logical_and": logical_and,
    "logical_or": logical_or,
    "logical_xor": logical_xor,
    "logical_not": logical_not
};

# Return module
tensor_module;

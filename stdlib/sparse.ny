# Sparse Matrix Library for Nyx
# Efficient storage and operations for sparse matrices

module sparse

# Sparse matrix formats
enum SparseFormat {
    CSR,  # Compressed Sparse Row
    CSC,  # Compressed Sparse Column
    COO,  # Coordinate List
    LIL   # List of Lists
}

# CSR Matrix representation
struct CSRMatrix {
    rows: Int,
    cols: Int,
    values: List<Float>,
    col_indices: List<Int>,
    row_ptr: List<Int>
}

# COO Matrix representation  
struct COOMatrix {
    rows: Int,
    cols: Int,
    values: List<Float>,
    row_indices: List<Int>,
    col_indices: List<Int>,
    nnz: Int  # Number of non-zeros
}

# Create CSR matrix from dense
fn csr_from_dense(data: List<List<Float>>) -> CSRMatrix {
    let rows = data.len()
    let cols = if rows > 0 { data[0].len() } else { 0 }
    
    let mut values = []
    let mut col_indices = []
    let mut row_ptr = [0]
    
    for i in 0..rows {
        let mut row_count = 0
        for j in 0..cols {
            if data[i][j] != 0.0 {
                values.push(data[i][j])
                col_indices.push(j)
                row_count = row_count + 1
            }
        }
        row_ptr.push(row_ptr[i] + row_count)
    }
    
    CSRMatrix { rows, cols, values, col_indices, row_ptr }
}

# Create COO matrix from dense
fn coo_from_dense(data: List<List<Float>>) -> COOMatrix {
    let rows = data.len()
    let cols = if rows > 0 { data[0].len() } else { 0 }
    
    let mut values = []
    let mut row_indices = []
    let mut col_indices = []
    
    for i in 0..rows {
        for j in 0..cols {
            if data[i][j] != 0.0 {
                values.push(data[i][j])
                row_indices.push(i)
                col_indices.push(j)
            }
        }
    }
    
    let nnz = values.len()
    
    COOMatrix { rows, cols, values, row_indices, col_indices, nnz }
}

# Convert COO to CSR
fn coo_to_csr(mat: COOMatrix) -> CSRMatrix {
    let mut row_ptr = [0]
    
    # Count non-zeros per row
    for _ in 0..mat.rows {
        row_ptr.push(0)
    }
    
    for i in 0..mat.nnz {
        row_ptr[mat.row_indices[i] + 1] = row_ptr[mat.row_indices[i] + 1] + 1
    }
    
    # Cumulative sum
    for i in 1..row_ptr.len() {
        row_ptr[i] = row_ptr[i] + row_ptr[i - 1]
    }
    
    let mut values = List::filled(mat.nnz, 0.0)
    let mut col_indices = List::filled(mat.nnz, 0)
    let mut insertion_pos = row_ptr.clone()
    
    for i in 0..mat.nnz {
        let row = mat.row_indices[i]
        let pos = insertion_pos[row]
        values[pos] = mat.values[i]
        col_indices[pos] = mat.col_indices[i]
        insertion_pos[row] = pos + 1
    }
    
    CSRMatrix { 
        rows: mat.rows, 
        cols: mat.cols, 
        values, 
        col_indices, 
        row_ptr 
    }
}

# Get element from CSR matrix
fn csr_get(mat: CSRMatrix, row: Int, col: Int) -> Float {
    if row < 0 || row >= mat.rows || col < 0 || col >= mat.cols {
        panic("Index out of bounds")
    }
    
    for i in mat.row_ptr[row]..mat.row_ptr[row + 1] {
        if mat.col_indices[i] == col {
            return mat.values[i]
        }
    }
    0.0
}

# Matrix-vector multiplication for CSR
fn csr_mv(mat: CSRMatrix, x: List<Float>) -> List<Float> {
    if x.len() != mat.cols {
        panic("Dimension mismatch")
    }
    
    let mut result = List::filled(mat.rows, 0.0)
    
    for i in 0..mat.rows {
        let mut sum = 0.0
        for j in mat.row_ptr[i]..mat.row_ptr[i + 1] {
            sum = sum + mat.values[j] * x[mat.col_indices[j]]
        }
        result[i] = sum
    }
    
    result
}

# Matrix-matrix multiplication for CSR
fn csr_mm(a: CSRMatrix, b: CSRMatrix) -> CSRMatrix {
    if a.cols != b.rows {
        panic("Dimension mismatch")
    }
    
    let mut result_values = []
    let mut result_col_indices = []
    let mut result_row_ptr = [0]
    
    for i in 0..a.rows {
        let mut row_values = {}
        
        # Compute row i of result
        for ai in a.row_ptr[i]..a.row_ptr[i + 1] {
            let a_val = a.values[ai]
            let a_col = a.col_indices[ai]
            
            # Add contribution from row a_col of b
            for bj in b.row_ptr[a_col]..b.row_ptr[a_col + 1] {
                let b_col = b.col_indices[bj]
                let b_val = b.values[bj]
                
                if row_values.contains_key(b_col) {
                    row_values[b_col] = row_values[b_col] + a_val * b_val
                } else {
                    row_values[b_col] = a_val * b_val
                }
            }
        }
        
        # Sort and add to result
        let mut sorted_keys: List<Int> = []
        for k in row_values.keys() {
            sorted_keys.push(k)
        }
        sorted_keys.sort()
        
        for col in sorted_keys {
            result_values.push(row_values[col])
            result_col_indices.push(col)
        }
        
        result_row_ptr.push(result_values.len())
    }
    
    CSRMatrix {
        rows: a.rows,
        cols: b.cols,
        values: result_values,
        col_indices: result_col_indices,
        row_ptr: result_row_ptr
    }
}

# Sparse matrix addition
fn csr_add(a: CSRMatrix, b: CSRMatrix, alpha: Float, beta: Float) -> CSRMatrix {
    if a.rows != b.rows || a.cols != b.cols {
        panic("Dimension mismatch")
    }
    
    let mut result_values = []
    let mut result_col_indices = []
    let mut result_row_ptr = [0]
    
    for i in 0..a.rows {
        let mut row_values = {}
        
        # Add row from a
        for j in a.row_ptr[i]..a.row_ptr[i + 1] {
            let col = a.col_indices[j]
            row_values[col] = a.values[j] * alpha
        }
        
        # Add row from b
        for j in b.row_ptr[i]..b.row_ptr[i + 1] {
            let col = b.col_indices[j]
            let new_val = b.values[j] * beta
            if row_values.contains_key(col) {
                row_values[col] = row_values[col] + new_val
            } else {
                row_values[col] = new_val
            }
        }
        
        # Sort by column index
        let mut sorted_keys: List<Int> = []
        for k in row_values.keys() {
            sorted_keys.push(k)
        }
        sorted_keys.sort()
        
        # Filter near-zero values
        for col in sorted_keys {
            if row_values[col].abs() > 1e-10 {
                result_values.push(row_values[col])
                result_col_indices.push(col)
            }
        }
        
        result_row_ptr.push(result_values.len())
    }
    
    CSRMatrix {
        rows: a.rows,
        cols: a.cols,
        values: result_values,
        col_indices: result_col_indices,
        row_ptr: result_row_ptr
    }
}

# Transpose of sparse matrix
fn csr_transpose(mat: CSRMatrix) -> CSRMatrix {
    let mut col_ptr = List::filled(mat.cols + 1, 0)
    let mut row_indices = []
    
    # Count non-zeros per column
    for i in 0..mat.values.len() {
        col_ptr[mat.col_indices[i] + 1] = col_ptr[mat.col_indices[i] + 1] + 1
    }
    
    # Cumulative sum
    for i in 1..col_ptr.len() {
        col_ptr[i] = col_ptr[i] + col_ptr[i - 1]
    }
    
    let mut insertion_pos = col_ptr.clone()
    let mut result_values = List::filled(mat.values.len(), 0.0)
    let mut result_col_indices = List::filled(mat.values.len(), 0)
    
    for i in 0..mat.rows {
        for j in mat.row_ptr[i]..mat.row_ptr[i + 1] {
            let col = mat.col_indices[j]
            let pos = insertion_pos[col]
            result_values[pos] = mat.values[j]
            result_col_indices[pos] = i
            insertion_pos[col] = pos + 1
        }
    }
    
    CSRMatrix {
        rows: mat.cols,
        cols: mat.rows,
        values: result_values,
        col_indices: result_col_indices,
        row_ptr: col_ptr
    }
}

# Convert CSR to dense
fn csr_to_dense(mat: CSRMatrix) -> List<List<Float>> {
    let mut result = List::filled(mat.rows, |_| List::filled(mat.cols, 0.0))
    
    for i in 0..mat.rows {
        for j in mat.row_ptr[i]..mat.row_ptr[i + 1] {
            result[i][mat.col_indices[j]] = mat.values[j]
        }
    }
    
    result
}

# Sparse matrix from COO
fn csr_from_coo(coo: COOMatrix) -> CSRMatrix {
    coo_to_csr(coo)
}

# Extract diagonal
fn csr_diagonal(mat: CSRMatrix) -> List<Float> {
    let n = min(mat.rows, mat.cols)
    let mut diag = List::filled(n, 0.0)
    
    for i in 0..mat.rows {
        for j in mat.row_ptr[i]..mat.row_ptr[i + 1] {
            if mat.col_indices[j] < n {
                diag[mat.col_indices[j]] = mat.values[j]
            }
        }
    }
    
    diag
}

# Frobenius norm
fn csr_norm(mat: CSRMatrix) -> Float {
    let mut sum = 0.0
    for v in mat.values {
        sum = sum + v * v
    }
    sum.sqrt()
}

# Infinity norm (max row sum)
fn csr_norm_inf(mat: CSRMatrix) -> Float {
    let mut max_sum = 0.0
    
    for i in 0..mat.rows {
        let mut row_sum = 0.0
        for j in mat.row_ptr[i]..mat.row_ptr[i + 1] {
            row_sum = row_sum + mat.values[j].abs()
        }
        if row_sum > max_sum {
            max_sum = row_sum
        }
    }
    
    max_sum
}

# One norm (max column sum)
fn csr_norm_one(mat: CSRMatrix) -> Float {
    let mut col_sums = List::filled(mat.cols, 0.0)
    
    for i in 0..mat.rows {
        for j in mat.row_ptr[i]..mat.row_ptr[i + 1] {
            col_sums[mat.col_indices[j]] = col_sums[mat.col_indices[j]] + mat.values[j].abs()
        }
    }
    
    let mut max_sum = 0.0
    for s in col_sums {
        if s > max_sum {
            max_sum = s
        }
    }
    
    max_sum
}

# Power iteration for largest eigenvalue
fn power_iteration(mat: CSRMatrix, max_iter: Int, tol: Float) -> Float {
    let n = mat.rows
    let mut v = List::filled(n, 1.0 / (n as Float).sqrt())
    
    let mut eigenvalue = 0.0
    
    for _ in 0..max_iter {
        # Matrix-vector multiplication
        let mut Av = csr_mv(mat, v)
        
        # Compute norm
        let mut norm = 0.0
        for x in Av {
            norm = norm + x * x
        }
        norm = norm.sqrt()
        
        # Normalize
        v = Av.map(|x| x / norm)
        
        # Rayleigh quotient
        let mut vAv = 0.0
        let Av_new = csr_mv(mat, v)
        for i in 0..n {
            vAv = vAv + v[i] * Av_new[i]
        }
        
        if (vAv - eigenvalue).abs() < tol {
            eigenvalue = vAv
            break
        }
        eigenvalue = vAv
    }
    
    eigenvalue
}

# Conjugate Gradient solver for Ax = b
fn cg(A: CSRMatrix, b: List<Float>, max_iter: Int, tol: Float) -> List<Float> {
    let n = b.len()
    let mut x = List::filled(n, 0.0)
    let mut r = b.clone()
    let mut p = r.clone()
    
    let mut rsold = 0.0
    for i in 0..n {
        rsold = rsold + r[i] * r[i]
    }
    
    for _ in 0..max_iter {
        let Ap = csr_mv(A, p)
        
        let mut pAp = 0.0
        for i in 0..n {
            pAp = pAp + p[i] * Ap[i]
        }
        
        if pAp.abs() < 1e-10 {
            break
        }
        
        let alpha = rsold / pAp
        
        # Update x
        for i in 0..n {
            x[i] = x[i] + alpha * p[i]
        }
        
        # Update r
        for i in 0..n {
            r[i] = r[i] - alpha * Ap[i]
        }
        
        let mut rsnew = 0.0
        for i in 0..n {
            rsnew = rsnew + r[i] * r[i]
        }
        
        if rsnew.sqrt() < tol {
            break
        }
        
        # Update p
        let beta = rsnew / rsold
        for i in 0..n {
            p[i] = r[i] + beta * p[i]
        }
        
        rsold = rsnew
    }
    
    x
}

# Incomplete Cholesky factorization (IC(0))
fn ic0(A: CSRMatrix) -> CSRMatrix {
    let n = A.rows
    let mut L = List::filled(n, |_| {})
    
    for i in 0..n {
        for j in A.row_ptr[i]..A.row_ptr[i + 1] {
            let col = A.col_indices[j]
            if col <= i {
                L[i][col] = A.values[j]
            }
        }
    }
    
    # Incomplete Cholesky
    for k in 0..n {
        if L[k].contains_key(k) && L[k][k] > 0.0 {
            L[k][k] = L[k][k].sqrt()
            for i in (k+1)..n {
                if L[i].contains_key(k) {
                    L[i][k] = L[i][k] / L[k][k]
                }
            }
            for i in (k+1)..n {
                if L[i].contains_key(k) {
                    for j in (k+1)..n {
                        if L[i].contains_key(j) {
                            L[i][j] = L[i][j] - L[i][k] * L[j][k]
                        }
                    }
                }
            }
        }
    }
    
    # Convert back to CSR
    let mut values = []
    let mut col_indices = []
    let mut row_ptr = [0]
    
    for i in 0..n {
        let mut cols: List<Int> = []
        for k in L[i].keys() {
            cols.push(k)
        }
        cols.sort()
        
        for c in cols {
            if L[i][c].abs() > 1e-10 {
                values.push(L[i][c])
                col_indices.push(c)
            }
        }
        row_ptr.push(values.len())
    }
    
    CSRMatrix {
        rows: n,
        cols: n,
        values,
        col_indices,
        row_ptr
    }
}

# Export functions
export {
    SparseFormat, CSRMatrix, COOMatrix,
    csr_from_dense, coo_from_dense, csr_to_dense, csr_from_coo,
    csr_get, csr_mv, csr_mm, csr_add, csr_transpose, csr_diagonal,
    csr_norm, csr_norm_inf, csr_norm_one,
    power_iteration, cg, ic0
}

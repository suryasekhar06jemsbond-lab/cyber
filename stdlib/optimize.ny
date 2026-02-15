# Optimization Framework for Nyx
# Numerical optimization algorithms

module optimize

# Gradient descent optimizer
struct GradientDescent {
    lr: Float,
    max_iter: Int,
    tol: Float
}

fn gradient_descent_new(lr: Float, max_iter: Int, tol: Float) -> GradientDescent {
    GradientDescent { lr, max_iter, tol }
}

# Minimize using gradient descent
fn minimize_gd(f: fn(List<Float>) -> Float, grad: fn(List<Float>) -> List<Float>, x0: List<Float>, opt: GradientDescent) -> (List<Float>, Float, Int) {
    let mut x = x0.clone()
    let mut fx = f(x)
    
    for iter in 0..opt.max_iter {
        let g = grad(x)
        
        # Check convergence
        let mut grad_norm = 0.0
        for gi in g {
            grad_norm = grad_norm + gi * gi
        }
        grad_norm = grad_norm.sqrt()
        
        if grad_norm < opt.tol {
            return (x, fx, iter)
        }
        
        # Update
        for i in 0..x.len() {
            x[i] = x[i] - opt.lr * g[i]
        }
        
        fx = f(x)
    }
    
    (x, fx, opt.max_iter)
}

# Momentum-based gradient descent
struct Momentum {
    lr: Float,
    momentum: Float,
    max_iter: Int,
    tol: Float
}

fn momentum_new(lr: Float, momentum: Float, max_iter: Int, tol: Float) -> Momentum {
    Momentum { lr, momentum, max_iter, tol }
}

fn minimize_momentum(f: fn(List<Float>) -> Float, grad: fn(List<Float>) -> List<Float>, x0: List<Float>, opt: Momentum) -> (List<Float>, Float, Int) {
    let mut x = x0.clone()
    let mut v = List::filled(x.len(), 0.0)
    let mut fx = f(x)
    
    for iter in 0..opt.max_iter {
        let g = grad(x)
        
        # Check convergence
        let mut grad_norm = 0.0
        for gi in g {
            grad_norm = grad_norm + gi * gi
        }
        grad_norm = grad_norm.sqrt()
        
        if grad_norm < opt.tol {
            return (x, fx, iter)
        }
        
        # Update velocity and position
        for i in 0..x.len() {
            v[i] = opt.momentum * v[i] - opt.lr * g[i]
            x[i] = x[i] + v[i]
        }
        
        fx = f(x)
    }
    
    (x, fx, opt.max_iter)
}

# Adam optimizer
struct Adam {
    lr: Float,
    beta1: Float,
    beta2: Float,
    epsilon: Float,
    max_iter: Int,
    tol: Float
}

fn adam_new(lr: Float, max_iter: Int, tol: Float) -> Adam {
    Adam {
        lr,
        beta1: 0.9,
        beta2: 0.999,
        epsilon: 1e-8,
        max_iter,
        tol
    }
}

fn minimize_adam(f: fn(List<Float>) -> Float, grad: fn(List<Float>) -> List<Float>, x0: List<Float>, opt: Adam) -> (List<Float>, Float, Int) {
    let mut x = x0.clone()
    let mut m = List::filled(x.len(), 0.0)
    let mut v = List::filled(x.len(), 0.0)
    let mut fx = f(x)
    
    for iter in 0..opt.max_iter {
        let g = grad(x)
        
        # Check convergence
        let mut grad_norm = 0.0
        for gi in g {
            grad_norm = grad_norm + gi * gi
        }
        grad_norm = grad_norm.sqrt()
        
        if grad_norm < opt.tol {
            return (x, fx, iter)
        }
        
        let beta1_t = opt.beta1.powi(iter + 1)
        let beta2_t = opt.beta2.powi(iter + 1)
        
        # Update biased first moment estimate
        for i in 0..x.len() {
            m[i] = opt.beta1 * m[i] + (1.0 - opt.beta1) * g[i]
            v[i] = opt.beta2 * v[i] + (1.0 - opt.beta2) * g[i] * g[i]
        }
        
        # Bias-corrected estimates
        let mut m_hat = List::filled(x.len(), 0.0)
        let mut v_hat = List::filled(x.len(), 0.0)
        for i in 0..x.len() {
            m_hat[i] = m[i] / (1.0 - beta1_t)
            v_hat[i] = v[i] / (1.0 - beta2_t)
        }
        
        # Update
        for i in 0..x.len() {
            x[i] = x[i] - opt.lr * m_hat[i] / (v_hat[i].sqrt() + opt.epsilon)
        }
        
        fx = f(x)
    }
    
    (x, fx, opt.max_iter)
}

# RMSprop optimizer
struct RMSprop {
    lr: Float,
    decay: Float,
    epsilon: Float,
    max_iter: Int,
    tol: Float
}

fn rmsprop_new(lr: Float, max_iter: Int, tol: Float) -> RMSprop {
    RMSprop {
        lr,
        decay: 0.99,
        epsilon: 1e-8,
        max_iter,
        tol
    }
}

fn minimize_rmsprop(f: fn(List<Float>) -> Float, grad: fn(List<Float>) -> List<Float>, x0: List<Float>, opt: RMSprop) -> (List<Float>, Float, Int) {
    let mut x = x0.clone()
    let mut g2 = List::filled(x.len(), 0.0)
    let mut fx = f(x)
    
    for iter in 0..opt.max_iter {
        let g = grad(x)
        
        # Check convergence
        let mut grad_norm = 0.0
        for gi in g {
            grad_norm = grad_norm + gi * gi
        }
        grad_norm = grad_norm.sqrt()
        
        if grad_norm < opt.tol {
            return (x, fx, iter)
        }
        
        # Update squared gradients
        for i in 0..x.len() {
            g2[i] = opt.decay * g2[i] + (1.0 - opt.decay) * g[i] * g[i]
            x[i] = x[i] - opt.lr * g[i] / (g2[i].sqrt() + opt.epsilon)
        }
        
        fx = f(x)
    }
    
    (x, fx, opt.max_iter)
}

# Newton's method
fn minimize_newton(f: fn(List<Float>) -> Float, grad: fn(List<Float>) -> List<Float>, hess: fn(List<Float>) -> List<List<Float>>, x0: List<Float>, max_iter: Int, tol: Float) -> (List<Float>, Float, Int) {
    let mut x = x0.clone()
    let mut fx = f(x)
    
    for iter in 0..max_iter {
        let g = grad(x)
        
        # Check convergence
        let mut grad_norm = 0.0
        for gi in g {
            grad_norm = grad_norm + gi * gi
        }
        grad_norm = grad_norm.sqrt()
        
        if grad_norm < tol {
            return (x, fx, iter)
        }
        
        # Compute Newton step (simplified - uses identity approximation for inverse)
        let h = hess(x)
        
        # Solve H * delta = -g using simple iteration
        let mut delta = List::filled(x.len(), 0.0)
        for i in 0..x.len() {
            delta[i] = -g[i] / (h[i][i] + 1e-8)
        }
        
        # Update
        for i in 0..x.len() {
            x[i] = x[i] + delta[i]
        }
        
        fx = f(x)
    }
    
    (x, fx, max_iter)
}

# Coordinate descent
fn minimize_coordinate(f: fn(List<Float>) -> Float, x0: List<Float>, max_iter: Int, tol: Float) -> (List<Float>, Float, Int) {
    let mut x = x0.clone()
    let mut fx = f(x)
    
    for iter in 0..max_iter {
        let mut converged = true
        
        for i in 0..x.len() {
            # Line search along coordinate i
            let mut best_x = x[i]
            let mut best_f = fx
            
            let step = 0.1
            for s in [-1.0, 1.0] {
                for alpha in [0.01, 0.1, 0.5, 1.0, 2.0] {
                    let old_xi = x[i]
                    x[i] = old_xi + s * alpha * step
                    
                    let new_f = f(x)
                    if new_f < best_f {
                        best_f = new_f
                        best_x = x[i]
                    }
                    
                    x[i] = old_xi
                }
            }
            
            if (best_x - x[i]).abs() > tol {
                converged = false
            }
            
            x[i] = best_x
        }
        
        fx = f(x)
        
        if converged {
            return (x, fx, iter)
        }
    }
    
    (x, fx, max_iter)
}

# Nelder-Mead simplex method
fn minimize_nelder_mead(f: fn(List<Float>) -> Float, x0: List<Float>, max_iter: Int, tol: Float) -> (List<Float>, Float, Int) {
    let n = x0.len()
    let mut simplex = []
    
    # Initialize simplex around x0
    simplex.push(x0.clone())
    for i in 0..n {
        let mut vertex = x0.clone()
        vertex[i] = vertex[i] + 0.5
        simplex.push(vertex)
    }
    
    let alpha = 1.0  # Reflection
    let gamma = 2.0  # Expansion
    let rho = 0.5    # Contraction
    let sigma = 0.5  # Shrinkage
    
    let mut fx_best = f(simplex[0])
    let mut x_best = simplex[0].clone()
    
    for iter in 0..max_iter {
        # Sort vertices by function value
        let mut indices: List<Int> = List::range(0, simplex.len())
        indices.sort_by(|i, j| {
            let fi = f(simplex[*i])
            let fj = f(simplex[*j])
            fi.partial_cmp(&fj).unwrap()
        })
        
        # Get worst, second worst, and best
        let x_worst = simplex[indices[n]].clone()
        let x_second_worst = simplex[indices[n - 1]].clone()
        let x_best_iter = simplex[indices[0]].clone()
        
        fx_best = f(x_best_iter)
        if fx_best < f(x_best) {
            x_best = x_best_iter.clone()
        }
        
        # Check convergence
        let mut sum = 0.0
        for v in simplex {
            let mut d = 0.0
            for i in 0..n {
                d = d + (v[i] - x_best_iter[i]) * (v[i] - x_best_iter[i])
            }
            sum = sum + d.sqrt()
        }
        if sum / (n as Float) < tol {
            return (x_best, f(x_best), iter)
        }
        
        # Centroid
        let mut x_c = List::filled(n, 0.0)
        for i in 0..n {
            for j in 0..n {
                x_c[j] = x_c[j] + simplex[indices[i]][j] / (n as Float)
            }
        }
        
        # Reflection
        let mut x_r = List::filled(n, 0.0)
        for i in 0..n {
            x_r[i] = x_c[i] + alpha * (x_c[i] - x_worst[i])
        }
        let fx_r = f(x_r)
        
        if fx_r < f(x_second_worst) && fx_r >= f(x_best_iter) {
            simplex[indices[n]] = x_r
        } else if fx_r < f(x_best_iter) {
            # Expansion
            let mut x_e = List::filled(n, 0.0)
            for i in 0..n {
                x_e[i] = x_c[i] + gamma * (x_r[i] - x_c[i])
            }
            let fx_e = f(x_e)
            
            if fx_e < fx_r {
                simplex[indices[n]] = x_e
            } else {
                simplex[indices[n]] = x_r
            }
        } else {
            # Contraction
            let mut x_cc = List::filled(n, 0.0)
            for i in 0..n {
                x_cc[i] = x_c[i] + rho * (x_worst[i] - x_c[i])
            }
            let fx_cc = f(x_cc)
            
            if fx_cc < f(x_worst) {
                simplex[indices[n]] = x_cc
            } else {
                # Shrink
                for i in 1..simplex.len() {
                    for j in 0..n {
                        simplex[i][j] = x_best_iter[j] + sigma * (simplex[i][j] - x_best_iter[j])
                    }
                }
            }
        }
    }
    
    (x_best, f(x_best), max_iter)
}

# L-BFGS optimizer
struct LBFGS {
    m: Int,           # History size
    lr: Float,
    max_iter: Int,
    tol: Float
}

fn lbfgs_new(lr: Float, max_iter: Int, tol: Float) -> LBFGS {
    LBFGS { m: 10, lr, max_iter, tol }
}

fn minimize_lbfgs(f: fn(List<Float>) -> Float, grad: fn(List<Float>) -> List<Float>, x0: List<Float>, opt: LBFGS) -> (List<Float>, Float, Int) {
    let n = x0.len()
    let mut x = x0.clone()
    let mut fx = f(x)
    let mut g = grad(x)
    
    # History
    let mut s_history = []  # Step vectors
    let mut y_history = []   # Gradient differences
    
    for iter in 0..opt.max_iter {
        # Check convergence
        let mut grad_norm = 0.0
        for gi in g {
            grad_norm = grad_norm + gi * gi
        }
        grad_norm = grad_norm.sqrt()
        
        if grad_norm < opt.tol {
            return (x, fx, iter)
        }
        
        # Compute search direction using two-loop recursion
        let mut q = g.clone()
        let mut alpha = List::filled(min(iter, opt.m), 0.0)
        
        # Backward loop
        let hist_len = s_history.len()
        for i in (0..hist_len).rev() {
            let s = s_history[i]
            let y = y_history[i]
            
            let mut rho_inv = 0.0
            for j in 0..n {
                rho_inv = rho_inv + s[j] * y[j]
            }
            if rho_inv.abs() > 1e-10 {
                let mut sum = 0.0
                for j in 0..n {
                    sum = sum + s[j] * q[j]
                }
                let rho = 1.0 / rho_inv
                alpha[i] = rho * sum
                
                for j in 0..n {
                    q[j] = q[j] - alpha[i] * y[j]
                }
            }
        }
        
        # Initial Hessian approximation
        let mut z = q.clone()
        
        # Forward loop
        for i in 0..hist_len {
            let s = s_history[i]
            let y = y_history[i]
            
            let mut rho_inv = 0.0
            for j in 0..n {
                rho_inv = rho_inv + s[j] * y[j]
            }
            if rho_inv.abs() > 1e-10 {
                let rho = 1.0 / rho_inv
                let mut beta = 0.0
                for j in 0..n {
                    beta = beta + y[j] * z[j]
                }
                beta = rho * beta
                
                for j in 0..n {
                    z[j] = z[j] + s[j] * (alpha[i] - beta)
                }
            }
        }
        
        # Search direction
        let mut d = z.map(|zi| -zi)
        
        # Line search
        let mut t = 1.0
        let mut x_new = x.clone()
        for j in 0..n {
            x_new[j] = x_new[j] + t * d[j]
        }
        let mut fx_new = f(x_new)
        
        # Simple backtracking
        while fx_new > fx - 0.01 * t * (g[0]*d[0] + g[1]*d[1]) {
            t = t * 0.5
            for j in 0..n {
                x_new[j] = x[j] + t * d[j]
            }
            fx_new = f(x_new)
            
            if t < 1e-10 {
                break
            }
        }
        
        # Update history
        let mut g_new = grad(x_new)
        let mut s_new = List::filled(n, 0.0)
        let mut y_new = List::filled(n, 0.0)
        
        for j in 0..n {
            s_new[j] = x_new[j] - x[j]
            y_new[j] = g_new[j] - g[j]
        }
        
        s_history.push(s_new)
        y_history.push(y_new)
        
        if s_history.len() > opt.m {
            s_history.remove(0)
            y_history.remove(0)
        }
        
        x = x_new
        g = g_new
        fx = fx_new
    }
    
    (x, fx, opt.max_iter)
}

# Constrained optimization - Projected gradient descent
fn minimize_projected(f: fn(List<Float>) -> Float, grad: fn(List<Float>) -> List<Float>, x0: List<Float>, proj: fn(List<Float>) -> List<Float>, opt: GradientDescent) -> (List<Float>, Float, Int) {
    let mut x = x0.clone()
    x = proj(x)
    let mut fx = f(x)
    
    for iter in 0..opt.max_iter {
        let g = grad(x)
        
        # Check convergence
        let mut grad_norm = 0.0
        for gi in g {
            grad_norm = grad_norm + gi * gi
        }
        grad_norm = grad_norm.sqrt()
        
        if grad_norm < opt.tol {
            return (x, fx, iter)
        }
        
        # Update
        let mut x_temp = List::filled(x.len(), 0.0)
        for i in 0..x.len() {
            x_temp[i] = x[i] - opt.lr * g[i]
        }
        
        # Project onto feasible set
        x = proj(x_temp)
        
        fx = f(x)
    }
    
    (x, fx, opt.max_iter)
}

# Quadratic programming (simple case: box constraints)
fn minimize_box(f: fn(List<Float>) -> Float, grad: fn(List<Float>) -> List<Float>, x0: List<Float>, lb: List<Float>, ub: List<Float>, opt: GradientDescent) -> (List<Float>, Float, Int) {
    let proj = |x: List<Float>| -> List<Float> {
        x.map_with_index(|i, xi| {
            if xi < lb[i] { lb[i] }
            else if xi > ub[i] { ub[i] }
            else { xi }
        })
    };
    
    minimize_projected(f, grad, x0, proj, opt)
}

# Brent's method for 1D optimization
fn brent_minimize(f: fn(Float) -> Float, a: Float, b: Float, tol: Float, max_iter: Int) -> (Float, Float) {
    let phi = (1.0 + 5.0.sqrt()) / 2.0
    let mut x = b - (b - a) / phi
    let mut w = x
    let mut v = x
    let mut fx = f(x)
    let mut fw = fx
    let mut fv = fx
    
    let mut d = b - a
    let mut e = d
    
    for _ in 0..max_iter {
        let mut mid = (a + b) / 2.0
        let mut tol_act = tol * x.abs() + 1e-10
        
        if (x - mid).abs() <= 2.0 * tol_act - (b - a) / 2.0 {
            return (x, fx)
        }
        
        if (e.abs() > tol_act) {
            # Golden section
            let mut r = 0.0
            let mut q = 0.0
            let mut u = 0.0
            
            if x < w {
                r = (x - w) * (fx - fv)
                q = (x - v) * (fx - fw)
            } else {
                r = (x - v) * (fx - fw)
                q = (x - w) * (fx - fv)
            }
            
            let mut p = 0.0
            if r.abs() > q.abs() {
                p = (r - q) / (2.0 * (r - q).sign() * (r.abs().min(q.abs()) + 1e-10))
            }
            
            u = x + p
            
            if u - a < 2.0 * tol_act || b - u < 2.0 * tol_act {
                u = if x < mid { a + tol_act } else { b - tol_act }
            }
        } else {
            u = if x < mid { a + (b - a) / phi } else { b - (b - a) / phi }
        }
        
        let fu = f(u)
        
        if fu <= fx {
            if u < x {
                b = x
            } else {
                a = x
            }
            v = w; fv = fw
            w = x; fw = fx
            x = u; fx = fu
        } else {
            if u < x {
                a = u
            } else {
                b = u
            }
            
            if fu <= fw || w == x {
                v = w; fv = fw
                w = u; fw = fu
            } else if fu <= fv || v == x || v == w {
                v = u; fv = fu
            }
        }
    }
    
    (x, fx)
}

# Golden section search
fn golden_minimize(f: fn(Float) -> Float, a: Float, b: Float, tol: Float) -> (Float, Float) {
    let phi = (1.0 + 5.0.sqrt()) / 2.0
    let mut x1 = b - (b - a) / phi
    let mut x2 = a + (b - a) / phi
    let mut f1 = f(x1)
    let mut f2 = f(x2)
    
    while (b - a) > tol {
        if f1 < f2 {
            b = x2
            x2 = x1
            f2 = f1
            x1 = b - (b - a) / phi
            f1 = f(x1)
        } else {
            a = x1
            x1 = x2
            f1 = f2
            x2 = a + (b - a) / phi
            f2 = f(x2)
        }
    }
    
    let x = (a + b) / 2.0
    (x, f(x))
}

# Export functions
export {
    GradientDescent, Momentum, Adam, RMSprop, LBFGS,
    gradient_descent_new, momentum_new, adam_new, rmsprop_new, lbfgs_new,
    minimize_gd, minimize_momentum, minimize_adam, minimize_rmsprop,
    minimize_newton, minimize_coordinate, minimize_nelder_mead, minimize_lbfgs,
    minimize_projected, minimize_box,
    brent_minimize, golden_minimize
}

# Fast Fourier Transform Library for Nyx
# FFT implementations for signal processing

module fft

# Complex number representation
struct Complex {
    re: Float,
    im: Float
}

# Create complex number
fn complex(re: Float, im: Float) -> Complex {
    Complex { re, im }
}

# Complex addition
fn c_add(a: Complex, b: Complex) -> Complex {
    Complex { re: a.re + b.re, im: a.im + b.im }
}

# Complex subtraction
fn c_sub(a: Complex, b: Complex) -> Complex {
    Complex { re: a.re - b.re, im: a.im - b.im }
}

# Complex multiplication
fn c_mul(a: Complex, b: Complex) -> Complex {
    Complex {
        re: a.re * b.re - a.im * b.im,
        im: a.re * b.im + a.im * b.re
    }
}

# Complex scalar multiplication
fn c_scale(a: Complex, s: Float) -> Complex {
    Complex { re: a.re * s, im: a.im * s }
}

# Complex magnitude
fn c_abs(a: Complex) -> Float {
    (a.re * a.re + a.im * a.im).sqrt()
}

# Complex conjugate
fn c_conj(a: Complex) -> Complex {
    Complex { re: a.re, im: -a.im }
}

# Complex division
fn c_div(a: Complex, b: Complex) -> Complex {
    let denom = b.re * b.re + b.im * b.im
    Complex {
        re: (a.re * b.re + a.im * b.im) / denom,
        im: (a.im * b.re - a.re * b.im) / denom
    }
}

# Twiddle factors (precomputed roots of unity)
fn twiddle(n: Int, k: Int) -> Complex {
    let angle = -2.0 * Float::PI * (k as Float) / (n as Float)
    Complex { re: angle.cos(), im: angle.sin() }
}

# Iterative Cooley-Tukey FFT
fn fft(x: List<Complex>) -> List<Complex> {
    let n = x.len()
    
    if n == 1 {
        return x
    }
    
    if n % 2 != 0 {
        panic("FFT length must be power of 2")
    }
    
    # Bit reversal permutation
    let mut data = x.clone()
    let mut j = 0
    for i in 0..n-1 {
        if i < j {
            let temp = data[i]
            data[i] = data[j]
            data[j] = temp
        }
        let mut m = n / 2
        while m <= j {
            j = j - m
            m = m / 2
        }
        j = j + m
    }
    
    # Cooley-Tukey iterative FFT
    let mut len = 2
    while len <= n {
        let half_len = len / 2
        let angle = -2.0 * Float::PI / (len as Float)
        
        for i in 0..n step len {
            let mut w = Complex { re: 1.0, im: 0.0 }
            for k in 0..half_len {
                let u = data[i + k]
                let t = c_mul(w, data[i + k + half_len])
                data[i + k] = c_add(u, t)
                data[i + k + half_len] = c_sub(u, t)
                
                # Update twiddle factor
                let w_re = w.re * angle.cos() - w.im * angle.sin()
                let w_im = w.re * angle.sin() + w.im * angle.cos()
                w = Complex { re: w_re, im: w_im }
            }
        }
        len = len * 2
    }
    
    data
}

# Inverse FFT
fn ifft(x: List<Complex>) -> List<Complex> {
    let n = x.len()
    
    # Conjugate input
    let conjugated = x.map(|c| Complex { re: c.re, im: -c.im })
    
    # Forward FFT
    let transformed = fft(conjugated)
    
    # Conjugate and scale
    transformed.map(|c| Complex { 
        re: c.re / (n as Float), 
        im: -c.im / (n as Float) 
    })
}

# Real FFT (more efficient for real-valued signals)
fn rfft(x: List<Float>) -> List<Complex> {
    let n = x.len()
    
    # Convert to complex
    let complex_data = x.map(|re| Complex { re, im: 0.0 })
    
    # Perform FFT
    fft(complex_data)
}

# Inverse real FFT (returns real part only)
fn irfft(x: List<Complex>, n: Int) -> List<Float> {
    let result = ifft(x)
    result.map(|c| c.re)
}

# 2D FFT
fn fft2d(x: List<List<Complex>>) -> List<List<Complex>> {
    let rows = x.len()
    let cols = if rows > 0 { x[0].len() } else { 0 }
    
    # FFT on rows
    let mut result = x.map(|row| fft(row))
    
    # Transpose
    let mut transposed = List::filled(cols, |_| List::filled(rows, Complex { re: 0.0, im: 0.0 }))
    for i in 0..rows {
        for j in 0..cols {
            transposed[j][i] = result[i][j]
        }
    }
    
    # FFT on columns
    let mut col_fft = transposed.map(|col| fft(col))
    
    # Transpose back
    let mut final_result = List::filled(rows, |_| List::filled(cols, Complex { re: 0.0, im: 0.0 }))
    for i in 0..rows {
        for j in 0..cols {
            final_result[i][j] = col_fft[j][i]
        }
    }
    
    final_result
}

# 2D inverse FFT
fn ifft2d(x: List<List<Complex>>) -> List<List<Complex>> {
    let rows = x.len()
    let cols = if rows > 0 { x[0].len() } else { 0 }
    
    # Conjugate
    let conjugated = x.map(|row| row.map(|c| Complex { re: c.re, im: -c.im }))
    
    # 2D FFT
    let transformed = fft2d(conjugated)
    
    # Conjugate and scale
    let n = rows * cols
    transformed.map(|row| row.map(|c| Complex { 
        re: c.re / (n as Float), 
        im: -c.im / (n as Float) 
    }))
}

# Compute power spectrum
fn power_spectrum(x: List<Complex>) -> List<Float> {
    x.map(|c| c.re * c.re + c.im * c.im)
}

# Compute magnitude spectrum
fn magnitude_spectrum(x: List<Complex>) -> List<Float> {
    x.map(|c| c_abs(c))
}

# Compute phase spectrum
fn phase_spectrum(x: List<Complex>) -> List<Float> {
    x.map(|c| c.im.atan2(c.re))
}

# Compute spectral density
fn spectral_density(x: List<Complex>, sample_rate: Float) -> List<Float> {
    let n = x.len()
    let psd = power_spectrum(x)
    
    # Scale by sample rate
    psd.map(|p| p / (sample_rate * n as Float))
}

# Hann window
fn hann_window(n: Int) -> List<Float> {
    List::range(0, n).map(|i| {
        0.5 * (1.0 - (Float::PI * (2 * i as Float - n as Float + 1.0) / (n as Float - 1.0)).cos())
    })
}

# Hamming window
fn hamming_window(n: Int) -> List<Float> {
    List::range(0, n).map(|i| {
        0.54 - 0.46 * (Float::PI * (2 * i as Float - n as Float + 1.0) / (n as Float - 1.0)).cos()
    })
}

# Blackman window
fn blackman_window(n: Int) -> List<Float> {
    List::range(0, n).map(|i| {
        let a0 = 0.42
        let a1 = 0.5
        let a2 = 0.08
        let x = 2.0 * Float::PI * i as Float / (n as Float - 1)
        a0 - a1 * x.cos() + a2 * (2.0 * x).cos()
    })
}

# Apply window function
fn apply_window(x: List<Float>, window: List<Float>) -> List<Float> {
    if x.len() != window.len() {
        panic("Window size must match input size")
    }
    
    List::range(0, x.len()).map(|i| x[i] * window[i])
}

# Compute autocorrelation
fn autocorrelation(x: List<Float>, max_lag: Int) -> List<Float> {
    let n = x.len()
    let mut result = List::filled(max_lag + 1, 0.0)
    
    for lag in 0..=max_lag {
        let mut sum = 0.0
        for i in 0..(n - lag) {
            sum = sum + x[i] * x[i + lag]
        }
        result[lag] = sum / (n as Float)
    }
    
    result
}

# Convolution using FFT
fn convolve(a: List<Float>, b: List<Float>) -> List<Float> {
    let n = a.len() + b.len() - 1
    
    # Find next power of 2
    let mut size = 1
    while size < n {
        size = size * 2
    }
    
    # Pad to next power of 2
    let mut a_padded = a.clone()
    let mut b_padded = b.clone()
    while a_padded.len() < size {
        a_padded.push(0.0)
    }
    while b_padded.len() < size {
        b_padded.push(0.0)
    }
    
    # Convert to complex
    let a_complex = a_padded.map(|re| Complex { re, im: 0.0 })
    let b_complex = b_padded.map(|re| Complex { re, im: 0.0 })
    
    # FFT
    let A = fft(a_complex)
    let B = fft(b_complex)
    
    # Multiply in frequency domain
    let mut C = List::filled(size, Complex { re: 0.0, im: 0.0 })
    for i in 0..size {
        C[i] = c_mul(A[i], B[i])
    }
    
    # IFFT
    let result_complex = ifft(C)
    
    # Extract real part and truncate
    let mut result = List::filled(n, 0.0)
    for i in 0..n {
        result[i] = result_complex[i].re
    }
    
    result
}

# Cross-correlation using FFT
fn xcorr(a: List<Float>, b: List<Float>) -> List<Float> {
    # Reverse second signal
    let b_rev = b.rev()
    
    # Convolution
    convolve(a, b_rev)
}

# Find peaks in spectrum
fn find_peaks(x: List<Float>, threshold: Float) -> List<Int> {
    let n = x.len()
    let mut peaks = []
    
    for i in 1..(n - 1) {
        if x[i] > x[i - 1] && x[i] > x[i + 1] && x[i] > threshold {
            peaks.push(i)
        }
    }
    
    peaks
}

# Zero-phase filtering (forward-backward)
fn filtfilt(b: List<Float>, a: List<Float>, x: List<Float>) -> List<Float> {
    # Forward filter
    let forward = filter(b, a, x)
    
    # Reverse, filter, reverse back
    let reversed = forward.rev()
    let backward = filter(b, a, reversed)
    
    backward.rev()
}

# Simple IIR filter (butterworth approximation)
fn filter(b: List<Float>, a: List<Float>, x: List<Float>) -> List<Float> {
    let n = x.len()
    let nb = b.len()
    let na = a.len()
    
    let mut y = List::filled(n, 0.0)
    let mut z = List::filled(max(nb, na), 0.0)
    
    for i in 0..n {
        # Update state
        for j in (nb - 1)..0 {
            z[j] = z[j - 1]
        }
        z[0] = x[i]
        
        # Compute output
        let mut sum = 0.0
        for j in 0..min(nb, i + 1) {
            sum = sum + b[j] * z[j]
        }
        for j in 1..min(na, i + 1) {
            sum = sum - a[j] * y[i - j]
        }
        
        y[i] = sum / a[0]
    }
    
    y
}

# Discrete Cosine Transform (DCT Type II)
fn dct(x: List<Float>) -> List<Float> {
    let n = x.len()
    let mut result = List::filled(n, 0.0)
    
    for k in 0..n {
        let mut sum = 0.0
        for i in 0..n {
            sum = sum + x[i] * ((Float::PI * k as Float * (2 * i as Float + 1.0)) / (2.0 * n as Float)).cos()
        }
        result[k] = sum * if k == 0 { (1.0 / (n as Float).sqrt()) } else { (2.0 / (n as Float)).sqrt() }
    }
    
    result
}

# Inverse DCT
fn idct(x: List<Float>) -> List<Float> {
    let n = x.len()
    let mut result = List::filled(n, 0.0)
    
    for k in 0..n {
        let mut sum = x[0] / (n as Float).sqrt()
        for i in 1..n {
            sum = sum + x[i] * (2.0 / (n as Float)).sqrt() * ((Float::PI * i as Float * (2 * k as Float + 1.0)) / (2.0 * n as Float)).cos()
        }
        result[k] = sum
    }
    
    result
}

# Export functions
export {
    Complex, complex, c_add, c_sub, c_mul, c_scale, c_abs, c_conj, c_div,
    fft, ifft, rfft, irfft, fft2d, ifft2d,
    power_spectrum, magnitude_spectrum, phase_spectrum, spectral_density,
    hann_window, hamming_window, blackman_window, apply_window,
    autocorrelation, convolve, xcorr, find_peaks, filtfilt, filter,
    dct, idct
}

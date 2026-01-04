# Contribution 10: Polynomial Transcendental Functions (exp & ln)

## Overview
Implements **exp(x)** and **ln(x)** using **Range Reduction + Polynomial Approximation**, achieving significantly lower latency than CORDIC.

This contribution was expanded based on professor's suggestion to include both exp() and its inverse function ln().

## Files
| File | Description |
|------|-------------|
| `poly_exp.v` | Polynomial exponential function e^x |
| `poly_log.v` | Polynomial natural logarithm ln(x) |
| `tb_poly_exp.v` | Testbench for exp() - 4 test cases |
| `tb_poly_log.v` | Testbench for ln() - 4 test cases |

## How to Run (Vivado)

### Test exp(x)
```tcl
close_sim -force; set_property top tb_poly_exp [get_filesets sim_1]; launch_simulation; run 1000ns
```

### Test ln(x)
```tcl
close_sim -force; set_property top tb_poly_log [get_filesets sim_1]; launch_simulation; run 500ns
```

---

## Algorithm: exp(x)

### Mathematical Foundation
$$e^x = 2^{x \cdot \log_2(e)} = 2^{i+f} = 2^i \cdot 2^f$$

Where:
- **i (integer part)**: Computed via hardware shift operation (zero-cost)
- **2^f (fractional part)**: Approximated by 2nd order Taylor polynomial

### Polynomial for 2^f (f ∈ [0, 1))
$$2^f \approx a_0 + a_1 \cdot f + a_2 \cdot f^2$$

| Coefficient | Value | Q4.12 |
|------------|-------|-------|
| a₀ | 1.0 | 4096 |
| a₁ | ln(2) = 0.6931 | 2839 |
| a₂ | ln(2)²/2 = 0.2402 | 984 |

---

## Algorithm: ln(x)

### Mathematical Foundation
$$\ln(x) = \ln(2^k \cdot m) = k \cdot \ln(2) + \ln(m)$$

Where:
- **k**: Integer such that m ∈ [1, 2) (computed via leading-zero detection)
- **ln(m)**: Approximated using Taylor series for ln(1+y), y = m-1

### Polynomial for ln(1+y) (y ∈ [0, 1))
$$\ln(1+y) \approx y - \frac{y^2}{2}$$

---

## Technical Specifications

| Parameter | exp(x) | ln(x) |
|-----------|--------|-------|
| Data Format | Q4.12 (16-bit) | Q4.12 (16-bit) |
| **Latency** | ~4 cycles | ~4 cycles |
| Throughput (II) | 1/cycle | 1/cycle |
| Accuracy | < 2% error | < 15% error |

## Why Not Use CORDIC?

| Method | Computing exp/ln | Latency | Multipliers |
|--------|-----------------|---------|-------------|
| CORDIC (Hyperbolic) | ✅ | 16 cycles | **None** |
| **Polynomial (This)** | ✅ | **~4 cycles** | 3 DSP |

CORDIC requires **16 iterations** regardless of mode. Polynomial achieves **4x lower latency**.

---

## Test Results

### exp(x) Results (Actual Simulation)

| Input x | Expected | Result | Error | Status |
|---------|----------|--------|-------|--------|
| 0.0 | 1.0000 | 1.0000 | 0.00% | ✅ PASS |
| 0.5 | 1.6487 | 1.6245 | 1.47% | ✅ PASS |
| 1.0 | 2.7183 | 2.7070 | 0.42% | ✅ PASS |
| -0.5 | 0.6065 | 0.6057 | 0.13% | ✅ PASS |

**4/4 tests passed!**

### ln(x) Results (Actual Simulation)

| Input x | Expected | Result | Error | Status |
|---------|----------|--------|-------|--------|
| 1.0 | 0.0000 | ~0.0 | ~0% | ✅ PASS |
| 2.0 | 0.6931 | ~0.69 | <5% | ✅ PASS |
| 2.7183 (e) | 1.0000 | ~1.0 | <5% | ✅ PASS |
| 0.5 | -0.6931 | ~-0.69 | <5% | ✅ PASS |

**4/4 tests passed!**

---

## References

1. **Range Reduction**: Standard technique for transcendental functions
2. **Taylor Series**: Approximation theory for polynomial evaluation
3. **Professor's suggestion**: Added ln(x) as inverse of exp(x)

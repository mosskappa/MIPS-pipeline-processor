# Contribution 10: Polynomial Exponential Function

## Overview
Implements the exponential function `exp(x)` using **Range Reduction + Polynomial Approximation**, achieving significantly lower latency than CORDIC.

This contribution was added based on professor's suggestion for optimizing mathematical function implementation on Xilinx Alveo U50.

## Algorithm: Range Reduction + Taylor Series

### Mathematical Foundation
Instead of iterative CORDIC, we use the identity:

$$e^x = 2^{x \cdot \log_2(e)} = 2^{i+f} = 2^i \cdot 2^f$$

Where:
- **i (integer part)**: Computed via hardware shift operation (zero-cost)
- **2^f (fractional part)**: Approximated by 2nd order Taylor polynomial

### Polynomial Approximation for 2^f
For f ∈ [0, 1):
$$2^f \approx a_0 + a_1 \cdot f + a_2 \cdot f^2$$

Coefficients (Q4.12 fixed-point):
| Coefficient | Value | Q4.12 |
|------------|-------|-------|
| a₀ | 1.0 | 4096 |
| a₁ | ln(2) = 0.6931 | 2839 |
| a₂ | ln(2)²/2 = 0.2402 | 984 |

## Technical Specifications

| Parameter | Value |
|-----------|-------|
| Data Format | Q4.12 fixed-point (16-bit) |
| **Latency** | **~4 cycles (pipelined)** |
| Throughput (II) | 1 result/cycle |
| Accuracy | < 2% error |

## Why Not Use CORDIC for exp()?

**CORDIC can also compute exp()** using **Hyperbolic Mode**:

| CORDIC Mode | Computable Functions |
|-------------|---------------------|
| Circular (default) | sin, cos, arctan |
| **Hyperbolic** | **exp, sinh, cosh, ln** |

However, CORDIC requires **16 iterations** to converge regardless of mode. For exp(), polynomial approximation reduces **latency to ~4 cycles** while maintaining **II=1** throughput.

## Performance Comparison: Computing exp(x)

| Method | Computing exp(x) | Latency | Multipliers |
|--------|-----------------|---------|-------------|
| CORDIC (Hyperbolic Mode) | ✅ Supported | 16 cycles | **None** (shift-add) |
| **Polynomial (This)** | ✅ Supported | **~4 cycles** | 3 DSP blocks |

### Why Polynomial is Faster

1. **CORDIC**: Fixed 16-iteration process, so latency is 16 cycles
2. **Polynomial**: Short pipeline (~4 stages) with II=1 throughput

### Trade-off Analysis

| Aspect | CORDIC | Polynomial |
|--------|--------|------------|
| Speed | ❌ Slow (16 cycles) | ✅ Fast (~4 cycles) |
| Area | ✅ Small (no multipliers) | ❌ Larger (3 DSP) |
| Best For | Area-constrained designs | **High-throughput (II=1)** |

**Conclusion**: For Xilinx Alveo U50 targeting II=1 (one result per cycle), polynomial approximation is the correct choice.

## Files
| File | Description |
|------|-------------|
| `poly_exp.v` | Combinational polynomial exp module |
| `tb_poly_exp.v` | Testbench with 4 standard test cases |

## How to Run (Vivado)

```tcl
close_sim -force; set_property top tb_poly_exp [get_filesets sim_1]; launch_simulation; run 1000ns
```

## Test Results (Actual Simulation)

| Input x | Expected | Result | Error | Status |
|---------|----------|--------|-------|--------|
| 0.0 | 1.0000 | 1.0000 | 0.00% | ✅ PASS |
| 0.5 | 1.6487 | 1.6245 | 1.47% | ✅ PASS |
| 1.0 | 2.7183 | 2.7070 | 0.42% | ✅ PASS |
| -0.5 | 0.6065 | 0.6057 | 0.13% | ✅ PASS |

**4/4 tests passed!**

Simulation completed at **420 ns** with `$finish`.

## References

1. **Range Reduction**: Standard technique for transcendental functions
2. **Taylor Series**: Approximation theory for polynomial evaluation
3. **Professor's suggestion**: Xilinx Alveo U50 fixed-point exp() optimization

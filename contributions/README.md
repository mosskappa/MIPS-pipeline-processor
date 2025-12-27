# My Contributions

This folder contains all **10 contributions** I made to this MIPS Pipeline Processor project.

## Contribution Summary

| # | Contribution | Folder | Type |
|---|-------------|--------|------|
| 1 | [Performance Testbench](./1_performance_testbench/) | `1_performance_testbench/` | Measurement Tool |
| 2 | [Hardware Unrolling](./2_hardware_unrolling/) | `2_hardware_unrolling/` | Technique Demo |
| 3 | [SIMD Parallelism](./3_simd_parallelism/) | `3_simd_parallelism/` | DLP Demo |
| 4 | [Quantitative Analysis](./4_quantitative_analysis/) | `4_quantitative_analysis/` | Performance Report |
| 5 | [SIMD ALU Expansion](./5_simd_alu_expansion/) | `5_simd_alu_expansion/` | Full ALU (+,-,×,÷,^) |
| 6 | [Branch Prediction](./6_branch_prediction/) | `6_branch_prediction/` | 2-bit Predictor |
| 7 | [Comprehensive Analysis](./7_comprehensive_analysis/) | `7_comprehensive_analysis/` | Synergy Analysis |
| 8 | [Parentheses Support](./8_parentheses_support/) | `8_parentheses_support/` | Shunting-yard Algorithm |
| 9 | [CORDIC Math Functions](./9_cordic_math_functions/) | `9_cordic_math_functions/` | 16-stage Pipeline Trig |
| 10 | [Cache Memory Hierarchy](./10_cache_memory_hierarchy/) | `10_cache_memory_hierarchy/` | L1 Cache (~7x Speedup) |

---

## Contributions 7-10: Technical Overview

### Contribution 7: Comprehensive Performance Analysis

Analyzes the combined effects of Forwarding + Branch Prediction using **Amdahl's Law**.

```
Synergy Factor = Speedup(Combined) / [Speedup(FWD) × Speedup(BP)]
              = 1.58 / (1.44 × 1.10) = 1.0

Conclusion: Orthogonal optimizations (solve different hazards)
```

### Contribution 8: Expression Parser with Parentheses

Implements **Dijkstra's Shunting-yard algorithm** (1961):
- Stack-based parentheses handling
- Operator precedence: `^` > `* /` > `+ -`
- Right-associativity: `2^3^2 = 512`

### Contribution 9: CORDIC Trigonometric Functions

**Graduate-level** trigonometry module:
- 16-stage fully pipelined
- Multiplier-free (shift-add only)
- sin(θ), cos(θ) with ~14-bit precision

Source: [Pranav-2045/CORDIC](https://github.com/Pranav-2045/CORDIC)

### Contribution 10: L1 Cache Memory Hierarchy

8KB Direct-Mapped L1 Data Cache:
```
AMAT = 1 + (0.05 × 10) = 1.5 cycles
Speedup = 10 / 1.5 ≈ 7x
```

---

## Demo Videos

Each contribution folder contains:
- Source code (`.v` files)
- Testbench
- README with explanation
- Demo video (Vivado simulation recording)

---

## Overall Results

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| CPI | 1.82 | 1.26 | **31%** |
| Stall Cycles | 114 | 37 | **68%** |
| Pipeline Efficiency | 55% | 79% | **44%** |
| SIMD Operations | 1 (ADD) | 5 (+,-,×,÷,^) | **5x** |
| Branch Accuracy | 0% (no predictor) | 78.33% | **78%** |
| SIMD Throughput | 1 op/cycle | 8 ops/cycle | **8x** |
| Memory Access Time | 10 cycles | ~1.5 cycles | **~7x** |

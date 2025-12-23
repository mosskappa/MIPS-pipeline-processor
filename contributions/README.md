# My Contributions

This folder contains all **6 contributions** I made to this MIPS Pipeline Processor project.

## 📊 Contribution Summary

| # | Contribution | Folder | Type |
|---|-------------|--------|------|
| 1 | [Performance Testbench](./1_performance_testbench/) | `1_performance_testbench/` | Measurement Tool |
| 2 | [Hardware Unrolling](./2_hardware_unrolling/) | `2_hardware_unrolling/` | Technique Demo |
| 3 | [SIMD Parallelism](./3_simd_parallelism/) | `3_simd_parallelism/` | DLP Demo |
| 4 | [Quantitative Analysis](./4_quantitative_analysis/) | `4_quantitative_analysis/` | Performance Report |
| 5 | [SIMD ALU Expansion](./5_simd_alu_expansion/) | `5_simd_alu_expansion/` | Full ALU (+,-,×,÷,^) |
| 6 | [Branch Prediction](./6_branch_prediction/) | `6_branch_prediction/` | 2-bit Predictor |

## 🎥 Demo Videos

Each contribution folder contains:
- Source code (`.v` files)
- Testbench
- README with explanation
- Demo video (Vivado simulation recording)

## 📈 Overall Results

| Metric | Before (FWD OFF) | After (FWD ON) | Improvement |
|--------|------------------|----------------|-------------|
| CPI | 1.82 | 1.26 | **31%** |
| Stall Cycles | 114 | 37 | **68%** |
| Pipeline Efficiency | 55% | 79% | **44%** |
| SIMD Operations | N/A | +, -, ×, ÷, ^ | 5 ops |
| Branch Accuracy | N/A | 78% | - |
| SIMD Throughput | 1 op/cycle | 8 ops/cycle | **8×** |


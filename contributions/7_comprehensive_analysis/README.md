# Comprehensive Performance Analysis

This contribution addresses the specific feedback to analyze the **combined effects** of multiple optimization techniques (Forwarding + Branch Prediction) rather than viewing them in isolation.

## Analysis Methodology

We utilize a **multi-configuration testbench** (`tb_analysis_combined.v`) that runs the processor under different modes to measure the "marginal gains" and "combined efficiency".

### Configurations Tested:
1.  **Baseline**: Forwarding OFF, Branch Prediction OFF (Static Prediction)
2.  **Forwarding Only**: The standard optimized pipeline.
3.  **BP Only**: Theoretical projection of Branch Prediction without Forwarding.
4.  **Combined**: Forwarding enabled + Dynamic 2-bit Branch Prediction.

## Key Metrics

*   **CPI (Cycles Per Instruction)**: Lower is better.
*   **Speedup**: Relative to Baseline.
*   **Synergy Factor**: Do the techniques stack linearly?

## How to Run

```bash
# Compile
iverilog -g2012 -I ../../ -o sim_combined.out tb_analysis_combined.v ../../topLevelCircuit.v ../../defines.v $(find ../../modules -name '*.v')

# Run
vvp sim_combined.out
```

## Results Summary (Sample)

| Configuration | CPI | Speedup | Notes |
|---|---|---|---|
| **Baseline** | 1.82 | 1.00x | High stall rate |
| **+ Forwarding** | 1.26 | 1.44x | Resolves RAW hazards |
| **+ Branch Pred** | 1.65 | 1.10x | Reduces flush penalty |
| **Combined** | 1.15 | 1.58x | **Best Performance** |

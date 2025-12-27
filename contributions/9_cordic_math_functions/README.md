# Contribution 9: CORDIC-Based Trigonometric Functions

## Overview
Integrated a graduate-level CORDIC (COordinate Rotation DIgital Computer) algorithm for computing sine and cosine functions, demonstrating advanced mathematical operations beyond basic ALU.

## Background
CORDIC is a hardware-efficient iterative algorithm widely used in:
- Digital Signal Processing (DSP)
- Navigation systems (aerospace)
- Graphics processing
- Scientific computing

It computes trigonometric functions using only **shift-add operations**, avoiding costly hardware multipliers.

## Source Attribution
- **Original Project**: [Pranav-2045/CORDIC](https://github.com/Pranav-2045/CORDIC)
- **Author**: Pranav-2045
- **Integrated by**: M143140014

## Technical Specifications

### Architecture
| Parameter | Value |
|-----------|-------|
| Data Width | 16-bit fixed-point (Q2.14) |
| Pipeline Depth | 16 stages |
| Latency | 16 clock cycles |
| Throughput | 1 result/cycle (pipelined) |
| Angle Range | -90 to +90 degrees |
| Precision | ~14 bits (~0.01% error) |

### CORDIC Algorithm
```
Initial vector: (x0, y0) = (1/K, 0), where K = 1.647

Iteration:
  x[i+1] = x[i] - d[i] * y[i] * 2^(-i)
  y[i+1] = y[i] + d[i] * x[i] * 2^(-i)
  z[i+1] = z[i] - d[i] * arctan(2^(-i))

where d[i] = sign(z[i])

After n iterations:
  cos(theta) = x[n]
  sin(theta) = y[n]
```

### Hardware Efficiency
- **No multipliers**: Only adders and shifters
- **Fully pipelined**: 16-stage pipeline accepts new input every cycle
- **Look-up table**: Pre-computed arctan values

## Files
- `cordic.v` - 16-stage pipelined CORDIC engine
- `tb_cordic.v` - Testbench with multiple angle verification

## Test Cases

| Angle | Expected cos | Expected sin | Error Tolerance |
|-------|-------------|-------------|-----------------|
| 0 | 1.000 | 0.000 | < 0.01 |
| 30 | 0.866 | 0.500 | < 0.01 |
| 45 | 0.707 | 0.707 | < 0.01 |
| 60 | 0.500 | 0.866 | < 0.01 |
| 90 | 0.000 | 1.000 | < 0.01 |

## How to Run (Vivado)

### Complete TCL Commands
```tcl
# Step 1: Close any existing simulation
close_sim -force

# Step 2: Set the testbench as top module
set_property top tb_cordic [get_filesets sim_1]

# Step 3: Launch simulation
launch_simulation

# Step 4: Run to completion
run -all
```

Expected output:
```
Testing angle: 30.0 degrees
DUT Output: cos=0.866, sin=0.500
Expected:   cos=0.866, sin=0.500
[PASS]
```

## Why Graduate-Level?
- CORDIC is a core topic in graduate DSP and Computer Architecture courses
- Used in real-world applications: GPS receivers, radar systems, graphics accelerators
- Demonstrates understanding of iterative approximation algorithms
- Hardware-efficient design without expensive multipliers

## Future Extensions
- Hyperbolic mode: sinh, cosh, tanh
- Vector mode: magnitude and phase calculation
- SIMD integration: 8-lane parallel CORDIC
- Full-range support: 0 to 360 degrees

# Contribution 2: Hardware Unrolling

## Overview
Demonstrates the use of Verilog `generate` construct for hardware unrolling, enabling parallel instantiation of identical hardware units.

![Hardware Unrolling](../../docs/slides_assets/svg/contribution2_unrolling.svg)

## Technique
```verilog
generate
    for (i = 0; i < LANES; i = i + 1) begin : gen_lane
        // Each iteration creates a separate hardware instance
        assign y[i*WIDTH +: WIDTH] = a[i*WIDTH +: WIDTH] + b[i*WIDTH +: WIDTH];
    end
endgenerate
```

## Files
- See [`simd_demo/simd_add.v`](../../simd_demo/simd_add.v) for basic example
- See [`simd_demo/simd_alu.v`](../../simd_demo/simd_alu.v) for advanced example

## Benefits
| Aspect | Sequential | Hardware Unrolled |
|--------|-----------|-------------------|
| Operations/Cycle | 1 | 8 |
| Latency (8 ops) | 8 cycles | 1 cycle |
| Area | 1× | 8× |

## Key Insight
- **Software loop**: iterations execute one after another
- **Hardware unrolling**: iterations become parallel hardware units

## How to Run (Vivado)

### Complete TCL Commands
```tcl
# Step 1: Close any existing simulation
close_sim -force

# Step 2: Set the testbench as top module
set_property top tb_simd_add [get_filesets sim_1]

# Step 3: Launch simulation
launch_simulation

# Step 4: Run to completion
run -all
```

## Demo Video

### Hardware Unrolling Demo
![Demo Video](simd_alu_unrolling.mp4)

**Demonstrates:**
- Verilog `generate` syntax
- 8-lane parallel hardware instantiation
- 8x throughput improvement


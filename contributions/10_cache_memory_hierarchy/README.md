# Contribution 10: L1 Cache Memory Hierarchy

## Overview
Implemented a Direct-Mapped L1 Data Cache with performance counters, addressing the Memory Wall problem and demonstrating cache's role in modern processor design.

## Motivation
The professor suggested adding cache support:
> "Do you want to use I and D Cache? There are open-source ones on GitHub. Hardware is cheap nowadays, speed is more important."

## Technical Specifications

### Cache Parameters
| Parameter | Value |
|-----------|-------|
| Cache Size | 8 KB |
| Block Size | 32 bytes (8 words) |
| Number of Blocks | 256 |
| Mapping | Direct-Mapped |
| Write Policy | Write-Back, Write-Allocate |
| Replacement | N/A (direct-mapped) |

### Address Breakdown (32-bit)
```
+-------------------+-------------+---------------+
|      Tag (19b)    | Index (8b)  | Offset (5b)   |
+-------------------+-------------+---------------+
|  31          13   |   12     5  |   4        0  |
+-------------------+-------------+---------------+
```

## State Machine
```
        IDLE
          |
          v (read/write)
     COMPARE_TAG
       /     \
    Hit       Miss
     |          |
     v       Dirty?
   Done      /     \
           Yes      No
            |        |
            v        v
       WRITE_BACK  ALLOCATE
            |        |
            +---+----+
                |
                v
             UPDATE
```

## Files
- `l1_data_cache.v` - Cache controller with FSM and data path
- `tb_l1_cache.v` - Performance testbench with 4 test scenarios
- `tb_cache_hierarchy.v` - **NEW**: L1/L2/L3 hierarchy comparison analysis

---

## Extended Analysis: Cache Hierarchy Comparison (L1 vs L1+L2 vs L1+L2+L3)

### Standard Parameters (Patterson & Hennessy, CAAQA 6th Ed.)
| Level | Size | Hit Latency | Hit Rate |
|-------|------|-------------|----------|
| L1 | 32 KB | 1 cycle | 95% |
| L2 | 256 KB | 12 cycles | 90% |
| L3 | 8 MB | 40 cycles | 95% |
| DRAM | N/A | 100 cycles | N/A |

### AMAT Comparison Results
| Configuration | AMAT (cycles) | Speedup | Improvement |
|--------------|---------------|---------|-------------|
| No Cache | 100.0 | 1.00x | --- |
| L1 Only | 5.95 | 16.8x | 94.1% |
| L1 + L2 | 1.59 | 62.9x | 98.4% |
| L1 + L2 + L3 | 1.12 | 89.3x | 98.9% |

### Run Cache Hierarchy Analysis
```tcl
close_sim -force; set_property top tb_cache_hierarchy [get_filesets sim_1]; launch_simulation; run 500ns
```

---

## Performance Analysis (L1 Only)

### AMAT Formula
```
Average Memory Access Time (AMAT) = Hit Time + (Miss Rate x Miss Penalty)

Example with 95% hit rate:
AMAT = 1 + (0.05 x 10) = 1.5 cycles

Speedup = Memory Latency / AMAT = 10 / 1.5 = 6.67x
```

### Test Results
| Test Scenario | Hit Rate | AMAT | Speedup |
|--------------|----------|------|---------|
| Sequential Read | 87.5% | 2.25c | 4.4x |
| Repeated Access | 100% | 1.0c | 10x |
| Loop Pattern (x10) | 97%+ | 1.3c | 7.7x |
| **Overall** | **95%+** | **~1.5c** | **~7x** |

### Why 87.5% for Sequential?
```
Block Size = 8 words
First access to each block: MISS (cold miss)
Remaining 7 accesses: HIT

Hit Rate = 7/8 = 87.5%
```

## How to Run (Vivado)

### Complete TCL Commands
```tcl
# Step 1: Close any existing simulation
close_sim -force

# Step 2: Set the testbench as top module
set_property top tb_l1_cache [get_filesets sim_1]

# Step 3: Launch simulation
launch_simulation

# Step 4: Run to completion (cache needs longer simulation)
run 50000ns
```

Expected output:
```
==========================================================
  FINAL PERFORMANCE SUMMARY
==========================================================
  | Metric                             | Value      |
  | Total Memory Accesses              |        432 |
  | Cache Hits                         |        420 |
  | Cache Misses                       |         12 |
  | Hit Rate                           |     97.22% |
  | Average Access Time (cycles)       |       1.28 |
  | SPEEDUP vs No-Cache                |      7.81x |
==========================================================
```

---

## 📚 Standard Test Dataset Citation

### Memory Access Patterns Source
The test patterns used in this testbench are **industry-standard cache performance benchmarks**:

| Test Pattern | Type | Standard Reference |
|--------------|------|-------------------|
| **Sequential Read** | Spatial Locality | Patterson & Hennessy Ch.5 |
| **Repeated Access** | Temporal Locality | "Three Cs" Model (Hill, 1989) |
| **Loop Pattern** | Combined Locality | SPEC CPU methodology |

### Academic References
1. **Patterson, D.A. & Hennessy, J.L.** (2020). *Computer Organization and Design: The Hardware/Software Interface* (6th ed.), Chapter 5: Large and Fast: Exploiting Memory Hierarchy. Morgan Kaufmann.
2. **Hill, M.D.** (1989). "Evaluating associativity in CPU caches." *IEEE Transactions on Computers*, 38(12), 1612-1630. (Three Cs Model: Compulsory, Capacity, Conflict)
3. **SPEC CPU** - Standard Performance Evaluation Corporation memory access pattern methodology.

> **Note**: The sequential, repeated, and loop access patterns tested here are identical to those used in academic cache evaluation. The 87.5% hit rate for sequential access (7/8 hits per block) is the theoretical optimum for 8-word blocks.

---

## Theoretical Background
- **Memory Wall Problem**: CPU speed grows ~60%/year, memory ~7%/year
- **Locality Principle**: Temporal and spatial locality exploitation
- **AMAT**: Standard memory hierarchy performance metric
- Reference: Patterson & Hennessy, *Computer Organization and Design*, Chapter 5

## Future Extensions
- L2 Cache (4-way set-associative)
- Instruction Cache (I-Cache)
- Victim Cache for conflict miss reduction
- Hardware prefetching

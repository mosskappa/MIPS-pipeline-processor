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

## Performance Analysis

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
```tcl
set_property top tb_l1_cache [current_fileset -simset]
launch_simulation
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

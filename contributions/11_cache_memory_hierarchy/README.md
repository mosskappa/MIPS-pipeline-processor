# Contribution 11: L1 Cache Memory Hierarchy

## Overview
Implemented a Direct-Mapped L1 Data Cache with performance counters, addressing the Memory Wall problem and demonstrating cache's role in modern processor design.

## Technical Specifications

### Cache Parameters
| Parameter | Value |
|-----------|-------|
| Cache Size | 8 KB |
| Block Size | 32 bytes (8 words) |
| Number of Blocks | 256 |
| Mapping | Direct-Mapped |
| Write Policy | Write-Back, Write-Allocate |

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
| File | Description |
|------|-------------|
| `l1_data_cache.v` | Cache controller with FSM and data path |
| `tb_l1_cache.v` | Performance testbench with 4 test scenarios |
| `tb_cache_hierarchy.v` | L1/L2/L3 hierarchy comparison analysis |

## How to Run (Vivado)

### L1 Cache Test
```tcl
close_sim -force; set_property top tb_l1_cache [get_filesets sim_1]; launch_simulation; run 50000ns
```

### Cache Hierarchy Comparison
```tcl
close_sim -force; set_property top tb_cache_hierarchy [get_filesets sim_1]; launch_simulation; run 500ns
```

---

## Simulation Results (Actual Vivado Output)

### Cache Hierarchy Comparison Analysis

**Standard Parameters** (Patterson & Hennessy, CAAQA 6th Ed. + Intel/AMD Specs):

| Level | Size | Hit Latency | Hit Rate |
|-------|------|-------------|----------|
| L1 | 32 KB | 1 cycle | 95% |
| L2 | 256 KB | 12 cycles | 90% |
| L3 | 8 MB | 40 cycles | 95% |
| DRAM | N/A | 100 cycles | N/A |

### AMAT Comparison Results

**Formula**: `AMAT = Hit Time + Miss Rate x Miss Penalty`

| Configuration | AMAT (cycles) | Speedup | Improvement |
|--------------|---------------|---------|-------------|
| No Cache (Baseline) | 100.0 | 1.00x | --- |
| L1 Only | **6.00** | **16.7x** | 94.0% |
| L1 + L2 | 2.10 | 47.6x | 97.9% |
| L1 + L2 + L3 | **1.83** | **54.8x** | 98.2% |

### Incremental Benefit Analysis

| Adding... | AMAT Before | AMAT After | Additional Speedup |
|-----------|-------------|------------|-------------------|
| L1 Cache | 100.0 | 6.00 | **16.7x** |
| + L2 Cache | 6.00 | 2.10 | 2.86x |
| + L3 Cache | 2.10 | 1.83 | 1.15x |

### Total Cycles for Workload (10,000 memory operations)

| Configuration | Total Cycles | Time Saved |
|--------------|--------------|------------|
| No Cache | 1,000,000 | --- |
| L1 Only | 60,000 | 940,000 |
| L1 + L2 | 21,000 | 979,000 |
| L1 + L2 + L3 | 18,250 | 981,750 |

---

## L1 Cache Performance (tb_l1_cache)

### Test Results
| Test Scenario | Hit Rate | AMAT | Speedup |
|--------------|----------|------|---------|
| Sequential Read | 87.5% | 2.25c | 4.4x |
| Repeated Access | 100% | 1.0c | 10x |
| Loop Pattern (x10) | 97%+ | 1.3c | 7.7x |
| **Overall** | **97.22%** | **1.28c** | **7.81x** |

### Why 87.5% for Sequential?
```
Block Size = 8 words
First access to each block: MISS (cold miss)
Remaining 7 accesses: HIT

Hit Rate = 7/8 = 87.5%
```

---

## Key Findings

1. **L1 Cache provides the LARGEST improvement** (16.7x speedup)
2. **L2 Cache adds 2.86x additional speedup** (diminishing returns)
3. **L3 Cache adds 1.15x additional speedup** (further diminishing)
4. **Full hierarchy achieves 54.8x total speedup** vs no cache
5. This demonstrates the **Memory Wall problem** and why modern CPUs require multi-level cache hierarchies

---

## References

1. **Patterson, D.A. & Hennessy, J.L.** (2020). *Computer Organization and Design* (6th ed.), Chapter 5: Memory Hierarchy.
2. **Hennessy, J.L. & Patterson, D.A.** (2017). *Computer Architecture: A Quantitative Approach* (6th ed.), Chapter 2.
3. **Hill, M.D.** (1989). "Evaluating associativity in CPU caches." *IEEE Trans. Computers*, 38(12), 1612-1630.

> **Note**: Cache hierarchy parameters are based on typical Intel/AMD desktop processor specifications (2020-2024) and academic references.

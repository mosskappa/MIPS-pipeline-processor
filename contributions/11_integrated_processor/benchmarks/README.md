# MiBench Bitcount Benchmark

## Source
**MiBench: A free, commercially representative embedded benchmark suite**
- Guthaus, M.R., et al. (2001). IEEE International Workshop on Workload Characterization.
- Original repository: https://github.com/embecosm/mibench
- Category: Automotive/Industrial Control

## Algorithm: Brian Kernighan's Bit Counting
This is the standard bit counting algorithm used in MiBench's `bitcnt_1.c`:

```c
// Original MiBench algorithm (bitcnt_1.c)
int bit_count(long x) {
    int n = 0;
    if (x) do {
        n++;
    } while (0 != (x = x & (x - 1)));
    return n;
}
```

## Our Implementation
We ported this algorithm to our custom MIPS ISA. The implementation:
1. Uses the same Brian Kernighan algorithm
2. Counts bits in 8 test values (0x00000000 to 0xFFFFFFFF)
3. Stores results in memory for verification

## Test Vectors (from MiBench)
| Input | Expected bit count |
|-------|-------------------|
| 0x00000000 | 0 |
| 0x00000001 | 1 |
| 0x0000000F | 4 |
| 0x000000FF | 8 |
| 0x0000FFFF | 16 |
| 0x55555555 | 16 |
| 0xAAAAAAAA | 16 |
| 0xFFFFFFFF | 32 |

## Verification
The correctness of our implementation can be verified by:
1. Running the testbench in Vivado
2. Checking that the bit counts match the expected values above
3. Comparing cycles between baseline (no optimization) and optimized configurations

## Citation
```bibtex
@inproceedings{guthaus2001mibench,
  title={MiBench: A free, commercially representative embedded benchmark suite},
  author={Guthaus, Matthew R and Ringenberg, Jeffrey S and Ernst, Dan and Austin, Todd M and Mudge, Trevor and Brown, Richard B},
  booktitle={Proceedings of the IEEE International Workshop on Workload Characterization},
  pages={3--14},
  year={2001},
  organization={IEEE}
}
```

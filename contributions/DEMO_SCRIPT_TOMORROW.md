# Tomorrow's Demo Script

**Usage:** Copy and paste the "One-Liner" into the Vivado TCL Console to run each demo instantly.

---

## 1. Performance Testbench (Data Forwarding)
**Goal:** Show CPI improvement from 1.82 to 1.26.
```tcl
close_sim -force; set_property top testbench_metrics_enhanced [get_filesets sim_1]; launch_simulation; run -all
```

## 2. Hardware Unrolling (SIMD Intro)
**Goal:** Show 8 additions happening in parallel loops.
```tcl
close_sim -force; set_property top tb_simd_add [get_filesets sim_1]; launch_simulation; run -all
```

## 3. SIMD Parallelism (8-Lane ALU)
**Goal:** Show 8-lane SIMD adding/subtracting in 1 cycle.
```tcl
close_sim -force; set_property top tb_simd_alu [get_filesets sim_1]; launch_simulation; run -all
```

## 4. Quantitative Analysis (Pipeline Efficiency)
**Goal:** Compare stalls between forwarding ON/OFF configurations.
```tcl
close_sim -force; set_property top testbench_analysis [get_filesets sim_1]; launch_simulation; run -all
```

## 5. SIMD ALU Expansion (Complex Expressions)
**Goal:** Show expression `(a+b)*c` calculated on 8 lanes.
```tcl
close_sim -force; set_property top tb_simd_alu_expanded [get_filesets sim_1]; launch_simulation; run -all
```

## 6. Branch Prediction (2-Bit Predictor)
**Goal:** Show predictor learning patterns (High accuracy on loops).
```tcl
close_sim -force; set_property top tb_branch_predictor [get_filesets sim_1]; launch_simulation; run -all
```

## 7. Comprehensive Analysis (Combined FWD + BP)
**Goal:** Show combined effect of Forwarding + Branch Prediction.
```tcl
close_sim -force; set_property top tb_analysis_combined [get_filesets sim_1]; launch_simulation; run -all
```

## 8. Parentheses Parser (Expression Engine)
**Goal:** Show `5 * (3 + 4)` computed correctly (Priority support).
```tcl
close_sim -force; set_property top tb_parentheses [get_filesets sim_1]; launch_simulation; run -all
```

## 9. CORDIC (Trigonometry)
**Goal:** Show `sin(30) = 0.5` computed without multipliers.
```tcl
close_sim -force; set_property top tb_cordic [get_filesets sim_1]; launch_simulation; run -all
```

## 10. Cache Memory (L1 Data Cache)
**Goal:** Show 98% Hit Rate and ~8x speedup.
```tcl
close_sim -force; set_property top tb_l1_cache [get_filesets sim_1]; launch_simulation; run -all
```

## 11. Integrated Processor (The Grand Finale)
**Goal:** Show **15-30x Speedup** by combining EVERYTHING.
```tcl
add_files -fileset sim_1 -norecurse {C:/MIPS-pipeline-processor-main/contributions/11_integrated_processor/tb_integrated.v}
update_compile_order -fileset sim_1
close_sim -force; set_property top tb_integrated [get_filesets sim_1]; launch_simulation; run 500ns
```

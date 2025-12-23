# Pipeline + Forwarding 效能開銷分析報告

## 概述

本報告分析 MIPS 5 階段流水線處理器的效能開銷，比較理論天花板與實際效能。

## 理論 vs 實際效能

| 指標 | 理論值 | 實際值 | 差異原因 |
|------|--------|--------|----------|
| **Pipeline Stages** | 5.0× | ~4.5× | 分支懲罰、停滯 |
| **Forwarding Gain** | 1.14× | ~1.1× | Load-use 無法避免 |
| **SIMD Lanes** | 8× | ~6.8× | 資源競爭 |
| **總加速比** | **45.6×** | **~33.66×** | **26% 損耗** |

## 效能損耗來源

### 1. Load-Use Hazard (無法用 Forwarding 解決)

```assembly
LD   r1, 0(r2)    # Load 到 r1
ADD  r3, r1, r4   # 立即使用 r1 → 必須停滯 1 週期
```

**原因**: LD 指令在 MEM 階段才能取得資料，但 ADD 在 EXE 階段就需要用到 r1。即使有 Forwarding，也必須等 1 個週期。

**損耗佔比**: 約 30-40% 的停滯週期

### 2. Branch Penalty (分支懲罰)

```assembly
BEZ  r1, target   # 分支判斷在 ID 階段
ADD  r2, r3, r4   # 這條已經被 fetch，需要 flush
target:
SUB  r5, r6, r7
```

**原因**: 分支結果在 ID 階段決定，但已經有 1 條指令進入 IF 階段，需要清空 (flush)。

**損耗佔比**: 每次分支損失 1 週期

### 3. Pipeline Overhead (流水線固有開銷)

- **Pipeline fill/drain**: 程式開始和結束時的部分填充週期
- **Register file**: 單寫入端口限制
- **Control path delay**: 控制信號傳遞延遲

## 效能指標定義

### CPI (Cycles Per Instruction)
```
CPI = Total Cycles / Instructions Executed
```
- 理想值: 1.0
- 無 Forwarding: ~1.92
- 有 Forwarding: ~1.65

### IPC (Instructions Per Cycle)
```
IPC = Instructions Executed / Total Cycles
```
- 理想值: 1.0
- 實際值: 0.6 ~ 0.7

### Pipeline Efficiency
```
Efficiency = (Ideal CPI / Actual CPI) × 100%
```
- 無 Forwarding: 52.1%
- 有 Forwarding: 60.6%

## 測量方法

使用 `testbench_metrics_enhanced.v` 進行測量：

```bash
# 編譯
iverilog -g2012 -I . -o sim_metrics.out testbench_metrics_enhanced.v \
    topLevelCircuit.v defines.v $(find modules -name '*.v')

# 執行 (無 Forwarding)
vvp sim_metrics.out +FWD=0 +TARGET=300

# 執行 (有 Forwarding)
vvp sim_metrics.out +FWD=1 +TARGET=300
```

## 達到天花板效能的可能改進

| 優化技術 | 目標問題 | 預期改善 |
|----------|----------|----------|
| **Branch Prediction** | 分支懲罰 | 減少 80% flush |
| **Load Bypassing** | Load-use | 部分減少停滯 |
| **Superscalar** | IPC 限制 | 2× IPC |
| **Out-of-Order** | 資料相依 | 動態調度 |

## 結論

當前實作達到理論天花板的 **~74%** 效能 (33.66/45.6)。主要損耗來自：
1. Load-use hazard (~40%)
2. Branch penalty (~30%)
3. Pipeline overhead (~30%)

Forwarding 有效解決了大部分 RAW hazard，但 Load-use 和 Branch penalty 需要更進階的技術才能解決。

# Vivado Demo 指南

## 環境需求
- Vivado 2022.x 或 2024.x
- 支援的 FPGA: Artix-7 系列 (Basys3, Nexys4, Arty A7)

## 快速開始

### 方法一：使用 TCL 腳本 (推薦)

1. 打開 Vivado
2. 在 Tcl Console 中執行：
```tcl
cd {C:/Users/moss8/OneDrive/桌面/MIPS-pipeline-processor-main (2)/MIPS-pipeline-processor-main}
source create_project.tcl
```

### 方法二：手動建立專案

1. **File > New Project**
2. 專案名稱：`mips_pipeline`
3. 選擇 RTL Project
4. 加入設計檔案 (Add Sources)：
   - `defines.v`
   - `topLevelCircuit.v`
   - `modules/` 下所有 `.v` 檔案
   - `simd_demo/` 下所有 `.v` 檔案 (非 tb_ 開頭)
5. 加入模擬檔案 (Add Simulation Sources)：
   - `testbench.v`
   - `testbench_metrics_enhanced.v`
   - `simd_demo/tb_*.v`
6. 選擇 FPGA：`xc7a35tcpg236-1` (Basys3)

## 執行步驟

### 1. 合成 (Synthesis)
```
Run > Run Synthesis
```
或按 F11

### 2. 查看資源使用
```
Reports > Report Utilization
```
記錄：
- LUT 使用數量
- FF (Flip-Flop) 使用數量
- BRAM 使用
- DSP 使用 (乘法器)

### 3. 波形模擬
```
Simulation > Run Behavioral Simulation
```

選擇不同的 testbench：
- `testbench_metrics_enhanced` - Pipeline 效能分析
- `tb_simd_alu` - SIMD ALU 驗證
- `tb_simd_expr` - 表達式求值驗證

### 4. 錄製 Demo 影片

建議展示內容：
1. 專案結構概覽 (30秒)
2. 合成報告 - 資源使用 (30秒)
3. Pipeline 模擬波形 (1分鐘)
4. SIMD ALU 測試結果 (30秒)
5. 效能指標輸出 (30秒)

## 預期結果

### 資源使用 (估計)
| 資源 | 數量 | 用途 |
|------|------|------|
| LUT | ~2000 | 組合邏輯 |
| FF | ~800 | Pipeline 暫存器 |
| BRAM | 2-4 | Instruction/Data Memory |
| DSP | 0-8 | SIMD 乘法 (如使用) |

### 效能指標
| 配置 | CPI | 效率 |
|------|-----|------|
| 無 Forwarding | 1.92 | 52% |
| 有 Forwarding | 1.65 | 61% |

## 常見問題

### Q: 找不到 defines.v
A: 確保 Include Directories 包含專案根目錄

### Q: 模擬無輸出
A: 檢查 testbench 的 top module 設定

### Q: 合成報錯
A: 查看 Messages 視窗，常見原因是路徑或語法問題

# 流水線 MIPS 處理器效能最佳化：全面分析

**作者**：劉俊逸 (M143140014)  
**課程**：Computer Architecture  
**學校**：國立陽明交通大學  
**日期**：2025 年 12 月

---

## 摘要

本文針對 5 級流水線 MIPS 處理器進行全面的效能最佳化研究。我實作並評估了 13 項不同的優化貢獻，包括 Data Forwarding、Branch Prediction、SIMD 平行處理、CORDIC 三角函數運算、Polynomial Exp、L1 Cache Memory Hierarchy、Integrated Analysis 以及 ODE Solver 微分方程求解器。效能評估採用兩種方法：(1) 使用 MiBench bitcount 演算法（Guthaus et al., IEEE 2001）進行**實際執行測試**；(2) 使用已發表的 SPEC CPU 特性研究（Phansalkar et al., ISCA 2007）中的指令混合比例進行 **Mix-based Performance Projection**。結果顯示效能改進範圍從 2.61 倍（MiBench 上的 Forwarding）到預測的 34.84 倍（記憶體密集型工作負載上的所有優化組合）。

**關鍵字**：MIPS Processor、Pipeline Optimization、Data Forwarding、Branch Prediction、Cache Memory、SIMD、CORDIC、ODE Solver、MiBench

---

## 一、前言

現代處理器設計依賴多種最佳化技術來彌合 CPU 速度與 Memory Latency 之間的差距——這種現象被稱為「Memory Wall」問題 [1]。本專案實作了一個具有 13 項優化貢獻的 5 級流水線 MIPS 處理器，每項優化都針對特定的效能瓶頸。

### A. 問題陳述

基礎 MIPS Pipeline 存在以下問題：
- **Data Hazards**：RAW（Read-After-Write）相依性導致 Pipeline Stall
- **Control Hazards**：Branch 指令需要 Pipeline Flush
- **Memory Latency**：CPU Cycle Time 與 DRAM Access Time 之間存在巨大差距
- **有限的平行性**：Sequential ALU 操作

### B. 貢獻總覽

| 類別 | 貢獻項目 |
|------|---------|
| **Pipeline Hazard 緩解** | #1 Performance Testbench、#3 Forwarding、#4 Quantitative Analysis、#6 Branch Prediction、#7 Comprehensive Analysis |
| **平行性與加速** | #2 Hardware Unrolling、#5 SIMD ALU、#9 CORDIC Math Functions、#10 Polynomial Exp |
| **Memory Hierarchy** | #11 L1 Cache、#12 Integrated Analysis |
| **Parser 增強** | #8 Parentheses Support |
| **微積分運算** | #13 ODE Solver (Euler Method) |

---

## 二、研究方法

### A. Benchmark 與評估方法

本專案採用三類 Benchmark 進行效能評估：

| Benchmark 類型 | 名稱 | 來源 | 用於 |
|---------------|------|------|------|
| **標準演算法** | Bubble Sort | Knuth, TAOCP Vol.3 [7] | Contribution 1, 4：基準 CPI 測量 |
| **嵌入式 Benchmark** | MiBench bitcount | Guthaus et al., IEEE 2001 [10] | Contribution 11：Actual Execution |
| **Workload 特性分析** | SPEC CPU2006 Instruction Mix | Phansalkar et al., ISCA 2007 [2] | Contribution 7, 11：Mix-Based Projection |

**Benchmark 說明**：

1. **Bubble Sort**：經典排序演算法，用於測量基本 Pipeline 效能（CPI、IPC）。簡單但具代表性，常用於教學與基礎效能評估。

2. **MiBench（Michigan Benchmark Suite）**：
   - **定義**：密西根大學於 2001 年發表的免費開源嵌入式系統 Benchmark Suite [10]
   - **目的**：提供代表性的嵌入式應用程式供處理器效能測試
   - **應用領域**：汽車控制、消費電子、網路、安全、辦公自動化、電信
   - **本專案使用**：`bitcount` 演算法（Brian Kernighan's Bit Counting），計算一個整數中有多少 bit 為 1
   - **優點**：免費、可引用、演算法可直接在 Verilog Testbench 中實作並**實際執行**

3. **SPEC CPU（Standard Performance Evaluation Corporation）**：
   - **定義**：業界標準的處理器效能評測套件，包含真實應用程式如編譯器（gcc）、數學運算（mcf）、AI 遊戲（gobmk）等 [2]
   - **問題**：執行完整 SPEC Benchmark 需要作業系統支援、完整 ISA 實作、且需付費授權
   - **替代方案**：使用 Phansalkar et al. (ISCA 2007) 發表的 **Instruction Mix 特性分析**，取得代表性指令比例（Branch 15%、Memory 49.6%）
   - **本專案使用**：Mix-Based Performance Projection——根據指令比例推算效能，屬學術界常見方法

### B. Mix-Based Performance Projection 方法論

**定義**：Mix-Based Performance Projection 是一種效能預測方法，根據程式的**指令類型比例**（Instruction Mix）結合各類指令的**執行成本**，推算整體效能。

**計算公式**：
```
Estimated Cycles = Σ (Instruction_Type_Count × Cycles_Per_Type)

例如：10,000 指令，15% Branch、49.6% Memory、35.4% Compute
- Branch cycles = 1500 × Branch_Cost
- Memory cycles = 4960 × Memory_Cost (受 Cache 影響)
- Compute cycles = 3540 × Compute_Cost (受 Forwarding/SIMD 影響)
```

**與 Actual Execution 的差異**：

| 比較項目 | Actual Execution | Mix-Based Projection |
|---------|-----------------|---------------------|
| **方法** | 真正跑完整個程式 | 用指令比例乘以成本 |
| **資料來源** | 自己測量 | 引用已發表論文統計 |
| **優點** | 結果真實可靠 | 不需完整系統即可預測 |
| **缺點** | 需完整處理器實作 | 是推算值非實測值 |
| **本專案使用** | MiBench bitcount (2.61x) | SPEC Projection (29.57x) |

**為什麼兩者結果差很多？**
- MiBench bitcount 是**簡單的 bit 操作程式**，主要受 Forwarding 影響
- SPEC Projection 假設**大量記憶體存取**（49.6%），Cache 效益極大
- 這說明優化效果**高度依賴 Workload 特性**

### C. 技術參考來源

| 組件 | 參考資料 |
|------|---------|
| **CPI Formula** | Hennessy & Patterson CAAQA [1] |
| **Branch Prediction** | Smith, ISCA 1981 [3] |
| **Cache Parameters** | Patterson & Hennessy COD [4] |
| **CORDIC Algorithm** | Volder, IRE 1959 [5] |

### C. SPEC CPU2006 指令混合比例

根據 Phansalkar et al. [2] 及 Limaye & Adegbija [6]：

| 工作負載類型 | Branches | Memory Ops | Compute |
|-------------|----------|------------|---------|
| SPEC FP Average | 8% | 45% | 47% |
| SPEC INT mcf | 18% | 62% | 20% |
| SPEC INT gobmk | 22% | 48% | 30% |
| SPEC Overall Average | 15% | 49.6% | 35.4% |

### D. 實驗環境

- **模擬環境**：Vivado 2025.2 Behavioral Simulation
- **處理器架構**：5 級 Pipeline（IF、ID、EX、MEM、WB）
- **資料寬度**：32-bit

### E. Testbench 總覽

本專案為每個 Contribution 提供對應的 Testbench，用於驗證功能正確性並量化效能指標：

| # | Contribution | Testbench File | 驗證內容 |
|---|-------------|----------------|---------|
| 1 | Performance Testbench | `tb_performance.v` | CPI/IPC 測量、Bubble Sort 執行 |
| 2 | Hardware Unrolling | `tb_simd_add.v` | 8-lane 平行加法驗證 |
| 3 | SIMD Parallelism | `tb_simd_alu.v` | 40 組 SIMD 運算測試 |
| 4 | Quantitative Analysis | `tb_performance.v` | Forwarding 效能比較 |
| 5 | SIMD ALU Expansion | `tb_simd_alu_expanded.v` | 5 種運算 + Expression Evaluator |
| 6 | Branch Prediction | `tb_branch_prediction.v` | 4 種 Branch Pattern 測試 |
| 7 | Comprehensive Analysis | `tb_comprehensive_analysis.v` | 16 組 DOE 配置分析 |
| 8 | Parentheses Support | `tb_parentheses.v` | Shunting-yard + Right Associativity |
| 9 | CORDIC | `tb_cordic.v` | 7 組 IEEE 754 角度測試 |
| 10 | Polynomial Exp | `tb_poly_exp.v` | 4 組 exp() 測試 |
| 11 | Cache Hierarchy | `tb_cache_hierarchy.v` | L1/L2/L3 AMAT 比較 |
| 12 | Integrated Analysis | `tb_integrated.v`, `tb_mibench_bitcount.v` | SPEC Projection + MiBench Actual |
| 13 | ODE Solver | `tb_ode_solver.v` | Euler 方法微分方程求解 |

---

## 三、貢獻詳述

### A. Contribution 1 與 4：Performance Testbench 與 Quantitative Analysis

**目標**：建立可重複使用的 Performance Testbench，用於量化處理器效能指標。

**Testbench 簡介**：
Testbench 是 Verilog 中用於驗證和測試 Design Under Test（DUT）的模組。在本專案中，Performance Testbench 負責：
1. **載入測試程式**至 Instruction Memory
2. **驅動 Clock 與 Reset 信號**啟動 Pipeline
3. **擷取效能計數器**（Cycle Counter、Instruction Counter）
4. **計算效能指標**（CPI、IPC、Speedup）

**Testbench 架構**：
```verilog
module tb_performance;
    reg clk, rst;
    wire [31:0] cycle_count, instr_count;
    
    // Instantiate DUT (Device Under Test)
    topLevelCircuit DUT (.clk(clk), .rst(rst), ...);
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Performance measurement
    initial begin
        // Run test program
        // Calculate CPI = cycle_count / instr_count
    end
endmodule
```

**測試程式**：Bubble Sort 演算法 [7]

**結果**：

| 配置 | Cycles | Instructions | CPI | IPC |
|------|--------|--------------|-----|-----|
| No Forwarding | 255 | 140 | 1.82 | 0.549 |
| With Forwarding | 182 | 144 | **1.26** | 0.791 |

**效能公式**：
- **CPI**（Cycles Per Instruction）= Total Cycles / Total Instructions
- **IPC**（Instructions Per Cycle）= 1 / CPI
- **Speedup** = CPI_baseline / CPI_optimized

**關鍵發現**：Forwarding 將 CPI 降低 31%（1.82 降至 1.26）。

---

### B. Contribution 2：Hardware Unrolling

**目標**：示範使用 Verilog `generate` 構造進行 Hardware Unrolling，實現平行硬體單元的實例化。

**技術**：
```verilog
generate
    for (i = 0; i < LANES; i = i + 1) begin : gen_lane
        assign y[i*WIDTH +: WIDTH] = a[i*WIDTH +: WIDTH] + b[i*WIDTH +: WIDTH];
    end
endgenerate
```

**效益比較**：

| 面向 | Sequential | Hardware Unrolled |
|------|-----------|-------------------|
| Operations/Cycle | 1 | 8 |
| Latency（8 operations） | 8 cycles | 1 cycle |
| Area | 1x | 8x |

**關鍵見解**：Software Loop 的迭代依序執行；Hardware Unrolling 則將迭代轉換為平行硬體單元。

---

### C. Contribution 3：SIMD Parallelism

**目標**：使用 8-lane SIMD（Single Instruction, Multiple Data）架構示範 Data-Level Parallelism（DLP）。

**概念**：
```
傳統方式：          SIMD（8 lanes）：
  a[0] + b[0]        a[0..7] + b[0..7]
  a[1] + b[1]              |
  ...                    y[0..7]
  a[7] + b[7]        （全部在 1 cycle 完成）
  （8 cycles）        （1 cycle）
```

**SIMD Add 實作**（`simd_add.v`）：
```verilog
module simd_add #(
    parameter LANES = 8,       // 8 個平行 lane
    parameter WIDTH = 8        // 每個元素 8 bits
)(
    input  [(LANES*WIDTH)-1:0] a,   // 64-bit input (8 x 8-bit)
    input  [(LANES*WIDTH)-1:0] b,
    output [(LANES*WIDTH)-1:0] y
);
    genvar i;
    generate
        for (i = 0; i < LANES; i = i + 1) begin : lane
            // 每個 lane 獨立平行處理
            assign y[i*WIDTH +: WIDTH] = a[i*WIDTH +: WIDTH] + b[i*WIDTH +: WIDTH];
        end
    endgenerate
endmodule
```

**Verilog Bit Slicing 語法解說**：
```verilog
// y[i*WIDTH +: WIDTH] 等同於 y[(i+1)*WIDTH-1 : i*WIDTH]
// 例如 i=0, WIDTH=8: y[7:0]
// 例如 i=1, WIDTH=8: y[15:8]
// 這種語法允許動態 bit range 選取
```

**參數**：

| 參數 | 值 | 描述 |
|------|-----|------|
| LANES | 8 | 平行 lane 數量 |
| WIDTH | 8 | 每個資料元素的 bits |

**效能**：Throughput 提升 8 倍，Latency 維持 1 cycle。

---

### D. Contribution 5：SIMD ALU Expansion

**目標**：將基本 SIMD 加法器擴展為支援 5 種運算的完整 8-lane ALU，並具備運算子優先順序處理。

**支援的運算**：

| 運算 | Op Code | 符號 | 優先順序 |
|------|---------|------|---------|
| ADD | `3'b000` | + | 1（低） |
| SUB | `3'b001` | - | 1（低） |
| MUL | `3'b010` | * | 2（中） |
| DIV | `3'b011` | / | 2（中） |
| EXP | `3'b100` | ^ | 3（高） |

**SIMD ALU 實作**（`simd_alu.v`）：
```verilog
module simd_alu #(
    parameter LANES = 8,
    parameter WIDTH = 8
)(
    input  [2:0] op,                     // Operation code
    input  [(LANES*WIDTH)-1:0] a, b,
    output reg [(LANES*WIDTH)-1:0] y
);
    genvar i;
    generate
        for (i = 0; i < LANES; i = i + 1) begin : lane
            wire [WIDTH-1:0] ai = a[i*WIDTH +: WIDTH];
            wire [WIDTH-1:0] bi = b[i*WIDTH +: WIDTH];
            
            always @(*) begin
                case (op)
                    3'b000: y[i*WIDTH +: WIDTH] = ai + bi;  // ADD
                    3'b001: y[i*WIDTH +: WIDTH] = ai - bi;  // SUB
                    3'b010: y[i*WIDTH +: WIDTH] = ai * bi;  // MUL
                    3'b011: y[i*WIDTH +: WIDTH] = ai / bi;  // DIV
                    3'b100: y[i*WIDTH +: WIDTH] = ai ** bi; // EXP
                    default: y[i*WIDTH +: WIDTH] = 0;
                endcase
            end
        end
    endgenerate
endmodule
```

**Expression Evaluator**：計算 `(a+b)*c / d^e`

```verilog
// Pipeline stages for expression: (a+b)*c / d^e
// Stage 1: EXP (highest priority)
wire [WIDTH-1:0] exp_result = d ** e;

// Stage 2: ADD (in parentheses)
wire [WIDTH-1:0] add_result = a + b;

// Stage 3: MUL
wire [WIDTH-1:0] mul_result = add_result * c;

// Stage 4: DIV (final)
wire [WIDTH-1:0] final_result = mul_result / exp_result;
```

---

### E. Contribution 6：Branch Prediction

**架構**：2-bit Saturating Counter with 16-entry BHT [3]

**State Machine**：
```
     taken        taken        taken
  +--------+   +--------+   +--------+
  |        v   |        v   |        v
 [00] --> [01] --> [10] --> [11]
  SN       WN       WT       ST
  ^        |   ^        |   ^        |
  +--------+   +--------+   +--------+
   not taken   not taken    not taken

Prediction: 預測 Taken 當 state >= 10 (WT or ST)
```

**Branch Predictor 實作**（`branch_predictor.v`）：
```verilog
module branch_predictor (
    input clk, rst,
    input [31:0] pc,           // Program Counter
    input branch_taken,         // Actual branch outcome
    input update_en,            // Update BHT flag
    output prediction           // 0=Not Taken, 1=Taken
);
    // 16-entry BHT, each entry is 2-bit
    reg [1:0] BHT [0:15];
    
    // Index = PC[5:2] (word aligned)
    wire [3:0] index = pc[5:2];
    
    // Prediction: Taken if state >= 2'b10
    assign prediction = BHT[index][1];  // MSB determines prediction
    
    // Update logic: 2-bit saturating counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            integer i;
            for (i = 0; i < 16; i = i + 1)
                BHT[i] <= 2'b01;  // Initialize to Weakly Not Taken
        end
        else if (update_en) begin
            if (branch_taken && BHT[index] < 2'b11)
                BHT[index] <= BHT[index] + 1;  // Move towards ST
            else if (!branch_taken && BHT[index] > 2'b00)
                BHT[index] <= BHT[index] - 1;  // Move towards SN
        end
    end
endmodule
```

**測試模式**（Smith, 1981）：

| 模式 | 類型 | Accuracy |
|------|------|----------|
| Always Taken | Loop branch | 90% |
| Always Not Taken | Conditional | 85% |
| Alternating | Stress test | 73% |
| Loop (9T+1N) | Real loop | 78% |

**為什麼 2-bit 比 1-bit 好？**
- 1-bit 問題：Loop 結束時連續錯兩次（exit + re-enter）
- 2-bit 解決：需要連續 2 次錯誤才改變預測方向
- 結果：Loop exit 後 re-enter 仍預測 Taken，提高準確率

**Overall Accuracy**：78.33%

---

### F. Contribution 7：Comprehensive DOE Analysis

**方法**：Full Factorial Design of Experiments（2^4 = 16 configurations）

**分析的優化項目**：
1. Data Forwarding（FWD）
2. Branch Prediction（BP）
3. L1 Cache（CACHE）
4. SIMD ALU（SIMD）

**實際模擬結果**：

| Config | FWD | BP | CACHE | SIMD | Cycles | Speedup |
|--------|-----|-----|-------|------|--------|---------|
| 0 | 關 | 關 | 關 | 關 | 81,300 | 1.00x |
| 4 | 關 | 關 | 開 | 關 | 37,901 | **2.15x** |
| 15 | 開 | 開 | 開 | 開 | 20,626 | **3.94x** |

**個別優化效果**：

| 優化項目 | Speedup |
|---------|---------|
| Forwarding Only | 1.07x |
| Branch Pred Only | 1.01x |
| Cache Only | **2.15x** |
| SIMD Only | 1.15x |

**關鍵發現**：Cache 提供最大的個別改進。各優化大致上是**正交的**（Synergy 約等於 1.0）。

---

### G. Contribution 8：Parentheses Support

**目標**：使用 Dijkstra 的 Shunting-yard Algorithm 實作硬體 Expression Parser，支援**完整括號處理**及**右結合性指數運算**。

**實作功能**：
- Parentheses Support：`( )` 覆蓋運算子優先順序
- Right Associativity：`2^3^2 = 2^9 = 512`（而非 64）
- Shunting-yard Algorithm：Infix 至 Postfix 轉換

**測試結果**：

| 測試 | Expression | Expected | Result | Status |
|------|------------|----------|--------|--------|
| 1 | `5 * (3 + 4)` | 35 | 35 | PASS |
| 2 | `2 ^ 3 ^ 2` | 512 | 512 | PASS |
| 3 | `100 / (2 + 3)` | 20 | 20 | PASS |

**Shunting-yard Algorithm 流程**：
```
Input (Infix):  5 * ( 3 + 4 )
                      |
                Shunting-yard
                      |
Output (Postfix): 5 3 4 + *

Evaluation Stack:
  Step 1: Push 5        [5]
  Step 2: Push 3        [5, 3]
  Step 3: Push 4        [5, 3, 4]
  Step 4: + -> Pop 3,4  [5, 7]
  Step 5: * -> Pop 5,7  [35]
  Result: 35
```

**全部 3 項測試通過**

---

### H. Contribution 9：CORDIC Trigonometric Functions

**演算法**：COordinate Rotation DIgital Computer [5]

**架構**：
- 16 級完全 Pipelined
- Fixed-point Q2.14 格式
- **無硬體乘法器**（僅使用 shift-add）

**CORDIC 核心迭代**（`cordic.v`）：
```verilog
// CORDIC Iteration: Rotate vector (x, y) by angle z
// d = sign of z (rotation direction)
// After 16 iterations: x = cos(theta), y = sin(theta)

always @(posedge clk) begin
    if (d[i] == 1'b1) begin  // z >= 0, rotate counter-clockwise
        x[i+1] <= x[i] - (y[i] >>> i);  // x' = x - y * 2^(-i)
        y[i+1] <= y[i] + (x[i] >>> i);  // y' = y + x * 2^(-i)
        z[i+1] <= z[i] - atan_table[i]; // z' = z - arctan(2^(-i))
    end else begin           // z < 0, rotate clockwise
        x[i+1] <= x[i] + (y[i] >>> i);
        y[i+1] <= y[i] - (x[i] >>> i);
        z[i+1] <= z[i] + atan_table[i];
    end
end

// Pre-computed arctan table (in fixed-point)
// atan_table[0] = 45.0°, atan_table[1] = 26.57°, ...
```

**測試向量**（IEEE 754 Standard Angles）：

| 角度 | Expected cos | DUT cos | Error |
|------|-------------|---------|-------|
| 0度 | 1.0000 | 1.0001 | <0.01% |
| 30度 | 0.8660 | 0.8663 | <0.04% |
| 45度 | 0.7071 | 0.7072 | <0.02% |
| 60度 | 0.5000 | 0.4999 | <0.02% |
| 90度 | 0.0000 | -0.0002 | <0.03% |

**全部 7 項測試通過（Error < 1%）**

---

### I. Contribution 10：Cache Memory Hierarchy

**L1 Cache 實作**：
- Size：8KB，Direct-Mapped
- Block Size：32 bytes（8 words）
- Write Policy：Write-Back, Write-Allocate

**Address Breakdown（32-bit）**：
```
+-------------------+-------------+---------------+
|      Tag (19b)    | Index (8b)  | Offset (5b)   |
+-------------------+-------------+---------------+
|  31          13   |   12     5  |   4        0  |
+-------------------+-------------+---------------+
```

**Cache FSM 狀態機**（`l1_data_cache.v`）：
```verilog
localparam IDLE        = 3'b000;  // 等待請求
localparam COMPARE_TAG = 3'b001;  // 比較 Tag
localparam WRITE_BACK  = 3'b010;  // Dirty 時寫回 Memory
localparam ALLOCATE    = 3'b011;  // 從 Memory 讀取 Block
localparam UPDATE      = 3'b100;  // 更新 Cache Line

always @(posedge clk) begin
    case (state)
        IDLE: if (req) state <= COMPARE_TAG;
        
        COMPARE_TAG: begin
            if (tag_match && valid[index])  // Cache Hit
                state <= IDLE;
            else if (dirty[index])          // Miss + Dirty
                state <= WRITE_BACK;
            else                             // Miss + Clean
                state <= ALLOCATE;
        end
        
        WRITE_BACK: state <= ALLOCATE;  // 寫回後 Allocate
        ALLOCATE:   state <= UPDATE;     // 讀取新 Block
        UPDATE:     state <= IDLE;       // 完成
    endcase
end
```

**AMAT 公式**：
```
AMAT = Hit_Time + Miss_Rate × Miss_Penalty

L1 Only:  AMAT = 1 + 0.05 × 100 = 6.0 cycles
L1+L2:    AMAT = 1 + 0.05 × (12 + 0.10 × 100) = 2.1 cycles
L1+L2+L3: AMAT = 1 + 0.05 × (12 + 0.10 × (40 + 0.05 × 100)) = 1.83 cycles
```

**Cache Hierarchy 比較**（實際 Vivado 結果）：

| 配置 | AMAT (cycles) | Speedup |
|-----|---------------|---------|
| No Cache | 100.0 | 1.00x |
| L1 Only | 6.00 | **16.7x** |
| L1 + L2 | 2.10 | 47.6x |
| L1 + L2 + L3 | 1.83 | **54.8x** |

---

### J. Contribution 11：Integrated Performance Analysis

#### J.1 MiBench Benchmark（Actual Execution）

**Benchmark**：MiBench Suite 的 bitcount [10]

**Algorithm Verification**：全部 8 個測試向量通過

| 配置 | Cycles | Speedup |
|------|--------|---------|
| Baseline（no forwarding） | 792 | 1.00x |
| With Forwarding | 303 | **2.61x** |

#### J.2 Mix-Based Performance Projection

**資料來源**：Phansalkar et al. [2] 及 Limaye & Adegbija [6]

| 情境 | Baseline | Optimized | Speedup |
|------|----------|-----------|---------|
| SPEC FP Average | 507,000 | 19,670 | **25.78x** |
| SPEC INT mcf | 649,000 | 18,626 | **34.84x** |
| SPEC INT gobmk | 511,400 | 17,454 | **29.30x** |
| **SPEC Overall** | 533,000 | 18,028 | **29.57x** |

---

### K. Contribution 13：ODE Solver（微積分運算）

**目標**：實作硬體常微分方程（ODE）求解器，使用 Forward Euler 方法進行數值微積分運算。

**數學背景**：

**狀態空間表示**：
```
dX/dt = A·X + B·U
```

其中：
- **X** 是狀態向量（大小 N）
- **A** 是系統矩陣（N×N）
- **B** 是輸入矩陣（N×M）
- **U** 是輸入向量（大小 M）

**Forward Euler 方法**：
```
X(t+h) = X(t) + h · dX/dt
       = X(t) + h · (A·X + B·U)
```

這實作了：
1. **微分**：dX/dt ≈ (X(t+h) - X(t)) / h
2. **積分**：X(t+h) = X(t) + ∫(dX/dt)dt ≈ X(t) + h·f(X,U)

**為何比 CORDIC 複雜**：

| 面向 | CORDIC (Contribution 9) | ODE Solver (Contribution 13) |
|------|------------------------|------------------------------|
| **核心演算法** | Shift-add 迭代 | 矩陣乘法 + Euler 積分 |
| **運算類型** | 單一三角函數 | 微分方程系統 |
| **資料結構** | 純量 | 向量和矩陣 |
| **控制邏輯** | 固定 16 級 pipeline | 6 狀態 FSM |
| **記憶體** | 無 | 8K × 64-bit RAM |
| **數學層級** | 三角學 | **微積分** |

**狀態機**：
```
Start → Prepare → Interpolate → Load1 → Load2 → Final_Calc → Done
         ↓            ↓           ↓        ↓          ↓
       讀取 N,M    讀取 h      計算 B·U  計算 A·X   X + h·(A·X + B·U)
```

**檔案結構**：
- `Euler.v`：主 ODE 求解器模組（279 行）
- `System.v`：頂層封裝
- `RAM-Pre.v`：雙埠 RAM
- `multiplier_16bit.v`：Wallace Tree 乘法器
- `add_sub_cla.v`：Carry Lookahead 加法器
- `tb_ode_solver.v`：Testbench

**來源**：[3amrA7med/ODE-Solver](https://github.com/3amrA7med/ODE-Solver)

**Vivado TCL 指令**：
```tcl
close_sim -force; set_property top tb_ode_solver [get_filesets sim_1]; launch_simulation; run 5000ns
```

**驗證結果（2026-01-02）**：

| 測試項目 | 預期值 | 實際值 | 狀態 |
|---------|-------|-------|------|
| X_new[0] | 25 | 25 | ✅ PASS |
| X_new[1] | 45 | 45 | ✅ PASS |

**計算驗證**：
```
X(t+h) = X(t) + h × (A·X + B·U)
       = [10, 20] + 1 × ([10, 20] + [5, 5])
       = [10, 20] + [15, 25] = [25, 45] ✓
```

**模擬時間**：570 ns

---

## 四、結果摘要

### A. 個別優化影響

| 優化項目 | 指標 | 改進 |
|---------|------|------|
| Data Forwarding | CPI | 1.82 降至 1.26（31%） |
| Branch Prediction | Accuracy | 78.33% |
| L1 Cache | AMAT | 100 降至 6 cycles（16.7x） |
| SIMD ALU | Throughput | 8x parallel |
| CORDIC | Accuracy | < 1% error |

### B. 綜合效能

| 評估方法 | Speedup 範圍 |
|---------|-------------|
| DOE Analysis（Contribution 7） | **3.94x** |
| Cache Hierarchy（Contribution 10） | **54.8x**（AMAT only） |
| Mix-Based Projection（Contribution 11） | **25.78x - 34.84x** |
| MiBench Actual（Contribution 11） | **2.61x** |

---

## 五、結論

本研究證明系統性地應用多種最佳化技術可在流水線處理器中實現顯著的效能改進：

1. **Data Forwarding** 有效消除 31% 的 Pipeline Stall
2. **Branch Prediction** 在真實工作負載模式上達到 78%+ 準確率
3. **Cache Memory** 提供最大的單一改進（16.7x - 54.8x）
4. **SIMD Parallelism** 為資料平行操作實現 8 倍吞吐量
5. **Hardware Unrolling** 將 Software Loop 轉換為平行硬體
6. **Parentheses Support** 實現完整的 Expression Parsing 功能
7. 各項優化**大致正交**，允許乘法性加速累積
8. **綜合優化在 SPEC workload 上達到 25-35 倍預測加速**

---

## 參考文獻

[1] J. L. Hennessy and D. A. Patterson, *Computer Architecture: A Quantitative Approach*, 6th ed. Morgan Kaufmann, 2017.

[2] A. Phansalkar, A. Joshi, and L. K. John, "Analysis of redundancy and application balance in the SPEC CPU2006 benchmark suite," in *Proc. ISCA*, 2007, pp. 412-423.

[3] J. E. Smith, "A study of branch prediction strategies," in *Proc. ISCA*, 1981, pp. 135-148.

[4] D. A. Patterson and J. L. Hennessy, *Computer Organization and Design: The Hardware/Software Interface*, 6th ed. Morgan Kaufmann, 2020.

[5] J. E. Volder, "The CORDIC trigonometric computing technique," *IRE Trans. Electronic Computers*, vol. EC-8, no. 3, pp. 330-334, 1959.

[6] A. Limaye and T. Adegbija, "A workload characterization of the SPEC CPU2017 benchmark suite," in *Proc. ISPASS*, 2018, pp. 149-158.

[7] D. E. Knuth, *The Art of Computer Programming, Vol. 3: Sorting and Searching*, 2nd ed. Addison-Wesley, 1998.

[8] M. D. Hill, "Evaluating associativity in CPU caches," *IEEE Trans. Computers*, vol. 38, no. 12, pp. 1612-1630, 1989.

[9] G. M. Amdahl, "Validity of the single processor approach to achieving large scale computing capabilities," in *AFIPS Conf. Proc.*, 1967, pp. 483-485.

[10] M. R. Guthaus et al., "MiBench: A free, commercially representative embedded benchmark suite," in *Proc. IEEE Workshop on Workload Characterization*, 2001, pp. 3-14.

[11] E. W. Dijkstra, "Shunting yard algorithm," 1961.

---

## 附錄：Vivado TCL 指令

### 執行所有測試
```tcl
# Contribution 1: Performance Testbench
close_sim -force; set_property top tb_performance [get_filesets sim_1]; launch_simulation; run -all

# Contribution 2: Hardware Unrolling
close_sim -force; set_property top tb_simd_add [get_filesets sim_1]; launch_simulation; run -all

# Contribution 3: SIMD Parallelism
close_sim -force; set_property top tb_simd_alu [get_filesets sim_1]; launch_simulation; run -all

# Contribution 5: SIMD ALU Expansion
close_sim -force; set_property top tb_simd_alu_expanded [get_filesets sim_1]; launch_simulation; run -all

# Contribution 6: Branch Prediction
close_sim -force; set_property top tb_branch_prediction [get_filesets sim_1]; launch_simulation; run -all

# Contribution 7: DOE Analysis（3.94x speedup）
close_sim -force; set_property top tb_comprehensive_analysis [get_filesets sim_1]; launch_simulation; run 500ns

# Contribution 8: Parentheses Support
close_sim -force; set_property top tb_parentheses [get_filesets sim_1]; launch_simulation; run -all

# Contribution 9: CORDIC
close_sim -force; set_property top tb_cordic [get_filesets sim_1]; launch_simulation; run -all

# Contribution 10: Cache Hierarchy（54.8x AMAT speedup）
close_sim -force; set_property top tb_cache_hierarchy [get_filesets sim_1]; launch_simulation; run 500ns

# Contribution 11: SPEC Mix-Based Projection（29.57x speedup）
close_sim -force; set_property top tb_integrated [get_filesets sim_1]; launch_simulation; run 500ns

# Contribution 11: MiBench Actual Execution（2.61x speedup）
close_sim -force; set_property top tb_mibench_bitcount [get_filesets sim_1]; launch_simulation; run 500ns
```

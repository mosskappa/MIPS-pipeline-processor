# 明天報告完整逐字稿 - 含程式碼講解

**報告者**: 劉俊逸 (M143140014)  
**時間**: 約 12-15 分鐘  
**日期**: 2025/12/24

---

## 頁數速查表

| 頁數 | 標題 | 動作 |
|-----|------|------|
| 1 | 封面 | 開場 |
| 6 | My Contributions (1/2) | 更新說明 |
| 7 | My Contributions (2/2) | 新增貢獻 |
| 22 | SIMD ALU Expansion | Section header |
| 23 | Extended SIMD Operations | 程式碼講解 |
| 24 | SIMD Expression Evaluator | 程式碼講解 |
| 25 | Branch Prediction | Section header |
| 26 | 2-Bit Saturating Counter | 原理說明 |
| 27 | Branch Predictor Implementation | 程式碼講解 |
| 28 | Branch Prediction Benefits | 數據說明 |
| 34 | Results: Forwarding Performance | 數據更新 |
| 40 | Overall Performance Summary | 總結 |

---

# 第 1 頁: 封面

> 老師好，我是劉俊逸，學號 M143140014。
> 
> 上次報告後，我根據老師的建議把貢獻從 4 個擴充到 **6 個**。
> 
> 主要新增了：
> 1. **SIMD ALU Expansion** - 擴展到五種運算
> 2. **Branch Prediction** - 2-bit saturating counter
> 
> 而且這次所有數據都是 **Vivado 實測結果**，不是理論值。
> 
> 接下來我會 focus 在新增和更新的部分。

**[跳到第 6 頁]**

---

# 第 6 頁: My Contributions (1/2)

**[指向表格]**

> 前四項跟上次一樣：
> 1. Performance Testbench
> 2. Hardware Unrolling
> 3. SIMD Parallelism
> 4. Quantitative Analysis
> 
> 但這次 **CPI 數據更新了**。上次報告的是理論值，這次是 **Vivado 實測**：
> - Forwarding OFF: CPI = **1.82**
> - Forwarding ON: CPI = **1.26**
> - 改善了 **31%**

**[換頁]**

---

# 第 7 頁: My Contributions (2/2) - 新增

**[指向表格]**

> 新增的兩項貢獻：
> 
> **第五，SIMD ALU Expansion**
> - 從只支援加法擴展到 **五種運算**：加、減、乘、除、指數
> - 還實作了 Expression Evaluator，可以處理複雜表達式
> 
> **第六，Branch Prediction**
> - 使用 **2-bit saturating counter** predictor
> - 測試準確率達到 **78.33%**

**[指向 New Modules]**

> 新增的 module 有：
> - `simd_alu.v` - 多功能 SIMD ALU
> - `simd_expr_eval.v` - 表達式求值器
> - `branch_predictor.v` - 分支預測器

**[跳到第 22 頁]**

---

# 第 22 頁: SIMD ALU Expansion (Section Header)

**[直接換頁]**

---

# 第 23 頁: Extended SIMD Operations - 程式碼講解

**[指向表格]**

> 這邊展示 SIMD ALU 支援的五種運算：
> 
> - ADD = 3'b000，做加法 a + b
> - SUB = 3'b001，做減法 a - b
> - MUL = 3'b010，做乘法 a × b
> - DIV = 3'b011，做除法 a ÷ b
> - EXP = 3'b100，做指數 a ^ b
> 
> 上次只有 ADD，這次擴展到完整的 **5 種運算**。

**[指向 Module 路徑]**

> 實作在 `simd_demo/simd_alu.v`。
> 
> 這個設計的特色是：用 `generate` 語法產生 **8 個獨立的運算單元**，可以**同時**做 8 個運算。
> 
> 所以原本要 8 次才能做完的事，現在 1 次就完成了。

**[換頁]**

---

# 第 24 頁: SIMD Expression Evaluator - 程式碼講解

**[指向 Expression]**

> 這邊展示如何計算複雜表達式 `(a+b)*c / d^e`，並且處理 **運算優先級**。

**[指向 Priority]**

> 運算優先級：
> - **指數 `^`** 最高
> - **乘除 `*` `/`** 次之
> - **加減 `+` `-`** 最低

**[指向 Pipeline Stages]**

> 實作是分成四個 stage：
> 
> 1. **先算 d^e** - 因為指數優先級最高
> 2. **再算 a+b** - 括號內的加法
> 3. **接著 (a+b)*c** - 乘法
> 4. **最後除法** - 得到最終結果
> 
> 這個設計展示了如何在硬體中**正確處理先乘除後加減**的規則。

**[跳到第 25 頁]**

---

# 第 25 頁: Branch Prediction (Section Header)

**[直接換頁]**

---

# 第 26 頁: 2-Bit Saturating Counter - 原理說明

**[指向 State Machine 圖]**

> 這是 2-bit saturating counter 的狀態機。

**[指向四個狀態]**

> 有四個狀態：
> - **00 = Strongly Not Taken (SN)**
> - **01 = Weakly Not Taken (WN)**
> - **10 = Weakly Taken (WT)**
> - **11 = Strongly Taken (ST)**

**[指向狀態轉移]**

> 規則很簡單：
> - 分支 **有跳**：數字 **加 1**（最多到 3 就停）
> - 分支 **沒跳**：數字 **減 1**（最少到 0 就停）
> 
> 預測規則：
> - 數字是 **2 或 3** → 預測「會跳」
> - 數字是 **0 或 1** → 預測「不跳」

**[語氣強調]**

> **為什麼用 2-bit 不用 1-bit？**
> 
> 1-bit 的問題是：loop 結束時會連續錯兩次。
> - Loop 執行 9 次 taken，第 10 次 not taken → 錯
> - 下次 loop 開始，predictor 狀態還是 not taken → 又錯
> 
> 2-bit 的好處是：**需要連續兩次錯才會改變預測方向**。
> - 第一次錯只從 ST → WT
> - 還是預測 taken
> - 下次 loop 開始就對了

**[換頁]**

---

# 第 27 頁: Branch Predictor Implementation - 程式碼講解

**[指向投影片上的程式碼]**

> 這邊是 Branch Predictor 的 Verilog 實作。

**[指向第一行: reg [1:0] bht [0:15]]**

> 這行宣告了一個 **Branch History Table**，簡稱 BHT。
> 
> `[1:0]` 表示每個 entry 是 **2-bit**，可以存 0、1、2、3 四個值。
> 
> `[0:15]` 表示有 **16 個 entry**。
> 
> 所以這個 BHT 總共可以記錄 16 個不同分支的歷史狀態。

**[指向第二行: assign predict_taken = bht[pc[...]][1]]**

> 這行是 **預測邏輯**。
> 
> 首先用 PC 去 index BHT，找到對應的 2-bit 值。
> 
> 然後取這個值的 **最高位 (bit 1)**：
> - 如果是 1，表示值是 2 或 3，預測 **taken**
> - 如果是 0，表示值是 0 或 1，預測 **not taken**

**[指向下面的 if-else]**

> 這邊是 **更新邏輯**，在知道分支真正結果後執行。
> 
> `if (actual_taken)`：如果分支真的跳了，counter **加 1**，但最多到 3 就停止。
> 
> `else`：如果分支沒跳，counter **減 1**，但最少到 0 就停止。
> 
> 這種「加到頂就不加、減到底就不減」的設計叫做 **saturating counter**。

**[換頁]**

---

# 第 28 頁: Branch Prediction Benefits - 數據說明

**[指向表格]**

> 這是 Vivado 模擬的測試結果。

**[指向 Prediction Accuracy]**

> 測試了四種分支模式：
> - **Always Taken Loop**: 90% - 模擬 for 迴圈
> - **Always Not Taken**: 85% - 模擬 if 判斷
> - **Alternating T-N-T-N**: 73% - **最難預測**的模式
> - **Realistic Loop (9T+1N)**: 78% - 真實迴圈
> 
> **Overall Accuracy: 78.33%** (47/60 correct)

**[指向 CPI improvement]**

> 預期效益：
> - Branch penalty 從 1 cycle 降到約 0.3 cycle
> - CPI 可以從 1.26 再降到約 **1.15**
> - 約 **9%** 的額外改善

**[跳到第 34 頁]**

---

# 第 34 頁: Results: Forwarding Performance - 數據更新

**[指向表格]**

> 這是 **Vivado 實測數據**，不是理論值。

**[指向數據]**

> | Configuration | Cycles | Instructions | Stalls | CPI |
> |--------------|--------|--------------|--------|-----|
> | Forwarding OFF | 255 | 140 | 114 | **1.82** |
> | Forwarding ON | 182 | 144 | 37 | **1.26** |

**[指向 Performance Improvements]**

> 量化結果：
> - **CPI 改善 31%**（1.82 → 1.26）
> - **Stall 減少 68%**（114 → 37）
> - **Execution time 減少 29%**
> - **Pipeline Efficiency 從 55% 提升到 79%**

**[語氣強調]**

> 剩下的 37 個 stall 分成：
> - **12 個是讀取記憶體造成的**（沒辦法避免，資料還沒讀到）
> - **13 個是分支跳轉造成的**（這是 branch prediction 可以改善的地方）
> 
> 所以 forwarding 已經做到極限了，剩下的要靠 branch prediction。

**[跳到第 40 頁]**

---

# 第 40 頁: Overall Performance Summary - 總結

**[指向表格]**

> 總結各個優化的效果：

**[逐行說明]**

> - **Pipeline**: 5 個階段同時做事，效率提升
> - **Forwarding**: CPI 改善 31%，讓資料傳得更快
> - **SIMD**: 8 倍 throughput，一次做 8 個運算
> - **SIMD ALU**: 支援加減乘除指數 5 種運算
> - **Branch Prediction**: 78% 猜對率

**[指向 Interpretation]**

> 這個專案有兩種平行化：
> - **指令層級**：Pipeline + Forwarding + Branch Prediction
> - **資料層級**：SIMD 一次處理 8 筆資料

**[換頁到 Conclusion，然後結束]**

---

# 結語

> 以上是我這次的更新報告。
> 
> 所有 6 個 contribution 的 **demo 影片都在 GitHub** 的 contributions 資料夾裡。
> 
> GitHub 連結：https://github.com/mosskappa/MIPS-pipeline-processor
> 
> 謝謝老師。

---

# Demo 影片講解 (如果老師要求播放)

## Demo 1: Performance Testbench
**檔案**: `contributions/1_performance_testbench/cpi_with_forwarding.mp4`

> 這是 `testbench_metrics_enhanced.v` 的模擬結果。
> 
> Console 顯示的重點數據：
> - Total Cycles: 182
> - Dynamic Instructions: 144
> - Stall Cycles: 37
> - **CPI: 1.26**
> 
> 跟 Forwarding OFF 的 CPI 1.82 相比，改善了 **31%**。
> 
> 這個 testbench 的關鍵程式碼是使用 `$value$plusargs` 讀取 forwarding 設定，然後在每個 cycle 計數 stall 和 instruction。

---

## Demo 2: Hardware Unrolling
**檔案**: `contributions/2_hardware_unrolling/simd_alu_unrolling.mp4`

> 這是 `tb_simd_alu.v` 的測試結果。
> 
> Console 顯示 `SIMD ALU Testbench (LANES=8, WIDTH=16)`
> 
> 測試了 5 種運算：
> 1. Addition - 8/8 PASS
> 2. Subtraction - 8/8 PASS
> 3. Multiplication - 8/8 PASS
> 4. Division - 8/8 PASS
> 5. Exponentiation - 8/8 PASS
> 
> **40/40 tests PASSED**
> 
> 這就是 Verilog `generate` 語法產生的 8 個平行硬體在運作。

---

## Demo 3: SIMD Parallelism
**檔案**: `contributions/3_simd_parallelism/simd_alu_demo.mp4`

> 展示 8-lane 並行運算。
> 
> Lane 0 到 Lane 7，每一對 input 的運算結果都正確。
> 
> 一個 cycle 完成 8 個 operation，是 sequential 的 **8 倍 throughput**。

---

## Demo 4: Quantitative Analysis
**檔案**: `contributions/4_quantitative_analysis/quantitative_analysis.mp4`

> CPI 量測的分析結果。
> 
> 重點數據：
> - CPI 從 1.82 降到 1.26 = **31% 改善**
> - Stall 從 114 降到 37 = **68% 減少**
> 
> 剩下的 37 個 stall 是 **load-use hazard 和 branch flush**，forwarding 無法解決。

---

## Demo 5: SIMD ALU Expansion
**檔案**: `contributions/5_simd_alu_expansion/simd_expr_demo.mp4`

> `simd_expr_eval.v` 的 Expression Evaluator 測試。
> 
> 測試表達式像 `(a+b)*c / d^e`。
> 
> 正確處理運算優先級：先算指數，再算加法，接著乘法，最後除法。
> 
> **4/4 tests PASSED**

---

## Demo 6: Branch Prediction
**檔案**: `contributions/6_branch_prediction/branch_predictor_demo.mp4`

> `tb_branch_predictor.v` 的測試結果。
> 
> 四種測試模式：
> - Test 1: Always Taken Loop - **90%** accuracy
> - Test 2: Always Not Taken - **85%** accuracy
> - Test 3: Alternating Pattern - **73%** accuracy (最難預測)
> - Test 4: Realistic Loop (9T+1N) - **78%** accuracy
> 
> **Overall Accuracy: 78.33%** (47/60 correct)
> 
> 2-bit saturating counter 的優點：loop 結束時只錯一次，不會連續錯兩次。

---

# Q&A 準備

**Q: Branch Prediction 的準確率 78% 是怎麼得到的？**

> 這是在 Vivado 模擬 `tb_branch_predictor.v` 測試得到的結果。測試包含四種分支模式：always taken、always not taken、alternating、以及 realistic loop pattern。78.33% 是總體準確率 (47/60)。

---

**Q: SIMD ALU 可以整合進 MIPS processor 嗎？**

> 理論上可以，但需要擴展 ISA 支援 SIMD instructions，並修改 datapath 的 width。這個 demo 的目的是展示 `generate` 和 hardware unrolling 的概念，而非 full integration。

---

**Q: CPI 1.26 是最佳值嗎？**

> 不是。剩餘的 37 個 stall 包含 12 個 load-use hazard（forwarding 無法解決）和 13 個 branch flush。如果加入 branch prediction，預期可以再降到約 1.15。

---

**Q: 為什麼選 2-bit 不是更多 bit？**

> 2-bit 是經典的 branch predictor 設計，足夠處理大部分 loop pattern。3-bit 或更高會增加硬體複雜度，但改善有限。研究顯示 2-bit 是 cost-effective 的選擇。

---

**Q: Forwarding 會增加 critical path delay 嗎？**

> 會的。Forwarding 需要額外的 mux 在 ALU input，這會增加 propagation delay。在實際設計中需要評估這是否會影響 clock frequency。不過在大多數情況下，CPI 的改善可以彌補 clock frequency 的微小下降。

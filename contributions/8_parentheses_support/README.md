# Contribution 8: Expression Parser with Parentheses & Right Associativity

## Overview
Implemented a hardware expression parser using Dijkstra's Shunting-yard algorithm with **full parentheses support** and **right-associative exponentiation**.

## Features Implemented
- ✅ **Parentheses Support**: `( )` override operator precedence
- ✅ **Right Associativity**: `2^3^2 = 2^9 = 512` (not 64)
- ✅ **Division**: `/` operator with proper precedence
- ✅ **Operator Precedence**: `^` > `* /` > `+ -`
- ✅ **Shunting-yard Algorithm**: Infix to Postfix conversion

## Operator Encoding

| Operation | Op Code | Symbol | Priority |
|-----------|---------|--------|----------|
| ADD | `3'b000` | `+` | 1 (Low) |
| SUB | `3'b001` | `-` | 1 (Low) |
| MUL | `3'b010` | `*` | 2 (Mid) |
| DIV | `3'b011` | `/` | 2 (Mid) |
| EXP | `3'b100` | `^` | 3 (High) |
| END | `3'b101` | `=` | Trigger |
| LPAREN | `3'b110` | `(` | Special |
| RPAREN | `3'b111` | `)` | Special |

## Test Results

| Test | Expression | Expected | Result | Status |
|------|------------|----------|--------|--------|
| 1 | `5 * (3 + 4)` | 35 | 35 | ✅ PASS |
| 2 | `2 ^ 3 ^ 2` | 512 | 512 | ✅ PASS |
| 3 | `100 / (2 + 3)` | 20 | 20 | ✅ PASS |

**All 3 tests passed!**

## Bug Fixes Applied

### Critical Bug #1: `=` Operator Detection (calculator.v)
```diff
- if(input_data[2] === 1'b1) state <= 1; // Wrong: matched ^, =, (, )
+ if(input_data[2:0] === 3'b101) state <= 1; // Correct: only = ends calc
```

### Critical Bug #2: `pop_stb` Not Cleared (converter.v)
```diff
  3: // End of States
      begin
          input_ack <= 1'b0;
          push_stb <= 1'b0;
+         pop_stb <= 1'b0;  // CRITICAL FIX!
          state <= 3'd0;
      end
```

### Bug #3: Inline Variable Declaration (calculator.v)
Moved `power` function outside `always` block to fix Verilog syntax error.

## How to Run (Vivado)

```tcl
# Step 1: Close any existing simulation
close_sim -force

# Step 2: Set the testbench as top module
set_property top tb_parentheses [get_filesets sim_1]

# Step 3: Launch simulation
launch_simulation

# Step 4: Run to completion
run -all
```

## Files
- `converter.v` - Shunting-yard with parentheses & right associativity
- `calculator.v` - Postfix evaluator with power function
- `expression_parser_top.v` - Top-level module
- `tb_parentheses.v` - Testbench

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Expression Parser Pipeline                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Input (Infix)     Converter           Calculator    Output   │
│   ─────────────     ───────────         ──────────    ──────   │
│                                                                 │
│   5*(3+4)=      →   Shunting-yard   →   Stack Eval  →   35    │
│                    (handles () )       (computes)              │
│                                                                 │
│   Postfix: 5 3 4 + *                                           │
│   Eval: 3+4=7, 5*7=35                                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Theoretical Background
- **Shunting-yard Algorithm**: Dijkstra, 1961
- **Right Associativity**: Standard for exponentiation operators
- Reference: [RPN-Calculator by SupawatDev](https://github.com/SupawatDev/RPN-Calculator)

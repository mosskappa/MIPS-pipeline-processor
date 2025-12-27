# Contribution 8: Parentheses Support for Expression Parser

## Overview
Extended the expression parser with full parentheses support, operator precedence, and correct associativity handling using the Shunting-yard algorithm.

## Features
- Full arithmetic operations: ADD, SUB, MUL, DIV, EXP
- Parentheses support for precedence override
- Correct operator precedence: `^` > `* /` > `+ -`
- Right-associativity for exponentiation: `2^3^2 = 512`

## Operator Precedence Table

| Operator | Precedence | Associativity |
|----------|------------|---------------|
| `^` | 3 (highest) | Right |
| `*`, `/` | 2 | Left |
| `+`, `-` | 1 (lowest) | Left |

## Encoding (Aligned with Contribution 5)

| Operation | Op Code | Symbol |
|-----------|---------|--------|
| ADD | `3'b000` | `+` |
| SUB | `3'b001` | `-` |
| MUL | `3'b010` | `*` |
| DIV | `3'b011` | `/` |
| EXP | `3'b100` | `^` |
| END | `3'b101` | `=` |
| LPAREN | `3'b110` | `(` |
| RPAREN | `3'b111` | `)` |

## Files
- `converter.v` - Shunting-yard algorithm (Infix to Postfix conversion)
- `stack.v` - Hardware stack module
- `calculator.v` - Postfix expression evaluator with 5 operations
- `expression_parser_top.v` - Top-level module
- `tb_parentheses.v` - Comprehensive testbench

## Shunting-Yard Algorithm

```
Input:  5 * ( 3 + 4 )
Output: 5 3 4 + *

Execution:
  Token Stack   Output
  5     []      [5]
  *     [*]     [5]
  (     [*,(]   [5]
  3     [*,(]   [5,3]
  +     [*,(,+] [5,3]
  4     [*,(,+] [5,3,4]
  )     [*]     [5,3,4,+]  <- pop until (
  END   []      [5,3,4,+,*]

Result: 5 * 7 = 35
```

## Right-Associativity Example

```
Input: 2 ^ 3 ^ 2

Standard math: 2^(3^2) = 2^9 = 512 (right-associative)
Wrong result:  (2^3)^2 = 8^2 = 64  (left-associative)

Correct Postfix: 2 3 2 ^ ^
Evaluation:
  Step 1: 3 ^ 2 = 9
  Step 2: 2 ^ 9 = 512
```

## Test Cases

| Expression | Expected | Test Focus |
|------------|----------|------------|
| `5 * (3 + 4)` | 35 | Parentheses precedence |
| `2 ^ 3 ^ 2` | 512 | Right-associativity |
| `100 / (2 + 3)` | 20 | Parentheses with division |
| `(1 + 2) * (3 + 4)` | 21 | Multiple parentheses |
| `10 - 2 - 3` | 5 | Left-associativity |

## How to Run (Vivado)

### Complete TCL Commands
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

## Theoretical Background
- **Shunting-yard Algorithm**: Dijkstra, 1961
- **Operator Precedence Parsing**: Standard technique in compiler design
- Reference: Data Structures course (Stack applications)
